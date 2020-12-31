#coding: utf-8
#$LOAD_PATH.push('/opt/local/lib/ruby/gems/1.8/gems/twitter-0.7.0/lib')
#require 'twitter'

module Atgc

  class VM

    class ProgramError < StandardError; end

    def self.run(insns)
      new(insns).run
    end

    def initialize(insns)
      @insns  = insns
      @stack  = []
      @heap   = {}
      @labels = find_labels(@insns)
    end

    def run
      return_to = []
      pc = 0
      while pc < @insns.size
        insn, arg = *@insns[pc]
        
        case insn
        when :push
          push(arg)
        when :dup
          push(@stack[-1])
        when :copy
          push(@stack[-(arg+1)])
        when :swap
          y, x = pop, pop
          push(y)
          push(x)
        when :discard
          pop
        when :slide
          x = pop
          arg.times do 
            pop
          end
          push(x)

        when :add
          y, x = pop, pop
          push(x + y)
        when :sub
          y, x = pop, pop
          push(x - y)
        when :mul
          y, x = pop, pop
          push(x * y)
        when :div
          y, x = pop, pop
          push(x / y)
        when :mod
          y, x = pop, pop
          push(x % y)

        when :heap_write
          value, address = pop, pop
          @heap[address] = value
        when :heap_read
          address = pop
          value = @heap[address]
          if value.nil?
            raise ProgramError, "ヒープ未初期化呼び出し(address = #{address})"
          end
          push(value)
        when :label
        when :jump
          pc = jump_to(arg)
        when :jump_zero
          if pop == 0
            pc = jump_to(arg)
          end
        when :jump_negative
          if pop < 0
            pc = jump_to(arg)
          end
        when :call
          return_to.push(pc)
          pc = jump_to(arg)
        when :return
          pc = return_to.pop
          raise ProgramError, "サブルーチンの外からreturnしようとした" if pc.nil
        when :exit
          return

        when :char_out
          print pop.chr
        when :num_out
          print pop
        when :char_in
          address = pop
          @heap[address] = $stdin.getc.ord
        when :num_in
          address = pop
          @heap[address] = $stdin.gets.to_i
        when :tweet
          text = ""
          @stack.each{|c| text += c.chr}
          httpauth = Twitter::HTTPAuth.new('*****', '*****')
          client = Twitter::Base.new(httpauth)
          client.update(text)
        end
        
        pc += 1
      end
      raise ProgramError, "Programの最後はexit命令"
    end

    private
    
    def find_labels(insns)
      labels = {}
      insns.each_with_index do |item, i|
        insn, arg = *item
        if insn == :label
          labels[arg] ||= i
        end
      end
      labels
    end

    def jump_to(name)
      pc = @labels[name]
      raise ProgramError, "ジャンプ先が見つからず" if pc.nil?
      pc
    end

    def push(item)
      unless item.is_a?(Integer)
        raise ProgramError, "整数以外(#{item})をプッシュしようとした"
      end
      @stack.push(item)
    end

    def pop
      item = @stack.pop
      raise ProgramError, "空のスタックをポップしようとした" if item.nil?
      item
    end

  end
end

if $0 == __FILE__
  Whitespace::VM.run([[:push, 1], [:num_out], [:exit]])
end
