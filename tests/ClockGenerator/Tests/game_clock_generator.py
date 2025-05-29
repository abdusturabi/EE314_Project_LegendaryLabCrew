import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
import random

def to_hex(obj): # Convert to hex only if signal is longer than 16 bits
    try:
        binary_str = str(obj)
        binary_str = binary_str.strip()
        if(len(binary_str)>=16  and  binary_str.replace("1","").replace("0","") == ""):
            value = int(binary_str,2)
            hex_len = (len(binary_str)+3)//4
            hex_str = format(value, '0{}x'.format(hex_len))
            return "0x"+hex_str
    except Exception as e:
        pass
    return obj
#This function helps us see the values of the signals in our design.
def Log_Design(dut):
    #Log whatever signal you want from the datapath, called before positive clock edge
    s1 = "dut"
    obj1 = dut
    wires = []
    submodules = []
    for attribute_name in dir(obj1):
        attribute = getattr(obj1, attribute_name)
        if attribute.__class__.__module__.startswith('cocotb.handle'):
            if(attribute.__class__.__name__ == 'ModifiableObject'):
                wires.append((attribute_name, to_hex(attribute.value)) )
            elif(attribute.__class__.__name__ == 'HierarchyObject'):
                submodules.append((attribute_name, attribute.get_definition_name()) )
            elif(attribute.__class__.__name__ == 'HierarchyArrayObject'):
                submodules.append((attribute_name, f"[{len(attribute)}]") )
            elif(attribute.__class__.__name__ == 'NonHierarchyIndexableObject'):
                wires.append((attribute_name, [to_hex(v) for v in attribute.value] ) )
            #else:
                #print(f"{attribute_name}: {type(attribute)}")
                
        #else:
            #print(f"{attribute_name}: {type(attribute)}")
    #for sub in submodules:
    #    print(f"{s1}.{sub[0]:<16}is {sub[1]}")
    for wire in wires:
        print(f"{s1}.{wire[0]:<16}= {wire[1]}")


