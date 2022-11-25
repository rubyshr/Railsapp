# frozen_string_literal: true

# Common methods for the Lot API and views
module LotCommonMethods
  def send_award_notice
    participants = @event.selected_award_participant(params[:participant_list])
    selected_lot_ids = lots_list_params.to_h.map { |_k, v| v[:lot_id] }
    send_award_notice_email(participants)
    Lot.update_lots_to_notify(selected_lot_ids, true)
    # Because we use API only controller for our Rails API which doesnt include
    # this respond_to method
    if defined?(respond_to)
      respond_to { |format| format.js { render :send_award_notice } }
    else
      render json: {
        lots: @lots,
        award_notifications: @event.award_notifications,
        award_notification_messages: @event.award_notification_messages,
        award_notification_footer: @event.award_notification_message_footer
      }
    end
  end

  def lots_list_params
    params.require(:lots_list).permit! if params[:lots_list].present?
  end

  def set_lots_without_event_total_lot
    @lots = @event.lots.without_event_total
  end

  def award_notice_email(params, participant, message)
    AwardLots::AwardNoticeEmail.new(params, participant, message)
  end
end
