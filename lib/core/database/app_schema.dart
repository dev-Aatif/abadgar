import 'package:powersync/powersync.dart';

const schema = Schema([
  Table(
    'seasons',
    [
      Column.text('name'),
      Column.text('crop_type'),
      Column.real('land_area'),
      Column.text('start_date'),
      Column.text('end_date'),
      Column.text('status'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
    indexes: [
      Index('status_created', [
        IndexedColumn.ascending('status'),
        IndexedColumn.descending('created_at'),
      ]),
      Index('start_date_desc', [IndexedColumn.descending('start_date')]),
    ],
  ),
  Table(
    'transactions',
    [
      Column.text('season_id'),
      Column.real('amount'),
      Column.text('type'),
      Column.text('date'),
      Column.text('category'),
      Column.text('notes'),
      Column.real('quantity'),
      Column.text('buyer_name'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
    indexes: [
      Index('season_date', [
        IndexedColumn.ascending('season_id'),
        IndexedColumn.descending('date'),
      ]),
    ],
  ),
  Table(
    'yield_logs',
    [
      Column.text('season_id'),
      Column.real('total_weight'),
      Column.text('unit'),
      Column.text('disposition'),
      Column.real('sale_price'),
      Column.text('destination'),
      Column.text('transaction_id'),
      Column.text('date'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
    indexes: [
      Index('season_date', [
        IndexedColumn.ascending('season_id'),
        IndexedColumn.descending('date'),
      ]),
    ],
  ),
  Table(
    'lands',
    [
      Column.text('name'),
      Column.real('area'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
    indexes: [
      Index('name_asc', [IndexedColumn.ascending('name')]),
    ],
  ),
]);
