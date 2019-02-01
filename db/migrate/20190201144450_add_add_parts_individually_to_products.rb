class AddAddPartsIndividuallyToProducts < SpreeExtension::Migration[4.2]

  def self.up
    table = if table_exists?(:products)
      'products'
    elsif table_exists?(:spree_products)
      'spree_products'
    end

    change_table(table) do |t|
      t.column :add_parts_individually, :boolean, :default => false, :null => false
    end
  end

  def self.down
    table = if table_exists?(:products)
      'products'
    elsif table_exists?(:spree_products)
      'spree_products'
    end

    change_table(table) do |t|
      t.remove :add_parts_individually
    end
  end

end
