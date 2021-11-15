// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./TokenBase/Base.sol";

/**
 * @title dForce's Lending Protocol Contract.
 * @notice iTokens which wrap an EIP-20 underlying.
 * @author dForce Team.
 */
contract iToken is Base {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Expects to call only once to initialize a new market.
     * @param _underlyingToken The underlying token address.
     * @param _name Token name.
     * @param _symbol Token symbol.
     * @param _controller Core controller contract address.
     * @param _interestRateModel Token interest rate model contract address.
     */
    function initialize(
        address _underlyingToken,
        string memory _name,
        string memory _symbol,
        IControllerInterface _controller,
        IInterestRateModelInterface _interestRateModel
    ) external initializer {
        _initialize(
            _name,
            _symbol,
            ERC20(_underlyingToken).decimals(),
            _controller,
            _interestRateModel
        );

        underlying = IERC20Upgradeable(_underlyingToken);
    }

    /**
     * @notice In order to support deflationary token, returns the changed amount.
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom`.
     */
    function _doTransferIn(address _spender, uint256 _amount)
        internal
        override
        returns (uint256)
    {
        uint256 _balanceBefore = underlying.balanceOf(address(this));
        underlying.safeTransferFrom(_spender, address(this), _amount);
        return underlying.balanceOf(address(this)).sub(_balanceBefore);
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transfer`.
     */
    function _doTransferOut(address payable _recipient, uint256 _amount)
        internal
        override
    {
        underlying.safeTransfer(_recipient, _amount);
    }

    /**
     * @dev Gets balance of this contract in terms of the underlying
     */
    function _getCurrentCash() internal view override returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /**
     * @dev Caller deposits assets into the market and `_recipient` receives iToken in exchange.
     * @param _recipient The account that would receive the iToken.
     * @param _mintAmount The amount of the underlying token to deposit.
     */
    function mint(address _recipient, uint256 _mintAmount)
        external
        nonReentrant
        settleInterest
    {
        _mintInternal(_recipient, _mintAmount);
    }

    /**
     * @dev Caller redeems specified iToken from `_from` to get underlying token.
     * @param _from The account that would burn the iToken.
     * @param _redeemiToken The number of iToken to redeem.
     */
    function redeem(address _from, uint256 _redeemiToken)
        external
        nonReentrant
        settleInterest
    {
        _redeemInternal(
            _from,
            _redeemiToken,
            _redeemiToken.rmul(_exchangeRateInternal())
        );
    }

    /**
     * @dev Caller redeems specified underlying from `_from` to get underlying token.
     * @param _from The account that would burn the iToken.
     * @param _redeemUnderlying The number of underlying to redeem.
     */
    function redeemUnderlying(address _from, uint256 _redeemUnderlying)
        external
        nonReentrant
        settleInterest
    {
        _redeemInternal(
            _from,
            _redeemUnderlying.rdivup(_exchangeRateInternal()),
            _redeemUnderlying
        );
    }

    /**
     * @dev Caller borrows tokens from the protocol to their own address.
     * @param _borrowAmount The amount of the underlying token to borrow.
     */
    function borrow(uint256 _borrowAmount)
        external
        nonReentrant
        settleInterest
    {
        _borrowInternal(msg.sender, _borrowAmount);
    }

    /**
     * @dev Caller repays their own borrow.
     * @param _repayAmount The amount to repay.
     */
    function repayBorrow(uint256 _repayAmount)
        external
        nonReentrant
        settleInterest
    {
        _repayInternal(msg.sender, msg.sender, _repayAmount);
    }

    /**
     * @dev Caller repays a borrow belonging to borrower.
     * @param _borrower the account with the debt being payed off.
     * @param _repayAmount The amount to repay.
     */
    function repayBorrowBehalf(address _borrower, uint256 _repayAmount)
        external
        nonReentrant
        settleInterest
    {
        _repayInternal(msg.sender, _borrower, _repayAmount);
    }

    /**
     * @dev The caller liquidates the borrowers collateral.
     * @param _borrower The account whose borrow should be liquidated.
     * @param _assetCollateral The market in which to seize collateral from the borrower.
     * @param _repayAmount The amount to repay.
     */
    function liquidateBorrow(
        address _borrower,
        uint256 _repayAmount,
        address _assetCollateral
    ) external nonReentrant settleInterest {
        _liquidateBorrowInternal(_borrower, _repayAmount, _assetCollateral);
    }

    /**
     * @dev Transfers this tokens to the liquidator.
     * @param _liquidator The account receiving seized collateral.
     * @param _borrower The account having collateral seized.
     * @param _seizeTokens The number of iTokens to seize.
     */
    function seize(
        address _liquidator,
        address _borrower,
        uint256 _seizeTokens
    ) external override nonReentrant {
        _seizeInternal(msg.sender, _liquidator, _borrower, _seizeTokens);
    }

    /**
     * @notice Calculates interest and update total borrows and reserves.
     * @dev Updates total borrows and reserves with any accumulated interest.
     */
    function updateInterest() external override returns (bool) {
        _updateInterest();
        return true;
    }

    /**
     * @dev Gets the newest exchange rate by accruing interest.
     */
    function exchangeRateCurrent() external returns (uint256) {
        // Accrues interest.
        _updateInterest();

        return _exchangeRateInternal();
    }

    /**
     * @dev Calculates the exchange rate without accruing interest.
     */
    function exchangeRateStored() external view override returns (uint256) {
        return _exchangeRateInternal();
    }

    /**
     * @dev Gets the underlying balance of the `_account`.
     * @param _account The address of the account to query.
     */
    function balanceOfUnderlying(address _account) external returns (uint256) {
        // Accrues interest.
        _updateInterest();

        return _exchangeRateInternal().rmul(balanceOf[_account]);
    }

    /**
     * @dev Gets the user's borrow balance with the latest `borrowIndex`.
     */
    function borrowBalanceCurrent(address _account)
        external
        nonReentrant
        returns (uint256)
    {
        // Accrues interest.
        _updateInterest();

        return _borrowBalanceInternal(_account);
    }

    /**
     * @dev Gets the borrow balance of user without accruing interest.
     */
    function borrowBalanceStored(address _account)
        external
        view
        override
        returns (uint256)
    {
        return _borrowBalanceInternal(_account);
    }

    /**
     * @dev Gets user borrowing information.
     */
    function borrowSnapshot(address _account)
        external
        view
        returns (uint256, uint256)
    {
        return (
            accountBorrows[_account].principal,
            accountBorrows[_account].interestIndex
        );
    }

    /**
     * @dev Gets the current total borrows by accruing interest.
     */
    function totalBorrowsCurrent() external returns (uint256) {
        // Accrues interest.
        _updateInterest();

        return totalBorrows;
    }

    /**
     * @dev Returns the current per-block borrow interest rate.
     */
    function borrowRatePerBlock() public view returns (uint256) {
        return
            interestRateModel.getBorrowRate(
                _getCurrentCash(),
                totalBorrows,
                totalReserves
            );
    }

    /**
     * @dev Returns the current per-block supply interest rate.
     *  Calculates the supply rate:
     *  underlying = totalSupply × exchangeRate
     *  borrowsPer = totalBorrows ÷ underlying
     *  supplyRate = borrowRate × (1-reserveFactor) × borrowsPer
     */
    function supplyRatePerBlock() external view returns (uint256) {
        // `_underlyingScaled` is scaled by 1e36.
        uint256 _underlyingScaled = totalSupply.mul(_exchangeRateInternal());
        if (_underlyingScaled == 0) return 0;
        uint256 _totalBorrowsScaled = totalBorrows.mul(BASE);

        return
            borrowRatePerBlock().tmul(
                BASE.sub(reserveRatio),
                _totalBorrowsScaled.rdiv(_underlyingScaled)
            );
    }

    /**
     * @dev Get cash balance of this iToken in the underlying token.
     */
    function getCash() external view returns (uint256) {
        return _getCurrentCash();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interface/IFlashloanExecutor.sol";
import "../library/SafeRatioMath.sol";

import "./TokenERC20.sol";

/**
 * @title dForce's lending Base Contract
 * @author dForce
 */
abstract contract Base is TokenERC20 {
    using SafeRatioMath for uint256;

    /**
     * @notice Expects to call only once to create a new lending market.
     * @param _name Token name.
     * @param _symbol Token symbol.
     * @param _controller Core controller contract address.
     * @param _interestRateModel Token interest rate model contract address.
     */
    function _initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        IControllerInterface _controller,
        IInterestRateModelInterface _interestRateModel
    ) internal virtual {
        controller = _controller;
        interestRateModel = _interestRateModel;
        accrualBlockNumber = block.number;
        borrowIndex = BASE;
        flashloanFeeRatio = 0.0008e18;
        protocolFeeRatio = 0.25e18;
        __Ownable_init();
        __ERC20_init(_name, _symbol, _decimals);
        __ReentrancyGuard_init();

        uint256 chainId;

        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /*********************************/
    /******** Security Check *********/
    /*********************************/

    /**
     * @notice Ensure this is a iToken contract.
     */
    function isiToken() external pure returns (bool) {
        return true;
    }

    //----------------------------------
    //******** Main calculation ********
    //----------------------------------

    struct InterestLocalVars {
        uint256 borrowRate;
        uint256 currentBlockNumber;
        uint256 currentCash;
        uint256 totalBorrows;
        uint256 totalReserves;
        uint256 borrowIndex;
        uint256 blockDelta;
        uint256 simpleInterestFactor;
        uint256 interestAccumulated;
        uint256 newTotalBorrows;
        uint256 newTotalReserves;
        uint256 newBorrowIndex;
    }

    /**
     * @notice Calculates interest and update total borrows and reserves.
     * @dev Updates total borrows and reserves with any accumulated interest.
     */
    function _updateInterest() internal virtual override {
        InterestLocalVars memory _vars;
        _vars.currentCash = _getCurrentCash();
        _vars.totalBorrows = totalBorrows;
        _vars.totalReserves = totalReserves;

        // Gets the current borrow interest rate.
        _vars.borrowRate = interestRateModel.getBorrowRate(
            _vars.currentCash,
            _vars.totalBorrows,
            _vars.totalReserves
        );
        require(
            _vars.borrowRate <= maxBorrowRate,
            "_updateInterest: Borrow rate is too high!"
        );

        // Records the current block number.
        _vars.currentBlockNumber = block.number;

        // Calculates the number of blocks elapsed since the last accrual.
        _vars.blockDelta = _vars.currentBlockNumber.sub(accrualBlockNumber);

        /**
         * Calculates the interest accumulated into borrows and reserves and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  newTotalBorrows = interestAccumulated + totalBorrows
         *  newTotalReserves = interestAccumulated * reserveFactor + totalReserves
         *  newBorrowIndex = simpleInterestFactor * borrowIndex + borrowIndex
         */
        _vars.simpleInterestFactor = _vars.borrowRate.mul(_vars.blockDelta);
        _vars.interestAccumulated = _vars.simpleInterestFactor.rmul(
            _vars.totalBorrows
        );
        _vars.newTotalBorrows = _vars.interestAccumulated.add(
            _vars.totalBorrows
        );
        _vars.newTotalReserves = reserveRatio
            .rmul(_vars.interestAccumulated)
            .add(_vars.totalReserves);

        _vars.borrowIndex = borrowIndex;
        _vars.newBorrowIndex = _vars
            .simpleInterestFactor
            .rmul(_vars.borrowIndex)
            .add(_vars.borrowIndex);

        // Writes the previously calculated values into storage.
        accrualBlockNumber = _vars.currentBlockNumber;
        borrowIndex = _vars.newBorrowIndex;
        totalBorrows = _vars.newTotalBorrows;
        totalReserves = _vars.newTotalReserves;

        // Emits an `UpdateInterest` event.
        emit UpdateInterest(
            _vars.currentBlockNumber,
            _vars.interestAccumulated,
            _vars.newBorrowIndex,
            _vars.currentCash,
            _vars.newTotalBorrows,
            _vars.newTotalReserves
        );
    }

    struct MintLocalVars {
        uint256 exchangeRate;
        uint256 mintTokens;
        uint256 actualMintAmout;
    }

    /**
     * @dev User deposits token into the market and `_recipient` gets iToken.
     * @param _recipient The address of the user to get iToken.
     * @param _mintAmount The amount of the underlying token to deposit.
     */
    function _mintInternal(address _recipient, uint256 _mintAmount)
        internal
        virtual
    {
        controller.beforeMint(address(this), _recipient, _mintAmount);

        MintLocalVars memory _vars;

        /**
         * Gets the current exchange rate and calculate the number of iToken to be minted:
         *  mintTokens = mintAmount / exchangeRate
         */
        _vars.exchangeRate = _exchangeRateInternal();

        // Transfers `_mintAmount` from caller to contract, and returns the actual amount the contract
        // get, cause some tokens may be charged.

        _vars.actualMintAmout = _doTransferIn(msg.sender, _mintAmount);

        // Supports deflationary tokens.
        _vars.mintTokens = _vars.actualMintAmout.rdiv(_vars.exchangeRate);

        // Mints `mintTokens` iToken to `_recipient`.
        _mint(_recipient, _vars.mintTokens);

        controller.afterMint(
            address(this),
            _recipient,
            _mintAmount,
            _vars.mintTokens
        );

        emit Mint(msg.sender, _recipient, _mintAmount, _vars.mintTokens);
    }

    /**
     * @notice This is a common function to redeem, so only one of `_redeemiTokenAmount` or
     *         `_redeemUnderlyingAmount` may be non-zero.
     * @dev Caller redeems undelying token based on the input amount of iToken or underlying token.
     * @param _from The address of the account which will spend underlying token.
     * @param _redeemiTokenAmount The number of iTokens to redeem into underlying.
     * @param _redeemUnderlyingAmount The number of underlying tokens to receive.
     */
    function _redeemInternal(
        address _from,
        uint256 _redeemiTokenAmount,
        uint256 _redeemUnderlyingAmount
    ) internal virtual {
        require(
            _redeemiTokenAmount > 0,
            "_redeemInternal: Redeem iToken amount should be greater than zero!"
        );

        controller.beforeRedeem(address(this), _from, _redeemiTokenAmount);

        if (msg.sender != _from)
            _approve(
                _from,
                msg.sender,
                allowance[_from][msg.sender].sub(_redeemiTokenAmount)
            );

        _burn(_from, _redeemiTokenAmount);

        /**
         * Transfers `_redeemUnderlyingAmount` underlying token to caller.
         */
        _doTransferOut(msg.sender, _redeemUnderlyingAmount);

        controller.afterRedeem(
            address(this),
            _from,
            _redeemiTokenAmount,
            _redeemUnderlyingAmount
        );

        emit Redeem(
            _from,
            msg.sender,
            _redeemiTokenAmount,
            _redeemUnderlyingAmount
        );
    }

    /**
     * @dev Caller borrows assets from the protocol.
     * @param _borrower The account that will borrow tokens.
     * @param _borrowAmount The amount of the underlying asset to borrow.
     */
    function _borrowInternal(address payable _borrower, uint256 _borrowAmount)
        internal
        virtual
    {
        controller.beforeBorrow(address(this), _borrower, _borrowAmount);

        // Calculates the new borrower and total borrow balances:
        //  newAccountBorrows = accountBorrows + borrowAmount
        //  newTotalBorrows = totalBorrows + borrowAmount
        BorrowSnapshot storage borrowSnapshot = accountBorrows[_borrower];
        borrowSnapshot.principal = _borrowBalanceInternal(_borrower).add(
            _borrowAmount
        );
        borrowSnapshot.interestIndex = borrowIndex;
        totalBorrows = totalBorrows.add(_borrowAmount);

        // Transfers token to borrower.
        _doTransferOut(_borrower, _borrowAmount);

        controller.afterBorrow(address(this), _borrower, _borrowAmount);

        emit Borrow(
            _borrower,
            _borrowAmount,
            borrowSnapshot.principal,
            borrowSnapshot.interestIndex,
            totalBorrows
        );
    }

    /**
     * @notice Please approve enough amount at first!!! If not,
     *         maybe you will get an error: `SafeMath: subtraction overflow`
     * @dev `_payer` repays `_repayAmount` tokens for `_borrower`.
     * @param _payer The account to pay for the borrowed.
     * @param _borrower The account with the debt being payed off.
     * @param _repayAmount The amount to repay (or -1 for max).
     */
    function _repayInternal(
        address _payer,
        address _borrower,
        uint256 _repayAmount
    ) internal virtual returns (uint256) {
        controller.beforeRepayBorrow(
            address(this),
            _payer,
            _borrower,
            _repayAmount
        );

        // Calculates the latest borrowed amount by the new market borrowed index.
        uint256 _accountBorrows = _borrowBalanceInternal(_borrower);

        // Transfers the token into the market to repay.
        uint256 _actualRepayAmount =
            _doTransferIn(
                _payer,
                _repayAmount > _accountBorrows ? _accountBorrows : _repayAmount
            );

        // Calculates the `_borrower` new borrow balance and total borrow balances:
        //  accountBorrows[_borrower].principal = accountBorrows - actualRepayAmount
        //  newTotalBorrows = totalBorrows - actualRepayAmount

        // Saves borrower updates.
        BorrowSnapshot storage borrowSnapshot = accountBorrows[_borrower];
        borrowSnapshot.principal = _accountBorrows.sub(_actualRepayAmount);
        borrowSnapshot.interestIndex = borrowIndex;

        totalBorrows = totalBorrows < _actualRepayAmount
            ? 0
            : totalBorrows.sub(_actualRepayAmount);

        // Defense hook.
        controller.afterRepayBorrow(
            address(this),
            _payer,
            _borrower,
            _actualRepayAmount
        );

        emit RepayBorrow(
            _payer,
            _borrower,
            _actualRepayAmount,
            borrowSnapshot.principal,
            borrowSnapshot.interestIndex,
            totalBorrows
        );

        return _actualRepayAmount;
    }

    /**
     * @dev The caller repays some of borrow and receive collateral.
     * @param _borrower The account whose borrow should be liquidated.
     * @param _repayAmount The amount to repay.
     * @param _assetCollateral The market in which to seize collateral from the borrower.
     */
    function _liquidateBorrowInternal(
        address _borrower,
        uint256 _repayAmount,
        address _assetCollateral
    ) internal virtual {
        require(
            msg.sender != _borrower,
            "_liquidateBorrowInternal: Liquidator can not be borrower!"
        );
        // According to the parameter `_repayAmount` to see what is the exact error.
        require(
            _repayAmount != 0,
            "_liquidateBorrowInternal: Liquidate amount should be greater than 0!"
        );

        // Accrues interest for collateral asset.
        Base _dlCollateral = Base(_assetCollateral);
        _dlCollateral.updateInterest();

        controller.beforeLiquidateBorrow(
            address(this),
            _assetCollateral,
            msg.sender,
            _borrower,
            _repayAmount
        );

        require(
            _dlCollateral.accrualBlockNumber() == block.number,
            "_liquidateBorrowInternal: Failed to update block number in collateral asset!"
        );

        uint256 _actualRepayAmount =
            _repayInternal(msg.sender, _borrower, _repayAmount);

        // Calculates the number of collateral tokens that will be seized
        uint256 _seizeTokens =
            controller.liquidateCalculateSeizeTokens(
                address(this),
                _assetCollateral,
                _actualRepayAmount
            );

        // If this is also the collateral, calls seizeInternal to avoid re-entrancy,
        // otherwise make an external call.
        if (_assetCollateral == address(this)) {
            _seizeInternal(address(this), msg.sender, _borrower, _seizeTokens);
        } else {
            _dlCollateral.seize(msg.sender, _borrower, _seizeTokens);
        }

        controller.afterLiquidateBorrow(
            address(this),
            _assetCollateral,
            msg.sender,
            _borrower,
            _actualRepayAmount,
            _seizeTokens
        );

        emit LiquidateBorrow(
            msg.sender,
            _borrower,
            _actualRepayAmount,
            _assetCollateral,
            _seizeTokens
        );
    }

    /**
     * @dev Transfers this token to the liquidator.
     * @param _seizerToken The contract seizing the collateral.
     * @param _liquidator The account receiving seized collateral.
     * @param _borrower The account having collateral seized.
     * @param _seizeTokens The number of iTokens to seize.
     */
    function _seizeInternal(
        address _seizerToken,
        address _liquidator,
        address _borrower,
        uint256 _seizeTokens
    ) internal virtual {
        require(
            _borrower != _liquidator,
            "seize: Liquidator can not be borrower!"
        );

        controller.beforeSeize(
            address(this),
            _seizerToken,
            _liquidator,
            _borrower,
            _seizeTokens
        );

        /**
         * Calculates the new _borrower and _liquidator token balances,
         * that is transfer `_seizeTokens` iToken from `_borrower` to `_liquidator`.
         */
        _transfer(_borrower, _liquidator, _seizeTokens);

        // Hook checks.
        controller.afterSeize(
            address(this),
            _seizerToken,
            _liquidator,
            _borrower,
            _seizeTokens
        );
    }

    /**
     * @param _account The address whose balance should be calculated.
     */
    function _borrowBalanceInternal(address _account)
        internal
        view
        virtual
        returns (uint256)
    {
        // Gets stored borrowed data of the `_account`.
        BorrowSnapshot storage borrowSnapshot = accountBorrows[_account];

        // If borrowBalance = 0, return 0 directly.
        if (borrowSnapshot.principal == 0 || borrowSnapshot.interestIndex == 0)
            return 0;

        // Calculate new borrow balance with market new borrow index:
        //   recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
        return
            borrowSnapshot.principal.mul(borrowIndex).divup(
                borrowSnapshot.interestIndex
            );
    }

    /**
     * @dev Calculates the exchange rate from the underlying token to the iToken.
     */
    function _exchangeRateInternal() internal view virtual returns (uint256) {
        if (totalSupply == 0) {
            // This is the first time to mint, so current exchange rate is equal to initial exchange rate.
            return initialExchangeRate;
        } else {
            // exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
            return
                _getCurrentCash().add(totalBorrows).sub(totalReserves).rdiv(
                    totalSupply
                );
        }
    }

    function updateInterest() external virtual returns (bool);

    /**
     * @dev EIP2612 permit function. For more details, please look at here:
     * https://eips.ethereum.org/EIPS/eip-2612
     * @param _owner The owner of the funds.
     * @param _spender The spender.
     * @param _value The amount.
     * @param _deadline The deadline timestamp, type(uint256).max for max deadline.
     * @param _v Signature param.
     * @param _s Signature param.
     * @param _r Signature param.
     */
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_deadline >= block.timestamp, "permit: EXPIRED!");
        uint256 _currentNonce = nonces[_owner];
        bytes32 _digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            _owner,
                            _spender,
                            _value,
                            _currentNonce,
                            _deadline
                        )
                    )
                )
            );
        address _recoveredAddress = ecrecover(_digest, _v, _r, _s);
        require(
            _recoveredAddress != address(0) && _recoveredAddress == _owner,
            "permit: INVALID_SIGNATURE!"
        );
        nonces[_owner] = _currentNonce.add(1);
        _approve(_owner, _spender, _value);
    }

    /**
     * @dev Transfers this tokens to the liquidator.
     * @param _liquidator The account receiving seized collateral.
     * @param _borrower The account having collateral seized.
     * @param _seizeTokens The number of iTokens to seize.
     */
    function seize(
        address _liquidator,
        address _borrower,
        uint256 _seizeTokens
    ) external virtual;

    /**
     * @notice Users are expected to have enough allowance and balance before calling.
     * @dev Transfers asset in.
     */
    function _doTransferIn(address _spender, uint256 _amount)
        internal
        virtual
        returns (uint256);

    function exchangeRateStored() external view virtual returns (uint256);

    function borrowBalanceStored(address _account)
        external
        view
        virtual
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IFlashloanExecutor {
    function executeOperation(
        address reserve,
        uint256 amount,
        uint256 fee,
        bytes memory data
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

library SafeRatioMath {
    using SafeMathUpgradeable for uint256;

    uint256 private constant BASE = 10**18;
    uint256 private constant DOUBLE = 10**36;

    function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.add(y.sub(1)).div(y);
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(y).div(BASE);
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(BASE).div(y);
    }

    function rdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(BASE).add(y.sub(1)).div(y);
    }

    function tmul(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256 result) {
        result = x.mul(y).mul(z).div(DOUBLE);
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 base
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
                case 0 {
                    switch n
                        case 0 {
                            z := base
                        }
                        default {
                            z := 0
                        }
                }
                default {
                    switch mod(n, 2)
                        case 0 {
                            z := base
                        }
                        default {
                            z := x
                        }
                    let half := div(base, 2) // for rounding.

                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, base)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(
                                iszero(iszero(x)),
                                iszero(eq(div(zx, x), z))
                            ) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, base)
                        }
                    }
                }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./TokenAdmin.sol";

/**
 * @title dForce's lending Token ERC20 Contract
 * @author dForce
 */
abstract contract TokenERC20 is TokenAdmin {
    /**
     * @dev Transfers `_amount` tokens from `_spender` to `_recipient`.
     * @param _spender The address of the source account.
     * @param _recipient The address of the destination account.
     * @param _amount The number of tokens to transfer.
     */
    function _transferTokens(
        address _spender,
        address _recipient,
        uint256 _amount
    ) internal returns (bool) {
        require(
            _spender != _recipient,
            "_transferTokens: Do not self-transfer!"
        );

        controller.beforeTransfer(
            address(this),
            msg.sender,
            _recipient,
            _amount
        );

        _transfer(_spender, _recipient, _amount);

        controller.afterTransfer(address(this), _spender, _recipient, _amount);

        return true;
    }

    //----------------------------------
    //********* ERC20 Actions **********
    //----------------------------------

    /**
     * @notice Cause iToken is an ERC20 token, so users can `transfer` them,
     *         but this action is only allowed when after transferring tokens, the caller
     *         does not have a shortfall.
     * @dev Moves `_amount` tokens from caller to `_recipient`.
     * @param _recipient The address of the destination account.
     * @param _amount The number of tokens to transfer.
     */
    function transfer(address _recipient, uint256 _amount)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        return _transferTokens(msg.sender, _recipient, _amount);
    }

    /**
     * @notice Cause iToken is an ERC20 token, so users can `transferFrom` them,
     *         but this action is only allowed when after transferring tokens, the `_spender`
     *         does not have a shortfall.
     * @dev Moves `_amount` tokens from `_spender` to `_recipient`.
     * @param _spender The address of the source account.
     * @param _recipient The address of the destination account.
     * @param _amount The number of tokens to transfer.
     */
    function transferFrom(
        address _spender,
        address _recipient,
        uint256 _amount
    ) public virtual override nonReentrant returns (bool) {
        _approve(
            _spender,
            msg.sender,
            allowance[_spender][msg.sender].sub(_amount)
        );
        return _transferTokens(_spender, _recipient, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./TokenEvent.sol";

/**
 * @title dForce's lending Token admin Contract
 * @author dForce
 */
abstract contract TokenAdmin is TokenEvent {
    //----------------------------------
    //********* Owner Actions **********
    //----------------------------------

    modifier settleInterest() {
        // Accrues interest.
        _updateInterest();
        require(
            accrualBlockNumber == block.number,
            "settleInterest: Fail to accrue interest!"
        );
        _;
    }

    /**
     * @dev Sets a new controller.
     */
    function _setController(IControllerInterface _newController)
        external
        virtual
        onlyOwner
    {
        IControllerInterface _oldController = controller;
        // Ensures the input address is a controller contract.
        require(
            _newController.isController(),
            "_setController: This is not the controller contract!"
        );

        // Sets to new controller.
        controller = _newController;

        emit NewController(_oldController, _newController);
    }

    /**
     * @dev Sets a new interest rate model.
     * @param _newInterestRateModel The new interest rate model.
     */
    function _setInterestRateModel(
        IInterestRateModelInterface _newInterestRateModel
    ) external virtual onlyOwner settleInterest {
        // Gets current interest rate model.
        IInterestRateModelInterface _oldInterestRateModel = interestRateModel;

        // Ensures the input address is the interest model contract.
        require(
            _newInterestRateModel.isInterestRateModel(),
            "_setInterestRateModel: This is not the rate model contract!"
        );

        // Set to the new interest rate model.
        interestRateModel = _newInterestRateModel;

        emit NewInterestRateModel(_oldInterestRateModel, _newInterestRateModel);
    }

    /**
     * @dev Sets a new reserve ratio.
     */
    function _setNewReserveRatio(uint256 _newReserveRatio)
        external
        virtual
        onlyOwner
        settleInterest
    {
        require(
            _newReserveRatio <= maxReserveRatio,
            "_setNewReserveRatio: New reserve ratio too large!"
        );

        // Gets current reserve ratio.
        uint256 _oldReserveRatio = reserveRatio;

        // Sets new reserve ratio.
        reserveRatio = _newReserveRatio;

        emit NewReserveRatio(_oldReserveRatio, _newReserveRatio);
    }

    /**
     * @dev Sets a new flashloan fee ratio.
     */
    function _setNewFlashloanFeeRatio(uint256 _newFlashloanFeeRatio)
        external
        virtual
        onlyOwner
        settleInterest
    {
        require(
            _newFlashloanFeeRatio <= BASE,
            "setNewFlashloanFeeRatio: New flashloan ratio too large!"
        );

        // Gets current reserve ratio.
        uint256 _oldFlashloanFeeRatio = flashloanFeeRatio;

        // Sets new reserve ratio.
        flashloanFeeRatio = _newFlashloanFeeRatio;

        emit NewFlashloanFeeRatio(_oldFlashloanFeeRatio, _newFlashloanFeeRatio);
    }

    /**
     * @dev Sets a new protocol fee ratio.
     */
    function _setNewProtocolFeeRatio(uint256 _newProtocolFeeRatio)
        external
        virtual
        onlyOwner
        settleInterest
    // nonReentrant
    {
        require(
            _newProtocolFeeRatio <= BASE,
            "_setNewProtocolFeeRatio: New protocol ratio too large!"
        );

        // Gets current reserve ratio.
        uint256 _oldProtocolFeeRatio = protocolFeeRatio;

        // Sets new reserve ratio.
        protocolFeeRatio = _newProtocolFeeRatio;

        emit NewProtocolFeeRatio(_oldProtocolFeeRatio, _newProtocolFeeRatio);
    }

    /**
     * @dev Admin withdraws `_withdrawAmount` of the iToken.
     * @param _withdrawAmount Amount of reserves to withdraw.
     */
    function _withdrawReserves(uint256 _withdrawAmount)
        external
        virtual
        onlyOwner
        settleInterest
    // nonReentrant
    {
        require(
            _withdrawAmount <= totalReserves &&
                _withdrawAmount <= _getCurrentCash(),
            "_withdrawReserves: Invalid withdraw amount and do not have enough cash!"
        );

        uint256 _oldTotalReserves = totalReserves;
        // Updates total amount of the reserves.
        totalReserves = totalReserves.sub(_withdrawAmount);

        // Transfers reserve to the owner.
        _doTransferOut(owner, _withdrawAmount);

        emit ReservesWithdrawn(
            owner,
            _withdrawAmount,
            totalReserves,
            _oldTotalReserves
        );
    }

    /**
     * @notice Calculates interest and update total borrows and reserves.
     * @dev Updates total borrows and reserves with any accumulated interest.
     */
    function _updateInterest() internal virtual;

    /**
     * @dev Transfers underlying token out.
     */
    function _doTransferOut(address payable _recipient, uint256 _amount)
        internal
        virtual;

    /**
     * @dev Total amount of reserves owned by this contract.
     */
    function _getCurrentCash() internal view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./TokenStorage.sol";

/**
 * @title dForce's lending Token event Contract
 * @author dForce
 */
contract TokenEvent is TokenStorage {
    //----------------------------------
    //********** User Events ***********
    //----------------------------------

    event UpdateInterest(
        uint256 currentBlockNumber,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 cash,
        uint256 totalBorrows,
        uint256 totalReserves
    );

    event Mint(
        address spender,
        address recipient,
        uint256 mintAmount,
        uint256 mintTokens
    );

    event Redeem(
        address from,
        address recipient,
        uint256 redeemiTokenAmount,
        uint256 redeemUnderlyingAmount
    );

    /**
     * @dev Emits when underlying is borrowed.
     */
    event Borrow(
        address borrower,
        uint256 borrowAmount,
        uint256 accountBorrows,
        uint256 accountInterestIndex,
        uint256 totalBorrows
    );

    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 accountInterestIndex,
        uint256 totalBorrows
    );

    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address iTokenCollateral,
        uint256 seizeTokens
    );

    event Flashloan(
        address loaner,
        uint256 loanAmount,
        uint256 flashloanFee,
        uint256 protocolFee,
        uint256 timestamp
    );

    //----------------------------------
    //********** Owner Events **********
    //----------------------------------

    event NewReserveRatio(uint256 oldReserveRatio, uint256 newReserveRatio);
    event NewFlashloanFeeRatio(
        uint256 oldFlashloanFeeRatio,
        uint256 newFlashloanFeeRatio
    );
    event NewProtocolFeeRatio(
        uint256 oldProtocolFeeRatio,
        uint256 newProtocolFeeRatio
    );
    event NewFlashloanFee(
        uint256 oldFlashloanFeeRatio,
        uint256 newFlashloanFeeRatio,
        uint256 oldProtocolFeeRatio,
        uint256 newProtocolFeeRatio
    );

    event NewInterestRateModel(
        IInterestRateModelInterface oldInterestRateModel,
        IInterestRateModelInterface newInterestRateModel
    );

    event NewController(
        IControllerInterface oldController,
        IControllerInterface newController
    );

    event ReservesWithdrawn(
        address admin,
        uint256 amount,
        uint256 newTotalReserves,
        uint256 oldTotalReserves
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../library/Initializable.sol";
import "../library/ReentrancyGuard.sol";
import "../library/Ownable.sol";
import "../library/ERC20.sol";

import "../interface/IInterestRateModelInterface.sol";
import "../interface/IControllerInterface.sol";

/**
 * @title dForce's lending Token storage Contract
 * @author dForce
 */
contract TokenStorage is Initializable, ReentrancyGuard, Ownable, ERC20 {
    //----------------------------------
    //********* Token Storage **********
    //----------------------------------

    uint256 constant BASE = 1e18;

    /**
     * @dev Whether this token is supported in the market or not.
     */
    bool public constant isSupported = true;

    /**
     * @dev Maximum borrow rate(0.1% per block, scaled by 1e18).
     */
    uint256 constant maxBorrowRate = 0.001e18;

    /**
     * @dev Interest ratio set aside for reserves(scaled by 1e18).
     */
    uint256 public reserveRatio;

    /**
     * @dev Maximum interest ratio that can be set aside for reserves(scaled by 1e18).
     */
    uint256 constant maxReserveRatio = 1e18;

    /**
     * @notice This ratio is relative to the total flashloan fee.
     * @dev Flash loan fee rate(scaled by 1e18).
     */
    uint256 public flashloanFeeRatio;

    /**
     * @notice This ratio is relative to the total flashloan fee.
     * @dev Protocol fee rate when a flashloan happens(scaled by 1e18);
     */
    uint256 public protocolFeeRatio;

    /**
     * @dev Underlying token address.
     */
    IERC20Upgradeable public underlying;

    /**
     * @dev Current interest rate model contract.
     */
    IInterestRateModelInterface public interestRateModel;

    /**
     * @dev Core control of the contract.
     */
    IControllerInterface public controller;

    /**
     * @dev Initial exchange rate(scaled by 1e18).
     */
    uint256 constant initialExchangeRate = 1e18;

    /**
     * @dev The interest index for borrows of asset as of blockNumber.
     */
    uint256 public borrowIndex;

    /**
     * @dev Block number that interest was last accrued at.
     */
    uint256 public accrualBlockNumber;

    /**
     * @dev Total amount of this reserve borrowed.
     */
    uint256 public totalBorrows;

    /**
     * @dev Total amount of this reserves accrued.
     */
    uint256 public totalReserves;

    /**
     * @dev Container for user balance information written to storage.
     * @param principal User total balance with accrued interest after applying the user's most recent balance-changing action.
     * @param interestIndex The total interestIndex as calculated after applying the user's most recent balance-changing action.
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    /**
     * @dev 2-level map: userAddress -> assetAddress -> balance for borrows.
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            !_initialized,
            "Initializable: contract is already initialized"
        );

        _;

        _initialized = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
// abstract contract ReentrancyGuardUpgradeable is Initializable {
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {_setPendingOwner} and {_acceptOwner}.
 */
contract Ownable {
    /**
     * @dev Returns the address of the current owner.
     */
    address payable public owner;

    /**
     * @dev Returns the address of the current pending owner.
     */
    address payable public pendingOwner;

    event NewOwner(address indexed previousOwner, address indexed newOwner);
    event NewPendingOwner(
        address indexed oldPendingOwner,
        address indexed newPendingOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "onlyOwner: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal {
        owner = msg.sender;
        emit NewOwner(address(0), msg.sender);
    }

    /**
     * @notice Base on the inputing parameter `newPendingOwner` to check the exact error reason.
     * @dev Transfer contract control to a new owner. The newPendingOwner must call `_acceptOwner` to finish the transfer.
     * @param newPendingOwner New pending owner.
     */
    function _setPendingOwner(address payable newPendingOwner)
        external
        onlyOwner
    {
        require(
            newPendingOwner != address(0) && newPendingOwner != pendingOwner,
            "_setPendingOwner: New owenr can not be zero address and owner has been set!"
        );

        // Gets current owner.
        address oldPendingOwner = pendingOwner;

        // Sets new pending owner.
        pendingOwner = newPendingOwner;

        emit NewPendingOwner(oldPendingOwner, newPendingOwner);
    }

    /**
     * @dev Accepts the admin rights, but only for pendingOwenr.
     */
    function _acceptOwner() external {
        require(
            msg.sender == pendingOwner,
            "_acceptOwner: Only for pending owner!"
        );

        // Gets current values for events.
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;

        // Set the new contract owner.
        owner = pendingOwner;

        // Clear the pendingOwner.
        pendingOwner = address(0);

        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 {
    using SafeMathUpgradeable for uint256;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowance[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            allowance[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            allowance[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balanceOf[sender] = balanceOf[sender].sub(amount);
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        balanceOf[account] = balanceOf[account].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title dForce Lending Protocol's InterestRateModel Interface.
 * @author dForce Team.
 */
interface IInterestRateModelInterface {
    function isInterestRateModel() external view returns (bool);

    /**
     * @dev Calculates the current borrow interest rate per block.
     * @param cash The total amount of cash the market has.
     * @param borrows The total amount of borrows the market has.
     * @param reserves The total amnount of reserves the market has.
     * @return The borrow rate per block (as a percentage, and scaled by 1e18).
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @dev Calculates the current supply interest rate per block.
     * @param cash The total amount of cash the market has.
     * @param borrows The total amount of borrows the market has.
     * @param reserves The total amnount of reserves the market has.
     * @param reserveRatio The current reserve factor the market has.
     * @return The supply rate per block (as a percentage, and scaled by 1e18).
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveRatio
    ) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IControllerAdminInterface {
    /// @notice Emitted when an admin supports a market
    event MarketAdded(
        address iToken,
        uint256 collateralFactor,
        uint256 borrowFactor,
        uint256 supplyCapacity,
        uint256 borrowCapacity,
        uint256 distributionFactor
    );

    function _addMarket(
        address _iToken,
        uint256 _collateralFactor,
        uint256 _borrowFactor,
        uint256 _supplyCapacity,
        uint256 _borrowCapacity,
        uint256 _distributionFactor
    ) external;

    /// @notice Emitted when new price oracle is set
    event NewPriceOracle(address oldPriceOracle, address newPriceOracle);

    function _setPriceOracle(address newOracle) external;

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(
        uint256 oldCloseFactorMantissa,
        uint256 newCloseFactorMantissa
    );

    function _setCloseFactor(uint256 newCloseFactorMantissa) external;

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(
        uint256 oldLiquidationIncentiveMantissa,
        uint256 newLiquidationIncentiveMantissa
    );

    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa)
        external;

    /// @notice Emitted when iToken's collateral factor is changed by admin
    event NewCollateralFactor(
        address iToken,
        uint256 oldCollateralFactorMantissa,
        uint256 newCollateralFactorMantissa
    );

    function _setCollateralFactor(
        address iToken,
        uint256 newCollateralFactorMantissa
    ) external;

    /// @notice Emitted when iToken's borrow factor is changed by admin
    event NewBorrowFactor(
        address iToken,
        uint256 oldBorrowFactorMantissa,
        uint256 newBorrowFactorMantissa
    );

    function _setBorrowFactor(address iToken, uint256 newBorrowFactorMantissa)
        external;

    /// @notice Emitted when iToken's borrow capacity is changed by admin
    event NewBorrowCapacity(
        address iToken,
        uint256 oldBorrowCapacity,
        uint256 newBorrowCapacity
    );

    function _setBorrowCapacity(address iToken, uint256 newBorrowCapacity)
        external;

    /// @notice Emitted when iToken's supply capacity is changed by admin
    event NewSupplyCapacity(
        address iToken,
        uint256 oldSupplyCapacity,
        uint256 newSupplyCapacity
    );

    function _setSupplyCapacity(address iToken, uint256 newSupplyCapacity)
        external;

    /// @notice Emitted when pause guardian is changed by admin
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    function _setPauseGuardian(address newPauseGuardian) external;

    /// @notice Emitted when mint is paused/unpaused by admin or pause guardian
    event MintPaused(address iToken, bool paused);

    function _setMintPaused(address iToken, bool paused) external;

    function _setAllMintPaused(bool paused) external;

    /// @notice Emitted when redeem is paused/unpaused by admin or pause guardian
    event RedeemPaused(address iToken, bool paused);

    function _setRedeemPaused(address iToken, bool paused) external;

    function _setAllRedeemPaused(bool paused) external;

    /// @notice Emitted when borrow is paused/unpaused by admin or pause guardian
    event BorrowPaused(address iToken, bool paused);

    function _setBorrowPaused(address iToken, bool paused) external;

    function _setAllBorrowPaused(bool paused) external;

    /// @notice Emitted when transfer is paused/unpaused by admin or pause guardian
    event TransferPaused(bool paused);

    function _setTransferPaused(bool paused) external;

    /// @notice Emitted when seize is paused/unpaused by admin or pause guardian
    event SeizePaused(bool paused);

    function _setSeizePaused(bool paused) external;

    function _setiTokenPaused(address iToken, bool paused) external;

    function _setProtocolPaused(bool paused) external;

    event NewRewardDistributor(
        address oldRewardDistributor,
        address _newRewardDistributor
    );

    function _setRewardDistributor(address _newRewardDistributor) external;
}

interface IControllerPolicyInterface {
    function beforeMint(
        address iToken,
        address account,
        uint256 mintAmount
    ) external;

    function afterMint(
        address iToken,
        address minter,
        uint256 mintAmount,
        uint256 mintedAmount
    ) external;

    function beforeRedeem(
        address iToken,
        address redeemer,
        uint256 redeemAmount
    ) external;

    function afterRedeem(
        address iToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemedAmount
    ) external;

    function beforeBorrow(
        address iToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function afterBorrow(
        address iToken,
        address borrower,
        uint256 borrowedAmount
    ) external;

    function beforeRepayBorrow(
        address iToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external;

    function afterRepayBorrow(
        address iToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external;

    function beforeLiquidateBorrow(
        address iTokenBorrowed,
        address iTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external;

    function afterLiquidateBorrow(
        address iTokenBorrowed,
        address iTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repaidAmount,
        uint256 seizedAmount
    ) external;

    function beforeSeize(
        address iTokenBorrowed,
        address iTokenCollateral,
        address liquidator,
        address borrower,
        uint256 seizeAmount
    ) external;

    function afterSeize(
        address iTokenBorrowed,
        address iTokenCollateral,
        address liquidator,
        address borrower,
        uint256 seizedAmount
    ) external;

    function beforeTransfer(
        address iToken,
        address from,
        address to,
        uint256 amount
    ) external;

    function afterTransfer(
        address iToken,
        address from,
        address to,
        uint256 amount
    ) external;

    function beforeFlashloan(
        address iToken,
        address to,
        uint256 amount
    ) external;

    function afterFlashloan(
        address iToken,
        address to,
        uint256 amount
    ) external;
}

interface IControllerAccountEquityInterface {
    function calcAccountEquity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function liquidateCalculateSeizeTokens(
        address iTokenBorrowed,
        address iTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256);
}

interface IControllerAccountInterface {
    function hasEnteredMarket(address account, address iToken)
        external
        view
        returns (bool);

    function getEnteredMarkets(address account)
        external
        view
        returns (address[] memory);

    /// @notice Emitted when an account enters a market
    event MarketEntered(address iToken, address account);

    function enterMarkets(address[] calldata iTokens)
        external
        returns (bool[] memory);

    /// @notice Emitted when an account exits a market
    event MarketExited(address iToken, address account);

    function exitMarkets(address[] calldata iTokens)
        external
        returns (bool[] memory);

    /// @notice Emitted when an account add a borrow asset
    event BorrowedAdded(address iToken, address account);

    /// @notice Emitted when an account remove a borrow asset
    event BorrowedRemoved(address iToken, address account);

    function hasBorrowed(address account, address iToken)
        external
        view
        returns (bool);

    function getBorrowedAssets(address account)
        external
        view
        returns (address[] memory);
}

interface IControllerInterface is
    IControllerAdminInterface,
    IControllerPolicyInterface,
    IControllerAccountEquityInterface,
    IControllerAccountInterface
{
    /**
     * @notice Security checks when updating the comptroller of a market, always expect to return true.
     */
    function isController() external view returns (bool);

    /**
     * @notice Return all of the iTokens
     * @return The list of iToken addresses
     */
    function getAlliTokens() external view returns (address[] memory);

    /**
     * @notice Check whether a iToken is listed in controller
     * @param _iToken The iToken to check for
     * @return true if the iToken is listed otherwise false
     */
    function hasiToken(address _iToken) external view returns (bool);
}

