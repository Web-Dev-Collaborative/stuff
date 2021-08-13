#!/usr/bin/env ruby

require 'newrelic_plugin'
require 'snmp'

module NewRelic
  module F5Plugin

    class Device
      attr_accessor :snmp_manager

      # Create the OIDs if they do not exist
      OID_SYS_HTTP_COMPRESSION_STAT                          = "1.3.6.1.4.1.3375.2.1.1.2.22"
      OID_SYS_HTTP_COMPRESSION_STAT_AUDIO_POSTCOMPRESS_BYTES = "#{OID_SYS_HTTP_COMPRESSION_STAT}.24.0"
      OID_SYS_HTTP_COMPRESSION_STAT_AUDIO_PRECOMPRESS_BYTES  = "#{OID_SYS_HTTP_COMPRESSION_STAT}.23.0"
      OID_SYS_HTTP_COMPRESSION_STAT_CSS_POSTCOMPRESS_BYTES   = "#{OID_SYS_HTTP_COMPRESSION_STAT}.8.0"
      OID_SYS_HTTP_COMPRESSION_STAT_CSS_PRECOMPRESS_BYTES    = "#{OID_SYS_HTTP_COMPRESSION_STAT}.7.0"
      OID_SYS_HTTP_COMPRESSION_STAT_HTML_POSTCOMPRESS_BYTES  = "#{OID_SYS_HTTP_COMPRESSION_STAT}.6.0"
      OID_SYS_HTTP_COMPRESSION_STAT_HTML_PRECOMPRESS_BYTES   = "#{OID_SYS_HTTP_COMPRESSION_STAT}.5.0"
      OID_SYS_HTTP_COMPRESSION_STAT_IMAGE_POSTCOMPRESS_BYTES = "#{OID_SYS_HTTP_COMPRESSION_STAT}.20.0"
      OID_SYS_HTTP_COMPRESSION_STAT_IMAGE_PRECOMPRESS_BYTES  = "#{OID_SYS_HTTP_COMPRESSION_STAT}.19.0"
      OID_SYS_HTTP_COMPRESSION_STAT_JS_POSTCOMPRESS_BYTES    = "#{OID_SYS_HTTP_COMPRESSION_STAT}.10.0"
      OID_SYS_HTTP_COMPRESSION_STAT_JS_PRECOMPRESS_BYTES     = "#{OID_SYS_HTTP_COMPRESSION_STAT}.9.0"
      OID_SYS_HTTP_COMPRESSION_STAT_OCTET_POSTCOMPRESS_BYTES = "#{OID_SYS_HTTP_COMPRESSION_STAT}.18.0"
      OID_SYS_HTTP_COMPRESSION_STAT_OCTET_PRECOMPRESS_BYTES  = "#{OID_SYS_HTTP_COMPRESSION_STAT}.17.0"
      OID_SYS_HTTP_COMPRESSION_STAT_OTHER_POSTCOMPRESS_BYTES = "#{OID_SYS_HTTP_COMPRESSION_STAT}.26.0"
      OID_SYS_HTTP_COMPRESSION_STAT_OTHER_PRECOMPRESS_BYTES  = "#{OID_SYS_HTTP_COMPRESSION_STAT}.25.0"
      OID_SYS_HTTP_COMPRESSION_STAT_PLAIN_POSTCOMPRESS_BYTES = "#{OID_SYS_HTTP_COMPRESSION_STAT}.16.0"
      OID_SYS_HTTP_COMPRESSION_STAT_PLAIN_PRECOMPRESS_BYTES  = "#{OID_SYS_HTTP_COMPRESSION_STAT}.15.0"
      OID_SYS_HTTP_COMPRESSION_STAT_POSTCOMPRESS_BYTES       = "#{OID_SYS_HTTP_COMPRESSION_STAT}.3.0"
      OID_SYS_HTTP_COMPRESSION_STAT_PRECOMPRESS_BYTES        = "#{OID_SYS_HTTP_COMPRESSION_STAT}.2.0"
      OID_SYS_HTTP_COMPRESSION_STAT_SGML_POSTCOMPRESS_BYTES  = "#{OID_SYS_HTTP_COMPRESSION_STAT}.14.0"
      OID_SYS_HTTP_COMPRESSION_STAT_SGML_PRECOMPRESS_BYTES   = "#{OID_SYS_HTTP_COMPRESSION_STAT}.13.0"
      OID_SYS_HTTP_COMPRESSION_STAT_VIDEO_POSTCOMPRESS_BYTES = "#{OID_SYS_HTTP_COMPRESSION_STAT}.22.0"
      OID_SYS_HTTP_COMPRESSION_STAT_VIDEO_PRECOMPRESS_BYTES  = "#{OID_SYS_HTTP_COMPRESSION_STAT}.21.0"
      OID_SYS_HTTP_COMPRESSION_STAT_XML_POSTCOMPRESS_BYTES   = "#{OID_SYS_HTTP_COMPRESSION_STAT}.12.0"
      OID_SYS_HTTP_COMPRESSION_STAT_XML_PRECOMPRESS_BYTES    = "#{OID_SYS_HTTP_COMPRESSION_STAT}.11.0"
      OID_SYS_HTTP_STAT                                      = "1.3.6.1.4.1.3375.2.1.1.2.4"
      OID_SYS_HTTP_STAT_GET_REQS                             = "#{OID_SYS_HTTP_STAT}.8.0"
      OID_SYS_HTTP_STAT_NUMBER_REQS                          = "#{OID_SYS_HTTP_STAT}.7.0"
      OID_SYS_HTTP_STAT_POST_REQS                            = "#{OID_SYS_HTTP_STAT}.9.0"
      OID_SYS_HTTP_STAT_RESP_2XX_CNT                         = "#{OID_SYS_HTTP_STAT}.3.0"
      OID_SYS_HTTP_STAT_RESP_3XX_CNT                         = "#{OID_SYS_HTTP_STAT}.4.0"
      OID_SYS_HTTP_STAT_RESP_4XX_CNT                         = "#{OID_SYS_HTTP_STAT}.5.0"
      OID_SYS_HTTP_STAT_RESP_5XX_CNT                         = "#{OID_SYS_HTTP_STAT}.6.0"
      OID_SYS_HTTP_STAT_RESP_BUCKET_16K                      = "#{OID_SYS_HTTP_STAT}.19.0"
      OID_SYS_HTTP_STAT_RESP_BUCKET_1K                       = "#{OID_SYS_HTTP_STAT}.17.0"
      OID_SYS_HTTP_STAT_RESP_BUCKET_32K                      = "#{OID_SYS_HTTP_STAT}.20.0"
      OID_SYS_HTTP_STAT_RESP_BUCKET_4K                       = "#{OID_SYS_HTTP_STAT}.18.0"
      OID_SYS_HTTP_STAT_V10_REQS                             = "#{OID_SYS_HTTP_STAT}.11.0"
      OID_SYS_HTTP_STAT_V10_RESP                             = "#{OID_SYS_HTTP_STAT}.14.0"
      OID_SYS_HTTP_STAT_V11_REQS                             = "#{OID_SYS_HTTP_STAT}.12.0"
      OID_SYS_HTTP_STAT_V11_RESP                             = "#{OID_SYS_HTTP_STAT}.15.0"
      OID_SYS_HTTP_STAT_V9_REQS                              = "#{OID_SYS_HTTP_STAT}.10.0"
      OID_SYS_HTTP_STAT_V9_RESP                              = "#{OID_SYS_HTTP_STAT}.13.0"
      OID_SYS_STAT                                           = "1.3.6.1.4.1.3375.2.1.1.2.1"
      OID_SYS_STAT_CLIENT_BYTES_IN                           = "#{OID_SYS_STAT}.3.0"
      OID_SYS_STAT_CLIENT_BYTES_OUT                          = "#{OID_SYS_STAT}.5.0"
      OID_SYS_STAT_CLIENT_CUR_CONNS                          = "#{OID_SYS_STAT}.8.0"
      OID_SYS_STAT_CLIENT_TOT_CONNS                          = "#{OID_SYS_STAT}.7.0"
      OID_SYS_STAT_MEMORY_USED                               = "#{OID_SYS_STAT}.45.0"
      OID_SYS_STAT_PVA_CLIENT_CUR_CONNS                      = "#{OID_SYS_STAT}.22.0"
      OID_SYS_STAT_PVA_SERVER_CUR_CONNS                      = "#{OID_SYS_STAT}.29.0"
      OID_SYS_STAT_SERVER_BYTES_IN                           = "#{OID_SYS_STAT}.10.0"
      OID_SYS_STAT_SERVER_BYTES_OUT                          = "#{OID_SYS_STAT}.12.0"
      OID_SYS_STAT_SERVER_CUR_CONNS                          = "#{OID_SYS_STAT}.15.0"
      OID_SYS_STAT_SERVER_TOT_CONNS                          = "#{OID_SYS_STAT}.14.0"
      OID_SYS_TCP_STAT                                       = "1.3.6.1.4.1.3375.2.1.1.2.12"
      OID_SYS_TCP_STAT_OPEN                                  = "#{OID_SYS_TCP_STAT}.2.0"   # "The number of current open connections."
      OID_SYS_TCP_STAT_CLOSE_WAIT                            = "#{OID_SYS_TCP_STAT}.3.0"   # "The number of current connections in CLOSE-WAIT/LAST-ACK."
      OID_SYS_TCP_STAT_FIN_WAIT                              = "#{OID_SYS_TCP_STAT}.4.0"   # "The number of current connections in FIN-WAIT/CLOSING."
      OID_SYS_TCP_STAT_TIME_WAIT                             = "#{OID_SYS_TCP_STAT}.5.0"   # "The number of current connections in TIME-WAIT."
      OID_SYS_TCP_STAT_ACCEPTS                               = "#{OID_SYS_TCP_STAT}.6.0"   # "The number of connections accepted."
      OID_SYS_TCP_STAT_ACCEPTFAILS                           = "#{OID_SYS_TCP_STAT}.7.0"   # "The number of connections not accepted."
      OID_SYS_TCP_STAT_CONNECTS                              = "#{OID_SYS_TCP_STAT}.8.0"   # "The number of connections established."
      OID_SYS_TCP_STAT_CONNFAILS                             = "#{OID_SYS_TCP_STAT}.9.0"   # "The number of connection failures."
      OID_SYS_TCP_STAT_EXPIRES                               = "#{OID_SYS_TCP_STAT}.10.0"  # "The number of connections expired due to idle timeout."
      OID_SYS_TCP_STAT_ABANDONS                              = "#{OID_SYS_TCP_STAT}.11.0"  # "The number of connections abandoned connections due to retries/keep-alives."
      OID_SYS_TCP_STAT_RXRST                                 = "#{OID_SYS_TCP_STAT}.12.0"  # "The number of received RST."
      OID_SYS_TCP_STAT_RXBADSUM                              = "#{OID_SYS_TCP_STAT}.13.0"  # "The number of bad checksum."
      OID_SYS_TCP_STAT_RXBADSEG                              = "#{OID_SYS_TCP_STAT}.14.0"  # "The number of malformed segments."
      OID_SYS_TCP_STAT_RXOOSEG                               = "#{OID_SYS_TCP_STAT}.15.0"  # "The number of out of order segments."
      OID_SYS_TCP_STAT_RXCOOKIE                              = "#{OID_SYS_TCP_STAT}.16.0"  # "The number of received SYN-cookies."
      OID_SYS_TCP_STAT_RXBADCOOKIE                           = "#{OID_SYS_TCP_STAT}.17.0"  # "The number of bad SYN-cookies."
      OID_SYS_TCP_STAT_SYNCACHEOVER                          = "#{OID_SYS_TCP_STAT}.18.0"  # "The number of SYN-cache overflow."
      OID_SYS_TCP_STAT_TXREXMITS                             = "#{OID_SYS_TCP_STAT}.19.0"  # "The number of retransmitted segments."
      OID_SYS_GLOBAL_STAT                                    = "1.3.6.1.4.1.3375.2.1.1.2"
      OID_SYS_STAT_HARD_SYNCOOKIE_GEN                        = "#{OID_SYS_GLOBAL_STAT}.57.0"  # "The number of hardware SYN cookies are generated on the system."
      OID_SYS_STAT_HARD_SYNCOOKIE_DET                        = "#{OID_SYS_GLOBAL_STAT}.58.0"  # "The number of hardware SYN cookies are detected on the system."


      #
      # Init
      #
      def initialize(snmp = nil)
        if snmp
          @snmp_manager = snmp
        else
          @snmp_manager = nil
        end
      end



      #
      # Perform polling and reportings of metrics
      #
      def poll(agent, snmp)
        @snmp_manager = snmp

        system_memory = get_memory
        system_memory.each_key { |m| agent.report_metric m, "bytes", system_memory[m] } unless system_memory.nil?

        system_connections = get_connections
        system_connections.each_key { |m| agent.report_metric m, "conn", system_connections[m] } unless system_connections.nil?

        system_connection_rates = get_connection_rates
        system_connection_rates.each_key { |m| agent.report_counter_metric m, "conn/sec", system_connection_rates[m] } unless system_connection_rates.nil?

        system_throughput = get_throughput
        system_throughput.each_key { |m| agent.report_counter_metric m, "bits/sec", system_throughput[m] } unless system_throughput.nil?

        system_http_reqs = get_http_requests
        system_http_reqs.each_key { |m| agent.report_counter_metric m, "req/sec", system_http_reqs[m] } unless system_http_reqs.nil?

        system_http_resp = get_http_responses
        system_http_resp.each_key { |m| agent.report_counter_metric m, "resp/sec", system_http_resp[m] } unless system_http_resp.nil?

        system_http_compression = get_http_compression
        system_http_compression.each_key { |m| agent.report_counter_metric m, "bits/sec", system_http_compression[m] } unless system_http_compression.nil?

        system_tcp_conns = get_tcp_connections
        system_tcp_conns.each_key { |m| agent.report_metric m, "conn", system_tcp_conns[m] } unless system_tcp_conns.nil?

        system_tcp_conn_rates = get_tcp_connection_rates
        system_tcp_conn_rates.each_key { |m| agent.report_counter_metric m, "conn/sec", system_tcp_conn_rates[m] } unless system_tcp_conn_rates.nil?

        system_tcp_syn_rates = get_tcp_syn_rates
        system_tcp_syn_rates.each_key { |m| agent.report_counter_metric m, "SYN/sec", system_tcp_syn_rates[m] } unless system_tcp_syn_rates.nil?

        system_tcp_segment_rates = get_tcp_segment_rates
        system_tcp_segment_rates.each_key { |m| agent.report_counter_metric m, "segments/sec", system_tcp_segment_rates[m] } unless system_tcp_segment_rates.nil?

        system_tcp_error_rates = get_tcp_error_rates
        system_tcp_error_rates.each_key { |m| agent.report_counter_metric m, "errs/sec", system_tcp_error_rates[m] } unless system_tcp_error_rates.nil?
      end



      #
      # Gather Memory related metrics and report them in bytes
      #
      def get_memory(snmp = nil)
        metrics = { }
        snmp    = snmp_manager unless snmp

        if snmp
          res = gather_snmp_metrics_array([OID_SYS_STAT_MEMORY_USED], snmp)

          # Bail out if we didn't get anything
          return metrics if res.empty?

          metrics["Memory/TMM"]  = res[0]
        end

        return metrics
      end


      #
      # Gather Global connection related metrics and report them in conn
      #
      def get_connections(snmp = nil)
        metrics = { }
        snmp    = snmp_manager unless snmp

        if snmp
          res = gather_snmp_metrics_array([OID_SYS_STAT_CLIENT_CUR_CONNS, OID_SYS_STAT_SERVER_CUR_CONNS], snmp)

          # Bail out if we didn't get anything
          return metrics if res.empty?

          metrics["Connections/Current/Client"]     = res[0]
          metrics["Connections/Current/Server"]     = res[1]
        end

        return metrics
      end


      #
      # Gather Global connection rate related metrics and report them in conn/sec
      #
      def get_connection_rates(snmp = nil)
        metrics = { }
        snmp    = snmp_manager unless snmp

        if snmp
          res = gather_snmp_metrics_array([OID_SYS_STAT_CLIENT_TOT_CONNS, OID_SYS_STAT_SERVER_TOT_CONNS], snmp)

          # Bail out if we didn't get anything
          return metrics if res.empty?

          metrics["Connections/Rate/Client"] = res[0]
          metrics["Connections/Rate/Server"] = res[1]
        end

        return metrics
      end


      #
      # Gather Global throughput related metrics and report them in bits/sec
      #
      def get_throughput(snmp = nil)
        metrics = { }
        snmp    = snmp_manager unless snmp

        if snmp
          res = gather_snmp_metrics_array([OID_SYS_STAT_CLIENT_BYTES_IN, OID_SYS_STAT_CLIENT_BYTES_OUT,
                                           OID_SYS_STAT_SERVER_BYTES_IN, OID_SYS_STAT_SERVER_BYTES_OUT],
                                           snmp)

          # Bail out if we didn't get anything
          return metrics if res.empty?

          metrics["Throughput/Client/In"]  = (res[0].to_f * 8)
          metrics["Throughput/Client/Out"] = (res[1].to_f * 8)
          metrics["Throughput/Server/In"]  = (res[2].to_f * 8)
          metrics["Throughput/Server/Out"] = (res[3].to_f * 8)
          tot = 0
          res.each { |x| tot += x.to_f }
          metrics["Throughput/Total"] = (tot * 8)
        end

        return metrics
      end


      #
      # Gather Global HTTP related metrics in req/sec
      #
      def get_http_requests(snmp = nil)
        metrics = { }
        snmp    = snmp_manager unless snmp

        if snmp
          res = gather_snmp_metrics_array([OID_SYS_HTTP_STAT_NUMBER_REQS, OID_SYS_HTTP_STAT_GET_REQS, OID_SYS_HTTP_STAT_POST_REQS,
                                           OID_SYS_HTTP_STAT_V9_REQS,     OID_SYS_HTTP_STAT_V10_REQS, OID_SYS_HTTP_STAT_V11_REQS],
                                         snmp)

          # Bail out if we didn't get anything
          return metrics if res.empty?

          metrics["HTTP/Method/All"]           = res[0]
          metrics["HTTP/Method/Get"]           = res[1]
          metrics["HTTP/Method/Post"]          = res[2]
          metrics["HTTP/Version/v0.9/Request"] = res[3]
          metrics["HTTP/Version/v1.0/Request"] = res[4]
          metrics["HTTP/Version/v1.1/Request"] = res[5]
        end

        return metrics
      end


      #
      # Gather Global HTTP related metrics in resp/sec
      #
      def get_http_responses(snmp = nil)
        metrics = { }
        snmp    = snmp_manager unless snmp

        if snmp
          res = gather_snmp_metrics_array([OID_SYS_HTTP_STAT_RESP_2XX_CNT,    OID_SYS_HTTP_STAT_RESP_3XX_CNT,    OID_SYS_HTTP_STAT_RESP_4XX_CNT,
                                           OID_SYS_HTTP_STAT_RESP_5XX_CNT,    OID_SYS_HTTP_STAT_V9_RESP,         OID_SYS_HTTP_STAT_V10_RESP,
                                           OID_SYS_HTTP_STAT_V11_RESP,        OID_SYS_HTTP_STAT_RESP_BUCKET_1K,  OID_SYS_HTTP_STAT_RESP_BUCKET_4K,
                                           OID_SYS_HTTP_STAT_RESP_BUCKET_16K, OID_SYS_HTTP_STAT_RESP_BUCKET_32K],
                                         snmp)

          # Bail out if we didn't get anything
          return metrics if res.empty?

          metrics["HTTP/Response Code/2xx"]        = res[0]
          metrics["HTTP/Response Code/3xx"]        = res[1]
          metrics["HTTP/Response Code/4xx"]        = res[2]
          metrics["HTTP/Response Code/5xx"]        = res[3]
          metrics["HTTP/Version/v0.9/Response"]    = res[4]
          metrics["HTTP/Version/v1.0/Response"]    = res[5]
          metrics["HTTP/Version/v1.1/Response"]    = res[6]
          metrics["HTTP/Response Size/1k Bucket"]  = res[7]
          metrics["HTTP/Response Size/4k Bucket"]  = res[8]
          metrics["HTTP/Response Size/16k Bucket"] = res[9]
          metrics["HTTP/Response Size/32k Bucket"] = res[10]
        end

        return metrics
      end


      #
      # HTTP Compression Stats in bits/sec
      #
      def get_http_compression(snmp = nil)
        metrics = { }
        snmp    = snmp_manager unless snmp

        if snmp
          res = gather_snmp_metrics_array([OID_SYS_HTTP_COMPRESSION_STAT_PRECOMPRESS_BYTES,       OID_SYS_HTTP_COMPRESSION_STAT_POSTCOMPRESS_BYTES,
                                           OID_SYS_HTTP_COMPRESSION_STAT_HTML_PRECOMPRESS_BYTES,  OID_SYS_HTTP_COMPRESSION_STAT_HTML_POSTCOMPRESS_BYTES,
                                           OID_SYS_HTTP_COMPRESSION_STAT_CSS_PRECOMPRESS_BYTES,   OID_SYS_HTTP_COMPRESSION_STAT_CSS_POSTCOMPRESS_BYTES,
                                           OID_SYS_HTTP_COMPRESSION_STAT_JS_PRECOMPRESS_BYTES,    OID_SYS_HTTP_COMPRESSION_STAT_JS_POSTCOMPRESS_BYTES,
                                           OID_SYS_HTTP_COMPRESSION_STAT_XML_PRECOMPRESS_BYTES,   OID_SYS_HTTP_COMPRESSION_STAT_XML_POSTCOMPRESS_BYTES,
                                           OID_SYS_HTTP_COMPRESSION_STAT_SGML_PRECOMPRESS_BYTES,  OID_SYS_HTTP_COMPRESSION_STAT_SGML_POSTCOMPRESS_BYTES,
                                           OID_SYS_HTTP_COMPRESSION_STAT_PLAIN_PRECOMPRESS_BYTES, OID_SYS_HTTP_COMPRESSION_STAT_PLAIN_POSTCOMPRESS_BYTES,
                                           OID_SYS_HTTP_COMPRESSION_STAT_OCTET_PRECOMPRESS_BYTES, OID_SYS_HTTP_COMPRESSION_STAT_OCTET_POSTCOMPRESS_BYTES,
                                           OID_SYS_HTTP_COMPRESSION_STAT_IMAGE_PRECOMPRESS_BYTES, OID_SYS_HTTP_COMPRESSION_STAT_IMAGE_POSTCOMPRESS_BYTES,
                                           OID_SYS_HTTP_COMPRESSION_STAT_VIDEO_PRECOMPRESS_BYTES, OID_SYS_HTTP_COMPRESSION_STAT_VIDEO_POSTCOMPRESS_BYTES,
                                           OID_SYS_HTTP_COMPRESSION_STAT_AUDIO_PRECOMPRESS_BYTES, OID_SYS_HTTP_COMPRESSION_STAT_AUDIO_POSTCOMPRESS_BYTES,
                                           OID_SYS_HTTP_COMPRESSION_STAT_OTHER_PRECOMPRESS_BYTES, OID_SYS_HTTP_COMPRESSION_STAT_OTHER_POSTCOMPRESS_BYTES],
                                         snmp)

          # Bail out if we didn't get anything
          return metrics if res.empty?

          vals = bytes_to_bits(res)

          metrics["HTTP/Compression/Total/Pre"]       = vals[0]
          metrics["HTTP/Compression/Total/Post"]      = vals[1]
          metrics["HTTP/Compression/HTML/Pre"]        = vals[2]
          metrics["HTTP/Compression/HTML/Post"]       = vals[3]
          metrics["HTTP/Compression/CSS/Pre"]         = vals[4]
          metrics["HTTP/Compression/CSS/Post"]        = vals[5]
          metrics["HTTP/Compression/Javascript/Pre"]  = vals[6]
          metrics["HTTP/Compression/Javascript/Post"] = vals[7]
          metrics["HTTP/Compression/XML/Pre"]         = vals[8]
          metrics["HTTP/Compression/XML/Post"]        = vals[9]
          metrics["HTTP/Compression/SGML/Pre"]        = vals[10]
          metrics["HTTP/Compression/SGML/Post"]       = vals[11]
          metrics["HTTP/Compression/Plain/Pre"]       = vals[12]
          metrics["HTTP/Compression/Plain/Post"]      = vals[13]
          metrics["HTTP/Compression/Octet/Pre"]       = vals[14]
          metrics["HTTP/Compression/Octet/Post"]      = vals[15]
          metrics["HTTP/Compression/Image/Pre"]       = vals[16]
          metrics["HTTP/Compression/Image/Post"]      = vals[17]
          metrics["HTTP/Compression/Video/Pre"]       = vals[18]
          metrics["HTTP/Compression/Video/Post"]      = vals[19]
          metrics["HTTP/Compression/Audio/Pre"]       = vals[20]
          metrics["HTTP/Compression/Audio/Post"]      = vals[21]
          metrics["HTTP/Compression/Other/Pre"]       = vals[22]
          metrics["HTTP/Compression/Other/Post"]      = vals[23]
        end

        return metrics
      end



      #
      # Gather TCP Statistics in conn
      #
      def get_tcp_connections(snmp = nil)
        metrics = { }
        snmp    = snmp_manager unless snmp

        if snmp
          res = gather_snmp_metrics_array([OID_SYS_TCP_STAT_OPEN, OID_SYS_TCP_STAT_CLOSE_WAIT, OID_SYS_TCP_STAT_FIN_WAIT,
                                           OID_SYS_TCP_STAT_TIME_WAIT],
                                         snmp)

          # Bail out if we didn't get anything
          return metrics if res.empty?

          metrics["TCP/Connection State/Open"]       = res[0]
          metrics["TCP/Connection State/Wait/Close"] = res[1]
          metrics["TCP/Connection State/Wait/FIN"]   = res[2]
          metrics["TCP/Connection State/Wait/TIME"]  = res[3]
        end

        return metrics
      end


      #
      # Gather TCP Segment statistics
      #
      def get_tcp_segment_rates(snmp = nil)
        metrics = { }
        snmp    = snmp_manager unless snmp

        if snmp
          res = gather_snmp_metrics_array([OID_SYS_TCP_STAT_RXBADSEG, OID_SYS_TCP_STAT_RXOOSEG,
                                           OID_SYS_TCP_STAT_TXREXMITS],
                                         snmp)

          # Bail out if we didn't get anything
          return metrics if res.empty?

          metrics["TCP/Segments/Received Malformed"]    = res[0]
          metrics["TCP/Segments/Received Out of Order"] = res[1]
          metrics["TCP/Segments/Retransmitted"]         = res[2]
        end

        return metrics
      end


      #
      # Gather TCP Error statistics
      #
      def get_tcp_error_rates(snmp = nil)
        metrics = { }
        snmp    = snmp_manager unless snmp

        if snmp
          res = gather_snmp_metrics_array([OID_SYS_TCP_STAT_RXRST, OID_SYS_TCP_STAT_RXBADSUM], snmp)

          # Bail out if we didn't get anything
          return metrics if res.empty?

          metrics["TCP/Errors/Received/Resets"]                = res[0]
          metrics["TCP/Errors/Received/Bad Checksums"]         = res[1]
        end

        return metrics
      end


      #
      # Gather TCP Syn statistics
      #
      def get_tcp_syn_rates(snmp = nil)
        metrics = { }
        snmp    = snmp_manager unless snmp

        if snmp
          res = gather_snmp_metrics_array([OID_SYS_TCP_STAT_RXCOOKIE, OID_SYS_TCP_STAT_RXBADCOOKIE,
                                           OID_SYS_TCP_STAT_SYNCACHEOVER, OID_SYS_STAT_HARD_SYNCOOKIE_GEN, OID_SYS_STAT_HARD_SYNCOOKIE_DET],
                                         snmp)

          # Bail out if we didn't get anything
          return metrics if res.empty?

          metrics["TCP/SYN/Received SYN-Cookies"]           = res[0]
          metrics["TCP/SYN/Bad SYN-Cookies"]                = res[1]
          metrics["TCP/SYN/SYN-cache Overflows"]            = res[2]
          metrics["TCP/SYN/Hardware SYN-Cookies Generated"] = res[3]
          metrics["TCP/SYN/Hardware SYN-Cookies Detected"]  = res[4]
        end

        return metrics
      end


      #
      # Gather TCP Statistics in conn/sec
      #
      def get_tcp_connection_rates(snmp = nil)
        metrics = { }
        snmp    = snmp_manager unless snmp

        if snmp
          res = gather_snmp_metrics_array([OID_SYS_TCP_STAT_ACCEPTS,  OID_SYS_TCP_STAT_ACCEPTFAILS,
                                           OID_SYS_TCP_STAT_CONNECTS, OID_SYS_TCP_STAT_CONNFAILS,
                                           OID_SYS_TCP_STAT_EXPIRES,  OID_SYS_TCP_STAT_ABANDONS],
                                         snmp)

          # Bail out if we didn't get anything
          return metrics if res.empty?

          metrics["TCP/Accepts"]                 = res[0]
          metrics["TCP/Accept Fails"]            = res[1]
          metrics["TCP/Connections/Established"] = res[2]
          metrics["TCP/Connections/Failed"]      = res[3]
          metrics["TCP/Connections/Expired"]     = res[4]
          metrics["TCP/Connections/Abandoned"]   = res[5]
        end

        return metrics
      end

    end
  end
end

