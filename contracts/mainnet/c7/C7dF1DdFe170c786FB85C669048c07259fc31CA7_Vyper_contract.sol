"""
@title Greenwood Controller
@notice An entry point for the Greenwood Protocol
@author Greenwood Labs
"""

# define the interfaces used by the contract
interface ESCROW:
    def borrow(_borrow_ticker: String[10], _collateral_ticker: String[10], _borrow_context: AssetContext, _collateral_context: AssetContext, _amount: uint256, _borrower: address, _calculator: address, _collateralization_ratio: uint256, _store: address, _version: String[11]): payable
    def repay(_borrow_ticker: String[10], _collateral_ticker: String[10], _amount: uint256, _calculator: address, _loan_key: bytes32, _store: address, _version: String[11]): payable
    def addCollateral(_collateral_ticker: String[10], _amount: uint256, _depositor: address, _loan_key: bytes32, _store: address, _version: String[11]): payable
    def withdrawCollateral(_borrow_ticker: String[10], _collateral_ticker: String[10], _amount: uint256, _calculator: address, _loan_key: bytes32,  _store: address, _version: String[11]): nonpayable

interface LIQUIDATOR:
    def liquidate(_borrow_ticker: String[10], _collateral_ticker: String[10], _aave_V2_escrow: address, _compound_escrow: address, _key_count: uint256, _liquidator: address, _loan_keys: bytes32[100], _aave_v2_loan_keys: bytes32[100], _compound_loan_keys: bytes32[100], _store: address, _version: String[11]): nonpayable

interface REGISTRY:
    def getAddress(_contract: String[20], _version: String[11], ) -> address: nonpayable
    def governance() -> address: nonpayable

interface ROUTER:
    def split(_borrow_ticker: String[10], _collateral_ticker: String[10], _amount: uint256, _protocol: String[10], _store: address, _version: String[11]) -> Split: nonpayable

interface STORE:
    def getAssetContext(_ticker: String[10]) -> AssetContext: view
    def recordLoan(_borrower: address, _borrow_asset: address, _collateral_asset: address, _collateralization_ratio: uint256, _collateral_locked: uint256, _index: uint256, _principal: uint256, _protocol: String[10], _version: String[11]): nonpayable
    def updateLoan(_collateral_locked: uint256, _index: uint256, _loan_key: bytes32, _outstanding: uint256, _version: String[11]): nonpayable
    def getLoan(_loan_key: bytes32) -> Loan: view
    def getLoanProtocol(_loan_key: bytes32) -> String[10]: view

# define the events used by the contract
event SetRegistry:
    previousRegistry: address
    newRegistry: address
    governance: address
    blockNumber: uint256

event TogglePauseBorrow:
    previousIsBorrowPaused: bool
    newIsBorrowPaused: bool
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

struct Loan:
    collateralAsset: address
    borrowAsset: address
    outstanding: uint256
    collateralizationRatio: uint256
    collateralLocked: uint256
    borrower: address
    lastBorrowIndex: uint256
    repaymentTime: uint256

struct Split:
    compoundSplit: uint256
    aaveV2Split: uint256
    borrowContext: AssetContext
    collateralContext: AssetContext

# define the storage variables used by the contract
isBorrowPaused: public(bool)
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

        # return the equality comparison boolean
        return governance == _caller

    # catch extraneous role arguments
    else:

        # revert
        raise "Unhandled role argument"

