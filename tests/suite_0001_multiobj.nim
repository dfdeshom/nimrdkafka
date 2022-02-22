import strutils, unittest, times, random
import nimrdkafka

# Nim port of test suites in librdkafka/tests/test.c
# and individual test suites

var suiteName = "0001_multiobj"
var test_on_ci = true

proc test_conf_set(kafkaConf: var PRDKConf, name: string, value: string): void =
  var errstr: cstring = ""
  var res: RDKConfRes
  res = rd_kafka_conf_set(kafkaConf, cast[cstring](name), cast[cstring](value),
      errstr, sizeof(errstr))
  if res != RD_KAFKA_CONF_OK:
    raise newException(CatchableError, "Failed to set config " & name & "=" & value)

proc test_conf_init(kafkaConf: var PRDKConf, topicConf: var PRDKTopicConf,
    timeout: int): void =
  # TODO check additional conf path
  var errstr: cstring = ""

  if kafkaConf.isNil == false:
    kafkaConf = rd_kafka_conf_new()
    echo "1"
    var res = rd_kafka_conf_set(kafkaConf, "client.id", suiteName, errstr,
        sizeof(errstr))
    # TODO check idempotent producer
    # TODO bind error and stat callbacks:
    # rd_kafka_conf_set_error_cb(kafkaConf, test_error_cb);
    # rd_kafka_conf_set_stats_cb(kafkaConf, test_stats_cb);
    if test_on_ci == true:
      echo "1-1"
      test_conf_set(kafkaConf, "request.timeout.ms", strUtils.intToStr(timeout))

  # TODO setting SIGIO for speeding up termination
  # TODO enabling socket emulation

  if topicConf.isNil == false:
    echo "2"
    topicConf = rd_kafka_topic_conf_new()

  # TODO open and read optional test config (see tests.c)

proc test_create_handle(mode: RDKType, kafkaConf: var PRDKConf): PRDK =
  var rk: PRDK
  var errstr: cstring = ""
  var nullTopic: PRDKTopicConf
  if kafkaConf.isNil == true:
    test_conf_init(kafkaConf, nullTopic, 0)
    # TODO socket emulation enable
  else:
    # TODO implement rd_kafka_conf_get
    # TODO make sure to check existing client.id
    test_conf_set(kafkaConf, "client.id", suiteName)

  rk = rd_kafka_new(mode, kafkaConf, errstr, sizeof(errstr))

  if rk.isNil:
    raise newException(CatchableError, "Failed to create rdkafka instance: " &
        cast[string](errstr))
  echo "Created kafka instance"

  return rk

suite "0001_multiobj":
  var kafkaConf: PRDKConf
  var topicConf: PRDKTopicConf

  setup:
    test_conf_init(kafkaConf, topicConf, 10)

  test "Creating and destroying 5 kafka instances":
    var rk: PRDK
    var rkt: PRDKTopic
    rk = test_create_handle(RD_KAFKA_PRODUCER, kafkaConf)
    var numBrokers = rd_kafka_brokers_add(rk, "localhost:9092")

    # TODO properly randomized topic name
    randomize()
    let num = rand(100000)
    let topicName = suiteName & "-" & $num & "-0001"

    rkt = rd_kafka_topic_new(rk, topicName, topicConf)
    if rkt.isNil:
      echo "Failed to create topic for rdkafka instance" # TODO
      fail()

    var message: string = "test message for iteration #"
    var p = rd_kafka_produce(
      rkt,
      cast[cint](RD_KAFKA_PARTITION_UA),           # random partition
      cast[cint](RD_KAFKA_MSG_F_COPY),
      message.cstring,
      message.len+1,
      nil, 0, nil
    )
    let flushError = rd_kafka_flush(rk, cast[cint](-1))
    rd_kafka_topic_destroy(rkt)
    rd_kafka_destroy(rk)
