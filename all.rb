require 'pry'

class A

  def good
    '111'
  end

  private

  def bad
    '111'
  end
end

class B
  def call
    a = A.instance_methods - A.ancestors[1..-1].flat_map { |x| x.instance_methods }.uniq
    # => [:good]
    b = A.private_instance_methods - A.ancestors[1..-1].flat_map { |x| x.private_instance_methods }.uniq
    # => [:bad]
    #
    # A.protected_instance_methods # TODO: - этих тоже надо учесть !
    # NOTE: при таком подходе не будут учтены методы, которые объявлены в самом A, но тоже объявлены выше в иерархии..
    binding.pry
  end
end

# A.instance_methods - A.ancestors[1..-1].flat_map { |x| x.instance_methods }.uniq

B.new.call
