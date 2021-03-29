"""
@title Greenwood Treasury
@notice Treasury contract for the Greenwood Protocol
@author Greenwood Labs
"""

# define the interfaces used by the contract
interface REGISTRY:
    def getAddress(_contract: String[20], _version: String[11], ) -> address: nonpayable
    def governance() -> address: nonpayable

# define the events emitted by the contract
event Fallback:
    value: uint256
    sender: address
    blockNumber: uint256
    
event SetRegistry:
    previousRegistry: address
    newRegistry: address
    governance: address
    blockNumber: uint256

event TransferERC20:
    amount: uint256
    asset: address
    governance: address
    blockNumber: uint256

event TransferETH:
    value: uint256
    governance: address
    blockNumber: uint256

# define the storage variables used by the contract
registry: public(address)

@external
def __init__(_registry: address):
    """
    @notice Contract constructor
    @param _registry The address of the Greenwood Registry
    """

    # set the address of the Escrow
    self.registry = _registry

@internal
def isGovernance(_caller: address, _role: String[20]) -> bool:
    """
    @notice Method for role-based security
    @param _caller The address that called the permissioned method
    @param _role The requested authorization level
    @return True if the caller is the Governance, False otherwise
    """

    # check if the requested role is "governance"
    if keccak256(_role) == keccak256("governance"):

        # get the address of the Governance from the Registry
        governance: address = REGISTRY(self.registry).governance()

        # return the equality comparison
        return governance == _caller

    # catch extraneous role arguments
    else:

        # revert
        raise "Unhandled role argument"

@external
@nonreentrant("erc20_lock")
def transferERC20(_amount: uint256, _asset: address):
    """
    @notice Transfers ERC20 tokens to the Governance
    @param _amount The amount of asset to transfer scaled by the asset's decimals
    @param _asset The underlying address of the asset to transfer
    """

    # require that the method caller is the Governance
    assert self.isGovernance(msg.sender, "governance") == True, "Only Governance can call this method"

    # get the address of the Governance from the Registry
    to: address = REGISTRY(self.registry).governance()

    # require that the Governance is not the zero address
    assert to != ZERO_ADDRESS

    # transfer collected fees to the Governance
    transferResponse: Bytes[32] = raw_call(
        _asset,
        concat(
            method_id("transfer(address,uint256)"),
            convert(to, bytes32),
            convert(_amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(transferResponse) > 0:
        assert convert(transferResponse, bool), "Failed safeTransfer"

    # emit a TransferERC20 event
    log TransferERC20(_amount, _asset, to, block.number)

    
@external
@nonreentrant("eth_lock")
def transferETH(_amount: uint256):
    """
    @notice Transfers ETH to the Governance
    @param _amount The amount of ETH to transfer in wei
    """

    # require that the method caller is the Governance
    assert self.isGovernance(msg.sender, "governance") == True, "Only Governance can call this method"

    # get the address of the Governance from the Registry
    to: address = REGISTRY(self.registry).governance()

    # require that the Governance is not the zero address
    assert to != ZERO_ADDRESS

    # send fees collected in ETH to the governance
    send(to, _amount)

    # emit a TransferETH event
    log TransferETH(_amount, to, block.number)

@external
@nonreentrant("registry_lock")
def setRegistry(_new_registry: address):
    """
    @notice Updates the address of the Registry
    @param _new_registry The address of the new Greenwood Registry
    @dev Only the Governance can call this method
    @dev Only call this method with a valid Greenwood Registry or subsequent calls will fail!
    """

    # require that the method caller is the Governance
    assert self.isGovernance(msg.sender, "governance") == True, "Only Governance can call this method"

    # get the previous Registry
    previousRegistry: address = self.registry

    # update the address of the Registry
    self.registry = _new_registry

    # emit a SetRegistry event
    log SetRegistry(previousRegistry, _new_registry, msg.sender, block.number)

@external
@payable
def __default__():
    """
    @notice Fallback function for receiving ETH
    """

    log Fallback(msg.value, msg.sender, block.number)