import rdkafka

let ee = rd_kafka_version_str()
echo("librdkafak version: " & $ee)

# send some messages
proc produce():string =
  let conf = rd_kafka_conf_new()
  var errstr:cstring= ""
  let kp = rd_kafka_new(rd_kafka_type_t.RD_KAFKA_PRODUCER,conf,errstr,512)

  # broker
  var numbrokers = rd_kafka_brokers_add(kp,"localhost:9092")
  echo("brokers added: "& $numbrokers)

  # topic
  let topic_conf = rd_kafka_topic_conf_new()
  let topic_name:cstring = "test_topic"
  let topic = rd_kafka_topic_new(kp,topic_name,topic_conf)
 
  let part:int32 = 1
  for i in 1..10:
    var message:cstring = "test mesage! " & $i 
    
    var p = rd_kafka_produce(topic,part,cast[cint](RD_KAFKA_MSG_F_COPY),
                             message,
                             message.len+1,
                             nil,0,nil)
    echo("add result " & $p)
 
proc message_to_str(m: ptr rd_kafka_message_t): cstring =
  echo ("m len"& $m.len)
  echo("m partition: " & $m.partition)
  let err = rd_kafka_message_errstr(m)
  if err != nil or err.len > 0:
    echo("error: " & $err)
    return cast[string](err)
    
  var res = cast[cstring](m.payload)
  echo("payload: " & $res)
  echo("offset: " & $m.offset)
  #result = "dsd"
  result = res
  
proc consume(): string =
  # kafka handle
  let conf = rd_kafka_conf_new()
  var errstr:cstring= ""
  let kc = rd_kafka_new(rd_kafka_type_t.RD_KAFKA_CONSUMER,conf,errstr,512)

  echo($errstr)

  # broker
  var numbrokers = rd_kafka_brokers_add(kc,"localhost:9092")
  echo("brokers added: "& $numbrokers)

  # topic
  let topic_conf = rd_kafka_topic_conf_new()
  let topic_name:cstring = "test_topic"
  let topic = rd_kafka_topic_new(kc,topic_name,topic_conf)
 
  # start consuming
  let part:int32 = 1
  var res= rd_kafka_consume_start(topic,
                                  part,
                                  RD_KAFKA_OFFSET_TAIL(5)
                                  #cast[int64_t](2)
  ) 
  echo("sart consuming value: " & $res)
  var message = rd_kafka_consume(topic, part, 1000)
  var ms = message_to_str(message)
  echo("message: " & $ms)
  # stop consumming
  discard rd_kafka_consume_stop(topic, part)
  result = ""

#discard produce()
#discard consume()
