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

## Installation

Manual install, by executing:

    $ gem install fluent-plugin-record-demux

Add to Gemfile with:

    $ bundle add fluent-plugin-record-demux


## Copyright

* Copyright(c) 2024-2025 Thomas Tych
* License
  * Apache License, Version 2.0
