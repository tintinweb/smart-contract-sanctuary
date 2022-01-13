// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.7;

interface IAuctioneerLike {

    function getExpectedAmount(uint256 swapAmount_) external view returns (uint256 expectedAmount_);

}

interface IERC20Like {

    function approve(address spender_, uint256 amount_) external returns (bool success_);

    function balanceOf(address account_) external view returns (uint256 balanceOf_);

    function decimals() external view returns (uint8 decimals_);

    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

}

interface IMapleGlobalsLike {

   function getLatestPrice(address asset_) external view returns (uint256 price_);

   function protocolPaused() external view returns (bool protocolPaused_);

}

interface IMapleLoanLike {

    function acceptNewTerms(address refinancer_, bytes[] calldata calls_, uint256 amount_) external;

    function claimableFunds() external view returns (uint256 claimableFunds_);

    function collateralAsset() external view returns (address collateralAsset_);

    function fundsAsset() external view returns (address fundsAsset_);

    function principal() external view returns (uint256 principal_);

    function claimFunds(uint256 amount_, address destination_) external;

    function repossess(address destination_) external returns (uint256 collateralAssetAmount_, uint256 fundsAssetAmount_);

}

interface IMapleProxyFactoryLike {

    function upgradeInstance(uint256 toVersion_, bytes calldata arguments_) external;

}

interface IPoolFactoryLike {

    function globals() external pure returns (address globals_);

}

interface IPoolLike {

    function poolDelegate() external view returns (address poolDelegate_);

    function superFactory() external view returns (address superFactory_);

}

/// @title Small Library to standardize erc20 token interactions.
library ERC20Helper {

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function transfer(address token_, address to_, uint256 amount_) internal returns (bool success_) {
        return _call(token_, abi.encodeWithSelector(IERC20Like.transfer.selector, to_, amount_));
    }

    function transferFrom(address token_, address from_, address to_, uint256 amount_) internal returns (bool success_) {
        return _call(token_, abi.encodeWithSelector(IERC20Like.transferFrom.selector, from_, to_, amount_));
    }

    function approve(address token_, address spender_, uint256 amount_) internal returns (bool success_) {
        // If setting approval to zero fails, return false.
        if (!_call(token_, abi.encodeWithSelector(IERC20Like.approve.selector, spender_, uint256(0)))) return false;

        // If `amount_` is zero, return true as the previous step already did this.
        if (amount_ == uint256(0)) return true;

        // Return the result of setting the approval to `amount_`.
        return _call(token_, abi.encodeWithSelector(IERC20Like.approve.selector, spender_, amount_));
    }

    function _call(address token_, bytes memory data_) private returns (bool success_) {
        if (token_.code.length == uint256(0)) return false;

        bytes memory returnData;
        ( success_, returnData ) = token_.call(data_);

        return success_ && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
    }

}

interface ILiquidator {

    /**
     * @dev   Auctioneer was set.
     * @param auctioneer_ Address of the auctioneer.
     */
    event AuctioneerSet(address auctioneer_);

    /**
     * @dev   Funds were withdrawn from the liquidator.
     * @param token_       Address of the token that was withdrawn.
     * @param destination_ Address of where tokens were sent.
     * @param amount_      Amount of tokens that were sent.
     */
    event FundsPulled(address token_, address destination_, uint256 amount_);

    /**
     * @dev   Portion of collateral was liquidated.
     * @param swapAmount_     Amount of collateralAsset that was liquidated.
     * @param returnedAmount_ Amount of fundsAsset that was returned.
     */
    event PortionLiquidated(uint256 swapAmount_, uint256 returnedAmount_);

    /**
     * @dev Getter function that returns `collateralAsset`.
     */
    function collateralAsset() external view returns (address collateralAsset_);

    /**
     * @dev Getter function that returns `destination` - address that liquidated funds are sent to.
     */
    function destination() external view returns (address destination_);

    /**
     * @dev Getter function that returns `auctioneer`.
     */
    function auctioneer() external view returns (address auctioneer_);

