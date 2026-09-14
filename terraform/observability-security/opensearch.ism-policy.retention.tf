# O ism_template so vale para indices criados depois que a policy existe -- os
# indices diarios ja abertos continuam sem policy ate rolar a data.
resource "opensearch_ism_policy" "retention" {
  for_each = var.opensearch_retention

  policy_id = "nsse_${each.key}_retention"

  body = jsonencode({
    policy = {
      description   = "Retencao de ${each.value.min_index_age} para os indices de ${each.key} do nsse"
      default_state = "hot"

      ism_template = [
        {
          index_patterns = each.value.index_patterns
          priority       = each.value.priority
        }
      ]

      states = [
        {
          name    = "hot"
          actions = []

          transitions = [
            {
              state_name = "delete"
              conditions = {
                min_index_age = each.value.min_index_age
              }
            }
          ]
        },
        {
          name = "delete"

          # O retry e preenchido pelo OpenSearch com estes defaults. Sem
          # declarar, todo plan seguinte tentaria remove-lo -- diff perpetuo.
          actions = [
            {
              delete = {}

              retry = {
                count   = 3
                backoff = "exponential"
                delay   = "1m"
              }
            }
          ]

          transitions = []
        }
      ]
    }
  })
}
