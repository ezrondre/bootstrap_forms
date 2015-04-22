require 'bootstrap_forms/bootstrap_form_builder'
require 'bootstrap_forms/bootstrap_form_helper'

module BootstrapForms
end

ActionView::Base.send :include, BootstrapForms::BootstrapFormHelper