    /**
     * @dev Getter function that returns `fundsAsset`.
     */
    function fundsAsset() external view returns (address fundsAsset_);

    /**
     * @dev Getter function that returns `globals`.
     */
    function globals() external view returns (address);

    /**
     * @dev Getter function that returns `owner`.
     */
    function owner() external view returns (address owner_);

    /**
     * @dev   Set the auctioneer contract address, which is used to pull the `getExpectedAmount`.
     *        Can only be set by `owner`.
     * @param auctioneer_ The auctioneer contract address.
     */
    function setAuctioneer(address auctioneer_) external;

    /**
     * @dev   Pulls a specified amount of ERC-20 tokens from the contract.
     *        Can only be called by `owner`.
     * @param token_       The ERC-20 token contract address.
     * @param destination_ The destination of the transfer.
     * @param amount_      The amount to transfer.
     */
    function pullFunds(address token_, address destination_, uint256 amount_) external;

    /**
     * @dev    Returns the expected amount to be returned from a flash loan given a certain amount of `collateralAsset`.
     * @param  swapAmount_     Amount of `collateralAsset` to be flash-borrowed.
     * @return expectedAmount_ Amount of `fundsAsset` that must be returned in the same transaction.
     */
    function getExpectedAmount(uint256 swapAmount_) external returns (uint256 expectedAmount_);

    /**
     * @dev   Flash loan function that:
     *        1. Transfers a specified amount of `collateralAsset` to `msg.sender`.
     *        2. Performs an arbitrary call to `msg.sender`, to trigger logic necessary to get `fundsAsset` (e.g., AMM swap).
     *        3. Performs a `transferFrom`, taking the corresponding amount of `fundsAsset` from the user.
     *        If the required amount of `fundsAsset` is not returned in step 3, the entire transaction reverts.
     * @param swapAmount_      Amount of `collateralAsset` that is to be borrowed in the flash loan.
     * @param maxReturnAmount_ Max amount of `fundsAsset` that can be returned to the liquidator contract.
     * @param data_            ABI-encoded arguments to be used in the low-level call to perform step 2.
     */
    function liquidatePortion(uint256 swapAmount_, uint256 maxReturnAmount_, bytes calldata data_) external;

}

