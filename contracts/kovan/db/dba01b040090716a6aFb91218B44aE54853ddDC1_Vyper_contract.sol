# @version 0.2.15

"""
@title Voting Escrow
@author Curve Finance
@license MIT
@notice Votes have a weight depending on time, so that users are
        committed to the future of (whatever they are voting for)
@dev Vote weight decays linearly over time. Lock time cannot be
     more than `MAXTIME` (4 years).
"""

data: public(uint256)

@view
@external
def get_delegated_to() -> (address, uint256, uint256, uint256):
    return (
        convert(shift(self.data, 96), address),
        shift(self.data, 80) % 2**16,
        shift(self.data, 40) % 2**40,
        self.data % 2**40
    )

@external
def delegate_boost(
    _receiver: address,
    _pct: uint256,
    _cancel_time: uint256,
    _expire_time: uint256
):
    data_temp: uint256 = shift(_pct, -80) + shift(_cancel_time, -40) + _expire_time
    self.data = data_temp + shift(convert(_receiver, uint256), -96)