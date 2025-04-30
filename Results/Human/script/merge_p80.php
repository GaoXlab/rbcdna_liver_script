<?php
$type = $argv[1];

if (empty($type)) {
    echo "type is required";
    die;
}
$beds = glob("all.{$type}.tab.*[0-9]");
$bed_fp = [];
foreach ($beds as $bed) {
    $bed_fp[] = fopen($bed, "r");
}
$output_fp = fopen("all.{$type}.bed", "wb+");

do {
    $continue = false;
    $pos = [];
    $each_result = [];
    $total = count($beds);
    foreach ($bed_fp as $fp) {
        $line = fgetcsv($fp, null, "\t");
        if ($line === false) {
            break 2;
        }
        if (!$pos) {
            $pos = array_slice($line, 0, 3);
        }
        $each_result [] = $line;
        $continue = true;
    }
    $output_line = [
        ...$pos,
        array_sum(array_column($each_result, 3)) / $total,
        array_sum(array_column($each_result, 4)) / $total,
        0
    ];
    fputcsv($output_fp, $output_line, "\t");
} while ($continue);