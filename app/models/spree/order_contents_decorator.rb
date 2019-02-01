module Spree
  OrderContents.class_eval do

    def add(variant, quantity = 1, options = {})
      timestamp = Time.current
      if variant.parts.any? && variant.product.add_parts_individually
        line_items = add_parts_individually(variant, quantity, options)
        line_items.each do |line_item|
          options[:line_item_created] = (timestamp <= line_item.created_at)
          after_add_or_remove(line_item, options)
        end
        line_items.last
      else
        line_item = add_to_line_item(variant, quantity, options)
        options[:line_item_created] = true if timestamp <= line_item.created_at
        after_add_or_remove(line_item, options)
      end
    end


    def add_to_line_item(variant, quantity, options = {})
      line_item = grab_line_item_by_variant(variant, false, options)

      if line_item && part_variants_match?(line_item, variant, quantity, options)
        line_item.quantity += quantity.to_i
        line_item.currency = currency unless currency.nil?
      else
        opts = { currency: order.currency }.merge(whitelist(options))
        line_item = order.line_items.new(quantity: quantity,
                                          variant: variant,
                                          options: opts)
      end

      line_item.target_shipment = options[:shipment] if options.has_key? :shipment
      line_item.save!

      line_item
    end

    def add_to_line_item_with_parts(variant, quantity, options = {})
      add_to_line_item_without_parts(variant, quantity, options).
        tap do |line_item|
        populate_part_line_items(
          line_item,
          variant.parts_variants,
          options["selected_variants"]
        )
      end
    end

    alias_method :add_to_line_item_without_parts, :add_to_line_item
    alias_method :add_to_line_item, :add_to_line_item_with_parts

    private

    def add_parts_individually(variant, quantity, options = {})
      variant.parts_variants.map do |part_variant|
        selected_variants = options[:selected_variants]
        variant_id = variant_id_for(part_variant, selected_variants)
        qty = part_variant.count * quantity

        # uses add_to_line_item to ensure any other extensions overriding that method
        # are also triggered and to ensure items are matched to existing cart items
        add_to_line_item(Spree::Variant.find(variant_id), qty, options)
      end
    end

    def part_variants_match?(line_item, variant, quantity, options)
      if line_item.parts.any? && options["selected_variants"]
        selected_variant_ids = options["selected_variants"].values.map(&:to_i)
        matched = part_variant_ids(line_item) & selected_variant_ids

        matched == selected_variant_ids
      else
        true
      end
    end

    def part_variant_ids(line_item)
      line_item.part_line_items.map(&:variant_id)
    end

    def populate_part_line_items(line_item, parts, selected_variants)
      parts.each do |part|
        part_line_item = line_item.part_line_items.find_or_initialize_by(
          line_item: line_item,
          variant_id: variant_id_for(part, selected_variants)
        )

        part_line_item.update_attributes!(quantity: part.count)
      end
    end

    def variant_id_for(part, selected_variants)
      if part.variant_selection_deferred?
        selected_variants[part.part.id.to_s]
      else
        part.part.id
      end
    end

    def whitelist(params)
      if params.is_a? ActionController::Parameters
        params.permit(PermittedAttributes.line_item_attributes)
      else
        params.slice(*PermittedAttributes.line_item_attributes)
      end
    end
  end
end
