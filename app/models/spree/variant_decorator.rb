Spree::Variant.class_eval do
  has_many :parts_variants, class_name: "Spree::AssembliesPart", foreign_key: "assembly_id"
  has_many :assemblies_variants, class_name: "Spree::AssembliesPart", foreign_key: "part_id"

  has_many :assemblies, through: :assemblies_variants, class_name: "Spree::Variant", dependent: :destroy
  has_many :parts, through: :parts_variants, class_name: "Spree::Variant", dependent: :destroy

  def assemblies_for(products)
    assemblies.where(id: products)
  end

  def part?
    assemblies.exists?
  end

  # this computes how many assemblies are actually available for a variant by looking at the
  # total on hand for all parts and deferred variant parts
  def total_assemblies_available
    if is_master? && product.has_variants?
      # total avail is the sum of all variants on the master's product
      product.variants.map { |v| v.total_assemblies_available }.sum
    else
      # for a variant, the total available is bottlenecked by the least available part
      parts_variants.map(&:total_assemblies_available).min
    end
  end
end
