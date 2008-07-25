class RemoveYubicoIdentityFromAccount < ActiveRecord::Migration
  def self.up
    remove_column :accounts, :yubico_identity
    remove_column :accounts, :last_authenticated_with_yubikey
  end

  def self.down
    add_column :accounts, :yubico_identity, :string, :limit => 12
    add_column :account, :last_authenticated_with_yubikey, :boolean
  end
end
