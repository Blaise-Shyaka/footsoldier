class UnionPayMerchantsController < ApplicationController
  before_action :set_union_pay_merchant, only: %i[ show edit update destroy ]

  # GET /union_pay_merchants or /union_pay_merchants.json
  def index
    @union_pay_merchants = current_user.union_pay_merchants
  end

  # GET /union_pay_merchants/1 or /union_pay_merchants/1.json
  def show
  end

  # GET /union_pay_merchants/new
  def new
    @union_pay_merchant = UnionPayMerchant.new
  end

  # GET /union_pay_merchants/1/edit
  def edit
  end

  # POST /union_pay_merchants or /union_pay_merchants.json
  def create
    @union_pay_merchant = UnionPayMerchant.new(union_pay_merchant_params)

    respond_to do |format|
      if @union_pay_merchant.save
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
      if @union_pay_merchant.update(union_pay_merchant_params)
        format.html { redirect_to @union_pay_merchant, notice: "Union pay merchant was successfully updated." }
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
      params.fetch(:union_pay_merchant, {})
    end
end
