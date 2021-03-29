"""
@title Greenwood AaveV2Escrow
@notice Aave V2 integrations for the Greenwood Protocol
@author Greenwood Labs
"""

# define the interfaces used by the contract
interface AAVE_V2_CALCULATOR:
    def calculateBorrow(_borrow_context: AssetContext, _collateral_context: AssetContext, _amount: uint256, _collateralization_ratio: uint256, _version: String[11]) -> AaveV2BorrowCalculation: nonpayable
    def calculateWithdraw(_borrow_context: AssetContext, _collateral_context: AssetContext, _escrow: address, _loan: Loan, _version: String[11]) -> AaveV2WithdrawCalculation: nonpayable
    def calculateRepay(_borrow_context: AssetContext, _collateral_context: AssetContext, _amount: uint256, _escrow: address, _loan: Loan, _version: String[11])-> AaveV2RepayCalculation: nonpayable

interface REGISTRY:
    def getAddress(_contract: String[20], _version: String[11]) -> address: nonpayable
    def governance() -> address: nonpayable

interface STORE:
    def getAssetContext(_ticker: String[10]) -> AssetContext: view
    def recordLoan(_borrower: address, _borrow_asset: address, _collateral_asset: address, _collateralization_ratio: uint256, _collateral_locked: uint256, _index: uint256, _principal: uint256, _protocol: String[10], _version: String[11]): nonpayable
    def updateLoan(_collateral_locked: uint256, _index: uint256, _loan_key: bytes32, _outstanding: uint256, _version: String[11]): nonpayable
    def getLoan(_loan_key: bytes32) -> Loan: view
    def getLoanProtocol(_loan_key: bytes32) -> String[10]: view

# define the constants used by the contract
LOOP_LIMIT: constant(uint256) = 100

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

        # return the equality comparison boolean
        return escrow == _caller
    
    # check if the requested role is "governance"
    elif keccak256(_role) == keccak256("governance"):

        # get the address of the Governance from the Registry
        governance: address = REGISTRY(self.registry).governance()

        # return the equality comparison boolean
        return governance == _caller

    # check if the requested role is "liquidator"
    elif keccak256(_role) == keccak256("liquidator"):

        # get the address of the Liquidator from the Registry
        liquidator: address = REGISTRY(self.registry).getAddress("liquidator", _version)

        # return the equality comparison boolean
        return liquidator == _caller

    # catch extraneous role arguments
    else:

        # revert
        raise "Unhandled role argument"

