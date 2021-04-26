# @version ^0.2.12
dummyVal1: address
dummyVal2: address
appData1: public(uint256)
appData2: public(bytes32)


@external
def someFunc(_inp: uint256):
    self.appData1 = _inp


@external
def oneFunc(_addr: address):
    self.dummyVal1 = _addr