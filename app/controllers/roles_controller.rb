# frozen_string_literal: true

class RolesController < ApplicationController
  filter_resource_access
  helper :application
  layout 'admin'

  def index
    @roles = Role.all

    respond_to do |format|
      format.html { render 'index' }
      format.xml  { render xml: @roles }
    end
  end

  # GET /roles/1
  # GET /roles/1.xml
  def show
    @role = Role.find(params[:id])
    @users = User.all

    respond_to do |format|
      format.html { render 'show' }
      format.xml  { render xml: @role }
    end
  end

  # GET /roles/1/edit
  def edit
    @role = Role.find(params[:id])
    @users = User.all # TODO: where { :role == @role.id }
  end

  # PUT /roles/1
  # PUT /roles/1.xml
  def update
    @role = Role.find(params[:id])

    respond_to do |format|
      if @role.update(role_params)
        flash[:notice] = t(:role_updated)
        format.html { redirect_to(@role) }
        format.xml  { head :ok }
      else
        format.html { render 'edit' }
        format.xml  { render xml: @role.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /roles/1
  # DELETE /roles/1.xml
  def destroy
    @role = Role.find(params[:id])
    @role.destroy

    respond_to do |format|
      format.html { redirect_to(roles_url) }
      format.xml  { head :ok }
    end
  end

  def new_role_from_params
    @role = Role.new(role_params)
  end

  private

  def role_params
    params.require(:role).permit(:role) if params[:role].present?
  end
end
