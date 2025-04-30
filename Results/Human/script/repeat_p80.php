<?php
require __DIR__ . "/functions.php";
$pos_file_name = $argv[1];
$neg_file_name = $argv[2];
$repeat_count = $argv[3];
# default prefix is all.sample.info with no type specified
$prefix = $argv[4] ?? 'all.sample.info';

$pos_ids = load_id_from_file($pos_file_name);
$neg_ids = load_id_from_file($neg_file_name);
$cut_count = intval(min(count($pos_ids), count($neg_ids)) * 0.8);

for ($i = 1; $i <= $repeat_count; $i++) {
    shuffle($pos_ids);
    shuffle($neg_ids);

    $sampling_pos_ids = array_slice($pos_ids, 0, $cut_count);
    $sampling_neg_ids = array_slice($neg_ids, 0, $cut_count);
    $info = make_info(array_merge($sampling_pos_ids, $sampling_neg_ids), $sampling_pos_ids, $sampling_neg_ids);
    write_info("$prefix.$i", $info);
}