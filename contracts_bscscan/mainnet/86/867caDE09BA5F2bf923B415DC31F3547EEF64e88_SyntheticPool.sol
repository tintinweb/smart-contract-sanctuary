// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../Interfaces/ITWAP.sol";
import "../Interfaces/ICustomToken.sol";
import "./CollateralReserve.sol";

contract SyntheticPool is AccessControlUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 private constant MAINTAINER = keccak256("MAINTAINER");
    bytes32 private constant PAUSER = keccak256("PAUSER");

    // Core
    CollateralReserve public collateralReserve;

    // Token
    ICustomToken public share; // Super Dop
    ICustomToken public synth; // Synthetic
    IERC20 public collateralToken; // Stablecoin

    // Oracles
    ITWAP public synthTWAP;

    mapping(address => uint256) public lastAction;

    // Fee
    uint256 public mintingFee;
    uint256 public redemptionFee;
    uint256 public constant MAX_FEE = 5e16; // 5%

    // Constants for various precisions
    uint256 public constant PRICE_PRECISION = 1e18;
    uint256 public constant COLLATERAL_RATIO_PRECISION = 1e18;
    uint256 public constant COLLATERAL_RATIO_MAX = 1e18;
    uint256 public constant FEE_PRECISION = 1e18;

    // Flash loan & Reentrancy prevention
    uint256 public actionDelay;

    // AccessControl state variables
    bool public mintPaused;
    bool public redeemPaused;

    modifier notRedeemPaused() {
        require(redeemPaused == false, "Redeeming is paused");
        _;
    }

    modifier notMintPaused() {
        require(mintPaused == false, "Minting is paused");
        _;
    }

    function initialize(
        address _collateralReserve,
        address _collateralToken,
        address _synth,
        address _synthTWAP,
        address _share,
        address _owner
    ) public initializer {
        collateralReserve = CollateralReserve(_collateralReserve);
        collateralToken = IERC20(_collateralToken);
        synth = ICustomToken(_synth);
        synthTWAP = ITWAP(_synthTWAP);
        share = ICustomToken(_share);

        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        grantRole(MAINTAINER, _owner);

        actionDelay = 1; // Number of blocks to wait before being able to call mint or redeem
        mintPaused = true;
        redeemPaused = true;
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Returns the price of the pool collateral in USD
    function getCollateralPrice() public view returns (uint256) {
        return
            ITWAP(collateralReserve.oracleOf(address(collateralToken))).consult(
                address(collateralToken),
                1e18
            );
    }

    function getSynthPrice() public view returns (uint256) {
        return synthTWAP.consult(address(synth), 1e18);
    }

    // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency
    function mint1t1Synth(uint256 colAmount, uint256 synthOutMin)
        external
        notMintPaused
    {
        require(block.number >= lastAction[msg.sender].add(actionDelay));
        require(
            collateralReserve.globalCollateralRatio() >= COLLATERAL_RATIO_MAX,
            "Collateral ratio must be >= 1"
        );

        uint256 _synthAmount = colAmount.mul(getCollateralPrice()).div(
            getSynthPrice()
        );

        uint256 _synthAmountReceive = _synthAmount
            .mul(FEE_PRECISION.sub(mintingFee))
            .div(FEE_PRECISION);
        require(synthOutMin <= _synthAmountReceive, "Slippage limit reached");

        uint256 _fee = _synthAmount.sub(_synthAmountReceive);

        lastAction[msg.sender] = block.number;

        collateralToken.safeTransferFrom(
            msg.sender,
            address(collateralReserve),
            colAmount
        );

        synth.mint(msg.sender, _synthAmountReceive);
        synth.mint(address(this), _fee);
    }

    // 0% collateral-backed
    function mintAlgorithmicSynth(uint256 shareAmount, uint256 synthOutMin)
        external
        notMintPaused
    {
        require(block.number >= lastAction[msg.sender].add(actionDelay));
        require(share.balanceOf(msg.sender) >= shareAmount, "No enough Share");
        require(
            collateralReserve.globalCollateralRatio() == 0,
            "Collateral ratio must be 0"
        );

        uint256 _synthAmount = shareAmount
            .mul(collateralReserve.getSharePrice())
            .div(getSynthPrice());

        uint256 _synthAmountReceive = _synthAmount
            .mul(FEE_PRECISION.sub(mintingFee))
            .div(FEE_PRECISION);
        require(synthOutMin <= _synthAmountReceive, "Slippage limit reached");

        uint256 _fee = _synthAmount.sub(_synthAmountReceive);

        lastAction[msg.sender] = block.number;

        share.burnFrom(msg.sender, shareAmount);
        synth.mint(msg.sender, _synthAmountReceive);
        synth.mint(address(this), _fee);
    }

    // Will fail if fully collateralized or fully algorithmic
    // > 0% and < 100% collateral-backed
    function mintFractionalSynth(
        uint256 _collateralAmount,
        uint256 _shareAmount,
        uint256 _synthOutMin
    ) external notMintPaused {
        require(block.number >= lastAction[msg.sender].add(actionDelay));

        uint256 _sharePrice = collateralReserve.getSharePrice();
        uint256 _collateralPrice = getCollateralPrice();
        uint256 _synthPrice = getSynthPrice();
        uint256 _globalCollateralRatio = collateralReserve
            .globalCollateralRatio();

        require(
            _globalCollateralRatio < COLLATERAL_RATIO_MAX &&
                _globalCollateralRatio > 0,
            "Collateral ratio must not be 100% or 0%"
        );

        require(share.balanceOf(msg.sender) >= _shareAmount, "No enough Share");

        uint256 _collateralValue = _collateralAmount.mul(_collateralPrice);
        uint256 _shareNeeded = COLLATERAL_RATIO_MAX
            .sub(_globalCollateralRatio)
            .mul(_collateralValue)
            .div(_globalCollateralRatio.mul(_sharePrice));

        uint256 _totalDepositValue = _collateralValue.add(
            _shareNeeded.mul(_sharePrice)
        );

        uint256 _synthAmount = _totalDepositValue
            .mul(PRICE_PRECISION)
            .div(_synthPrice)
            .div(PRICE_PRECISION);

        uint256 _synthAmountReceive = _synthAmount
            .mul(FEE_PRECISION.sub(mintingFee))
            .div(FEE_PRECISION);
        require(_synthOutMin <= _synthAmountReceive, "Slippage limit reached");
        require(_shareNeeded <= _shareAmount, "Not enough Share inputted");

        uint256 _fee = _synthAmount.sub(_synthAmountReceive);

        lastAction[msg.sender] = block.number;

        share.burnFrom(msg.sender, _shareNeeded);
        collateralToken.safeTransferFrom(
            msg.sender,
            address(collateralReserve),
            _collateralAmount
        );
        synth.mint(msg.sender, _synthAmountReceive);
        synth.mint(address(this), _fee);
    }

    // Redeem collateral. 100% collateral-backed
    function redeem1t1Synth(
        uint256 _synthAmount,
        uint256 _minCollateralAmountOut
    ) external notRedeemPaused {
        require(block.number >= lastAction[msg.sender].add(actionDelay));
        require(
            collateralReserve.getECR() == COLLATERAL_RATIO_MAX,
            "Collateral ratio must be == 1"
        );
        require(synth.balanceOf(msg.sender) >= _synthAmount, "No enough synth");

        uint256 _collateralNeeded = _synthAmount.mul(getSynthPrice()).div(
            getCollateralPrice()
        );

        uint256 _collateralReceived = (
            _collateralNeeded.mul(PRICE_PRECISION.sub(redemptionFee))
        ).div(PRICE_PRECISION);

        require(
            _collateralReceived <=
                collateralToken.balanceOf(address(collateralReserve)),
            "Not enough collateral in pool"
        );
        require(
            _minCollateralAmountOut <= _collateralReceived,
            "Slippage limit reached"
        );

        uint256 _fee = _collateralNeeded.sub(_collateralReceived);

        lastAction[msg.sender] = block.number;

        // Move all external functions to the end
        collateralReserve.requestTransfer(
            msg.sender,
            address(collateralToken),
            _collateralReceived
        );

        collateralReserve.requestTransfer(
            address(this),
            address(collateralToken),
            _fee
        );

        synth.burnFrom(msg.sender, _synthAmount);
    }

    // Redeem Synth for Share. 0% collateral-backed
    function redeemAlgorithmicSynth(uint256 _synthAmount, uint256 _shareOutMin)
        external
        notRedeemPaused
    {
        require(block.number >= lastAction[msg.sender].add(actionDelay));
        require(synth.balanceOf(msg.sender) >= _synthAmount, "No enough synth");

        uint256 _ecr = collateralReserve.getECR();
        require(_ecr == 0, "Collateral ratio must be 0");

        uint256 _sharePrice = collateralReserve.getSharePrice();
        uint256 _synthPrice = getSynthPrice();

        uint256 _synthDollarValue = _synthAmount.mul(_synthPrice).div(
            PRICE_PRECISION
        );

        uint256 _shareAmount = _synthDollarValue.mul(PRICE_PRECISION).div(
            _sharePrice
        );

        uint256 _shareReceived = _shareAmount
            .mul(FEE_PRECISION.sub(redemptionFee))
            .div(FEE_PRECISION);

        lastAction[msg.sender] = block.number;

        require(_shareOutMin <= _shareReceived, "Slippage limit reached");

        // Move all external functions to the end
        synth.burnFrom(msg.sender, _synthAmount);
        share.mint(msg.sender, _shareReceived);
    }

    // Will fail if fully collateralized or algorithmic
    // Redeem Synth for collateral and Share. > 0% and < 100% collateral-backed
    function redeemFractionalSynth(
        uint256 _synthAmount,
        uint256 _shareOutMin,
        uint256 _minCollateralAmountOut
    ) external notRedeemPaused {
        require(block.number >= lastAction[msg.sender].add(actionDelay));
        require(synth.balanceOf(msg.sender) >= _synthAmount, "No enough synth");

        uint256 _ecr = collateralReserve.getECR();

        require(
            _ecr < COLLATERAL_RATIO_MAX && _ecr > 0,
            "Collateral ratio needs to be lower than 100% or higher than 0%"
        );

        uint256 _sharePrice = collateralReserve.getSharePrice();
        uint256 _synthPrice = getSynthPrice();
        uint256 _collateralPrice = getCollateralPrice();

        uint256 _synthAmountPostFee = (
            _synthAmount.mul(FEE_PRECISION.sub(redemptionFee))
        ).div(FEE_PRECISION);

        uint256 _synthDollarValue = _synthAmountPostFee.mul(_synthPrice).div(
            PRICE_PRECISION
        );

        uint256 _fee = _synthAmount.sub(_synthAmountPostFee);

        uint256 _shareReceived = _synthDollarValue
            .mul(COLLATERAL_RATIO_PRECISION.sub(_ecr))
            .div(_sharePrice);

        uint256 _collateralReceived = _synthDollarValue.mul(_ecr).div(
            _collateralPrice
        );

        require(
            _collateralReceived <=
                collateralToken.balanceOf(address(collateralReserve)),
            "Not enough collateral in pool"
        );
        require(
            _minCollateralAmountOut <= _collateralReceived,
            "Slippage limit reached [Collateral]"
        );

        require(
            _shareOutMin <= _shareReceived,
            "Slippage limit reached [Share]"
        );

        lastAction[msg.sender] = block.number;

        // Move all external functions to the end
        synth.burnFrom(msg.sender, _synthAmount);
        synth.mint(address(this), _fee);
        share.mint(msg.sender, _shareReceived);
        collateralReserve.requestTransfer(
            msg.sender,
            address(collateralToken),
            _collateralReceived
        );
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function toggleMinting() external {
        require(hasRole(PAUSER, msg.sender), "Caller is not a pauser");
        mintPaused = !mintPaused;

        emit MintingToggled(mintPaused);
    }

    function toggleRedeeming() external {
        require(hasRole(PAUSER, msg.sender), "Caller is not a pauser");
        redeemPaused = !redeemPaused;

        emit RedeemingToggled(redeemPaused);
    }

    function setActionDelay(uint256 _newDelay) external {
        require(hasRole(MAINTAINER, msg.sender), "Caller is not a maintainer");
        require(_newDelay > 0, "Delay should not be zero");
        actionDelay = _newDelay;
    }

    function setMintingFee(uint256 _new) external {
        require(hasRole(MAINTAINER, msg.sender), "Caller is not a maintainer");
        require(_new <= MAX_FEE, "The new fee is too high");
        mintingFee = _new;
        emit SetMintingFee(mintingFee);
    }

    function setRedemptionFee(uint256 _new) external {
        require(hasRole(MAINTAINER, msg.sender), "Caller is not a maintainer");
        require(_new <= MAX_FEE, "The new fee is too high");
        redemptionFee = _new;
        emit SetRedemptionFee(redemptionFee);
    }

    function withdrawFee() external {
        require(hasRole(MAINTAINER, msg.sender), "Caller is not a maintainer");
        collateralToken.transfer(
            msg.sender,
            collateralToken.balanceOf(address(this))
        );
        synth.transfer(msg.sender, synth.balanceOf(address(this)));
        share.transfer(msg.sender, share.balanceOf(address(this)));
    }

    function setCollateralReserve(address _collateralReserve) external {
        require(hasRole(MAINTAINER, msg.sender), "Caller is not a maintainer");
        collateralReserve = CollateralReserve(_collateralReserve);
    }

    function setSynthTWAP(address _synthTWAP) external {
        require(hasRole(MAINTAINER, msg.sender), "Caller is not a maintainer");
        synthTWAP = ITWAP(_synthTWAP);
    }

    /* ========== EVENTS ========== */

    event MintingToggled(bool toggled);
    event RedeemingToggled(bool toggled);
    event CollateralPriceToggled(bool toggled);
    event SetMintingFee(uint256 newFee);
    event SetRedemptionFee(uint256 newFee);

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ITWAP {
    function consult(address _token, uint256 _amountIn)
        external
        view
        returns (uint256 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ICustomToken {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

    function mint(address to, uint256 _amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function getSynthPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";



import "../Interfaces/ITWAP.sol";
import "../Interfaces/ITreasuryVault.sol";
import "./SyntheticPool.sol";
import "./Synth.sol";
import "./TWX.sol";

contract CollateralReserve is AccessControlUpgradeable {
    bytes32 private constant MAINTAINER = keccak256("MAINTAINER");
    bytes32 private constant RATIO_SETTER = keccak256("RATIO_SETTER");
    bytes32 private constant PAUSER = keccak256("PAUSER");
    bytes32 private constant POOL = keccak256("POOL");

    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using SafeERC20 for IERC20;

    address public feeCollector;

    /* ========== COLLATERAL ========== */
    // List of allowed collateral
    address[] public collateralAddressArray;
    // Check existing of collateral
    mapping(address => bool) public collateralAddress;

    /* ========== ORACLE ========== */
    // List of oracle
    address[] public oracleArray;

    // Check existing of oracle
    mapping(address => bool) public oracleExist;

    // oracleOf(ERC20()) => TWAP Address
    mapping(address => address) public oracleOf;

    /* ========== Synthetic Pools ========== */
    // list of synth pool
    address[] public synthPoolArray;
    // Check existing of synthetic pool
    mapping(address => bool) public synthPoolExist;

    // list of synth token
    address[] public synthArray;
    // Check existing of synthetic token
    mapping(address => bool) public synthExists;

    // Enable and disable pool
    mapping(address => bool) public enabledPool;

    // Global collateral target, set by growth ratio
    uint256 public globalCollateralRatio;

    // Growth ratio calculation and ratio setter (stepUp, stepDown)
    address public pidController;

    address[] public poolArrays;

    uint256 public refreshCooldown; // Seconds to wait before being able to run refreshCollateralRatio()
    uint256 public lastCallTime;

    uint256 public constant PRICE_PRECISION = 1e18;
    uint256 public constant RATIO_PRECISION = 1e18;
    uint256 public constant RATIO_UPPER_BOUND = 1e18; //100%
    uint256 public constant RATIO_LOWER_BOUND = 0; //0%
    uint256 public constant MAX_FEE = 5e16; // 5%
    uint256 private constant FEE_PRECISION = 1e18;

    uint256 public bonusRate;
    uint256 public ratioDelta; // Should initially be 25e15 or 0.25%
    uint256 public buybackFee;
    uint256 public recollatFee;
    bool public recollateralizePaused;
    bool public buyBackPaused;

    /* ========== Investment ========== */
    address[] public vaults;
    uint256 public investCollateralRatio;

    ICustomToken public share;
    ITWAP public shareTWAP;

    function initialize(
        address _owner,
        address _pidController,
        address _share,
        address _shareTWAP,
        address _feeCollector
    ) public initializer {
        ratioDelta = 25e14; // 0.25%
        bonusRate = 75e14; // 0.75%
        refreshCooldown = 0;
        globalCollateralRatio = 1e18; // 100%
        pidController = _pidController;
        feeCollector = _feeCollector;

        share = ICustomToken(_share);
        shareTWAP = ITWAP(_shareTWAP);

        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        grantRole(MAINTAINER, _owner);
        setPIDController(_pidController);

        recollateralizePaused = true;
        buyBackPaused = true;
        investCollateralRatio = 7e17; // 70%
    }

    function globalCollateralValue() public view returns (uint256 _tcv) {
        for (uint256 i = 0; i < collateralAddressArray.length; i++) {
            // Exclude null addresses
            if (collateralAddressArray[i] != address(0)) {
                uint256 _totalBalance = IERC20(collateralAddressArray[i])
                    .balanceOf(address(this));

                uint256 _price = ITWAP(oracleOf[collateralAddressArray[i]])
                    .consult(collateralAddressArray[i], 1e18);

                _tcv = _tcv.add(_totalBalance.mul(_price).div(PRICE_PRECISION));
            }
        }

        for (uint256 i = 0; i < vaults.length; i++) {
            if (vaults[i] != address(0)) {
                ITreasuryVault vault = ITreasuryVault(vaults[i]);

                uint256 _totalBalance = vault.vaultBalance();

                address _asset = vault.asset();

                uint256 _price = ITWAP(oracleOf[_asset]).consult(_asset, 1e18);

                _tcv = _tcv.add(_totalBalance.mul(_price).div(PRICE_PRECISION));
            }
        }
    }

    function totalGlobalSynthValue() public view returns (uint256 _tgsv) {
        for (uint256 i = 0; i < synthArray.length; i++) {
            if (synthArray[i] != address(0)) {
                uint256 _totalSupply = IERC20(synthArray[i]).totalSupply();
                uint256 _price = Synth(synthArray[i]).getSynthPrice();
                _tgsv = _tgsv.add(
                    _totalSupply.mul(_price).div(PRICE_PRECISION)
                );
            }
        }
    }

    function getECR() public view returns (uint256) {
        uint256 collateralValue = globalCollateralValue();
        uint256 marketCap = totalGlobalSynthValue();
        return collateralValue.mul(PRICE_PRECISION).div(marketCap);
    }

    function getCollateralTokenValue(address _collateralToken)
        public
        view
        returns (uint256)
    {
        return IERC20(_collateralToken).balanceOf(address(this)); //TODO + vault[col]
    }

    // Returns the price of the pool collateral in USD
    function getSharePrice() public view returns (uint256) {
        return ITWAP(shareTWAP).consult(address(share), 1e18);
    }

    // Function can be called by an Share holder to have the protocol buy back Share with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackShare(
        uint256 _shareAmount,
        uint256 _collateralOutMin,
        address _collateralToken
    ) external {
        require(buyBackPaused == false, "Buyback is paused");
        require(share.balanceOf(msg.sender) >= _shareAmount, "No enough Share");

        uint256 excessCollateralBalance = excessCollateralBalance(
            _collateralToken
        );

        require(
            excessCollateralBalance > 0,
            "No excess collateral to buy back!"
        );

        uint256 _sharePrice = getSharePrice();
        uint256 _requireShareValue = _shareAmount.mul(_sharePrice).div(
            PRICE_PRECISION
        );

        uint256 _collateralPrice = ITWAP(oracleOf[_collateralToken]).consult(
            _collateralToken,
            1e18
        );

        uint256 _collateralEquivalent = _shareAmount.mul(_sharePrice).div(
            _collateralPrice
        );

        uint256 _excessCollateralValue = excessCollateralBalance
            .mul(_collateralPrice)
            .div(PRICE_PRECISION);

        require(
            _requireShareValue <= _excessCollateralValue,
            "Buyback over excess balance"
        );

        uint256 _collateralEquivalentReceived = _collateralEquivalent
            .mul(FEE_PRECISION.sub(buybackFee))
            .div(FEE_PRECISION);

        require(
            IERC20(_collateralToken).balanceOf(address(this)) >=
                _collateralEquivalentReceived,
            "Not enough available excess collateral token"
        );

        uint256 _fee = _collateralEquivalent.sub(_collateralEquivalentReceived);

        require(
            _collateralOutMin <= _collateralEquivalentReceived,
            "Slippage limit reached"
        );

        share.burnFrom(msg.sender, _shareAmount);
        IERC20(_collateralToken).transfer(
            msg.sender,
            _collateralEquivalentReceived
        );
        IERC20(_collateralToken).transfer(feeCollector, _fee);
    }

    function excessCollateralBalance(address _collateralToken)
        public
        view
        returns (uint256 _totalExcess)
    {
        uint256 _tcr = globalCollateralRatio;
        uint256 _ecr = getECR();
        if (_ecr <= _tcr) {
            return 0;
        }

        uint256 _collateralPrice = ITWAP(oracleOf[_collateralToken]).consult(
            _collateralToken,
            1e18
        );

        uint256 _targetCollateralValue = totalGlobalSynthValue().mul(_tcr).div(
            PRICE_PRECISION
        );

        uint256 _collateralValueExcess = globalCollateralValue().sub(
            _targetCollateralValue
        );

        _totalExcess = _collateralValueExcess.mul(PRICE_PRECISION).div(
            _collateralPrice
        );
    }

    function getMaxBuybackShare(address _collateralToken)
        external
        view
        returns (uint256 _maxShare)
    {
        uint256 _excessCollateralBalance = excessCollateralBalance(
            _collateralToken
        );

        uint256 _collateralPrice = ITWAP(oracleOf[_collateralToken]).consult(
            _collateralToken,
            1e18
        );

        uint256 _excessCollateralValue = _excessCollateralBalance
            .mul(_collateralPrice)
            .div(PRICE_PRECISION);

        uint256 _excessCollateralValuePostFee = _excessCollateralValue
            .mul(RATIO_PRECISION.sub(buybackFee))
            .div(RATIO_PRECISION);

        uint256 _multiplier = _excessCollateralValue.mul(RATIO_PRECISION).div(
            _excessCollateralValuePostFee
        );

        uint256 _sharePrice = getSharePrice();

        _maxShare = _excessCollateralValue.mul(_multiplier).div(_sharePrice);
    }

    function recollateralizeAmount(address _collateralToken)
        public
        view
        returns (uint256 _collateralNeeded)
    {
        uint256 _ecr = getECR();
        uint256 _tcr = globalCollateralRatio;

        if (_tcr <= _ecr) {
            return 0;
        }

        uint256 _collateralPrice = ITWAP(oracleOf[_collateralToken]).consult(
            _collateralToken,
            1e18
        );

        uint256 _targetCollateralValue = totalGlobalSynthValue().mul(_tcr).div(
            PRICE_PRECISION
        );

        uint256 _collateralValueNeeded = _targetCollateralValue.sub(
            globalCollateralValue()
        );

        _collateralNeeded = _collateralValueNeeded.mul(PRICE_PRECISION).div(
            _collateralPrice
        );
    }

    // When the protocol is recollateralizing, we need to give a discount of Share to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get Share for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of Share + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra Share value from the bonus rate as an arb opportunity
    function recollateralizeShare(
        address _collateralToken,
        uint256 _collateralAmount,
        uint256 _shareOutMin
    ) external {
        require(recollateralizePaused == false, "Recollateralize is paused");

        uint256 _collateralPrice = ITWAP(oracleOf[_collateralToken]).consult(
            _collateralToken,
            1e18
        );

        uint256 _recollateralizeValue = recollateralizeAmount(_collateralToken)
            .mul(_collateralPrice)
            .div(PRICE_PRECISION);

        require(_recollateralizeValue > 0, "insufficient collateral");

        uint256 _requestCollateralValue = ITWAP(oracleOf[_collateralToken])
            .consult(_collateralToken, 1e18)
            .mul(_collateralAmount)
            .div(PRICE_PRECISION);

        require(
            _requestCollateralValue <= _recollateralizeValue,
            "Request recollateralize over limit"
        );

        uint256 _sharePaidBack = _requestCollateralValue
            .mul(PRICE_PRECISION.add(bonusRate))
            .div(getSharePrice());

        uint256 _sharePaidBackReceived = _sharePaidBack
            .mul(FEE_PRECISION.sub(recollatFee))
            .div(FEE_PRECISION);

        require(
            _shareOutMin <= _sharePaidBackReceived,
            "Slippage limit reached"
        );

        uint256 _fee = _sharePaidBack.sub(_sharePaidBackReceived);

        IERC20(_collateralToken).safeTransferFrom(
            msg.sender,
            address(this),
            _collateralAmount
        );
        share.mint(msg.sender, _sharePaidBackReceived);
        share.mint(feeCollector, _fee);
    }

    /* ========== Roles ========== */
    function setPIDController(address _pidController) public {
        require(hasRole(MAINTAINER, msg.sender));
        grantRole(RATIO_SETTER, _pidController);
        pidController = _pidController;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setFeeCollector(address _newFeeCollector) external {
        require(hasRole(MAINTAINER, msg.sender));
        feeCollector = _newFeeCollector;
    }

    function setBonusRate(uint256 _newBonusRate) external {
        require(hasRole(MAINTAINER, msg.sender));
        bonusRate = _newBonusRate;
    }

    function setBuybackFee(uint256 _newBuybackFee) external {
        require(hasRole(MAINTAINER, msg.sender));
        require(_newBuybackFee <= MAX_FEE, "The new fee is to high");
        buybackFee = _newBuybackFee;
        emit SetBuybackFee(buybackFee);
    }

    function setRecollatFee(uint256 _newRecollatFee) external {
        require(hasRole(MAINTAINER, msg.sender));
        require(_newRecollatFee <= MAX_FEE, "The new fee is to high");
        recollatFee = _newRecollatFee;
        emit SetRecollatFee(recollatFee);
    }

    function toggleRecollateralize() external {
        require(hasRole(PAUSER, msg.sender));
        recollateralizePaused = !recollateralizePaused;

        emit RecollateralizeToggled(recollateralizePaused);
    }

    function toggleBuyBack() external {
        require(hasRole(PAUSER, msg.sender));
        buyBackPaused = !buyBackPaused;

        emit BuybackToggled(buyBackPaused);
    }

    function setShareTWAP(address _new) external {
        require(hasRole(MAINTAINER, msg.sender));
        shareTWAP = ITWAP(_new);
    }

    function requestTransfer(
        address _receiver,
        address _token,
        uint256 _amount
    ) external {
        require(hasRole(POOL, msg.sender), "Sender is not a pool");
        IERC20(_token).transfer(_receiver, _amount);
    }

    function setRefreshCooldown(uint256 newCooldown) external {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        refreshCooldown = newCooldown;
    }

    // Adds collateral addresses supported, such as tether and busd, must be ERC20
    function addCollateralAddress(
        address _collateralTokenAddress,
        address _oracle
    ) external {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        require(_collateralTokenAddress != address(0), "Zero address detected");

        require(
            collateralAddress[_collateralTokenAddress] == false,
            "Address already exists"
        );

        require(oracleExist[_oracle], "Oracle is not exists");

        collateralAddress[_collateralTokenAddress] = true;
        collateralAddressArray.push(_collateralTokenAddress);
        oracleOf[_collateralTokenAddress] = _oracle;

        emit AddCollateralToken(_collateralTokenAddress);
    }

    function addOracle(address _oracle) external {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        require(_oracle != address(0), "Zero address detected");

        require(oracleExist[_oracle] == false, "Address already exists");

        oracleExist[_oracle] = true;
        oracleArray.push(_oracle);

        emit AddOracle(_oracle);
    }

    function setOracleOf(address _token, address _oracle) external {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        require(_oracle != address(0), "Zero address detected");

        oracleOf[_token] = _oracle;
    }

    function addPool(address poolAddress) external {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        require(poolAddress != address(0), "Zero address detected");

        require(synthPoolExist[poolAddress] == false, "Address already exists");
        synthPoolExist[poolAddress] = true;
        synthPoolArray.push(poolAddress);

        grantRole(POOL, poolAddress);

        emit PoolAdded(poolAddress);
    }

    function addSynth(address _synthAddress) external {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        require(_synthAddress != address(0), "Zero address detected");

        require(synthExists[_synthAddress] == false, "Address already exists");
        synthExists[_synthAddress] = true;
        synthArray.push(_synthAddress);

        emit AddSynthToken(_synthAddress);
    }

    // Remove a pool
    function removePool(address poolAddress) public {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        require(poolAddress != address(0), "Zero address detected");
        require(synthPoolExist[poolAddress] == true, "Address nonexistant");

        // Delete from the mapping
        delete synthPoolExist[poolAddress];

        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < synthPoolArray.length; i++) {
            if (synthPoolArray[i] == poolAddress) {
                synthPoolArray[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        revokeRole(POOL, poolAddress);

        emit PoolRemoved(poolAddress);
    }

    function removeCollateral(address _collateralAddress) public {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        require(_collateralAddress != address(0), "Zero address detected");
        require(
            collateralAddress[_collateralAddress] == true,
            "Address nonexistant"
        );

        // Delete from the mapping
        delete collateralAddress[_collateralAddress];

        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < collateralAddressArray.length; i++) {
            if (collateralAddressArray[i] == _collateralAddress) {
                collateralAddressArray[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        // also remove oracle of this token
        if (oracleOf[_collateralAddress] != address(0)) {
            removeOracle(oracleOf[_collateralAddress]);
        }

        emit CollateralTokenRemoved(_collateralAddress);
    }

    function removeSynth(address synthAddress) public {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        require(synthAddress != address(0), "Zero address detected");
        require(synthExists[synthAddress] == true, "Address nonexistant");

        // Delete from the mapping
        delete synthExists[synthAddress];

        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < synthArray.length; i++) {
            if (synthArray[i] == synthAddress) {
                synthArray[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit SynthTokenRemoved(synthAddress);
    }

    function removeOracle(address oracleAddress) public {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        require(oracleAddress != address(0), "Zero address detected");
        require(oracleExist[oracleAddress] == true, "Address nonexistant");

        // Delete from the mapping
        delete oracleExist[oracleAddress];

        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < oracleArray.length; i++) {
            if (oracleArray[i] == oracleAddress) {
                oracleArray[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit OracleRemoved(oracleAddress);
    }

    function toggleEnablePool(address _pool) external {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        enabledPool[_pool] = !enabledPool[_pool];
    }

    function setRatioDelta(uint256 _delta) external {
        require(hasRole(RATIO_SETTER, msg.sender));
        require(
            block.timestamp - lastCallTime >= refreshCooldown,
            "Must wait for the refresh cooldown since last refresh"
        );
        ratioDelta = _delta;
    }

    function setGlobalCollateralRatio(uint256 newRatio) external {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        require(
            newRatio <= RATIO_UPPER_BOUND && newRatio >= RATIO_LOWER_BOUND,
            "New ratio exceed bound"
        );
        globalCollateralRatio = newRatio;
        lastCallTime = block.timestamp; // Set the time of the last expansion

        emit SetGlobalCollateralRatio(globalCollateralRatio);
    }

    function setInvestCollateralRatio(uint256 _investCollateralRatio) external {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        investCollateralRatio = _investCollateralRatio;

        emit SetInvestCollateralRatio(investCollateralRatio);
    }

    function stepUpTCR() external {
        require(
            hasRole(RATIO_SETTER, msg.sender),
            "Sender is not a ratio setter"
        );
        require(
            block.timestamp - lastCallTime >= refreshCooldown,
            "Must wait for the refresh cooldown since last refresh"
        );

        globalCollateralRatio = globalCollateralRatio.add(ratioDelta);

        if (globalCollateralRatio > RATIO_UPPER_BOUND) {
            globalCollateralRatio = RATIO_UPPER_BOUND;
        }

        lastCallTime = block.timestamp; // Set the time of the last expansion

        emit SetGlobalCollateralRatio(globalCollateralRatio);
    }

    function stepDownTCR() external {
        require(
            hasRole(RATIO_SETTER, msg.sender),
            "Sender is not a ratio setter"
        );
        require(
            block.timestamp - lastCallTime >= refreshCooldown,
            "Must wait for the refresh cooldown since last refresh"
        );

        globalCollateralRatio = globalCollateralRatio.sub(ratioDelta);
        require(
            globalCollateralRatio >= RATIO_LOWER_BOUND,
            "New ratio exceed bound"
        );

        lastCallTime = block.timestamp; // Set the time of the last expansion
        emit SetGlobalCollateralRatio(globalCollateralRatio);
    }

    /* ================ Investment - Vault ================ */

    function addVault(address _vault) external {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        require(_vault != address(0), "invalidAddress");

        vaults.push(_vault);
        emit VaultAdded(_vault);
    }

    function removeVault(address _vault) external {
        require(hasRole(MAINTAINER, msg.sender), "Sender is not a maintainer");
        require(_vault != address(0), "invalidAddress");

        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < vaults.length; i++) {
            if (vaults[i] == _vault) {
                vaults[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }
        emit VaultRemoved(_vault);
    }

    function recallFromVault(uint256 index) public {
        require(hasRole(MAINTAINER, msg.sender));

        _recallFromVault(index);
    }

    function enterVault(uint256 index) public {
        require(hasRole(MAINTAINER, msg.sender));
        _enterVault(index);
    }

    function rebalanceVault(uint256 index) external {
        require(hasRole(MAINTAINER, msg.sender));
        _recallFromVault(index);
        _enterVault(index);
    }

    function _recallFromVault(uint256 index) internal {
        require(vaults[index] != address(0), "Vault does not exist");

        ITreasuryVault(vaults[index]).withdraw();
    }

    function _enterVault(uint256 index) internal {
        require(vaults[index] != address(0), "No vault");

        ITreasuryVault vault = ITreasuryVault(vaults[index]);

        IERC20 _collateral = IERC20(vault.asset());

        // 1. check balance
        uint256 _collateralBalance = _collateral.balanceOf(address(this));

        require(_collateralBalance > 0, "Collateral Balance is zero");

        // 2. now pools should contain all collaterals. we will calc how much to use
        uint256 _investmentAmount = (
            investCollateralRatio.mul(_collateralBalance)
        ).div(RATIO_PRECISION);

        if (_investmentAmount > 0) {
            _collateral.safeApprove(address(vault), 0);
            _collateral.safeApprove(address(vault), _investmentAmount);
            vault.deposit(_investmentAmount);
        }
    }

    /* ========== EVENTS ========== */
    event SetInvestCollateralRatio(uint256 newInvestCollateralRatio);
    event SetGlobalCollateralRatio(uint256 newRatio);
    event PoolAdded(address newPool);
    event PoolRemoved(address newPool);
    event AddCollateralToken(address newCollateral);
    event AddSynthToken(address newSynth);
    event AddOracle(address newOracle);
    event CollateralTokenRemoved(address collateral);
    event SynthTokenRemoved(address synth);
    event OracleRemoved(address oracle);
    event VaultAdded(address newVault);
    event VaultRemoved(address newVault);
    event SetBuybackFee(uint256 newFee);
    event SetRecollatFee(uint256 newFee);
    event RecollateralizeToggled(bool toggled);
    event BuybackToggled(bool toggled);

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

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
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ITreasuryVault {
    function asset() external view returns (address);

    function vaultBalance() external view returns (uint256);

    function deposit(uint256 _amount) external;

    function withdraw() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20BurnableUpgradeable.sol";


import "../Interfaces/ITWAP.sol";
import "./SyntheticPool.sol";

contract Synth is ERC20BurnableUpgradeable, AccessControlUpgradeable {
    uint256 public tokenCap;
    ITWAP synthTWAP;

    bytes32 public constant MAINTAINER = keccak256("MAINTAINER");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    uint256 private constant PRICE_PRECISION = 1e18;

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol
    ) public initializer {
        tokenCap = 100000 ether;
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ERC20_init_unchained(_name, _symbol);
        __ERC20Burnable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        grantRole(MAINTAINER, _owner);
    }

    function getSynthPrice() public view returns (uint256) {
        return ITWAP(synthTWAP).consult(address(this), 1e18);
    }

    function setOracle(ITWAP _synthTWAP) public {
        require(hasRole(MAINTAINER, msg.sender), "Caller is not a MAINTAINER");
        synthTWAP = _synthTWAP;
        emit SetOracle(address(_synthTWAP));
    }

    function setTokenCap(uint256 _newCap) external {
        require(hasRole(MAINTAINER, msg.sender), "Caller is not a MAINTAINER");
        tokenCap = _newCap;
        emit SetTokenCap(_newCap);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function mint(address to, uint256 _amount) external {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");

        uint256 newSupply = totalSupply() + _amount;
        require(newSupply <= tokenCap, "Minting exceed cap");

        _mint(to, _amount);
        emit Mint(to, _amount);
    }

    /* ========== EVENTS ========== */
    event Mint(address to, uint256 amount);
    event SetOracle(address oracle);
    event SetTokenCap(uint256 newCap);

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


contract TWX is ERC20BurnableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    function initialize(address _owner) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ERC20_init_unchained("Twindex", "TWX");
        __ERC20Burnable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    function mint(address to, uint256 _amount) external {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
    using SafeMathUpgradeable for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
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

