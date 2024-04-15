# fluent-plugin-record-demux

[Fluentd](https://fluentd.org/) plugin to dmux records.

## plugins

### out - record_dmux

#### config

| setting | type | default | description |
|---------|------|---------|-------------|
|         |      |         |             |

#### example

Example of configuration

``` text
<match *>
  @type record_dmux

  tag data.dmux

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

* Copyright(c) 2024- Thomas Tych
* License
  * Apache License, Version 2.0