@external
@payable
@nonreentrant("controller_lock")
def borrow(_borrow_ticker: String[10], _collateral_ticker: String[10], _amount: uint256, _collateralization_ratio: uint256, _protocol: String[10], _version: String[11]):
    """
    @notice Borrow assets from AaveV2 or Compound at the lowest instantaneous APR
    @param _borrow_ticker The ticker string of the asset that is being borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _amount The amount of asset being borrowed scaled by the asset's decimals
    @param _collateralization_ratio The collateralization ratio for the loan
    @param _protocol The name of the underlying lending protocol for the loan
    @param _version The version of the Greenwood protocol to use
    """

    # require that borrowing is not paused
    assert self.isBorrowPaused == False, "Borrowing is paused"

    # require that the collateralization ratio is at least 100%
    assert _collateralization_ratio >= 100, "Collateralization ratio too low"

    # cache the Registry address into memory
    cachedRegistry: address = self.registry

    # get the addresses of the Greenwood Router and Store for the specified version from the Registry
    store: address = REGISTRY(cachedRegistry).getAddress("store", _version)
    router: address = REGISTRY(cachedRegistry).getAddress("router", _version)

    # find the protocol with the lowest instantaneous APR
    split: Split = ROUTER(router).split(_borrow_ticker, _collateral_ticker, _amount, _protocol, store, _version)

    # check if the loan should be routed to Aave V2
    if split.aaveV2Split == 100 and split.compoundSplit == 0:

        # get the addresses of the Greenwood Aave V2 Escrow and Calculator for the specified version from the Registry
        aaveV2Escrow: address = REGISTRY(cachedRegistry).getAddress("aaveV2Escrow", _version)
        aaveV2Calculator: address = REGISTRY(cachedRegistry).getAddress("aaveV2Calculator", _version)

        # call borrow() on the Aave V2 Escrow to initiate the borrow
        ESCROW(aaveV2Escrow).borrow(_borrow_ticker, _collateral_ticker, split.borrowContext, split.collateralContext, _amount, msg.sender, aaveV2Calculator, _collateralization_ratio, store, _version)

    # check if the loan should be routed to Compound
    elif split.compoundSplit == 100 and split.aaveV2Split == 0:

        # get the addresses of the Greenwood Compound Escrow and Calculator for the specified version from the Registry
        compoundEscrow: address = REGISTRY(cachedRegistry).getAddress("compoundEscrow", _version)
        compoundCalculator: address = REGISTRY(cachedRegistry).getAddress("compoundCalculator", _version)

        # call borrow() on the Compound Escrow to initiate the borrow
        ESCROW(compoundEscrow).borrow(_borrow_ticker, _collateral_ticker, split.borrowContext, split.collateralContext, _amount, msg.sender, compoundCalculator, _collateralization_ratio, store, _version, value=msg.value)

    # catch unsupported borrow splits
    else:

        # revert
        raise "Unhandled split values for borrow"
         
@external
@payable
@nonreentrant("controller_lock")
def repay(_borrow_ticker: String[10], _collateral_ticker: String[10], _amount: uint256, _loan_key: bytes32, _version: String[11]):
    """
    @notice Repay borrowed assets to Aave V2 or Compound
    @param _borrow_ticker The ticker string of the asset that was being borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _amount The amount of the repayment scaled by the asset's decimals
    @param _loan_key The uinque identifier for the loan
    @param _version The version of the Greenwood protocol to use
    @dev Passing 2 ** 256 - 1 as _amount triggers a full repayment
    """

    # cache the Registry address into memory
    cachedRegistry: address = self.registry

    # get the addresses of the Greenwood Store for the specified version from the Registry
    store: address = REGISTRY(cachedRegistry).getAddress("store", _version)

    # get the loan protocol from the Store
    protocol: String[10] = STORE(store).getLoanProtocol(_loan_key)

    # require that a protocol string was returned
    assert keccak256(protocol) != keccak256(""), "No loan protocol returned from the Store"

    # check if the loan was originated with Aave V2
    if keccak256(protocol) == keccak256("aavev2"):

        # get the addresses of the Greenwood Aave V2 Escrow and Calculator for the specified version from the Registry
        aaveV2Escrow: address = REGISTRY(cachedRegistry).getAddress("aaveV2Escrow", _version)
        aaveV2Calculator: address = REGISTRY(cachedRegistry).getAddress("aaveV2Calculator", _version)

        # call repay() on Escrow to initiate the repayment of the loan
        ESCROW(aaveV2Escrow).repay(_borrow_ticker, _collateral_ticker, _amount, aaveV2Calculator, _loan_key, store, _version)
    
    # check if the loan was originated with Compound
    elif keccak256(protocol) == keccak256("compound"):

        # get the addresses of the Greenwood Compound escrow and Calculator for the specified version from the Registry
        compoundEscrow: address = REGISTRY(cachedRegistry).getAddress("compoundEscrow", _version)
        compoundCalculator: address = REGISTRY(cachedRegistry).getAddress("compoundCalculator", _version)

        # call repay() on Escrow to initiate the repayment of the loan
        ESCROW(compoundEscrow).repay(_borrow_ticker, _collateral_ticker, _amount, compoundCalculator, _loan_key, store, _version, value=msg.value)

    # catch unsupported lending protocols
    else:

        # revert
        raise "Unhandled protocol for repay"

