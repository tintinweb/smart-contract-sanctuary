# @version 0.2.11
"""
@title Pool Migrator
@author Curve.fi
@notice Zap for moving liquidity between Curve factory pools in a single transaction
@license MIT
"""

interface ERC20:
    def approve(_spender: address, _amount: uint256): nonpayable

interface Swap:
    def transferFrom(_owner: address, _spender: address, _amount: uint256) -> bool: nonpayable
    def add_liquidity(_amounts: uint256[2], _min_mint_amount: uint256, _receiver: address) -> uint256: nonpayable
    def remove_liquidity(_burn_amount: uint256, _min_amounts: uint256[2]) -> uint256[2]: nonpayable
    def coins(i: uint256) -> address: view


# pool -> coins are approved?
is_approved: HashMap[address, bool]


@external
def migrate_to_new_pool(_old_pool: address, _new_pool: address, _amount: uint256) -> uint256:
    """
    @notice Migrate liquidity between two pools
    @dev Each pool must be deployed by the curve factory and contain identical
         assets. The migrator must have approval to transfer `_old_pool` tokens
         on behalf of the caller.
    @param _old_pool Address of the pool to migrate from
    @param _new_pool Address of the pool to migrate into
    @param _amount Number of `_old_pool` LP tokens to migrate
    @return uint256 Number of `_new_pool` LP tokens received
    """
    Swap(_old_pool).transferFrom(msg.sender, self, _amount)
    amounts: uint256[2] = Swap(_old_pool).remove_liquidity(_amount, [0, 0])

    if not self.is_approved[_new_pool]:
        for i in range(2):
            coin: address = Swap(_new_pool).coins(i)
            ERC20(coin).approve(_new_pool, MAX_UINT256)
        self.is_approved[_new_pool] = True

    return Swap(_new_pool).add_liquidity(amounts, 0, msg.sender)