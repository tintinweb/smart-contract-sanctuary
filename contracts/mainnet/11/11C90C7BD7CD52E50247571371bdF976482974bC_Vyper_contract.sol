"""
@title Liquidator
@notice Loan liquidation contract for the Greenwood Protocol
@author Greenwood Labs
"""

# define the interfaces used by the contract
from vyper.interfaces import ERC20

interface AAVE_V2_PRICE_FEED:
    def getAssetPrice(_asset: address) -> uint256: view

interface COMPTROLLER:
    def markets(_c_token: address) -> (bool, uint256, bool): view

interface COMPOUND_PRICE_FEED:
    def price(_ticker: String[10]) -> uint256: view

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

interface ESCROW:
    def liquidate(_borrow_ticker: String[10], _collateral_ticker: String[10], _borrow_index: uint256, _key_count: uint256, _loan_keys: bytes32[100], _liquidator: address, _redeem_amount: uint256, _repay_amount: uint256, _store: address, _version: String[11]): payable

interface REGISTRY:
    def getAddress(_contract: String[20], _version: String[11], ) -> address: nonpayable
    def governance() -> address: nonpayable

interface STORE:
    def getAssetContext(_ticker: String[10]) -> AssetContext: view
    def recordLoan(_borrower: address, _borrow_asset: address, _collateral_asset: address, _collateralization_ratio: uint256, _collateral_locked: uint256, _index: uint256, _principal: uint256, _protocol: String[10], _version: String[11]): nonpayable
    def updateLoan(_collateral_locked: uint256, _index: uint256, _loan_key: bytes32, _outstanding: uint256, _version: String[11]): nonpayable
    def getLoan(_loan_key: bytes32) -> Loan: view
    def getLoanProtocol(_loan_key: bytes32) -> String[10]: view

# decalre the constants used by the contract
LOOP_LIMIT: constant(uint256) = 100
TEN_EXP_6: constant(uint256) = 1000000
TEN_EXP_18: constant(uint256) = 1000000000000000000
ZERO_BYTES_32: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000000000000

# define the events used by the contract
event SetRegistry:
    previousRegistry: address
    newRegistry: address
    governance: address
    blockNumber: uint256

#  define the structs used by the contract
struct AaveV2CollateralCalculation:
    isLiquidatable: bool
    outstanding: uint256

struct AaveV2Data:
    collateralAssetLTV: uint256
    borrowIndex: uint256
    variableDebtTokenAddress: address
    escrowBorrowBalance: uint256
    scaledBalanceOf: uint256
    borrowAssetPriceExp: uint256
    collateralAssetPriceExp: uint256

struct AssetContext:
    aToken: address
    aaveV2PriceFeed: address
    aaveV2LendingPool: address
    cToken: address
    compoundPriceFeed: address
    comptroller: address
    decimals: uint256
    underlying: address

struct CompoundData:
    collateralFactorMantissa: uint256
    borrowIndex: uint256
    borrowAssetPriceExp: uint256
    collateralAssetPriceExp: uint256

struct CompoundCollateralCalculation:
    isLiquidatable: bool
    outstanding: uint256

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
registry: public(address)
aaveV2Data: AaveV2Data
compoundData: CompoundData

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
        escrow: address = REGISTRY(self.registry).getAddress("controller", _version)

        # return the equality comparison boolean
        return escrow == _caller
    
    # check if the requested role is "governance"
    elif keccak256(_role) == keccak256("governance"):

        # get the address of the Governance from the Registry
        governance: address = REGISTRY(self.registry).governance()

        # return the equality comparison boolean
        return governance == _caller

    # catch extraneous role arguments
    else:

        # revert
        raise "Unhandled role argument"


