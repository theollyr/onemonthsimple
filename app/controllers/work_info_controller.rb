class WorkInfoController < ApplicationController
  def index
    @user = current_user
    if !(@user) || @user.admin
      flash[:error] = "Sorry, no user with that user id exists"
      redirect_to home_dashboard_index_path
    end
  end
end
