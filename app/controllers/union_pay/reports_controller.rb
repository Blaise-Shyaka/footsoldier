class UnionPay::ReportsController < UnionPayController
  before_action :verify_client_credentials
  
  def merchants
    @merchants = UnionPayMerchant.all
  end

  def banks
    @banks = UnionPayBank.all
  end

  def merchants_analysis
    @merchants_accepting_international_payments =
      percentage_of(UnionPayMerchant.where(merchant_accept_international_payment: 'Yes').length, 
                    UnionPayMerchant.all.length)

    @merchant_accept_upi_cards_test_not_allowed =
      percentage_of(UnionPayMerchant.where(chip_in_pos_upi_accepted:'The cashier stated UnionPay Accepted/ Test not allowed').length, 
                    UnionPayMerchant.all.length)

    @merchant_accept_upi_cards_test_allowed =
      percentage_of(UnionPayMerchant.where(chip_in_pos_upi_accepted:'The cashier stated UnionPay accepted/ Tested').length, 
                    UnionPayMerchant.all.length)

    @transactions_with_approved_result =
      percentage_of(UnionPayMerchant.where(chip_in_pos_purchase_transaction_result: 'Approved').length, 
                    (@merchant_accept_upi_cards_test_allowed * 100))

    @merchants_accepting_visa_only =
      percentage_of(UnionPayMerchant.where(chip_in_pos_other_card_schemes_accepted: 'VISA').length, 
                    UnionPayMerchant.all.length)

    @merchants_accepting_mastercard_only =
      percentage_of(UnionPayMerchant.where(chip_in_pos_other_card_schemes_accepted: 'Mastercard').length, 
                    UnionPayMerchant.all.length)

    @merchants_accepting_both_visa_and_mastercard =
      percentage_of(UnionPayMerchant.where(chip_in_pos_other_card_schemes_accepted: 'both VISA and Mastercard').length, 
                    UnionPayMerchant.all.length)

    @physical_decal_displayed_before_campaign =
      percentage_of(UnionPayMerchant.where(upi_decal_displayed_before_visit: 'Physical decal').length, 
                    UnionPayMerchant.all.length)

    @electronic_decal_displayed_before_campaign =
      percentage_of(UnionPayMerchant.where(upi_decal_displayed_before_visit: 'Electronic decal').length, 
                    UnionPayMerchant.all.length)

    @upi_decal_displayed_after_visit =
      percentage_of(UnionPayMerchant.where(upi_decal_displayed_after_visit: 'Yes').length, 
                    UnionPayMerchant.all.length)

    @only_visa_decal_displayed =
      percentage_of(UnionPayMerchant.where(is_visa_or_mastercard_displayed: 'Only VISA decal posted').length, 
                    UnionPayMerchant.all.length)

    @only_mastercard_decal_displayed =
      percentage_of(UnionPayMerchant.where(is_visa_or_mastercard_displayed: 'Only Mastercard decal posted').length, 
                    UnionPayMerchant.all.length)

    @both_visa_and_mastercard_decal_displayed =
      percentage_of(UnionPayMerchant.where(is_visa_or_mastercard_displayed: 'Both of them posted').length, 
                    UnionPayMerchant.all.length)

    @upi_contactless_on_decal =
      percentage_of(UnionPayMerchant.where(is_contactless_mark_shown_upi_single_decal: 'Yes').length, 
                    UnionPayMerchant.all.length)

    @both_visa_and_mastercard_contactless_on_decal =
      percentage_of(UnionPayMerchant.where(is_visa_or_mastercard_contactless_mark_shown_on_single_decal: 'Both of them shown').length, 
                    UnionPayMerchant.all.length)
  end

  def banks_analysis
  end

  private

  def verify_client_credentials
    unless current_user.is_upi_client
      flash[:alert] = "Unauthorized! You must be from UPI to access this resource"
      redirect_to user_path(current_user)
    end
  end

  def percentage_of(x, y)
    (x * 100 / y.to_f).round(2)
  end
end