@internal
def fetchAaveV2Data(_borrow_context: AssetContext, _collateral_context: AssetContext, _escrow: address) -> AaveV2Data:
    """
    @notice Get Aave V2 data for liquidation calculations
    @param _borrow_context The AssetContext struct of the asset being borrowed
    @param _collateral_context The AssetContext struct of the asset being used as collateral
    @param _escrow The address of the Greenwood Escrow to use
    @return AaveV2Data struct
    """

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
    collateralAssetLTV: uint256 = convert(slice(collateralReserveData, 30, 2), uint256)

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

    # get the variableDebtToken scaledBalanceOf the Escrow
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

    # get the price of the borrow asset and the collateral asset denominated in ETH
    borrowAssetPriceExp: uint256 = AAVE_V2_PRICE_FEED(_borrow_context.aaveV2PriceFeed).getAssetPrice(_borrow_context.underlying)
    collateralAssetPriceExp: uint256 = AAVE_V2_PRICE_FEED(_collateral_context.aaveV2PriceFeed).getAssetPrice(_collateral_context.underlying)

    # scale down the prices and convert them to decimals
    borrowAssetPrice: decimal = convert(borrowAssetPriceExp, decimal) / convert(TEN_EXP_18, decimal)
    collateralAssetPrice: decimal = convert(collateralAssetPriceExp, decimal) / convert(TEN_EXP_18, decimal)

    # return the data
    return AaveV2Data({
        collateralAssetLTV: collateralAssetLTV,
        borrowIndex: borrowIndex,
        variableDebtTokenAddress: variableDebtTokenAddress,
        escrowBorrowBalance: escrowBorrowBalance,
        scaledBalanceOf: scaledBalanceOf,
        borrowAssetPriceExp: borrowAssetPriceExp,
        collateralAssetPriceExp: collateralAssetPriceExp,
    })

@internal
def fetchCompoundData(_borrow_ticker: String[10], _collateral_ticker: String[10], _borrow_context: AssetContext, _collateral_context: AssetContext) -> CompoundData:
    """
    @notice Get Compound data for liquidation calculations
    @param _borrow_ticker The ticker string of the asset that is being borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _borrow_context The AssetContext struct of the asset being borrowed
    @param _collateral_context The AssetContext struct of the asset being used as collateral
    @return CompoundData struct
    """

    # setup memory variables to handle comptroller return values
    isListed: bool = False
    collateralFactorMantissa: uint256 = 0
    isComped: bool = False

    # get the collateral factor for the collateral asset using the comptroller
    isListed, collateralFactorMantissa, isComped  = COMPTROLLER(_collateral_context.comptroller).markets(_collateral_context.cToken)

    # get the current borrowIndex from the cToken
    borrowIndex: uint256 = CTOKEN(_borrow_context.cToken).borrowIndex()

    # get the price of the borrow asset and the collateral asset denominated in USD
    borrowAssetPriceExp: uint256 = COMPOUND_PRICE_FEED(_borrow_context.compoundPriceFeed).price(_borrow_ticker)
    collateralAssetPriceExp: uint256 = COMPOUND_PRICE_FEED(_collateral_context.compoundPriceFeed).price(_collateral_ticker)

    # return the data
    return CompoundData({
        collateralFactorMantissa: collateralFactorMantissa,
        borrowIndex: borrowIndex,
        borrowAssetPriceExp: borrowAssetPriceExp,
        collateralAssetPriceExp: collateralAssetPriceExp
    })

@internal
def checkAaveV2Collateral(_borrow_context: AssetContext, _collateral_context: AssetContext, _aave_v2_data: AaveV2Data, _escrow: address, _loan: Loan) -> AaveV2CollateralCalculation:
    """
    @notice Calculate the required collateral and liquidatibility for an Aave V2 loan
    @param _borrow_context The AssetContext struct of the asset being borrowed
    @param _collateral_context The AssetContext struct of the asset being used as collateral
    @param _aave_v2_data The AaveV2Data struct with data for liquidation calculatios
    @param _escrow The address of the Greenwood Escrow to use
    @param _loan A Loan struct containing loan data
    @return AaveV2CollateralCalculation struct
    """

    # scale down the LTV to a percentage
    collateralAssetLTV: decimal = convert(_aave_v2_data.collateralAssetLTV, decimal) / 10000.0

    # calculate the borrow balance increase of the Escrow
    balanceIncrease: decimal = ((convert(_aave_v2_data.escrowBorrowBalance, decimal) - convert(_aave_v2_data.scaledBalanceOf, decimal)) * (convert(_loan.lastBorrowIndex, decimal) / convert(10 ** 27, decimal))) / convert(10 ** 18, decimal)

    # declare a memory variable to store the amount of interest accrued
    interestAccrued: decimal = 0.0

    # check that the Escrow borrow balance is not equal to the balance increase to prevent division by 0
    if convert(_aave_v2_data.escrowBorrowBalance, decimal) != balanceIncrease:

        # calculate the interest accrued since the last action on the loan
        interestAccrued = balanceIncrease / (convert(_aave_v2_data.escrowBorrowBalance, decimal) - balanceIncrease)

    # apply interest accrued to the outstanding balance of the loan
    borrowBalanceScaled: uint256 = convert(convert(_loan.outstanding, decimal) * (1.0 + interestAccrued), uint256)

    # scale down the prices and convert them to decimals
    borrowAssetPrice: decimal = convert(_aave_v2_data.borrowAssetPriceExp, decimal) / convert(TEN_EXP_18, decimal)
    collateralAssetPrice: decimal = convert(_aave_v2_data.collateralAssetPriceExp, decimal) / convert(TEN_EXP_18, decimal)

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

    # subtract the required collateral from the collateral locked to see if the loan is undercollateralized
    collateralDifference: int128 = convert(_loan.collateralLocked, int128) - convert(requiredCollateralScaled, int128)

    # check if the collateral difference is negative
    if collateralDifference < 0:

        # if the collateral difference is negative return True
        return AaveV2CollateralCalculation({
            isLiquidatable: True,
            outstanding: borrowBalanceScaled
        })

    # check if the collateral difference is non-negative
    elif collateralDifference >= 0:
        
        # if the collateral difference is non-negative return False
        return AaveV2CollateralCalculation({
            isLiquidatable: False,
            outstanding: 0
        })

    else:

        # return False as a fallback case
        return AaveV2CollateralCalculation({
            isLiquidatable: False,
            outstanding: 0
        })

