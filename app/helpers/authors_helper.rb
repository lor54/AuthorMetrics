module AuthorsHelper
    def getUrlEncodedPid(dblpUrl)
        ERB::Util.url_encode(dblpUrl.delete_prefix('https://dblp.org/pid/'))
    end
end
