#let invoice(
  // The invoice number
  invoice-nr,
  // The date on which the invoice was created
  invoice-date,
  // A list of items
  items,
  // Other stuff
  data
) = {
  set page(paper: "a4", margin: (x: 20%, y: 20%, top: 20%, bottom: 20%))

  // Typst can't format numbers yet, so we use this from here:
  // https://github.com/typst/typst/issues/180#issuecomment-1484069775
  let format_currency(number) = {
    let precision = 2
    assert(precision > 0)
    let s = str(calc.round(number, digits: precision))
    let after_dot = s.find(regex("\..*"))
    if after_dot == none {
      s = s + "."
      after_dot = "."
    }
    for i in range(precision - after_dot.len() + 1){
      s = s + "0"
    }
    s
  }

  set text(number-type: "old-style")

  smallcaps[
    *#data.author.name* •
    #data.author.street •
    #data.author.zip #data.author.city, #data.author.country
  ]

  v(1em)

  [
    #set par(leading: 0.40em)
    #set text(size: 1.2em)
    #data.recipient.name \
    #data.recipient.street \
    #data.recipient.zip #data.recipient.city, #data.recipient.country
  ]

  v(4em)

  grid(columns: (1fr, 1fr), align: bottom, heading[
    #data.labels.invoice \##invoice-nr
  ],
  [
    #set align(right)
    #data.author.city, *#invoice-date*
  ])

  let total = items.map((item) => decimal(item.price)).sum()

  let items = items.enumerate().map(
    ((id, item)) => (
      [#str(id + 1).],
      [#item.description],
      [#format_currency(decimal(item.price))#data.labels.currency],
    ),
  ).flatten()

  [
    #let tax = decimal(data.at("tax", default: 0))
    #set text(number-type: "lining")
    #table(
      stroke: none,
      columns: (auto, 10fr, auto),
      align: ((column, row) => if column == 1 { left } else { right }),
      table.hline(stroke: (thickness: 0.5pt, dash: "dotted")),
      [*#data.labels.pos*], [*#data.labels.description*], [*#data.labels.price*],
      table.hline(),
      ..items,
      table.hline(),
      [],
      [
        #set align(end)
        #data.labels.subtotal:
      ],
      [#format_currency({(decimal(1) - tax) * total})#data.labels.currency],
      table.hline(start: 2),
      ..if tax != 0 {(
        [],
        [
          #set text(number-type: "old-style")
          #set align(end)
          #str(tax * 100)% #data.labels.tax:
        ],
        [#format_currency(tax * total)#data.labels.currency],
        table.hline(start: 2),
        [],
      )} else {([], [], [], [])},
      [
        #set align(end)
        *#data.labels.total:*
      ],
      [*#format_currency(total)#data.labels.currency*],
      table.hline(start: 2),
    )
  ]

  v(2em)

  [
    #set text(size: 0.8em)
    #data.notes
  ]

  if data.at("bank-account", default: none) != none [
    #set text(number-type: "lining")
    #box(
      inset: 10pt,
      radius: 2pt,
      stroke: 0.3pt,
      width: 100%,
      fill: cmyk(5%, 0%, 0%, 5%),
      [
        #grid(
          align: left,
          columns: 3,
          gutter: 9pt,

          data.labels.recipient, [:], data.bank-account.name,
          data.labels.institution, [:], data.bank-account.bank,
          data.labels.iban, [:], data.bank-account.iban,
          data.labels.bic, [:], data.bank-account.bic,
        )
      ]
    )
  ]

  [
    #set text(size: 0.8em)
    #set text(number-type: "lining")
    #if data.author.at("tax_nr", default: none) != none [
      #v(0.5em)
      #data.labels.tax-number: #data.author.tax_nr
    ]
    #v(0.5em)
    #data.labels.closing-statement
    #v(1em)
    #data.author.name
  ]
}
#invoice(
  sys.inputs.number,
  sys.inputs.date,
  json(bytes(sys.inputs.items)),
  yaml(sys.inputs.config)
)