@internal
def checkCompoundCollateral(_borrow_ticker: String[10], _collateral_ticker: String[10], _borrow_context: AssetContext, _collateral_context: AssetContext, _compound_data: CompoundData, _loan: Loan) -> CompoundCollateralCalculation:
    """
    @notice Calculate the required collateral and liquidatibility for a Compound loan
    @param _borrow_ticker The ticker string of the asset that is being borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _borrow_context The AssetContext struct of the asset being borrowed
    @param _collateral_context The AssetContext struct of the asset being used as collateral
    @param _compound_data The CompoundData struct with data for liquidation calculatios
    @param _loan A Loan struct containing loan data
    @return CompoundCollateralCalculation struct
    """

    # convert collateralFactorMantissa to a percentage
    collateralFactor: decimal = convert(_compound_data.collateralFactorMantissa, decimal) / convert(TEN_EXP_18, decimal)

    # calculate the interestAccrued since the last action on the loan
    interestAccrued: decimal = convert(_compound_data.borrowIndex, decimal) / convert(_loan.lastBorrowIndex, decimal) - 1.0

    # apply interest accrued to the outstanding balance of the loan
    borrowBalanceScaled: uint256 = convert(convert(_loan.outstanding, decimal) * (1.0 + interestAccrued), uint256)

    # convert the prices to decimals
    borrowAssetPrice: decimal = convert(_compound_data.borrowAssetPriceExp, decimal) / convert(TEN_EXP_6, decimal)
    collateralAssetPrice: decimal = convert(_compound_data.collateralAssetPriceExp, decimal) / convert(TEN_EXP_6, decimal)

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

    # subtract the required collateral from the collateral locked to see if the loan is undercollateralized
    collateralDifference: int128 = convert(_loan.collateralLocked, int128) - convert(requiredCollateralScaled, int128)

    # check if the collateral difference is negative
    if collateralDifference < 0:

        # if the collateral difference is negative return True
        return CompoundCollateralCalculation({
            isLiquidatable: True,
            outstanding: borrowBalanceScaled
        })

    # check if the collateral difference is non-negative
    elif collateralDifference >= 0:
        
        # if the collateral difference is non-negative return False
        return CompoundCollateralCalculation({
            isLiquidatable: False,
            outstanding: 0
        })

    else:

        # return False as a fallback case
        return CompoundCollateralCalculation({
            isLiquidatable: False,
            outstanding: 0
        })