contract Liquidator is ILiquidator {

    uint256 private constant NOT_LOCKED = uint256(0);
    uint256 private constant LOCKED     = uint256(1);

    uint256 internal _locked;

    address public override immutable collateralAsset;
    address public override immutable destination;
    address public override immutable fundsAsset;
    address public override immutable globals;
    address public override immutable owner;

    address public override auctioneer;

    /*****************/
    /*** Modifiers ***/
    /*****************/

    modifier whenProtocolNotPaused() {
        require(!IMapleGlobalsLike(globals).protocolPaused(), "LIQ:PROTOCOL_PAUSED");
        _;
    }

    modifier lock() {
        require(_locked == NOT_LOCKED, "LIQ:LOCKED");
        _locked = LOCKED;
        _;
        _locked = NOT_LOCKED;
    }

    /**
     * @param owner_           The address of an account that will have administrative privileges on this contract.
     * @param collateralAsset_ The address of the collateral asset being liquidated.
     * @param fundsAsset_      The address of the funds asset.
     * @param auctioneer_      The address of an Auctioneer.
     * @param destination_     The address to send funds asset after liquidation.
     * @param globals_         The address of a Maple Globals contract.
     */
    constructor(address owner_, address collateralAsset_, address fundsAsset_, address auctioneer_, address destination_, address globals_) {
        require((owner           = owner_)           != address(0), "LIQ:C:INVALID_OWNER");
        require((collateralAsset = collateralAsset_) != address(0), "LIQ:C:INVALID_COL_ASSET");
        require((fundsAsset      = fundsAsset_)      != address(0), "LIQ:C:INVALID_FUNDS_ASSET");
        require((destination     = destination_)     != address(0), "LIQ:C:INVALID_DEST");

        require(!IMapleGlobalsLike(globals = globals_).protocolPaused(), "LIQ:C:INVALID_GLOBALS");

        // NOTE: Auctioneer of zero is valid, since it is starting the contract off in a paused state.
        auctioneer = auctioneer_;
    }

    function setAuctioneer(address auctioneer_) external override {
        require(msg.sender == owner, "LIQ:SA:NOT_OWNER");

        emit AuctioneerSet(auctioneer = auctioneer_);
    }

    function pullFunds(address token_, address destination_, uint256 amount_) external override {
        require(msg.sender == owner, "LIQ:PF:NOT_OWNER");

        emit FundsPulled(token_, destination_, amount_);

        require(ERC20Helper.transfer(token_, destination_, amount_), "LIQ:PF:TRANSFER");
    }

    function getExpectedAmount(uint256 swapAmount_) public view override returns (uint256 expectedAmount_) {
        return IAuctioneerLike(auctioneer).getExpectedAmount(swapAmount_);
    }

    function liquidatePortion(uint256 collateralAmount_, uint256 maxReturnAmount_, bytes calldata data_) external override whenProtocolNotPaused lock {
        // Transfer a requested amount of collateralAsset to the borrwer.
        require(ERC20Helper.transfer(collateralAsset, msg.sender, collateralAmount_), "LIQ:LP:TRANSFER");

        // Perform a low-level call to msg.sender, allowing a swap strategy to be executed with the transferred collateral.
        msg.sender.call(data_);

        // Calculate the amount of fundsAsset required based on the amount of collateralAsset borrowed.
        uint256 returnAmount = getExpectedAmount(collateralAmount_);
        require(returnAmount <= maxReturnAmount_, "LIQ:LP:MAX_RETURN_EXCEEDED");

        emit PortionLiquidated(collateralAmount_, returnAmount);

        // Pull required amount of fundsAsset from the borrower, if this amount of funds cannot be recovered atomically, revert.
        require(ERC20Helper.transferFrom(fundsAsset, msg.sender, destination, returnAmount), "LIQ:LP:TRANSFER_FROM");
    }

}

/// @title An implementation that is to be proxied, must implement IProxied.
interface IProxied {

    /**
     *  @dev The address of the proxy factory.
     */
    function factory() external view returns (address factory_);

    /**
     *  @dev The address of the implementation contract being proxied.
     */
    function implementation() external view returns (address implementation_);

    /**
     *  @dev   Modifies the proxy's implementation address.
     *  @param newImplementation_ The address of an implementation contract.
     */
    function setImplementation(address newImplementation_) external;

    /**
     *  @dev   Modifies the proxy's storage by delegate-calling a migrator contract with some arguments.
     *         Access control logic critical since caller can force a selfdestruct via a malicious `migrator_` which is delegatecalled.
     *  @param migrator_  The address of a migrator contract.
     *  @param arguments_ Some encoded arguments to use for the migration.
     */
    function migrate(address migrator_, bytes calldata arguments_) external;

}

/// @title A Maple implementation that is to be proxied, must implement IMapleProxied.
interface IMapleProxied is IProxied {

    /**
     *  @dev   The instance was upgraded.
     *  @param toVersion_ The new version of the loan.
     *  @param arguments_ The upgrade arguments, if any.
     */
    event Upgraded(uint256 toVersion_, bytes arguments_);

    /**
     *  @dev   Upgrades a contract implementation to a specific version.
     *         Access control logic critical since caller can force a selfdestruct via a malicious `migrator_` which is delegatecalled.
     *  @param toVersion_ The version to upgrade to.
     *  @param arguments_ Some encoded arguments to use for the upgrade.
     */
    function upgrade(uint256 toVersion_, bytes calldata arguments_) external;

}

/// @title DebtLocker interacts with Loans on behalf of PoolV1.
interface IDebtLocker is IMapleProxied {

    /**************/
    /*** Events ***/
    /**************/

    /**
     * @dev   Emitted when `setAllowedSlippage` is called.
     * @param newSlippage_ New value for `allowedSlippage`.
     */
    event AllowedSlippageSet(uint256 newSlippage_);

