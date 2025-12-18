import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/product_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/stock_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProductProvider(),
      child: MaterialApp(
        title: 'Bélanger Stock',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.brown,
          primaryColor: const Color(0xFF292524),
          scaffoldBackgroundColor: const Color(0xFFE8E5DF),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF292524),
            primary: const Color(0xFF292524),
            secondary: const Color(0xFFC9C5BD),
            background: const Color(0xFFE8E5DF),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF292524),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF292524),
              foregroundColor: Colors.white,
            ),
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
        routes: {
          '/add-product': (context) => const AddProductScreen(),
          '/stock': (context) => const StockScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/product-detail') {
            final productId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: productId),
            );
          }
          return null;
        },
      ),
    );
  }
}
