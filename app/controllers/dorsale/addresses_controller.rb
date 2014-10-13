require_dependency "dorsale/application_controller"

module Dorsale
  class AddressesController < ApplicationController
    before_action :set_address, only: [:show, :edit, :update, :destroy]

    # GET /addresses
    def index
      @addresses = Address.all
    end

    # GET /addresses/1
    def show
    end

    # GET /addresses/new
    def new
      @address = Address.new
    end

    # GET /addresses/1/edit
    def edit
    end

    # POST /addresses
    def create
      @address = Address.new(address_params)

      if @address.save
        redirect_to @address, notice: 'Address was successfully created.'
      else
        render action: 'new'
      end
    end

    # PATCH/PUT /addresses/1
    def update
      if @address.update(address_params)
        redirect_to [dorsale, @address], notice: 'Address was successfully updated.'
      else
        render action: 'edit'
      end
    end

    # DELETE /addresses/1
    def destroy
      @address.destroy
      redirect_to dorsale.addresses_url, notice: 'Address was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_address
        @address = Address.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def address_params
        params.require(:address).permit(:street, :street_bis, :city, :zip, :country)
      end
  end
end
