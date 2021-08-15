event Register:
    name: String[64]

event Update:
    oldName: String[64]
    newName: String[64]

event Unregister:
    name: String[64]

struct Info:
    exists: bool
    registeredAtBlock: uint256
    name: String[64]

names: public(HashMap[address, Info])

@external
def update(_name : String[64]):
    """
    @dev Register a name.
    @param _name The name to register or update.
    """
    info: Info = self.names[msg.sender]
    if not info.exists:
        new_info: Info = empty(Info)
        new_info.exists = True
        new_info.registeredAtBlock = block.number
        new_info.name = _name
        self.names[msg.sender] = new_info
        log Register(_name)
    elif info.name == _name:
        raise "Name did not need to change."
    else:
        info.name = _name
        oldName: String[64] = info.name
        self.names[msg.sender] = info
        log Update(oldName, _name)

@external
def unregister():
    info: Info = self.names[msg.sender]
    if info.exists:
        self.names[msg.sender] = empty(Info)
        log Unregister(info.name)
    else:
        raise "You do not have a name to unregister."