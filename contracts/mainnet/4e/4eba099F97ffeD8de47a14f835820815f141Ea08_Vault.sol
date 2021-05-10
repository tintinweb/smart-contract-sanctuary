// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./tokens/EIP20NonStandardInterface.sol";

import "./IDerivativeSpecification.sol";
import "./collateralSplits/ICollateralSplit.sol";
import "./tokens/IERC20MintedBurnable.sol";
import "./tokens/ITokenBuilder.sol";
import "./IFeeLogger.sol";

import "./IPausableVault.sol";

/// @title Derivative implementation Vault
/// @notice A smart contract that references derivative specification and enables users to mint and redeem the derivative
contract Vault is Ownable, Pausable, IPausableVault, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint8;

    uint256 public constant FRACTION_MULTIPLIER = 10**12;

    enum State { Created, Live, Settled }

    event StateChanged(State oldState, State newState);
    event LiveStateSet(address primaryToken, address complementToken);
    event SettledStateSet(
        int256[] underlyingStarts,
        int256[] underlyingEnds,
        uint256 primaryConversion,
        uint256 complementConversion
    );
    event Minted(address indexed recipient, uint256 minted, uint256 collateral, uint256 fee);
    event Refunded(address indexed recipient, uint256 tokenAmount, uint256 collateral);
    event Redeemed(
        address indexed recipient,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 conversion,
        uint256 collateral
    );

    /// @notice start of live period
    uint256 public liveTime;
    /// @notice end of live period
    uint256 public settleTime;

    /// @notice redeem function can only be called after the end of the Live period + delay
    uint256 public settlementDelay;

    /// @notice underlying value at the start of live period
    int256[] public underlyingStarts;
    /// @notice underlying value at the end of live period
    int256[] public underlyingEnds;

    /// @notice primary token conversion rate multiplied by 10 ^ 12
    uint256 public primaryConversion;
    /// @notice complement token conversion rate multiplied by 10 ^ 12
    uint256 public complementConversion;

    /// @notice protocol fee multiplied by 10 ^ 12
    uint256 public protocolFee;
    /// @notice limit on author fee multiplied by 10 ^ 12
    uint256 public authorFeeLimit;

    // @notice protocol's fee receiving wallet
    address public feeWallet;

    // @notice current state of the vault
    State public state;

    // @notice derivative specification address
    IDerivativeSpecification public derivativeSpecification;
    // @notice collateral token address
    IERC20 public collateralToken;
    // @notice oracle address
    address[] public oracles;
    address[] public oracleIterators;
    // @notice collateral split address
    ICollateralSplit public collateralSplit;
    // @notice derivative's token builder strategy address
    ITokenBuilder public tokenBuilder;
    IFeeLogger public feeLogger;

    // @notice primary token address
    IERC20MintedBurnable public primaryToken;
    // @notice complement token address
    IERC20MintedBurnable public complementToken;

    constructor(
        uint256 _liveTime,
        uint256 _protocolFee,
        address _feeWallet,
        address _derivativeSpecification,
        address _collateralToken,
        address[] memory _oracles,
        address[] memory _oracleIterators,
        address _collateralSplit,
        address _tokenBuilder,
        address _feeLogger,
        uint256 _authorFeeLimit,
        uint256 _settlementDelay
    ) public {
        require(_liveTime > 0, "Live zero");
        require(_liveTime <= block.timestamp, "Live in future");
        liveTime = _liveTime;

        protocolFee = _protocolFee;

        require(_feeWallet != address(0), "Fee wallet");
        feeWallet = _feeWallet;

        require(_derivativeSpecification != address(0), "Derivative");
        derivativeSpecification = IDerivativeSpecification(
            _derivativeSpecification
        );

        require(_collateralToken != address(0), "Collateral token");
        collateralToken = IERC20(_collateralToken);

        require(_oracles.length > 0, "Oracles");
        require(_oracles[0] != address(0), "First oracle is absent");
        oracles = _oracles;

        require(_oracleIterators.length > 0, "OracleIterators");
        require(
            _oracleIterators[0] != address(0),
            "First oracle iterator is absent"
        );
        oracleIterators = _oracleIterators;

        require(_collateralSplit != address(0), "Collateral split");
        collateralSplit = ICollateralSplit(_collateralSplit);

        require(_tokenBuilder != address(0), "Token builder");
        tokenBuilder = ITokenBuilder(_tokenBuilder);

        require(_feeLogger != address(0), "Fee logger");
        feeLogger = IFeeLogger(_feeLogger);

        authorFeeLimit = _authorFeeLimit;

        settleTime = liveTime + derivativeSpecification.livePeriod();
        require(block.timestamp < settleTime, "Settled time");

        settlementDelay = _settlementDelay;
    }

    function pause() external override onlyOwner() {
        _pause();
    }

    function unpause() external override onlyOwner() {
        _unpause();
    }

    /// @notice Initialize vault by creating derivative token and switching to Live state
    /// @dev Extracted from constructor to reduce contract gas creation amount
    function initialize(int256[] calldata _underlyingStarts) external {
        require(state == State.Created, "Incorrect state.");

        underlyingStarts = _underlyingStarts;

        changeState(State.Live);

        (primaryToken, complementToken) = tokenBuilder.buildTokens(
            derivativeSpecification,
            settleTime,
            address(collateralToken)
        );

        emit LiveStateSet(address(primaryToken), address(complementToken));
    }

    function changeState(State _newState) internal {
        state = _newState;
        emit StateChanged(state, _newState);
    }

    /// @notice Switch to Settled state if appropriate time threshold is passed and
    /// set underlyingStarts value and set underlyingEnds value,
    /// calculate primaryConversion and complementConversion params
    /// @dev Reverts if underlyingEnds are not available
    /// Vault cannot settle when it paused
    function settle(uint256[] calldata _underlyingEndRoundHints)
        public
        whenNotPaused()
    {
        require(state == State.Live, "Incorrect state");
        require(
            block.timestamp >= (settleTime + settlementDelay),
            "Incorrect time"
        );
        changeState(State.Settled);

        uint256 split;
        (split, underlyingEnds) = collateralSplit.split(
            oracles,
            oracleIterators,
            underlyingStarts,
            settleTime,
            _underlyingEndRoundHints
        );
        split = range(split);

        uint256 collectedCollateral = collateralToken.balanceOf(address(this));
        uint256 mintedPrimaryTokenAmount = primaryToken.totalSupply();

        if (mintedPrimaryTokenAmount > 0) {
            uint256 primaryCollateralPortion = collectedCollateral.mul(split);
            primaryConversion = primaryCollateralPortion.div(
                mintedPrimaryTokenAmount
            );
            complementConversion = collectedCollateral
                .mul(FRACTION_MULTIPLIER)
                .sub(primaryCollateralPortion)
                .div(mintedPrimaryTokenAmount);
        }

        emit SettledStateSet(
            underlyingStarts,
            underlyingEnds,
            primaryConversion,
            complementConversion
        );
    }

    function range(uint256 _split) public pure returns (uint256) {
        if (_split > FRACTION_MULTIPLIER) {
            return FRACTION_MULTIPLIER;
        }
        return _split;
    }

    function performMint(address _recipient, uint256 _collateralAmount)
        internal
    {
        require(state == State.Live, "Live is over");

        require(_collateralAmount > 0, "Zero amount");
        _collateralAmount = doTransferIn(msg.sender, _collateralAmount);

        uint256 feeAmount = withdrawFee(_collateralAmount);

        uint256 netAmount = _collateralAmount.sub(feeAmount);

        uint256 tokenAmount = denominate(netAmount);

        primaryToken.mint(_recipient, tokenAmount);
        complementToken.mint(_recipient, tokenAmount);

        emit Minted(_recipient, tokenAmount, _collateralAmount, feeAmount);
    }

    function mintTo(address _recipient, uint256 _collateralAmount)
        external
        nonReentrant()
    {
        performMint(_recipient, _collateralAmount);
    }

    /// @notice Mints primary and complement derivative tokens
    /// @dev Checks and switches to the right state and does nothing if vault is not in Live state
    function mint(uint256 _collateralAmount) external nonReentrant() {
        performMint(msg.sender, _collateralAmount);
    }

    function performRefund(address _recipient, uint256 _tokenAmount) internal {
        require(_tokenAmount > 0, "Zero amount");
        require(
            _tokenAmount <= primaryToken.balanceOf(msg.sender),
            "Insufficient primary amount"
        );
        require(
            _tokenAmount <= complementToken.balanceOf(msg.sender),
            "Insufficient complement amount"
        );

        primaryToken.burnFrom(msg.sender, _tokenAmount);
        complementToken.burnFrom(msg.sender, _tokenAmount);
        uint256 unDenominated = unDenominate(_tokenAmount);

        emit Refunded(_recipient, _tokenAmount, unDenominated);
        doTransferOut(_recipient, unDenominated);
    }

    /// @notice Refund equal amounts of derivative tokens for collateral at any time
    function refund(uint256 _tokenAmount) external nonReentrant() {
        performRefund(msg.sender, _tokenAmount);
    }

    function refundTo(address _recipient, uint256 _tokenAmount)
        external
        nonReentrant()
    {
        performRefund(_recipient, _tokenAmount);
    }

    function performRedeem(
        address _recipient,
        uint256 _primaryTokenAmount,
        uint256 _complementTokenAmount,
        uint256[] calldata _underlyingEndRoundHints
    ) internal {
        require(
            _primaryTokenAmount > 0 || _complementTokenAmount > 0,
            "Both tokens zero amount"
        );
        require(
            _primaryTokenAmount <= primaryToken.balanceOf(msg.sender),
            "Insufficient primary amount"
        );
        require(
            _complementTokenAmount <= complementToken.balanceOf(msg.sender),
            "Insufficient complement amount"
        );

        if (
            block.timestamp >= (settleTime + settlementDelay) &&
            state == State.Live
        ) {
            settle(_underlyingEndRoundHints);
        }

        if (state == State.Settled) {
            uint collateral = redeemAsymmetric(
                _recipient,
                primaryToken,
                _primaryTokenAmount,
                primaryConversion
            );
            collateral = redeemAsymmetric(
                _recipient,
                complementToken,
                _complementTokenAmount,
                complementConversion
            ).add(collateral);

            if (collateral > 0) {
                doTransferOut(_recipient, collateral);
            }
        }
    }

    function redeemTo(
        address _recipient,
        uint256 _primaryTokenAmount,
        uint256 _complementTokenAmount,
        uint256[] calldata _underlyingEndRoundHints
    ) external nonReentrant() {
        performRedeem(
            _recipient,
            _primaryTokenAmount,
            _complementTokenAmount,
            _underlyingEndRoundHints
        );
    }

    /// @notice Redeems unequal amounts previously calculated conversions if the vault is in Settled state
    function redeem(
        uint256 _primaryTokenAmount,
        uint256 _complementTokenAmount,
        uint256[] calldata _underlyingEndRoundHints
    ) external nonReentrant() {
        performRedeem(
            msg.sender,
            _primaryTokenAmount,
            _complementTokenAmount,
            _underlyingEndRoundHints
        );
    }

    function redeemAsymmetric(
        address _recipient,
        IERC20MintedBurnable _derivativeToken,
        uint256 _amount,
        uint256 _conversion
    ) internal returns(uint256 collateral){
        if (_amount == 0) {
            return 0;
        }

        _derivativeToken.burnFrom(msg.sender, _amount);
        collateral = _amount.mul(_conversion) / FRACTION_MULTIPLIER;
        emit Redeemed(_recipient, address(_derivativeToken),_amount, _conversion, collateral);
    }

    function denominate(uint256 _collateralAmount)
        internal
        view
        returns (uint256)
    {
        return
            _collateralAmount.div(
                derivativeSpecification.primaryNominalValue() +
                    derivativeSpecification.complementNominalValue()
            );
    }

    function unDenominate(uint256 _tokenAmount)
        internal
        view
        returns (uint256)
    {
        return
            _tokenAmount.mul(
                derivativeSpecification.primaryNominalValue() +
                    derivativeSpecification.complementNominalValue()
            );
    }

    function withdrawFee(uint256 _amount) internal returns (uint256) {
        uint256 protocolFeeAmount =
            calcAndTransferFee(_amount, payable(feeWallet), protocolFee);

        feeLogger.log(
            msg.sender,
            address(collateralToken),
            protocolFeeAmount,
            derivativeSpecification.author()
        );

        uint256 authorFee = derivativeSpecification.authorFee();
        if (authorFee > authorFeeLimit) {
            authorFee = authorFeeLimit;
        }
        uint256 authorFeeAmount =
            calcAndTransferFee(
                _amount,
                payable(derivativeSpecification.author()),
                authorFee
            );

        return protocolFeeAmount.add(authorFeeAmount);
    }

    function calcAndTransferFee(
        uint256 _amount,
        address payable _beneficiary,
        uint256 _fee
    ) internal returns (uint256 _feeAmount) {
        _feeAmount = _amount.mul(_fee).div(FRACTION_MULTIPLIER);
        if (_feeAmount > 0) {
            doTransferOut(_beneficiary, _feeAmount);
        }
    }

    /// @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
    /// This will revert due to insufficient balance or insufficient allowance.
    /// This function returns the actual amount received,
    /// which may be less than `amount` if there is a fee attached to the transfer.
    /// @notice This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
    /// See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
    function doTransferIn(address from, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 balanceBefore = collateralToken.balanceOf(address(this));
        EIP20NonStandardInterface(address(collateralToken)).transferFrom(
            from,
            address(this),
            amount
        );

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = collateralToken.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    /// @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
    /// error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
    /// insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
    /// it is >= amount, this should not revert in normal conditions.
    /// @notice This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
    /// See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
    function doTransferOut(address to, uint256 amount) internal {
        EIP20NonStandardInterface(address(collateralToken)).transfer(
            to,
            amount
        );

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

/// @title EIP20NonStandardInterface
/// @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
/// See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
interface EIP20NonStandardInterface {
    /// @notice Get the total number of tokens in circulation
    /// @return The supply of tokens
    function totalSupply() external view returns (uint256);

    /// @notice Gets the balance of the specified address
    /// @param owner The address from which the balance will be retrieved
    /// @return balance The balance
    function balanceOf(address owner) external view returns (uint256 balance);

    //
    // !!!!!!!!!!!!!!
    // !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    // !!!!!!!!!!!!!!
    //

    /// @notice Transfer `amount` tokens from `msg.sender` to `dst`
    /// @param dst The address of the destination account
    /// @param amount The number of tokens to transfer
    function transfer(address dst, uint256 amount) external;

    //
    // !!!!!!!!!!!!!!
    // !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    // !!!!!!!!!!!!!!
    //

    /// @notice Transfer `amount` tokens from `src` to `dst`
    /// @param src The address of the source account
    /// @param dst The address of the destination account
    /// @param amount The number of tokens to transfer
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external;

    /// @notice Approve `spender` to transfer up to `amount` from `src`
    /// @dev This will overwrite the approval amount for `spender`
    ///  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
    /// @param spender The address of the account which may transfer tokens
    /// @param amount The number of tokens that are approved
    /// @return success Whether or not the approval succeeded
    function approve(address spender, uint256 amount)
        external
        returns (bool success);

    /// @notice Get the current allowance from `owner` for `spender`
    /// @param owner The address of the account which owns the tokens to be spent
    /// @param spender The address of the account which may transfer tokens
    /// @return remaining The number of tokens allowed to be spent
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

/// @title Derivative Specification interface
/// @notice Immutable collection of derivative attributes
/// @dev Created by the derivative's author and published to the DerivativeSpecificationRegistry
interface IDerivativeSpecification {
    /// @notice Proof of a derivative specification
    /// @dev Verifies that contract is a derivative specification
    /// @return true if contract is a derivative specification
    function isDerivativeSpecification() external pure returns (bool);

    /// @notice Set of oracles that are relied upon to measure changes in the state of the world
    /// between the start and the end of the Live period
    /// @dev Should be resolved through OracleRegistry contract
    /// @return oracle symbols
    function oracleSymbols() external view returns (bytes32[] memory);

    /// @notice Algorithm that, for the type of oracle used by the derivative,
    /// finds the value closest to a given timestamp
    /// @dev Should be resolved through OracleIteratorRegistry contract
    /// @return oracle iterator symbols
    function oracleIteratorSymbols() external view returns (bytes32[] memory);

    /// @notice Type of collateral that users submit to mint the derivative
    /// @dev Should be resolved through CollateralTokenRegistry contract
    /// @return collateral token symbol
    function collateralTokenSymbol() external view returns (bytes32);

    /// @notice Mapping from the change in the underlying variable (as defined by the oracle)
    /// and the initial collateral split to the final collateral split
    /// @dev Should be resolved through CollateralSplitRegistry contract
    /// @return collateral split symbol
    function collateralSplitSymbol() external view returns (bytes32);

    /// @notice Lifecycle parameter that define the length of the derivative's Live period.
    /// @dev Set in seconds
    /// @return live period value
    function livePeriod() external view returns (uint256);

    /// @notice Parameter that determines starting nominal value of primary asset
    /// @dev Units of collateral theoretically swappable for 1 unit of primary asset
    /// @return primary nominal value
    function primaryNominalValue() external view returns (uint256);

    /// @notice Parameter that determines starting nominal value of complement asset
    /// @dev Units of collateral theoretically swappable for 1 unit of complement asset
    /// @return complement nominal value
    function complementNominalValue() external view returns (uint256);

    /// @notice Minting fee rate due to the author of the derivative specification.
    /// @dev Percentage fee multiplied by 10 ^ 12
    /// @return author fee
    function authorFee() external view returns (uint256);

    /// @notice Symbol of the derivative
    /// @dev Should be resolved through DerivativeSpecificationRegistry contract
    /// @return derivative specification symbol
    function symbol() external view returns (string memory);

    /// @notice Return optional long name of the derivative
    /// @dev Isn't used directly in the protocol
    /// @return long name
    function name() external view returns (string memory);

    /// @notice Optional URI to the derivative specs
    /// @dev Isn't used directly in the protocol
    /// @return URI to the derivative specs
    function baseURI() external view returns (string memory);

    /// @notice Derivative spec author
    /// @dev Used to set and receive author's fee
    /// @return address of the author
    function author() external view returns (address);
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

/// @title Collateral Split interface
/// @notice Contains mathematical functions used to calculate relative claim
/// on collateral of primary and complement assets after settlement.
/// @dev Created independently from specification and published to the CollateralSplitRegistry
interface ICollateralSplit {
    /// @notice Proof of collateral split contract
    /// @dev Verifies that contract is a collateral split contract
    /// @return true if contract is a collateral split contract
    function isCollateralSplit() external pure returns (bool);

    /// @notice Symbol of the collateral split
    /// @dev Should be resolved through CollateralSplitRegistry contract
    /// @return collateral split specification symbol
    function symbol() external pure returns (string memory);

    /// @notice Calcs primary asset class' share of collateral at settlement.
    /// @dev Returns ranged value between 0 and 1 multiplied by 10 ^ 12
    /// @param _underlyingStarts underlying values in the start of Live period
    /// @param _underlyingEndRoundHints specify for each oracle round of the end of Live period
    /// @return _split primary asset class' share of collateral at settlement
    /// @return _underlyingEnds underlying values in the end of Live period
    function split(
        address[] calldata _oracles,
        address[] calldata _oracleIterators,
        int256[] calldata _underlyingStarts,
        uint256 _settleTime,
        uint256[] calldata _underlyingEndRoundHints
    ) external view returns (uint256 _split, int256[] memory _underlyingEnds);
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20MintedBurnable is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

import "./IERC20MintedBurnable.sol";
import "../IDerivativeSpecification.sol";

interface ITokenBuilder {
    function isTokenBuilder() external pure returns (bool);

    function buildTokens(
        IDerivativeSpecification derivative,
        uint256 settlement,
        address _collateralToken
    ) external returns (IERC20MintedBurnable, IERC20MintedBurnable);
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

interface IFeeLogger {
    function log(
        address _liquidityProvider,
        address _collateral,
        uint256 _protocolFee,
        address _author
    ) external;
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

interface IPausableVault {
    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}