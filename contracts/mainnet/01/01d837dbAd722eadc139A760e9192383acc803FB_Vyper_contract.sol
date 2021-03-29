"""
@title Greenwood AaveV2Calculator
@notice AaveV2 calculations for the Greenwood Protocol
@author Greenwood Labs
"""

# define the interfaces used by the contract
from vyper.interfaces import ERC20

interface AAVE_V2_PRICE_FEED:
    def getAssetPrice(_asset: address) -> uint256: view

interface REGISTRY:
    def getAddress(_contract: String[20], _version: String[11]) -> address: nonpayable
    def governance() -> address: nonpayable

# define the constants used by the contract
TEN_EXP_18: constant(uint256) = 1000000000000000000

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
struct AaveV2BorrowCalculation:
    requiredCollateral: uint256
    borrowIndex: uint256
    borrowAmount: uint256
    originationFee: uint256

struct AaveV2RepayCalculation:
    repayAmount: uint256
    redemptionAmount: int128
    requiredCollateral: uint256
    outstanding: int128
    borrowIndex: uint256

struct AaveV2WithdrawCalculation:
    requiredCollateral: uint256
    outstanding: uint256

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
        controller: address = REGISTRY(self.registry).getAddress("aaveV2Escrow", _version)

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
def calculateBorrow(_borrow_context: AssetContext, _collateral_context: AssetContext, _amount: uint256, _collateralization_ratio: uint256, _version: String[11]) -> AaveV2BorrowCalculation:
    """
    @notice Calculate and return values needed to open a loan on Aave V2
    @param _borrow_context The AssetContext struct of the asset being borrowed
    @param _collateral_context The AssetContext struct of the asset being used as collateral
    @param _amount The amount of asset being borrowed scaled by the asset's decimals
    @param _collateralization_ratio The collateralization ratio for the loan
    @param _version The version of the Greenwood Protocol to use
    @return AaveV2BorrowCalculation struct
    @dev Only the AaveV2Escrow or the Governance can call this method
    """

    # require that the method caller is the Escrow or the Governance
    assert self.isAuthorized(msg.sender, "escrow", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True, "Only Escrow or Governance can call this method"

    # get the LTV ratio of the collateral asset
    collateralReserveData: Bytes[768] = raw_call(
        _collateral_context.aaveV2LendingPool,
        concat(
            method_id("getReserveData(address)"),
            convert(_collateral_context.underlying, bytes32)
        ),
        max_outsize=768
    )

    # parse the LTV from collateralReserveData and convert it to a percentage
    collateralAssetLTV: decimal = convert(convert(slice(collateralReserveData, 30, 2), uint256), decimal) / 10000.0

    # get the current borrowIndex of the borrow asset
    borrowReserveData: Bytes[768] = raw_call(
        _borrow_context.aaveV2LendingPool,
        concat(
            method_id("getReserveData(address)"),
            convert(_borrow_context.underlying, bytes32)
        ),
        max_outsize=768
    )

    # parse the variableBorrowIndex from borrowReserveData
    borrowIndex: uint256 = convert(slice(borrowReserveData, 64, 32), uint256)

    # get the price of the borrow asset and the collateral asset denominated in ETH
    borrowAssetPriceScaled: uint256 = AAVE_V2_PRICE_FEED(_borrow_context.aaveV2PriceFeed).getAssetPrice(_borrow_context.underlying)
    collateralAssetPriceScaled: uint256 = AAVE_V2_PRICE_FEED(_collateral_context.aaveV2PriceFeed).getAssetPrice(_collateral_context.underlying)

    # scale down the asset prices and convert them to decimals
    borrowAssetPrice: decimal = convert(borrowAssetPriceScaled, decimal) / convert(TEN_EXP_18, decimal)
    collateralAssetPrice: decimal = convert(collateralAssetPriceScaled, decimal) / convert(TEN_EXP_18, decimal)

    # convert the borrow amount to a decimal and scale it down
    borrowAmount: decimal = convert(_amount, decimal) / convert(10 ** _borrow_context.decimals, decimal)

    # calculate the protocol fee
    originationFee: decimal = (borrowAmount * (convert(self.protocolFee, decimal) / convert(TEN_EXP_18, decimal))) / (collateralAssetPrice / borrowAssetPrice)

    # calculate the value of the borrow request denominated in ETH
    borrowAmountInETH: decimal = borrowAmount * borrowAssetPrice

    # calculate the required collateral denominated in ETH
    requiredCollateralInETH: decimal = borrowAmountInETH / collateralAssetLTV
    
    # calculate the required collateral denominated in the collateral asset 
    requiredCollateral: decimal = requiredCollateralInETH / collateralAssetPrice

    # calculate the required collateral for Greenwood plus fees denominated in the collateral asset 
    requiredCollateralGreenwood: decimal = requiredCollateral * (convert(_collateralization_ratio, decimal) / 100.0)

    # scale the required collateral for Greenwood by the decimals of the collateral asset
    requiredCollateralScaled: uint256 = convert(requiredCollateralGreenwood * convert(10 ** _collateral_context.decimals, decimal), uint256)

    # return the calculations
    return AaveV2BorrowCalculation({
        requiredCollateral: requiredCollateralScaled,
        borrowIndex: borrowIndex,
        borrowAmount: convert(borrowAmount * convert(10 ** _borrow_context.decimals, decimal), uint256),    # scale the borrow amount back up and convert it to a uint256
        originationFee: convert(originationFee * convert(10 ** _collateral_context.decimals, decimal), uint256) # scale the protocol fee back up and convert it to a uint256
    })

@external
def calculateWithdraw(_borrow_context: AssetContext, _collateral_context: AssetContext, _escrow: address, _loan: Loan, _version: String[11]) -> AaveV2WithdrawCalculation:
    """
    @notice Calculate and return values needed to withdraw collateral from Aave V2
    @param _borrow_context The AssetContext struct of the asset being borrowed
    @param _collateral_context The AssetContext struct of the asset being used as collateral
    @param _escrow The address of the Greenwood Escrow use
    @param _loan A Loan struct containing loan data
    @param _version The version of the Greenwood Protocol to use
    @return AaveV2WithdrawCalculation struct
    @dev Only the AaveV2Escrow or the Governance can call this method
    """

    # require that the method caller is the Escrow or the Governance
    assert self.isAuthorized(msg.sender, "escrow", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True, "Only Escrow or Governance can call this method"

    # get the LTV ratio of the collateral asset
    collateralReserveData: Bytes[768] = raw_call(
        _collateral_context.aaveV2LendingPool,
        concat(
            method_id("getReserveData(address)"),
            convert(_collateral_context.underlying, bytes32)
        ),
        max_outsize=768
    )

    # parse the LTV from collateralReserveData and convert it to a percentage
    collateralAssetLTV: decimal = convert(convert(slice(collateralReserveData, 30, 2), uint256), decimal) / 10000.0

    # get the current borrowIndex of the borrow asset
    borrowReserveData: Bytes[768] = raw_call(
        _borrow_context.aaveV2LendingPool,
        concat(
            method_id("getReserveData(address)"),
            convert(_borrow_context.underlying, bytes32)
        ),
        max_outsize=768
    )

    # parse the variableBorrowIndex from borrowReserveData
    borrowIndex: uint256 = convert(slice(borrowReserveData, 64, 32), uint256)

    # parse the variableDebtTokenAddress from borrowReserveData
    variableDebtTokenAddress: address = convert(convert(slice(borrowReserveData, 288, 32), bytes32), address)

    # get variableDebtToken balance of the Escrow
    escrowBorrowBalance: uint256 = ERC20(variableDebtTokenAddress).balanceOf(_escrow)

    # get the variableDebtToken scaledBalanceOf of the Escrow
    scaledBalanceOfResponse: Bytes[32] = raw_call(
        variableDebtTokenAddress,
        concat(
            method_id("scaledBalanceOf(address)"),
            convert(_escrow, bytes32)
        ),
        max_outsize=32
    )

    # convert the scaledBalanceOfResponse to a uint256
    scaledBalanceOf: uint256 = convert(scaledBalanceOfResponse, uint256)

    # calculate the borrow balance increase of the Escrow
    balanceIncrease: decimal = ((convert(escrowBorrowBalance, decimal) - convert(scaledBalanceOf, decimal)) * (convert(_loan.lastBorrowIndex, decimal) / convert(10 ** 27, decimal))) / convert(10 ** 18, decimal)

    # declare a memory variable to store the amount of interest accrued
    interestAccrued: decimal = 0.0

    # check that the escrow borrow balance is not equal to the balance increase to prevent division by 0
    if convert(escrowBorrowBalance, decimal) != balanceIncrease:

        # calculate the interest accrued since the last action on the loan
        interestAccrued = balanceIncrease / (convert(escrowBorrowBalance, decimal) - balanceIncrease)

    # apply interest accrued to the outstanding balance of the loan
    borrowBalanceScaled: uint256 = convert(convert(_loan.outstanding, decimal) * (1.0 + interestAccrued), uint256)

    # get the price of the borrow asset and the collateral asset denominated in ETH
    borrowAssetPriceExp: uint256 = AAVE_V2_PRICE_FEED(_borrow_context.aaveV2PriceFeed).getAssetPrice(_borrow_context.underlying)
    collateralAssetPriceExp: uint256 = AAVE_V2_PRICE_FEED(_collateral_context.aaveV2PriceFeed).getAssetPrice(_collateral_context.underlying)

    # scale down the prices and convert them to decimals
    borrowAssetPrice: decimal = convert(borrowAssetPriceExp, decimal) / convert(TEN_EXP_18, decimal)
    collateralAssetPrice: decimal = convert(collateralAssetPriceExp, decimal) / convert(TEN_EXP_18, decimal)

    # convert the borrow balance to a decimal and scale it down
    borrowBalance: decimal = convert(borrowBalanceScaled, decimal) / convert(10 ** _borrow_context.decimals, decimal)

    # calculate the value of the borrow balance denominated in ETH
    borrowAmountInETH: decimal = borrowBalance * borrowAssetPrice

    # calculate the required collateral denominated in ETH
    requiredCollateralInETH: decimal = borrowAmountInETH / collateralAssetLTV

    # calculate the required collateral denominated in the collateral asset 
    requiredCollateral: decimal = requiredCollateralInETH / collateralAssetPrice

    # calculate the required collateral for Greenwood denominated in the collateral asset 
    requiredCollateralGreenwood: decimal = requiredCollateral * (convert(_loan.collateralizationRatio, decimal) / 100.0)

    # scale the required collateral for Greenwood by the decimals of the collateral asset
    requiredCollateralScaled: uint256 = convert(requiredCollateralGreenwood * convert(10 ** _collateral_context.decimals, decimal), uint256)

    # return the calculation
    return AaveV2WithdrawCalculation({
        requiredCollateral: requiredCollateralScaled,
        outstanding: borrowBalanceScaled
    })

@external
def calculateRepay(_borrow_context: AssetContext, _collateral_context: AssetContext, _amount: uint256, _escrow: address, _loan: Loan, _version: String[11]) -> AaveV2RepayCalculation:
    """
    @notice Calculate and return values needed to repay a loan on Aave V2
    @param _borrow_context The AssetContext struct of the asset being borrowed
    @param _collateral_context The AssetContext struct of the asset being used as collateral
    @param _amount The amount of asset being repaid scaled by the asset's decimals
    @param _escrow The address of the Greenwood Escrow use
    @param _loan A Loan struct containing loan data
    @param _version The version of the Greenwood Protocol to use
    @return AaveV2RepayCalculation struct
    @dev Passing 2 ** 256 - 1 as _amount triggers a full repayment
    @dev Only the AaveV2Escrow or the Governance can call this method
    """

    # require that the method caller is the Escrow or the Governance
    assert self.isAuthorized(msg.sender, "escrow", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True, "Only Escrow or Governance can call this method"
    
    # get the current borrowIndex of the borrow asset
    borrowReserveData: Bytes[768] = raw_call(
        _borrow_context.aaveV2LendingPool,
        concat(
            method_id("getReserveData(address)"),
            convert(_borrow_context.underlying, bytes32)
        ),
        max_outsize=768
    )

    # parse the variableBorrowIndex from borrowReserveData
    borrowIndex: uint256 = convert(slice(borrowReserveData, 64, 32), uint256)

    # parse the variableDebtTokenAddress from borrowReserveData
    variableDebtTokenAddress: address = convert(convert(slice(borrowReserveData, 288, 32), bytes32), address)

    # get variableDebtToken balance of the Escrow
    escrowBorrowBalance: uint256 = ERC20(variableDebtTokenAddress).balanceOf(_escrow)

    # get the variableDebtToken scaledBalanceOf of the Escrow
    scaledBalanceOfResponse: Bytes[32] = raw_call(
        variableDebtTokenAddress,
        concat(
            method_id("scaledBalanceOf(address)"),
            convert(_escrow, bytes32)
        ),
        max_outsize=32
    )

    # convert the scaledBalanceOfResponse to a uint256
    scaledBalanceOf: uint256 = convert(scaledBalanceOfResponse, uint256)

    # calculate the borrow balance increase of the Escrow
    balanceIncrease: decimal = ((convert(escrowBorrowBalance, decimal) - convert(scaledBalanceOf, decimal)) * (convert(_loan.lastBorrowIndex, decimal) / convert(10 ** 27, decimal))) / convert(10 ** 18, decimal)

    # declare a memory variable to store the amount of interest accrued
    interestAccrued: decimal = 0.0

    # check that the escrow borrow balance is not equal to the balance increase to prevent division by 0
    if convert(escrowBorrowBalance, decimal) != balanceIncrease:

        # calculate the interest accrued since the last action on the loan
        interestAccrued = balanceIncrease / (convert(escrowBorrowBalance, decimal) - balanceIncrease)

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

    # subtract the repayment amount from the borrow balance to get the outstanding balance
    outstandingBalanceScaled: int128 = convert(borrowBalance, int128) - convert(repayAmount, int128)

    # get the LTV ratio of the collateral asset
    collateralReserveData: Bytes[768] = raw_call(
        _collateral_context.aaveV2LendingPool,
        concat(
            method_id("getReserveData(address)"),
            convert(_collateral_context.underlying, bytes32)
        ),
        max_outsize=768
    )

    # parse the LTV from collateralReserveData and convert it to a percentage
    collateralAssetLTV: decimal = convert(convert(slice(collateralReserveData, 30, 2), uint256), decimal) / 10000.0

    # get the price of the borrow asset and the collateral asset denominated in ETH
    borrowAssetPriceExp: uint256 = AAVE_V2_PRICE_FEED(_borrow_context.aaveV2PriceFeed).getAssetPrice(_borrow_context.underlying)
    collateralAssetPriceExp: uint256 = AAVE_V2_PRICE_FEED(_collateral_context.aaveV2PriceFeed).getAssetPrice(_collateral_context.underlying)

    # scale down the prices and convert them to decimals
    borrowAssetPrice: decimal = convert(borrowAssetPriceExp, decimal) / convert(TEN_EXP_18, decimal)
    collateralAssetPrice: decimal = convert(collateralAssetPriceExp, decimal) / convert(TEN_EXP_18, decimal)

    # convert the outstanding balance to a decimal and scale it down
    outstandingBalance: decimal = convert(outstandingBalanceScaled, decimal) / convert(10 ** _borrow_context.decimals, decimal)

    # calculate the value of the outstanding borrow amount denominated in ETH
    borrowAmountInETH: decimal = outstandingBalance * borrowAssetPrice

    # calculate the required collateral denominated in ETH
    requiredCollateralInETH: decimal = borrowAmountInETH / collateralAssetLTV

    # calculate the amount of collateral asset to lock
    requiredCollateral: decimal = requiredCollateralInETH / collateralAssetPrice

    # calculate the required collateral denominated in the collateral asset
    requiredCollateralGreenwood: decimal = requiredCollateral * (convert(_loan.collateralizationRatio, decimal) / 100.0)

    # calculate the required collateral for Greenwood denominated in the collateral asset 
    requiredCollateralScaled: uint256 = convert(requiredCollateralGreenwood * convert(10 ** _collateral_context.decimals, decimal), uint256)

    # calculate the redemption amount
    redemptionAmount: int128 = convert(_loan.collateralLocked, int128) - convert(requiredCollateralScaled, int128)

    # return the calculations
    return AaveV2RepayCalculation({
        repayAmount: repayAmount,
        redemptionAmount: redemptionAmount,
        requiredCollateral: requiredCollateralScaled,
        outstanding: convert(outstandingBalance * convert(10 ** _borrow_context.decimals, decimal), int128), # scale the outstanding balance back up and convert it to an int128
        borrowIndex: borrowIndex
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