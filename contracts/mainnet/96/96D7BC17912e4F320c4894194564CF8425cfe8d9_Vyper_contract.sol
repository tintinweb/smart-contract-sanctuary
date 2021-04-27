# @version 0.2.12

from vyper.interfaces import ERC20

CURVE_APOOL: constant(address) = 0xDeBF20617708857ebe4F679508E7b7863a8A8EeE
AAVE_REWARD_DISTRIBUTOR: constant(address) = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5
CLAIM_FREQUENCY: constant(uint256) = 3600 * 6  # six hours

owner: public(address)
future_owner: public(address)

# [last update][receiver]
reward_data: uint256


@external
def __init__(_owner: address):
    self.owner = _owner


@external
def claim_rewards():
    reward_data: uint256 = self.reward_data
    if reward_data == 0:
        return

    assert convert(msg.sender, uint256) == reward_data % 2**160

    if block.timestamp > shift(reward_data, -160) + CLAIM_FREQUENCY:
        # claim rewards on behalf of pool and transfer to gauge
        raw_call(
            AAVE_REWARD_DISTRIBUTOR,
            concat(
                method_id("claimRewardsOnBehalf(address[],uint256,address,address)"),
                convert(32 * 4, bytes32),
                convert(MAX_UINT256, bytes32),
                convert(CURVE_APOOL, bytes32),
                convert(msg.sender, bytes32),
                convert(3, bytes32),
                convert(0x028171bCA77440897B824Ca71D1c56caC55b68A3, bytes32),  # aDAI
                convert(0xBcca60bB61934080951369a648Fb03DF4F96263C, bytes32),  # aUSDC
                convert(0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811, bytes32),  # aUSDT
            )
        )
        self.reward_data = shift(block.timestamp, 160) + convert(msg.sender, uint256)


@view
@external
def last_claim() -> uint256:
    return shift(self.reward_data, -160)


@view
@external
def reward_receiver() -> address:
    return convert(self.reward_data % 2**160, address)


@external
def set_reward_receiver(_reward_receiver: address):
    """
    @notice Set the reward reciever address
    @dev Setting to `ZERO_ADDRESS` disables claiming
    @param _reward_receiver Address that claimed stkAAVE is sent to
    """
    assert msg.sender == self.owner

    self.reward_data = convert(_reward_receiver, uint256)


@external
def commit_transfer_ownership(_future_owner: address):
    """
    @notice Transfer ownership of contract to `_future_owner`
    @param _future_owner Address to have ownership transferred to
    """
    assert msg.sender == self.owner

    self.future_owner = _future_owner


@external
def accept_transfer_ownership():
    """
    @notice Accept a pending ownership transfer
    """
    owner: address = self.future_owner
    assert msg.sender == owner

    self.owner = owner