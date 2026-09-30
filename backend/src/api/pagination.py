from rest_framework.pagination import PageNumberPagination


class DefaultPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 10000

    def paginate_queryset(self, queryset, request, view=None):
        # allow client to disable pagination per-request with ?page_size=0 or ?page_size=all
        param = request.query_params.get(self.page_size_query_param)
        if param in ('0', 'all'):
            return None
        return super().paginate_queryset(queryset, request, view)
