<?php
const TEST_IDS_PATH = './';
$TAB_FILE_DIR = getcwd() . "/modelData";
function load_id_from_file($file, &$label = []): array
{
    $ids = file($file, FILE_IGNORE_NEW_LINES);
    $result = [];
    foreach ($ids as $id) {
        if (strpos($id, '.txt') !== FALSE) {
            if (file_exists(TEST_IDS_PATH . $id)) {
                $result = array_merge($result, load_id_from_file(TEST_IDS_PATH . $id));
            }
        } else {
            $line = preg_split("#\s+#", $id);
            $result [] = $line[0];
            if (strpos($file, "test") !== FALSE) {
            }
            if (count($line) > 1) {
                $label[$line[0]] = $line[1];
            }
        }
    }
    return array_filter(array_values(array_unique($result)));
}

function make_vector($ids ,$mode, $output_name, $samples, $whitelist, $pos_ids = [], $neg_ids = []){
    global $TAB_FILE_DIR;
    $file_name = $output_name;
    $index = file($TAB_FILE_DIR . "/$mode/sorted.tab.index", FILE_IGNORE_NEW_LINES);
    file_put_contents($file_name, count($ids) . " " . count($whitelist). "\n");
    $pos_ids_dict = array_fill_keys($pos_ids, true);
    $neg_ids_dict = array_fill_keys($neg_ids, true);
    sort($ids);
    $dict = array_fill_keys($whitelist, 1);
    $whitelist_keys = [];
    foreach ($whitelist as $wl) {
        $whitelist_keys [] = array_search($wl, $index);
    }
    foreach ($ids as $id) {
        $line_data = [];
        $line_data [] = isset($pos_ids_dict[$id]) ? 1 : (isset($neg_ids_dict[$id]) ? 0 : ($samples[$id]['ca'] ?? 0));
        $line_data [] = $id;
        $raw_data = raw($id, $mode);
        foreach ($whitelist_keys as $key) {
            $line_data [] = sprintf("%0.1lf", $raw_data[$key]);
        }
        file_put_contents($file_name, join(' ', $line_data) . "\n", FILE_APPEND);
    }
}

function  make_info($ids, $pos_label = [], $neg_label = []) {
    $results = [];
    foreach ($ids as $id) {
        $sample_label = -1;
        if (in_array($id, $pos_label)) {
            $sample_label = 1;
        } else if (in_array($id, $neg_label)) {
            $sample_label = 0;
        }
        $results[] = [
            $id,
            $sample_label,
            '-',
            -2,
            0,
            -1,
        ];
    }
    return $results;
}

function write_info($filename, $info) {
    $fp = fopen($filename, 'w+');
    fputcsv($fp, [count($info)]);
    foreach ($info as $item) {
        fputcsv($fp, $item, " ");

    }
    fclose($fp);
}
function features($file)
{
    $lines = file($file, FILE_IGNORE_NEW_LINES);
    $features = [];
    foreach ($lines as $line) {
        $line = explode("\t", $line);
        $features[] = [
            'chr' => $line[0],
            'start' => $line[1],
            'end' => $line[2],
            'score' => $line[3],
        ];
    }
    return $features;
}

function raw($id, $type="q30", $origin = false)
{
    global $TAB_FILE_DIR;
    $dir = $origin ? 'origin' : 'cleaned';
    $file_name = $TAB_FILE_DIR . "/{$type}/{$dir}/$id.raw";
    if (!file_exists($file_name)) {
        return [];
    }
    return file($file_name, FILE_IGNORE_NEW_LINES);
}