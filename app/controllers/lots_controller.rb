# frozen_string_literal: true

class LotsController < ApplicationController
  include LotCommonMethods

  before_action :new_lot_from_params, only: %i[create]
  after_action :reset_event_total_lot, only: :destroy
  before_action :recover_lots, only: [:index]

  helper :application
  layout 'admin' # 'application_for_current_event'


  # GET /lots/1
  # GET /lots/1.xml
  def show
    respond_to do |format|
      format.html { render layout: false } # show.html.erb
      format.xml  { render xml: @lot }
      format.js   { render 'show' }
    end
  end

  # GET /lots/new
  # GET /lots/new.xml
  def new
    @lot = @event.lots.new
    @upload_from_csv = params[:upload_from_csv]
    set_values_for_lot
    respond_to do |format|
      format.html { render @lot, layout: false } # new.html.erb
      format.xml  { render xml: @lot }
      format.js   { render 'new' }
    end
  end

  # GET /lots/1/edit
  def edit
    @edit_current_price = @event.is_completed? || @event.simple_lot_rfq_completed?
    set_values_for_lot
    respond_to do |format|
      format.html { render layout: false } # new.html.erb
      format.xml  { render xml: @lot }
      format.js   { render 'edit' }
    end
  end

  # POST /lots
  # POST /lots.xml
  def create
    respond_to do |format|
      if @lot.save
        @event.reload
        flash[:notice] = t(:lot_created)
        @redirect_url = if @lot.complex_structure
                          event_advanced_lots_url(@lot.event_id)
                        else
                          event_lots_url(@lot.event_id)
                        end
        format.html { redirect_to(@redirect_url) }
        format.xml  { render xml: @lot, status: :created, location: @lot }
      else
        format.html { render 'new' }
        format.xml  { render xml: @lot.errors, status: :unprocessable_entity }
      end
      format.js { render 'create' }
    end
  end

  # PUT /lots/1
  # PUT /lots/1.xml
  def update
    @event = @lot.event
    retrieve_event_participants
    respond_to do |format|
      if @lot.update(lot_params)
        @event.reload
        @event_total_lot = @event.event_total_lot
        flash[:notice] = t(:lot_updated)
        format.html { redirect_to(event_lots_url(@lot.event_id)) }
        format.xml  { head :ok }
      else
        format.html { render 'edit' }
        format.xml  { render xml: @lot.errors, status: :unprocessable_entity }
      end
      format.js { render 'update' }
    end
  end

  def destroy_all
    lots_ids = params[:selected_lot_ids].split(',')
    @event.lots.where(id: lots_ids).map(&:really_destroy!)
    respond_to do |format|
      format.html do
        flash[:notice] = t(:deleted_lot_message)
        redirect_back(
          fallback_location: destroy_all_event_lots_path(@event)
        )
      end
    end
  end

  def award
    @lots = @event.lots.where(is_event_total: false)
    if current_user.show_award_lot_msg
      flash[:notice] = t(:show_welcome_msg_to_host)
      current_user.update_column(:show_award_lot_msg, false)
    end
    respond_to do |format|
      format.js { render 'award' }
    end
  end

  private

  # Need to reset being_destroyed flag so other functionality show works fine.
  def reset_event_total_lot
    @event_total_lot
        &.update_column('being_destroyed', false)
  end

  def new_lot_from_params
    @lot = Lot.new(lot_params)
  end

  def load_lot
    @lot = Lot.find(params[:id])
  end


  def completed_lot_params
    params.require(:lot).permit(:current_price)
          .delocalize(current_price: :number)
  end

  def recover_lots
    return unless params[:lots_relevant] == 'true'

    @event.recover_deleted_lots
    @event.lots.reload
  end

  def retrieve_event_participants
    if @event.simple_lot_rfq_completed?
      @event_round = EventRound.find_by(id: params[:event_round])
      @event_participants = @event.event_participants_for_event(@event_round)
    elsif @event.is_completed?
      @event_participants = @event.active_or_participating_participants
    end
  end
end
