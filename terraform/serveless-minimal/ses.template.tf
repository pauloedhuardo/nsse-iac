resource "aws_ses_template" "order_confirmed" {
  name    = "order-confirmed-template"
  subject = "Importante"
  html    = "<h1>Invoice {{InvoiceNumber}} gerada com sucesso para ordem {{OrderId}}</h1>"
  text    = "Invoice {{InvoiceNumber}} gerada com sucesso para ordem {{OrderId}}."
}