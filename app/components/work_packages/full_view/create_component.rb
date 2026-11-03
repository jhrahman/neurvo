# frozen_string_literal: true

module WorkPackages
  module FullView
    class CreateComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(type:, project:, default_project: nil)
        super()

        @type = type
        @project = project
        @default_project = default_project
      end
    end
  end
end
