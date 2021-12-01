class ChefWumujyisController < ApplicationController
  before_action :set_chef_wumujyi, only: %i[ show edit update destroy ]
  before_action :verify_promoter_credentials
  before_action :validate_promoter_input, only: %i[edit update create]

  # GET /chef_wumujyis or /chef_wumujyis.json
   def index
    @chef_wumujyis = current_user.chef_wumujyis
  end

  # GET /chef_wumujyis/1 or /chef_wumujyis/1.json
  def show
  end

  # GET /chef_wumujyis/new
  def new
    @chef_wumujyi = current_user.chef_wumujyis.new
  end

  # GET /chef_wumujyis/1/edit
  def edit
  end

  # POST /chef_wumujyis or /chef_wumujyis.json
  def create
    @chef_wumujyi = current_user.chef_wumujyis.new(chef_wumujyi_params)

    respond_to do |format|
      if @chef_wumujyi.save
        format.html { redirect_to @chef_wumujyi, notice: "Chef wumujyi was successfully created." }
        format.json { render :show, status: :created, location: @chef_wumujyi }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chef_wumujyi.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /chef_wumujyis/1 or /chef_wumujyis/1.json
  def update
    respond_to do |format|
      if @chef_wumujyi.update(chef_wumujyi_params)
        format.html { redirect_to @chef_wumujyi, notice: "Chef wumujyi was successfully updated." }
        format.json { render :show, status: :ok, location: @chef_wumujyi }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @chef_wumujyi.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chef_wumujyis/1 or /chef_wumujyis/1.json
  def destroy
    @chef_wumujyi.destroy
    respond_to do |format|
      format.html { redirect_to chef_wumujyis_url, notice: "Chef wumujyi was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chef_wumujyi
      @chef_wumujyi = ChefWumujyi.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def chef_wumujyi_params
      params.require(:chef_wumujyi).permit(:coupon_number, :vehicle_type, :fueled_value, :plate_number, :customer_name, :telephone_number, :service_station_name)
    end

    def verify_promoter_credentials
      unless current_user.is_promoter && current_user.works_with_engen
        flash[:alert] = "Ooooops ... You don't work with Engen"
        redirect_to user_path(current_user)
      end
    end

    def validate_promoter_input
      @chef_wumujyi = current_user.chef_wumujyis.new(chef_wumujyi_params)

      if chef_wumujyi_params[:vehicle_type] === 'Moto Driver' && Integer(chef_wumujyi_params[:fueled_value]) < 5000
        flash[:alert] = "Error! Minimum fuel value for a Moto Driver is 5,000Rwf"
        render "chef_wumujyis/new"
      elsif chef_wumujyi_params[:vehicle_type] === 'Taxi Driver' && Integer(chef_wumujyi_params[:fueled_value]) < 20000
        flash[:alert] = "Error! Minimum fuel value for a Taxi Driver is 20,000Rwf"
        render "chef_wumujyis/new"
      elsif chef_wumujyi_params[:vehicle_type] === 'Bus Driver' && Integer(chef_wumujyi_params[:fueled_value]) < 50000
        flash[:alert] = "Error! Minimum fuel value for a Bus Driver is 50,000Rwf"
        render "chef_wumujyis/new"
      elsif chef_wumujyi_params[:vehicle_type] === 'Truck Driver' && Integer(chef_wumujyi_params[:fueled_value]) < 100000
        flash[:alert] = "Error! Minimum fuel value for a Truck Driver is 100,000Rwf"
        render "chef_wumujyis/new"
      elsif chef_wumujyi_params[:vehicle_type] === 'Private' && Integer(chef_wumujyi_params[:fueled_value]) < 20000
        flash[:alert] = "Error! Minimum fuel value for a Private car is 20,000Rwf"
        render "chef_wumujyis/new"
      end
    end
end
