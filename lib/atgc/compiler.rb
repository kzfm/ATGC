# coding: utf-8
require 'strscan'

module Atgc

  class Compiler
    
    class ProgramError < StandardError; end

    NUM = /([gc]+)a/
    LABEL = NUM

    def self.compile(src)
      new(src).compile
    end

    def initialize(src)
      @src = src
      @s = nil
    end

    def compile
      @s = StringScanner.new(bleach(@src))
      insns = []
      until @s.eos?
        insns.push(step)
      end
      insns
    end

    private
    
    def bleach(src)
      src.gsub(/[^atgc]/,"")
    end

    def step
      case
      when @s.scan(/cc#{NUM}/)       then [:push, num(@s[1])]
      when @s.scan(/cac/)            then [:dup ]
      when @s.scan(/ctc#{NUM}/)      then [:copy,num(@s[1])]
      when @s.scan(/cat/)            then [:swap]
      when @s.scan(/caa/)            then [:discard]
      when @s.scan(/cta#{NUM}/)      then [:slide, num(@s[1])]

      when @s.scan(/tccc/)           then [:add]
      when @s.scan(/tcct/)           then [:sub]
      when @s.scan(/tcca/)           then [:mul]      
      when @s.scan(/tctc/)           then [:div]
      when @s.scan(/tctt/)           then [:mod]

      when @s.scan(/ttc/)            then [:heap_write]
      when @s.scan(/ttt/)            then [:heap_read]

      when @s.scan(/acc#{LABEL}/)    then [:label, label(@s[1])]
      when @s.scan(/actt#{LABEL}/)   then [:call, label(@s[1])]
      when @s.scan(/aca#{LABEL}/)    then [:jump, label(@s[1])]
      when @s.scan(/atc#{LABEL}/)    then [:jump_zero, label(@s[1])]
      when @s.scan(/att#{LABEL}/)    then [:jump_negative, label(@s[1])]
      when @s.scan(/ata/)            then [:return]
      when @s.scan(/aaa/)            then [:exit]

      when @s.scan(/tacc/)           then [:char_out]
      when @s.scan(/tact/)           then [:num_out]
      when @s.scan(/tatc/)           then [:char_in]
      when @s.scan(/tatt/)           then [:num_in]
      when @s.scan(/tatg/)           then [:tweet]
      else
        raise ProgramError, "どの命令にもマッチせず"
      end
    end

    def num(str)
      if str !~ /\A[gc]+\z/
        raise ArgumentError, "数値はgc(#{str.inspect})"
      end

      num = str.sub(/\Ag/, "+").
        sub(/\Ac/, "-").
        gsub(/g/, "0").
        gsub(/c/, "1")
      num.to_i(2)
    end

    def label(str)
      str
    end

  end
end

if $0 == __FILE__
  p Atgc::Compiler.compile("ccgcatactaaa")
end
