
class Workstation < Sequel::Model(DB[:workstations])
    attr_accessor :instruction_ptr, :data_ptr, :tape, :history
    #instruction pointer points to history to allow for looping
    #data pointer points to tape
end