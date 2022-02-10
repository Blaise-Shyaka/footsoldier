class UnionPayMerchantsController < ApplicationController
  before_action :authenticate_user
  before_action :set_union_pay_merchant, only: %i[ show edit update destroy ]
  before_action :verify_promoter_credentials

  # GET /union_pay_merchants or /union_pay_merchants.json
  def index
    @union_pay_merchants = UnionPayMerchant.where(edited_by: nil)
  end

  # GET /union_pay_merchants/1 or /union_pay_merchants/1.json
  def show
  end

  # GET /union_pay_merchants/new
  def new
    @acquirers = ['Bank of Kigali', 'Equity Bank', 'Ecobank', 'KCB', 'BPR']
    @union_pay_merchant = UnionPayMerchant.new
  end

  # GET /union_pay_merchants/1/edit
  def edit
    @acquirers = ['Bank of Kigali', 'Equity Bank', 'Ecobank', 'KCB', 'BPR']
  end

  # POST /union_pay_merchants or /union_pay_merchants.json
  def create
    @user = current_user
    @union_pay_merchant = @user.union_pay_merchants.new(union_pay_merchant_params)

    respond_to do |format|
      if @union_pay_merchant.save!
        format.html { redirect_to @union_pay_merchant, notice: "Union pay merchant was successfully created." }
        format.json { render :show, status: :created, location: @union_pay_merchant }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @union_pay_merchant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /union_pay_merchants/1 or /union_pay_merchants/1.json
  def update
    respond_to do |format|
      upi_params = union_pay_merchant_params.merge(:edited_by => current_user.id)
      if @union_pay_merchant.update(upi_params)
        format.html { redirect_to union_pay_merchants_url, notice: "Union pay merchant was successfully updated." }
        format.json { render :show, status: :ok, location: @union_pay_merchant }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @union_pay_merchant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /union_pay_merchants/1 or /union_pay_merchants/1.json
  def destroy
    @union_pay_merchant.destroy
    respond_to do |format|
      format.html { redirect_to union_pay_merchants_url, notice: "Union pay merchant was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_union_pay_merchant
      @union_pay_merchant = UnionPayMerchant.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def union_pay_merchant_params
      params.require(:union_pay_merchant)
      .permit(:merchant_name,
      :address,
      :merchant_category,
      :merchant_accept_international_payment,
      :acquirer_one,
      :acquirer_two,
      :acquirer_three,
      :acquirer_four,
      :acquirer_five,
      :contactless_upi_accepted,
      :contactless_why_upi_not_accepted,
      :contactless_purchase_transaction_result,
      :contactless_other_card_schemes_accepted,
      :contactless_test_scenario,
      :chip_in_pos_upi_accepted,
      :chip_in_pos_why_upi_not_accepted,
      :chip_in_pos_purchase_transaction_result,
      :chip_in_pos_other_card_schemes_accepted,
      :chip_in_pos_test_scenario,
      :swipe_upi_accepted,
      :swipe_why_upi_not_accepted,
      :swipe_purchase_transaction_result,
      :swipe_other_card_schemes_accepted,
      :swipe_test_scenario,
      :upi_decal_displayed_before_visit,
      :upi_decal_displayed_after_visit,
      :is_contactless_mark_shown_upi_single_decal,
      :is_visa_or_mastercard_contactless_mark_shown_on_single_decal,
      :is_contactless_mark_shown_on_integrated_decal,
      :is_visa_or_mastercard_displayed,
      :special_comments,
      :contactless_code,
      :chip_in_pos_code,
      :swipe_code)
    end

    def verify_promoter_credentials
      unless current_user.is_promoter && current_user.works_with_upi_merchants
        flash[:alert] = "Ooooops ... You don't work with merchants"
        redirect_to user_path(current_user)
      end
    end

    def authenticate_user
      if current_user.nil?
        redirect_to new_user_session_path
      end
    end
end
