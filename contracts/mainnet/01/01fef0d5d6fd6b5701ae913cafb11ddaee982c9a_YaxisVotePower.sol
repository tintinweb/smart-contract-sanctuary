// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMasterChef {
    function userInfo(uint256, address) external view returns (uint256, uint256, uint256);
    function pendingYaxis(uint256, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IMasterChef.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IVoteProxy.sol";
import "./interfaces/IYaxisBar.sol";

contract YaxisVotePower is IVoteProxy {
    using SafeMath for uint256;

    uint256 public constant PID = 6;
    // solhint-disable-next-line const-name-snakecase
    uint8 public constant override decimals = uint8(18);

    // ETH/YAX token
    IUniswapV2Pair public immutable yaxEthUniswapV2Pair;

    // YAX token
    IERC20 public immutable yax;

    // YaxisChef contract
    IMasterChef public immutable chef;

    // sYAX token
    IYaxisBar public immutable yaxisBar;

    constructor(
        address _yax,
        address _yaxisChef,
        address _yaxisBar,
        address _yaxEthUniswapV2Pair
    )
        public
    {
        yax = IERC20(_yax);
        chef = IMasterChef(_yaxisChef);
        yaxisBar = IYaxisBar(_yaxisBar);
        yaxEthUniswapV2Pair = IUniswapV2Pair(_yaxEthUniswapV2Pair);
    }

    function totalSupply()
        external
        view
        override
        returns (uint256 _supply)
    {
        (uint256 _yaxReserves,,) = yaxEthUniswapV2Pair.getReserves();
        _supply = yaxEthUniswapV2Pair.totalSupply();
        _supply = _supply == 0
            ? 1e18
            : _supply;
        uint256 _lpStakingYax = _yaxReserves
            .mul(yaxEthUniswapV2Pair.balanceOf(address(chef)))
            .div(_supply);
        _supply = sqrt(
            yax.totalSupply()
                .add(_lpStakingYax)
                .add(yaxisBar.availableBalance())
        );
    }

    function balanceOf(
        address _voter
    )
        external
        view
        override
        returns (uint256 _balance)
    {
        (uint256 _stakeAmount,,) = chef.userInfo(PID, _voter);
        (uint256 _yaxReserves,,) = yaxEthUniswapV2Pair.getReserves();
        uint256 _supply = yaxEthUniswapV2Pair.totalSupply();
        _supply = _supply == 0
            ? 1e18
            : _supply;
        uint256 _lpStakingYax = _yaxReserves
            .mul(_stakeAmount)
            .div(_supply)
            .add(chef.pendingYaxis(PID, _voter));
        _supply = yaxisBar.totalSupply();
        _supply = _supply == 0
            ? 1e18
            : _supply;
        uint256 _syaxAmount = yaxisBar.balanceOf(_voter)
            .mul(yaxisBar.availableBalance())
            .div(_supply);
        _balance = sqrt(
            yax.balanceOf(_voter)
                .add(_lpStakingYax)
                .add(_syaxAmount)
        );
    }

    function sqrt(
        uint256 x
    )
        private
        pure
        returns (uint256 y)
    {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        y = y * (10 ** 9);
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
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Pair is IERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IVoteProxy {
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _voter) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYaxisBar is IERC20 {
    function availableBalance() external view returns (uint256);
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

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./IVaultManager.sol";

/**
 * @title yAxisMetaVaultManager
 * @notice This contract serves as the central point for governance-voted
 * variables. Fees and permissioned addresses are stored and referenced in
 * this contract only.
 */
contract yAxisMetaVaultManager is IVaultManager { // solhint-disable-line contract-name-camelcase
    using SafeERC20 for IERC20;

    address public override governance;
    address public override harvester;
    address public override insurancePool;
    address public override stakingPool;
    address public override strategist;
    address public override treasury;
    address public override yax;

    /**
     *  The following fees are all mutable.
     *  They are updated by governance (community vote).
     */
    uint256 public override insuranceFee;
    uint256 public override insurancePoolFee;
    uint256 public override stakingPoolShareFee;
    uint256 public override treasuryBalance;
    uint256 public override treasuryFee;
    uint256 public override withdrawalProtectionFee;

    mapping(address => bool) public override vaults;
    mapping(address => bool) public override controllers;

    /**
     * @param _yax The address of the YAX token
     */
    constructor(address _yax) public {
        yax = _yax;
        governance = msg.sender;
        strategist = msg.sender;
        harvester = msg.sender;
        stakingPoolShareFee = 2000;
        treasuryBalance = 20000e18;
        treasuryFee = 500;
        withdrawalProtectionFee = 10;
    }

    /**
     * GOVERNANCE-ONLY FUNCTIONS
     */

    /**
     * @notice Allows governance to pull tokens out of this contract
     * (it should never hold tokens)
     * @param _token The address of the token
     * @param _amount The amount to withdraw
     * @param _to The address to send to
     */
    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external {
        require(msg.sender == governance, "!governance");
        _token.safeTransfer(_to, _amount);
    }

    /**
     * @notice Sets the governance address
     * @param _governance The address of the governance
     */
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    /**
     * @notice Sets the insurance fee
     * @dev Throws if setting fee over 1%
     * @param _insuranceFee The value for the insurance fee
     */
    function setInsuranceFee(uint256 _insuranceFee) public {
        require(msg.sender == governance, "!governance");
        require(_insuranceFee <= 100, "_insuranceFee over 1%");
        insuranceFee = _insuranceFee;
    }

    /**
     * @notice Sets the insurance pool address
     * @param _insurancePool The address of the insurance pool
     */
    function setInsurancePool(address _insurancePool) public {
        require(msg.sender == governance, "!governance");
        insurancePool = _insurancePool;
    }

    /**
     * @notice Sets the insurance pool fee
     * @dev Throws if setting fee over 20%
     * @param _insurancePoolFee The value for the insurance pool fee
     */
    function setInsurancePoolFee(uint256 _insurancePoolFee) public {
        require(msg.sender == governance, "!governance");
        require(_insurancePoolFee <= 2000, "_insurancePoolFee over 20%");
        insurancePoolFee = _insurancePoolFee;
    }

    /**
     * @notice Sets the staking pool address
     * @param _stakingPool The address of the staking pool
     */
    function setStakingPool(address _stakingPool) public {
        require(msg.sender == governance, "!governance");
        stakingPool = _stakingPool;
    }

    /**
     * @notice Sets the staking pool share fee
     * @dev Throws if setting fee over 50%
     * @param _stakingPoolShareFee The value for the staking pool fee
     */
    function setStakingPoolShareFee(uint256 _stakingPoolShareFee) public {
        require(msg.sender == governance, "!governance");
        require(_stakingPoolShareFee <= 5000, "_stakingPoolShareFee over 50%");
        stakingPoolShareFee = _stakingPoolShareFee;
    }

    /**
     * @notice Sets the strategist address
     * @param _strategist The address of the strategist
     */
    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    /**
     * @notice Sets the treasury address
     * @param _treasury The address of the treasury
     */
    function setTreasury(address _treasury) public {
        require(msg.sender == governance, "!governance");
        treasury = _treasury;
    }

    /**
     * @notice Sets the maximum treasury balance
     * @dev Strategies will read this value to determine whether or not
     * to give the treasury the treasuryFee
     * @param _treasuryBalance The maximum balance of the treasury
     */
    function setTreasuryBalance(uint256 _treasuryBalance) public {
        require(msg.sender == governance, "!governance");
        treasuryBalance = _treasuryBalance;
    }

    /**
     * @notice Sets the treasury fee
     * @dev Throws if setting fee over 20%
     * @param _treasuryFee The value for the treasury fee
     */
    function setTreasuryFee(uint256 _treasuryFee) public {
        require(msg.sender == governance, "!governance");
        require(_treasuryFee <= 2000, "_treasuryFee over 20%");
        treasuryFee = _treasuryFee;
    }

    /**
     * @notice Sets the withdrawal protection fee
     * @dev Throws if setting fee over 1%
     * @param _withdrawalProtectionFee The value for the withdrawal protection fee
     */
    function setWithdrawalProtectionFee(uint256 _withdrawalProtectionFee) public {
        require(msg.sender == governance, "!governance");
        require(_withdrawalProtectionFee <= 100, "_withdrawalProtectionFee over 1%");
        withdrawalProtectionFee = _withdrawalProtectionFee;
    }

    /**
     * @notice Sets the YAX address
     * @param _yax The address of the YAX token
     */
    function setYax(address _yax) external {
        require(msg.sender == governance, "!governance");
        yax = _yax;
    }

    /**
     * (GOVERNANCE|STRATEGIST)-ONLY FUNCTIONS
     */

    /**
     * @notice Sets the status for a controller
     * @param _controller The address of the controller
     * @param _status The status of the controller
     */
    function setControllerStatus(address _controller, bool _status) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        controllers[_controller] = _status;
    }

    /**
     * @notice Sets the harvester address
     * @param _harvester The address of the harvester
     */
    function setHarvester(address _harvester) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        harvester = _harvester;
    }

    /**
     * @notice Sets the status for a vault
     * @param _vault The address of the vault
     * @param _status The status of the vault
     */
    function setVaultStatus(address _vault, bool _status) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        vaults[_vault] = _status;
    }

    /**
     * EXTERNAL VIEW FUNCTIONS
     */

    /**
     * @notice Returns a tuple of:
     *     YAX token,
     *     Staking pool address,
     *     Staking pool share fee,
     *     Treasury address,
     *     Checks the balance of the treasury and returns the treasury fee
     *         if below the treasuryBalance, or 0 if above
     */
    function getHarvestFeeInfo()
        external
        view
        override
        returns (address, address, uint256, address, uint256, address, uint256)
    {
        return (
            yax,
            stakingPool,
            stakingPoolShareFee,
            treasury,
            IERC20(yax).balanceOf(treasury) >= treasuryBalance ? 0 : treasuryFee,
            insurancePool,
            insurancePoolFee
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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

interface IVaultManager {
    function controllers(address) external view returns (bool);
    function getHarvestFeeInfo() external view returns (address, address, uint256, address, uint256, address, uint256);
    function governance() external view returns (address);
    function harvester() external view returns (address);
    function insuranceFee() external view returns (uint256);
    function insurancePool() external view returns (address);
    function insurancePoolFee() external view returns (uint256);
    function stakingPool() external view returns (address);
    function stakingPoolShareFee() external view returns (uint256);
    function strategist() external view returns (address);
    function treasury() external view returns (address);
    function treasuryBalance() external view returns (uint256);
    function treasuryFee() external view returns (uint256);
    function vaults(address) external view returns (bool);
    function withdrawalProtectionFee() external view returns (uint256);
    function yax() external view returns (address);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./IController.sol";
import "./IHarvester.sol";
import "./IVaultManager.sol";

/**
 * @title yAxisMetaVaultHarvester
 * @notice This contract is to be used as a central point to call
 * harvest on all strategies for any given token. It has its own
 * permissions for harvesters (set by the strategist or governance).
 */
contract yAxisMetaVaultHarvester is IHarvester { // solhint-disable-line contract-name-camelcase
    using SafeMath for uint256;

    IVaultManager public vaultManager;
    IController public controller;

    struct Strategy {
        uint256 timeout;
        uint256 lastCalled;
        address[] addresses;
    }

    mapping(address => Strategy) public strategies;
    mapping(address => bool) public isHarvester;

    /**
     * @notice Logged when a controller is set
     */
    event ControllerSet(address indexed controller);

    /**
     * @notice Logged when harvest is called for a strategy
     */
    event Harvest(
        address indexed controller,
        address indexed strategy
    );

    /**
     * @notice Logged when a harvester is set
     */
    event HarvesterSet(address indexed harvester, bool status);

    /**
     * @notice Logged when a strategy is added for a token
     */
    event StrategyAdded(address indexed token, address indexed strategy, uint256 timeout);

    /**
     * @notice Logged when a strategy is removed for a token
     */
    event StrategyRemoved(address indexed token, address indexed strategy, uint256 timeout);

    /**
     * @notice Logged when a vault manger is set
     */
    event VaultManagerSet(address indexed vaultManager);

    /**
     * @param _vaultManager The address of the yAxisMetaVaultManager contract
     * @param _controller The address of the controller
     */
    constructor(address _vaultManager, address _controller) public {
        vaultManager = IVaultManager(_vaultManager);
        controller = IController(_controller);
    }

    /**
     * (GOVERNANCE|STRATEGIST)-ONLY FUNCTIONS
     */

    /**
     * @notice Adds a strategy to the rotation for a given token and sets a timeout
     * @param _token The address of the token
     * @param _strategy The address of the strategy
     * @param _timeout The timeout between harvests
     */
    function addStrategy(
        address _token,
        address _strategy,
        uint256 _timeout
    ) external override onlyStrategist {
        strategies[_token].addresses.push(_strategy);
        strategies[_token].timeout = _timeout;
        emit StrategyAdded(_token, _strategy, _timeout);
    }

    /**
     * @notice Removes a strategy from the rotation for a given token and sets a timeout
     * @param _token The address of the token
     * @param _strategy The address of the strategy
     * @param _timeout The timeout between harvests
     */
    function removeStrategy(
        address _token,
        address _strategy,
        uint256 _timeout
    ) external override onlyStrategist {
        uint256 tail = strategies[_token].addresses.length;
        uint256 index;
        bool found;
        for (uint i; i < tail; i++) {
            if (strategies[_token].addresses[i] == _strategy) {
                index = i;
                found = true;
                break;
            }
        }

        if (found) {
            strategies[_token].addresses[index] = strategies[_token].addresses[tail.sub(1)];
            strategies[_token].addresses.pop();
            strategies[_token].timeout = _timeout;
            emit StrategyRemoved(_token, _strategy, _timeout);
        }
    }

    /**
     * @notice Sets the address of the controller
     * @param _controller The address of the controller
     */
    function setController(IController _controller) external onlyStrategist {
        controller = _controller;
        emit ControllerSet(address(_controller));
    }

    /**
     * @notice Sets the status of a harvester address to be able to call harvest functions
     * @param _harvester The address of the harvester
     * @param _status The status to allow the harvester to harvest
     */
    function setHarvester(address _harvester, bool _status) public onlyStrategist {
        isHarvester[_harvester] = _status;
        emit HarvesterSet(_harvester, _status);
    }

    /**
     * @notice Sets the address of the vault manager contract
     * @param _vaultManager The address of the vault manager
     */
    function setVaultManager(address _vaultManager) external onlyStrategist {
        vaultManager = IVaultManager(_vaultManager);
        emit VaultManagerSet(_vaultManager);
    }

    /**
     * (GOVERNANCE|STRATEGIST|HARVESTER)-ONLY FUNCTIONS
     */

    /**
     * @notice Harvests a given strategy on the provided controller
     * @dev This function ignores the timeout
     * @param _controller The address of the controller
     * @param _strategy The address of the strategy
     */
    function harvest(
        IController _controller,
        address _strategy
    ) public onlyHarvester {
        _controller.harvestStrategy(_strategy);
        emit Harvest(address(_controller), _strategy);
    }

    /**
     * @notice Harvests the next available strategy for a given token and
     * rotates the strategies
     * @param _token The address of the token
     */
    function harvestNextStrategy(address _token) external {
        require(canHarvest(_token), "!canHarvest");
        address strategy = strategies[_token].addresses[0];
        harvest(controller, strategy);
        uint256 k = strategies[_token].addresses.length;
        if (k > 1) {
            address[] memory _strategies = new address[](k);
            for (uint i; i < k-1; i++) {
                _strategies[i] = strategies[_token].addresses[i+1];
            }
            _strategies[k-1] = strategy;
            strategies[_token].addresses = _strategies;
        }
        // solhint-disable-next-line not-rely-on-time
        strategies[_token].lastCalled = block.timestamp;
    }

    /**
     * EXTERNAL VIEW FUNCTIONS
     */

    /**
     * @notice Returns the addresses of the strategies for a given token
     * @param _token The address of the token
     */
    function strategyAddresses(address _token) external view returns (address[] memory) {
        return strategies[_token].addresses;
    }

    /**
     * PUBLIC VIEW FUNCTIONS
     */

    /**
     * @notice Returns the availability of a token's strategy to be harvested
     * @param _token The address of the token
     */
    function canHarvest(address _token) public view returns (bool) {
        Strategy storage strategy = strategies[_token];
        if (strategy.addresses.length == 0 ||
            // solhint-disable-next-line not-rely-on-time
            strategy.lastCalled > block.timestamp.sub(strategy.timeout)) {
            return false;
        }
        return true;
    }

    /**
     * MODIFIERS
     */

    modifier onlyHarvester() {
        require(isHarvester[msg.sender], "!harvester");
        _;
    }

    modifier onlyStrategist() {
        require(vaultManager.controllers(msg.sender)
             || msg.sender == vaultManager.strategist()
             || msg.sender == vaultManager.governance(),
             "!strategist"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IController {
    function balanceOf(address) external view returns (uint256);
    function earn(address, uint256) external;
    function investEnabled() external view returns (bool);
    function harvestStrategy(address) external;
    function strategyTokens(address) external returns (address);
    function vaults(address) external view returns (address);
    function want(address) external view returns (address);
    function withdraw(address, uint256) external;
    function withdrawFee(address, uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IHarvester {
    function addStrategy(address, address, uint256) external;
    function removeStrategy(address, address, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../IController.sol";
import "../IConverter.sol";
import "../IHarvester.sol";
import "../IMetaVault.sol";
import "../IStrategy.sol";
import "../IVaultManager.sol";

/**
 * @title StrategyControllerV2
 * @notice This controller allows multiple strategies to be used
 * for a single token, and multiple tokens are supported.
 */
contract StrategyControllerV2 is IController {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bool public globalInvestEnabled;
    uint256 public maxStrategies;
    IVaultManager public vaultManager;

    struct TokenStrategy {
        address[] strategies;
        mapping(address => uint256) index;
        mapping(address => bool) active;
        mapping(address => uint256) caps;
    }

    // token => (want => converter)
    mapping(address => mapping(address => address)) public converters;
    // token => TokenStrategy
    mapping(address => TokenStrategy) internal tokenStrategies;
    // strategy => token
    mapping(address => address) public override strategyTokens;
    // token => vault
    mapping(address => address) public override vaults;
    // vault => token
    mapping(address => address) public vaultTokens;

    /**
     * @notice Logged when earn is called for a strategy
     */
    event Earn(address indexed strategy);

    /**
     * @notice Logged when harvest is called for a strategy
     */
    event Harvest(address indexed strategy);

    /**
     * @notice Logged when insurance is claimed for a vault
     */
    event InsuranceClaimed(address indexed vault);

    /**
     * @notice Logged when a converter is set
     */
    event SetConverter(address input, address output, address converter);

    /**
     * @notice Logged when a vault manager is set
     */
    event SetVaultManager(address vaultManager);

    /**
     * @notice Logged when a strategy is added for a token
     */
    event StrategyAdded(address indexed token, address indexed strategy, uint256 cap);

    /**
     * @notice Logged when a strategy is removed for a token
     */
    event StrategyRemoved(address indexed token, address indexed strategy);

    /**
     * @notice Logged when strategies are reordered for a token
     */
    event StrategiesReordered(
        address indexed token,
        address indexed strategy1,
        address indexed strategy2
    );

    /**
     * @param _vaultManager The address of the vaultManager
     */
    constructor(address _vaultManager) public {
        vaultManager = IVaultManager(_vaultManager);
        globalInvestEnabled = true;
        maxStrategies = 10;
    }

    /**
     * GOVERNANCE-ONLY FUNCTIONS
     */

    /**
     * @notice Adds a strategy for a given token
     * @dev Only callable by governance
     * @param _token The address of the token
     * @param _strategy The address of the strategy
     * @param _cap The cap of the strategy
     * @param _converter The converter of the strategy (can be zero address)
     * @param _canHarvest Flag for whether the strategy can be harvested
     * @param _timeout The timeout between harvests
     */
    function addStrategy(
        address _token,
        address _strategy,
        uint256 _cap,
        address _converter,
        bool _canHarvest,
        uint256 _timeout
    ) external onlyGovernance {
        // ensure the strategy hasn't been added
        require(!tokenStrategies[_token].active[_strategy], "active");
        address _want = IStrategy(_strategy).want();
        // ensure a converter is added if the strategy's want token is
        // different than the want token of the vault
        if (_want != IMetaVault(vaults[_token]).want()) {
            require(_converter != address(0), "!_converter");
            converters[_token][_want] = _converter;
            // enable the strategy on the converter
            IConverter(_converter).setStrategy(_strategy, true);
        }
        // get the index of the newly added strategy
        uint256 index = tokenStrategies[_token].strategies.length;
        // ensure we haven't added too many strategies already
        require(index < maxStrategies, "!maxStrategies");
        // push the strategy to the array of strategies
        tokenStrategies[_token].strategies.push(_strategy);
        // set the cap
        tokenStrategies[_token].caps[_strategy] = _cap;
        // set the index
        tokenStrategies[_token].index[_strategy] = index;
        // activate the strategy
        tokenStrategies[_token].active[_strategy] = true;
        // store the reverse mapping
        strategyTokens[_strategy] = _token;
        // if the strategy should be harvested
        if (_canHarvest) {
            // add it to the harvester
            IHarvester(vaultManager.harvester()).addStrategy(_token, _strategy, _timeout);
        }
        emit StrategyAdded(_token, _strategy, _cap);
    }

    /**
     * @notice Claims the insurance fund of a vault
     * @dev Only callable by governance
     * @dev When insurance is claimed by the controller, the insurance fund of
     * the vault is zeroed out, increasing the getPricePerFullShare and applying
     * the gains to everyone in the vault.
     * @param _vault The address of the vault
     */
    function claimInsurance(address _vault) external onlyGovernance {
        IMetaVault(_vault).claimInsurance();
        emit InsuranceClaimed(_vault);
    }

    /**
     * @notice Sets the address of the vault manager contract
     * @dev Only callable by governance
     * @param _vaultManager The address of the vault manager
     */
    function setVaultManager(address _vaultManager) external onlyGovernance {
        vaultManager = IVaultManager(_vaultManager);
        emit SetVaultManager(_vaultManager);
    }

    /**
     * (GOVERNANCE|STRATEGIST)-ONLY FUNCTIONS
     */

    /**
     * @notice Withdraws token from a strategy to governance
     * @dev Only callable by governance or the strategist
     * @param _strategy The address of the strategy
     * @param _token The address of the token
     */
    function inCaseStrategyGetStuck(
        address _strategy,
        address _token
    ) external onlyStrategist {
        IStrategy(_strategy).withdraw(_token);
        IERC20(_token).safeTransfer(
            vaultManager.governance(),
            IERC20(_token).balanceOf(address(this))
        );
    }

    /**
     * @notice Withdraws token from the controller to governance
     * @dev Only callable by governance or the strategist
     * @param _token The address of the token
     * @param _amount The amount that will be withdrawn
     */
    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount
    ) external onlyStrategist {
        IERC20(_token).safeTransfer(vaultManager.governance(), _amount);
    }

    /**
     * @notice Removes a strategy for a given token
     * @dev Only callable by governance or strategist
     * @param _token The address of the token
     * @param _strategy The address of the strategy
     * @param _timeout The timeout between harvests
     */
    function removeStrategy(
        address _token,
        address _strategy,
        uint256 _timeout
    ) external onlyStrategist {
        TokenStrategy storage tokenStrategy = tokenStrategies[_token];
        // ensure the strategy is already added
        require(tokenStrategy.active[_strategy], "!active");
        // get the index of the strategy to remove
        uint256 index = tokenStrategy.index[_strategy];
        // get the index of the last strategy
        uint256 tail = tokenStrategy.strategies.length.sub(1);
        // get the address of the last strategy
        address replace = tokenStrategy.strategies[tail];
        // replace the removed strategy with the tail
        tokenStrategy.strategies[index] = replace;
        // set the new index for the replaced strategy
        tokenStrategy.index[replace] = index;
        // remove the duplicate replaced strategy
        tokenStrategy.strategies.pop();
        // remove the strategy's index
        delete tokenStrategy.index[_strategy];
        // remove the strategy's cap
        delete tokenStrategy.caps[_strategy];
        // deactivate the strategy
        delete tokenStrategy.active[_strategy];
        // pull funds from the removed strategy to the vault
        IStrategy(_strategy).withdrawAll();
        // remove the strategy from the harvester
        IHarvester(vaultManager.harvester()).removeStrategy(_token, _strategy, _timeout);
        // get the strategy want token
        address _want = IStrategy(_strategy).want();
        // if a converter is used
        if (_want != IMetaVault(vaults[_token]).want()) {
            // disable the strategy on the converter
            IConverter(converters[_token][_want]).setStrategy(_strategy, false);
        }
        emit StrategyRemoved(_token, _strategy);
    }

    /**
     * @notice Reorders two strategies for a given token
     * @dev Only callable by governance or strategist
     * @param _token The address of the token
     * @param _strategy1 The address of the first strategy
     * @param _strategy2 The address of the second strategy
     */
    function reorderStrategies(
        address _token,
        address _strategy1,
        address _strategy2
    ) external onlyStrategist {
        require(_strategy1 != _strategy2, "_strategy1 == _strategy2");
        TokenStrategy storage tokenStrategy = tokenStrategies[_token];
        // ensure the strategies are already added
        require(tokenStrategy.active[_strategy1]
             && tokenStrategy.active[_strategy2],
             "!active");
        // get the indexes of the strategies
        uint256 index1 = tokenStrategy.index[_strategy1];
        uint256 index2 = tokenStrategy.index[_strategy2];
        // set the new addresses at their indexes
        tokenStrategy.strategies[index1] = _strategy2;
        tokenStrategy.strategies[index2] = _strategy1;
        // update indexes
        tokenStrategy.index[_strategy1] = index2;
        tokenStrategy.index[_strategy2] = index1;
        emit StrategiesReordered(_token, _strategy1, _strategy2);
    }

    /**
     * @notice Sets/updates the cap of a strategy for a token
     * @dev Only callable by governance or strategist
     * @dev If the balance of the strategy is greater than the new cap (except if
     * the cap is 0), then withdraw the difference from the strategy to the vault.
     * @param _token The address of the token
     * @param _strategy The address of the strategy
     * @param _cap The new cap of the strategy
     */
    function setCap(
        address _token,
        address _strategy,
        uint256 _cap
    ) external onlyStrategist {
        require(tokenStrategies[_token].active[_strategy], "!active");
        tokenStrategies[_token].caps[_strategy] = _cap;
        uint256 _balance = IStrategy(_strategy).balanceOf();
        // send excess funds (over cap) back to the vault
        if (_balance > _cap && _cap != 0) {
            uint256 _diff = _balance.sub(_cap);
            IStrategy(_strategy).withdraw(_diff);
        }
    }

    /**
     * @notice Sets/updates the converter for given input and output tokens
     * @dev Only callable by governance or strategist
     * @param _input The address of the input token
     * @param _output The address of the output token
     * @param _converter The address of the converter
     */
    function setConverter(
        address _input,
        address _output,
        address _converter
    ) external onlyStrategist {
        converters[_input][_output] = _converter;
        emit SetConverter(_input, _output, _converter);
    }

    /**
     * @notice Sets/updates the global invest enabled flag
     * @dev Only callable by governance or strategist
     * @param _investEnabled The new bool of the invest enabled flag
     */
    function setInvestEnabled(bool _investEnabled) external onlyStrategist {
        globalInvestEnabled = _investEnabled;
    }

    /**
     * @notice Sets/updates the maximum number of strategies for a token
     * @dev Only callable by governance or strategist
     * @param _maxStrategies The new value of the maximum strategies
     */
    function setMaxStrategies(uint256 _maxStrategies) external onlyStrategist {
        require(_maxStrategies > 0, "!_maxStrategies");
        maxStrategies = _maxStrategies;
    }

    /**
     * @notice Sets the address of a vault for a given token
     * @dev Only callable by governance or strategist
     * @param _token The address of the token
     * @param _vault The address of the vault
     */
    function setVault(address _token, address _vault) external onlyStrategist {
        require(vaults[_token] == address(0), "vault");
        vaults[_token] = _vault;
        vaultTokens[_vault] = _token;
    }

    /**
     * @notice Withdraws all funds from a strategy
     * @dev Only callable by governance or the strategist
     * @param _strategy The address of the strategy
     */
    function withdrawAll(address _strategy) external onlyStrategist {
        // WithdrawAll sends 'want' to 'vault'
        IStrategy(_strategy).withdrawAll();
    }

    /**
     * (GOVERNANCE|STRATEGIST|HARVESTER)-ONLY FUNCTIONS
     */

    /**
     * @notice Harvests the specified strategy
     * @dev Only callable by governance, the strategist, or the harvester
     * @param _strategy The address of the strategy
     */
    function harvestStrategy(address _strategy) external override onlyHarvester {
        IStrategy(_strategy).harvest();
        emit Harvest(_strategy);
    }

    /**
     * VAULT-ONLY FUNCTIONS
     */

    /**
     * @notice Invests funds into a strategy
     * @dev Only callable by a vault
     * @param _token The address of the token
     * @param _amount The amount that will be invested
     */
    function earn(address _token, uint256 _amount) external override onlyVault(_token) {
        // get the first strategy that will accept the deposit
        address _strategy = getBestStrategyEarn(_token, _amount);
        // get the want token of the strategy
        address _want = IStrategy(_strategy).want();
        // if the depositing token is not what the strategy wants, convert it
        // then transfer it to the strategy
        if (_want != _token) {
            address _converter = converters[_token][_want];
            IERC20(_token).safeTransfer(_converter, _amount);
            _amount = IConverter(_converter).convert(
                _token,
                _want,
                _amount
            );
            IERC20(_want).safeTransfer(_strategy, _amount);
        } else {
            IERC20(_token).safeTransfer(_strategy, _amount);
        }
        // call the strategy's deposit function
        IStrategy(_strategy).deposit();
        emit Earn(_strategy);
    }

    /**
     * @notice Withdraws funds from a strategy
     * @dev Only callable by a vault
     * @dev If the withdraw amount is greater than the first strategy given
     * by getBestStrategyWithdraw, this function will loop over strategies
     * until the requested amount is met.
     * @param _token The address of the token
     * @param _amount The amount that will be withdrawn
     */
    function withdraw(address _token, uint256 _amount) external override onlyVault(_token) {
        (
            address[] memory _strategies,
            uint256[] memory _amounts
        ) = getBestStrategyWithdraw(_token, _amount);
        for (uint i = 0; i < _strategies.length; i++) {
            // getBestStrategyWithdraw will return arrays larger than needed
            // if this happens, simply exit the loop
            if (_strategies[i] == address(0)) {
                break;
            }
            IStrategy(_strategies[i]).withdraw(_amounts[i]);
        }
    }

    /**
     * EXTERNAL VIEW FUNCTIONS
     */

    /**
     * @notice Returns the balance of the sum of all strategies for a given token
     * @dev This function would make deposits more expensive for the more strategies
     * that are added for a given token
     * @param _token The address of the token
     */
    function balanceOf(address _token) external view override returns (uint256 _balance) {
        uint256 k = tokenStrategies[_token].strategies.length;
        for (uint i = 0; i < k; i++) {
            IStrategy _strategy = IStrategy(tokenStrategies[_token].strategies[i]);
            address _want = _strategy.want();
            if (_want != _token) {
                address _converter = converters[_token][_want];
                _balance = _balance.add(IConverter(_converter).convert_rate(
                    _want,
                    _token,
                    _strategy.balanceOf()
               ));
            } else {
                _balance = _balance.add(_strategy.balanceOf());
            }
        }
    }

    /**
     * @notice Returns the cap of a strategy for a given token
     * @param _token The address of the token
     * @param _strategy The address of the strategy
     */
    function getCap(address _token, address _strategy) external view returns (uint256) {
        return tokenStrategies[_token].caps[_strategy];
    }

    /**
     * @notice Returns whether investing is enabled for the calling vault
     * @dev Should be called by the vault
     */
    function investEnabled() external view override returns (bool) {
        if (globalInvestEnabled) {
            return tokenStrategies[vaultTokens[msg.sender]].strategies.length > 0;
        }
        return false;
    }

    /**
     * @notice Returns all the strategies for a given token
     * @param _token The address of the token
     */
    function strategies(address _token) external view returns (address[] memory) {
        return tokenStrategies[_token].strategies;
    }

    /**
     * @notice Returns the want address of a given token
     * @dev Since strategies can have different want tokens, default to using the
     * want token of the vault for a given token.
     * @param _token The address of the token
     */
    function want(address _token) external view override returns (address) {
        return IMetaVault(vaults[_token]).want();
    }

    /**
     * @notice Returns the fee for withdrawing a specified amount
     * @param _amount The amount that will be withdrawn
     */
    function withdrawFee(
        address,
        uint256 _amount
    ) external view override returns (uint256 _fee) {
        return vaultManager.withdrawalProtectionFee().mul(_amount).div(10000);
    }

    /**
     * PUBLIC VIEW FUNCTIONS
     */

    /**
     * @notice Returns the best (optimistic) strategy for funds to be sent to with earn
     * @param _token The address of the token
     * @param _amount The amount that will be invested
     */
    function getBestStrategyEarn(
        address _token,
        uint256 _amount
    ) public view returns (address _strategy) {
        // get the index of the last strategy
        uint256 k = tokenStrategies[_token].strategies.length;
        // scan backwards from the index to the beginning of strategies
        for (uint i = k; i > 0; i--) {
            _strategy = tokenStrategies[_token].strategies[i - 1];
            // get the new balance if the _amount were added to the strategy
            uint256 balance = IStrategy(_strategy).balanceOf().add(_amount);
            uint256 cap = tokenStrategies[_token].caps[_strategy];
            // stop scanning if the deposit wouldn't go over the cap
            if (balance <= cap || cap == 0) {
                break;
            }
        }
        // if never broken from the loop, use the last scanned strategy
        // this could cause it to go over cap if (for some reason) no strategies
        // were added with 0 cap
    }

    /**
     * @notice Returns the best (optimistic) strategy for funds to be withdrawn from
     * @dev Since Solidity doesn't support dynamic arrays in memory, the returned arrays
     * from this function will always be the same length as the amount of strategies for
     * a token. Check that _strategies[i] != address(0) when consuming to know when to
     * break out of the loop.
     * @param _token The address of the token
     * @param _amount The amount that will be withdrawn
     */
    function getBestStrategyWithdraw(
        address _token,
        uint256 _amount
    ) public view returns (
        address[] memory _strategies,
        uint256[] memory _amounts
    ) {
        // get the length of strategies
        uint256 k = tokenStrategies[_token].strategies.length;
        // initialize fixed-length memory arrays
        _strategies = new address[](k);
        _amounts = new uint256[](k);
        // scan forward from the the beginning of strategies
        for (uint i = 0; i < k; i++) {
            address _strategy = tokenStrategies[_token].strategies[i];
            _strategies[i] = _strategy;
            // get the balance of the strategy
            uint256 _balance = IStrategy(_strategy).balanceOf();
            // if the strategy doesn't have the balance to cover the withdraw
            if (_balance < _amount) {
                // withdraw what we can and add to the _amounts
                _amounts[i] = _balance;
                _amount = _amount.sub(_balance);
            } else {
                // stop scanning if the balance is more than the withdraw amount
                _amounts[i] = _amount;
                break;
            }
        }
    }

    /**
     * MODIFIERS
     */

    modifier onlyGovernance() {
        require(msg.sender == vaultManager.governance(), "!governance");
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == vaultManager.strategist()
             || msg.sender == vaultManager.governance(),
             "!strategist"
        );
        _;
    }

    modifier onlyHarvester() {
        require(
            msg.sender == vaultManager.harvester() ||
            msg.sender == vaultManager.strategist() ||
            msg.sender == vaultManager.governance(),
            "!harvester"
        );
        _;
    }

    modifier onlyVault(address _token) {
        require(msg.sender == vaults[_token], "!vault");
        _;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

pragma solidity 0.6.12;

interface IConverter {
    function token() external view returns (address _share);
    function convert(
        address _input,
        address _output,
        uint _inputAmount
    ) external returns (uint _outputAmount);
    function convert_rate(
        address _input,
        address _output,
        uint _inputAmount
    ) external view returns (uint _outputAmount);
    function convert_stables(
        uint[3] calldata amounts
    ) external returns (uint _shareAmount); // 0: DAI, 1: USDC, 2: USDT
    function calc_token_amount(
        uint[3] calldata amounts,
        bool deposit
    ) external view returns (uint _shareAmount);
    function calc_token_amount_withdraw(
        uint _shares,
        address _output
    ) external view returns (uint _outputAmount);
    function setStrategy(address _strategy, bool _status) external;
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

pragma solidity 0.6.12;

interface IMetaVault {
    function balance() external view returns (uint);
    function setController(address _controller) external;
    function claimInsurance() external;
    function token() external view returns (address);
    function available() external view returns (uint);
    function withdrawFee(uint _amount) external view returns (uint);
    function earn() external;
    function calc_token_amount_deposit(uint[3] calldata amounts) external view returns (uint);
    function calc_token_amount_withdraw(uint _shares, address _output) external view returns (uint);
    function convert_rate(address _input, uint _amount) external view returns (uint);
    function deposit(uint _amount, address _input, uint _min_mint_amount, bool _isStake) external;
    function harvest(address reserve, uint amount) external;
    function withdraw(uint _shares, address _output) external;
    function want() external view returns (address);
    function getPricePerFullShare() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IStrategy {
    function balanceOf() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);
    function balanceOfWant() external view returns (uint256);
    function deposit() external;
    function harvest() external;
    function name() external view returns (string memory);
    function skim() external;
    function want() external view returns (address);
    function withdraw(address) external;
    function withdraw(uint256) external;
    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../IStableSwap3Pool.sol";
import "../ISwap.sol";
import "../IVaultManager.sol";
import "../IStrategy.sol";
import "../IController.sol";

/**
 * @title BaseStrategy
 * @notice The BaseStrategy is an abstract contract which all
 * yAxis strategies should inherit functionality from. It gives
 * specific security properties which make it hard to write an
 * insecure strategy.
 * @notice All state-changing functions implemented in the strategy
 * should be internal, since any public or externally-facing functions
 * are already handled in the BaseStrategy.
 * @notice The following functions must be implemented by a strategy:
 * - function _deposit() internal virtual;
 * - function _harvest() internal virtual;
 * - function _withdraw(uint256 _amount) internal virtual;
 * - function _withdrawAll() internal virtual;
 * - function balanceOfPool() public view override virtual returns (uint256);
 */
abstract contract BaseStrategy is IStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public constant ONE_HUNDRED_PERCENT = 10000;

    address public immutable override want;
    address public immutable weth;
    address public immutable controller;
    IVaultManager public immutable vaultManager;

    string public override name;
    ISwap public router;

    event ApproveForSpender(address token, address spender, uint256 amount);
    event SetController(address controller);
    event SetRouter(address router);
    event Skim();
    event Withdraw(address vault, uint256 amount);

    /**
     * @param _controller The address of the controller
     * @param _vaultManager The address of the vaultManager
     * @param _want The desired token of the strategy
     * @param _weth The address of WETH
     * @param _router The address of the router for swapping tokens
     */
    constructor(
        string memory _name,
        address _controller,
        address _vaultManager,
        address _want,
        address _weth,
        address _router
    ) public {
        require(_controller != address(0), "!_controller");
        require(_vaultManager != address(0), "!_vaultManager");
        require(_want != address(0), "!_want");
        require(_weth != address(0), "!_weth");
        require(_router != address(0), "!_router");
        name = _name;
        want = _want;
        controller = _controller;
        vaultManager = IVaultManager(_vaultManager);
        weth = _weth;
        router = ISwap(_router);
        IERC20(_weth).safeApprove(address(_router), type(uint256).max);
    }

    /**
     * GOVERNANCE-ONLY FUNCTIONS
     */

    /**
     * @notice Approves a token address to be spent by an address
     * @param _token The address of the token
     * @param _spender The address of the spender
     * @param _amount The amount to spend
     */
    function approveForSpender(IERC20 _token, address _spender, uint256 _amount) external {
        require(msg.sender == vaultManager.governance(), "!governance");
        _token.safeApprove(_spender, _amount);
        emit ApproveForSpender(address(_token), _spender, _amount);
    }

    /**
     * @notice Sets the address of the ISwap-compatible router
     * @param _router The address of the router
     */
    function setRouter(address _router) external {
        require(msg.sender == vaultManager.governance(), "!governance");
        router = ISwap(_router);
        IERC20(weth).safeApprove(address(_router), 0);
        IERC20(weth).safeApprove(address(_router), type(uint256).max);
        emit SetRouter(_router);
    }

    /**
     * AUTHORIZED-ONLY FUNCTIONS
     */

    /**
     * @notice Deposits funds to the strategy's pool
     */
    function deposit() external override onlyAuthorized {
        _deposit();
    }

    /**
     * @notice Harvest funds in the strategy's pool
     */
    function harvest() external override onlyAuthorized {
        _harvest();
    }

    /**
     * @notice Sends stuck want tokens in the strategy to the controller
     */
    function skim() external override onlyAuthorized {
        IERC20(want).safeTransfer(controller, balanceOfWant());
        emit Skim();
    }

    /**
     * @notice Sends stuck tokens in the strategy to the controller
     * @param _asset The address of the token to withdraw
     */
    function withdraw(address _asset) external override onlyAuthorized {
        require(want != _asset, "want");

        IERC20 _assetToken = IERC20(_asset);
        uint256 _balance = _assetToken.balanceOf(address(this));
        _assetToken.safeTransfer(controller, _balance);
    }

    /**
     * @notice Initiated from a vault, withdraws funds from the pool
     * @param _amount The amount of the want token to withdraw
     */
    function withdraw(uint256 _amount) external override onlyAuthorized {
        uint256 _balance = balanceOfWant();
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        address _token = _vaultWant();
        address _vault = IController(controller).vaults(_token);
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(_token).safeTransfer(_vault, _amount);
        emit Withdraw(_vault, _amount);
    }

    /**
     * @notice Withdraws all funds from the strategy
     */
    function withdrawAll() external override onlyAuthorized {
        _withdrawAll();

        address _token = _vaultWant();
        uint256 _balance = IERC20(_token).balanceOf(address(this));

        address _vault = IController(controller).vaults(_token);
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(_token).safeTransfer(_vault, _balance);
        emit Withdraw(_vault, _balance);
    }

    /**
     * EXTERNAL VIEW FUNCTIONS
     */

    /**
     * @notice Returns the strategy's balance of the want token plus the balance of pool
     */
    function balanceOf() external override view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    /**
     * PUBLIC VIEW FUNCTIONS
     */

    /**
     * @notice Returns the balance of the pool
     * @dev Must be implemented by the strategy
     */
    function balanceOfPool() public view override virtual returns (uint256);

    /**
     * @notice Returns the balance of the want token on the strategy
     */
    function balanceOfWant() public view override returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    /**
     * INTERNAL FUNCTIONS
     */

    function _deposit() internal virtual;

    function _harvest() internal virtual;

    function _payHarvestFees(
        address _poolToken
    ) internal returns (uint256 _wethBal) {
        uint256 _amount = IERC20(_poolToken).balanceOf(address(this));
        _swapTokens(_poolToken, weth, _amount);
        _wethBal = IERC20(weth).balanceOf(address(this));

        if (_wethBal > 0) {
            // get all the necessary variables in a single call
            (
                address yax,
                address stakingPool,
                uint256 stakingPoolShareFee,
                address treasury,
                uint256 treasuryFee,
                address insurance,
                uint256 insurancePoolFee
            ) = vaultManager.getHarvestFeeInfo();

            uint256 _fee;

            // pay the staking pool with YAX
            if (stakingPoolShareFee > 0 && stakingPool != address(0)) {
                _fee = _wethBal.mul(stakingPoolShareFee).div(ONE_HUNDRED_PERCENT);
                _swapTokens(weth, yax, _fee);
                IERC20(yax).safeTransfer(stakingPool, IERC20(yax).balanceOf(address(this)));
            }

            // pay the treasury with YAX
            if (treasuryFee > 0 && treasury != address(0)) {
                _fee = _wethBal.mul(treasuryFee).div(ONE_HUNDRED_PERCENT);
                _swapTokens(weth, yax, _fee);
                IERC20(yax).safeTransfer(treasury, IERC20(yax).balanceOf(address(this)));
            }

            // pay the insurance pool with YAX
            if (insurancePoolFee > 0 && insurance != address(0)) {
                _fee = _wethBal.mul(insurancePoolFee).div(ONE_HUNDRED_PERCENT);
                _swapTokens(weth, yax, _fee);
                IERC20(yax).safeTransfer(insurance, IERC20(yax).balanceOf(address(this)));
            }

            // return the remaining WETH balance
            _wethBal = IERC20(weth).balanceOf(address(this));
        }
    }

    function _swapTokens(address _input, address _output, uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = _input;
        path[1] = _output;
        router.swapExactTokensForTokens(
            _amount,
            1,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp.add(1800)
        );
    }

    function _vaultWant() internal returns (address) {
        return IController(controller).strategyTokens(address(this));
    }

    function _withdraw(uint256 _amount) internal virtual;

    function _withdrawAll() internal virtual;

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        address _token = _vaultWant();
        uint256 _before = IERC20(_token).balanceOf(address(this));
        _withdraw(_amount);
        uint256 _after = IERC20(_token).balanceOf(address(this));
        _amount = _after.sub(_before);

        return _amount;
    }

    /**
     * MODIFIERS
     */

    modifier onlyAuthorized() {
        require(msg.sender == controller
             || msg.sender == vaultManager.strategist()
             || msg.sender == vaultManager.governance(),
             "!authorized"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

pragma solidity 0.6.12;

interface IStableSwap3Pool {
    function get_virtual_price() external view returns (uint);
    function balances(uint) external view returns (uint);
    function get_dy(int128 i, int128 j, uint dx) external view returns (uint dy);
    function exchange(int128 i, int128 j, uint dx, uint min_dy) external;
    function add_liquidity(uint[3] calldata amounts, uint min_mint_amount) external;
    function remove_liquidity(uint _amount, uint[3] calldata amounts) external;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_amount) external;
    function calc_token_amount(uint[3] calldata amounts, bool deposit) external view returns (uint);
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface ISwap {
    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../interfaces/YearnV2.sol";
import "../IConverter.sol";
import "./BaseStrategy.sol";

contract StrategyYearnV2 is BaseStrategy {
    address public immutable yvToken;
    IConverter public converter;

    constructor(
        string memory _name,
        address _yvToken,
        address _underlying,
        address _converter,
        address _controller,
        address _vaultManager,
        address _weth,
        address _router
    )
        public
        BaseStrategy(
            _name,
            _controller,
            _vaultManager,
            _underlying,
            _weth,
            _router
        )
    {
        require(_yvToken != address(0), "!_yvToken");
        require(_converter != address(0), "!_converter");
        yvToken = _yvToken;
        converter = IConverter(_converter);
        IERC20(_underlying).safeApprove(_converter, type(uint256).max);
        IERC20(_underlying).safeApprove(_yvToken, type(uint256).max);
    }

    function balanceOfPool() public view override returns (uint256) {
        if (ERC20(yvToken).totalSupply() == 0) {
            return 0;
        }
        uint256 balance = IERC20(yvToken).balanceOf(address(this));
        return balance
            .mul(IYearnV2Vault(yvToken).pricePerShare())
            .div(1e18);
    }

    function _deposit() internal override {
        IYearnV2Vault(yvToken).deposit();
    }

    function _harvest() internal override {
        // TODO: add a way to harvest the interest earned amount
        return;
    }

    function _withdraw(uint256 _amount) internal override {
        IYearnV2Vault vaultToken = IYearnV2Vault(yvToken);
        _amount = _amount.mul(1e18).div(vaultToken.pricePerShare());
        vaultToken.withdraw(_amount);
        _amount = balanceOfWant();
        if (_amount > 0) {
            _convert(want, _vaultWant(), _amount);
        }
    }

    function _withdrawAll() internal override {
        uint256 balance = IERC20(yvToken).balanceOf(address(this));
        IYearnV2Vault(yvToken).withdraw();

        balance = balanceOfWant();
        if (balance > 0) {
            _convert(want, _vaultWant(), balance);
        }
    }

    function _convert(address _from, address _to, uint256 _amount) internal {
        require(converter.convert_rate(_from, _to, _amount) > 0, "!convert_rate");
        IERC20(_from).safeTransfer(address(converter), _amount);
        converter.convert(_from, _to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
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
pragma solidity ^0.6.2;

interface IYearnV2Vault {
    function deposit(uint256 amount) external returns (uint256);
    function deposit() external returns (uint256);
    function withdraw(uint256 shares) external;
    function withdraw() external;
    function pricePerShare() external view returns (uint256);
    function token() external view returns (address);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/GSN/Context.sol";

import "./IVaultManager.sol";
import "./IController.sol";
import "./IConverter.sol";
import "./IMetaVault.sol";

/**
 * @title yAxisMetaVault
 * @notice The metavault is where users deposit and withdraw stablecoins
 * @dev This metavault will pay YAX incentive for depositors and stakers
 * It does not need minter key of YAX. Governance multisig will mint total
 * of 34000 YAX and send into the vault in the beginning
 */
contract yAxisMetaVault is ERC20, IMetaVault {
    using Address for address;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20[4] public inputTokens; // DAI, USDC, USDT, 3Crv

    IERC20 public token3CRV;
    IERC20 public tokenYAX;

    uint public min = 9500;
    uint public constant max = 10000;

    uint public earnLowerlimit = 5 ether; // minimum to invest is 5 3CRV
    uint public totalDepositCap = 10000000 ether; // initial cap set at 10 million dollar

    address public governance;
    address public controller;
    uint public insurance;
    IVaultManager public vaultManager;
    IConverter public converter;

    bool public acceptContractDepositor = false; // dont accept contract at beginning

    struct UserInfo {
        uint amount;
        uint yaxRewardDebt;
        uint accEarned;
    }

    uint public lastRewardBlock;
    uint public accYaxPerShare;

    uint public yaxPerBlock;

    mapping(address => UserInfo) public userInfo;

    address public treasuryWallet = 0x362Db1c17db4C79B51Fe6aD2d73165b1fe9BaB4a;

    uint public constant BLOCKS_PER_WEEK = 46500;

    // Block number when each epoch ends.
    uint[5] public epochEndBlocks;

    // Reward multipler for each of 5 epoches (epochIndex: reward multipler)
    uint[6] public epochRewardMultiplers = [86000, 64000, 43000, 21000, 10000, 1];

    /**
     * @notice Emitted when a user deposits funds
     */
    event Deposit(address indexed user, uint amount);

    /**
     * @notice Emitted when a user withdraws funds
     */
    event Withdraw(address indexed user, uint amount);

    /**
     * @notice Emitted when YAX is paid to a user
     */
    event RewardPaid(address indexed user, uint reward);

    /**
     * @param _tokenDAI The address of the DAI token
     * @param _tokenUSDC The address of the USDC token
     * @param _tokenUSDT The address of the USDT token
     * @param _token3CRV The address of the 3CRV token
     * @param _tokenYAX The address of the YAX token
     * @param _yaxPerBlock The amount of YAX rewarded per block
     * @param _startBlock The starting block for rewards
     */
    constructor (IERC20 _tokenDAI, IERC20 _tokenUSDC, IERC20 _tokenUSDT, IERC20 _token3CRV, IERC20 _tokenYAX,
        uint _yaxPerBlock, uint _startBlock) public ERC20("yAxis.io:MetaVault:3CRV", "MVLT") {
        inputTokens[0] = _tokenDAI;
        inputTokens[1] = _tokenUSDC;
        inputTokens[2] = _tokenUSDT;
        inputTokens[3] = _token3CRV;
        token3CRV = _token3CRV;
        tokenYAX = _tokenYAX;
        yaxPerBlock = _yaxPerBlock; // supposed to be 0.000001 YAX (1000000000000 = 1e12 wei)
        lastRewardBlock = (_startBlock > block.number) ? _startBlock : block.number; // supposed to be 11,163,000 (Sat Oct 31 2020 06:30:00 GMT+0)
        epochEndBlocks[0] = lastRewardBlock + BLOCKS_PER_WEEK * 2; // weeks 1-2
        epochEndBlocks[1] = epochEndBlocks[0] + BLOCKS_PER_WEEK * 2; // weeks 3-4
        epochEndBlocks[2] = epochEndBlocks[1] + BLOCKS_PER_WEEK * 4; // month 2
        epochEndBlocks[3] = epochEndBlocks[2] + BLOCKS_PER_WEEK * 8; // month 3-4
        epochEndBlocks[4] = epochEndBlocks[3] + BLOCKS_PER_WEEK * 8; // month 5-6
        governance = msg.sender;
    }

    /**
     * @dev Throws if called by a contract and we are not allowing.
     */
    modifier checkContract() {
        if (!acceptContractDepositor) {
            require(!address(msg.sender).isContract() && msg.sender == tx.origin, "Sorry we do not accept contract!");
        }
        _;
    }

    /**
     * @notice Returns the current token3CRV balance of the vault and controller, minus insurance
     * @dev Ignore insurance fund for balance calculations
     */
    function balance() public override view returns (uint) {
        uint bal = token3CRV.balanceOf(address(this));
        if (controller != address(0)) bal = bal.add(IController(controller).balanceOf(address(token3CRV)));
        return bal.sub(insurance);
    }

    /**
     * @notice Called by Governance to set the value for min
     * @param _min The new min value
     */
    function setMin(uint _min) external {
        require(msg.sender == governance, "!governance");
        min = _min;
    }

    /**
     * @notice Called by Governance to set the value for the governance address
     * @param _governance The new governance value
     */
    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    /**
     * @notice Called by Governance to set the value for the controller address
     * @param _controller The new controller value
     */
    function setController(address _controller) public override {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    /**
     * @notice Called by Governance to set the value for the converter address
     * @param _converter The new converter value
     * @dev Requires that the return address of token() from the converter is the
     * same as token3CRV
     */
    function setConverter(IConverter _converter) public {
        require(msg.sender == governance, "!governance");
        require(_converter.token() == address(token3CRV), "!token3CRV");
        converter = _converter;
    }

    /**
     * @notice Called by Governance to set the value for the vaultManager address
     * @param _vaultManager The new vaultManager value
     */
    function setVaultManager(IVaultManager _vaultManager) public {
        require(msg.sender == governance, "!governance");
        vaultManager = _vaultManager;
    }

    /**
     * @notice Called by Governance to set the value for the earnLowerlimit
     * @dev earnLowerlimit determines the minimum balance of this contract for earn
     * to be called
     * @param _earnLowerlimit The new earnLowerlimit value
     */
    function setEarnLowerlimit(uint _earnLowerlimit) public {
        require(msg.sender == governance, "!governance");
        earnLowerlimit = _earnLowerlimit;
    }

    /**
     * @notice Called by Governance to set the value for the totalDepositCap
     * @dev totalDepositCap is the maximum amount of value that can be deposited
     * to the metavault at a time
     * @param _totalDepositCap The new totalDepositCap value
     */
    function setTotalDepositCap(uint _totalDepositCap) public {
        require(msg.sender == governance, "!governance");
        totalDepositCap = _totalDepositCap;
    }

    /**
     * @notice Called by Governance to set the value for acceptContractDepositor
     * @dev acceptContractDepositor allows the metavault to accept deposits from
     * smart contract addresses
     * @param _acceptContractDepositor The new acceptContractDepositor value
     */
    function setAcceptContractDepositor(bool _acceptContractDepositor) public {
        require(msg.sender == governance, "!governance");
        acceptContractDepositor = _acceptContractDepositor;
    }

    /**
     * @notice Called by Governance to set the value for yaxPerBlock
     * @dev Makes a call to updateReward()
     * @param _yaxPerBlock The new yaxPerBlock value
     */
    function setYaxPerBlock(uint _yaxPerBlock) public {
        require(msg.sender == governance, "!governance");
        updateReward();
        yaxPerBlock = _yaxPerBlock;
    }

    /**
     * @notice Called by Governance to set the value for epochEndBlocks at the given index
     * @dev Throws if _index >= 5
     * @dev Throws if _epochEndBlock > the current block.number
     * @dev Throws if the stored block.number at the given index is > the current block.number
     * @param _index The index to set of epochEndBlocks
     * @param _epochEndBlock The new epochEndBlocks value at the index
     */
    function setEpochEndBlock(uint8 _index, uint256 _epochEndBlock) public {
        require(msg.sender == governance, "!governance");
        require(_index < 5, "_index out of range");
        require(_epochEndBlock > block.number, "Too late to update");
        require(epochEndBlocks[_index] > block.number, "Too late to update");
        epochEndBlocks[_index] = _epochEndBlock;
    }

    /**
     * @notice Called by Governance to set the value for epochRewardMultiplers at the given index
     * @dev Throws if _index < 1 or > 5
     * @dev Throws if the stored block.number at the previous index is > the current block.number
     * @param _index The index to set of epochRewardMultiplers
     * @param _epochRewardMultipler The new epochRewardMultiplers value at the index
     */
    function setEpochRewardMultipler(uint8 _index, uint256 _epochRewardMultipler) public {
        require(msg.sender == governance, "!governance");
        require(_index > 0 && _index < 6, "Index out of range");
        require(epochEndBlocks[_index - 1] > block.number, "Too late to update");
        epochRewardMultiplers[_index] = _epochRewardMultipler;
    }

    /**
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from The from block
     * @param _to The to block
     */
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        // start at the end of the epochs
        for (uint8 epochId = 5; epochId >= 1; --epochId) {
            // if _to (the current block number if called within this contract) is after the previous epoch ends
            if (_to >= epochEndBlocks[epochId - 1]) {
                // if the last reward block is after the previous epoch: return the number of blocks multiplied by this epochs multiplier
                if (_from >= epochEndBlocks[epochId - 1]) return _to.sub(_from).mul(epochRewardMultiplers[epochId]);
                // get the multiplier amount for the remaining reward of the current epoch
                uint256 multiplier = _to.sub(epochEndBlocks[epochId - 1]).mul(epochRewardMultiplers[epochId]);
                // if epoch is 1: return the remaining current epoch reward with the first epoch reward
                if (epochId == 1) return multiplier.add(epochEndBlocks[0].sub(_from).mul(epochRewardMultiplers[0]));
                // for all epochs in between the first and current epoch
                for (epochId = epochId - 1; epochId >= 1; --epochId) {
                    // if the last reward block is after the previous epoch: return the current remaining reward with the previous epoch
                    if (_from >= epochEndBlocks[epochId - 1]) return multiplier.add(epochEndBlocks[epochId].sub(_from).mul(epochRewardMultiplers[epochId]));
                    // accumulate the multipler with the reward from the epoch
                    multiplier = multiplier.add(epochEndBlocks[epochId].sub(epochEndBlocks[epochId - 1]).mul(epochRewardMultiplers[epochId]));
                }
                // return the accumulated multiplier with the reward from the first epoch
                return multiplier.add(epochEndBlocks[0].sub(_from).mul(epochRewardMultiplers[0]));
            }
        }
        // return the reward amount between _from and _to in the first epoch
        return _to.sub(_from).mul(epochRewardMultiplers[0]);
    }

    /**
     * @notice Called by Governance to set the value for the treasuryWallet
     * @param _treasuryWallet The new treasuryWallet value
     */
    function setTreasuryWallet(address _treasuryWallet) public {
        require(msg.sender == governance, "!governance");
        treasuryWallet = _treasuryWallet;
    }

    /**
     * @notice Called by Governance or the controller to claim the amount stored in the insurance fund
     * @dev If called by the controller, insurance will auto compound the vault, increasing getPricePerFullShare
     */
    function claimInsurance() external override {
        // if claim by controller for auto-compounding (current insurance will stay to increase sharePrice)
        // otherwise send the fund to treasuryWallet
        if (msg.sender != controller) {
            // claim by governance for insurance
            require(msg.sender == governance, "!governance");
            token3CRV.safeTransfer(treasuryWallet, insurance);
        }
        insurance = 0;
    }

    /**
     * @notice Get the address of the 3CRV token
     */
    function token() public override view returns (address) {
        return address(token3CRV);
    }

    /**
     * @notice Get the amount that the metavault allows to be borrowed
     * @dev min and max are used to keep small withdrawals cheap
     */
    function available() public override view returns (uint) {
        return token3CRV.balanceOf(address(this)).mul(min).div(max);
    }

    /**
     * @notice If the controller is set, returns the withdrawFee of the 3CRV token for the given _amount
     * @param _amount The amount being queried to withdraw
     */
    function withdrawFee(uint _amount) public override view returns (uint) {
        return (controller == address(0)) ? 0 : IController(controller).withdrawFee(address(token3CRV), _amount);
    }

    /**
     * @notice Sends accrued 3CRV tokens on the metavault to the controller to be deposited to strategies
     */
    function earn() public override {
        if (controller != address(0)) {
            IController _contrl = IController(controller);
            if (_contrl.investEnabled()) {
                uint _bal = available();
                token3CRV.safeTransfer(controller, _bal);
                _contrl.earn(address(token3CRV), _bal);
            }
        }
    }

    /**
     * @notice Returns the amount of 3CRV given for the amounts deposited
     * @param amounts The stablecoin amounts being deposited
     */
    function calc_token_amount_deposit(uint[3] calldata amounts) external override view returns (uint) {
        return converter.calc_token_amount(amounts, true);
    }

    /**
     * @notice Returns the amount given in the desired token for the given shares
     * @param _shares The amount of shares to withdraw
     * @param _output The desired token to withdraw
     */
    function calc_token_amount_withdraw(uint _shares, address _output) external override view returns (uint) {
        uint _withdrawFee = withdrawFee(_shares);
        if (_withdrawFee > 0) {
            _shares = _shares.mul(10000 - _withdrawFee).div(10000);
        }
        uint r = (balance().mul(_shares)).div(totalSupply());
        if (_output == address(token3CRV)) {
            return r;
        }
        return converter.calc_token_amount_withdraw(r, _output);
    }

    /**
     * @notice Returns the amount of 3CRV that would be given for the amount of input tokens
     * @param _input The stablecoin to convert to 3CRV
     * @param _amount The amount of stablecoin to convert
     */
    function convert_rate(address _input, uint _amount) external override view returns (uint) {
        return converter.convert_rate(_input, address(token3CRV), _amount);
    }

    /**
     * @notice Deposit a single stablecoin to the metavault
     * @dev Users must approve the metavault to spend their stablecoin
     * @param _amount The amount of the stablecoin to deposit
     * @param _input The address of the stablecoin being deposited
     * @param _min_mint_amount The expected amount of shares to receive
     * @param _isStake Stakes shares or not
     */
    function deposit(uint _amount, address _input, uint _min_mint_amount, bool _isStake) external override checkContract {
        require(_amount > 0, "!_amount");
        uint _pool = balance();
        uint _before = token3CRV.balanceOf(address(this));
        if (_input == address(token3CRV)) {
            token3CRV.safeTransferFrom(msg.sender, address(this), _amount);
        } else if (converter.convert_rate(_input, address(token3CRV), _amount) > 0) {
            IERC20(_input).safeTransferFrom(msg.sender, address(converter), _amount);
            converter.convert(_input, address(token3CRV), _amount);
        }
        uint _after = token3CRV.balanceOf(address(this));
        require(totalDepositCap == 0 || _after <= totalDepositCap, ">totalDepositCap");
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        require(_amount >= _min_mint_amount, "slippage");
        if (_amount > 0) {
            if (!_isStake) {
                _deposit(msg.sender, _pool, _amount);
            } else {
                uint _shares = _deposit(address(this), _pool, _amount);
                _stakeShares(_shares);
            }
        }
    }

    /**
     * @notice Deposits multiple stablecoins simultaneously to the metavault
     * @dev 0: DAI, 1: USDC, 2: USDT, 3: 3CRV
     * @dev Users must approve the metavault to spend their stablecoin
     * @param _amounts The amounts of each stablecoin being deposited
     * @param _min_mint_amount The expected amount of shares to receive
     * @param _isStake Stakes shares or not
     */
    function depositAll(uint[4] calldata _amounts, uint _min_mint_amount, bool _isStake) external checkContract {
        uint _pool = balance();
        uint _before = token3CRV.balanceOf(address(this));
        bool hasStables = false;
        for (uint8 i = 0; i < 4; i++) {
            uint _inputAmount = _amounts[i];
            if (_inputAmount > 0) {
                if (i == 3) {
                    inputTokens[i].safeTransferFrom(msg.sender, address(this), _inputAmount);
                } else if (converter.convert_rate(address(inputTokens[i]), address(token3CRV), _inputAmount) > 0) {
                    inputTokens[i].safeTransferFrom(msg.sender, address(converter), _inputAmount);
                    hasStables = true;
                }
            }
        }
        if (hasStables) {
            uint[3] memory _stablesAmounts;
            _stablesAmounts[0] = _amounts[0];
            _stablesAmounts[1] = _amounts[1];
            _stablesAmounts[2] = _amounts[2];
            converter.convert_stables(_stablesAmounts);
        }
        uint _after = token3CRV.balanceOf(address(this));
        require(totalDepositCap == 0 || _after <= totalDepositCap, ">totalDepositCap");
        uint _totalDepositAmount = _after.sub(_before); // Additional check for deflationary tokens
        require(_totalDepositAmount >= _min_mint_amount, "slippage");
        if (_totalDepositAmount > 0) {
            if (!_isStake) {
                _deposit(msg.sender, _pool, _totalDepositAmount);
            } else {
                uint _shares = _deposit(address(this), _pool, _totalDepositAmount);
                _stakeShares(_shares);
            }
        }
    }

    /**
     * @notice Stakes metavault shares
     * @param _shares The amount of shares to stake
     */
    function stakeShares(uint _shares) external {
        uint _before = balanceOf(address(this));
        IERC20(address(this)).transferFrom(msg.sender, address(this), _shares);
        uint _after = balanceOf(address(this));
        _shares = _after.sub(_before);
        // Additional check for deflationary tokens
        _stakeShares(_shares);
    }

    function _deposit(address _mintTo, uint _pool, uint _amount) internal returns (uint _shares) {
        if (address(vaultManager) != address(0)) {
            // expected 0.1% of deposits go into an insurance fund (or auto-compounding if called by controller) in-case of negative profits to protect withdrawals
            // it is updated by governance (community vote)
            uint _insuranceFee = vaultManager.insuranceFee();
            if (_insuranceFee > 0) {
                uint _insurance = _amount.mul(_insuranceFee).div(10000);
                _amount = _amount.sub(_insurance);
                insurance = insurance.add(_insurance);
            }
        }

        if (totalSupply() == 0) {
            _shares = _amount;
        } else {
            _shares = (_amount.mul(totalSupply())).div(_pool);
        }
        if (_shares > 0) {
            if (token3CRV.balanceOf(address(this)) > earnLowerlimit) {
                earn();
            }
            _mint(_mintTo, _shares);
        }
    }

    function _stakeShares(uint _shares) internal {
        UserInfo storage user = userInfo[msg.sender];
        updateReward();
        _getReward();
        user.amount = user.amount.add(_shares);
        user.yaxRewardDebt = user.amount.mul(accYaxPerShare).div(1e12);
        emit Deposit(msg.sender, _shares);
    }

    /**
     * @notice Returns the pending YAXs for a given account
     * @param _account The address to query
     */
    function pendingYax(address _account) public view returns (uint _pending) {
        UserInfo storage user = userInfo[_account];
        uint _accYaxPerShare = accYaxPerShare;
        uint lpSupply = balanceOf(address(this));
        if (block.number > lastRewardBlock && lpSupply != 0) {
            uint256 _multiplier = getMultiplier(lastRewardBlock, block.number);
            _accYaxPerShare = accYaxPerShare.add(_multiplier.mul(yaxPerBlock).mul(1e12).div(lpSupply));
        }
        _pending = user.amount.mul(_accYaxPerShare).div(1e12).sub(user.yaxRewardDebt);
    }

    /**
     * @notice Sets the lastRewardBlock and accYaxPerShare
     */
    function updateReward() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint lpSupply = balanceOf(address(this));
        if (lpSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 _multiplier = getMultiplier(lastRewardBlock, block.number);
        accYaxPerShare = accYaxPerShare.add(_multiplier.mul(yaxPerBlock).mul(1e12).div(lpSupply));
        lastRewardBlock = block.number;
    }

    function _getReward() internal {
        UserInfo storage user = userInfo[msg.sender];
        uint _pendingYax = user.amount.mul(accYaxPerShare).div(1e12).sub(user.yaxRewardDebt);
        if (_pendingYax > 0) {
            user.accEarned = user.accEarned.add(_pendingYax);
            safeYaxTransfer(msg.sender, _pendingYax);
            emit RewardPaid(msg.sender, _pendingYax);
        }
    }

    /**
     * @notice Withdraw the entire balance for an account
     * @param _output The address of the desired stablecoin to receive
     */
    function withdrawAll(address _output) external {
        unstake(userInfo[msg.sender].amount);
        withdraw(balanceOf(msg.sender), _output);
    }

    /**
     * @notice Used to swap any borrowed reserve over the debt limit to liquidate to 'token'
     * @param reserve The address of the token to swap to 3CRV
     * @param amount The amount to swap
     */
    function harvest(address reserve, uint amount) external override {
        require(msg.sender == controller, "!controller");
        require(reserve != address(token3CRV), "token3CRV");
        IERC20(reserve).safeTransfer(controller, amount);
    }

    /**
     * @notice Unstakes the given shares from the metavault
     * @dev call unstake(0) to only receive the reward
     * @param _amount The amount to unstake
     */
    function unstake(uint _amount) public {
        updateReward();
        _getReward();
        UserInfo storage user = userInfo[msg.sender];
        if (_amount > 0) {
            require(user.amount >= _amount, "stakedBal < _amount");
            user.amount = user.amount.sub(_amount);
            IERC20(address(this)).transfer(msg.sender, _amount);
        }
        user.yaxRewardDebt = user.amount.mul(accYaxPerShare).div(1e12);
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @notice Withdraws an amount of shares to a given output stablecoin
     * @dev No rebalance implementation for lower fees and faster swaps
     * @param _shares The amount of shares to withdraw
     * @param _output The address of the stablecoin to receive
     */
    function withdraw(uint _shares, address _output) public override {
        uint _userBal = balanceOf(msg.sender);
        if (_shares > _userBal) {
            uint _need = _shares.sub(_userBal);
            require(_need <= userInfo[msg.sender].amount, "_userBal+staked < _shares");
            unstake(_need);
        }
        uint r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        if (address(vaultManager) != address(0)) {
            // expected 0.1% of withdrawal go back to vault (for auto-compounding) to protect withdrawals
            // it is updated by governance (community vote)
            uint _withdrawalProtectionFee = vaultManager.withdrawalProtectionFee();
            if (_withdrawalProtectionFee > 0) {
                uint _withdrawalProtection = r.mul(_withdrawalProtectionFee).div(10000);
                r = r.sub(_withdrawalProtection);
            }
        }

        // Check balance
        uint b = token3CRV.balanceOf(address(this));
        if (b < r) {
            uint _toWithdraw = r.sub(b);
            if (controller != address(0)) {
                IController(controller).withdraw(address(token3CRV), _toWithdraw);
            }
            uint _after = token3CRV.balanceOf(address(this));
            uint _diff = _after.sub(b);
            if (_diff < _toWithdraw) {
                r = b.add(_diff);
            }
        }

        if (_output == address(token3CRV)) {
            token3CRV.safeTransfer(msg.sender, r);
        } else {
            require(converter.convert_rate(address(token3CRV), _output, r) > 0, "rate=0");
            token3CRV.safeTransfer(address(converter), r);
            uint _outputAmount = converter.convert(address(token3CRV), _output, r);
            IERC20(_output).safeTransfer(msg.sender, _outputAmount);
        }
    }

    /**
     * @notice Returns the address of the 3CRV token
     */
    function want() external override view returns (address) {
        return address(token3CRV);
    }

    /**
     * @notice Returns the rate of earnings of a single share
     */
    function getPricePerFullShare() external override view returns (uint) {
        return balance().mul(1e18).div(totalSupply());
    }

    /**
     * @notice Transfers YAX from the metavault to a given address
     * @dev Ensures the metavault has enough balance to transfer
     * @param _to The address to transfer to
     * @param _amount The amount to transfer
     */
    function safeYaxTransfer(address _to, uint _amount) internal {
        uint _tokenBal = tokenYAX.balanceOf(address(this));
        tokenYAX.safeTransfer(_to, (_tokenBal < _amount) ? _tokenBal : _amount);
    }

    /**
     * @notice Converts non-3CRV stablecoins held in the metavault to 3CRV
     * @param _token The address to convert
     */
    function earnExtra(address _token) public {
        require(msg.sender == governance, "!governance");
        require(address(_token) != address(token3CRV), "3crv");
        require(address(_token) != address(this), "mlvt");
        uint _amount = IERC20(_token).balanceOf(address(this));
        require(converter.convert_rate(_token, address(token3CRV), _amount) > 0, "rate=0");
        IERC20(_token).safeTransfer(address(converter), _amount);
        converter.convert(_token, address(token3CRV), _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../interfaces/GenericVault.sol";
import "../IConverter.sol";
import "./BaseStrategy.sol";

contract StrategyGenericVault is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public vault;
    IConverter public converter;

    /**
     * @param _name The name of the strategy
     * @param _vault The address of the vault
     * @param _converter The address of the converter
     * @param _controller The address of the controller
     * @param _vaultManager The address of the vaultManager
     * @param _weth The address of WETH
     * @param _router The address of the router for swapping tokens
     */
    constructor(
        string memory _name,
        address _vault,
        address _converter,
        address _controller,
        address _vaultManager,
        address _weth,
        address _router
    )
        public
        BaseStrategy(
            _name,
            _controller,
            _vaultManager,
            IGenericVault(_vault).token(),
            _weth,
            _router
        )
    {
        require(_vault != address(0), "!_vault");
        require(_converter != address(0), "!_converter");
        vault = _vault;
        converter = IConverter(_converter);
        IERC20(IGenericVault(_vault).token()).safeApprove(_vault, type(uint256).max);
    }

    function _deposit() internal override {
        uint256 _amount = balanceOfWant();
        if (_amount > 0) {
            IGenericVault(vault).deposit(_amount);
        }
    }

    function _harvest() internal override {
        // Harvest is not necessary for generic vaults
        return;
    }

    function _withdraw(uint256 _amount) internal override {
        _amount = _amount.mul(1e18).div(getPricePerFullShare());
        IGenericVault(vault).withdraw(_amount);
        _amount = balanceOfWant();
        if (_amount > 0) {
            _convert(want, _vaultWant(), _amount);
        }
    }

    function _withdrawAll() internal override {
        uint256 _amount = IERC20(vault).balanceOf(address(this));
        if (_amount > 0) {
            IGenericVault(vault).withdrawAll();
            _amount = balanceOfWant();
            _convert(want, _vaultWant(), _amount);
        }
    }

    // Allow overrideing to implement fee
    function balanceOfPool() public view virtual override returns (uint256) {
        if (ERC20(vault).totalSupply() == 0) return 0;

        return IERC20(vault).balanceOf(address(this))
            .mul(getPricePerFullShare())
            .div(1e18);
    }

    function _convert(address _from, address _to, uint256 _amount) internal {
        require(converter.convert_rate(_from, _to, _amount) > 0, "!convert_rate");
        IERC20(_from).safeTransfer(address(converter), _amount);
        converter.convert(_from, _to, _amount);
    }

    // Allow overriding to change the name
    function getPricePerFullShare() public view virtual returns (uint256) {
        return IGenericVault(vault).getPricePerFullShare();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface IGenericVault {
    function token() external view returns (address);
    function getPricePerFullShare() external view returns (uint256);
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function depositAll() external;
    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./MockERC20.sol";
import "../../interfaces/GenericVault.sol";

contract MockGenericVault is MockERC20 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;

    uint public min = 9500;
    uint public constant max = 10000;

    constructor (address _token) public MockERC20(
        string(abi.encodePacked("Generic Vault ", ERC20(_token).name())),
        string(abi.encodePacked("v", ERC20(_token).symbol())),
        ERC20(_token).decimals()
    ) {
        token = IERC20(_token);
    }

    function balance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function available() public view returns (uint) {
        return token.balanceOf(address(this)).mul(min).div(max);
    }

    function depositAll() external {
        deposit(token.balanceOf(msg.sender));
    }

    function deposit(uint _amount) public {
        uint _pool = balance();
        uint _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint _after = token.balanceOf(address(this));
        _amount = _after.sub(_before);
        uint shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    function withdraw(uint _shares) public {
        uint r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);
        token.safeTransfer(msg.sender, r);
    }

    function getPricePerFullShare() public view returns (uint) {
        return balance().mul(1e18).div(totalSupply());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract MockERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address private _owner;

    uint internal _totalSupply;

    mapping(address => uint)                   private _balance;
    mapping(address => mapping(address => uint)) private _allowance;

    modifier _onlyOwner_() {
        require(msg.sender == _owner, "ERR_NOT_OWNER");
        _;
    }

    event Approval(address indexed src, address indexed dst, uint amt);
    event Transfer(address indexed src, address indexed dst, uint amt);

    // Math
    function add(uint a, uint b) internal pure returns (uint c) {
        require((c = a + b) >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require((c = a - b) <= a);
    }

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _owner = msg.sender;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function _move(address src, address dst, uint amt) internal {
        require(_balance[src] >= amt, "!bal");
        _balance[src] = sub(_balance[src], amt);
        _balance[dst] = add(_balance[dst], amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint amt) internal {
        _move(from, address(this), amt);
    }

    function _mint(address dst, uint amt) internal {
        _balance[dst] = add(_balance[dst], amt);
        _totalSupply = add(_totalSupply, amt);
        emit Transfer(address(0), dst, amt);
    }

    function _burn(address dst, uint amt) internal {
        _balance[dst] = sub(_balance[dst], amt);
        _totalSupply = sub(_totalSupply, amt);
        emit Transfer(dst, address(0), amt);
    }

    function allowance(address src, address dst) external view returns (uint) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) public view returns (uint) {
        return _balance[whom];
    }

    function faucet(uint256 amt) public returns (bool) {
        _mint(msg.sender, amt);
        return true;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function approve(address dst, uint amt) external returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function mint(address dst, uint256 amt) public _onlyOwner_ returns (bool) {
        _mint(dst, amt);
        return true;
    }

    function burn(uint amt) public returns (bool) {
        require(_balance[msg.sender] >= amt, "!bal");
        _burn(msg.sender, amt);
        return true;
    }

    function burnFrom(address src, uint amt) public _onlyOwner_ returns (bool) {
        require(_balance[src] >= amt, "!bal");
        _burn(src, amt);
        return true;
    }

    function transfer(address dst, uint amt) external returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(address src, address dst, uint amt) external returns (bool) {
        require(msg.sender == src || amt <= _allowance[src][msg.sender], "!spender");
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(- 1)) {
            _allowance[src][msg.sender] = sub(_allowance[src][msg.sender], amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }

    function transferOwnership(address newOwner) external _onlyOwner_ {
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/PickleJar.sol";
import "./MockERC20.sol";

contract MockPickleJar is MockERC20 {
    IERC20 public t3crv;
    IERC20 public lpToken;

    constructor(IERC20 _t3crv) public MockERC20("pickling Curve.fi DAI/USDC/USDT", "p3Crv", 18) {
        t3crv = _t3crv;
    }

    function balance() public view returns (uint) {
        return t3crv.balanceOf(address(this));
    }

    function available() external view returns (uint) {
        return balance() * 9500 / 10000;
    }

    function depositAll() external {
        deposit(t3crv.balanceOf(msg.sender));
    }

    function deposit(uint _amount) public {
        t3crv.transferFrom(msg.sender, address(this), _amount);
        uint256 shares = _amount * 1000000000000000000 / getRatio();
        _mint(msg.sender, shares);
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    function withdraw(uint _shares) public {
        uint256 r = _shares * getRatio() / 1000000000000000000;
        _burn(msg.sender, _shares);
        t3crv.transfer(msg.sender, r);
    }

    function getRatio() public pure returns (uint) {
        return 1010000000000000000; // +1%
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface PickleJar {
    function balanceOf(address account) external view returns (uint);
    function balance() external view returns (uint);
    function available() external view returns (uint);
    function depositAll() external;
    function deposit(uint _amount) external;
    function withdrawAll() external;
    function withdraw(uint _shares) external;
    function getRatio() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../IStableSwap3Pool.sol";

import "../../interfaces/PickleJar.sol";
import "../../interfaces/PickleMasterChef.sol";

import "./BaseStrategy.sol";

contract StrategyPickle3Crv is BaseStrategy {
    address public immutable p3crv;

    // used for pickle -> weth -> [stableForAddLiquidity] -> 3crv route
    address public immutable pickle;

    // for add_liquidity via curve.fi to get back 3CRV
    // (set stableForAddLiquidity for the best stable coin used in the route)
    address public immutable dai;
    address public immutable usdc;
    address public immutable usdt;

    PickleJar public immutable pickleJar;
    PickleMasterChef public pickleMasterChef;
    uint256 public poolId = 14;

    IStableSwap3Pool public stableSwap3Pool;
    address public stableForAddLiquidity;

    event SetStableForAddLiquidity(address stableForAddLiquidity);
    event SetPickleMasterChef(address pickleMasterChef);
    event SetPoolId(uint256 poolId);

    constructor(
        string memory _name,
        address _want,
        address _p3crv,
        address _pickle,
        address _weth,
        address _dai,
        address _usdc,
        address _usdt,
        address _stableForAddLiquidity,
        PickleMasterChef _pickleMasterChef,
        IStableSwap3Pool _stableSwap3Pool,
        address _controller,
        address _vaultManager,
        address _router
    )
        public
        BaseStrategy(_name, _controller, _vaultManager, _want, _weth, _router)
    {
        require(_p3crv != address(0), "!_p3crv");
        require(_pickle != address(0), "!_pickle");
        require(_dai != address(0), "!_dai");
        require(_usdc != address(0), "!_usdc");
        require(_usdt != address(0), "!_usdt");
        require(address(_pickleMasterChef) != address(0), "!_pickleMasterChef");
        require(_stableForAddLiquidity != address(0), "!_stableForAddLiquidity");
        require(address(_stableSwap3Pool) != address(0), "!_stableSwap3Pool");
        p3crv = _p3crv;
        pickle = _pickle;
        dai = _dai;
        usdc = _usdc;
        usdt = _usdt;
        pickleMasterChef = _pickleMasterChef;
        stableForAddLiquidity = _stableForAddLiquidity;
        stableSwap3Pool = _stableSwap3Pool;
        pickleJar = PickleJar(_p3crv);
        IERC20(_want).safeApprove(_p3crv, type(uint256).max);
        IERC20(_p3crv).safeApprove(address(_pickleMasterChef), type(uint256).max);
        IERC20(_pickle).safeApprove(address(_router), type(uint256).max);
    }

    function setStableForLiquidity(address _stableForAddLiquidity) external onlyAuthorized {
        require(_stableForAddLiquidity == dai
            || _stableForAddLiquidity == usdc
            || _stableForAddLiquidity == usdt,
            "!_stableForAddLiquidity");
        stableForAddLiquidity = _stableForAddLiquidity;
        emit SetStableForAddLiquidity(_stableForAddLiquidity);
    }

    function setPickleMasterChef(PickleMasterChef _pickleMasterChef) external onlyAuthorized {
        pickleMasterChef = _pickleMasterChef;
        IERC20(p3crv).safeApprove(address(_pickleMasterChef), 0);
        IERC20(p3crv).safeApprove(address(_pickleMasterChef), type(uint256).max);
        emit SetPickleMasterChef(address(_pickleMasterChef));
    }

    function setPoolId(uint _poolId) external onlyAuthorized {
        poolId = _poolId;
        emit SetPoolId(_poolId);
    }

    function _deposit() internal override {
        uint _wantBal = balanceOfWant();
        if (_wantBal > 0) {
            // deposit 3crv to pickleJar
            pickleJar.depositAll();
        }

        uint _p3crvBal = IERC20(p3crv).balanceOf(address(this));
        if (_p3crvBal > 0) {
            // stake p3crv to pickleMasterChef
            pickleMasterChef.deposit(poolId, _p3crvBal);
        }
    }

    function _claimReward() internal {
        pickleMasterChef.withdraw(poolId, 0);
    }

    function _withdrawAll() internal override {
        (uint amount,) = pickleMasterChef.userInfo(poolId, address(this));
        pickleMasterChef.withdraw(poolId, amount);
        pickleJar.withdrawAll();
    }

    // to get back want (3CRV)
    function _addLiquidity() internal {
        // 0: DAI, 1: USDC, 2: USDT
        uint[3] memory amounts;
        amounts[0] = IERC20(dai).balanceOf(address(this));
        amounts[1] = IERC20(usdc).balanceOf(address(this));
        amounts[2] = IERC20(usdt).balanceOf(address(this));
        // add_liquidity(uint[3] calldata amounts, uint min_mint_amount)
        stableSwap3Pool.add_liquidity(amounts, 1);
    }

    function _harvest() internal override {
        _claimReward();
        uint256 _remainingWeth = _payHarvestFees(pickle);

        if (_remainingWeth > 0) {
            _swapTokens(weth, stableForAddLiquidity, _remainingWeth);
            _addLiquidity();

            if (balanceOfWant() > 0) {
                _deposit(); // auto re-invest
            }
        }
    }

    function _withdraw(uint256 _amount) internal override {
        // unstake p3crv from pickleMasterChef
        uint _ratio = pickleJar.getRatio();
        _amount = _amount.mul(1e18).div(_ratio);
        (uint _stakedAmount,) = pickleMasterChef.userInfo(poolId, address(this));
        if (_amount > _stakedAmount) {
            _amount = _stakedAmount;
        }
        uint _before = pickleJar.balanceOf(address(this));
        pickleMasterChef.withdraw(poolId, _amount);
        uint _after = pickleJar.balanceOf(address(this));
        _amount = _after.sub(_before);

        // withdraw 3crv from pickleJar
        pickleJar.withdraw(_amount);
    }

    function balanceOfPool() public view override returns (uint) {
        uint p3crvBal = pickleJar.balanceOf(address(this));
        (uint amount,) = pickleMasterChef.userInfo(poolId, address(this));
        return p3crvBal.add(amount).mul(pickleJar.getRatio()).div(1e18);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface PickleMasterChef {
    function deposit(uint _poolId, uint _amount) external;
    function withdraw(uint _poolId, uint _amount) external;
    function pendingPickle(uint _pid, address _user) external view returns (uint);
    function userInfo(uint _pid, address _user) external view returns (uint amount, uint rewardDebt);
    function emergencyWithdraw(uint _pid) external;
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./IConverter.sol";
import "./IVaultManager.sol";
import "./IStableSwap3Pool.sol";
import "./IStableSwap3PoolOracle.sol";

/**
 * @title StableSwap3PoolConverter
 * @notice The StableSwap3PoolConverter is used to convert funds on Curve's 3Pool.
 * It is backed by Chainlink's price feeds to be secure against attackers.
 */
contract StableSwap3PoolConverter is IConverter {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant ONE_HUNDRED_PERCENT = 10000;

    IVaultManager public immutable vaultManager;
    IStableSwap3PoolOracle public immutable oracle;
    IStableSwap3Pool public immutable stableSwap3Pool;
    IERC20 public immutable token3CRV; // 3Crv

    uint256[3] public PRECISION_MUL = [1, 1e12, 1e12];
    IERC20[3] public tokens; // DAI, USDC, USDT
    uint256 public minSlippage;

    mapping(address => bool) public strategies;

    /**
     * @param _tokenDAI The address of the DAI token
     * @param _tokenUSDC The address of the USDC token
     * @param _tokenUSDT The address of the USDT token
     * @param _token3CRV The address of the 3CRV token
     * @param _stableSwap3Pool The address of 3Pool
     * @param _vaultManager The address of the Vault Manager
     * @param _oracle The address of the StableSwap3PoolOracle
     */
    constructor(
        IERC20 _tokenDAI,
        IERC20 _tokenUSDC,
        IERC20 _tokenUSDT,
        IERC20 _token3CRV,
        IStableSwap3Pool _stableSwap3Pool,
        IVaultManager _vaultManager,
        IStableSwap3PoolOracle _oracle
    ) public {
        tokens[0] = _tokenDAI;
        tokens[1] = _tokenUSDC;
        tokens[2] = _tokenUSDT;
        token3CRV = _token3CRV;
        stableSwap3Pool = _stableSwap3Pool;
        tokens[0].safeApprove(address(_stableSwap3Pool), type(uint256).max);
        tokens[1].safeApprove(address(_stableSwap3Pool), type(uint256).max);
        tokens[2].safeApprove(address(_stableSwap3Pool), type(uint256).max);
        _token3CRV.safeApprove(address(_stableSwap3Pool), type(uint256).max);
        vaultManager = _vaultManager;
        oracle = _oracle;
        minSlippage = 100;
    }

    /**
     * @notice Called by Governance to enable or disable a strategy to use the converter
     * @param _strategy The address of the strategy
     * @param _status The bool flag allowing or disallowing use of the converter by the strategy
     */
    function setStrategy(address _strategy, bool _status) external override onlyGovernance {
        strategies[_strategy] = _status;
    }

    /**
     * @notice Called by the strategist to set the slippage allowed on the minimum tokens received
     * @param _slippage The slippage percentage
     */
    function setMinSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < ONE_HUNDRED_PERCENT, "!_slippage");
        minSlippage = _slippage;
    }

    /**
     * @notice Called by Governance to approve a token address to be spent by an address
     * @param _token The address of the token
     * @param _spender The address of the spender
     * @param _amount The amount to spend
     */
    function approveForSpender(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) external onlyGovernance {
        _token.safeApprove(_spender, _amount);
    }

    /**
     * @notice Returns the address of the 3CRV token
     */
    function token() external view override returns (address) {
        return address(token3CRV);
    }

    /**
     * @notice Returns the expected amount of tokens for a given amount by querying
     * the latest data from Chainlink
     * @param _inputAmount The input amount of tokens that are being converted
     */
    function getExpected(uint256 _inputAmount) public view returns (uint256 _min, uint256 _max) {
        ( _min, _max ) = oracle.getPrices();
        uint256 _eth = oracle.getEthereumPrice();
        _min = _inputAmount.mul(_eth).mul(_min).div(1e18).div(1e18);
        uint256 _slippage = minSlippage;
        if (_slippage > 0) {
            _slippage = _min.mul(_slippage).div(ONE_HUNDRED_PERCENT);
            _min = _min.sub(_slippage);
        }
        _max = _inputAmount.mul(_eth).mul(_max).div(1e18).div(1e18);
    }

    /**
     * @notice Converts the amount of input tokens to output tokens
     * @param _input The address of the token being converted
     * @param _output The address of the token to be converted to
     * @param _inputAmount The input amount of tokens that are being converted
     */
    function convert(
        address _input,
        address _output,
        uint256 _inputAmount
    ) external override onlyAuthorized returns (uint256 _outputAmount) {
        if (_output == address(token3CRV)) { // convert to 3CRV
            uint256[3] memory amounts;
            for (uint8 i = 0; i < 3; i++) {
                if (_input == address(tokens[i])) {
                    ( uint256 _min, uint256 _max ) = getExpected(_inputAmount.mul(PRECISION_MUL[i]));
                    amounts[i] = _inputAmount;
                    uint256 _before = token3CRV.balanceOf(address(this));
                    stableSwap3Pool.add_liquidity(amounts, _min);
                    uint256 _after = token3CRV.balanceOf(address(this));
                    _outputAmount = _after.sub(_before);
                    require(_outputAmount <= _max, ">_max");
                    token3CRV.safeTransfer(msg.sender, _outputAmount);
                    return _outputAmount;
                }
            }
        } else if (_input == address(token3CRV)) { // convert from 3CRV
            ( uint256 _min, uint256 _max ) = getExpected(_inputAmount);
            for (uint8 i = 0; i < 3; i++) {
                if (_output == address(tokens[i])) {
                    uint256 _before = tokens[i].balanceOf(address(this));
                    stableSwap3Pool.remove_liquidity_one_coin(_inputAmount, i, _min.div(PRECISION_MUL[i]));
                    uint256 _after = tokens[i].balanceOf(address(this));
                    _outputAmount = _after.sub(_before);
                    require(_outputAmount <= _max, ">_max");
                    tokens[i].safeTransfer(msg.sender, _outputAmount);
                    return _outputAmount;
                }
            }
        }
        return 0;
    }

    /**
     * @notice Checks the amount of input tokens to output tokens
     * @param _input The address of the token being converted
     * @param _output The address of the token to be converted to
     * @param _inputAmount The input amount of tokens that are being converted
     */
    function convert_rate(
        address _input,
        address _output,
        uint256 _inputAmount
    ) external override view returns (uint256) {
        if (_output == address(token3CRV)) { // convert to 3CRV
            uint256[3] memory amounts;
            for (uint8 i = 0; i < 3; i++) {
                if (_input == address(tokens[i])) {
                    amounts[i] = _inputAmount;
                    return stableSwap3Pool.calc_token_amount(amounts, true);
                }
            }
        } else if (_input == address(token3CRV)) { // convert from 3CRV
            for (uint8 i = 0; i < 3; i++) {
                if (_output == address(tokens[i])) {
                    // @dev this is for UI reference only, the actual share price
                    // (stable/CRV) will be re-calculated on-chain when we do convert()
                    return stableSwap3Pool.calc_withdraw_one_coin(_inputAmount, i);
                }
            }
        }
        return 0;
    }

    /**
     * @notice Converts stables of the 3Pool to 3CRV
     * @dev 0: DAI, 1: USDC, 2: USDT
     * @param amounts Array of token amounts
     */
    function convert_stables(
        uint256[3] calldata amounts
    ) external override onlyAuthorized returns (uint256 _shareAmount) {
        uint256 _sum;
        for (uint8 i; i < 3; i++) {
            _sum = _sum.add(amounts[i].mul(PRECISION_MUL[i]));
        }
        ( uint256 _min, uint256 _max ) = getExpected(_sum);
        uint256 _before = token3CRV.balanceOf(address(this));
        stableSwap3Pool.add_liquidity(amounts, _min);
        uint256 _after = token3CRV.balanceOf(address(this));
        _shareAmount = _after.sub(_before);
        require(_shareAmount <= _max, ">_max");
        token3CRV.safeTransfer(msg.sender, _shareAmount);
    }

    /**
     * @notice Checks the amount of 3CRV given for the amounts
     * @dev 0: DAI, 1: USDC, 2: USDT
     * @param amounts Array of token amounts
     * @param deposit Flag for depositing LP tokens
     */
    function calc_token_amount(
        uint256[3] calldata amounts,
        bool deposit
    ) external override view returns (uint256 _shareAmount) {
        _shareAmount = stableSwap3Pool.calc_token_amount(amounts, deposit);
    }

    /**
     * @notice Checks the amount of an output token given for 3CRV
     * @param _shares The amount of 3CRV
     * @param _output The address of the output token
     */
    function calc_token_amount_withdraw(
        uint256 _shares,
        address _output
    ) external override view returns (uint256) {
        for (uint8 i = 0; i < 3; i++) {
            if (_output == address(tokens[i])) {
                return stableSwap3Pool.calc_withdraw_one_coin(_shares, i);
            }
        }
        return 0;
    }

    /**
     * @notice Allows Governance to withdraw tokens from the converter
     * @dev This contract should never have any tokens in it at the end of a transaction
     * @param _token The address of the token
     * @param _amount The amount to withdraw
     * @param _to The address to receive the tokens
     */
    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyGovernance {
        _token.safeTransfer(_to, _amount);
    }

    /**
     * @dev Throws if not called by a vault, controller, strategy, or governance
     */
    modifier onlyAuthorized() {
        require(vaultManager.vaults(msg.sender)
            || vaultManager.controllers(msg.sender)
            || strategies[msg.sender]
            || msg.sender == vaultManager.governance(),
            "!authorized"
        );
        _;
    }

    /**
     * @dev Throws if not called by a controller or governance
     */
    modifier onlyGovernance() {
        require(vaultManager.controllers(msg.sender)
            || msg.sender == vaultManager.governance(), "!governance");
        _;
    }

    /**
     * @dev Throws if not called by the strategist
     */
    modifier onlyStrategist {
        require(msg.sender == vaultManager.strategist(), "!strategist");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface IStableSwap3PoolOracle {
    function getEthereumPrice() external view returns (uint256);
    function getPrices() external view returns (uint256, uint256);
    function getSafeAnswer(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./IStableSwap3PoolOracle.sol";
import "../interfaces/Chainlink.sol";

contract StableSwap3PoolOracle is IStableSwap3PoolOracle {
    using SafeMath for uint256;

    uint256 public constant MAX_ROUND_TIME = 1 hours;
    uint256 public constant MAX_STALE_ANSWER = 24 hours;
    uint256 public constant ETH_USD_MUL = 1e10; // ETH-USD feed is to 8 decimals

    address public immutable ethUsd;
    address[3] public feeds;

    constructor(
        address _feedETHUSD,
        address _feedDAIETH,
        address _feedUSDCETH,
        address _feedUSDTETH
    )
        public
    {
        ethUsd = _feedETHUSD;
        feeds[0] = _feedDAIETH;
        feeds[1] = _feedUSDCETH;
        feeds[2] = _feedUSDTETH;
    }

    /**
     * @notice Retrieves the current price of ETH/USD as provided by Chainlink
     * @dev Reverts if the answer from Chainlink is not safe
     */
    function getEthereumPrice() external view override returns (uint256 _price) {
        _price = getSafeAnswer(ethUsd);
        require(_price > 0, "!getEthereumPrice");
        _price = _price.mul(ETH_USD_MUL);

    }

    /**
     * @notice Retrieves the minimum price of the 3pool tokens as provided by Chainlink
     * @dev Reverts if none of the Chainlink nodes are safe
     */
    function getPrices() external view override returns (uint256 _minPrice, uint256 _maxPrice) {
        for (uint8 i = 0; i < 3; i++) {
            // get the safe answer from Chainlink
            uint256 _answer = getSafeAnswer(feeds[i]);

            // store the first iteration regardless (handle that later if 0)
            // otherwise,check that _answer is greater than 0 and only store it if less
            // than the previously observed price
            if (i == 0) {
                _minPrice = _answer;
                _maxPrice = _answer;
            } else if (_answer > 0 && _answer < _minPrice) {
                _minPrice = _answer;
            } else if (_answer > 0 && _answer > _maxPrice) {
                _maxPrice = _answer;
            }
        }

        // if we couldn't get a valid price from any of the Chainlink feeds,
        // revert because nothing is safe
        require(_minPrice > 0 && _maxPrice > 0, "!getPrices");
    }

    /**
     * @notice Get and check the answer provided by Chainlink
     * @param _feed The address of the Chainlink price feed
     */
    function getSafeAnswer(address _feed) public view override returns (uint256) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = AggregatorV3Interface(_feed).latestRoundData();

        // latest round is carried over from previous round
        if (answeredInRound < roundId) {
            return 0;
        }

        // latest answer is stale
        // solhint-disable-next-line not-rely-on-time
        if (updatedAt < block.timestamp.sub(MAX_STALE_ANSWER)) {
            return 0;
        }

        // round has taken too long to collect answers
        if (updatedAt.sub(startedAt) > MAX_ROUND_TIME) {
            return 0;
        }

        // Chainlink already rejects answers outside of a range (like what would cause
        // a negative answer)
        return uint256(answer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface AggregatorInterface {
      function latestAnswer() external view returns (int256);
      function latestTimestamp() external view returns (uint256);
      function latestRound() external view returns (uint256);
      function getAnswer(uint256 roundId) external view returns (int256);
      function getTimestamp(uint256 roundId) external view returns (uint256);
}

interface AggregatorV3Interface {

      function decimals() external view returns (uint8);
      function description() external view returns (string memory);
      function version() external view returns (uint256);

      // getRoundData and latestRoundData should both raise "No data present"
      // if they do not have data to report, instead of returning unset values
      // which could be misinterpreted as actual reported values.
      function getRoundData(uint80 _roundId)
            external
            view
            returns (
                  uint80 roundId,
                  int256 answer,
                  uint256 startedAt,
                  uint256 updatedAt,
                  uint80 answeredInRound
            );
      function latestRoundData()
            external
            view
            returns (
                  uint80 roundId,
                  int256 answer,
                  uint256 startedAt,
                  uint256 updatedAt,
                  uint80 answeredInRound
            );
}

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../../interfaces/Chainlink.sol";

/**
 * @title MockV3Aggregator
 * @notice Based on the FluxAggregator contract
 * @notice Use this contract when you need to test
 * other contract's ability to read data from an
 * aggregator contract, but how the aggregator got
 * its answer is unimportant
 */
contract MockV3Aggregator is AggregatorV2V3Interface {
  uint256 constant public override version = 0;

  uint8 public override decimals;
  int256 public override latestAnswer;
  uint256 public override latestTimestamp;
  uint256 public override latestRound;

  mapping(uint256 => int256) public override getAnswer;
  mapping(uint256 => uint256) public override getTimestamp;
  mapping(uint256 => uint256) private getStartedAt;

  constructor(
    uint8 _decimals,
    int256 _initialAnswer
  ) public {
    decimals = _decimals;
    updateAnswer(_initialAnswer);
  }

  function updateAnswer(
    int256 _answer
  ) public {
    latestAnswer = _answer;
    latestTimestamp = block.timestamp;
    latestRound++;
    getAnswer[latestRound] = _answer;
    getTimestamp[latestRound] = block.timestamp;
    getStartedAt[latestRound] = block.timestamp;
  }

  function updateRoundData(
    uint80 _roundId,
    int256 _answer,
    uint256 _timestamp,
    uint256 _startedAt
  ) public {
    latestRound = _roundId;
    latestAnswer = _answer;
    latestTimestamp = _timestamp;
    getAnswer[latestRound] = _answer;
    getTimestamp[latestRound] = _timestamp;
    getStartedAt[latestRound] = _startedAt;
  }

  function getRoundData(uint80 _roundId)
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (
      _roundId,
      getAnswer[_roundId],
      getStartedAt[_roundId],
      getTimestamp[_roundId],
      _roundId
    );
  }

  function latestRoundData()
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (
      uint80(latestRound),
      getAnswer[latestRound],
      getStartedAt[latestRound],
      getTimestamp[latestRound],
      uint80(latestRound)
    );
  }

  function description()
    external
    view
    override
    returns (string memory)
  {
    return "v0.6/tests/MockV3Aggregator.sol";
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../interfaces/dYdXSoloMargin.sol";
import "../IConverter.sol";
import "./BaseStrategy.sol";

contract StrategydYdXSoloMargin is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public dYdX;
    uint256 marketId;
    IConverter public converter;

    /**
       * @param _dYdX The address of the dYdX Solo Margin contract
       * @param _marketId The dYdX Solo Margin Market ID: https://docs.dydx.exchange/#solo-markets
       * @param _converter The address of the converter
       * @param _controller The address of the controller
       * @param _vaultManager The address of the vaultManager
       * @param _weth The address of WETH
       * @param _router The address of the router for swapping tokens
       */
    constructor(
        address _dYdX,
        uint256 _marketId,
        address _converter,
        address _controller,
        address _vaultManager,
        address _weth,
        address _router
    )
    public
    BaseStrategy(
        string(abi.encodePacked("dYdX SoloMargin: ", ERC20(ISoloMargin(_dYdX).getMarketTokenAddress(_marketId)).symbol())),
        _controller,
        _vaultManager,
        ISoloMargin(_dYdX).getMarketTokenAddress(_marketId),
        _weth,
        _router
    )
    {
        require(_dYdX != address(0), "!_dYdX");
        require(_converter != address(0), "!_converter");
        dYdX = _dYdX;
        marketId = _marketId;
        converter = IConverter(_converter);
        IERC20(ISoloMargin(_dYdX).getMarketTokenAddress(_marketId)).safeApprove(_dYdX, type(uint256).max);
    }

    function _deposit() internal override {
        uint256 _amount = balanceOfWant();
        if (_amount > 0) {
            Account.Info[] memory accounts = new Account.Info[](1);
            accounts[0] = Account.Info({
                owner: address(this),
                number: 0 // Should be MARGIN
            });

            Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
            actions[0] = Actions.ActionArgs({
                actionType: Actions.ActionType.Deposit,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: true,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: _amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });

            ISoloMargin(dYdX).operate(accounts, actions);
        }
    }

    function _harvest() internal override {
        // Harvest is not necessary in this strategy
        return;
    }

    function _withdraw(uint256 _amount) internal override {
        Account.Info[] memory accounts = new Account.Info[](1);
        accounts[0] = Account.Info({
            owner: address(this),
            number: 0 // Should be MARGIN
        });

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Withdraw,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: _amount
            }),
            primaryMarketId: marketId,
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });

        ISoloMargin(dYdX).operate(accounts, actions);

        _amount = balanceOfWant();
        if (_amount > 0) {
            _convert(want, _vaultWant(), _amount);
        }
    }

    function _withdrawAll() internal override {
        uint256 amount = balanceOfPool();
        if (amount > 0) {
            _withdraw(amount);
        }
    }

    function balanceOfPool() public view override returns (uint256) {
        Account.Info memory account = Account.Info({
            owner: address(this),
            number: 0 // Should be MARGIN
        });
        Types.Wei memory balance = ISoloMargin(dYdX).getAccountWei(account, marketId);
        if (balance.sign) {
            return balance.value;
        }
        return 0;
    }

    function _convert(address _from, address _to, uint256 _amount) internal {
        require(converter.convert_rate(_from, _to, _amount) > 0, "!convert_rate");
        IERC20(_from).safeTransfer(address(converter), _amount);
        converter.convert(_from, _to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

library Account {
    enum Status {
        Normal,
        Liquid,
        Vapor
    }

    struct Info {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    function equals(
        Info memory a,
        Info memory b
    )
        internal
        pure
        returns (bool)
    {
        return a.owner == b.owner && a.number == b.number;
    }
}

library Types {
    enum AssetDenomination {
        Wei // the amount is denominated in wei
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    enum AssetReference {
        Delta // the amount is given as a delta from the current value
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }
}

library Actions {
    enum ActionType {
        Deposit, // supply tokens
        Withdraw // borrow tokens
    }

    enum AccountLayout {
        OnePrimary,
        TwoPrimary,
        PrimaryAndSecondary
    }

    enum MarketLayout {
        ZeroMarkets,
        OneMarket,
        TwoMarkets
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct DepositArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address from;
    }

    struct WithdrawArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address to;
    }

    function parseDepositArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (DepositArgs memory)
    {
        assert(args.actionType == ActionType.Deposit);
        return DepositArgs({
            amount: args.amount,
            account: accounts[args.accountId],
            market: args.primaryMarketId,
            from: args.otherAddress
        });
    }

    function parseWithdrawArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (WithdrawArgs memory)
    {
        assert(args.actionType == ActionType.Withdraw);
        return WithdrawArgs({
            amount: args.amount,
            account: accounts[args.accountId],
            market: args.primaryMarketId,
            to: args.otherAddress
        });
    }
}

interface ISoloMargin {
    function operate(Account.Info[] memory accounts, Actions.ActionArgs[] memory actions) external;
    function getMarketTokenAddress(uint256 marketId) external view returns (address);
    function getAccountWei(Account.Info memory account, uint256 marketId) external view returns (Types.Wei memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../interfaces/dYdXSoloMargin.sol";

contract MockdYdXSoloMargin is ISoloMargin {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using SafeMath for uint128;

    // Store balances as (Account => (MarketID => balance))
    mapping(address => mapping(uint256 => uint128)) balances;

    // Mapping of tokens as (MarketID => token)
    mapping(uint256 => address) tokens;

    constructor (uint256[] memory _marketIds, address[] memory _addresses) public {
        require(_marketIds.length == _addresses.length, "marketIds.length != addresses.length");
        for (uint256 i = 0; i < _marketIds.length; i++) {
            tokens[_marketIds[i]] = _addresses[i];
        }
    }

    function operate(Account.Info[] memory accounts, Actions.ActionArgs[] memory actions) public override {
        _verifyInputs(accounts, actions);

        _runActions(
            accounts,
            actions
        );
    }

    function _verifyInputs(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    ) private pure {
        require(actions.length != 0, "Cannot have zero actions");
        require(accounts.length != 0, "Cannot have zero accounts");

        for (uint256 a = 0; a < accounts.length; a++) {
            for (uint256 b = a + 1; b < accounts.length; b++) {
                require(!Account.equals(accounts[a], accounts[b]), "Cannot duplicate accounts");
            }
        }
    }

    function _runActions(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    ) private {
        for (uint256 i = 0; i < actions.length; i++) {
            Actions.ActionArgs memory action = actions[i];
            Actions.ActionType actionType = action.actionType;

            if (actionType == Actions.ActionType.Deposit) {
                _deposit(Actions.parseDepositArgs(accounts, action));
            } else if (actionType == Actions.ActionType.Withdraw) {
                _withdraw(Actions.parseWithdrawArgs(accounts, action));
            }
        }
    }

    function _deposit(
        Actions.DepositArgs memory args
    )
        private
    {
        require(
            args.from == msg.sender || args.from == args.account.owner,
            "Invalid deposit source"
        );

        // We'll not implement all cases in this mock, for simplicity
        require(args.amount.denomination == Types.AssetDenomination.Wei, "!Types.AssetDenomination.Wei");
        IERC20(tokens[args.market]).safeTransferFrom(args.from, address(this), args.amount.value);

        uint128 newBalance = to128(SafeMath.add(balances[args.account.owner][args.market], args.amount.value));
        balances[args.account.owner][args.market] = newBalance;
    }

    function _withdraw(
        Actions.WithdrawArgs memory args
    )
        private
    {
        require(
            msg.sender == args.account.owner,
            "Not valid operator"
        );
        require(args.amount.value <= balances[args.account.owner][args.market], "!balance");
        require(!args.amount.sign, "should receive negative amount");
        IERC20(tokens[args.market]).safeTransfer(args.to, args.amount.value);

        uint128 newBalance = to128(SafeMath.sub(balances[args.account.owner][args.market], args.amount.value));
        balances[args.account.owner][args.market] = newBalance;
    }

    function getMarketTokenAddress(uint256 marketId) external override view returns (address) {
        return tokens[marketId];
    }

    function getAccountWei(Account.Info memory account, uint256 marketId)
        external
        override
        view
        returns (Types.Wei memory)
    {
        Types.Wei memory balance = Types.Wei({
            sign: true,
            value: balances[account.owner][marketId]
        });
        return balance;
    }

    function to128(
        uint256 number
    )
        internal
        pure
        returns (uint128)
    {
        uint128 result = uint128(number);
        require(result == number, "Unsafe cast to uint128");
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../interfaces/Stabilize.sol";

contract MockzpaToken is ERC20, IZPAToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 constant divisionFactor = 100000;

    address public override underlyingAsset;
    uint256 public override initialFee = 1000; // 1000 = 1%, 100000 = 100%, max fee restricted in contract is 10%
    uint256 public override endFee = 100; // 100 = 0.1%
    uint256 public override feeDuration = 604800; // The amount of seconds it takes from the initial to end fee

    // Info of each user.
    struct UserInfo {
        uint256 depositTime; // The time the user made a deposit, every deposit resets the time
    }

    mapping(address => UserInfo) private userInfo;

    constructor(
        string memory _name,
        string memory _symbol,
        address _underlyingAsset
    )
        public
        ERC20(_name, _symbol)
    {
        underlyingAsset = _underlyingAsset;
    }

    function deposit(uint256 _amount) external override {
        uint256 _toMint = _amount.mul(1e18).div(pricePerToken());
        IERC20(underlyingAsset).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _toMint);
        userInfo[_msgSender()].depositTime = block.timestamp; // Update the deposit time
    }

    function redeem(uint256 _amount) external override {
        uint256 _underlyingAmount = _amount.mul(pricePerToken()).div(1e18);
        _burn(msg.sender, _amount);

        // Pay fee upon withdrawing
        if (userInfo[_msgSender()].depositTime == 0) {
            // The user has never deposited here
            userInfo[_msgSender()].depositTime = block.timestamp; // Give them the max fee
        }

        uint256 feeSubtraction = initialFee.sub(endFee).mul(block.timestamp.sub(userInfo[_msgSender()].depositTime)).div(feeDuration);
        if (feeSubtraction > initialFee.sub(endFee)) {
            // Cannot reduce fee more than this
            feeSubtraction = initialFee.sub(endFee);
        }
        uint256 fee = initialFee.sub(feeSubtraction);
        fee = _underlyingAmount.mul(fee).div(divisionFactor);
        _underlyingAmount = _underlyingAmount.sub(fee);

        // Now withdraw this amount to the user and send fee to treasury
        IERC20(underlyingAsset).safeTransfer(msg.sender, _underlyingAmount);
        IERC20(underlyingAsset).safeTransfer(DEAD, fee);
    }

    function pricePerToken() public view override returns (uint256) {
        return 2e18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface IZPAToken {
    function deposit(uint256) external;
    function redeem(uint256) external;
    function underlyingAsset() external view returns (address);
    function pricePerToken() external view returns (uint256);

    function initialFee() external view returns (uint256);
    function endFee() external view returns (uint256);
    function feeDuration() external view returns (uint256);
}

interface IZPAPool {
    function deposit(uint256, uint256) external;
    function withdraw(uint256, uint256) external;
    function exit(uint256, uint256) external;
    function getReward(uint256) external;
    function rewardEarned(uint256, address) external view returns (uint256);
    function poolTokenAddress(uint256) external view returns (address);
    function poolBalance(uint256, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../../interfaces/Stabilize.sol";
import "../IConverter.sol";
import "./BaseStrategy.sol";

contract StrategyStabilize is BaseStrategy {
    address public immutable zpaToken;
    address public immutable pool;
    address public immutable STBZ;
    uint256 public immutable poolId;
    IConverter public converter;

    uint256 private depositTime; // The time the strategy made a deposit into zpa-Token, every deposit resets the time
    uint256 private constant DIVISION_FACTOR = 100000;
    uint256 private constant INITIAL_FEE = 1000; // 1000 = 1%, 100000 = 100%, max fee restricted in contract is 10%
    uint256 private constant END_FEE = 100; // 100 = 0.1%
    uint256 private constant FEE_DURATION = 604800; // The amount of seconds it takes from the initial to end fee

    constructor(
        string memory _name,
        address _underlying,
        address _zpaToken,
        address _pool,
        uint256 _poolId,
        address _STBZ,
        address _converter,
        address _controller,
        address _vaultManager,
        address _weth,
        address _router
    )
        public
        BaseStrategy(_name, _controller, _vaultManager, _underlying, _weth, _router)
    {
        require(_zpaToken != address(0), "!_zpaToken");
        require(_pool != address(0), "!_pool");
        require(_STBZ != address(0), "!_STBZ");
        require(_converter != address(0), "!_converter");
        zpaToken = _zpaToken;
        pool = _pool;
        poolId = _poolId;
        STBZ = _STBZ;
        converter = IConverter(_converter);
        IERC20(_STBZ).safeApprove(address(_router), type(uint256).max);
        IERC20(_underlying).safeApprove(address(_converter), type(uint256).max);
        IERC20(_underlying).safeApprove(_zpaToken, type(uint256).max);
        IERC20(_zpaToken).safeApprove(_pool, type(uint256).max);
    }

    function balanceOfPool() public view override returns (uint256) {
        IZPAToken _zpaToken = IZPAToken(zpaToken);
        uint256 zpaBalance = balanceOfzpaToken()
                            .mul(_zpaToken.pricePerToken())
                            .div(1e18);
        return (IZPAPool(pool).poolBalance(poolId, address(this)))
            .mul(_zpaToken.pricePerToken())
            .div(1e18)
            .add(zpaBalance).sub(calculateZPATokenWithdrawFee(zpaBalance));
    }

    function balanceOfzpaToken() public view returns (uint256) {
        return IERC20(zpaToken).balanceOf(address(this));
    }

    function calculateZPATokenWithdrawFee(uint256 amount) public view returns (uint256) {
        uint256 _depositTime = depositTime;
        if (_depositTime == 0) {
            // Never deposited
            _depositTime = block.timestamp; // Give the max fee
        }

        uint256 feeSubtraction = INITIAL_FEE.sub(END_FEE).mul(block.timestamp.sub(_depositTime)).div(FEE_DURATION);
        if (feeSubtraction > INITIAL_FEE.sub(END_FEE)) {
            // Cannot reduce fee more than this
            feeSubtraction = INITIAL_FEE.sub(END_FEE);
        }
        uint256 fee = INITIAL_FEE.sub(feeSubtraction);
        return amount.mul(fee).div(DIVISION_FACTOR);
    }

    function _deposit() internal override {
        uint256 amount = balanceOfWant();
        if (amount > 0) {
            depositTime = block.timestamp;
            IZPAToken(zpaToken).deposit(amount);
        }
        amount = balanceOfzpaToken();
        if (amount > 0) {
            IZPAPool(pool).deposit(poolId, amount);
        }
    }

    function _harvest() internal override {
        IZPAPool(pool).getReward(poolId);
        uint256 remainingWeth = _payHarvestFees(STBZ);

        if (remainingWeth > 0) {
            _swapTokens(weth, want, remainingWeth);

            if (balanceOfWant() > 0) {
                _deposit();
            }
        }
    }

    function _withdraw(uint256 _amount) internal override {
        _amount = _amount.mul(1e18).div(IZPAToken(zpaToken).pricePerToken());
        uint256 _before = balanceOfzpaToken();
        IZPAPool(pool).withdraw(poolId, _amount);
        uint256 _after = balanceOfzpaToken();
        _amount = _after.sub(_before);
        IZPAToken(zpaToken).redeem(_amount);
        _amount = balanceOfWant();
        if (_amount > 0) {
            _convert(want, _vaultWant(), _amount);
        }
    }

    function _withdrawAll() internal override {
        uint256 amount = IZPAPool(pool).poolBalance(poolId, address(this));
        IZPAPool(pool).exit(poolId, amount);

        amount = balanceOfzpaToken();
        if (amount > 0) {
            IZPAToken(zpaToken).redeem(amount);
            amount = balanceOfWant();
            _convert(want, _vaultWant(), amount);
        }
    }

    function _convert(address _from, address _to, uint256 _amount) internal {
        require(converter.convert_rate(_from, _to, _amount) > 0, "!convert_rate");
        IERC20(_from).safeTransfer(address(converter), _amount);
        converter.convert(_from, _to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../interfaces/Stabilize.sol";

contract MockStabilizePool is IZPAPool {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public lpToken;
    IERC20 public rewardToken;
    uint256 public rewardRate;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 unclaimedReward;
    }

    mapping(uint256 => mapping(address => UserInfo)) private userInfo;
    mapping(uint256 => address) public override poolTokenAddress;

    constructor(
        address _lpToken,
        address _rewardToken,
        uint256 _rewardRate
    ) public {
        lpToken = IERC20(_lpToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate;
    }

    function deposit(uint256 _pid, uint256 _amount) external override {
        userInfo[_pid][msg.sender].amount = userInfo[_pid][msg.sender].amount.add(_amount);
        lpToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public override {
        userInfo[_pid][msg.sender].amount = userInfo[_pid][msg.sender].amount.sub(_amount);
        lpToken.safeTransfer(msg.sender, _amount);
    }

    function exit(uint256 _pid, uint256 _amount) external override {
        withdraw(_pid, _amount);
        getReward(_pid);
    }

    function getReward(uint256 _pid) public override {
        uint256 _amount = rewardEarned(_pid, msg.sender);
        rewardToken.safeTransfer(msg.sender, _amount);
    }

    function rewardEarned(uint256 _pid, address _user) public view override returns (uint256) {
        return poolBalance(_pid, _user).mul(rewardRate).div(1000);
    }

    function poolBalance(uint256 _pid, address _user) public view override returns (uint256) {
        return userInfo[_pid][_user].amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract MockYearnV2 is ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public underlying;

    constructor(string memory name, string memory symbol, IERC20 _underlying) public ERC20(name, symbol) {
        underlying = _underlying;
    }

    function balance() public view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    function pricePerShare() public view returns (uint256) {
        return balance().mul(1e18).div(totalSupply());
    }

    function deposit() external returns (uint256) {
        uint256 _balance = underlying.balanceOf(msg.sender);
        return deposit(_balance);
    }

    function deposit(uint256 _amount) public returns (uint256) {
        uint256 underlyingTotal = balance();
        uint256 _before = balance();
        underlying.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = balance();
        _amount = _after.sub(_before);
        uint256 shares;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(underlyingTotal);
        }
        _mint(msg.sender, shares);
        return shares;
    }

    function withdraw() external {
        withdraw(balanceOf(msg.sender));
    }

    function withdraw(uint256 _amount) public {
        uint256 ret = (balance().mul(_amount)).div(totalSupply());
        _burn(msg.sender, _amount);
        underlying.safeTransfer(msg.sender, ret);
    }

    function token() external view returns (address) {
        return address(underlying);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

contract MockUniswapRouter is IUniswapRouter {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 univ2LpToken;

    constructor(IERC20 _univ2LpToken) public {
        univ2LpToken = _univ2LpToken;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) public override returns (uint256[] memory amounts) {
        return _swap(amountIn, amountOutMin, path, to, deadline);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {
        return _swap(amountIn, amountOutMin, path, to, deadline);
    }

    function _swap(
        uint256 amountIn,
        uint256,
        address[] calldata path,
        address to,
        uint256
    ) internal returns (uint256[] memory amounts) {
        uint256 amountOut = amountIn.mul(1); // assume 1 INPUT -> 1 OUTPUT
        IERC20 inputToken = IERC20(path[0]);
        IERC20 outputToken = IERC20(path[path.length - 1]);
        inputToken.safeTransferFrom(msg.sender, address(this), amountIn);
        outputToken.safeTransfer(to, amountOut);
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint,
        uint,
        address to,
        uint
    ) external override returns (uint amountA, uint amountB, uint liquidity) {
        amountA = (amountADesired < amountBDesired) ? amountADesired : amountBDesired;
        amountB = amountA;
        liquidity = amountA;
        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountB);
        univ2LpToken.safeTransfer(to, liquidity); // 1A + 1B -> 1LP
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../interfaces/Idle.sol";

contract MockIdleToken is ERC20, IIdleTokenV3_1 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public override token;
    IERC20 public rewardToken;
    IERC20 public govToken;

    constructor(
        string memory _name,
        string memory _symbol,
        address _underlyingAsset,
        address _rewardToken,
        address _govToken
    )
        public
        ERC20(_name, _symbol)
    {
        token = _underlyingAsset;
        rewardToken = ERC20(_rewardToken);
        govToken = ERC20(_govToken);
    }

    function mintIdleToken(uint256 _amount, bool, address) external override returns (uint256 mintedTokens) {
        mintedTokens = _amount.mul(1e18).div(tokenPrice());
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, mintedTokens);
    }

    function redeemIdleToken(uint256 _amount) external override returns (uint256 redeemedTokens) {
        uint256 price = tokenPrice();
        redeemedTokens = _amount.mul(price).div(1e18);
        _burn(msg.sender, _amount);
        rewardToken.safeTransfer(msg.sender, 10e18);
        govToken.safeTransfer(msg.sender, 5e18);
        IERC20(token).safeTransfer(msg.sender, redeemedTokens);
    }

    function tokenPrice() public view override returns (uint256) {
        return 2e18; // 1 idleDAI = 2 DAI
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface IIdleTokenV3_1 {
    function tokenPrice() external view returns (uint256 price);
    function token() external view returns (address);
    function mintIdleToken(uint256 _amount, bool _skipRebalance, address _referral) external returns (uint256 mintedTokens);
    function redeemIdleToken(uint256 _amount) external returns (uint256 redeemedTokens);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../../interfaces/Idle.sol";
import "../IConverter.sol";
import "./BaseStrategy.sol";

contract StrategyIdle is BaseStrategy {
    address public immutable idleYieldToken;
    address public immutable IDLE;
    address public immutable COMP;
    IConverter public converter;

    constructor(
        string memory _name,
        address _underlying,
        address _idleYieldToken,
        address _IDLE,
        address _COMP,
        address _converter,
        address _controller,
        address _vaultManager,
        address _weth,
        address _router
    )
        public
        BaseStrategy(_name, _controller, _vaultManager, _underlying, _weth, _router)
    {
        require(_idleYieldToken != address(0), "!_idleYieldToken");
        require(_IDLE != address(0), "!_IDLE");
        require(_COMP != address(0), "!_COMP");
        require(_converter != address(0), "!_converter");
        idleYieldToken = _idleYieldToken;
        IDLE = _IDLE;
        COMP = _COMP;
        converter = IConverter(_converter);
        IERC20(_IDLE).safeApprove(address(_router), type(uint256).max);
        IERC20(_COMP).safeApprove(address(_router), type(uint256).max);
        IERC20(_underlying).safeApprove(address(_converter), type(uint256).max);
        IERC20(_underlying).safeApprove(_idleYieldToken, type(uint256).max);
    }

    function balanceOfPool() public view override returns (uint256) {
        uint256 balance = balanceOfYieldToken();
        return balance
            .mul(pricePerToken())
            .div(1e18);
    }

    function pricePerToken() public view returns (uint256) {
        return IIdleTokenV3_1(idleYieldToken).tokenPrice();
    }

    function balanceOfYieldToken() public view returns (uint256) {
        return IERC20(idleYieldToken).balanceOf(address(this));
    }

    function _deposit() internal override {
        uint256 balance = balanceOfWant();
        if (balance > 0) {
            IIdleTokenV3_1(idleYieldToken).mintIdleToken(balance, true, address(0));
        }
    }

    function _harvest() internal override {
        IIdleTokenV3_1(idleYieldToken).redeemIdleToken(0);
        uint256 remainingWeth = _payHarvestFees(IDLE);

        _liquidateAsset(COMP, want);

        if (remainingWeth > 0) {
            _swapTokens(weth, want, remainingWeth);
        }

        _deposit();
    }

    function _withdraw(uint256 _amount) internal override {
        _amount = _amount.mul(1e18).div(IIdleTokenV3_1(idleYieldToken).tokenPrice());
        IIdleTokenV3_1(idleYieldToken).redeemIdleToken(_amount);

        _liquidateAsset(COMP, want);
        _liquidateAsset(IDLE, want);

        _amount = balanceOfWant();
        if (_amount > 0) {
            _convert(want, _vaultWant(), _amount);
        }
    }

    function _withdrawAll() internal override {
        uint256 balance = balanceOfYieldToken();
        IIdleTokenV3_1(idleYieldToken).redeemIdleToken(balance);

        _liquidateAsset(COMP, want);
        _liquidateAsset(IDLE, want);

        balance = balanceOfWant();
        if (balance > 0) {
            _convert(want, _vaultWant(), balance);
        }
    }

    function _convert(address _from, address _to, uint256 _amount) internal {
        require(converter.convert_rate(_from, _to, _amount) > 0, "!convert_rate");
        IERC20(_from).safeTransfer(address(converter), _amount);
        converter.convert(_from, _to, _amount);
    }

    function _liquidateAsset(address asset, address to) internal {
        uint256 assetBalance = IERC20(asset).balanceOf(address(this));
        if (assetBalance > 0) {
            _swapTokens(asset, to, assetBalance);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./MockERC20.sol";

contract MockFlamIncomeVault is MockERC20 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;

    uint public min = 9500;
    uint public constant max = 10000;

    constructor (address _token) public MockERC20(
        string(abi.encodePacked("flamincomed ", ERC20(_token).name())),
        string(abi.encodePacked("f", ERC20(_token).symbol())),
        ERC20(_token).decimals()
    ) {
        token = IERC20(_token);
    }

    function balance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function available() public view returns (uint) {
        return token.balanceOf(address(this)).mul(min).div(max);
    }

    function depositAll() external {
        deposit(token.balanceOf(msg.sender));
    }

    function deposit(uint _amount) public {
        uint _pool = balance();
        uint _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint _after = token.balanceOf(address(this));
        _amount = _after.sub(_before);
        uint shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    function withdraw(uint _shares) public {
        uint r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);
        token.safeTransfer(msg.sender, r);
    }

    function priceE18() public view returns (uint) {
        return balance().mul(1e18).div(totalSupply());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract MockDRewards {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public lpToken;
    IERC20 public rewardToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    uint256 rewardRate; // over 1000

    constructor(
        address _lpToken,
        address _rewardToken,
        uint256 _rewardRate
    ) public {
        lpToken = IERC20(_lpToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function earned(address account) public view returns (uint256) {
        return balanceOf(account).mul(rewardRate).div(1000);
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        lpToken.safeTransfer(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            if (reward > rewardToken.balanceOf(address(this))) {
                reward = rewardToken.balanceOf(address(this));
            }
            rewardToken.safeTransfer(msg.sender, reward);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract MockDErc20 is ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public underlying;

    constructor(string memory name, string memory symbol, IERC20 _underlying) public ERC20(name, symbol) {
        underlying = _underlying;
    }

    function getExchangeRate() public pure returns (uint256) {
        return 2e18; // 1 dDAI = 2 DAI
    }

    function getTokenBalance(address _account) external view returns (uint256) {
        return balanceOf(_account).mul(getExchangeRate()).div(1e18);
    }

    function mint(address _account, uint256 _amount) external {
        uint256 _toMint = _amount.mul(1e18).div(getExchangeRate());
        underlying.safeTransferFrom(msg.sender, address(this), _amount);
        _mint(_account, _toMint);
    }

    function redeem(address _account, uint256 _amount) external {
        uint256 _underlyingAmount = _amount.mul(getExchangeRate()).div(1e18);
        _burn(_account, _amount);
        underlying.safeTransfer(msg.sender, _underlyingAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../interfaces/Gauge.sol";

contract MockCurveMinter is Mintr {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 crv;

    constructor(IERC20 _crv) public {
        crv = _crv;
    }

    function mint(address) external override {
        uint _bal = crv.balanceOf(address(this));
        crv.safeTransfer(msg.sender, _bal.div(10)); // always mint 10% amount of balance
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface Gauge {
    function deposit(uint) external;
    function balanceOf(address) external view returns (uint);
    function withdraw(uint) external;
    function claimable_tokens(address) external view returns (uint);
}

interface Mintr {
    function mint(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../../interfaces/Gauge.sol";
import "../../interfaces/Balancer.sol";

import "./BaseStrategy.sol";

contract StrategyCurve3Crv is BaseStrategy {
    // used for Crv -> weth -> [dai/usdc/usdt] -> 3crv route
    address public immutable crv;

    // for add_liquidity via curve.fi to get back 3CRV (use getMostPremium() for the best stable coin used in the route)
    address public immutable dai;
    address public immutable usdc;
    address public immutable usdt;

    Mintr public immutable crvMintr;
    IStableSwap3Pool public immutable stableSwap3Pool;
    Gauge public immutable gauge; // 3Crv Gauge

    constructor(
        string memory _name,
        address _want,
        address _crv,
        address _weth,
        address _dai,
        address _usdc,
        address _usdt,
        Gauge _gauge,
        Mintr _crvMintr,
        IStableSwap3Pool _stableSwap3Pool,
        address _controller,
        address _vaultManager,
        address _router
    )
        public
        BaseStrategy(_name, _controller, _vaultManager, _want, _weth, _router)
    {
        require(_crv != address(0), "!_crv");
        require(_dai != address(0), "!_dai");
        require(_usdc != address(0), "!_usdc");
        require(_usdt != address(0), "!_usdt");
        require(address(_gauge) != address(0), "!_gauge");
        require(address(_crvMintr) != address(0), "!_crvMintr");
        require(address(_stableSwap3Pool) != address(0), "!_stableSwap3Pool");
        crv = _crv;
        dai = _dai;
        usdc = _usdc;
        usdt = _usdt;
        stableSwap3Pool = _stableSwap3Pool;
        gauge = _gauge;
        crvMintr = _crvMintr;
        IERC20(_want).safeApprove(address(_gauge), type(uint256).max);
        IERC20(_crv).safeApprove(address(_router), type(uint256).max);
        IERC20(_dai).safeApprove(address(_stableSwap3Pool), type(uint256).max);
        IERC20(_usdc).safeApprove(address(_stableSwap3Pool), type(uint256).max);
        IERC20(_usdt).safeApprove(address(_stableSwap3Pool), type(uint256).max);
        IERC20(_want).safeApprove(address(_stableSwap3Pool), type(uint256).max);
    }

    function _deposit() internal override {
        uint256 _wantBal = balanceOfWant();
        if (_wantBal > 0) {
            // deposit [want] to Gauge
            gauge.deposit(_wantBal);
        }
    }

    function _claimReward() internal {
        crvMintr.mint(address(gauge));
    }

    function _addLiquidity() internal {
        uint256[3] memory amounts;
        amounts[0] = IERC20(dai).balanceOf(address(this));
        amounts[1] = IERC20(usdc).balanceOf(address(this));
        amounts[2] = IERC20(usdt).balanceOf(address(this));
        stableSwap3Pool.add_liquidity(amounts, 1);
    }

    function getMostPremium() public view returns (address, uint256) {
        uint256[] memory balances = new uint256[](3);
        balances[0] = stableSwap3Pool.balances(0); // DAI
        balances[1] = stableSwap3Pool.balances(1).mul(10**12); // USDC
        balances[2] = stableSwap3Pool.balances(2).mul(10**12); // USDT

        if (balances[0] < balances[1] && balances[0] < balances[2]) { // DAI
            return (dai, 0);
        }

        if (balances[1] < balances[0] && balances[1] < balances[2]) { // USDC
            return (usdc, 1);
        }

        if (balances[2] < balances[0] && balances[2] < balances[1]) { // USDT
            return (usdt, 2);
        }

        return (dai, 0); // If they're somehow equal, we just want DAI
    }

    function _harvest() internal override {
        _claimReward();
        uint256 _remainingWeth = _payHarvestFees(crv);

        if (_remainingWeth > 0) {
            (address _stableCoin,) = getMostPremium(); // stablecoin we want to convert to
            _swapTokens(weth, _stableCoin, _remainingWeth);
            _addLiquidity();

            if (balanceOfWant() > 0) {
                _deposit();
            }
        }
    }

    function _withdrawAll() internal override {
        uint256 _bal = gauge.balanceOf(address(this));
        _withdraw(_bal);
    }

    function _withdraw(uint256 _amount) internal override {
        gauge.withdraw(_amount);
    }

    function balanceOfPool() public view override returns (uint) {
        return gauge.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface Balancer {
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;
    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountOut, uint spotPriceAfter);
    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountIn, uint spotPriceAfter);
    function joinswapExternAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    ) external returns (uint poolAmountOut);
    function exitswapPoolAmountIn(
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    ) external returns (uint tokenAmountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../interfaces/Gauge.sol";

contract MockCurveGauge is Gauge {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 want;

    mapping(address => uint) public amounts;

    constructor(IERC20 _want) public {
        want = _want;
    }

    function deposit(uint _amount) external override {
        want.safeTransferFrom(msg.sender, address(this), _amount);
        amounts[msg.sender] = amounts[msg.sender].add(_amount);
    }

    function balanceOf(address _account) external override view returns (uint) {
        return amounts[_account];
    }

    function claimable_tokens(address _account) external override view returns (uint) {
        return amounts[_account].div(10); // always return 10% of staked
    }

    function withdraw(uint _amount) external override {
        want.safeTransfer(msg.sender, _amount);
        amounts[msg.sender] = amounts[msg.sender].sub(_amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract MockYaxisBar is ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable YAX;

    constructor(
        address _yax
    )
        public
        ERC20("Staked yAxis", "sYAX")
    {
        YAX = IERC20(_yax);
    }

    function availableBalance()
        external
        view
        returns (uint256)
    {
        return YAX.balanceOf(address(this));
    }

    function enter(
        uint256 _amount
    )
        external
    {
        require(_amount > 0, "!_amount");
        _mint(msg.sender, _amount.mul(1e18).div(getPricePerFullShare()));
        YAX.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function leave(
        uint256 _amount
    )
        public
    {
        require(_amount > 0, "!_amount");
        _burn(msg.sender, _amount);
        YAX.safeTransfer(msg.sender, _amount.mul(getPricePerFullShare()).div(1e18));
    }

    function exit()
        external
    {
        leave(balanceOf(msg.sender));
    }

    function getPricePerFullShare()
        public
        view
        returns (uint256)
    {
        return totalSupply() == 0
            ? 1e18
            : YAX.balanceOf(address(this)).mul(1e18).div(totalSupply());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract MockUniswapPair is ERC20 {
    using SafeERC20 for IERC20;

    address public immutable token0;
    address public immutable token1;

    constructor(
        address _token0,
        address _token1
    )
        public
        ERC20("Uniswap Pair", "UNI-V2")
    {
        token0 = _token0;
        token1 = _token1;
    }

    function addLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        uint256 _amountOut
    )
        external
    {
        IERC20(token0).safeTransferFrom(msg.sender, address(this), _amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), _amount1);
        _mint(msg.sender, _amountOut);
    }

    function getReserves()
        external
        view
        returns (uint112, uint112, uint32)
    {
        return (
            uint112(IERC20(token0).balanceOf(address(this))),
            uint112(IERC20(token1).balanceOf(address(this))),
            uint32(block.timestamp)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "../../interfaces/FlamIncome.sol";
import "./StrategyGenericVault.sol";

contract StrategyFlamIncome is StrategyGenericVault {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /**
     * @param _vault The address of the vault
     * @param _converter The address of the converter
     * @param _controller The address of the controller
     * @param _vaultManager The address of the vaultManager
     * @param _weth The address of WETH
     * @param _router The address of the router for swapping tokens
     */
    constructor(
        address _vault,
        address _converter,
        address _controller,
        address _vaultManager,
        address _weth,
        address _router
    )
        public
        StrategyGenericVault(
            string(abi.encodePacked("FlamIncome: ", ERC20(IVault(_vault).token()).symbol())),
            _vault,
            _converter,
            _controller,
            _vaultManager,
            _weth,
            _router
        )
    {}

    function getPricePerFullShare() public view override returns(uint256) {
        return priceE18();
    }

    function priceE18() public view returns (uint256) {
        return IVault(vault).priceE18();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface IVault {
    function token() external view returns (address);
    function priceE18() external view returns (uint);
    function deposit(uint) external;
    function withdraw(uint) external;
    function depositAll() external;
    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../../interfaces/DForce.sol";
import "../IConverter.sol";
import "./BaseStrategy.sol";

contract StrategyDforce is BaseStrategy {
    address public immutable dToken;
    address public immutable pool;
    address public immutable DF;
    IConverter public converter;

    constructor(
        string memory _name,
        address _underlying,
        address _dToken,
        address _pool,
        address _DF,
        address _converter,
        address _controller,
        address _vaultManager,
        address _weth,
        address _router
    )
        public
        BaseStrategy(_name, _controller, _vaultManager, _underlying, _weth, _router)
    {
        require(_dToken != address(0), "!_dToken");
        require(_pool != address(0), "!_pool");
        require(_DF != address(0), "!_DF");
        require(_converter != address(0), "!_converter");
        dToken = _dToken;
        pool = _pool;
        DF = _DF;
        converter = IConverter(_converter);
        IERC20(_DF).safeApprove(address(_router), type(uint256).max);
        IERC20(_underlying).safeApprove(address(_converter), type(uint256).max);
        IERC20(_underlying).safeApprove(_dToken, type(uint256).max);
        IERC20(_dToken).safeApprove(_pool, type(uint256).max);
    }

    function balanceOfPool() public view override returns (uint256) {
        return (dRewards(pool).balanceOf(address(this)))
            .mul(dERC20(dToken).getExchangeRate())
            .div(1e18)
            .add(balanceOfdToken());
    }

    function balanceOfdToken() public view returns (uint256) {
        return dERC20(dToken).getTokenBalance(address(this));
    }

    function _deposit() internal override {
        uint256 _amount = balanceOfWant();
        if (_amount > 0) {
            dERC20(dToken).mint(address(this), _amount);
        }
        uint256 _dToken = IERC20(dToken).balanceOf(address(this));
        if (_dToken > 0) {
            dRewards(pool).stake(_dToken);
        }
    }

    function _harvest() internal override {
        dRewards(pool).getReward();
        uint256 _remainingWeth = _payHarvestFees(DF);

        if (_remainingWeth > 0) {
            _swapTokens(weth, want, _remainingWeth);

            if (balanceOfWant() > 0) {
                _deposit();
            }
        }
    }

    function _withdraw(uint256 _amount) internal override {
        _amount = _amount.mul(1e18).div(dERC20(dToken).getExchangeRate());
        uint256 _before = IERC20(dToken).balanceOf(address(this));
        dRewards(pool).withdraw(_amount);
        uint256 _after = IERC20(dToken).balanceOf(address(this));
        _amount = _after.sub(_before);
        dERC20(dToken).redeem(address(this), _amount);
        _amount = balanceOfWant();
        if (_amount > 0) {
            _convert(want, _vaultWant(), _amount);
        }
    }

    function _withdrawAll() internal override {
        dRewards(pool).exit();
        uint256 _amount = IERC20(dToken).balanceOf(address(this));
        if (_amount > 0) {
            dERC20(dToken).redeem(address(this), _amount);
            _amount = balanceOfWant();
            _convert(want, _vaultWant(), _amount);
        }
    }

    function _convert(address _from, address _to, uint256 _amount) internal {
        require(converter.convert_rate(_from, _to, _amount) > 0, "!convert_rate");
        IERC20(_from).safeTransfer(address(converter), _amount);
        converter.convert(_from, _to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface dRewards {
    function withdraw(uint) external;
    function getReward() external;
    function stake(uint) external;
    function balanceOf(address) external view returns (uint);
    function exit() external;
}

interface dERC20 {
  function mint(address, uint256) external;
  function redeem(address, uint) external;
  function getTokenBalance(address) external view returns (uint);
  function getExchangeRate() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockPickleMasterChef {
    IERC20 public pickleToken;
    IERC20 public lpToken;

    struct UserInfo {
        uint amount; // How many LP tokens the user has provided.
        uint rewardDebt; // Reward debt. See explanation below.
    }

    mapping(uint => mapping(address => UserInfo)) public userInfo;

    constructor(IERC20 _pickleToken, IERC20 _lpToken) public {
        pickleToken = _pickleToken;
        lpToken = _lpToken;
    }

    function deposit(uint _pid, uint _amount) external {
        lpToken.transferFrom(msg.sender, address(this), _amount);
        UserInfo storage user = userInfo[_pid][msg.sender];
        pickleToken.transfer(msg.sender, user.amount / 10); // always get 10% of deposited amount
        user.amount = user.amount + _amount;
    }

    function withdraw(uint _pid, uint _amount) external {
        lpToken.transfer(msg.sender, _amount);
        UserInfo storage user = userInfo[_pid][msg.sender];
        pickleToken.transfer(msg.sender, user.amount / 10); // always get 10% of deposited amount
        user.amount = user.amount - _amount;
    }

    function pendingPickle(uint, address) external view returns (uint) {
        return pickleToken.balanceOf(address(this)) / 10;
    }

    function emergencyWithdraw(uint _pid) external {
        UserInfo storage user = userInfo[_pid][msg.sender];
        lpToken.transfer(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IVoteProxy.sol";

contract YaxisVoteProxy {
    IVoteProxy public voteProxy;
    address public governance;
    constructor() public {
        governance = msg.sender;
    }

    function name() external pure returns (string memory) {
        return "YAXIS Vote Power";
    }

    function symbol() external pure returns (string memory) {
        return "YAX VP";
    }

    function decimals() external view returns (uint8) {
        return voteProxy.decimals();
    }

    function totalSupply() external view returns (uint256) {
        return voteProxy.totalSupply();
    }

    function balanceOf(address _voter) external view returns (uint256) {
        return voteProxy.balanceOf(_voter);
    }

    function setVoteProxy(IVoteProxy _voteProxy) external {
        require(msg.sender == governance, "!governance");
        voteProxy = _voteProxy;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }



/**
 * This function allows governance to take unsupported tokens out of the contract.
 * This is in an effort to make someone whole, should they seriously mess up.
 * There is no guarantee governance will vote to return these.
 * It also allows for removal of airdropped tokens.
 */
    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(to, amount);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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
  "metadata": {
    "useLiteralContent": true
  }
}