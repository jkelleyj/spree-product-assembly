module SpreeProductAssembly
  module DefaultRefundAmountExtensions

    def compute(return_item)
      super.round(2)
    end

    def percentage_of_line_item(inventory_unit_or_return_item)
      percentage_of_line_item_with_assembly(inventory_unit_or_return_item) || super
    end

    protected

    # Handle some spree version nuances and also assembly nuance.
    # 1) Spree 3.3 added quantity to InventoryUnit
    # 2) Spree 3.3 addd return_quantity to ReturnItem
    # 3) Spree 3.3 passes a return_item to method, while < 3.2 passes an inventory_unit
    def percentage_of_line_item_with_assembly(inventory_unit_or_return_item)
      if inventory_unit_or_return_item.is_a?(Spree::InventoryUnit)
        percentage_of_line_item_from_inventory_unit(inventory_unit_or_return_item)
      else
        percentage_of_line_item_from_return_item(inventory_unit_or_return_item)
      end
    end

    # Spree 3.2 or earlier, inventory units always had 1 unit
    def percentage_of_line_item_from_inventory_unit(inventory_unit)
      compute_percentage_for_assembly(1, inventory_unit.line_item, inventory_unit.variant)
    end

    # Spree 3.3 or later
    def percentage_of_line_item_from_return_item(return_item)
      compute_percentage_for_assembly(
        return_item.return_quantity,
        return_item.inventory_unit.line_item,
        return_item.variant
      )
    end

    def compute_percentage_for_assembly(number_of_units, line_item, variant)
      return unless line_item.product.assembly?

      variant_quantity_hash = line_item.quantity_by_variant

      list_total = 0
      variant_quantity_hash.each_pair do |v, ct|
        list_total = list_total + BigDecimal.new(v.price) * ct
      end

      (number_of_units * variant.price / BigDecimal.new(list_total)).round(3)
    end
  end
end
