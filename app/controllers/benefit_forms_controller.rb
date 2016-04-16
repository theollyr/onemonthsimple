class BenefitFormsController < ApplicationController
  DOC_DIR = File.join('public', 'docs')
  DOC_FILES = Dir[File.join(DOC_DIR, '*')]

  def index
    @benefits = Benefits.new
  end

  def download
    if DOC_FILES.include?(params[:name])
      file = Rails.root.join(params[:name])
      send_file file, :disposition => 'attachment'
    else
      redirect_to user_benefit_forms_path(:user_id => current_user.user_id)
    end
  end

  def upload
    file = params[:benefits][:upload]
    if file
      flash[:success] = "File Successfully Uploaded!"
      Benefits.save(file, params[:benefits][:backup])
    else
      flash[:error] = "Something went wrong"
    end
    redirect_to user_benefit_forms_path(:user_id => current_user.user_id)
  end
end