@external
@payable
@nonreentrant("controller_lock")
def addCollateral(_collateral_ticker: String[10], _amount: uint256, _loan_key: bytes32, _version: String[11]):
    """
    @notice Add collateral to an underlying lending protocol
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _amount The amount of the deposit scaled by the asset's decimals
    @param _loan_key The uinque identifier for the loan
    @param _version The version of the Greenwood protocol to use
    """

    # cache the Registry address into memory
    cachedRegistry: address = self.registry

    # get the address of the Greenwood Store for the specified version from the Registry
    store: address = REGISTRY(cachedRegistry).getAddress("store", _version)

    # get the loan protocol from the Store
    protocol: String[10] = STORE(store).getLoanProtocol(_loan_key)

    # require that a protocol string was returned
    assert keccak256(protocol) != keccak256(""), "No loan protocol returned from the Store"

    # check if the loan was originated with Aave V2
    if keccak256(protocol) == keccak256("aavev2"):

        # get the address of the Greenwood Aave V2 Escrow for the specified version from the Registry
        aaveV2Escrow: address = REGISTRY(cachedRegistry).getAddress("aaveV2Escrow", _version)

        # call addCollateral() on the Aave V2 Escrow to initiate the addition of collateral
        ESCROW(aaveV2Escrow).addCollateral(_collateral_ticker, _amount, msg.sender, _loan_key, store, _version)

    # check if the loan was originated with Compound
    elif keccak256(protocol) == keccak256("compound"):

        # get the address of the Greenwood Compound Escrow for the specified version from the Registry
        compoundEscrow: address = REGISTRY(cachedRegistry).getAddress("compoundEscrow", _version)

        # call addCollateral() on the Compound Escrow to initiate the addition of collateral
        ESCROW(compoundEscrow).addCollateral(_collateral_ticker, _amount, msg.sender, _loan_key, store, _version, value=msg.value)

    # catch unsupported lending protocols
    else:

        # revert
        raise "Unhandled protocol for addCollateral"

