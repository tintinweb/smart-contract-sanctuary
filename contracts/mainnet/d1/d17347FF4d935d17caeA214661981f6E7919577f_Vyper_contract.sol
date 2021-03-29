"""
@title Greenwood Router
@notice Used to calculate instantaneous APR for Aave V2 and Compound
@author Greenwood Labs
"""

# define the interfaces used by the contract
interface CTOKEN:
    def borrowRatePerBlock() -> uint256: view

interface REGISTRY:
    def getAddress(_contract: String[20], _version: String[11], ) -> address: nonpayable
    def governance() -> address: nonpayable

interface STORE:
    def getAssetContext(_ticker: String[10]) -> AssetContext: view

# define the constants used by the contract
BLOCKS_PER_DAY: constant(decimal) = 5760.0
CONTRACT_PRECISION: constant(decimal) = 10000000000.0
ETH_PRECISION: constant(decimal) = 1000000000000000000.0

# define the events used by the contract
event SetRegistry:
    previousRegistry: address
    newRegistry: address
    governance: address
    blockNumber: uint256

# define the structs used by the contract
struct AssetContext:
    aToken: address
    aaveV2PriceFeed: address
    aaveV2LendingPool: address
    cToken: address
    compoundPriceFeed: address
    comptroller: address
    decimals: uint256
    underlying: address

struct Split:
    compoundSplit: uint256
    aaveV2Split: uint256
    borrowContext: AssetContext
    collateralContext: AssetContext

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
def isAuthorized(_caller: address, _role: String[20], _version: String[11]) -> bool:
    """
    @notice Method for role-based security
    @param _caller The address that called the permissioned method
    @param _role The requested authorization level
    @param _version The version of Greenwood to use
    @return True if the caller is authorized, False otherwise
    """

    # check if the requested role is "controller"
    if keccak256(_role) == keccak256("controller"):

        # get the address of the Controller from the Registry
        controller: address = REGISTRY(self.registry).getAddress("controller", _version)

        # return the equality comparison
        return controller == _caller
    
    # check if the requested role is "governance"
    elif keccak256(_role) == keccak256("governance"):

        # get the address of the Governance from the Registry
        governance: address = REGISTRY(self.registry).governance()

        # return the equality comparison
        return governance == _caller

    # catch extraneous role arguments
    else:

        # revert
        raise "Unhandled role argument"



