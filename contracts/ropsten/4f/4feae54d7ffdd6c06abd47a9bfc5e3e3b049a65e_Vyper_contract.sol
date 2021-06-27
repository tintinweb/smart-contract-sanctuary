data: public(String[255])
creator: public(address)

@external
def __init__(_data: String[255]):
    self.creator = msg.sender
    self.data = _data