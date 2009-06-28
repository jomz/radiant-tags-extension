module SiteControllerExtensions

  def self.included(base)
    base.class_eval do
      alias_method_chain :show_page, :tag
      
      private

      def show_uncached_page_with_tag_suffix(url, tag)
        @page = find_page(url)
        unless @page.nil?
          process_page(@page)
          @cache.cache_response(url + '/' + tag, response) if request.get? and live? and @page.cache?
          @performed_render = true
        else
          render :template => 'site/not_found', :status => 404
        end
      rescue Page::MissingRootPageError
        redirect_to welcome_url
      end
      
    end
  end
  
  def show_page_with_tag
    if params[:tag]
      response.headers.delete('Cache-Control')
      url = params[:url]
      if Array === url
        url = url.join('/')
      else
        url = url.to_s
      end
      
      tag = params[:tag]
      if (request.get? || request.head?) and live? and (@cache.response_cached?(url + '/' + tag))
        @cache.update_response(url + '/' + tag, response, request)
        @performed_render = true
      else
        show_uncached_page_with_tag_suffix(url, tag)
      end
    else
      show_page_without_tag
    end

  end
  
end