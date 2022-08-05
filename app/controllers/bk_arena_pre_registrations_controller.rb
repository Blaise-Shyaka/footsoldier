class BkArenaPreRegistrationsController < ApplicationController
  before_action :set_bk_arena_pre_registration, only: %i[ show edit update destroy ]
  before_action :authenticate_user
  before_action :verify_promoter_credentials

  # GET /bk_arena_pre_registrations or /bk_arena_pre_registrations.json
  def index
    @bk_arena_pre_registrations = BkArenaPreRegistration.all
  end

  # GET /bk_arena_pre_registrations/1 or /bk_arena_pre_registrations/1.json
  def show
  end

  # GET /bk_arena_pre_registrations/new
  def new
    @bk_arena_pre_registration = BkArenaPreRegistration.new
  end

  # GET /bk_arena_pre_registrations/1/edit
  def edit
  end

  # POST /bk_arena_pre_registrations or /bk_arena_pre_registrations.json
  def create
    @bk_arena_pre_registration = BkArenaPreRegistration.new(bk_arena_pre_registration_params)

    respond_to do |format|
      if @bk_arena_pre_registration.save
        format.html { redirect_to @bk_arena_pre_registration, notice: "Bk arena pre registration was successfully created." }
        format.json { render :show, status: :created, location: @bk_arena_pre_registration }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @bk_arena_pre_registration.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /bk_arena_pre_registrations/1 or /bk_arena_pre_registrations/1.json
  def update
    respond_to do |format|
      if @bk_arena_pre_registration.update(bk_arena_pre_registration_params)
        format.html { redirect_to @bk_arena_pre_registration, notice: "Bk arena pre registration was successfully updated." }
        format.json { render :show, status: :ok, location: @bk_arena_pre_registration }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @bk_arena_pre_registration.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bk_arena_pre_registrations/1 or /bk_arena_pre_registrations/1.json
  def destroy
    @bk_arena_pre_registration.destroy
    respond_to do |format|
      format.html { redirect_to bk_arena_pre_registrations_url, notice: "Bk arena pre registration was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bk_arena_pre_registration
      @bk_arena_pre_registration = BkArenaPreRegistration.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def bk_arena_pre_registration_params
      params.require(:bk_arena_pre_registration).permit(
      :first_name,
      :last_name,
      :id_type,
      :id_number,
      :tel_no,
      :email,
      :gender,
      :spouse,
      :son_daughter,
      :parent,
      :brother_sister,
      :other,
      :province,
      :district,
      :sector,
      :cell,
      :village,
      :preferred_branch,
      )
    end

    def verify_promoter_credentials
      unless current_user.is_promoter && current_user.works_with_bk_arena
        flash[:alert] = "Ooooops ... You don't work on this project"
        redirect_to user_path(current_user)
      end
    end

    def authenticate_user
      if current_user.nil?
        redirect_to new_user_session_path
      end
    end
end