@external
def borrow(_borrow_ticker: String[10], _collateral_ticker: String[10], _borrow_context: AssetContext, _collateral_context: AssetContext, _amount: uint256, _borrower: address, _calculator: address, _collateralization_ratio: uint256, _store: address, _version: String[11]):
    """
    @notice Borrow assets from Aave V2
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
    assert self.isAuthorized(msg.sender, "controller", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True, "Only Controller or Governance can call this method"

    # require that the borrow amount is greater than 0 after scaling it down
    assert convert(_amount, decimal) / convert(10 ** _borrow_context.decimals, decimal) > 0.0, "Borrow amount must be greater than 0"

    # get requiredCollateral, borrowIndex, borrowAmount, and protocolFee from the Calculator
    borrowCalculations: AaveV2BorrowCalculation = AAVE_V2_CALCULATOR(_calculator).calculateBorrow(_borrow_context, _collateral_context, _amount, _collateralization_ratio, _version)

    # check if the origination fee is greater than 0
    if borrowCalculations.originationFee > 0:

        # get the address of the Treasury from the Registry
        treasury: address = REGISTRY(self.registry).getAddress("treasury", _version)

        # require that a Treasury address was returned from the Store
        assert treasury != ZERO_ADDRESS, "No Treasury address returned from the Store"

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
            assert convert(transferResponse, bool), "Failed safeTransfer"

    # move collateral from the borrower to the Escrow using safeTransferFrom 
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
        assert convert(transferFromResponse, bool), "Failed safeTransferFrom"

    # approve the collateral transfer from Escrow to the Aave V2 LendingPool
    approveResponse: Bytes[32] = raw_call(
        _collateral_context.underlying,
        concat(
            method_id("approve(address,uint256)"),
            convert(_collateral_context.aaveV2LendingPool, bytes32),
            convert(borrowCalculations.requiredCollateral, bytes32),
        ),
        max_outsize=32,
    )
    if len(approveResponse) > 0:
        assert convert(approveResponse, bool), "Failed approve"

    # supply the collateral to Aave V2
    raw_call(
        _collateral_context.aaveV2LendingPool,
        concat(
            method_id("deposit(address,uint256,address,uint16)"),
            convert(_collateral_context.underlying, bytes32),
            convert(borrowCalculations.requiredCollateral, bytes32),
            convert(self, bytes32),
            convert(0, bytes32) 
        )
    )

    # execute the borrow on Aave V2
    raw_call(
        _borrow_context.aaveV2LendingPool,
        concat(
            method_id("borrow(address,uint256,uint256,uint16,address)"),
            convert(_borrow_context.underlying, bytes32),
            convert(_amount, bytes32),
            convert(2, bytes32),
            convert(0, bytes32),
            convert(self, bytes32),
        )
    )

    # transfer the borrowed asset to the borrower using safeTransfer
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
        assert convert(transferResponse, bool), "Failed safeTransfer"

    # call recordLoan() on the Store to store the loan data
    STORE(_store).recordLoan(_borrower, _borrow_context.underlying, _collateral_context.underlying, _collateralization_ratio, borrowCalculations.requiredCollateral, borrowCalculations.borrowIndex, _amount, "aavev2", _version)

    # emit a Borrow event
    log Borrow(_borrower, _amount, _borrow_context.underlying, _collateral_context.underlying, block.number)
    
@external
def repay(_borrow_ticker: String[10], _collateral_ticker: String[10], _amount: uint256, _calculator: address, _loan_key: bytes32, _store: address, _version: String[11]):
    """
    @notice Repay an Aave V2 loan
    @param _borrow_ticker The ticker string of the asset that was borrowed
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _amount The amount of the repayment scaled by the asset's decimals
    @param _calculator The address of the Greenwood Calculator to use
    @param _loan_key The uinque identifier for the loan
    @param _store The address of the Greenwood Store to use
    @param _version The version of Greenwood to use
    @dev Only the Controller or the Governance can call this method
    """

    # require that the method is being called by the Controller or the Governance
    assert self.isAuthorized(msg.sender, "controller", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True, "Only Controller or Governance can call this method"

    # get the loan protocol from the Store
    loanProtocol: String[10] = STORE(_store).getLoanProtocol(_loan_key)

    # get the rest of the loan data from the Store
    loan: Loan = STORE(_store).getLoan(_loan_key)

    # require that the outstanding balance of the loan is greater than 0
    assert loan.outstanding > 0, "Outstanding balance must be greater than 0"

    # get the asset contexts for the borrow asset and the collateral asset from the Store
    borrowContext: AssetContext = STORE(_store).getAssetContext(_borrow_ticker)
    collateralContext: AssetContext = STORE(_store).getAssetContext(_collateral_ticker)
    
    # require the the loan assets match the underlying assets of the contexts
    assert borrowContext.underlying == loan.borrowAsset, "Borrow context mismatch"
    assert collateralContext.underlying == loan.collateralAsset, "Collateral context mismatch"

    # check if this is a full repayment
    if _amount != MAX_UINT256:

        # require that the repay amount is greater than 0 after scaling it down
        assert convert(_amount, decimal) / convert(10 ** borrowContext.decimals, decimal) > 0.0, "Repayment amount must be greater than 0"
    
    # check that this loan was originated with Aave V2
    if keccak256(loanProtocol) == keccak256("aavev2"):

        # get the redemption amount from the Calculator
        repayCalculations: AaveV2RepayCalculation = AAVE_V2_CALCULATOR(_calculator).calculateRepay(borrowContext, collateralContext, _amount, self, loan, _version)

        # move the repayment asset (borrow asset) from the borrower to the Escrow
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
            assert convert(transferFromResponse, bool), "Failed safeTransferFrom"
        
        # approve the Aave V2 LendingPool to access the token balance of the Escrow
        approveResponse: Bytes[32] = raw_call(
            borrowContext.underlying,
            concat(
                method_id("approve(address,uint256)"),
                convert(borrowContext.aaveV2LendingPool, bytes32),
                convert(repayCalculations.repayAmount, bytes32),
            ),
            max_outsize=32,
        )
        if len(approveResponse) > 0:
            assert convert(approveResponse, bool), "Failed approve"    

        # call repay() on the Aave V2 LendingPool
        raw_call(
            borrowContext.aaveV2LendingPool,
            concat(
                method_id("repay(address,uint256,uint256,address)"),
                convert(borrowContext.underlying, bytes32),
                convert(repayCalculations.repayAmount, bytes32),
                convert(2, bytes32),
                convert(self, bytes32)
            ),
        )

        # check if the redemption amount is less than 0
        if repayCalculations.redemptionAmount < 0:

            # emit a Liquidate event because the loan is undercollateralized
            log Liquidate(_loan_key, loan.outstanding, borrowContext.underlying, collateralContext.underlying, block.number)

        # check if the redemption amount is greater than 0
        elif repayCalculations.redemptionAmount > 0:

            # allow the Aave V2 LendingPool to burn the aTokens
            approveBurnResponse: Bytes[32] = raw_call(
                collateralContext.aToken,
                concat(
                    method_id("approve(address,uint256)"),
                    convert(collateralContext.aaveV2LendingPool, bytes32),
                    convert(convert(repayCalculations.redemptionAmount, uint256), bytes32),
                ),
                max_outsize=32,
            )
            if len(approveBurnResponse) > 0:
                assert convert(approveBurnResponse, bool), "Failed approve"

            # call withdraw() on the Aave V2 LendingPool
            raw_call(
                collateralContext.aaveV2LendingPool,
                concat(
                    method_id("withdraw(address,uint256,address)"),
                    convert(collateralContext.underlying, bytes32),
                    convert(convert(repayCalculations.redemptionAmount, uint256), bytes32),
                    convert(self, bytes32)
                ),
            )
            
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
                assert convert(transferResponse, bool), "Failed safeTransfer"

            # update the loan with collateral needed, checkpoint borrow index, and outstanding balance
            STORE(_store).updateLoan(repayCalculations.requiredCollateral, repayCalculations.borrowIndex, _loan_key, convert(repayCalculations.outstanding, uint256), _version)

            # emit a Repay event
            log Repay(loan.borrower, repayCalculations.repayAmount, borrowContext.underlying, convert(repayCalculations.redemptionAmount, uint256), collateralContext.underlying, block.number)
                
        # check if the redemption amount is equal to 0
        elif repayCalculations.redemptionAmount == 0:

            # emit a Repay event
            log Repay(loan.borrower, repayCalculations.repayAmount, borrowContext.underlying, convert(repayCalculations.redemptionAmount, uint256), collateralContext.underlying, block.number)
    
    # catch extraneous lending protocols
    else:
        raise "Unhandled protocol"


@external
def addCollateral(_collateral_ticker: String[10], _amount: uint256, _depositor: address, _loan_key: bytes32, _store: address, _version: String[11]):
    """
    @notice Add collateral to Aave V2
    @param _collateral_ticker The ticker string of the asset that is being used as collateral
    @param _amount The amount of the deposit scaled by the asset's decimals
    @param _depositor The address of the depositor
    @param _loan_key The uinque identifier for the loan
    @param _store The address of the Greenwood Store contract to use
    @param _version The version of Greenwood to use
    @dev Only the Controller or the Governance can call this method
    """

    # require that the method is being called by the Controller or the Governance
    assert self.isAuthorized(msg.sender, "controller", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True, "Only Controller or Governance can call this method"

    # get the loan's protocol from the Store
    protocol: String[10] = STORE(_store).getLoanProtocol(_loan_key)

    # require that a protocol was returned from the Store
    assert keccak256(protocol) != keccak256(""), "No loan protocol returned from the Store"

    # get the loan data from the Store
    loan: Loan = STORE(_store).getLoan(_loan_key)

    # get the context of the collateral asset from the Store
    collateralContext: AssetContext = STORE(_store).getAssetContext(_collateral_ticker)

    # require that the loan's collateral asset and underlying asset of the collateral context match
    assert loan.collateralAsset == collateralContext.underlying, "Collateral context mismatch"

    # require that the deposit amount is greater than 0 after scaling it down
    assert convert(_amount, decimal) / convert(10 ** collateralContext.decimals, decimal) > 0.0, "Deposit amount must be greater than 0"

    # check if this loan was originated with Aave V2
    if keccak256(protocol) == keccak256("aavev2"):

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
            assert convert(transferFromResponse, bool), "Failed safeTransferFrom"

        # approve the collateral transfer from Escrow to Aave V2
        approveResponse: Bytes[32] = raw_call(
            collateralContext.underlying,
            concat(
                method_id("approve(address,uint256)"),
                convert(collateralContext.aaveV2LendingPool, bytes32),
                convert(_amount, bytes32),
            ),
            max_outsize=32,
        )
        if len(approveResponse) > 0:
            assert convert(approveResponse, bool), "Failed approve"

        # supply the collateral to Aave V2
        raw_call(
            collateralContext.aaveV2LendingPool,
            concat(
                method_id("deposit(address,uint256,address,uint16)"),
                convert(collateralContext.underlying, bytes32),
                convert(_amount, bytes32),
                convert(self, bytes32),
                convert(0, bytes32) 
            )
        )
        
        # add the amount of collateral to the existing amount of collateralLocked
        collateralLocked: uint256 = loan.collateralLocked + _amount

        # pass borrowIndex of 0 so this member of the  Loan truct is not updated
        borrowIndex: uint256 = 0

        # update the loan with the new value of collateral locked
        STORE(_store).updateLoan(collateralLocked, borrowIndex, _loan_key, loan.outstanding, _version)

        # emit an AddCollateral event
        log AddCollateral(_loan_key, _depositor, _amount, collateralContext.underlying, block.number)
        
    else:
        raise "malformed protocol string"

@external
def withdrawCollateral(_borrow_ticker: String[10], _collateral_ticker: String[10], _amount: uint256, _calculator: address, _loan_key: bytes32,  _store: address, _version: String[11]):
    """
    @notice Withdraw collateral from Aave V2
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
    assert self.isAuthorized(msg.sender, "controller", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True, "Only Controller or Governance can call this method"

    # get the loan's protocol from the Store 
    protocol: String[10] = STORE(_store).getLoanProtocol(_loan_key)

    # require that a protocol was returned from the Store
    assert keccak256(protocol) != keccak256(""), "No loan protocol returned from the Store"

    # get the loan data from the Store 
    loan: Loan = STORE(_store).getLoan(_loan_key)

    # get the asset contexts for the borrow asset and the collateral asset from the Store
    collateralContext: AssetContext = STORE(_store).getAssetContext(_collateral_ticker)
    borrowContext: AssetContext = STORE(_store).getAssetContext(_borrow_ticker)

    # require the the loan assets match the underlying assets of the contexts
    assert loan.borrowAsset == borrowContext.underlying, "Borrow context mismatch"
    assert loan.collateralAsset == collateralContext.underlying, "Collateral context mismatch"

    # require that the withdraw amount is greater than 0 after scaling it down
    assert convert(_amount, decimal) / convert(10 ** collateralContext.decimals, decimal) > 0.0, "Withdraw amount must be greater than 0"

    # check if this loan was originated with Aave V2
    if keccak256(protocol) == keccak256("aavev2"):

        # get the withdraw calculations from the Calculator
        withdrawCalculations: AaveV2WithdrawCalculation = AAVE_V2_CALCULATOR(_calculator).calculateWithdraw(borrowContext, collateralContext, self, loan, _version)

        # require that this withdraw does not violate collateral requirements
        assert loan.collateralLocked - _amount >= withdrawCalculations.requiredCollateral, "Withdraw amount violates collateral requirements"

        # allow the Aave V2 LendingPool to burn the aTokens
        approveBurnResponse: Bytes[32] = raw_call(
            collateralContext.aToken,
            concat(
                method_id("approve(address,uint256)"),
                convert(collateralContext.aaveV2LendingPool, bytes32),
                convert(_amount, bytes32),
            ),
            max_outsize=32,
        )
        if len(approveBurnResponse) > 0:
            assert convert(approveBurnResponse, bool), "Failed approve"

        # call withdraw() on the Aave V2 LendingPool
        raw_call(
            collateralContext.aaveV2LendingPool,
            concat(
                method_id("withdraw(address,uint256,address)"),
                convert(collateralContext.underlying, bytes32),
                convert(_amount, bytes32),
                convert(self, bytes32)
            ),
        )

        # recalculate collateral locked by subtracting the withdraw amount from collateralLocked
        collateralLocked: uint256 = loan.collateralLocked - _amount

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
            assert convert(transferResponse, bool), "Failed safeTransfer"

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
    assert self.isAuthorized(msg.sender, "liquidator", _version) == True or self.isAuthorized(msg.sender, "governance", _version) == True, "Only Liquidator or Governance can call this method"

    # get the asset contexts for the borrow asset and the collateral asset from the Store
    borrowContext: AssetContext = STORE(_store).getAssetContext(_borrow_ticker)
    collateralContext: AssetContext = STORE(_store).getAssetContext(_collateral_ticker)

    # require that the liquidation redemption amount is greater than 0
    assert _redeem_amount > 0, "Liquidation redeem amount must be greater than 0"

    # require that the liquidation repayment amount is greater than 0
    assert _repay_amount > 0, "Liquidation repay amount must be greater than 0"

    # move repayment asset (borrow asset) from Liquidator to Escrow
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
        assert convert(transferFromResponse, bool), "Failed safeTransferFrom"

    # approve the Aave V2 LendingPool to access the token balance of Escrow
    approveResponse: Bytes[32] = raw_call(
        borrowContext.underlying,
        concat(
            method_id("approve(address,uint256)"),
            convert(borrowContext.aaveV2LendingPool, bytes32),
            convert(_repay_amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(approveResponse) > 0:
        assert convert(approveResponse, bool), "Failed approve"

    # call repay() on the Aave V2 LendingPool
    raw_call(
        borrowContext.aaveV2LendingPool,
        concat(
            method_id("repay(address,uint256,uint256,address)"),
            convert(borrowContext.underlying, bytes32),
            convert(_repay_amount, bytes32),
            convert(2, bytes32),
            convert(self, bytes32)
        ),
    )

    # allow the Aave V2 LendingPool to burn the aTokens
    approveBurnResponse: Bytes[32] = raw_call(
        collateralContext.aToken,
        concat(
            method_id("approve(address,uint256)"),
            convert(collateralContext.aaveV2LendingPool, bytes32),
            convert(_redeem_amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(approveBurnResponse) > 0:
        assert convert(approveBurnResponse, bool), "Failed approve"

    # call withdraw() on the Aave V2 LendingPool
    raw_call(
        collateralContext.aaveV2LendingPool,
        concat(
            method_id("withdraw(address,uint256,address)"),
            convert(collateralContext.underlying, bytes32),
            convert(_redeem_amount, bytes32),
            convert(self, bytes32)
        ),
    )

    # transfer the redeemed collateral asset to the liquidator
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
        assert convert(transferResponse, bool), "Failed safeTransfer"

    # declare memory variable to store the number of loan keys that have been processed
    loanKeyCounter: uint256 = 0

    # update the outstanding balance and collateral needed for the loans
    for i in range(LOOP_LIMIT):
        if loanKeyCounter < _key_count:
            STORE(_store).updateLoan(0, _borrow_index, _loan_keys[i], 0, _version)

            # increment the loan key counter
            loanKeyCounter += 1
        
        # all loan keys have been processed
        elif loanKeyCounter == _key_count:

            # halt loop execution
            break

        else:

            # halt loop execution as a fallback case
            break

    # emit a Liquidation event
    log Liquidation(borrowContext.underlying, collateralContext.underlying, _liquidator, _loan_keys, _redeem_amount, _repay_amount, block.number)

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