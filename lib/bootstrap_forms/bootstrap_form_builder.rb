require 'action_view/helpers/form_helper'
require 'action_view/helpers/tag_helper'

module BootstrapForms
  class BootstrapFormBuilder < ActionView::Helpers::FormBuilder

    class_attribute :allowed_designs, :allowed_label_styles
    self.allowed_designs = [:table, :default]
    self.allowed_label_styles = [:default, :placeholder, :both]

    (field_helpers - [:label, :hidden_field, :radio_button, :fields_for, :select, :file_field, :submit, :check_box]).each do |selector|
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__+1
      def #{selector}(method, *args)
        html_options = build_html_options_in_args!(args)
        options = args.detect{|opt| opt.is_a?(Hash)}
        html_options[:placeholder] = label(method, options[:label]).gsub(/<.*>(.*)<.*>/, '\\1')
        return super(method, *args) if without_label?(options)
        @row_builder.get_row(label(method, options[:label]), super(method,*args))
      end
      RUBY_EVAL
    end

    def submit(*args)
      html_options = build_html_options_in_args!(args)
      html_options[:class] = html_options[:class].sub(/form-control/, 'btn btn-default')
      options = args.detect{|opt| opt.is_a?(Hash)}
      return super(*args)
    end

    def radio_button(method, tag_value, *args)
      return super(method, *args) if @capture_mode
      @template.label_tag do
        super(method, tag_value, *args) +
        label( method.to_s + '_' + tag_value.to_s )
      end
    end

    def check_box(method, *args)
      html_options = build_html_options_in_args!(args)
      options = args.detect{|opt| opt.is_a?(Hash)}
      html_options[:class] = html_options[:class].sub(/form-control/, '')
      return super(method, *args) if without_label?(options)
      @row_builder.get_row(label(method, options[:label]), super(method,*args))
    end

    def label(*args)
      result = super(*args)
      @row_builder.label = result if @capture_mode
      result
    end

    def field(*args, &block)
      method = args.shift if args.count >= 1 && !args.first.is_a?(Hash)

      html_options = build_html_options_in_args!(args)
      if @capture_mode
        @row_builder.content = @template.capture(self, &block)
      else
        raise 'You have to provide an method name if you are not in capture mode!' unless method
        @capture_mode = true
        @row_builder.get_row(label(method, options[:label]), @template.capture(self, &block))
      end
    ensure
      @capture_mode = false
    end

    def date_select(method, *args)
      html_options = build_html_options_in_args!(args)
      html_options.merge!(:with_css_classes => true, :date_separator => '<div class="select_separator">&nbsp;</div>')
      element = @template.content_tag(:div, super(method, *args) , :class => 'field_wrapper date_selects')
      return element if @capture_mode

      options = args.detect{|opt| opt.is_a?(Hash)}
      @row_builder.get_row(label(method, options[:label]), element)
    end

    def select(method, *args)
      build_html_options_in_args!(args)
      element = @template.content_tag(:div, super(method, *args), :class => 'designed_select')

      return element if @capture_mode
      options = args.detect{|opt| opt.is_a?(Hash)}
      @row_builder.get_row(label(method, options[:label]), element)
    end

    def collection_select(method, *args)
      build_options_and_html_options_in_args!(args)
      element = @template.content_tag(:div, super(method, *args), :class => 'designed_select')

      return element if @capture_mode
      options = args.detect{|opt| opt.is_a?(Hash)}
      @row_builder.get_row(label(method, options[:label]), element)
    end

    def radio_button_select(method, choices, options={})
      s = ''
      choices.each do |value, label_string|
        s << @template.content_tag(:span,
              radio_button(method, value, @default_html_option.merge(options)) +
              label("#{method}_#{value}", label_string),
            :class => 'radio_wrapper'
          )
      end
      return s.html_safe if @capture_mode
      @row_builder.get_row(label(method), s.html_safe)
    end

    def fields_for(record_name, record_object=nil, field_options={}, &block)
      field_options, record_object = record_object, nil if record_object.is_a?(Hash) && record_object.extractable_options?
      field_options = build_html_options(field_options)
      content = nil
      content = super(record_name, record_object, field_options, &block)

      return content if @capture_mode || field_options[:no_label]
      @row_builder.get_row(label(record_name, field_options[:label]), content)
    end

    def bootstrap_fields_for(*args, &block)
      args << {} unless args.last.is_a?(Hash)
      options = args.last
      options[:builder] = self.class
      # options[:no_label] = true if options[:no_label].nil?
      fields_for(*args, &block)
    end

    def sectioned_fields_for(*args, &block)
      form_section(:inner => :true) do |form|
        form.fields_for(*args, &block)
      end
    end

    def file_field(field_name, options)
      @template.content_tag(:div, class: 'input-group') do
        res = ''.html_safe
        res << @template.content_tag(:span, class: 'fake-fileinput btn btn-default form-control') do
          s = ''.html_safe
          s << label(field_name, options[:label])
          s << super(field_name, options)
          s
        end
        res << @template.content_tag(:span, @template.content_tag(:i, '', class: 'glyphicon glyphicon-folder-open' ), class: 'input-group-addon')
        res
      end
    end

    def clonned_fields_for(field_name, objects_hash = nil, options={}, &block)
      objects_hash ||= @object.send(field_name)
      objects_hash['1'] = nil if objects_hash.empty?
      @template.content_tag(:div, :class => "clonnable_fields#{' form-inline' if options[:inline]}", :data => {:last_key => objects_hash.keys.max }) do
        s = ''
        objects_hash.each do |key, object|
          options[:index] = key
          s << @template.content_tag(:div, :class => "fields fields-#{key}", :data => {:key => key} ) do
              fields_for(field_name, object, options, &block)
            end
        end
        options[:index] = 'TEMPLATE'
        s << @template.content_tag(:div, :class => 'template_fields') do
          fields_for(field_name, options, &block)
        end
        s.html_safe
      end
    end

    def initialize(*args)
      options = args.last.is_a?(Hash) ? args.last : {}
      @design = options[:design] || :default
      @label_style = options[:label_style] || :label

      @default_html_option = options[:default_html_option] || {}
      @default_html_option[:class] = @default_html_option[:class] ? 'form-control ' + @default_html_option[:class] : 'form-control'

      super

      @row_builder = instantiate_row_builder(@design, @label_style)
    end

    def design=(design)
      raise ArgumentError, "design #{design} is not allowed" unless self.class.allowed_designs.include?(design)
      @design = design
      @row_builder = instantiate_row_builder(@design, @label_style)
    end

    def label_style=(label_style)
      raise ArgumentError, "design #{design} is not allowed" unless self.class.allowed_label_styles.include?(label_style)
      @label_style = label_style
      @row_builder = instantiate_row_builder(@design, @label_style)
    end

    def form_section(options={}, &block)
      @section_opened = true
      @default_html_option.merge!(:readonly => options[:disabled])
      options[:class] = "#{options[:class]} designed_form_section #{'disabled' if options[:disabled]}"
      @section_options = options unless options[:inner]
      @template.content_tag(containing_tag_name.to_sym, @template.capture(self, &block), options)
    ensure
      @section_opened, @section_options = false, nil unless options[:inner]
      @default_html_option.merge!(:disabled => false)
    end

    def section_enable(label, options={})
      raise 'Cannot enable section outside of it' unless @section_opened
      return unless @section_options[:disabled]
      options[:class] = "#{options[:class]} designed_form_section_enabler"
      @template.content_tag(:span, label, options)
    end

    def row(&block)
      @capture_mode = true
      yield(self)
      @row_builder.get_row(nil,nil)
    ensure
      @capture_mode = false
    end

    private

      def containing_tag_name
        case @design
        when :default
          :fieldset
        when :box
          :div
        end
      end

      def instantiate_row_builder(design, label_style, *args)
        BootstrapRowBuilder.new(design, label_style, @template, *args)
      end

      def build_html_options(options)
        @default_html_option.merge(options) do |key, oldval, newval |
          case key
            when :class
              "#{oldval} #{newval}"
            else
              newval
          end
        end
      end

      def build_html_options_in_args!(args)
        html_options = args.last.is_a?(Hash) ? args.pop : {}
        args << build_html_options(html_options)
        args.last
      end

      def build_options_and_html_options_in_args!(args)
        options = args.detect{|arg| arg.is_a?(Hash)}
        unless options
          options ||= {}
          args << options
        end
        if options.equal?(args.last)
          args << {}
        end
        build_html_options_in_args!(args)
      end

      def with_set_capture_mode(capture_mode=true)
        cm_was, @capture_mode = @capture_mode, capture_mode
        yield
      ensure
        @capture_mode = cm_was
      end

      def without_label?(field_options)
        @label_style == :placeholder || @capture_mode || field_options[:no_label]
      end

  end

  class BootstrapRowBuilder
    include ActionView::Helpers::TagHelper

    attr_writer :label
    attr_accessor :content

    attr_reader :design

    def initialize(design, label_style, template)
      @design, @label_style, @template = design, label_style, template
    end

    def row_wrapper_tag(options={}, &block)
      tag = case design
      when :default
        default_class = 'form-group'
        :div
      end
      options[:class] = (options[:class] ? options[:class].to_s + ' ' : '') + default_class unless default_class.blank?

      @template.content_tag(tag, options, &block)
    end

    def field_wrapper_tag(options={}, &block)
      tag = case design
      when :default
        default_class = 'controls'
        :div
      end
      options[:class] = (options[:class] ? options[:class].to_s + ' ' : '') + default_class unless default_class.blank?

      if block_given?
        @template.content_tag(tag, options, &block)
      else
        tag
      end
    end

    def get_row(label, content, options={})
      @label ||= label
      @content ||= content
      build_row(options)
    end

    def row_fields(label, builder, &block)
      @label = label
      @content = capture(builder, &block)
      build_row
    end

    private
      def build_row(options)
        raise StandardError, "label or content wasn't set" unless @label && @content
        row_wrapper_tag do
          row = ''
          row << @label
          row << ' '
          row << @content

          row.html_safe
        end
      ensure
        @label = nil
        @content = nil
      end

      # def method_missing(name, *attrs, &block)
      #   if @receiver && @receiver.respond_to?(name)
      #     @receiver.send(name, *attrs, &block)
      #   else
      #     super
      #   end
      # end

  end
end
