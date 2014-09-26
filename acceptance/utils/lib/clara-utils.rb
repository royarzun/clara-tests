require 'ffi-rzmq'
require 'rubygems'

Thread.abort_on_exception = true

P_EXTERNAL_IN  = "7771"
P_EXTERNAL_OUT = "7772"
  
DISCOVERY_LIST_SERVICES_ENGINE = "list_services_by_engine"
DISCOVERY_LIST_SERVICES_HOST   = "list_services_by_host"
DISCOVERY_LIST_DPES            = "list_dpes"

class ClaraUtils
  def initialize(platform_host)
    @context = ZMQ::Context.new
    @name = "DiscoveryQuery"
    @platform = platform_host
    @discovery = platform_host + ":" + "Discovery"

    @socket_out = _socket ZMQ::PUB, platform_host, P_EXTERNAL_IN
    @socket_in  = _socket ZMQ::SUB, platform_host, P_EXTERNAL_OUT

    _subscribe()
  end
  
  def _socket(socket_type, host, port)
    connection = @context.socket(socket_type)
    connection.connect("tcp://" + host.to_s + ":" + port.to_s)
    sleep 0.1
    return connection
  end

  def _subscribe
    @socket_in.setsockopt ZMQ::SUBSCRIBE, @name
    @thread = Thread.new { _callback() }
  end

  def _callback
    res = []
    while true
      @socket_in.recv_strings(res)
      if res
        break
      end
    end
    return res
  end

  def request(action, value)
    message = [@discovery.to_s,@name.to_s,action.to_s,value.to_s]
    @socket_out.send_strings message
  end

  def wait_response
    @thread.join
    return @thread.value
  end
end

def list_dpes(platform_addr)
  query = ClaraUtils.new(platform_addr.to_s)
  query.request DISCOVERY_LIST_DPES,""
  query.wait_response
end

def list_service_engine(platform_addr)
  query = ClaraUtils.new(platform_addr.to_s)
  query.request DISCOVERY_LIST_SERVICE_ENGINE,""
  query.wait_response
end 

def list_service_host(platform_addr)
  query = ClaraUtils.new(platform_addr.to_s)
  query.request DISCOVERY_LIST_SERVICES_HOST,""
  a = query.wait_response
  return a
end 
