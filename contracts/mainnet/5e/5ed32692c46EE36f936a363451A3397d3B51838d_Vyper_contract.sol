"""
@title Greenwood Store
@notice Loan and asset storage contract for the Greenwood Protocol
@author Greenwood Labs
"""

# define the interfaces used by the contract
interface REGISTRY:
    def getAddress(_contract: String[20], _version: String[11], ) -> address: nonpayable
    def governance() -> address: nonpayable

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

struct Loan:
    collateralAsset: address
    borrowAsset: address
    outstanding: uint256
    collateralizationRatio: uint256
    collateralLocked: uint256
    borrower: address
    lastBorrowIndex: uint256
    repaymentTime: uint256

    
# define the storage variables used by the contract
assetContexts: public(HashMap[String[10], AssetContext])
assetTickers: public(HashMap[String[10], address])
registry: public(address)
loans: public(HashMap[bytes32, Loan])
loanNumbers: public(HashMap[address, uint256])
loanProtocols: public(HashMap[bytes32, String[10]])

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

    # check if the requested role is "aaveV2Escrow"
    if keccak256(_role) == keccak256("aaveV2Escrow"):

        # get the address of the AaveV2Escrow from the Registry
        aaveV2Escrow: address = REGISTRY(self.registry).getAddress("aaveV2Escrow", _version)

        # return the equality comparison
        return aaveV2Escrow == _caller
    
    # check if the requested role is "compoundEscrow"
    elif keccak256(_role) == keccak256("compoundEscrow"):

        # get the address of the CompoundEscrow from the Registry
        compoundEscrow: address = REGISTRY(self.registry).getAddress("compoundEscrow", _version)

        # return the equality comparison
        return compoundEscrow == _caller

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
def setAssetContext(_ticker: String[10], _a_token: address, _aave_v2_price_feed: address, _aave_v2_lending_pool: address, _c_token: address, _compound_price_feed: address, _comptroller: address, _decimals: uint256, _underlying: address, _version: String[11]):
    """
    @notice Writes contextual information about an asset ticker to storage
    @param _ticker The ticker string of that asset that the context applies to
    @param _a_token The address of the Aave V2 aToken contract for the underlying asset
    @param _aave_V2_price_feed The address of the Aave V2 price feed contract
    @param _aave_v2_lending_pool The address of the Aave V2 LendingPool contract
    @param _c_token The address of the Compound cToken contract for the underlying asset
    @param _compound_price_feed The address of the Compound price feed contract
    @param _comptroller The address of the Compound Comptroller contract
    @param _decimals The decimals of the underlying asset
    @param _underlying The address of the underlying asset
    @param _version The version of the Greenwood Protocol to use
    @dev Only the Governance can call this method
    """
   
    # require that the method caller is the governance
    assert self.isAuthorized(msg.sender, "governance", _version) == True, "Only Governance can call this method"

    # check if the aToken address is the zero address
    if _a_token != ZERO_ADDRESS:

        # write the aToken address to storage
        self.assetContexts[_ticker].aToken = _a_token

    # check if the Aave V2 price feed address is the zero address
    if _aave_v2_price_feed != ZERO_ADDRESS:

        # write the Aave V2 price feed address to stroage
        self.assetContexts[_ticker].aaveV2PriceFeed = _aave_v2_price_feed

    # check if the Aave V2 LendingPool address is the zero address
    if _aave_v2_lending_pool != ZERO_ADDRESS:

        # write the Aave V2 LendingPool address to storage
        self.assetContexts[_ticker].aaveV2LendingPool = _aave_v2_lending_pool

    # check if the cToken address is the zero address
    if _c_token != ZERO_ADDRESS:

        # write the cToken address to storage
        self.assetContexts[_ticker].cToken = _c_token

    # check if the Compound price feed address is the zero address
    if _compound_price_feed != ZERO_ADDRESS:

        # write the Compound price feed address to storage
        self.assetContexts[_ticker].compoundPriceFeed = _compound_price_feed

    # check if the Comptroller address is the zero address
    if _comptroller != ZERO_ADDRESS:

        # write the Comptroller address to storage
        self.assetContexts[_ticker].comptroller = _comptroller

    # check if the asset decimals are zero
    if _decimals != 0:

        # write the asset decimals to stroage
        self.assetContexts[_ticker].decimals = _decimals

    # check if the underlying address is the zero address
    if _underlying != ZERO_ADDRESS:

        # write the underlying address to storage
        self.assetContexts[_ticker].underlying = _underlying
    
@external
@view
def getAssetContext(_ticker: String[10]) -> AssetContext:
    """
    @notice Gets contextual information about a given asset ticker from storage
    @param _ticker The ticker string of that asset that the context applies to
    @return AssetContext struct
    """

    # read the contextual data out of storage and return it
    return AssetContext({
        aToken: self.assetContexts[_ticker].aToken,
        aaveV2PriceFeed: self.assetContexts[_ticker].aaveV2PriceFeed,
        aaveV2LendingPool: self.assetContexts[_ticker].aaveV2LendingPool,
        cToken: self.assetContexts[_ticker].cToken,
        compoundPriceFeed: self.assetContexts[_ticker].compoundPriceFeed,
        comptroller: self.assetContexts[_ticker].comptroller,
        decimals: self.assetContexts[_ticker].decimals,
        underlying: self.assetContexts[_ticker].underlying
    })

