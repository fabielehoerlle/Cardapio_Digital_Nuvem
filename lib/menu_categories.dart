import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'home_banner.dart'; // Add this import

class MenuCategories extends StatefulWidget {
  const MenuCategories({super.key, required this.setView});

  final Function(String) setView;

  @override
  _MenuCategoriesState createState() => _MenuCategoriesState();
}

class _MenuCategoriesState extends State<MenuCategories> {
  final Logger _logger = Logger('MenuCategories');

  final _categoriesFuture =
      Supabase.instance.client.from('dd_menu_categories').select();

  Map<String, dynamic>? _selectedCategory; // exemplo: Copo da Felicidade
  Map<String, dynamic>? _selectedVariation; //exemplo: 300ml ou 500ml
  final Map<String, dynamic>? _selectedOptions =
      {}; // exemplo: BASE, COMPLEMENTOS, etc

  // função para adicionar uma opção
  void registerOption(String fieldName, String optionName, String optionType,
      dynamic optionValue) {
    _logger.warning(
        'Registering option: $fieldName, $optionName, $optionType, $optionValue');
    setState(() {
      if (optionType == 'radio') {
        _selectedOptions![fieldName] = optionName;
      }
      if (optionType == 'checkbox') {
        _selectedOptions![fieldName] ??= <String>{};
        final selectedSet = _selectedOptions[fieldName] as Set<String>;
        if (selectedSet.contains(optionName)) {
          selectedSet.remove(optionName);
        } else {
          selectedSet.add(optionName);
        }
      }
      if (optionType == 'quantity') {
        if (!_selectedOptions!.containsKey(fieldName)) {
          _selectedOptions[fieldName] = {};
        }
        _selectedOptions[fieldName][optionName] = optionValue as int;
      }
    });
  }

  // função para inserir o pedido no banco de dados
  Future<void> insertPedido() async {
    try {
      // menu_options will be the stringified json of _selectedOptions
      String menuOptions = jsonEncode(_selectedOptions);

      final response =
          await Supabase.instance.client.from('dd_menu_pedidos').insert({
        'created_at': DateTime.now().toIso8601String(),
        'menu_category_id': _selectedCategory!['id'] as int,
        'menu_variation_id': _selectedVariation!['id'] as int,
        'menu_options': menuOptions,
      });

      print(response);

      widget.setView('pedidos');
    } catch (e) {
      _logger.severe('Exception while inserting order: $e');
      // Handle any exceptions, maybe show an error message to the user
    }
  }

  Widget createCategoriesGridView(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData ||
            snapshot.data == null ||
            (snapshot.data as List).isEmpty) {
          return const Center(child: Text('No categories found.'));
        }

