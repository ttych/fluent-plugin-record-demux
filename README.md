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

### example

Example of configuration

``` text
<match *>
  @type record_demux

  tag data.demux

  demux_keys a, b, c
  shared_keys d, e, f
  remove_keys g, i, j
</match>
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
