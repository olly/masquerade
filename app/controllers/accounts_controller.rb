class AccountsController < ApplicationController
  
  before_filter :login_required, :except => [:show, :new, :create]
  
  def show
    @account = Account.find(:first, :conditions => ['login = ? AND enabled = ?', params[:account], true])
    raise ActiveRecord::RecordNotFound if @account.nil?
    
    respond_to do |format|
      format.html do
        response.headers['X-XRDS-Location'] = identity_url(:account => @account, :format => :xrds, :protocol => scheme)
      end
      format.xrds
    end
  end

  def edit
    @account = current_account
  end

  def update
    @account = current_account
    if @account.update_attributes(params[:account])
      flash[:notice] = t(:profile_updated)
      redirect_to edit_account_path(:account => current_account)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @account = current_account
    if @account.authenticated?(params[:confirmation_password])
      @account.disable!
      current_account.forget_me 
      cookies.delete :auth_token
      reset_session
      flash[:notice] = t(:account_disabled)
      redirect_to home_path
    else
      flash[:error] = t(:entered_password_is_wrong)
      redirect_to edit_account_path
    end
  end

  def change_password
    if Account.authenticate(current_account.login, params[:old_password])
      if ((params[:password] == params[:password_confirmation]) && !params[:password_confirmation].blank?)
        current_account.password_confirmation = params[:password_confirmation]
        current_account.password = params[:password]        
        if current_account.save
          flash[:notice] = t(:password_has_been_changed)
          redirect_to edit_account_path(:account => current_account)
        else
          flash[:error] = t(:sorry_password_couldnt_be_changed)
          redirect_to edit_account_path
        end
      else
        flash[:error] = t(:confirmation_of_new_password_invalid)
        @old_password = params[:old_password]
        redirect_to edit_account_path
      end
    else
      flash[:error] = t(:old_password_incorrect)
      redirect_to edit_account_path
    end 
  end
  
end