        final categories = snapshot.data as List<dynamic>;

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 600 ? 2 : 3;
            return SingleChildScrollView(
              child: Column(
                children: [
                  const HomeBanner(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 3 / 4,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          borderRadius: BorderRadius.circular(12.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 4.0,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Image.network(
                                      category['image'] as String,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.broken_image,
                                          size: 150,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    category['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget createVariationsGridView(BuildContext context) {
    if (_selectedCategory == null) {
      return createCategoriesGridView(context);
    }

    final categoryName = _selectedCategory!['name'] as String;
    final categorySlug = _selectedCategory!['slug'];

    final filteredVariations = Supabase.instance.client
        .from('dd_menu_variations')
        .select()
        .eq('category_slug', categorySlug);

    _logger
        .info('Category Slug: $categorySlug, Variations: $filteredVariations');

    return FutureBuilder<List<dynamic>>(
      future: filteredVariations,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData ||
            snapshot.data == null ||
            (snapshot.data as List).isEmpty) {
          return const Center(child: Text('No variations found.'));
        }

        final variations = snapshot.data as List<dynamic>;

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 600 ? 2 : 3;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 3 / 4,
                      ),
                      itemCount: variations.length,
                      itemBuilder: (context, index) {
                        final variation = variations[index];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedVariation = variation;
                            });
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 4.0,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Image.network(
                                      variation['image'] as String,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.broken_image,
                                          size: 150,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    variation['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16.0),
                    if (_selectedCategory != null && _selectedVariation == null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = null;
                              _selectedVariation = null;
                            });
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Categories'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget createOptionsListView(BuildContext context) {
    if (_selectedVariation == null) {
      return createVariationsGridView(context);
    }

    final categoryName = _selectedCategory!['name'] as String;
    final variationName = _selectedVariation!['name'] as String;
    final categoryId = _selectedCategory!['id'] as int;

    // each option in filteredOptions is like this:
    // {"id":1, "created_at":"2024-05-02T18:45:11.883Z", "menu_category_id":1, "menu_variation_id":1, "field_label":"Base","field_type":"radio","field_options":["Açaí","Cupuaçú"]}
    final filteredOptions = Supabase.instance.client
        .from('dd_menu_options')
        .select()
        .eq('menu_category_id', categoryId);
    _logger.info('Category ID: $categoryId, Options: $filteredOptions');

    return FutureBuilder<List<dynamic>>(
      future: filteredOptions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData ||
            snapshot.data == null ||
            (snapshot.data as List).isEmpty) {
          return const Center(child: Text('No options found.'));
        }

        final options = snapshot.data as List<dynamic>;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Título da página
              Text(
                '$categoryName - $variationName',
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              // Lista de opções (organizadas em grupos como BASE, COMPLEMENTO, etc)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return Column(
                    children: [
                      // Título da opção (BASE, COMPLEMENTO, etc)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 4.0,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text(
                            option['field_label'] as String,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Lista de opções (Açaí, Cupuaçú, etc)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: option['field_options'].length,
                        itemBuilder: (context, index) {
                          final fieldType = option['field_type'] as String;
                          final fieldOption =
                              option['field_options'][index] as String;
                          final optionName = option['field_label'] as String;

                          return OptionItem(
                            fieldName: optionName,
                            fieldOption: fieldOption,
                            fieldType: fieldType,
                            registerOption: registerOption,
                            selectedOptions: _selectedOptions,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    print(_selectedOptions);
                    await insertPedido();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Finalizar Pedido'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget wid;
    if (_selectedCategory == null) {
      wid = createCategoriesGridView(context);
    } else if (_selectedVariation == null) {
      wid = createVariationsGridView(context);
    } else {
      wid = createOptionsListView(context);
    }
    return Expanded(
      child: SingleChildScrollView(
        child: wid,
      ),
    );
  }
}

class OptionItem extends StatelessWidget {
  const OptionItem({
    super.key,
    required this.fieldName,
    required this.fieldOption,
    required this.fieldType, // for radio or checkbox
    required this.registerOption,
    required this.selectedOptions,
  });

  final String fieldName;
  final String fieldOption;
  final String fieldType;
  final Function(String, String, String, dynamic) registerOption;
  final Map<String, dynamic>? selectedOptions;

  @override
  Widget build(BuildContext context) {
    bool isSelected = selectedOptions?[fieldName] == fieldOption;
    switch (fieldType.toLowerCase()) {
      case 'radio':
        return OptionItemRadio(
          fieldOption: fieldOption,
          isSelected: isSelected,
          onTap: () => registerOption(fieldName, fieldOption, fieldType, null),
        );
      case 'checkbox':
        return OptionItemCheckbox(
          fieldOption: fieldOption,
          isSelected: isSelected,
          onTap: () => registerOption(fieldName, fieldOption, fieldType, null),
        );
      case 'quantity':
        return OptionItemQuantity(
          fieldOption: fieldOption,
          quantity: selectedOptions?[fieldName]?[fieldOption] ?? 0,
          onQuantityChanged: (int newQuantity) {
            registerOption(fieldName, fieldOption, fieldType, newQuantity);
          },
        );
      default:
        return ListTile(
          title: Text(fieldOption),
        );
    }
  }
}

class OptionItemRadio extends StatelessWidget {
  const OptionItemRadio({
    super.key,
    required this.fieldOption,
    required this.isSelected,
    required this.onTap,
  });

  final String fieldOption;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 24.0,
        height: 24.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey,
            width: 2.0,
          ),
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                ),
              )
            : null,
      ),
      title: Text(
        fieldOption,
        style: const TextStyle(fontSize: 16.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}

class OptionItemCheckbox extends StatelessWidget {
  const OptionItemCheckbox({
    super.key,
    required this.fieldOption,
    required this.isSelected,
    required this.onTap,
  });

  final String fieldOption;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 24.0,
        height: 24.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey,
            width: 2.0,
          ),
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                size: 16.0,
                color: Colors.blue,
              )
            : null,
      ),
      title: Text(
        fieldOption,
        style: const TextStyle(fontSize: 16.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}

class OptionItemQuantity extends StatelessWidget {
  const OptionItemQuantity({
    super.key,
    required this.fieldOption,
    required this.quantity,
    required this.onQuantityChanged,
  });

  final String fieldOption;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(fieldOption),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => onQuantityChanged(quantity - 1),
            icon: const Icon(Icons.remove),
          ),
          Text('$quantity'),
          IconButton(
            onPressed: () => onQuantityChanged(quantity + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
