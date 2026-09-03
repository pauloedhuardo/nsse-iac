/* Sufixo dos snapshots finais. O identificador de snapshot nao pode se repetir na
   conta, entao um nome fixo faz o destroy seguinte falhar com
   DBClusterSnapshotAlreadyExistsFault.

   time_static captura o instante uma unica vez e o congela no state, o que evita o
   diff perpetuo que timestamp() causaria. Como o recurso e destruido junto com o
   resto do stack, cada ciclo destroy/apply gera um sufixo novo. */
resource "time_static" "final_snapshot" {}

locals {
  final_snapshot_suffix = formatdate("YYYYMMDDhhmmss", time_static.final_snapshot.rfc3339)
}