@external
def split(_borrow_ticker: String[10], _collateral_ticker: String[10], _amount: uint256, _protocol: String[10], _store: address, _version: String[11]) -> Split:
    """
    @notice Calculate which lending protocol has the lowest APR for the given borrow request
    @param _borrow_ticker The ticker string of the asset that is being borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _amount The amount of asset being borrowed scaled by the asset's decimals
    @param _protocol The name of the underlying lending protocol for the loan
    @param _store The address of the Greenwood Store to use
    @param _version The version of the Greenwood Protocol to use
    @dev Only the Controller or the Governance can call this method
    @return Split struct
    """

    # require that the method is being called by the Controller or the Governance
    assert self.isAuthorized(msg.sender, "controller", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True, "Only Controller or Governance can call this method"

    # get the borrow asset context and the collateral asset context from the Store
    borrowContext: AssetContext = STORE(_store).getAssetContext(_borrow_ticker)
    collateralContext: AssetContext = STORE(_store).getAssetContext(_collateral_ticker)

    # assert that the contexts were returned from the Store
    assert borrowContext.underlying != ZERO_ADDRESS, "Borrow asset context has ZERO_ADDRESS for underlying"
    assert collateralContext.underlying != ZERO_ADDRESS, "Collateral asset context has ZERO_ADDRESS for underlying"

    # check if the specified lending protocol was Compound
    if keccak256(_protocol) == keccak256("compound"):
        
        # route 100% of the borrow to Compound
        return Split({
            compoundSplit: 100, 
            aaveV2Split: 0,                    
            borrowContext: borrowContext,
            collateralContext: collateralContext
        })

    # check if the specified lending protocol was Aave V2
    elif keccak256(_protocol) == keccak256("aavev2"):
        
        # route 100% of the borrow to Aave V2
        return Split({
            compoundSplit: 0, 
            aaveV2Split: 100,                    
            borrowContext: borrowContext,
            collateralContext: collateralContext
        })
        
    # check if no lending protocol was specified
    elif keccak256(_protocol) == keccak256(""):

        # check if the borrow asset is supported by both protocols
        if borrowContext.aToken != ZERO_ADDRESS and borrowContext.cToken != ZERO_ADDRESS:

            # call borrowRatePerBlock on the cToken contract and calculate instantaneous APR for Compound
            rate: decimal = convert(CTOKEN(borrowContext.cToken).borrowRatePerBlock(), decimal)
            t0: decimal = rate / ETH_PRECISION * BLOCKS_PER_DAY + 1.0
            t1: decimal = t0 * t0
            for i in range(362):
                t1 = t1 * t0
            t2: decimal = t1 - 1.0
            compoundAPR: uint256 = convert(t2 * CONTRACT_PRECISION, uint256)
            
            # call getReserveData on the Aave V2 LendingPool
            _response: Bytes[768] = raw_call(
                borrowContext.aaveV2LendingPool,
                concat(
                    method_id("getReserveData(address)"),
                    convert(borrowContext.underlying, bytes32)
                ),
                max_outsize=768
            )

            # parse the instantaneous APR for Aave V2
            # @dev getReserveData returns 12 items. currentVariableBorrowRate is the 5th item. each item is given 32 bytes in the list
            aaveAPR: uint256 = convert((convert(slice(_response, 128, 32), decimal) / convert(10 ** 26, decimal)) * CONTRACT_PRECISION, uint256)

            # check if the instantaneous APR for Aave V2 is less than the instantaneous APR for Compound
            if aaveAPR < compoundAPR:

                # route 100% of the borrow to Aave V2
                return Split({
                    compoundSplit: 0, 
                    aaveV2Split: 100,                    
                    borrowContext: borrowContext,
                    collateralContext: collateralContext
                })

            # check if the instantaneous APR for Compound is less than the instantaneous APR for Aave V2
            elif compoundAPR < aaveAPR:

                # route 100% of the borrow to Compound 
                return Split({
                    compoundSplit: 100,
                    aaveV2Split: 0,
                    borrowContext: borrowContext,
                    collateralContext: collateralContext
                })

            # handle matching instantaneous APRs
            else:

                # route 100% of the borrow to Compound 
                return Split({
                    compoundSplit: 100,
                    aaveV2Split: 0,
                    borrowContext: borrowContext,
                    collateralContext: collateralContext
                })

        # check if the borrow asset is only supported by Compound
        elif borrowContext.aToken == ZERO_ADDRESS and borrowContext.cToken != ZERO_ADDRESS:

            # route 100% of the borrow to Compound 
            return Split({
                compoundSplit: 100,
                aaveV2Split: 0,
                borrowContext: borrowContext,
                collateralContext: collateralContext
            })

        # check if the borrow asset is only supported by Aave V2
        elif borrowContext.aToken != ZERO_ADDRESS and borrowContext.cToken == ZERO_ADDRESS:

            # route 100% of the borrow to Aave V2 
            return Split({
                compoundSplit: 0,
                aaveV2Split: 100,
                borrowContext: borrowContext,
                collateralContext: collateralContext
            })

        # catch unsupported assets
        else:

            # revert
            raise "Unsupported borrow asset"

    # catch unsupported lending protocols
    else:

        # revert
        raise "Unsupported protocol"

@external
def setRegistry(_new_registry: address):
    """
    @notice Updates the address of the Registry
    @param _new_registry The address of the new Greenwood Registry
    @dev Only the Governance can call this method
    @dev Only call this method with a valid Greenwood Registry or subsequent calls will fail!
    """

    # require that the method caller is the Governance
    assert self.isAuthorized(msg.sender, "governance", "") == True, "Only Governance can call this method"

    # get the previous Registry
    previousRegistry: address = self.registry

    # update the address of the Registry
    self.registry = _new_registry

    # emit a SetRegistry event
    log SetRegistry(previousRegistry, _new_registry, msg.sender, block.number)