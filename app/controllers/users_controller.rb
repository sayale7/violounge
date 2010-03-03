class UsersController < ApplicationController
  
  def index
    if params[:login_like]
      @users = User.login_like_or_user_common_street_like(params[:login_like])
      @users = @users + User.user_common_city_like(params[:login_like])
      @users = @users + User.user_common_state_like(params[:login_like])
      if params[:login_like].to_s.match(" ")
        split = params[:login_like].split(' ', 2)
        @user_commons = UserCommon.all(:conditions  => "firstname LIKE '%#{split.first}%' and lastname LIKE '%#{split.second}%'")
        @user_commons = @user_commons + UserCommon.all(:conditions  => "lastname LIKE '%#{split.first}%' and firstname LIKE '%#{split.second}%'")
        @user_commons.each do |user_common|
          @users = @users + User.find_all_by_id(user_common.user_id)
        end
      else
        @user_commons = UserCommon.firstname_like_or_lastname_like(params[:login_like])
        @user_commons.each do |user_common|
          @users = @users + User.find_all_by_id(user_common.user_id)
        end
      end
    else
      @users = User.all
    end
    @users = @users.uniq
    respond_to do |format|
      format.html 
      format.js
    end
  end
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(params[:user])
    if @user.save #signup!(params)
      @user.update_attribute(:active, true)
      @user_common = UserCommon.new
      if @user_common.save
        @user_common.update_attribute("user_id", @user.id)
      end
      # @user.deliver_activation_instructions!
      flash[:notice] = t("user.register_success")
      redirect_to login_url
    else
      render :action => :new
    end
  end
  
  def show
    if current_user
      if params[:id].to_s.eql?('current') || params[:id].to_s.eql?(current_user.id.to_s)
        @user = current_user
        @current_one = true
      else
        @user = User.find(params[:id])
        @current_one = false
      end
    else
      @user = User.find(params[:id])
      @current_one = false
    end
    @user_common = UserCommon.find_by_user_id(@user.id)
    @profile_image = ProfileImage.find_by_user_id(@user.id)
    @comment = Comment.new
    @comments = @user.comments
  end

  def edit
    if current_user
      @user = current_user
      @profile_image = ProfileImage.find_by_user_id(@user.id)
    else
      flash[:error] = t('common.access_denied')
      redirect_to root_url
    end
  end
  
  def update
    if current_user
      @user = current_user # makes our views "cleaner" and more consistent
      if @user.update_attributes(params[:user])
        @profile_image = ProfileImage.find_by_user_id(@user.id)
        flash[:notice] = "Account updated!"
        redirect_to user_path(@user)
      else
        render :action => :edit
      end
    else
      flash[:error] = t('common.access_denied')
      redirect_to root_url
    end
  end

  def destroy_user
    if current_user 
      @user = User.find(current_user)
      if @user.destroy
        flash[:notice] = t('common.destroyed')
        redirect_to root_url
      else
        flash[:error] = t('common.access_denied')
      end
    else
      flash[:error] = t('common.access_denied')
    end
  end
end