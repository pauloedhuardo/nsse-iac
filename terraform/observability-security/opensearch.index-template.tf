# Um index template so vale para indices criados depois dele -- os indices de
# hoje ficam com o mapping antigo ate virar a data.
resource "opensearch_composable_index_template" "nsse" {
  for_each = var.opensearch_index_templates

  name = "nsse_${each.key}"

  body = jsonencode({
    index_patterns = each.value.index_patterns
    priority       = each.value.priority

    template = {
      settings = {
        number_of_shards   = each.value.number_of_shards
        number_of_replicas = each.value.number_of_replicas
        refresh_interval   = each.value.refresh_interval
      }

      mappings = merge(
        {
          properties = each.value.properties
        },
        each.value.keyword_attributes ? {
          dynamic_templates = [
            {
              attributes_as_keyword = {
                path_match         = "attributes.*"
                match_mapping_type = "string"
                mapping = {
                  type = "keyword"
                }
              }
            }
          ]
        } : {}
      )
    }
  })
}
