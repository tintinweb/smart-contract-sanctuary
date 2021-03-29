"""
@title Greenwood CompoundCalculator
@notice Compound calculations for the Greenwood Protocol
@author Greenwood Labs
"""

# define the interfaces used by the contract
interface COMPOUND_PRICE_FEED:
    def price(_ticker: String[10]) -> uint256: view

interface COMPTROLLER:
    def markets(_c_token: address) -> (bool, uint256, bool): view

interface CTOKEN:
    def mint(_mint_amount: uint256) -> uint256: payable
    def borrow(_borrow_amount: uint256) -> uint256: payable
    def repayBorrow(_repay_amount: uint256) -> uint256: payable
    def borrowIndex() -> uint256: nonpayable
    def redeemUnderlying(_redeem_amount: uint256) -> uint256: payable
    def exchangeRateStored() -> uint256: nonpayable
    def borrowRatePerBlock() -> uint256: nonpayable
    def borrowBalanceCurrent(_account: address) -> uint256: nonpayable
    def accrualBlockNumber() -> uint256: nonpayable

interface REGISTRY:
    def getAddress(_contract: String[20], _version: String[11]) -> address: nonpayable
    def governance() -> address: nonpayable

# define the constants used by the contract
LOOP_LIMIT: constant(uint256) = 100
TEN_EXP_6: constant(uint256) = 1000000
TEN_EXP_18: constant(uint256) = 1000000000000000000
CONTRACT_PRECISION: constant(decimal) = 10000000000.0

# define the events emitted by the contract
event SetFee:
    previousFee: uint256
    newFee: uint256
    governance: address
    blockNumber: uint256

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

struct CompoundBorrowCalculation:
    requiredCollateral: uint256
    borrowAmount: uint256
    originationFee: uint256

struct CompoundRepayCalculation:
    repayAmount: uint256
    redemptionAmount: int128
    requiredCollateral: uint256
    outstanding: int128

struct CompoundWithdrawCalculation:
    requiredCollateral: uint256
    outstanding: uint256

# define the storage variables used by the contract
protocolFee: public(uint256)
registry: public(address)

