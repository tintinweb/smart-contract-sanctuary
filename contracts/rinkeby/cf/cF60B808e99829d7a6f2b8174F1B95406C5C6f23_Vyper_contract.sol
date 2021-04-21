# @version 0.2.4

interface MERC20:
    def mint(_to: address, _value: uint256) -> bool: nonpayable

token: public(address)


@external
def __init__(_token: address):
    self.token = _token

@external
@nonreentrant('lock')
def mint(gauge_addr: address):
    MERC20(self.token).mint(msg.sender, 100000000000000000000)