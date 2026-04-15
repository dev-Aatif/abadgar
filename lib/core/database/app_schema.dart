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
  Table('transactions', [
    Column.text('season_id'),
    Column.real('amount'),
    Column.text('category'),
    Column.text('date'),
    Column.text('type'),
    Column.text('notes'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
]);
