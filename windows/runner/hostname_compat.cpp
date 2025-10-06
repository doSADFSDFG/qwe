#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>

namespace {
using GetHostNameWPtr = INT(WSAAPI*)(PWSTR, INT);

GetHostNameWPtr ResolveSystemGetHostNameW() {
  HMODULE ws2_module = GetModuleHandleW(L"ws2_32.dll");
  if (!ws2_module) {
    ws2_module = LoadLibraryW(L"ws2_32.dll");
    if (!ws2_module) {
      return nullptr;
    }
  }
  return reinterpret_cast<GetHostNameWPtr>(
      GetProcAddress(ws2_module, "GetHostNameW"));
}

int MultiByteToWide(const char* source, PWSTR destination, INT dest_len) {
  int converted = MultiByteToWideChar(CP_UTF8, 0, source, -1, destination,
                                      dest_len);
  if (converted != 0) {
    return converted;
  }
  DWORD utf8_error = GetLastError();
  converted =
      MultiByteToWideChar(CP_ACP, 0, source, -1, destination, dest_len);
  if (converted == 0) {
    // Preserve the most meaningful error if the UTF-8 attempt failed due to
    // insufficient buffer space.
    if (utf8_error == ERROR_INSUFFICIENT_BUFFER ||
        GetLastError() == ERROR_INSUFFICIENT_BUFFER) {
      SetLastError(ERROR_INSUFFICIENT_BUFFER);
    }
  }
  return converted;
}

}  // namespace

extern "C" INT WSAAPI GetHostNameW(PWSTR name, INT namelen) {
  if (!name || namelen <= 0) {
    WSASetLastError(WSAEFAULT);
    return SOCKET_ERROR;
  }

  static GetHostNameWPtr system_impl = ResolveSystemGetHostNameW();
  if (system_impl) {
    return system_impl(name, namelen);
  }

  WSADATA wsa_data;
  bool wsa_started = false;
  int startup_result = WSAStartup(MAKEWORD(2, 2), &wsa_data);
  if (startup_result == 0) {
    wsa_started = true;
  } else if (startup_result == WSASYSNOTREADY ||
             startup_result == WSAEINVAL || startup_result == WSAEINPROGRESS) {
    WSASetLastError(startup_result);
    return SOCKET_ERROR;
  }

  char hostname[NI_MAXHOST] = {0};
  int lookup_result = gethostname(hostname, sizeof(hostname));
  int lookup_error = lookup_result == SOCKET_ERROR ? WSAGetLastError() : 0;

  if (wsa_started) {
    WSACleanup();
  }

  if (lookup_result == SOCKET_ERROR) {
    WSASetLastError(lookup_error);
    return SOCKET_ERROR;
  }

  int converted = MultiByteToWide(hostname, name, namelen);
  if (converted == 0) {
    if (namelen > 0) {
      name[0] = L'\0';
    }
    if (GetLastError() == ERROR_INSUFFICIENT_BUFFER) {
      WSASetLastError(WSAEFAULT);
    } else {
      WSASetLastError(WSAEOPNOTSUPP);
    }
    return SOCKET_ERROR;
  }

  return 0;
}