@external
def recordLoan(_borrower: address, _borrow_asset: address, _collateral_asset: address, _collateralization_ratio: uint256, _collateral_locked: uint256, _index: uint256, _principal: uint256, _protocol: String[10], _version: String[11]):
    """
    @notice Writes information about a loan to storage
    @param _borrower The address of the borrower
    @param _borrow_asset The address of the asset that is being borrowed
    @param _collateral_asset The address of the asset that is being used as collateral
    @param _collateralization_ratio The collateralization ratio for the loan
    @param _collateral_locked The amount of collateral locked for the loan scaled by the collateral asset's decimals
    @param _index The borrow index at origination
    @param _principal The principal of the loan scaled by the borrow asset's decimals
    @param _protocol The name of the underlying lending protocol for the loan
    @param _version The version of the Greenwood Protocol to use
    @dev Only the AaveV2Escrow, the CompoundEscrow or the Governance can call this method
    """

    # require that the method is being called by an Escrow or the Governance
    assert self.isAuthorized(msg.sender, "aaveV2Escrow", _version) == True or self.isAuthorized(msg.sender, "compoundEscrow", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True, "Only Escrow or Governance can call this method"

    # create a unique lookup key by concatenating the borrower's address with their current loan number and hashing
    loanKey: bytes32 = keccak256(concat(convert(_borrower, bytes32), convert(self.loanNumbers[_borrower], bytes32)))

    # write the collateral asset to storage
    self.loans[loanKey].collateralAsset = _collateral_asset

    # write the borrow asset to storage
    self.loans[loanKey].borrowAsset = _borrow_asset

    # write the principal to storage as the outstanding loan balance
    self.loans[loanKey].outstanding = _principal

    # write the collateralization ratio to storage
    self.loans[loanKey].collateralizationRatio = _collateralization_ratio

    # write the collateral locked to storage
    self.loans[loanKey].collateralLocked = _collateral_locked

    # write the borrower's address to storage
    self.loans[loanKey].borrower = _borrower

    # write the borrow index to storage
    self.loans[loanKey].lastBorrowIndex = _index

    # write loan protocol to storage
    self.loanProtocols[loanKey] = _protocol

    # increment the borrower's loan number
    self.loanNumbers[_borrower] += 1

@external
def updateLoan(_collateral_locked: uint256, _index: uint256, _loan_key: bytes32, _outstanding: uint256, _version: String[11]):
    """
    @notice Updates information about a loan in storage
    @param _collateral_locked The amount of collateral locked for the loan scaled by the collateral asset's decimals
    @param _index The borrow index at the time the method is called
    @param _loan_key The uinque identifier for the loan
    @param _outstanding The outstanding balance of the loan scaled by the borrow asset's decimals
    @param _version The version of the Greenwood Protocol to use
    @dev Only the AaveV2Escrow, the CompoundEscrow or the Governance can call this method
    """

    # require that the method is being called by an escrow or the governance
    assert self.isAuthorized(msg.sender, "aaveV2Escrow", _version) == True or self.isAuthorized(msg.sender, "compoundEscrow", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True, "Only Escrow or Governance can call this method"

    # require that the loan key corresponds to an existing loan
    assert self.loans[_loan_key].borrower != ZERO_ADDRESS, "No corresponding loan to update"

    # update the outstanding balance of the loan
    self.loans[_loan_key].outstanding = _outstanding

    # update the collateral locked for the loan
    self.loans[_loan_key].collateralLocked = _collateral_locked

    # set the lastBorrowIndex of the loan if the _borrow_index argument is not 0
    if _index != 0:
        self.loans[_loan_key].lastBorrowIndex = _index

    # set the repayment time of the loan if the _outstanding argument is 0
    if _outstanding == 0:
        self.loans[_loan_key].repaymentTime = block.timestamp

@external
@view
def getLoan(_loan_key: bytes32) -> Loan:
    """
    @notice Gets loan data from storage
    @param _loan_key The uinque identifier for the loan
    @return Loan struct
    """

    # read the loan data out of storage and return it
    return Loan({
        collateralAsset: self.loans[_loan_key].collateralAsset,
        borrowAsset: self.loans[_loan_key].borrowAsset,
        outstanding: self.loans[_loan_key].outstanding,
        collateralizationRatio: self.loans[_loan_key].collateralizationRatio,
        collateralLocked: self.loans[_loan_key].collateralLocked,
        borrower: self.loans[_loan_key].borrower,
        lastBorrowIndex: self.loans[_loan_key].lastBorrowIndex,
        repaymentTime: self.loans[_loan_key].repaymentTime
    })

@external
@view
def getLoanProtocol(_loan_key: bytes32) -> String[10]:
    """
    @notice Gets the name of the lending protocol of loan from storage
    @param _loan_key The uinque identifier for the loan
    @return String with a maximum length of 10
    """

    # read the loan protocol data out of storage and return it
    return self.loanProtocols[_loan_key]

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