@external
@nonreentrant("controller_lock")
def withdrawCollateral(_borrow_ticker: String[10], _collateral_ticker: String[10], _amount: uint256, _loan_key: bytes32, _version: String[11]):
    """
    @notice Withdraw collateral from an underlying lending protocol
    @param _borrow_ticker The ticker string of the asset that was borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _amount The amount of the withdrawal scaled by the asset's decimals
    @param _loan_key The uinque identifier for the loan
    @param _version The version of the Greenwood protocol to use
    """

    # cache the Registry address into memory
    cachedRegistry: address = self.registry

    # get the address of the Greenwood Store for the specified version from the Registry
    store: address = REGISTRY(cachedRegistry).getAddress("store", _version)

    # get the loan protocol from the Store
    protocol: String[10] = STORE(store).getLoanProtocol(_loan_key)

    # require that a protocol string was returned
    assert keccak256(protocol) != keccak256(""), "No loan protocol returned from the Store"

    # check if the loan was originated with Aave V2
    if keccak256(protocol) == keccak256("aavev2"):

        # get the addresses of the Greenwood Aave V2 Escrow and Calculator for the specified version from the Registry
        aaveV2Escrow: address = REGISTRY(cachedRegistry).getAddress("aaveV2Escrow", _version)
        aaveV2Calculator: address = REGISTRY(cachedRegistry).getAddress("aaveV2Calculator", _version)

        # call withdrawCollateral() on the Aave V2 Escrow to initiate the withdrawal of collateral
        ESCROW(aaveV2Escrow).withdrawCollateral(_borrow_ticker, _collateral_ticker, _amount, aaveV2Calculator, _loan_key, store, _version)

    # check if the loan was originated with Compound
    elif keccak256(protocol) == keccak256("compound"):

        # get the addresses of the Greenwood Compound Escrow and Calculator for the specified version from the Registry
        compoundEscrow: address = REGISTRY(cachedRegistry).getAddress("compoundEscrow", _version)
        compoundCalculator: address = REGISTRY(cachedRegistry).getAddress("compoundCalculator", _version)

        # call withdrawCollateral() on the Compound Escrow to initiate the withdrawal of collateral
        ESCROW(compoundEscrow).withdrawCollateral(_borrow_ticker, _collateral_ticker, _amount, compoundCalculator, _loan_key, store, _version)
    
    # catch unsupported protocols
    else:
        raise "Unhandled protocol for withdrawCollateral"

@external
@payable
@nonreentrant("controller_lock")
def liquidate(_borrow_ticker: String[10], _collateral_ticker: String[10], _key_count: uint256, _loan_keys: bytes32[100], _version: String[11]):
    """
    @notice Liquidate undercollateralized loans    
    @param _borrow_ticker The ticker string of the asset that was borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _key_count The number of uinque identifiers in the _loan_keys array
    @param _loan_keys The uinque identifiers for the loans
    @param _version The version of the Greenwood protocol to use
    """

    # require that the key count is less than or equal to the max length of the loan keys array
    assert _key_count <= 100 and _key_count > 0, "Key count must be less than or equal to 100 and greater than 0"

    # cache the Registry address into memory
    cachedRegistry: address = self.registry

    # get the addresses of the Greenwood Store for the specified version from the Registry
    store: address = REGISTRY(cachedRegistry).getAddress("store", _version)

    # get the addresses of the Greenwood Liquidator for the specified version from the Registry
    liquidator: address = REGISTRY(cachedRegistry).getAddress("liquidator", _version)

    # get the address of the Greenwood Aave V2 Escrow from the Registry
    aaveV2Escrow: address = REGISTRY(cachedRegistry).getAddress("aaveV2Escrow", _version)

    # get the addresso f the Greenwood Compound Escrow from the Registry
    compoundEscrow: address = REGISTRY(cachedRegistry).getAddress("compoundEscrow", _version)

    # call liquidate() on the Liquidator
    LIQUIDATOR(liquidator).liquidate(_borrow_ticker, _collateral_ticker, aaveV2Escrow, compoundEscrow, _key_count, msg.sender, _loan_keys, empty(bytes32[100]), empty(bytes32[100]), store, _version)

@external
@nonreentrant("controller_lock")
def togglePauseBorrow():
    """
    @notice Pause and unpause the borrow method
    @dev Only the Controller governance can call this method
    """

    # assert that the method caller is the Governance
    assert self.isGovernance(msg.sender, "governance") == True, "Only Governance can call this method"

    # get the previous isBorrowPaused
    previousIsBorrowPaused: bool = self.isBorrowPaused

    # set the isBorrowPaused bool to be the negation of the current value
    self.isBorrowPaused = not self.isBorrowPaused

    # emit a TogglePauseBorrow event
    log TogglePauseBorrow(previousIsBorrowPaused, not previousIsBorrowPaused, msg.sender, block.number)

@external
@nonreentrant("controller_lock")
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