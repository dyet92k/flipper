require 'moneta'

module Flipper
  module Adapters
    class Moneta
      include ::Flipper::Adapter

      FEATURES_KEY = :flipper_features

      # Public: The name of the adapter.
      attr_reader :name

      # Public
      def initialize(moneta)
        @moneta = moneta
        @name = :moneta
      end

      # Public:  The set of known features
      def features
        moneta[FEATURES_KEY] || Set.new
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        moneta[FEATURES_KEY] = features << feature.key.to_s
        true
      end

      # Public: Removes a feature from the set of known features and clears
      # all the values for the feature.
      def remove(feature)
        moneta[FEATURES_KEY] = features.delete(feature.key.to_s)
        moneta.delete(key(feature.key))
        true
      end

      # Public: Clears all the gate values for a feature.
      def clear(feature)
        moneta[key(feature.key)] = default_config
        true
      end

      # Public: Gets the values for all gates for a given feature.
      #
      # Returns a Hash of Flipper::Gate#key => value.
      def get(feature)
        default_config.merge(moneta[key(feature.key)].to_h)
      end

      # Public: Get all features and gate values in one call. Defaults to one call
      # to features and another to get_multi. Feel free to override per adapter to
      # make this more efficient.
      def get_all
        instances = features.map { |key| build_feature(key) }
        get_multi(instances)
      end

      # Public: Get multiple features in one call. Defaults to one get per
      # feature. Feel free to override per adapter to make this more efficient and
      # reduce network calls.
      def get_multi(features)
        result = {}
        features.each do |feature|
          result[feature.key] = get(feature)
        end
        result
      end

      # Public: Enables a gate for a given thing.
      #
      # feature - The Flipper::Feature for the gate.
      # gate - The Flipper::Gate to disable.
      # thing - The Flipper::Type being enabled for the gate.
      #
      # Returns true.
      def enable(feature, gate, thing)
        case gate.data_type
        when :boolean, :integer
          result = get(feature)
          result[gate.key] = thing.value.to_s
          moneta[key(feature.key)] = result
        when :set
          result = get(feature)
          result[gate.key] << thing.value.to_s
          moneta[key(feature.key)] = result
        end
        true
      end

      # Public: Disables a gate for a given thing.
      #
      # feature - The Flipper::Feature for the gate.
      # gate - The Flipper::Gate to disable.
      # thing - The Flipper::Type being disabled for the gate.
      #
      # Returns true.
      def disable(feature, gate, thing)
        case gate.data_type
        when :boolean
          clear(feature)
        when :integer
          result = get(feature)
          result[gate.key] = thing.value.to_s
          moneta[key(feature.key)] = result
        when :set
          result = get(feature)
          result[gate.key] = result[gate.key].delete(thing.value.to_s)
          moneta[key(feature.key)] = result
        end
        true
      end

      private

      def key(feature_key)
        "#{FEATURES_KEY}/#{feature_key}"
      end

      attr_reader :moneta
    end
  end
end