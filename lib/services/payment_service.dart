import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'api_service.dart';

class PaymentService {
  late Razorpay _rp;
  final void Function(String type) onSuccess;
  final void Function(String error) onFailed;

  PaymentService({required this.onSuccess, required this.onFailed}) {
    _rp = Razorpay();
    _rp.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _rp.on(Razorpay.EVENT_PAYMENT_ERROR, _onFailed);
  }

  Future<void> startPayment(String type) async {
    try {
      final order = await ApiService.post('/payments/create-order', {'type': type});
      if (order.containsKey('error')) {
        onFailed(order['error']?.toString() ?? 'Unable to start payment');
        return;
      }

      final key = order['key']?.toString() ?? '';
      final orderId = order['order_id']?.toString() ?? '';
      final amount = order['amount'];
      if (key.isEmpty || orderId.isEmpty || amount == null) {
        onFailed('Invalid payment order from server');
        return;
      }

      _rp.open({
        'key': key,
        'order_id': orderId,
        'amount': amount,
        'currency': 'INR',
        'name': 'ProNutri',
        'description': type == 'credits' ? '₹100 AI Credits' : '₹100 Monthly Subscription',
        'prefill': {'contact': '', 'email': ''},
        'theme': {'color': '#1E6EBD'},
      });
    } catch (_) {
      onFailed('Unable to start payment. Please try again.');
    }
  }

  void _onSuccess(PaymentSuccessResponse r) => onSuccess(r.paymentId ?? '');
  void _onFailed(PaymentFailureResponse r) => onFailed(r.message ?? 'Failed');
  void dispose() => _rp.clear();
}
