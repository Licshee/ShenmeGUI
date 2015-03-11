module ShenmeGUI

  class HookedArray < Array 
    
    @unhook_methods = %i{<< []= clear collect! compact! concat delete delete_at delete_if fill flatten! replace insert keep_if map map! pop push reject! replace rotate! select! shift shuffle! slice! sort! sort_by! uniq! unshift}
    @unhook_methods = Hash[@unhook_methods.collect{|x| [x, Array.instance_method(x)]}]

    def initialize(arr, owner)
      @owner = owner
      super(arr)
    end
    
    @unhook_methods.each do |k, v|
      define_method(k) do |*arr, &block|
        result = v.bind(self).call(*arr, &block)
        @owner.sync
        result
      end
    end

  end

  class HookedString < String
    @unhook_methods = %i{<< []= capitalize! chomp! chop! clear concat delete! downcase! encode! force_encoding gsub! insert lstrip! succ! next! prepend replace reverse! rstrip! slice! squeeze! strip! sub! swapcase! tr! tr_s! upcase!}
    @unhook_methods = Hash[@unhook_methods.collect{|x| [x, String.instance_method(x)]}]
    
    def initialize(str, owner)
      @owner = owner
      super(str)
    end

    @unhook_methods.each do |k, v|
      define_method(k) do |*arr, &block|
        result = v.bind(self).call(*arr, &block)
        @owner.sync
        result
      end
    end

  end
  
  class << self
    attr_accessor :elements, :socket
    attr_reader :this

    def hook(obj)
      case obj
        when String
          HookedString.new(obj, self)
        when Array
          HookedArray.new(obj, self)
        else
          obj
      end
    end

    def handle(msg)
      match_data = msg.match(/(.+?):(\d+)(?:->)?({.+?})?/)
      command = match_data[1].to_sym
      id = match_data[2].to_i
      if match_data[3]
        data = JSON.parse(match_data[3])
        data = Hash[data.keys.collect(&:to_sym).zip(data.values.collect{|x| hook x})]
      end
      target = elements[id]
      case command
        when :sync
          target.properties.update(data)
        else
          event_lambda = elements[id].events[command]
          @this = elements[id]
          result = ShenmeGUI.instance_exec(&event_lambda) if event_lambda
          @this = nil
          result

      end
      target
    end

    def app(params={}, &block)
      instance_eval(&block)
      File.open('index.html', 'w'){ |f| f.write elements[0].render }
      nil
    end

  end

  @elements = []
  @temp_stack = []

  def self.start!
    ws_thread = Thread.new do
      EM.run do
        EM::WebSocket.run(:host => "0.0.0.0", :port => 80) do |ws|
          ws.onopen do
            puts "WebSocket connection open"
            elements.each { |e| e.add_events; e.sync }
          end

          ws.onclose { puts "Connection closed" }

          ws.onmessage do |msg|
            puts "Recieved message: #{msg}"
            handle msg
          end
          
          @socket = ws
        end
      end
    end

    index_path = "#{Dir.pwd}/index.html"
    `start file:///#{index_path}`

    ws_thread.join
  rescue Interrupt
    puts 'bye~'
  end

end