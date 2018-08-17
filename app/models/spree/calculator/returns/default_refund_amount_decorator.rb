Spree::Calculator::Returns::DefaultRefundAmount.class_eval do
  prepend SpreeProductAssembly::DefaultRefundAmountExtensions

end
