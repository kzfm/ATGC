require 'atgc/compiler'
require 'atgc/vm'

module Atgc

  def self.run(src)
    insns = Atgc::Compiler.compile(src)
    Atgc::VM.run(insns)
  end
end
