Hi Heiner,
 
anbei das kleine Script, dass die statistiken von unify abholt. Die erforderlichen anpassungen sollten selbsterklärend sein.
 
eingebunden habe ich das dann in telegraf mit folgendem config-ausschnitt


````
[[inputs.exec]]
#   ## Commands array
  commands = [ "/storage/getUnifiStats.sh" ]
#
#   ## Timeout for each command to complete.
  timeout = "5s"
#
#   ## measurement name suffix (for separating different commands)
#   name_suffix = "_mycollector"
#
#   ## Data format to consume.
#   ## Each data format has its own unique set of configuration options, read
#   ## more about them here:
#   ## https://github.com/influxdata/telegraf/blob/master/docs/DATA_FORMATS_INPUT.md
  data_format = "json"
  tag_keys = [ "hostname", "name" ]

````


Lars
