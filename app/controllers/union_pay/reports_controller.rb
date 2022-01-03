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
                    UnionPayMerchant.all.length)

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
    @total_nber_of_banks = UnionPayBank.all.length
    @atms_accepting_upi_cards = percentage_of(UnionPayBank.where(upi_accepted: 'UnionPay Accepted/ Tested').length,
                                              UnionPayBank.all.length)
    @atms_where_test_not_allowed = percentage_of(UnionPayBank.where(upi_accepted: 'Test not allowed').length,
                                                UnionPayBank.all.length)
    @atms_where_transaction_is_approved = percentage_of(UnionPayBank.where(transaction_result: 'Approved').length,
                                                      UnionPayBank.all.length)
    @atms_where_transaction_is_failed = percentage_of(UnionPayBank.where(transaction_result: 'Failed').length,
                                                      UnionPayBank.all.length)
    @atms_pysical_decal_is_displayed_before_visit = percentage_of(UnionPayBank.where(upi_decal_displayed_before_visit: 'Physical decal').length,
                                                                  UnionPayBank.all.length)
    @atms_electronic_decal_is_displayed_before_visit = percentage_of(UnionPayBank.where(upi_decal_displayed_before_visit: 'Electronic decal').length,
                                                                    UnionPayBank.all.length)
    @atms_no_decal_is_displayed_before_visit = percentage_of(UnionPayBank.where(upi_decal_displayed_before_visit: 'No UnionPay decal').length,
                                                            UnionPayBank.all.length)
    @atms_decal_displayed_after_visit = percentage_of(UnionPayBank.where(upi_decal_displayed_after_visit: 'Yes').length,
                                                      UnionPayBank.all.length)
    @visa_and_mastercard_decal_displayed = percentage_of(UnionPayBank.where(is_visa_or_mastercard_displayed: 'Yes').length,
                                                        UnionPayBank.all.length)
  end

  def download_merchants_csv
    @union_pay_merchants = UnionPayMerchant.all

    respond_to do |format|
      format.html
      format.csv { send_data @union_pay_merchants.to_csv, filename: "UnionPay-Merchants-#{Date.today}.csv" }
    end
  end

  def download_atms_csv
    @union_pay_atms = UnionPayBank.all

    respond_to do |format|
      format.html
      format.csv { send_data @union_pay_atms.to_csv, filename: "UnionPay-ATMs-#{Date.today}.csv" }
    end
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