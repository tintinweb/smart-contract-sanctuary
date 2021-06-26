# @version ^0.2.12

testVar: public(uint256)

event TestEvent:
    testVar: uint256

@external
def __init__():
    pass


@external
def test_call(_value: uint256) -> uint256:
    self.testVar = _value
    log TestEvent(_value)

    return _value