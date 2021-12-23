storedData: immutable(uint256)
storedData2: immutable(address)
storedData3: immutable(int128)

@external
def __init__():
  storedData = block.timestamp
  storedData2 = msg.sender
  storedData3 = 123321

@view
@external
def returnStoredData() -> uint256:
    return storedData

@view
@external
def returnStoredData2() -> address:
    return storedData2

@view
@external
def returnStoredData3() -> int128:
    return storedData3