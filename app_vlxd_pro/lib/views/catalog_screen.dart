import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/product_viewmodel.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initialQuery = context.read<ProductViewModel>().searchQuery;
    if (initialQuery.isNotEmpty) {
      _searchController.text = initialQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tra cứu & Tìm kiếm vật tư'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm xi măng, thép Hòa Phát, cát, đá, gạch...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
                    suffixIcon: productVm.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              productVm.search('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => productVm.search(val),
                ),
                const SizedBox(height: 8),

                // Category & Sort row
                Row(
                  children: [
                    // Category dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            isExpanded: true,
                            value: productVm.selectedCategoryId,
                            hint: const Text('Tất cả danh mục', style: TextStyle(fontSize: 13)),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Tất cả danh mục', style: TextStyle(fontSize: 13)),
                              ),
                              ...productVm.categories.map((c) => DropdownMenuItem<int?>(
                                value: c.maDanhMuc,
                                child: Text(c.tenDanhMuc, style: const TextStyle(fontSize: 13)),
                              )),
                            ],
                            onChanged: (catId) => productVm.selectCategory(catId),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Sort dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: productVm.sortBy,
                          items: const [
                            DropdownMenuItem(value: 'default', child: Text('Mặc định', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'price_asc', child: Text('Giá thấp → cao', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'price_desc', child: Text('Giá cao → thấp', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (val) {
                            if (val != null) productVm.setSortBy(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Count Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Text(
                  'Tìm thấy ${productVm.products.length} sản phẩm',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (productVm.searchQuery.isNotEmpty || productVm.selectedCategoryId != null)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      productVm.search('');
                      productVm.selectCategory(null);
                    },
                    child: const Text('Xóa bộ lọc', style: TextStyle(fontSize: 12, color: Color(0xFF1565C0))),
                  ),
              ],
            ),
          ),

          // Grid Results
          Expanded(
            child: productVm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productVm.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Không có vật tư phù hợp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Hãy thử thay đổi từ khóa hoặc bộ lọc danh mục', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.63,
                        ),
                        itemCount: productVm.products.length,
                        itemBuilder: (context, index) {
                          final prod = productVm.products[index];
                          return ProductCard(
                            product: prod,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(productId: prod.maSanPham),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
