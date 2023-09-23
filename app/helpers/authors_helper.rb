module AuthorsHelper
    def getUrlEncodedPid(dblpUrl)
        ERB::Util.url_encode(dblpUrl.delete_prefix('https://dblp.org/pid/'))
    end

    def authorPath(pid, tabname)
        res = authors_path + '/' + ERB::Util.url_encode(pid)
        res += tabname == '' ? '' : '/' + tabname
    end
end
