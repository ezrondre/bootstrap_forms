
module BootstrapForms
  module BootstrapFormHelper

    ALERT_TYPES = [:danger, :info, :success, :warning] unless const_defined?(:ALERT_TYPES)

    def bootstrap_flash(messages = nil)
      flash_messages = []
      (messages || flash).each do |type, message|
        # Skip empty messages, e.g. for devise messages set to nothing in a locale file.
        next if message.blank?

        type = type.to_sym
        type = :info if type == :notice
        type = :danger if type == :error
        next unless ALERT_TYPES.include?(type)

        Array(message).each do |msg|
          text = content_tag(:div,
                             content_tag(:button, raw("&times;"), :class => "close", "data-dismiss" => "alert") +
                             msg, :class => "alert fade in alert-#{type} alert-dismissible")
          flash_messages << text if msg
        end
      end
      flash_messages.join("\n").html_safe
    end

    def error_messages_for(record)
      return unless record
      messages = {error: []}
      errors_obj = record.is_a?(ActiveModel::Errors) ? record : record.errors

      errors_obj.full_messages.each do |message|
        messages[:error] << message
      end
      bootstrap_flash(messages)
    end


    def bootstrap_form_for(*args, &block)
      args << {} unless args.last.is_a?(Hash)
      options = args.last
      options[:html] ||= {}
      options[:html].merge!(:class => "bootsrap_form"){|key,val1,val2| val1.to_s+' '+val2 }
      options.merge!({:builder => Youmix::BootstrapFormBuilder})

      form_for(*args, &block)
    end

  end
end
