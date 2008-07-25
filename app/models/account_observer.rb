class AccountObserver < ActiveRecord::Observer

  def after_create(account)
    account.personas.new(:title => "Standard").update_attribute(:deletable, false) if account.recently_created?
  end
  
  def after_save(account)
    AccountMailer.deliver_forgot_password(account) if account.recently_forgot_password?
  end
  
end
