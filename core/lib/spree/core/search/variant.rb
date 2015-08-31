module Spree
  module Core
    module Search
      class Variant

        class_attribute :search_terms
        self.search_terms = [
          :sku_cont,
          :product_name_cont,
          :product_slug_cont,
          :option_values_presentation_cont,
          :option_values_name_cont,
        ]

        class_attribute :search_term_filter
        self.search_term_filter = ->(word, terms) { terms } # default filter dosen't filter anything

        def initialize(query_string, scope: Spree::Variant.all)
          @query_string = query_string
          @scope = scope
        end

        # Searches the variants table using the ransack 'search_terms' defined on the class.
        # Each word of the query string is searched individually, matching by a union of the ransack
        # search terms, then we find the intersection of those queries, ensuring that each word matches
        # one of the rules.
        #
        # == Returns:
        # ActiveRecord::Relation of variants
        def results
          return @scope if @query_string.blank?

          matches = @query_string.split.map do |word|
            @scope.ransack(search_term_params(word)).result.pluck(:id)
          end

          Spree::Variant.where(id: matches.inject(:&))
        end

        private

        def search_terms(word, terms)
          self.class.search_term_filter.call(word, terms)
        end

        def search_term_params(word)
          terms = Hash[search_terms(word, self.class.search_terms).map { |t| [t, word] }]
          terms.merge(m: 'or')
        end
      end
    end
  end
end