@external
def __init__(_protocol_fee: uint256, _registry: address):
    """
    @notice Contract constructor
    @param _protocol_fee The origination fee for the Greenwood Protocol scaled by 1e18
    @param _registry The address of the Greenwood Registry
    """

    # set the protocol fee
    self.protocolFee = _protocol_fee

    # set the address of the Greenwood Registry
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

    # check if the requested role is "escrow"
    if keccak256(_role) == keccak256("escrow"):

        # get the address of the Escrow from the Registry
        controller: address = REGISTRY(self.registry).getAddress("compoundEscrow", _version)

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
def calculateBorrow(_borrow_ticker: String[10], _collateral_ticker: String[10], _borrow_context: AssetContext, _collateral_context: AssetContext, _amount: uint256, _collateralization_ratio: uint256, _version: String[11]) -> CompoundBorrowCalculation:
    """
    @notice Calculate and return values needed to open a loan on Compound
    @param _borrow_ticker The ticker string of the asset that is being borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _borrow_context The AssetContext struct of the asset being borrowed
    @param _collateral_context The AssetContext struct of the asset being used as collateral
    @param _amount The amount of asset being borrowed scaled by the asset's decimals
    @param _collateralization_ratio The collateralization ratio for the loan
    @param _version The version of the Greenwood Protocol to use
    @return CompoundBorrowCalculation struct
    @dev Only the CompoundEscrow or the Governance can call this method
    """

    # require that the method caller is the Escrow or the Governance
    assert self.isAuthorized(msg.sender, "escrow", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True

    # setup memory variables to handle comptroller return values
    isListed: bool = False
    collateralFactorMantissa: uint256 = 0
    isComped: bool = False

    # get the collateral factor for the collateral asset using the comptroller
    isListed, collateralFactorMantissa, isComped  = COMPTROLLER(_collateral_context.comptroller).markets(_collateral_context.cToken)

    # convert collateralFactorMantissa to a percentage
    collateralFactor: decimal = convert(collateralFactorMantissa, decimal) / convert(TEN_EXP_18, decimal)

    # get the price of the borrow asset and the collateral asset denominated in USD
    borrowAssetPriceExp: uint256 = COMPOUND_PRICE_FEED(_borrow_context.compoundPriceFeed).price(_borrow_ticker)
    collateralAssetPriceExp: uint256 = COMPOUND_PRICE_FEED(_collateral_context.compoundPriceFeed).price(_collateral_ticker)

    # scale down the asset prices and convert them to decimals
    borrowAssetPrice: decimal = convert(borrowAssetPriceExp, decimal) / convert(TEN_EXP_6, decimal)
    collateralAssetPrice: decimal = convert(collateralAssetPriceExp, decimal) / convert(TEN_EXP_6, decimal)

    # convert the borrow amount to a decimal and scale it down
    borrowAmount: decimal = convert(_amount, decimal) / convert(10 ** _borrow_context.decimals, decimal)

    # calculate the protocol fee
    originationFee: decimal = (borrowAmount * (convert(self.protocolFee, decimal) / convert(TEN_EXP_18, decimal))) / (collateralAssetPrice / borrowAssetPrice)

    # calculate the value of the borrow request denominated in USD
    borrowAmountInUSD: decimal = borrowAmount * borrowAssetPrice

    # calculate the required collateral denominated in USD
    requiredCollateralInUSD: decimal = borrowAmountInUSD / collateralFactor

    # calculate the required collateral denominated in the collateral asset 
    requiredCollateral: decimal = requiredCollateralInUSD / collateralAssetPrice

    # calculate the required collateral for Greenwood plus fees denominated in the collateral asset
    requiredCollateralGreenwood: decimal = requiredCollateral * (convert(_collateralization_ratio, decimal) / 100.0)

    # scale the required collateral for Greenwood by the decimals of the collateral asset
    requiredCollateralScaled: uint256 = convert(requiredCollateralGreenwood * convert(10 ** _collateral_context.decimals, decimal), uint256)

    return CompoundBorrowCalculation({
        requiredCollateral: requiredCollateralScaled,
        borrowAmount: convert(borrowAmount * convert(10 ** _borrow_context.decimals, decimal), uint256),    # scale the borrow amount back up and convert it to a uint256
        originationFee: convert(originationFee * convert(10 ** _collateral_context.decimals, decimal), uint256) # scale the protocol fee back up and convert it to a uint256
    })

@external
def calculateWithdraw(_borrow_ticker: String[10], _collateral_ticker: String[10], _borrow_context: AssetContext, _collateral_context: AssetContext, _loan: Loan, _version: String[11]) -> CompoundWithdrawCalculation:
    """
    @notice Calculate and return values needed to withdraw collateral from Compound
    @param _borrow_ticker The ticker string of the asset that is being borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _borrow_context The AssetContext struct of the asset being borrowed
    @param _collateral_context The AssetContext struct of the asset being used as collateral
    @param _loan A Loan struct containing loan data
    @param _version The version of the Greenwood Protocol to use
    @return CompoundWithdrawCalculation struct
    @dev Only the CompoundEscrow or the Governance can call this method
    """

    # require that the method caller is the Escrow or the Governance
    assert self.isAuthorized(msg.sender, "escrow", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True, "Only Escrow or Governance can call this method"

    # setup memory variables to handle comptroller return values
    isListed: bool = False
    collateralFactorMantissa: uint256 = 0
    isComped: bool = False

    # get the collateral factor for the collateral asset using the comptroller
    isListed, collateralFactorMantissa, isComped  = COMPTROLLER(_collateral_context.comptroller).markets(_collateral_context.cToken)

    # convert collateralFactorMantissa to a percentage
    collateralFactor: decimal = convert(collateralFactorMantissa, decimal) / convert(TEN_EXP_18, decimal)

    # get the current borrowIndex from the cToken
    borrowIndex: uint256 = CTOKEN(_borrow_context.cToken).borrowIndex()

    # calculate the interestAccrued since the last action on the loan
    interestAccrued: decimal = convert(borrowIndex, decimal) / convert(_loan.lastBorrowIndex, decimal) - 1.0

    # apply interest accrued to the outstanding balance of the loan
    borrowBalanceScaled: uint256 = convert(convert(_loan.outstanding, decimal) * (1.0 + interestAccrued), uint256)

    # get the price of the borrow asset and the collateral asset denominated in USD
    borrowAssetPriceExp: uint256 = COMPOUND_PRICE_FEED(_borrow_context.compoundPriceFeed).price(_borrow_ticker)
    collateralAssetPriceExp: uint256 = COMPOUND_PRICE_FEED(_collateral_context.compoundPriceFeed).price(_collateral_ticker)

    # scale down the asset prices and convert them to decimals
    borrowAssetPrice: decimal = convert(borrowAssetPriceExp, decimal) / convert(TEN_EXP_6, decimal)
    collateralAssetPrice: decimal = convert(collateralAssetPriceExp, decimal) / convert(TEN_EXP_6, decimal)

    # convert the borrow balance to a decimal and scale it down
    borrowBalance: decimal = convert(borrowBalanceScaled, decimal) / convert(10 ** _borrow_context.decimals, decimal)

    # calculate the value of the outstanding balance denominated in USD
    borrowAmountInUSD: decimal = borrowBalance * borrowAssetPrice

    # calculate the required collateral denominated in USD
    requiredCollateralInUSD: decimal = borrowAmountInUSD / collateralFactor

    # calculate the required collateral denominated in the collateral asset 
    requiredCollateral: decimal = requiredCollateralInUSD / collateralAssetPrice

    # calculate the required collateral for Greenwood denominated in the collateral asset 
    requiredCollateralGreenwood: decimal = requiredCollateral * (convert(_loan.collateralizationRatio, decimal) / 100.0)

    # scale the required collateral for Greenwood by the decimals of the collateral asset
    requiredCollateralScaled: uint256 = convert(requiredCollateralGreenwood * convert(10 ** _collateral_context.decimals, decimal), uint256)

    return CompoundWithdrawCalculation({
        requiredCollateral: requiredCollateralScaled,
        outstanding: borrowBalanceScaled
    })

@external
def calculateRepay(_borrow_ticker: String[10], _collateral_ticker: String[10], _borrow_context: AssetContext, _collateral_context: AssetContext, _amount: uint256, _loan: Loan, _version: String[11]) -> CompoundRepayCalculation:
    """
    @notice Calculate and return values needed to repay a loan on Compound
    @param _borrow_ticker The ticker string of the asset that is being borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _borrow_context The AssetContext struct of the asset being borrowed
    @param _collateral_context The AssetContext struct of the asset being used as collateral
    @param _amount The amount of asset being repaid scaled by the asset's decimals
    @param _loan The Loan struct containing the data for the loan
    @param _version The version of the Greenwood Protocol to use
    @return CompoundRepayCalculation struct
    @dev Only the CompoundEscrow or the Governance can call this method
    """

    # require that the method caller is the Escrow or the Governance
    assert self.isAuthorized(msg.sender, "escrow", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True, "Only Escrow or Governance can call this method"
    
    # check if the borrow ticker is ETH
    if keccak256(_borrow_ticker) == keccak256('ETH'):
        
        # call repayBorrow() on the cEther with a value of 0 to refresh the borrowIndex
        raw_call(
            _borrow_context.cToken,
            method_id("repayBorrow()"),
            value = 0
        )
    
    # check if the borrow ticker is BAT
    elif keccak256(_borrow_ticker) == keccak256('BAT'):

        # do not attempt to refresh the borrow index
        pass

    else:

        # call repayBorrow() on the cToken with a value of 0 to refresh the borrowIndex
        CTOKEN(_borrow_context.cToken).repayBorrow(0)

    # get the borrowIndex from the cToken
    borrowIndex: uint256 = CTOKEN(_borrow_context.cToken).borrowIndex()

    # calculate the interestAccrued on the borrow
    interestAccrued: decimal = convert(borrowIndex, decimal) / convert(_loan.lastBorrowIndex, decimal) - 1.0

    # apply interest accrued to the outstanding balance of the loan
    borrowBalance: uint256 = convert(convert(_loan.outstanding, decimal) * (1.0 + interestAccrued), uint256)
           
    # declare a memory variable to store the repayment amount 
    repayAmount: uint256 = 0

    # check if this is a full repayment or an over-repayment
    if _amount == MAX_UINT256 or _amount > borrowBalance:

        # set repaymentAmount to be the borrowBalance
        repayAmount = borrowBalance

    # handle partial repayment
    else:

        # set repaymentAmount to be the requested amount
        repayAmount = _amount

    # subtract the repayment amount from borrowBalance to get the outstandingBalance
    outstandingBalanceScaled: int128 = convert(borrowBalance, int128) - convert(repayAmount, int128)

    # setup memory variables to handle comptroller return values
    isListed: bool = False
    collateralFactorMantissa: uint256 = 0
    isComped: bool = False

    # get the collateral factor for the collateral asset using the comptroller
    isListed, collateralFactorMantissa, isComped  = COMPTROLLER(_collateral_context.comptroller).markets(_collateral_context.cToken)

    # convert collateralFactorMantissa to a percentage
    collateralFactor: decimal = convert(collateralFactorMantissa, decimal) / convert(TEN_EXP_18, decimal)

    # get the price of the borrow asset and the collateral asset denominated in USD
    borrowAssetPriceExp: uint256 = COMPOUND_PRICE_FEED(_borrow_context.compoundPriceFeed).price(_borrow_ticker)
    collateralAssetPriceExp: uint256 = COMPOUND_PRICE_FEED(_collateral_context.compoundPriceFeed).price(_collateral_ticker)

    # scale down the asset prices and convert them to decimals
    borrowAssetPrice: decimal = convert(borrowAssetPriceExp, decimal) / convert(TEN_EXP_6, decimal)
    collateralAssetPrice: decimal = convert(collateralAssetPriceExp, decimal) / convert(TEN_EXP_6, decimal)

    # convert the outstanding balance to a decimal and scale it down
    outstandingBalance: decimal = convert(outstandingBalanceScaled, decimal) / convert(10 ** _borrow_context.decimals, decimal)

    # calculate the value of the outstanding balance denominated in USD
    borrowAmountInUSD: decimal = outstandingBalance * borrowAssetPrice

    # calculate the required collateral denominated in USD
    requiredCollateralInUSD: decimal = borrowAmountInUSD / collateralFactor

    # calculate the required collateral denominated in the collateral asset 
    requiredCollateral: decimal = requiredCollateralInUSD / collateralAssetPrice

    # calculate the required collateral for Greenwood denominated in the collateral asset
    requiredCollateralGreenwood: decimal = requiredCollateral * (convert(_loan.collateralizationRatio, decimal) / 100.0)

    # scale the required collateral for Greenwood by the decimals of the collateral asset
    requiredCollateralScaled: uint256 = convert(requiredCollateralGreenwood * convert(10 ** _collateral_context.decimals, decimal), uint256)

    # calculate the redemption amount
    redemptionAmount: int128 = convert(_loan.collateralLocked, int128) - convert(requiredCollateralScaled, int128)

    return CompoundRepayCalculation({
        repayAmount: repayAmount,
        redemptionAmount: redemptionAmount,
        requiredCollateral: requiredCollateralScaled,
        outstanding: convert(outstandingBalance * convert(10 ** _borrow_context.decimals, decimal), int128), # scale the outstanding balance back up and convert it to an int128
    })

@external
def setProtocolFee(_new_fee: uint256):
    """
    @notice Updates the protocol fee
    @param _new_fee The new protocol fee
    @dev Only the Governance can call this method 
    """

    # require that the method caller is the Governance
    assert self.isAuthorized(msg.sender, "governance", "") == True, "Only Governance can call this method"

    # get the previous protocol fee
    previousFee: uint256 = self.protocolFee

    # update the protocol fee
    self.protocolFee = _new_fee

    # emit a SetFee event
    log SetFee(previousFee, _new_fee, msg.sender, block.number)

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