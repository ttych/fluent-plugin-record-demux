# fluent-plugin-record-demux

[Fluentd](https://fluentd.org/) plugin to dmux records.

## plugin - out - record_dmux

### config

| setting              | type            | default | description                                                                |
|----------------------|-----------------|---------|----------------------------------------------------------------------------|
| tag                  | string          | *nil*   | tag to emit records on                                                     |
| demux_keys           | array of string | *nil*   | keys to demux, computed when nil                                           |
| shared_keys          | array of string | []      | keys to not demux, and to keep                                             |
| remove_keys          | array of string | []      | keys to remove                                                             |
| event_key_uniformize | bool            | false   | change record/event structure to name/value                                |
| event_key_prefix     | string          | ''      | prefix before *name* in case of event_key_uniformize                       |
| shared_key_prefix    | string          | ''      | prefix to add in from of *shared keys* key name                            |
| timestamp_key        | string          | *nil*   | add timestamp key when defined, computed from time of the event            |
| timestamp_format     | enum            | iso     | can be iso for iso8601(3) or epochmillis for epoch with millisecond format |

### example 1

Example of configuration:

``` text
<match *>
  @type record_demux

  tag data.demux

  demux_keys a, b, c
  shared_keys d, e, f
  remove_keys g, i, j
</match>
```

### example 2

With configuration:

``` text
<match *>
  @type record_demux

  tag data.demux

  shared_keys tags_1, tags_2
  remove_keys tmp
</match>
```

or with configuration:

``` text
<match *>
  @type record_demux

  tag data.demux

  demux_keys a, b, c
  remove_keys tmp
</match>
```

It will transform event like:

``` text
{ "a": "data_a", "b": "data_b", "c": "data_c", "tags_1": "data_1", "tags_2": "data_2", "tmp": "data_tmp" }
```

into events:

``` text
{ "a": "data_a", "tags_1": "data_1", "tags_2": "data_2" }
{ "b": "data_b", "tags_1": "data_1", "tags_2": "data_2" }
{ "c": "data_c", "tags_1": "data_1", "tags_2": "data_2" }
```

## plugin - out - record_dmux_picker

Demux record/event, by selecting nested fields for shared and demux parts.

It transforms 1 record/event to multiple record/event.

### params

| setting                        | type                    | default | description                                    |
|--------------------------------|-------------------------|---------|------------------------------------------------|
| tags                           | string                  |         | tag to emit demux events on                    |
| demux_keys                     | hash                    |         | nested key to demux                            |
| shared_keys                    | hash                    | {}      | shared key to be present in each new event     |
| demux_key_normalize            | bool                    | false   | format key to demux, in a key: , value: format |
| demux_key_normalize_key_name   | string                  | key     | when demux_key_normalize, key name to use      |
| demux_key_normalize_value_name | string                  | value   | when demux_key_normalize, value name to use    |
| timestamp_key                  | string                  | nil     | key for timestamp field (nil means skip)       |
| timestamp_format               | enum (iso, epochmillis) | iso     | format of the time value                       |

### example 1

Give this event :

``` text
{
    "label1": "value_label1",
    "label2": "value_label2",
    "label3": "value_label3",
    "common": {
        "metadata1": "value_metadata1",
        "metadata2": "value_metadata2",
        "metadata3": "value_metadata3",
        "metadata4": "value_metadata4",
        "metadata5": "value_metadata5",
        "metadata6": "value_metadata6"
    }
}

```

With this conf :

``` text
<match data>
  @type record_demux_picker
  tag demuxed
  demux_keys $.label1:data1 , $.label2:data2 , $.label3:data3
  shared_keys $.common.metadata1:description1 , $.common.metadata2:description2 , $.common.metadata3:description3
</match>
```

It will produce :

``` text
{"description1":"value_metadata1","description2":"value_metadata2","description3":"value_metadata3","data1":"value_label1"}
{"description1":"value_metadata1","description2":"value_metadata2","description3":"value_metadata3","data2":"value_label2"}
{"description1":"value_metadata1","description2":"value_metadata2","description3":"value_metadata3","data3":"value_label3"}

```

## Installation

Manual install, by executing:

    $ gem install fluent-plugin-record-demux

Add to Gemfile with:

    $ bundle add fluent-plugin-record-demux


## Copyright

* Copyright(c) 2024-2025 Thomas Tych
* License
  * Apache License, Version 2.0