    /**
     * @dev   Emitted when `setAuctioneer` is called.
     * @param newAuctioneer_ New value for `auctioneer` in Liquidator.
     */
    event AuctioneerSet(address newAuctioneer_);

    /**
     * @dev   Emitted when `fundsToCapture` is set.
     * @param amount_ The amount of funds that will be captured next claim.
     */
    event FundsToCaptureSet(uint256 amount_);

    /**
     * @dev Emitted when `stopLiquidation` is called.
     */
    event LiquidationStopped();

    /**
     * @dev   Emitted when `setMinRatio` is called.
     * @param newMinRatio_ New value for `minRatio`.
     */
    event MinRatioSet(uint256 newMinRatio_);

    /*****************/
    /*** Functions ***/
    /*****************/

    /**
     * @dev   Accept the new loan terms and trigger a refinance.
     * @param refinancer_ The address of the refinancer contract.
     * @param calls_      The array of encoded data that are to be executed as delegatecalls by the refinancer.
     * @param amount_     The amount of `fundsAsset` that is to be sent to the Loan as part of the transaction.
     */
    function acceptNewTerms(address refinancer_, bytes[] calldata calls_, uint256 amount_) external;

    /**
     *  @dev    Claims funds to send to Pool. Handles funds from payments and liquidations.
     *          Only the Pool can call this function.
     *  @return details_
     *              [0] => Total Claimed.
     *              [1] => Interest Claimed.
     *              [2] => Principal Claimed.
     *              [3] => Pool Delegate Fees Claimed.
     *              [4] => Excess Returned Claimed.
     *              [5] => Amount Recovered (from Liquidation).
     *              [6] => Default Suffered.
     */
    function claim() external returns (uint256[7] memory details_);

    /**
     * @dev   Allows the poolDelegate to pull some funds from liquidator contract.
     * @param liquidator_  The liquidator to which pull funds from.
     * @param token_       The token address of the funds.
     * @param destination_ The destination address of captured funds.
     * @param amount_      The amount to pull.
     */
    function pullFundsFromLiquidator(address liquidator_, address token_, address destination_, uint256 amount_) external;

    /**
     * @dev Returns the address of the Pool Delegate that has control of the DebtLocker.
     */
    function poolDelegate() external view returns (address poolDelegate_);

    /**
     * @dev Repossesses funds and collateral from a loan and transfers them to the Liquidator.
     */
    function triggerDefault() external;

    /**
     * @dev   Sets the allowed slippage for auctioneer (used to determine expected amount to be returned in flash loan).
     * @param allowedSlippage_ Basis points representation of allowed percent slippage from market price.
     */
    function setAllowedSlippage(uint256 allowedSlippage_) external;

    /**
     * @dev   Sets the auctioneer contract for the liquidator.
     * @param auctioneer_ Address of auctioneer contract.
     */
    function setAuctioneer(address auctioneer_) external;

    /**
     * @dev   Sets the minimum "price" for auctioneer (used to determine expected amount to be returned in flash loan).
     * @param minRatio_ Price in fundsAsset precision (e.g., 10 * 10 ** 6 for $10 price for USDC).
     */
    function setMinRatio(uint256 minRatio_) external;

    /**
     * @dev    Returns the expected amount to be returned to the liquidator during a flash borrower liquidation.
     * @param  swapAmount_   Amount of collateralAsset being swapped.
     * @return returnAmount_ Amount of fundsAsset that must be returned in the same transaction.
     */
    function getExpectedAmount(uint256 swapAmount_) external view returns (uint256 returnAmount_);

    /**
     * @dev   Returns the expected amount to be returned to the liquidator during a flash borrower liquidation.
     * @param amount_ The amount of funds that should be captured next claim.
     */
    function setFundsToCapture(uint256 amount_) external;