@cocotb.test()
async def game_clock_generator(dut):
 
    test_failed = False  
    
    

    """Test the simple game FSM in EE314exp4.v"""

    for _wait_ in range(2):
        await RisingEdge(dut.CLOCK)

    async def Test_State(dut, initial_state, key,desired_state, desired_flags):
        """
        Test the FSM state transition.
        :param dut: The DUT object.
        :param initial_state: The initial state of the FSM.
        :param key: The key to press (0 for pressed, 1 for released).
        :param desired_state: The desired state of the FSM.
        """
        set_key([0, 0, 0])  # Release all keys
        await RisingEdge(dut.CLOCK)  # Wait for the clock edge
        await RisingEdge(dut.CLOCK)  # Wait for the clock edge again
        await Timer(1, units='us')

        # Set the initial state
        if (initial_state == IDLE_STATE):
            await RisingEdge(dut.CLOCK)
        elif (initial_state == LEFT_STATE):
            set_key([1, 0, 0])
            await RisingEdge(dut.CLOCK)
        elif (initial_state == RIGHT_STATE):
            set_key([1, 0, 0])
            await RisingEdge(dut.CLOCK)
        elif (initial_state == ATTACK_START_STATE):
            set_key([0, 1, 0])
            await RisingEdge(dut.CLOCK)
        elif (initial_state == ATTACK_ACTIVE_STATE):
            set_key([0, 1, 0])
            await RisingEdge(dut.CLOCK)
            set_key([0, 0, 0])
            await RisingEdge(dut.CLOCK)
        
        await Timer(1, units='us')

        # Set the key to the desired state
        set_key(key)
        await RisingEdge(dut.CLOCK)

        await Timer(1, units='us')

        # Mask the first 3 bits of the LEDR value
        try:
            result =  (((dut.ATTACK_FLAG.value & 0b1) << 2) | 
                        ((dut.ATTACK_DIR_FLAG.value & 0b1) << 1) | 
                            (dut.MOVE_FLAG.value & 0b1))
            final_state = dut.STATE.value.integer
        except ValueError:
            print("ValueError:")
            print(f"ATTACK_FLAG: {dut.ATTACK_FLAG.value}")
            print(f"ATTACK_DIR_FLAG: {dut.ATTACK_DIR_FLAG.value}")
            print(f"MOVE_FLAG: {dut.MOVE_FLAG.value}")
            print(f"STATE: {dut.STATE.value}")

        # Check if the current state matches the desired state
        if (final_state == desired_state) and (result == desired_flags):
            print(f"\nState transition from {initial_state} to {desired_state} successful.")
        else:
            test_failed = True
            print(f"\nState transition from {initial_state} to {desired_state} failed. \nExpected: {desired_state}, Got: {final_state}\n \nFlags: {result}, Expected Flags: {desired_flags}")
            Log_Design(dut)

    # MAIN CASE
    # KEY port: [3]=Left, [2]=Attack, [1]=Right, [0]=Clock; aktif-low
    # LEDR[0]=Move_flag, LEDR[1]=Attack_dir_flag, LEDR[2]=Attack_flag

    # 1. IDLE
    await Test_State(dut, IDLE_STATE, [0, 0, 0], IDLE_STATE, 0b000) # IDLE
    await Test_State(dut, IDLE_STATE, [1, 0, 0], LEFT_STATE, 0b001) # LEFT
    await Test_State(dut, IDLE_STATE, [0, 1, 0], ATTACK_START_STATE, 0b100) # ATTACK_START
    await Test_State(dut, IDLE_STATE, [0, 0, 1], RIGHT_STATE, 0b001) # RIGHT

    # 2. LEFT
    await Test_State(dut, LEFT_STATE, [0, 0, 0], IDLE_STATE, 0b000) # IDLE
    await Test_State(dut, LEFT_STATE, [1, 0, 0], LEFT_STATE, 0b001) # LEFT
    await Test_State(dut, LEFT_STATE, [0, 1, 0], ATTACK_START_STATE, 0b100) # ATTACK_START
    await Test_State(dut, LEFT_STATE, [0, 0, 1], RIGHT_STATE, 0b001) # RIGHT

    # 3. RIGHT
    await Test_State(dut, RIGHT_STATE, [0, 0, 0], IDLE_STATE, 0b000) # IDLE
    await Test_State(dut, RIGHT_STATE, [1, 0, 0], LEFT_STATE, 0b001) # LEFT
    await Test_State(dut, RIGHT_STATE, [0, 1, 0], ATTACK_START_STATE, 0b100) # ATTACK_START
    await Test_State(dut, RIGHT_STATE, [0, 0, 1], RIGHT_STATE, 0b001) # RIGHT

    # 4. ATTACK_START
    await Test_State(dut, ATTACK_START_STATE, [0, 0, 0], ATTACK_ACTIVE_STATE, 0b100)
    await Test_State(dut, ATTACK_START_STATE, [1, 0, 0], ATTACK_ACTIVE_STATE, 0b100)
    await Test_State(dut, ATTACK_START_STATE, [0, 1, 0], ATTACK_ACTIVE_STATE, 0b100)
    await Test_State(dut, ATTACK_START_STATE, [0, 0, 1], ATTACK_ACTIVE_STATE, 0b100)

    # 5. ATTACK_ACTIVE
    await Test_State(dut, ATTACK_ACTIVE_STATE, [0, 0, 0], IDLE_STATE, 0b000)
    await Test_State(dut, ATTACK_ACTIVE_STATE, [1, 0, 0], IDLE_STATE, 0b000)
    await Test_State(dut, ATTACK_ACTIVE_STATE, [0, 1, 0], IDLE_STATE, 0b000)
    await Test_State(dut, ATTACK_ACTIVE_STATE, [0, 0, 1], IDLE_STATE, 0b000)

    # DIR_ATTACK_STATE TEST
    set_key([0, 0, 0])
    await RisingEdge(dut.CLOCK)
    await RisingEdge(dut.CLOCK)
    set_key([1, 0, 0]) # LEFT KEY
    await RisingEdge(dut.CLOCK)
    set_key([0, 1, 0]) # ATTACK KEY
    await Timer(1, units='us')

    if (0b111 & ((dut.ATTACK_FLAG.value.integer << 2) | 
                    (dut.ATTACK_DIR_FLAG.value.integer << 1) | 
                    (dut.MOVE_FLAG.value.integer))) == 0b011:
        print("Directional Attack Flag Working!.")
    else:
        test_failed = True
        print("Directional Attack Flag NOT Working!.")
        print(f"Flags: {dut.ATTACK_FLAG.value}, \n{dut.ATTACK_DIR_FLAG.value}, \n{dut.MOVE_FLAG.value}")
            
    # Final assertion for the overall result
    if test_failed:
        raise AssertionError("Some test cases failed. Check logs for details.")
    else:
        cocotb.log.info("All test cases passed successfully!")