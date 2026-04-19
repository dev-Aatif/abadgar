import 'package:powersync/powersync.dart';

const schema = Schema([
  Table('seasons', [
    Column.text('name'),
    Column.text('crop_type'),
    Column.real('land_area'),
    Column.text('start_date'),
    Column.text('end_date'),
    Column.text('status'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
    Table(
      'transactions',
      [
        const Column.text('season_id'),
        const Column.real('amount'),
        const Column.text('type'),
        const Column.text('date'),
        const Column.text('category'),
        const Column.text('notes'),
        const Column.real('quantity'),
        const Column.text('buyer_name'),
        const Column.text('created_at'),
        const Column.text('updated_at'),
      ],
    ),
    Table(
      'yield_logs',
      [
        const Column.text('season_id'),
        const Column.real('total_weight'),
        const Column.text('unit'),
        const Column.text('disposition'),
        const Column.real('sale_price'),
        const Column.text('destination'),
        const Column.text('date'),
        const Column.text('created_at'),
        const Column.text('updated_at'),
      ],
    ),
    Table(
      'lands',
      [
        const Column.text('name'),
        const Column.real('area'),
        const Column.text('created_at'),
        const Column.text('updated_at'),
      ],
    ),
]);
