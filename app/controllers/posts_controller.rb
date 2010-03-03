class PostsController < ApplicationController
  
  uses_tiny_mce :options => {
                               :theme => 'advanced',
                               :plugins => %w{ safari spellchecker pagebreak style layer table save advhr advimage advlink emotions iespell inlinepopups insertdatetime preview media searchreplace print contextmenu paste directionality fullscreen noneditable visualchars nonbreaking xhtmlxtras template },
                               :theme_advanced_buttons1 => %w{save, bold italic underline strikethrough | justifyleft justifycenter justifyright justifyfull | styleselect formatselect fontselect fontsizeselect},
                               :theme_advanced_buttons2 => %w{cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,anchor,cleanup,help, image,|,code},
                               :theme_advanced_buttons3 => %w{ablecontrols,|,hr,removeformat,visualaid,|,sub,sup,|,charmap,emotions,iespell,media,advhr,|,print,|,ltr,rtl,|,fullscreen,insertdate,inserttime,preview,|,forecolor,backcolor},
                               :theme_advanced_buttons4 => %w{insertlayer,moveforward,movebackward,absolute,|,styleprops,spellchecker,|,cite,abbr,acronym,del,ins,attribs,|,visualchars,nonbreaking,template,blockquote,pagebreak,|,insertfile,insertimage},
                               :theme_advanced_toolbar_location => 'top',
                               :theme_advanced_toolbar_align => "left",
                               :theme_advanced_statusbar_location => "bottom",
                               :theme_advanced_resizing => true,
                               :force_br_newlines  =>  true
                             }
  # GET /posts
  # GET /posts.xml
  def index
    if params[:user_id]
      # blog from a specific user
      @posts = User.find(params[:user_id]).posts
    else
      unless params[:user_id_for_search].nil?
      # search on a specific user blog
        @posts = Post.from_date(from(params[:from]), to(params[:to])) 
        unless params[:search].to_s.eql?("")
          @posts = @posts & Post.title_like_or_body_like(params[:search])
        end
        @posts = @posts & User.find(params[:user_id_for_search]).posts
      else
      # search on all blogs
        @posts = Post.from_date(from(params[:from]), to(params[:to])) 
        if !params[:search].to_s.eql?("")
          @posts = @posts & Post.title_like_or_body_like_or_user_login_like(params[:search])
          get_all_user_ids(user_commons_searchlogic).each do |user_id|
            @posts = @posts + Post.find_all_by_user_id(user_id)
          end
        end
        @posts = @posts.uniq
      end
    end
    
    if params[:tag]
      @taggings = Tagging.find_all_by_tag_id(TagName.find(params[:tag]).tag_id)
      posts = Array.new
      @taggings.each do |tagging|
        posts = posts + Post.find_all_by_id(tagging.taggable_id)
      end
      @posts = @posts & posts
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @posts }
      format.atom
    end
  end
  
  
  def myblog
    @posts = Post.my_posts(current_user.id).from_date(from(params[:from]), to(params[:to]))
    if !params[:search].to_s.eql?("")
      @posts = @posts & Post.title_like_or_body_like(params[:search])
    end
    
    respond_to do |format|
      format.html # myblog.html.erb
      format.xml  { render :xml => @posts }
      format.atom
      format.js
    end
  end
  
  def add_tags
    @post = Post.find(params[:id])
    tags = Tag.find_all_by_id(params[:tags])
    tags.each do |tag|
      Tagging.find_or_create_by_tag_id_and_taggable_id_and_taggable_type(tag.id, @post.id, 'Post')
    end
    @not_in_post_tags = Tag.find_all_by_taggable_type('Post') - @post.tags
    unauthorized! if cannot? :manage, @post
    respond_to do |format|
      format.html { redirect_to('/posts/' + params[:id].to_s + '/edit') }
      format.js
    end
  end
  
  def remove_tags
    @post = Post.find(params[:id])
    tags = Tag.find_all_by_id(params[:tags])
    tags.each do |tag|
      Tagging.find_or_create_by_tag_id_and_taggable_id_and_taggable_type(tag.id, @post.id, 'Post').destroy
    end
    @not_in_post_tags = Tag.find_all_by_taggable_type('Post') - @post.tags
    unauthorized! if cannot? :manage, @post
    respond_to do |format|
      format.html { redirect_to('/posts/' + params[:id].to_s + '/edit') }
      format.js
    end
  end
  
  # GET /posts/1
  # GET /posts/1.xml
  def show
    @post = Post.find(params[:id])
    if current_user && current_user.id.to_s.eql?(@post.user_id.to_s)
      @current_one = true
    else
      @current_one = false
    end
    @comment = Comment.new
    @comments = @post.comments
    @tags = Array.new
    TagName.find_all_by_language_and_tag_id(I18n.locale.to_s, @post.tags).each do |item|
      @tags.push(item)
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post }
    end
  end
  
  # GET /posts/new
  # GET /posts/new.xml
  def new
    @post = Post.new   
  end

  # GET /posts/1/edit
  def edit
    @post = Post.find(params[:id])
    @not_in_post_tags = Tag.find_all_by_taggable_type('Post') - @post.tags
    unauthorized! if cannot? :manage, @post
  end

  # POST /posts
  # POST /posts.xml
  def create
    # unauthorized! if cannot? :create, @post
    #@post = Post.new(params[:post])
    @user = User.find_by_id(current_user)
    @post = @user.posts.new(params[:post])
    
    respond_to do |format|
      if @post.save
        flash[:notice] = t("common.created")
        format.html { redirect_to edit_post_path(@post) }
        format.xml  { render :xml => @post, :status => :created, :location => @post }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /posts/1
  # PUT /posts/1.xml
  def update
    @post = Post.find(params[:id])
    unauthorized! if cannot? :manage, @post
    
    respond_to do |format|
      if @post.update_attributes(params[:post])
        flash[:notice] = t("common.updated")
        format.html { redirect_to(@post) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /posts/1
  # DELETE /posts/1.xml
  def destroy
    @post = Post.find(params[:id])
    unauthorized! if cannot? :manage, @post
    
    if @post.delete
      respond_to do |format|
        flash[:notice] = t("common.delete_success")
        format.html { redirect_to(posts_url) }
        format.xml  { head :ok }
      end
    end
    
  end
  
  
  private
  
  def from(time)
    from = Time.new
    if time.to_s.eql?("")
      from = 6.weeks.ago
    else
      from = Time.parse(time.to_s)
    end
    
  end
  
  def to(time)
    to = Time.new
    if time.to_s.eql?("")
      to = Time.now
    else
      to = Time.parse(time.to_s)
    end
  end
  

  
  def post_from_user_searchlogic
    return Post.user_login_like(params[:search])
  end
  
  def user_commons_searchlogic
    if params[:search].to_s.match(" ")
      split = params[:search].split(' ', 2)
      user_commons = UserCommon.all(:conditions  => "firstname LIKE '%#{split.first}%' and lastname LIKE '%#{split.second}%'")
      user_commons = user_commons + UserCommon.all(:conditions  => "firstname LIKE '%#{split.second}%' and lastname LIKE '%#{split.first}%'")
      return user_commons.uniq
    else
      return UserCommon.firstname_like_or_lastname_like(params[:search])
    end
  end
  
  def get_all_user_ids(user_commons)
    user_ids = Array.new
    user_commons.each do |user_common|
      user_ids.push(user_common.user_id)
    end
    return user_ids
  end
  
end
