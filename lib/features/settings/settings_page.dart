import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../controllers/menu_controller.dart';
import '../../data/pos_database.dart';
import '../../models/menu_category.dart';
import '../../models/menu_item.dart';
import '../../widgets/error_state.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(menuCategoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorState(
          message: '메뉴 카테고리를 불러오지 못했습니다.',
          error: error,
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: FilledButton(
                onPressed: () => _showCategoryDialog(context),
                child: const Text('첫 번째 카테고리 추가'),
              ),
            );
          }

          _selectedCategoryId ??= categories.first.id;
          final selectedCategory =
              categories.firstWhere((category) => category.id == _selectedCategoryId, orElse: () => categories.first);

          return Row(
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '카테고리',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _showCategoryDialog(context),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount: categories.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final isSelected = category.id == _selectedCategoryId;
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text(category.name),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showCategoryDialog(context, category: category);
                                    } else if (value == 'delete') {
                                      _deleteCategory(category);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'edit', child: Text('수정')),
                                    PopupMenuItem(value: 'delete', child: Text('삭제')),
                                  ],
                                ),
                                onTap: () {
                                  setState(() => _selectedCategoryId = category.id);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: _MenuListPanel(category: selectedCategory),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCategoryDialog(BuildContext context, {MenuCategory? category}) async {
    final controller = TextEditingController(text: category?.name ?? '');
    final isEditing = category != null;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? '카테고리 수정' : '카테고리 추가'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(labelText: '카테고리명'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '카테고리명을 입력하세요';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                final db = ref.read(posDatabaseProvider);
                final name = controller.text.trim();
                if (isEditing) {
                  await db.updateCategory(category!.copyWith(name: name));
                } else {
                  await db.addCategory(name);
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
                ref.invalidate(menuCategoriesProvider);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCategory(MenuCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('카테고리 삭제'),
          content: Text('${category.name} 카테고리를 삭제할까요? 관련 메뉴도 함께 삭제됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final db = ref.read(posDatabaseProvider);
      await db.deleteCategory(category.id);
      ref.invalidate(menuCategoriesProvider);
      setState(() {
        _selectedCategoryId = null;
      });
    }
  }
}

class _MenuListPanel extends ConsumerWidget {
  const _MenuListPanel({required this.category});

  final MenuCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menusAsync = ref.watch(menuItemsProvider(category.id));
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${category.name} 메뉴',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showMenuDialog(context, ref, categoryId: category.id),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: menusAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => ErrorState(
                  message: '메뉴를 불러오지 못했습니다.',
                  error: error,
                ),
                data: (menus) {
                  if (menus.isEmpty) {
                    return const Center(child: Text('등록된 메뉴가 없습니다.'));
                  }
                  return ListView.separated(
                    itemCount: menus.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final menu = menus[index];
                      return ListTile(
                        title: Text(menu.name),
                        subtitle: Text('₩${NumberFormat('#,###').format(menu.price)}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showMenuDialog(context, ref, categoryId: category.id, menu: menu);
                            } else if (value == 'delete') {
                              _deleteMenu(context, ref, menu);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('수정')),
                            PopupMenuItem(value: 'delete', child: Text('삭제')),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMenuDialog(BuildContext context, WidgetRef ref,
      {required int categoryId, MenuItem? menu}) async {
    final nameController = TextEditingController(text: menu?.name ?? '');
    final priceController = TextEditingController(text: menu?.price.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final isEditing = menu != null;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? '메뉴 수정' : '메뉴 추가'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '메뉴명'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '메뉴명을 입력하세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: '가격'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return '올바른 가격을 입력하세요';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                final db = ref.read(posDatabaseProvider);
                final name = nameController.text.trim();
                final price = int.parse(priceController.text.trim());
                if (isEditing) {
                  await db.updateMenu(
                    MenuItem(
                      id: menu!.id,
                      name: name,
                      price: price,
                      categoryId: categoryId,
                    ),
                  );
                } else {
                  await db.addMenu(name: name, price: price, categoryId: categoryId);
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                ref.invalidate(menuItemsProvider(categoryId));
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMenu(BuildContext context, WidgetRef ref, MenuItem menu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('메뉴 삭제'),
          content: Text('${menu.name} 메뉴를 삭제할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final db = ref.read(posDatabaseProvider);
      await db.deleteMenu(menu.id);
      ref.invalidate(menuItemsProvider(category.id));
    }
  }
}
