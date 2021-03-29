"""
@title Greenwood CompoundEscrow
@notice Compound integrations for the Greenwood Protocol
@author Greenwood Labs
"""

# define the interfaces used by the contract
from vyper.interfaces import ERC20

interface COMPOUND_CALCULATOR:
    def calculateBorrow(_borrow_ticker: String[10], _collateral_ticker: String[10], _borrow_context: AssetContext, _collateral_context: AssetContext, _amount: uint256, _collateralization_ratio: uint256, _version: String[11]) -> CompoundBorrowCalculation: nonpayable
    def calculateWithdraw(_borrow_ticker: String[10], _collateral_ticker: String[10], _borrow_context: AssetContext, _collateral_context: AssetContext, _loan: Loan, _version: String[11]) -> CompoundWithdrawCalculation: nonpayable
    def calculateRepay(_borrow_ticker: String[10], _collateral_ticker: String[10], _borrow_context: AssetContext, _collateral_context: AssetContext, _amount: uint256, _loan: Loan, _version: String[11]) -> CompoundRepayCalculation: nonpayable

interface CTOKEN:
    def mint(_mint_amount: uint256) -> uint256: nonpayable
    def borrow(_borrow_amount: uint256) -> uint256: nonpayable
    def repayBorrow(_repay_amount: uint256) -> uint256: nonpayable
    def borrowIndex() -> uint256: nonpayable
    def redeemUnderlying(_redeem_amount: uint256) -> uint256: nonpayable
    def exchangeRateStored() -> uint256: nonpayable
    def borrowRatePerBlock() -> uint256: nonpayable
    def borrowBalanceCurrent(_account: address) -> uint256: nonpayable
    def accrualBlockNumber() -> uint256: nonpayable

interface REGISTRY:
    def getAddress(_contract: String[20], _version: String[11]) -> address: nonpayable
    def governance() -> address: nonpayable

interface STORE:
    def getAssetContext(_ticker: String[10]) -> AssetContext: view
    def recordLoan(_borrower: address, _borrow_asset: address, _collateral_asset: address, _collateralization_ratio: uint256, _collateral_locked: uint256, _index: uint256, _principal: uint256, _protocol: String[10], _version: String[11]): nonpayable
    def updateLoan(_collateral_locked: uint256, _index: uint256, _loan_key: bytes32, _outstanding: uint256, _version: String[11]): nonpayable
    def getLoan(_loan_key: bytes32) -> Loan: view
    def getLoanProtocol(_loan_key: bytes32) -> String[10]: view

# define the events emitted by the contract
event AddCollateral:
    loanKey: bytes32
    depositor: address
    amount: uint256
    collateralAsset: address
    blockNumber: uint256

event Borrow:
    borrower: address
    amount: uint256
    borrowAsset: address
    collateralAsset: address
    blockNumber: uint256

event Fallback:
    value: uint256
    sender: address
    blockNumber: uint256

event Liquidate:
    loanKey: bytes32
    outstanding: uint256
    borrowAsset: address
    collateralAsset: address
    blockNumber: uint256

event Liquidation:
    borrowAsset: address
    collateralAsset: address
    liquidator: address
    loanKeys: bytes32[100]
    redemptionAmount: uint256
    repayAmount: uint256
    blockNumber: uint256

event Repay:
    borrower: address
    repaymentAmount: uint256
    repaymentAsset: address
    redemptionAmount: uint256
    redemptionAsset: address
    blockNumber: uint256

event SetRegistry:
    previousRegistry: address
    newRegistry: address
    governance: address
    blockNumber: uint256

event WithdrawCollateral:
    loanKey: bytes32
    amount: uint256
    collateralAsset: address
    collateralLocked: uint256
    blockNumber: uint256

# define the constants used by the contract
LOOP_LIMIT: constant(uint256) = 100

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

        # return the equality comparison
        return escrow == _caller
    
    # check if the requested role is "governance"
    elif keccak256(_role) == keccak256("governance"):

        # get the address of the Governance from the Registry
        governance: address = REGISTRY(self.registry).governance()

        # return the equality comparison
        return governance == _caller

    # check if the requested role is "liquidator"
    elif keccak256(_role) == keccak256("liquidator"):

        # get the address of the Liquidator from the Registry
        liquidator: address = REGISTRY(self.registry).getAddress("liquidator", _version)

        # return the equality comparison
        return liquidator == _caller

    # catch extraneous role arguments
    else:

        # revert
        raise "Unhandled role argument"

