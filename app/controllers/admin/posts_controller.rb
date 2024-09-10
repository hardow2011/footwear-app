class Admin::PostsController < Admin::AdminController
  before_action :set_post, only: %i[edit update destroy]

  def index
    @posts = Post.order(updated_at: :desc)
  end
  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)

    @post.published = get_published_value_from_params

    if @post.save
      redirect_to admin_posts_path, notice: notice_message_from_published_status(@post)
    else
      render :new, status: :unprocessed_entity
    end
  end

  def edit
  end

  def update
    @post.published = get_published_value_from_params
    if @post.update(post_params)
      redirect_to admin_posts_path, notice: notice_message_from_published_status(@post)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to admin_posts_path, notice: 'Post was destroyed successfully.'
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title_en, :title_es, :overview_en, :overview_es, :content_en, :content_es, tags: [])
  end

  def get_published_value_from_params
    if [t('save_as_draft'), t('unpublish_post_and_save_as_draft')].include?(params[:commit])
      return false
    elsif [t('publish_post'), t('publish_updates')].include?(params[:commit])
      return true
    else
      Rails.error.report("Commit value #{params[:commit]} not allowed")
      render :new, status: :unprocessed_entity
      return
    end
  end

  def notice_message_from_published_status(post)
    if post.published
      return 'Post published successfuly.'
    else
      return 'Post saved as draft successfuly.'
    end
  end
end