@external
@payable
def liquidate(_borrow_ticker: String[10], _collateral_ticker: String[10], _aave_v2_escrow: address, _compound_escrow: address, _key_count: uint256, _liquidator: address, _loan_keys: bytes32[100], _aave_v2_loan_keys: bytes32[100], _compound_loan_keys: bytes32[100], _store: address, _version: String[11]):
    """
    @notice Compile undercollateralized loans for liquidation
    @param _borrow_ticker The ticker string of the asset that is being borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _store The address of the Greenwood AaveV2Escrow to use
    @param _store The address of the Greenwood CompoundEscrow to use
    @param _key_count The number of uinque identifiers in the _loan_keys array
    @param _liquidator The address that submitted the liquidation request
    @param _loan_keys An array of uinque identifiers for loans
    @param _aave_v2_loan_keys An empty array to store loan keys for Aave V2 loans
    @param _compound_loan_keys An empty array to store loan keys for Compound loans
    @param _store The address of the Greenwood Store to use
    @param _version The version of Greenwood to use
    @dev Only the Controller or the Governance can call this method
    """

    # require that the method is being called by the Controller or the Governance
    assert self.isAuthorized(msg.sender, "controller", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True, "Only Controller or Governance can call this method"

    # get the asset contexts for the borrow asset and the collateral asset from the Store
    collateralContext: AssetContext = STORE(_store).getAssetContext(_collateral_ticker)
    borrowContext: AssetContext = STORE(_store).getAssetContext(_borrow_ticker)

    # declare memory variables to store the number of loan keys that have been processed and the current indexes of the loanKey arrays
    loanKeyCounter: uint256 = 0
    currentAaveV2Index: uint256 = 0
    currentCompoundIndex: uint256 = 0

    # declare memory variables to store the loan keys of loans that need to be liquidated
    aaveV2LoanKeys: bytes32[100] = _aave_v2_loan_keys
    compoundLoanKeys: bytes32[100] = _compound_loan_keys

    # declare memory variables to store the status of fetched data
    isAaveV2DataFetched: bool = False
    isCompoundDataFetched: bool = False

    # declare memory variables to accumulate outstanding balances and collateral locked
    aaveV2Outstanding: uint256 = 0
    compoundOutstanding: uint256 = 0
    aaveV2CollateralLocked: uint256 = 0
    compoundCollateralLocked: uint256 = 0

    # loop over the loan keys
    for i in range(LOOP_LIMIT):

        if loanKeyCounter < _key_count:

            # get the current loan key from loan keys
            currentKey: bytes32 = _loan_keys[i]
        
            # get loan data from the Store
            currentLoan: Loan = STORE(_store).getLoan(currentKey)

            # require that a loan was returned
            assert currentLoan.borrowAsset != ZERO_ADDRESS, "No loan returned from the Store"

            # get loan protocol from the Store
            currentProtocol: String[10] = STORE(_store).getLoanProtocol(currentKey)

            # require that a loan protocol was returned
            assert keccak256(currentProtocol) == keccak256("aavev2") or keccak256(currentProtocol) == keccak256("compound"), "Invalid protocol returned from the Store"

            # require that the outstanding balance of the loan is non-negative
            assert currentLoan.outstanding > 0, "Outstanding balance must be greater than 0"

            # require that the underlying asset of the loan and contexts match
            assert currentLoan.borrowAsset == borrowContext.underlying, "Borrow context mismatch"
            assert currentLoan.collateralAsset == collateralContext.underlying, "Collateral context mismatch"

            # check if the loan was originated with Aave V2 but Aave V2 data has not been fetched
            if keccak256(currentProtocol) == keccak256("aavev2") and isAaveV2DataFetched == False:

                # get Aave V2 data
                self.aaveV2Data = self.fetchAaveV2Data(borrowContext, collateralContext, _aave_v2_escrow)

                # prevent refetching the data
                isAaveV2DataFetched = True

                # check if the current loan is liquidatable
                aaveV2CollateralCalculation: AaveV2CollateralCalculation = self.checkAaveV2Collateral(borrowContext, collateralContext, self.aaveV2Data , _aave_v2_escrow, currentLoan)

                # handle the return from checkAaveV2Collateral
                if aaveV2CollateralCalculation.isLiquidatable == True:

                    # if the current loan is liquidatable write the loan key to a byte array
                    aaveV2LoanKeys[currentAaveV2Index] = currentKey

                    # add the outstanding balance to the overall outstanding balance for the batch of aave loans
                    aaveV2Outstanding += aaveV2CollateralCalculation.outstanding

                    # add the locked collateral to the overall collateral to redeem
                    aaveV2CollateralLocked += currentLoan.collateralLocked

                    # increment the index
                    currentAaveV2Index += 1

            # check if the loan was originated with Aave V2 and Aave V2 data has been fetched
            elif keccak256(currentProtocol) == keccak256("aavev2") and isAaveV2DataFetched == True:
                
                # check if the current loan is liquidatable
                aaveV2CollateralCalculation: AaveV2CollateralCalculation = self.checkAaveV2Collateral(borrowContext, collateralContext, self.aaveV2Data , _aave_v2_escrow, currentLoan)

                # handle the return from checkAaveV2Collateral
                if aaveV2CollateralCalculation.isLiquidatable == True:

                    # if the current loan is liquidatable write the loan key to a byte array
                    aaveV2LoanKeys[currentAaveV2Index] = currentKey

                    # add the outstanding balance to the overall outstanding balance for the batch of aave loans
                    aaveV2Outstanding += aaveV2CollateralCalculation.outstanding

                    # add the locked collateral to the overall collateral to redeem
                    aaveV2CollateralLocked += currentLoan.collateralLocked

                    # increment the index
                    currentAaveV2Index += 1
            
            # check if the loan was originated with Compound but Compound data has not been fetched
            elif keccak256(currentProtocol) == keccak256("compound") and isCompoundDataFetched == False:

                # fetch compound data
                self.compoundData = self.fetchCompoundData(_borrow_ticker, _collateral_ticker, borrowContext, collateralContext)

                # set isCompoundDataFetched to True to prevent refetching the data
                isCompoundDataFetched = True

                # check if the current loan is liquidatable
                compoundCollateralCalculation: CompoundCollateralCalculation = self.checkCompoundCollateral(_borrow_ticker, _collateral_ticker, borrowContext, collateralContext, self.compoundData, currentLoan)

                # handle the return from checkCompoundCollateral
                if compoundCollateralCalculation.isLiquidatable == True:

                    # if the current loan is liquidatable write the loan key to a byte array
                    compoundLoanKeys[currentCompoundIndex] = currentKey

                    # add the outstanding balance to the overall outstanding balance for the batch of aave loans
                    compoundOutstanding += compoundCollateralCalculation.outstanding

                    # add the locked collateral to the overall collateral to redeem
                    compoundCollateralLocked += currentLoan.collateralLocked

                    # increment the index
                    currentCompoundIndex += 1

            # check if the loan was originated with Compound and Compound data has been fetched
            elif keccak256(currentProtocol) == keccak256("compound") and isCompoundDataFetched == True:

                # check if the current loan is liquidatable
                compoundCollateralCalculation: CompoundCollateralCalculation = self.checkCompoundCollateral(_borrow_ticker, _collateral_ticker, borrowContext, collateralContext, self.compoundData, currentLoan)

                # handle the return from checkCompoundCollateral
                if compoundCollateralCalculation.isLiquidatable == True:

                    # if the current loan is liquidatable write the loan key to a byte array
                    compoundLoanKeys[currentCompoundIndex] = currentKey

                    # add the outstanding balance to the overall outstanding balance for the batch of aave loans
                    compoundOutstanding += compoundCollateralCalculation.outstanding

                    # add the locked collateral to the overall collateral to redeem
                    compoundCollateralLocked += currentLoan.collateralLocked

                    # increment the index
                    currentCompoundIndex += 1

            # catch extraneous lending protocols
            else:

                # revert
                raise "Unhandled loan protocol"

            # increment the loan key counter
            loanKeyCounter += 1

        # all loan keys have been processed
        elif loanKeyCounter == _key_count:

            # halt loop execution
            break

        else:

            # halt loop execution as a fallback case
            break

    # check if aaveV2LoanKeys is empty
    if aaveV2LoanKeys[0] != ZERO_BYTES_32:
        
        # call liquidate on the Escrow with the aave v2 loan keys
        ESCROW(_aave_v2_escrow).liquidate(_borrow_ticker, _collateral_ticker, self.aaveV2Data.borrowIndex, currentAaveV2Index, aaveV2LoanKeys, _liquidator, aaveV2CollateralLocked, aaveV2Outstanding, _store, _version)

    # check if compoundLoanKeys is empty
    if compoundLoanKeys[0] != ZERO_BYTES_32:

        # call liquidate on the Escrow with the compound loan keys
        ESCROW(_compound_escrow).liquidate(_borrow_ticker, _collateral_ticker, self.compoundData.borrowIndex, currentCompoundIndex, compoundLoanKeys, _liquidator, compoundCollateralLocked, compoundOutstanding, _store, _version, value=msg.value)


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