@internal
def handleEnterMarketsResponse(_byte_arr: Bytes[96]) -> uint256:
  """
  @notice Converts 96 byte array to a uint256
  @param _byte_arr Byte array of length 96
  @return uint256
  @dev This assumes it is the output from a raw_call that takes form of offset + length + response
  """

  # assumes output is coming from an uint[], therefore start at byte 64
  # because first two sets of 32 are offset & length
  start: int128 = 32 * 2

  # extract32 bytes of data
  extracted: bytes32 = extract32(_byte_arr, start, output_type=bytes32)

  # return converted 32 bytes to uint256
  return convert(extracted, uint256)

@external
@payable
def borrow(_borrow_ticker: String[10], _collateral_ticker: String[10], _borrow_context: AssetContext, _collateral_context: AssetContext, _amount: uint256, _borrower: address, _calculator: address, _collateralization_ratio: uint256, _store: address, _version: String[11]):
    """
    @notice Borrow assets from Compound
    @param _borrow_ticker The ticker string of the asset being borrowed
    @param _collateral_ticker The ticker string of the asset being used as collateral
    @param _borrow_context The AssetContext struct of the asset being borrowed
    @param _collateral_context The AssetContext struct of the asset being used as collateral
    @param _amount The amount of asset being borrowed scaled by the asset's decimals
    @param _borrower The address of the borrower
    @param _calculator The address of the Grenwood Calculator to use
    @param _collateralization_ratio The collateralization ratio for the loan as a percentage
    @param _store The address of the Greenwood Store to use
    @param _version The version of Greenwood to use
    @dev Only the Controller or the Governance can call this method
    """

    # require that the method is being called by the Controller or the Governance
    assert self.isAuthorized(msg.sender, "controller", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True

    # require that the borrow amount is greater than 0 after scaling it down
    assert convert(_amount, decimal) / convert(10 ** _borrow_context.decimals, decimal) > 0.0

    # get required collateral, borrow index, borrow amount, and the origination fee from the Calculator
    borrowCalculations: CompoundBorrowCalculation = COMPOUND_CALCULATOR(_calculator).calculateBorrow(_borrow_ticker, _collateral_ticker, _borrow_context, _collateral_context, _amount, _collateralization_ratio, _version)

    # check if the collateral asset is ETH
    if keccak256(_collateral_ticker) == keccak256("ETH"):

        # check if the origination fee is greater than 0
        if borrowCalculations.originationFee > 0:

            # get the address of the Treasury from the Registry
            treasury: address = REGISTRY(self.registry).getAddress("treasury", _version)

            # require that a Treasury address was returned from the Store
            assert treasury != ZERO_ADDRESS

            # send the origination fee to the Treasury
            send(treasury, borrowCalculations.originationFee)

        # call mint() on the cEther contract and send msg.value, less the origination fee, in wei
        raw_call(
            _collateral_context.cToken,
            method_id("mint()"),
            value = msg.value - borrowCalculations.originationFee
        )

    else:

        # check if the origination fee is greater than 0
        if borrowCalculations.originationFee > 0:

            # get the address of the Treasury from the Registry
            treasury: address = REGISTRY(self.registry).getAddress("treasury", _version)

            # require that a Treasury address was returned from the Store
            assert treasury != ZERO_ADDRESS

            # transfer the origination fee to the Treasury
            transferResponse: Bytes[32] = raw_call(
                _collateral_context.underlying,
                concat(
                    method_id("transferFrom(address,address,uint256)"),
                    convert(_borrower, bytes32),
                    convert(treasury, bytes32),
                    convert(borrowCalculations.originationFee, bytes32),
                ),
                max_outsize=32,
            )
            if len(transferResponse) > 0:
                assert convert(transferResponse, bool)

        # move collateral from the borrower to Escrow 
        transferFromResponse: Bytes[32] = raw_call(
            _collateral_context.underlying,
            concat(
                method_id("transferFrom(address,address,uint256)"),
                convert(_borrower, bytes32),
                convert(self, bytes32),
                convert(borrowCalculations.requiredCollateral, bytes32),
            ),
            max_outsize=32,
        ) 
        if len(transferFromResponse) > 0:
            assert convert(transferFromResponse, bool)

        # approve the collateral transfer from Escrow to Compound
        approveResponse: Bytes[32] = raw_call(
            _collateral_context.underlying,
            concat(
                method_id("approve(address,uint256)"),
                convert(_collateral_context.cToken, bytes32),
                convert(borrowCalculations.requiredCollateral, bytes32),
            ),
            max_outsize=32,
        )
        if len(approveResponse) > 0:
            assert convert(approveResponse, bool)

        # require that the cTokens were minted successfully
        assert CTOKEN(_collateral_context.cToken).mint(borrowCalculations.requiredCollateral) == 0

    # allow for the usage of the collateral asset as collateral in Compound
    enterMarketsResponse: Bytes[96] = raw_call(
        _collateral_context.comptroller,                                # compound comptroller address
        concat(
            method_id("enterMarkets(address[])", output_type=Bytes[4]), # enterMarkets() method signature (4 bytes)
            convert(32, bytes32),                                       # offset (32 bytes)
            convert(1, bytes32),                                        # arrayLength (32 bytes)
            convert(_collateral_context.cToken, bytes32)                # addressArray (32 * 1 bytes)
        ),
        max_outsize=96,                                                 # outsize = offset + arrayLength + addressArray
    )

    # require that the market was entered successfully
    assert self.handleEnterMarketsResponse(enterMarketsResponse) == 0

    # require that the Compound borrow was successful
    assert CTOKEN(_borrow_context.cToken).borrow(_amount) == 0

    # get the current borrow index from the cToken
    borrowIndex: uint256 = CTOKEN(_borrow_context.cToken).borrowIndex()

    # check if the borrow asset is ETH
    if keccak256(_borrow_ticker) == keccak256("ETH"):

        # transfer ETH to the borrower
        send(_borrower, _amount)

    else:

        # transfer the borrow asset to the borrower
        transferResponse: Bytes[32] = raw_call(
            _borrow_context.underlying,
            concat(
                method_id("transfer(address,uint256)"),
                convert(_borrower, bytes32),
                convert(_amount, bytes32),
            ),
            max_outsize=32,
        )
        if len(transferResponse) > 0:
            assert convert(transferResponse, bool)

    # pass loan data to the Store for storage
    STORE(_store).recordLoan(_borrower, _borrow_context.underlying, _collateral_context.underlying, _collateralization_ratio, borrowCalculations.requiredCollateral, borrowIndex, _amount, "compound", _version)

    # emit a Borrow event
    log Borrow(_borrower, _amount, _borrow_context.underlying, _collateral_context.underlying, block.number)

@external
@payable
def repay(_borrow_ticker: String[10], _collateral_ticker: String[10], _amount: uint256, _calculator: address, _loan_key: bytes32, _store: address, _version: String[11]):
    """
    @notice Repay a Compound loan
    @param _borrow_ticker The ticker string of the asset that was borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _amount The amount of the repayment scaled by the asset's decimals
    @param _calculator The address of the Greenwood Calculator to use
    @param _loan_key The uinque identifier for the loan
    @param _store The address of the Greenwood Store to use
    @param _version The version of Greenwood to use
    @dev Only the Controller or the Governance can call this method
    """

    # require that the method is being called by the controller or the governance
    assert self.isAuthorized(msg.sender, "controller", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True

    # get the loan protocol from the Store
    loanProtocol: String[10] = STORE(_store).getLoanProtocol(_loan_key)

    # get the rest of the loan data from the Store
    loan: Loan = STORE(_store).getLoan(_loan_key)

    # require that the outstanding balance of the loan is greater than
    assert loan.outstanding > 0

    # get the asset contexts for the borrow asset and the collateral asset from the Store
    borrowContext: AssetContext = STORE(_store).getAssetContext(_borrow_ticker)
    collateralContext: AssetContext = STORE(_store).getAssetContext(_collateral_ticker)

    # require the the loan assets match the underlying assets of the contexts
    assert borrowContext.underlying == loan.borrowAsset
    assert collateralContext.underlying == loan.collateralAsset

    # check if this is a full repayment
    if _amount != MAX_UINT256:

        # require that the repay amount is greater than 0 after scaling it down
        assert convert(_amount, decimal) / convert(10 ** borrowContext.decimals, decimal) > 0.0
        
    # check that this loan was originated with Aave V2
    if keccak256(loanProtocol) == keccak256("compound"):

        # get the redemption amount from the Calculator
        repayCalculations: CompoundRepayCalculation = COMPOUND_CALCULATOR(_calculator).calculateRepay(_borrow_ticker, _collateral_ticker, borrowContext, collateralContext, _amount, loan, _version)

        # check if the borrow asset is ETH
        if keccak256(_borrow_ticker) == keccak256("ETH"):

            # call repayBorrow() on the cEther contract and send msg.value in wei
            raw_call(
                borrowContext.cToken,
                method_id("repayBorrow()"),
                value=msg.value
            )

        else:
            # move repayment asset (borrow asset) from borrower to Greenwood
            transferFromResponse: Bytes[32] = raw_call(
                borrowContext.underlying,
                concat(
                    method_id("transferFrom(address,address,uint256)"),
                    convert(loan.borrower, bytes32),
                    convert(self, bytes32),
                    convert(repayCalculations.repayAmount, bytes32),
                ),
                max_outsize=32,
            ) 
            if len(transferFromResponse) > 0:
                assert convert(transferFromResponse, bool)

            # approve the cToken of the borrow asset to access the token balance of Escrow
            approveResponse: Bytes[32] = raw_call(
                borrowContext.underlying,
                concat(
                    method_id("approve(address,uint256)"),
                    convert(borrowContext.cToken, bytes32),
                    convert(repayCalculations.repayAmount, bytes32),
                ),
                max_outsize=32,
            )
            if len(approveResponse) > 0:
                assert convert(approveResponse, bool)

            # require that the repayment was successful
            assert CTOKEN(borrowContext.cToken).repayBorrow(repayCalculations.repayAmount) == 0
            
        # if redemption amount is positive, redeem redemptionAmount of the collateral cToken for the underlying,
        if repayCalculations.redemptionAmount < 0:

            # emit a Liquidate event
            log Liquidate(_loan_key, loan.outstanding, borrowContext.underlying, collateralContext.underlying, block.number)

        elif repayCalculations.redemptionAmount > 0:

            # get the current borrowIndex from the cToken
            borrowIndex: uint256 = CTOKEN(borrowContext.cToken).borrowIndex()

            # require that the redemption was successful
            assert CTOKEN(collateralContext.cToken).redeemUnderlying(convert(repayCalculations.redemptionAmount, uint256)) == 0

            # check if the collateral asset is ETH
            if keccak256(_collateral_ticker) == keccak256("ETH"):

                # send the redeemed ETH back to the borrower
                send(loan.borrower, convert(repayCalculations.redemptionAmount, uint256))

            else:
            
                # transfer the redeemed collateral asset back to the borrower
                transferResponse: Bytes[32] = raw_call(
                    collateralContext.underlying,
                    concat(
                        method_id("transfer(address,uint256)"),
                        convert(loan.borrower, bytes32),
                        convert(convert(repayCalculations.redemptionAmount, uint256), bytes32),
                    ),
                    max_outsize=32,
                )
                if len(transferResponse) > 0:
                    assert convert(transferResponse, bool)

            # update the loan with outstanding balance and collateral needed
            STORE(_store).updateLoan(repayCalculations.requiredCollateral, borrowIndex, _loan_key, convert(repayCalculations.outstanding, uint256), _version)
            
            # emit a Repay event
            log Repay(loan.borrower, repayCalculations.repayAmount, borrowContext.underlying, convert(repayCalculations.redemptionAmount, uint256), collateralContext.underlying, block.number)

        elif repayCalculations.redemptionAmount == 0:

            # emit a Repay event
            log Repay(loan.borrower, repayCalculations.repayAmount, borrowContext.underlying, convert(repayCalculations.redemptionAmount, uint256), collateralContext.underlying, block.number)


@external
@payable
def addCollateral(_collateral_ticker: String[10], _amount: uint256, _depositor: address, _loan_key: bytes32, _store: address, _version: String[11]):
    """
    @notice Add collateral to Compound
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _amount The amount of the deposit scaled by the asset's decimals
    @param _depositor The address of the depositor
    @param _loan_key The uinque identifier for the loan
    @param _store The address of the Greenwood Store contract to use
    @param _version The version of Greenwood to use
    @dev Only the Controller or the Governance can call this method
    """


    # require that the method is being called by the Controller or the Governance
    assert self.isAuthorized(msg.sender, "controller", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True

    # get the loan's protocol from the Store
    protocol: String[10] = STORE(_store).getLoanProtocol(_loan_key)

    # require that a protocol was returned from the Store
    assert keccak256(protocol) != keccak256("")

    # get the loan data from the Store
    loan: Loan = STORE(_store).getLoan(_loan_key)

    # get the context of the collateral asset from the Store
    collateralContext: AssetContext = STORE(_store).getAssetContext(_collateral_ticker)

    # require that the loan's collateral asset and underlying asset of the collateral context match
    assert loan.collateralAsset == collateralContext.underlying

    # require that the deposit amount is greater than 0 adter scaling it dow# require that the deposit amount is greater than 0 after scaling it down
    assert convert(_amount, decimal) / convert(10 ** collateralContext.decimals, decimal) > 0.0

    # check if this loan was originated with Compound
    if keccak256(protocol) == keccak256("compound"):

        # check if the collateral asset is ETH
        if keccak256(_collateral_ticker) == keccak256("ETH"):

            # require that the _value sent matches the _amount to add
            assert _amount == msg.value

            # call mint() on the cEther contract and send msg.value in wei
            raw_call(
                collateralContext.cToken,
                method_id("mint()"),
                value=msg.value
            )
        
        else:

            # move collateral from user to Escrow 
            transferFromResponse: Bytes[32] = raw_call(
                collateralContext.underlying,
                concat(
                    method_id("transferFrom(address,address,uint256)"),
                    convert(_depositor, bytes32),
                    convert(self, bytes32),
                    convert(_amount, bytes32),
                ),
                max_outsize=32,
            ) 
            if len(transferFromResponse) > 0:
                assert convert(transferFromResponse, bool)

            # approve the collateral transfer from Escrow to Compound
            approveResponse: Bytes[32] = raw_call(
                collateralContext.underlying,
                concat(
                    method_id("approve(address,uint256)"),
                    convert(collateralContext.cToken, bytes32),
                    convert(_amount, bytes32),
                ),
                max_outsize=32,
            )
            if len(approveResponse) > 0:
                assert convert(approveResponse, bool)

            # require that the cToken minst was successful
            assert CTOKEN(collateralContext.cToken).mint(_amount) == 0

        # add the amount of collateral to the existing amount of collateralLocked
        collateralLocked: uint256 = loan.collateralLocked + _amount

        # pass borrowIndex of 0 so this member of the struct is not updated
        borrowIndex: uint256 = 0

        # update the loan with the new value of collateral locked
        STORE(_store).updateLoan(collateralLocked, borrowIndex, _loan_key, loan.outstanding, _version)

        # emit an AddCollateral event
        log AddCollateral(_loan_key, _depositor, _amount, collateralContext.underlying, block.number)
        
    else:
        raise "malformed protocol string"

@external
def withdrawCollateral(_borrow_ticker: String[10], _collateral_ticker: String[10], _amount: uint256, _calculator: address, _loan_key: bytes32, _store: address, _version: String[11]):
    """
    @notice Withdraw collateral from Compound
    @param _borrow_ticker The ticker string of the asset that was borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _amount The amount to withdraw scaled by the asset's decimals
    @param _calculator The address of the Greenwood Calculator to use
    @param _loan_key The uinque identifier for the loan
    @param _store The address of the Greenwood Store to use
    @param _version The version of Greenwood to use
    @dev Only the Controller or the Governance can call this method
    """

    # require that the method is being called by the Controller or the Governance
    assert self.isAuthorized(msg.sender, "controller", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True

    # get the loan's protocol from the Store 
    protocol: String[10] = STORE(_store).getLoanProtocol(_loan_key)

    # require that a protocol was returned from the Store
    assert keccak256(protocol) != keccak256("")

    # get the loan data from the Store 
    loan: Loan = STORE(_store).getLoan(_loan_key)

    # get the asset contexts for the borrow asset and the collateral asset from the Store
    collateralContext: AssetContext = STORE(_store).getAssetContext(_collateral_ticker)
    borrowContext: AssetContext = STORE(_store).getAssetContext(_borrow_ticker)

    # require the the loan assets match the underlying assets of the contexts
    assert loan.borrowAsset == borrowContext.underlying
    assert loan.collateralAsset == collateralContext.underlying

    # require that the withdraw amount is greater than 0 after scaling it down
    assert convert(_amount, decimal) / convert(10 ** collateralContext.decimals, decimal) > 0.0

    # check if this loan was originated with Compound
    if keccak256(protocol) == keccak256("compound"):

        # get the withdraw calculations from the Calculator
        withdrawCalculations: CompoundWithdrawCalculation = COMPOUND_CALCULATOR(_calculator).calculateWithdraw(_borrow_ticker, _collateral_ticker, borrowContext, collateralContext, loan, _version)

        # require that this withdraw does not violate collateral requirements
        assert loan.collateralLocked - _amount >= withdrawCalculations.requiredCollateral

        # redeem the collateral and require that the redemption was successful
        assert CTOKEN(collateralContext.cToken).redeemUnderlying(_amount) == 0

        # recalculate collateral locked by subtracting the withdraw amount from collateralLocked
        collateralLocked: uint256 = loan.collateralLocked - _amount

        # check if the collateral asset is ETH
        if keccak256(_collateral_ticker) == keccak256("ETH"):

            # send the redeemed ETH back to the borrower
            send(loan.borrower, _amount)

        else:

            # transfer the redeemed collateral asset back to the borrower
            transferResponse: Bytes[32] = raw_call(
                collateralContext.underlying,
                concat(
                    method_id("transfer(address,uint256)"),
                    convert(loan.borrower, bytes32),
                    convert(_amount, bytes32),
                ),
                max_outsize=32,
            )
            if len(transferResponse) > 0:
                assert convert(transferResponse, bool)

        # pass borrowIndex of 0 so this member of the struct is not updated
        borrowIndex: uint256 = 0

        # update the loan with outstanding balance and collateral needed
        STORE(_store).updateLoan(collateralLocked, borrowIndex, _loan_key, withdrawCalculations.outstanding, _version)

        # emit a WithdrawCollateral event
        log WithdrawCollateral(_loan_key, _amount, collateralContext.underlying, collateralLocked, block.number)
        
    # revert, unhandled loan.protocol
    else:
        raise "malformed protocol string"

@external
@payable
def liquidate(_borrow_ticker: String[10], _collateral_ticker: String[10], _borrow_index: uint256, _key_count: uint256, _loan_keys: bytes32[100], _liquidator: address, _redeem_amount: uint256, _repay_amount: uint256, _store: address, _version: String[11]):
    """
    @notice Liquidate undercollateralized loans
    @param _borrow_ticker The ticker string of the asset that was borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _borrow_index The latest borrow index from the underlying lending protocol
    @param _key_count The number of keys in the _loan_keys array
    @param _liquidator The address of the liquidator
    @param _redeem_amount The amount of collateral asset to redeem
    @param _repay_amount The amount of borrowed asset to repay
    @param _store The address of the Greenwood Store to use
    @param _version The version of Greenwood to use
    @dev Only the Controller or the Governance can call this method
    """

    # require that the method is being called by the Liquidator or the Governance
    assert self.isAuthorized(msg.sender, "liquidator", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True

    # get the asset contexts for the borrow asset and the collateral asset from the Store
    borrowContext: AssetContext = STORE(_store).getAssetContext(_borrow_ticker)
    collateralContext: AssetContext = STORE(_store).getAssetContext(_collateral_ticker)

    # require that the liquidation redemption amount is greater than 0
    assert _redeem_amount > 0

    # require that the liquidation repayment amount is greater than 0
    assert _repay_amount > 0

    # check if the borrow asset is ETH
    if keccak256(_borrow_ticker) == keccak256("ETH"):

        # call repayBorrow() on the cEther contract and send msg.value in wei
        raw_call(
            borrowContext.cToken,
            method_id("repayBorrow()"),
            value=msg.value
        )

    else:

        # move repayment asset (borrow asset) from borrower to Escrow
        transferFromResponse: Bytes[32] = raw_call(
            borrowContext.underlying,
            concat(
                method_id("transferFrom(address,address,uint256)"),
                convert(_liquidator, bytes32),
                convert(self, bytes32),
                convert(_repay_amount, bytes32),
            ),
            max_outsize=32,
        ) 
        if len(transferFromResponse) > 0:
            assert convert(transferFromResponse, bool)

        # approve the cToken of the borrow asset to access the token balance of Escrow
        approveResponse: Bytes[32] = raw_call(
            borrowContext.underlying,
            concat(
                method_id("approve(address,uint256)"),
                convert(borrowContext.cToken, bytes32),
                convert(_repay_amount, bytes32),
            ),
            max_outsize=32,
        )
        if len(approveResponse) > 0:
            assert convert(approveResponse, bool)

        # require that the repay was successful
        assert CTOKEN(borrowContext.cToken).repayBorrow(_repay_amount) == 0

    # require that the redemption was successful
    assert CTOKEN(collateralContext.cToken).redeemUnderlying(_redeem_amount) == 0

    # declare memory variable to store the number of loan keys that have been processed
    loanKeyCounter: uint256 = 0

    # update the outstanding balance and collateral needed for the loan
    for i in range(LOOP_LIMIT):

        # check if all loans have been liquidated
        if loanKeyCounter < _key_count:
            STORE(_store).updateLoan(0, _borrow_index, _loan_keys[i], 0, _version)

            # increment the loan key counter
            loanKeyCounter += 1
        
        # all loan keys have been liquidated
        elif loanKeyCounter == _key_count:

            # halt loop execution
            break

        else:

            # halt loop execution as a fallback case
            break

    # check if the collateral asset is ETH
    if keccak256(_collateral_ticker) == keccak256("ETH"):

        # send the redeemed ETH to the liquidator
        send(_liquidator, _redeem_amount)

    else:
    
        # transfer the redeemed collateral asset back to the borrower
        transferResponse: Bytes[32] = raw_call(
            collateralContext.underlying,
            concat(
                method_id("transfer(address,uint256)"),
                convert(_liquidator, bytes32),
                convert(_redeem_amount, bytes32),
            ),
            max_outsize=32,
        )
        if len(transferResponse) > 0:
            assert convert(transferResponse, bool)

    # emit a Liquidation event
    log Liquidation(borrowContext.underlying, collateralContext.underlying, _liquidator, _loan_keys, _redeem_amount, _repay_amount, block.number)

@external
def claimComp(_comp: address, _comptroller: address, _version: String[11]):
    """
    @notice Claims COMP rewards
    @param _comp The address of COMP
    @param _comptroller The address of the Compound Comptroller
    @param _treasury The address of the Greenwood Treasury
    @dev Only the Governance can call this method
    """

    # require that the method caller is the Governance
    assert self.isAuthorized(msg.sender, "governance", "") == True

    # call claimComp on the Compound Comptroller
    raw_call(
        _comptroller,
        concat(
            method_id("claimComp(address)"),
            convert(self, bytes32)
        )
    )

    # get the COMP balance of the Escrow
    compBalance: uint256 = ERC20(_comp).balanceOf(self)


    # get the address of the Treasury from the Registry
    treasury: address = REGISTRY(self.registry).getAddress("treasury", _version)


    # transfer the claimed COMP to the Treasury
    transferResponse: Bytes[32] = raw_call(
        _comp,
        concat(
            method_id("transfer(address,uint256)"),
            convert(treasury, bytes32),
            convert(compBalance, bytes32),
        ),
        max_outsize=32,
    )
    if len(transferResponse) > 0:
        assert convert(transferResponse, bool)

@external
def setRegistry(_new_registry: address):
    """
    @notice Updates the address of the Registry
    @param _new_registry The address of the new Greenwood Registry
    @dev Only the Governance can call this method
    @dev Only call this method with a valid Greenwood Registry or subsequent calls will fail!
    """

    # require that the method caller is the Governance
    assert self.isAuthorized(msg.sender, "governance", "") == True

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