    /**
     * @dev Called by the PoolDelegate in case of a DoS, where a user transfers small amounts of collateralAsset into the Liquidator
     *      to make `_isLiquidationActive` remain true.
     *      CALLING THIS MAY RESULT IN RECOGNIZED LOSSES IN POOL ACCOUNTING. CONSULT MAPLE TEAM FOR GUIDANCE.
     */
    function stopLiquidation() external;

    /*************/
    /*** State ***/
    /*************/

    /**
     * @dev The Loan contract this locker is holding tokens for.
     */
    function loan() external view returns (address loan_);

    /**
     * @dev The address of the liquidator.
     */
    function liquidator() external view returns (address liquidator_);

    /**
     * @dev The owner of this Locker (the Pool).
     */
    function pool() external view returns (address pool_);

    /**
     * @dev The maximum slippage allowed during liquidations.
     */
    function allowedSlippage() external view returns (uint256 allowedSlippage_);

    /**
     * @dev The amount in funds asset recovered during liquidations.
     */
    function amountRecovered() external view returns (uint256 amountRecovered_);

    /**
     * @dev The minimum exchange ration between funds asset and collateral asset.
     */
    function minRatio() external view returns (uint256 minRatio_);

    /**
     * @dev Returns the principal that was present at the time of last claim.
     */
    function principalRemainingAtLastClaim() external view returns (uint256 principalRemainingAtLastClaim_);

    /**
     * @dev Returns if the funds have been repossessed.
     */
    function repossessed() external view returns (bool repossessed_);

    /**
     * @dev Returns the amount of funds that will be captured next claim.
     */
    function fundsToCapture() external view returns (uint256 fundsToCapture_);

}

/// @title DebtLockerStorage maps the storage layout of a DebtLocker.
contract DebtLockerStorage {

    address internal _liquidator;
    address internal _loan;
    address internal _pool;

    bool internal _repossessed;

    uint256 internal _allowedSlippage;
    uint256 internal _amountRecovered;
    uint256 internal _fundsToCapture;
    uint256 internal _minRatio;
    uint256 internal _principalRemainingAtLastClaim;

}

