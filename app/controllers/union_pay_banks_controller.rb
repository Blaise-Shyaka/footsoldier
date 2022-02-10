class UnionPayBanksController < ApplicationController
  before_action :authenticate_user
  before_action :set_union_pay_bank, only: %i[ show edit update destroy ]
  before_action :verify_promoter_credentials

  # GET /union_pay_banks or /union_pay_banks.json
  def index
    @union_pay_banks = UnionPayBank.where(edited_by: nil)
  end

  # GET /union_pay_banks/1 or /union_pay_banks/1.json
  def show
  end

  # GET /union_pay_banks/new
  def new
    @union_pay_bank = UnionPayBank.new
  end

  # GET /union_pay_banks/1/edit
  def edit
  end

  # POST /union_pay_banks or /union_pay_banks.json
  def create
    @union_pay_bank = current_user.union_pay_banks.new(union_pay_bank_params)

    respond_to do |format|
      if @union_pay_bank.save
        format.html { redirect_to @union_pay_bank, notice: "Union pay bank was successfully created." }
        format.json { render :show, status: :created, location: @union_pay_bank }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @union_pay_bank.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /union_pay_banks/1 or /union_pay_banks/1.json
  def update
    respond_to do |format|
      upi_params = union_pay_bank_params.merge(edited_by: current_user.id)
      if @union_pay_bank.update(upi_params)
        format.html { redirect_to @union_pay_bank, notice: "Union pay bank was successfully updated." }
        format.json { render :show, status: :ok, location: @union_pay_bank }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @union_pay_bank.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /union_pay_banks/1 or /union_pay_banks/1.json
  def destroy
    @union_pay_bank.destroy
    respond_to do |format|
      format.html { redirect_to union_pay_banks_url, notice: "Union pay bank was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_union_pay_bank
      @union_pay_bank = UnionPayBank.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def union_pay_bank_params
      params.require(:union_pay_bank).permit(:bank_name, :atm_location, :upi_accepted, :why_test_not_allowed, :transaction_result, :transaction_code, :upi_decal_displayed_before_visit, :upi_decal_displayed_after_visit, :is_visa_or_mastercard_displayed, :special_comments)
    end

    def verify_promoter_credentials
      unless current_user.is_promoter && current_user.works_with_upi_banks
        flash[:alert] = "Ooooops ... You don't work with banks"
        redirect_to user_path(current_user)
      end
    end

    def authenticate_user
      if current_user.nil?
        redirect_to new_user_session_path
      end
    end
end
