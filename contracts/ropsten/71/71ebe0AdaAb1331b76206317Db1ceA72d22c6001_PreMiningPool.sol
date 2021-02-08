// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../interface/IERC20.sol";
import "../interface/ILToken.sol";
import "../interface/IMigratablePool.sol";
import "../interface/IPreMiningPool.sol";
import "../utils/SafeERC20.sol";
import "../math/MixedSafeMathWithUnit.sol";
import "./MigratablePool.sol";

/**
 * @title Deri Protocol PreMining PerpetualPool Implementation
 */
contract PreMiningPool is IMigratablePool, IPreMiningPool, MigratablePool {

    using MixedSafeMathWithUnit for uint256;
    using MixedSafeMathWithUnit for int256;
    using SafeERC20 for IERC20;

    // Trading symbol
    string private _symbol;

    // Base token contract, all settlements are done in base token
    IERC20  private _bToken;
    // Base token decimals
    uint256 private _bDecimals;
    // Liquidity provider token contract
    ILToken private _lToken;

    // Minimum amount requirement when add liquidity
    uint256 private _minAddLiquidity;
    // Redemption fee ratio when removing liquidity
    uint256 private _redemptionFeeRatio;

    // Total liquidity pool holds
    uint256 private _liquidity;

    bool private _mutex;
    // Locker to prevent reentry
    modifier _lock_() {
        require(!_mutex, "PerpetualPool: reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    /**
     * @dev A dummy constructor, which deos not initialize any storage variables
     * A template will be deployed with no initialization and real pool will be cloned
     * from this template (same as create_forwarder_to mechanism in Vyper),
     * and use `initialize` to initialize all storage variables
     */
    constructor () {}

    /**
     * @dev See {IPreMiningPool}.{initialize}
     */
    function initialize(
        string memory symbol_,
        address[2] calldata addresses_,
        uint256[2] calldata parameters_
    ) public override {
        require(
            bytes(_symbol).length == 0 && _controller == address(0),
            "PerpetualPool: already initialized"
        );

        _controller = msg.sender;
        _symbol = symbol_;

        _bToken = IERC20(addresses_[0]);
        _bDecimals = _bToken.decimals();
        _lToken = ILToken(addresses_[1]);

        _minAddLiquidity = parameters_[0];
        _redemptionFeeRatio = parameters_[1];
    }

    /**
     * @dev See {IMigratablePool}.{approveMigration}
     */
    function approveMigration() public override _controller_ {
        require(
            _migrationTimestamp != 0 && block.timestamp >= _migrationTimestamp,
            "PerpetualPool: migrationTimestamp not met yet"
        );
        // approve new pool to pull all base tokens from this pool
        _bToken.safeApprove(_migrationDestination, uint256(-1));
        // set lToken to new pool, after redirecting lToken to new pool,
        // this pool will stop functioning
        _lToken.setPool(_migrationDestination);
    }

    /**
     * @dev See {IMigratablePool}.{executeMigration}
     */
    function executeMigration(address source) public override _controller_ {
        uint256 migrationTimestamp_ = IPreMiningPool(source).migrationTimestamp();
        address migrationDestination_ = IPreMiningPool(source).migrationDestination();
        require(
            migrationTimestamp_ != 0 && block.timestamp >= migrationTimestamp_,
            "PerpetualPool: migrationTimestamp not met yet"
        );
        require(
            migrationDestination_ == address(this),
            "PerpetualPool: executeMigration to not destination pool"
        );

        // migrate base token
        _bToken.safeTransferFrom(source, address(this), _bToken.balanceOf(source));
        // migrate state values
        _liquidity = IPreMiningPool(source).getStateValues();

        emit ExecuteMigration(_migrationTimestamp, source, address(this));
    }

    /**
     * @dev See {IPreMiningPool}.{symbol}
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IPreMiningPool}.{getAddresses}
     */
    function getAddresses() public view override returns (
        address bToken,
        address lToken
    ) {
        return (
            address(_bToken),
            address(_lToken)
        );
    }

    /**
     * @dev See {IPreMiningPool}.{getParameters}
     */
    function getParameters() public view override returns (
        uint256 minAddLiquidity,
        uint256 redemptionFeeRatio
    ) {
        return (
            _minAddLiquidity,
            _redemptionFeeRatio
        );
    }

    /**
     * @dev See {IPreMiningPool}.{getStateValues}
     */
    function getStateValues() public view override returns (
        uint256 liquidity
    ) {
        return _liquidity;
    }


    //================================================================================
    // Pool interactions
    //================================================================================

    /**
     * @dev See {IPreMiningPool}.{addLiquidity}
     */
    function addLiquidity(uint256 bAmount) public override {
        _addLiquidity(bAmount);
    }

    /**
     * @dev See {IPreMiningPool}.{removeLiquidity}
     */
    function removeLiquidity(uint256 lShares) public override {
        _removeLiquidity(lShares);
    }

    //================================================================================
    // Critical Logic
    //================================================================================

    /**
     * @dev Low level addLiquidity implementation
     */
    function _addLiquidity(uint256 bAmount) internal _lock_ {
        require(
            bAmount >= _minAddLiquidity,
            "PerpetualPool: add liquidity less than minimum requirement"
        );
        require(
            bAmount.reformat(_bDecimals) == bAmount,
            "PerpetualPool: _addLiquidity bAmount not valid"
        );

        bAmount = _deflationCompatibleSafeTransferFrom(msg.sender, address(this), bAmount);

        uint256 poolDynamicEquity = _liquidity;
        uint256 totalSupply = _lToken.totalSupply();
        uint256 lShares;
        if (totalSupply == 0) {
            lShares = bAmount;
        } else {
            lShares = bAmount.mul(totalSupply).div(poolDynamicEquity);
        }

        _lToken.mint(msg.sender, lShares);
        _liquidity = _liquidity.add(bAmount);

        emit AddLiquidity(msg.sender, lShares, bAmount);
    }

    /**
     * @dev Low level removeLiquidity implementation
     */
    function _removeLiquidity(uint256 lShares) internal _lock_ {
        require(lShares > 0, "PerpetualPool: remove 0 liquidity");
        uint256 balance = _lToken.balanceOf(msg.sender);
        require(
            lShares == balance || balance.sub(lShares) >= 10**18,
            "PerpetualPool: remaining liquidity shares must be 0 or at least 1"
        );

        uint256 poolDynamicEquity = _liquidity;
        uint256 totalSupply = _lToken.totalSupply();
        uint256 bAmount = lShares.mul(poolDynamicEquity).div(totalSupply);
        if (lShares < totalSupply) {
            bAmount = bAmount.sub(bAmount.mul(_redemptionFeeRatio));
        }
        bAmount = bAmount.reformat(_bDecimals);

        _liquidity = _liquidity.sub(bAmount);

        _lToken.burn(msg.sender, lShares);
        _bToken.safeTransfer(msg.sender, bAmount.rescale(_bDecimals));

        emit RemoveLiquidity(msg.sender, lShares, bAmount);
    }

    /**
     * @dev safeTransferFrom for base token with deflation protection
     * Returns the actual received amount in base token (as base 10**18)
     */
    function _deflationCompatibleSafeTransferFrom(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 preBalance = _bToken.balanceOf(to);
        _bToken.safeTransferFrom(from, to, amount.rescale(_bDecimals));
        uint256 curBalance = _bToken.balanceOf(to);

        uint256 a = curBalance.sub(preBalance);
        uint256 b = 10**18;
        uint256 c = a * b;
        require(c / b == a, "PreMiningPool: _deflationCompatibleSafeTransferFrom multiplication overflows");

        uint256 actualReceivedAmount = c / (10 ** _bDecimals);
        return actualReceivedAmount;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `amount` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @dev Emitted when `amount` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `amount` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the name.
     */
    function symbol() external view returns (string memory);

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
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the allowance mechanism.
     * `amount` is then deducted from the caller's allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC20.sol";

/**
 * @title Deri Protocol liquidity provider token interface
 */
interface ILToken is IERC20 {

    /**
     * @dev Set the pool address of this LToken
     * pool is the only controller of this contract
     * can only be called by current pool
     */
    function setPool(address newPool) external;

    /**
     * @dev Returns address of pool
     */
    function pool() external view returns (address);

    /**
     * @dev Mint LToken to `account` of `amount`
     *
     * Can only be called by pool
     * `account` cannot be zero address
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Burn `amount` LToken of `account`
     *
     * Can only be called by pool
     * `account` cannot be zero address
     * `account` must owns at least `amount` LToken
     */
    function burn(address account, uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Deri Protocol migratable pool interface
 */
interface IMigratablePool {

    /**
     * @dev Emitted when migration is prepared
     * `source` pool will be migrated to `target` pool after `migrationTimestamp`
     */
    event PrepareMigration(uint256 migrationTimestamp, address source, address target);

    /**
     * @dev Emmited when migration is executed
     * `source` pool is migrated to `target` pool
     */
    event ExecuteMigration(uint256 migrationTimestamp, address source, address target);

    /**
     * @dev Set controller to `newController`
     *
     * can only be called by current controller or the controller has not been set
     */
    function setController(address newController) external;

    /**
     * @dev Returns address of current controller
     */
    function controller() external view returns (address);

    /**
     * @dev Returns the migrationTimestamp of this pool, zero means not set
     */
    function migrationTimestamp() external view returns (uint256);

    /**
     * @dev Returns the destination pool this pool will migrate to after grace period
     * zero address means not set
     */
    function migrationDestination() external view returns (address);

    /**
     * @dev Prepare a migration from this pool to `newPool` with `graceDays` as grace period
     * `graceDays` must be at least 3 days from now, allow users to verify the `newPool` code
     *
     * can only be called by controller
     */
    function prepareMigration(address newPool, uint256 graceDays) external;

    /**
     * @dev Approve migration to `newPool` when grace period ends
     * after approvement, current pool will stop functioning
     *
     * can only be called by controller
     */
    function approveMigration() external;

    /**
     * @dev Called from the `newPool` to migrate from `source` pool
     * the grace period of `source` pool must ends
     * current pool must be the destination pool set before grace period in the `source` pool
     *
     * can only be called by controller
     */
    function executeMigration(address source) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IMigratablePool.sol";

/**
 * @title Deri Protocol PreMining PerpetualPool Interface
 */
interface IPreMiningPool is IMigratablePool {

    /**
     * @dev Emitted when `owner` add liquidity of `bAmount`,
     * and receive `lShares` liquidity token
     */
    event AddLiquidity(address indexed owner, uint256 lShares, uint256 bAmount);

    /**
     * @dev Emitted when `owner` burn `lShares` of liquidity token,
     * and receive `bAmount` in base token
     */
    event RemoveLiquidity(address indexed owner, uint256 lShares, uint256 bAmount);

    /**
     * @dev Initialize pool
     *
     * addresses:
     *      bToken
     *      lToken
     *
     * parameters:
     *      minAddLiquidity
     *      redemptionFeeRatio
     */
    function initialize(
        string memory symbol_,
        address[2] calldata addresses_,
        uint256[2] calldata parameters_
    ) external;

    /**
     * @dev Returns trading symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns addresses of (bToken, pToken, lToken, oracle) in this pool
     */
    function getAddresses() external view returns (
        address bToken,
        address lToken
    );

    /**
     * @dev Returns parameters of this pool
     */
    function getParameters() external view returns (
        uint256 minAddLiquidity,
        uint256 redemptionFeeRatio
    );

    /**
     * @dev Returns currents state values of this pool
     */
    function getStateValues() external view returns (
        uint256 liquidity
    );

    /**
     * @dev Add liquidity of `bAmount` in base token
     *
     * New liquidity provider token will be issued to the provider
     */
    function addLiquidity(uint256 bAmount) external;

    /**
     * @dev Remove `lShares` of liquidity provider token
     *
     * The liquidity provider token will be burned and
     * the corresponding amount in base token will be sent to provider
     */
    function removeLiquidity(uint256 lShares) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interface/IERC20.sol";
import "../math/UnsignedSafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using UnsignedSafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Mixed safe math with base unit of 10**18
 */
library MixedSafeMathWithUnit {

    uint256 constant UONE = 10**18;
    uint256 constant UMAX = 2**255 - 1;

    int256 constant IONE = 10**18;
    int256 constant IMIN = -2**255;

    //================================================================================
    // Conversions
    //================================================================================

    /**
     * @dev Convert uint256 to int256
     */
    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, "MixedSafeMathWithUnit: convert uint256 to int256 overflow");
        int256 b = int256(a);
        return b;
    }

    /**
     * @dev Convert int256 to uint256
     */
    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, "MixedSafeMathWithUnit: convert int256 to uint256 overflow");
        uint256 b = uint256(a);
        return b;
    }

    /**
     * @dev Take abs of int256
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, "MixedSafeMathWithUnit: int256 abs overflow");
        if (a >= 0) {
            return a;
        } else {
            return -a;
        }
    }

    /**
     * @dev Take negation of int256
     */
    function neg(int256 a) internal pure returns (int256) {
        require(a != IMIN, "MixedSafeMathWithUnit: int256 negate overflow");
        return -a;
    }

    //================================================================================
    // Rescale and reformat
    //================================================================================

    function _rescale(uint256 a, uint256 decimals1, uint256 decimals2)
        internal pure returns (uint256)
    {
        uint256 scale1 = 10 ** decimals1;
        uint256 scale2 = 10 ** decimals2;
        uint256 b = a * scale2;
        require(b / scale2 == a, "MixedSafeMathWithUnit: rescale uint256 overflow");
        uint256 c = b / scale1;
        return c;
    }

    function _rescale(int256 a, uint256 decimals1, uint256 decimals2)
        internal pure returns (int256)
    {
        int256 scale1 = utoi(10 ** decimals1);
        int256 scale2 = utoi(10 ** decimals2);
        int256 b = a * scale2;
        require(b / scale2 == a, "MixedSafeMathWithUnit: rescale int256 overflow");
        int256 c = b / scale1;
        return c;
    }

    /**
     * @dev Rescales a value from 10**18 base to 10**decimals base
     */
    function rescale(uint256 a, uint256 decimals) internal pure returns (uint256) {
        return _rescale(a, 18, decimals);
    }

    function rescale(int256 a, uint256 decimals) internal pure returns (int256) {
        return _rescale(a, 18, decimals);
    }

    /**
     * @dev Reformat a value to be a valid 10**decimals base value
     * The formatted value is still in 10**18 base
     */
    function reformat(uint256 a, uint256 decimals) internal pure returns (uint256) {
        return _rescale(_rescale(a, 18, decimals), decimals, 18);
    }

    function reformat(int256 a, uint256 decimals) internal pure returns (int256) {
        return _rescale(_rescale(a, 18, decimals), decimals, 18);
    }


    //================================================================================
    // Addition
    //================================================================================

    /**
     * @dev Addition: uint256 + uint256
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "MixedSafeMathWithUnit: uint256 addition overflow");
        return c;
    }

    /**
     * @dev Addition: int256 + int256
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require(
            (b >= 0 && c >= a) || (b < 0 && c < a),
            "MixedSafeMathWithUnit: int256 addition overflow"
        );
        return c;
    }

    /**
     * @dev Addition: uint256 + int256
     * uint256(-b) will not overflow when b is IMIN
     */
    function add(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            return add(a, uint256(b));
        } else {
            return sub(a, uint256(-b));
        }
    }

    /**
     * @dev Addition: int256 + uint256
     */
    function add(int256 a, uint256 b) internal pure returns (int256) {
        return add(a, utoi(b));
    }

    //================================================================================
    // Subtraction
    //================================================================================

    /**
     * @dev Subtraction: uint256 - uint256
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "MixedSafeMathWithUnit: uint256 subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Subtraction: int256 - int256
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require(
            (b >= 0 && c <= a) || (b < 0 && c > a),
            "MixedSafeMathWithUnit: int256 subtraction overflow"
        );
        return c;
    }

    /**
     * @dev Subtraction: uint256 - int256
     * uint256(-b) will not overflow when b is IMIN
     */
    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            return sub(a, uint256(b));
        } else {
            return add(a, uint256(-b));
        }
    }

    /**
     * @dev Subtraction: int256 - uint256
     */
    function sub(int256 a, uint256 b) internal pure returns (int256) {
        return sub(a, utoi(b));
    }

    //================================================================================
    // Multiplication
    //================================================================================

    /**
     * @dev Multiplication: uint256 * uint256
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero,
        // but the benefit is lost if 'b' is also tested
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "MixedSafeMathWithUnit: uint256 multiplication overflow");
        return c / UONE;
    }

    /**
     * @dev Multiplication: int256 * int256
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero,
        // but the benefit is lost if 'b' is also tested
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        require(!(a == -1 && b == IMIN), "MixedSafeMathWithUnit: int256 multiplication overflow");
        int256 c = a * b;
        require(c / a == b, "MixedSafeMathWithUnit: int256 multiplication overflow");
        return c / IONE;
    }

    /**
     * @dev Multiplication: uint256 * int256
     */
    function mul(uint256 a, int256 b) internal pure returns (uint256) {
        return mul(a, itou(b));
    }

    /**
     * @dev Multiplication: int256 * uint256
     */
    function mul(int256 a, uint256 b) internal pure returns (int256) {
        return mul(a, utoi(b));
    }

    //================================================================================
    // Division
    //================================================================================

    /**
     * @dev Division: uint256 / uint256
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MixedSafeMathWithUnit: uint256 division by zero");
        uint256 c = a * UONE;
        require(
            c / UONE == a,
            "MixedSafeMathWithUnit: uint256 division internal multiplication overflow"
        );
        uint256 d = c / b;
        return d;
    }

    /**
     * @dev Division: int256 / int256
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "MixedSafeMathWithUnit: int256 division by zero");
        int256 c = a * IONE;
        require(
            c / IONE == a,
            "MixedSafeMathWithUnit: int256 division internal multiplication overflow"
        );
        require(!(c == IMIN && b == -1), "MixedSafeMathWithUnit: int256 division overflow");
        int256 d = c / b;
        return d;
    }

    /**
     * @dev Division: uint256 / int256
     */
    function div(uint256 a, int256 b) internal pure returns (uint256) {
        return div(a, itou(b));
    }

    /**
     * @dev Division: int256 / uint256
     */
    function div(int256 a, uint256 b) internal pure returns (int256) {
        return div(a, utoi(b));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interface/IMigratablePool.sol";

/**
 * @dev Deri Protocol migratable pool implementation
 */
abstract contract MigratablePool is IMigratablePool {

    // Controller address
    address _controller;

    // Migration timestamp of this pool, zero means not set
    // Migration timestamp can only be set with a grace period at least 3 days, and the
    // `migrationDestination` pool address must be also set when setting migration timestamp,
    // users can use this grace period to verify the `migrationDestination` pool code
    uint256 _migrationTimestamp;

    // The new pool this pool will migrate to after grace period, zero address means not set
    address _migrationDestination;

    modifier _controller_() {
        require(msg.sender == _controller, "can only be called by current controller");
        _;
    }

    /**
     * @dev See {IMigratablePool}.{setController}
     */
    function setController(address newController) public override {
        require(newController != address(0), "MigratablePool: setController to 0 address");
        require(
            _controller == address(0) || msg.sender == _controller,
            "MigratablePool: setController can only be called by current controller or not set"
        );
        _controller = newController;
    }

    /**
     * @dev See {IMigratablePool}.{controller}
     */
    function controller() public view override returns (address) {
        return _controller;
    }

    /**
     * @dev See {IMigratablePool}.{migrationTimestamp}
     */
    function migrationTimestamp() public view override returns (uint256) {
        return _migrationTimestamp;
    }

    /**
     * @dev See {IMigratablePool}.{migrationDestination}
     */
    function migrationDestination() public view override returns (address) {
        return _migrationDestination;
    }

    /**
     * @dev See {IMigratablePool}.{prepareMigration}
     */
    function prepareMigration(address newPool, uint256 graceDays) public override _controller_ {
        require(newPool != address(0), "MigratablePool: prepareMigration to 0 address");
        require(graceDays >= 3 && graceDays <= 365, "MigratablePool: graceDays must be 3-365 days");

        _migrationTimestamp = block.timestamp + graceDays * 1 days;
        _migrationDestination = newPool;

        emit PrepareMigration(_migrationTimestamp, address(this), _migrationDestination);
    }

    /**
     * @dev See {IMigratablePool}.{approveMigration}
     *
     * This function will be implemented in inheriting contract
     * This function will change if there is an upgrade to existent pool
     */
    // function approveMigration() public virtual override _controller_ {}

    /**
     * @dev See {IMigratablePool}.{executeMigration}
     *
     * This function will be implemented in inheriting contract
     * This function will change if there is an upgrade to existent pool
     */
    // function executeMigration(address source) public virtual override _controller_ {}

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Unsigned safe math
 */
library UnsignedSafeMath {

    /**
     * @dev Addition of unsigned integers, counterpart to `+`
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "UnsignedSafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Subtraction of unsigned integers, counterpart to `-`
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "UnsignedSafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Multiplication of unsigned integers, counterpart to `*`
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero,
        // but the benefit is lost if 'b' is also tested
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "UnsignedSafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Division of unsigned integers, counterpart to `/`
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "UnsignedSafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    /**
     * @dev Modulo of unsigned integers, counterpart to `%`
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "UnsignedSafeMath: modulo by zero");
        uint256 c = a % b;
        return c;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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