abstract contract SlotManipulatable {

    function _getReferenceTypeSlot(bytes32 slot_, bytes32 key_) internal pure returns (bytes32 value_) {
        return keccak256(abi.encodePacked(key_, slot_));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

    function _setSlotValue(bytes32 slot_, bytes32 value_) internal {
        assembly {
            sstore(slot_, value_)
        }
    }

}

/// @title An implementation that is to be proxied, will need ProxiedInternals.
abstract contract ProxiedInternals is SlotManipulatable {

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.factory') - 1`.
    bytes32 private constant FACTORY_SLOT = bytes32(0x7a45a402e4cb6e08ebc196f20f66d5d30e67285a2a8aa80503fa409e727a4af1);

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.implementation') - 1`.
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    /// @dev Delegatecalls to a migrator contract to manipulate storage during an initialization or migration.
    function _migrate(address migrator_, bytes calldata arguments_) internal virtual returns (bool success_) {
        uint256 size;

        assembly {
            size := extcodesize(migrator_)
        }

        if (size == uint256(0)) return false;

        ( success_, ) = migrator_.delegatecall(arguments_);
    }

    /// @dev Sets the factory address in storage.
    function _setFactory(address factory_) internal virtual returns (bool success_) {
        _setSlotValue(FACTORY_SLOT, bytes32(uint256(uint160(factory_))));
        return true;
    }

    /// @dev Sets the implementation address in storage.
    function _setImplementation(address implementation_) internal virtual returns (bool success_) {
        _setSlotValue(IMPLEMENTATION_SLOT, bytes32(uint256(uint160(implementation_))));
        return true;
    }

    /// @dev Returns the factory address.
    function _factory() internal view virtual returns (address factory_) {
        return address(uint160(uint256(_getSlotValue(FACTORY_SLOT))));
    }

    /// @dev Returns the implementation address.
    function _implementation() internal view virtual returns (address implementation_) {
        return address(uint160(uint256(_getSlotValue(IMPLEMENTATION_SLOT))));
    }

}

/// @title A Maple implementation that is to be proxied, will need MapleProxiedInternals.
abstract contract MapleProxiedInternals is ProxiedInternals {}

/// @title DebtLocker interacts with Loans on behalf of PoolV1.
contract DebtLocker is IDebtLocker, DebtLockerStorage, MapleProxiedInternals {

    /*****************/
    /*** Modifiers ***/
    /*****************/

    modifier whenProtocolNotPaused() {
        require(!IMapleGlobalsLike(_getGlobals()).protocolPaused(), "DL:PROTOCOL_PAUSED");
        _;
    }

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    function migrate(address migrator_, bytes calldata arguments_) external override {
        require(msg.sender == _factory(),        "DL:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "DL:M:FAILED");
    }

    function setImplementation(address newImplementation_) external override {
        require(msg.sender == _factory(),               "DL:SI:NOT_FACTORY");
        require(_setImplementation(newImplementation_), "DL:SI:FAILED");
    }

    function upgrade(uint256 toVersion_, bytes calldata arguments_) external override {
        require(msg.sender == _getPoolDelegate(), "DL:U:NOT_POOL_DELEGATE");

        emit Upgraded(toVersion_, arguments_);

        IMapleProxyFactoryLike(_factory()).upgradeInstance(toVersion_, arguments_);
    }

    /*******************************/
    /*** Pool Delegate Functions ***/
    /*******************************/

    function acceptNewTerms(address refinancer_, bytes[] calldata calls_, uint256 amount_) external override whenProtocolNotPaused {
        require(msg.sender == _getPoolDelegate(), "DL:ANT:NOT_PD");

        address loanAddress = _loan;

        require(
            (IMapleLoanLike(loanAddress).claimableFunds() + _fundsToCapture == uint256(0)) &&
            (IMapleLoanLike(loanAddress).principal() == _principalRemainingAtLastClaim),
            "DL:ANT:NEED_TO_CLAIM"
        );

        require(
            amount_ == uint256(0) || ERC20Helper.transfer(IMapleLoanLike(loanAddress).fundsAsset(), loanAddress, amount_),
            "DL:ANT:TRANSFER_FAILED"
        );

        IMapleLoanLike(loanAddress).acceptNewTerms(refinancer_, calls_, uint256(0));

        // NOTE: This must be set after accepting the new terms, which affects the loan principal.
        _principalRemainingAtLastClaim = IMapleLoanLike(loanAddress).principal();
    }

    function claim() external override whenProtocolNotPaused returns (uint256[7] memory details_) {
        require(msg.sender == _pool, "DL:C:NOT_POOL");

        return _repossessed ? _handleClaimOfRepossessed(msg.sender, _loan) : _handleClaim(msg.sender, _loan);
    }

    function pullFundsFromLiquidator(address liquidator_, address token_, address destination_, uint256 amount_) external override {
        require(msg.sender == _getPoolDelegate(), "DL:SA:NOT_PD");

        Liquidator(liquidator_).pullFunds(token_, destination_, amount_);
    }

    function setAllowedSlippage(uint256 allowedSlippage_) external override whenProtocolNotPaused {
        require(msg.sender == _getPoolDelegate(),    "DL:SAS:NOT_PD");
        require(allowedSlippage_ <= uint256(10_000), "DL:SAS:INVALID_SLIPPAGE");

        emit AllowedSlippageSet(_allowedSlippage = allowedSlippage_);
    }

    function setAuctioneer(address auctioneer_) external override whenProtocolNotPaused {
        require(msg.sender == _getPoolDelegate(), "DL:SA:NOT_PD");

        emit AuctioneerSet(auctioneer_);

        Liquidator(_liquidator).setAuctioneer(auctioneer_);
    }

    function setFundsToCapture(uint256 amount_) override external whenProtocolNotPaused {
        require(msg.sender == _getPoolDelegate(), "DL:SFTC:NOT_PD");

        emit FundsToCaptureSet(_fundsToCapture = amount_);
    }

    function setMinRatio(uint256 minRatio_) external override whenProtocolNotPaused {
        require(msg.sender == _getPoolDelegate(), "DL:SMR:NOT_PD");

        emit MinRatioSet(_minRatio = minRatio_);
    }

    // Pool delegate can prematurely stop liquidation when there's still significant amount to be liquidated.
    function stopLiquidation() external override {
        require(msg.sender == _getPoolDelegate(), "DL:SL:NOT_PD");

        _liquidator = address(0);

        emit LiquidationStopped();
    }

    function triggerDefault() external override whenProtocolNotPaused {
        require(msg.sender == _pool, "DL:TD:NOT_POOL");

        address loanAddress = _loan;

        require(
            (IMapleLoanLike(loanAddress).claimableFunds() == uint256(0)) &&
            (IMapleLoanLike(loanAddress).principal() == _principalRemainingAtLastClaim),
            "DL:TD:NEED_TO_CLAIM"
        );

        _repossessed = true;

        // Ensure that principal is always up to date, claim function will clear out all payments, but on refinance we need to ensure that
        // accounting is updated properly when principal is updated and there are no claimable funds.

        // Repossess collateral and funds from Loan.
        ( uint256 collateralAssetAmount, ) = IMapleLoanLike(loanAddress).repossess(address(this));

        address collateralAsset = IMapleLoanLike(loanAddress).collateralAsset();
        address fundsAsset      = IMapleLoanLike(loanAddress).fundsAsset();

        if (collateralAsset == fundsAsset || collateralAssetAmount == uint256(0)) return;

        // Deploy Liquidator contract and transfer collateral.
        require(
            ERC20Helper.transfer(
                collateralAsset,
                _liquidator = address(new Liquidator(address(this), collateralAsset, fundsAsset, address(this), address(this), _getGlobals())),
                collateralAssetAmount
            ),
            "DL:TD:TRANSFER"
       );
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _handleClaim(address pool_, address loan_) internal returns (uint256[7] memory details_) {
        // Get loan state variables needed
        uint256 claimableFunds = IMapleLoanLike(loan_).claimableFunds();

        require(claimableFunds > uint256(0), "DL:HC:NOTHING_TO_CLAIM");

        // Send funds to pool
        IMapleLoanLike(loan_).claimFunds(claimableFunds, pool_);

        uint256 currentPrincipalRemaining = IMapleLoanLike(loan_).principal();

        // Determine how much of `claimableFunds` is principal
        uint256 principalPortion = _principalRemainingAtLastClaim - currentPrincipalRemaining;

        // Update state variables
        _principalRemainingAtLastClaim = currentPrincipalRemaining;

        // Set return values
        // Note: All fees get deducted and transferred during `loan.fundLoan()` that omits the need to
        // return the fees distribution to the pool.
        details_[0] = claimableFunds;
        details_[1] = claimableFunds - principalPortion;
        details_[2] = principalPortion;

        uint256 amountOfFundsToCapture = _fundsToCapture;

        if (amountOfFundsToCapture > uint256(0)) {
            details_[0] += amountOfFundsToCapture;
            details_[2] += amountOfFundsToCapture;

            _fundsToCapture = uint256(0);

            require(ERC20Helper.transfer(IMapleLoanLike(loan_).fundsAsset(), pool_, amountOfFundsToCapture), "DL:HC:CAPTURE_FAILED");
        }
    }

    function _handleClaimOfRepossessed(address pool_, address loan_) internal returns (uint256[7] memory details_) {
        require(!_isLiquidationActive(), "DL:HCOR:LIQ_NOT_FINISHED");

        address fundsAsset       = IMapleLoanLike(loan_).fundsAsset();
        uint256 principalToCover = _principalRemainingAtLastClaim;      // Principal remaining at time of liquidation
        uint256 fundsCaptured    = _fundsToCapture;

        // Funds recovered from liquidation and any unclaimed previous payment amounts
        uint256 recoveredFunds = IERC20Like(fundsAsset).balanceOf(address(this)) - fundsCaptured;

        uint256 totalClaimed = recoveredFunds + fundsCaptured;

        // If `recoveredFunds` is greater than `principalToCover`, the remaining amount is treated as interest in the context of the pool.
        // If `recoveredFunds` is less than `principalToCover`, the difference is registered as a shortfall.
        details_[0] = totalClaimed;
        details_[1] = recoveredFunds > principalToCover ? recoveredFunds - principalToCover : uint256(0);
        details_[2] = fundsCaptured;
        details_[5] = recoveredFunds > principalToCover ? principalToCover : recoveredFunds;
        details_[6] = principalToCover > recoveredFunds ? principalToCover - recoveredFunds : uint256(0);

        _fundsToCapture = uint256(0);
        _repossessed    = false;

        require(ERC20Helper.transfer(fundsAsset, pool_, totalClaimed), "DL:HCOR:TRANSFER");
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    function allowedSlippage() external view override returns (uint256 allowedSlippage_) {
        return _allowedSlippage;
    }

    function amountRecovered() external view override returns (uint256 amountRecovered_) {
        return _amountRecovered;
    }

    function factory() external view override returns (address factory_) {
        return _factory();
    }

    function fundsToCapture() external view override returns (uint256 fundsToCapture_) {
        return _fundsToCapture;
    }

    function getExpectedAmount(uint256 swapAmount_) external view override whenProtocolNotPaused returns (uint256 returnAmount_) {
        address loanAddress     = _loan;
        address collateralAsset = IMapleLoanLike(loanAddress).collateralAsset();
        address fundsAsset      = IMapleLoanLike(loanAddress).fundsAsset();
        address globals         = _getGlobals();

        uint8 collateralAssetDecimals = IERC20Like(collateralAsset).decimals();

        uint256 oracleAmount =
            swapAmount_
                * IMapleGlobalsLike(globals).getLatestPrice(collateralAsset)  // Convert from `fromAsset` value.
                * uint256(10) ** uint256(IERC20Like(fundsAsset).decimals())   // Convert to `toAsset` decimal precision.
                * (uint256(10_000) - _allowedSlippage)                        // Multiply by allowed slippage basis points
                / IMapleGlobalsLike(globals).getLatestPrice(fundsAsset)       // Convert to `toAsset` value.
                / uint256(10) ** uint256(collateralAssetDecimals)             // Convert from `fromAsset` decimal precision.
                / uint256(10_000);                                            // Divide basis points for slippage.

        uint256 minRatioAmount = (swapAmount_ * _minRatio) / (uint256(10) ** collateralAssetDecimals);

        return oracleAmount > minRatioAmount ? oracleAmount : minRatioAmount;
    }

    function implementation() external view override returns (address implementation_) {
        return _implementation();
    }

    function liquidator() external view override returns (address liquidator_) {
        return _liquidator;
    }

    function loan() external view override returns (address loan_) {
        return _loan;
    }

    function minRatio() external view override returns (uint256 minRatio_) {
        return _minRatio;
    }

    function pool() external view override returns (address pool_) {
        return _pool;
    }

    function poolDelegate() external override view returns (address poolDelegate_) {
        return _getPoolDelegate();
    }

    function principalRemainingAtLastClaim() external view override returns (uint256 principalRemainingAtLastClaim_) {
        return _principalRemainingAtLastClaim;
    }

    function repossessed() external view override returns (bool repossessed_) {
        return _repossessed;
    }

    /*******************************/
    /*** Internal View Functions ***/
    /*******************************/

    function _getGlobals() internal view returns (address globals_) {
        return IPoolFactoryLike(IPoolLike(_pool).superFactory()).globals();
    }

    function _getPoolDelegate() internal view returns(address poolDelegate_) {
        return IPoolLike(_pool).poolDelegate();
    }

    function _isLiquidationActive() internal view returns (bool isActive_) {
        address liquidatorAddress = _liquidator;

        return (liquidatorAddress != address(0)) && (IERC20Like(IMapleLoanLike(_loan).collateralAsset()).balanceOf(liquidatorAddress) != uint256(0));
    }

}