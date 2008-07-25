class RemoveActivationFields < ActiveRecord::Migration
  def self.up
    remove_column :accounts, :activation_code
    remove_column :accounts, :activated_at
  end

  def self.down
    add_column :accounts, :activation_code, :string, :limit => 40
    add_column :accounts, :activated_at, :datetime
  end
end
