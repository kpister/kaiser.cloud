def handle_command(ws, command)
    error = ''
    commands = ['l', 'r', '[', ']', '+', '-']

    #unknown command error
    ws[:history] += command
    data = ws[:tape][ws[:data_ptr]].to_i

    # Handle instruction pointer
    if command == '[' && data == 0
        # JUMP forward
        # if there is nothing, FREEZE
    elsif command == ']' && data != 0
        # JUMP backward
        # if there is nothing, @error
    else
        ws[:instruction_ptr] += 1 
    end

    # Handle data updates
    ws[:tape][ws[:data_ptr]] = (data + 1).to_s if command == '+'
    ws[:tape][ws[:data_ptr]] = (data - 1).to_s if command == '-'

    # Handle data pointer 
    if command == 'l'
        if ws[:data_ptr] > 0
            error = 'Cannot move data pointer farther left'
        else
            ws[:data_ptr] -= 1
        end
    end
    if command == 'r'
        ws[:data_ptr] += 1
        if ws[:tape].length - 1 < ws[:data_ptr]
            ws[:tape] += '0'
        end
    end
    return ws, error
end
