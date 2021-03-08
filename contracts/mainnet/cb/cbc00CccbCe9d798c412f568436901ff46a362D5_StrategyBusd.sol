pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

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
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
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

pragma solidity ^0.5.5;

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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity 0.5.15;

interface IController {
    function vaults(address) external view returns (address);
    function withdraw(address, uint) external;
    function balanceOf(address) external view returns (uint);
    function underlyingBalanceOf(address) external view returns (uint);
    function earn(address, uint) external;
    function rewards() external view returns (address);
    function belRewards() external view returns (address);
    function paused() external view returns (bool);
}

pragma solidity 0.5.15;

interface ICrvDeposit{
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
    // function claimable_tokens(address) external view returns (uint256);
}

pragma solidity 0.5.15;

interface ICrvMinter{
    function mint(address) external;
}

pragma solidity 0.5.15;

// checked for busd pool
interface ICrvPoolUnderlying {
    function get_virtual_price() external view returns (uint256);
}

pragma solidity 0.5.15;

// checked for busd zap
interface ICrvPoolZap {
    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}

pragma solidity ^0.5.15;

interface IUniswapRouter {
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external;
}

pragma solidity 0.5.15;

interface IVotingEscrow {
    function create_lock(uint256 _value, uint256 _unlock_time) external;
    function increase_amount(uint256 _value) external;
    function increase_unlock_time(uint256 _unlock_time) external;
    function withdraw() external;
}

pragma solidity 0.5.15;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the a
     * specified account.
     * @param initalOwner The address of the inital owner.
     */
    constructor(address initalOwner) internal {
        _owner = initalOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Only owner can call");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Owner should not be 0 address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity 0.5.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Ownable.sol";
import "../interfaces/IVotingEscrow.sol";

/**
* @title CrvLocker
* @dev Inherit this contract to gain functionalities to interact with curve's voting_escrow
*/
contract CrvLocker is Ownable {

    constructor(address owner) public Ownable(owner) {}

    address constant public voting_escrow = address(0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2);
    IERC20 constant public crv = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);

    /**
     * @dev Lock CRV to enhance CRV rewards
     * @param amount amount of CRV to lock
     * @param unlockTime unix timestamp to unlock
     */
    function lock_crv(uint256 amount, uint256 unlockTime) external onlyOwner {
        crv.approve(voting_escrow, 0);
        crv.approve(voting_escrow, amount);
        IVotingEscrow(voting_escrow).create_lock(amount, unlockTime);
    }

    /**
     * @dev Withdraw locked CRV after the unlock time
     */
    function withdraw_crv() external onlyOwner {
        IVotingEscrow(voting_escrow).withdraw();
    }

    /**
     * @dev Increase CRV locking amount
     * @param amount amount of CRV to increase
     */
    function increase_crv_amount(uint256 amount) external onlyOwner {
        crv.approve(voting_escrow, 0);
        crv.approve(voting_escrow, amount);
        IVotingEscrow(voting_escrow).increase_amount(amount);
    }

    /**
     * @dev Increase CRV locking time
     * @param unlockTime new CRV locking time
     */
    function increase_crv_unlock_time(uint256 unlockTime) external onlyOwner {
        IVotingEscrow(voting_escrow).increase_unlock_time(unlockTime);
    }
}

pragma solidity 0.5.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/ICrvDeposit.sol";
import "../interfaces/ICrvMinter.sol";
import "../interfaces/ICrvPoolUnderlying.sol";
import "../interfaces/ICrvPoolZap.sol";
import "../interfaces/IController.sol";
import "../interfaces/IUniswapRouter.sol";
import "./CrvLocker.sol";

/*

 A strategy must implement the following calls;
 
 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()
 
 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller
 
*/

contract StrategyBusd is CrvLocker {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address constant public want = address(0x4Fabb145d64652a948d72533023f6E7A623C7C53); // busd
    address constant public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7); // usdt
    address constant public busdPool = address(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27); // bCrv swap
    address constant public busdPoolZap = address(0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB); // bCrv swap zap
    address constant public bCrvGauge = address(0x69Fb7c45726cfE2baDeE8317005d3F94bE838840); // bCrv gauge
    address constant public bCrv = address(0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B); // bCrv
    address constant public bella = address(0xA91ac63D040dEB1b7A5E4d4134aD23eb0ba07e14);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant public output = address(0xD533a949740bb3306d119CC777fa900bA034cd52); // CRV   
    address constant public unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public crv_minter = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);

    enum TokenIndexInbusdPool {DAI, USDC, USDT, BUSD}
    uint56 constant tokenIndexBusd = uint56(TokenIndexInbusdPool.BUSD);
    uint56 constant tokenIndexUsdt = uint56(TokenIndexInbusdPool.USDT);

    address public governance;
    address public controller;

    uint256 public toWant = 92; // 20% manager fee + 80%*90%
    uint256 public toBella = 8;
    uint256 public manageFee = 22; //92%*22% = 20%

    uint256 public burnPercent = 50;
    uint256 public distributionPercent = 50;
    address public burnAddress = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // withdrawSome withdraw a bit more to compensate the imbalanced asset, 10000=1
    uint256 public withdrawCompensation = 30;

    address[] public swap2BellaRouting;
    address[] public swap2UsdtRouting;
    
    constructor(address _controller, address _governance) public CrvLocker(_governance) {
        governance = _governance;
        controller = _controller;
        swap2BellaRouting = [output, weth, bella];
        swap2UsdtRouting = [output, weth, usdt];
        doApprove();
    }

    function doApprove () public {

        // crv -> want
        IERC20(crv).safeApprove(unirouter, 0);
        IERC20(crv).safeApprove(unirouter, uint(-1)); 

        // busd -> bCrv zap
        IERC20(want).safeApprove(busdPoolZap, 0);
        IERC20(want).safeApprove(busdPoolZap, uint(-1));

        // usdt -> bCrv zap
        IERC20(usdt).safeApprove(busdPoolZap, 0);
        IERC20(usdt).safeApprove(busdPoolZap, uint(-1));

        // bCrv -> bCrv gauge
        IERC20(bCrv).safeApprove(bCrvGauge, 0);
        IERC20(bCrv).safeApprove(bCrvGauge, uint(-1));

    }
    
    function deposit() public {
        require((msg.sender == governance || 
            (msg.sender == tx.origin) ||
            (msg.sender == controller)),"!contract");

        /// busd -> bCrv Pool
        uint256[4] memory amounts = wrapCoinAmount(IERC20(want).balanceOf(address(this)), tokenIndexBusd);
        ICrvPoolZap(busdPoolZap).add_liquidity(amounts, 0);

        /// bCrv -> gauge
        invest(bCrvGauge, IERC20(bCrv).balanceOf(address(this)));
    }

    /**
     * @dev Get CRV rewards
     */
    function harvest(address gauge) public {
        require(msg.sender == tx.origin ,"!contract");

        ICrvMinter(crv_minter).mint(gauge);

        uint256 crvToWant = crv.balanceOf(address(this)).mul(toWant).div(100);

        if (crvToWant == 0)
            return;

        uint256 bUsdtBefore = IERC20(usdt).balanceOf(address(this));

        IUniswapRouter(unirouter).swapExactTokensForTokens(
            crvToWant, 1, swap2UsdtRouting, address(this), block.timestamp
        );

        uint256 bUsdtAfter = IERC20(usdt).balanceOf(address(this));

        uint256 fee = bUsdtAfter.sub(bUsdtBefore).mul(manageFee).div(100);
        IERC20(usdt).safeTransfer(IController(controller).rewards(), fee);

        if (toBella != 0) {
            uint256 crvBalance = crv.balanceOf(address(this));
            IUniswapRouter(unirouter).swapExactTokensForTokens(
                crvBalance, 1, swap2BellaRouting, address(this), block.timestamp
            );
            splitBella();
        }

        depositUsdt();

    }

    /**
     * @dev usdt -> bCrv -> bCrv gauge
     */
    function depositUsdt() internal {
        /// usdt -> bCrv Pool
        uint256[4] memory amounts = wrapCoinAmount(IERC20(usdt).balanceOf(address(this)), tokenIndexUsdt);
        ICrvPoolZap(busdPoolZap).add_liquidity(amounts, 0);

        /// bCrv -> gauge
        invest(bCrvGauge, IERC20(bCrv).balanceOf(address(this)));
    }

    /**
     * @dev Deposit XCurve into XCurve gauge
     */
    function invest(address gauge, uint256 amount) internal {

        ICrvDeposit(gauge).deposit(amount);

    }

    /**
     * @dev Distribute bella to burn address and reward address
     */
    function splitBella() internal {
        uint bellaBalance = IERC20(bella).balanceOf(address(this));

        uint burn = bellaBalance.mul(burnPercent).div(100);
        uint distribution = bellaBalance.mul(distributionPercent).div(100);
        
        IERC20(bella).safeTransfer(IController(controller).belRewards(), distribution);
        IERC20(bella).safeTransfer(burnAddress, burn); 
    }
    
    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(address(_asset) != address(bCrv), "!bCrv");
        require(address(_asset) != address(want), "!want");
        require(address(_asset) != address(crv), "!crv");
        require(address(_asset) != address(usdt), "!usdt");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }
    
    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint _amount) external {
        require(msg.sender == controller, "!controller");
        uint _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, _amount);
    }
    
    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();
        balance = IERC20(want).balanceOf(address(this));
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);
    }
    
    function _withdrawAll() internal {
        // withdraw 3pool crv from gauge
        uint256 amount = ICrvDeposit(bCrvGauge).balanceOf(address(this));
        _withdrawXCurve(bCrvGauge, amount);
        
        // exchange xcrv from pool to say dai 
        ICrvPoolZap(busdPoolZap).remove_liquidity_one_coin(amount, tokenIndexBusd, 1);
    }
    
    function _withdrawSome(uint256 _amount) internal returns (uint) {
        // withdraw 3pool crv from gauge
        uint256 amount = _amount.mul(1e18).div(ICrvPoolUnderlying(busdPool).get_virtual_price())
            .mul(10000 + withdrawCompensation).div(10000);
        amount = _withdrawXCurve(bCrvGauge, amount);

        uint256 bBefore = IERC20(want).balanceOf(address(this));

        ICrvPoolZap(busdPoolZap).remove_liquidity_one_coin(amount, tokenIndexBusd, 1);

        uint256 bAfter = IERC20(want).balanceOf(address(this));

        return bAfter.sub(bBefore);
    }

    /**
     * @dev Internal function to withdraw yCurve, handle the case when withdraw amount exceeds the buffer
     * @param gauge Gauge address (3pool, busd, usdt)
     * @param amount Amount of yCurve to withdraw
     */
    function _withdrawXCurve(address gauge, uint256 amount) internal returns (uint256) {
        uint256 a = Math.min(ICrvDeposit(gauge).balanceOf(address(this)), amount);
        ICrvDeposit(gauge).withdraw(a);
        return a;
    }
    
    function balanceOf() public view returns (uint) {
        return IERC20(want).balanceOf(address(this))
                .add(balanceInPool());
    }
    
    function underlyingBalanceOf() public view returns (uint) {
        return IERC20(want).balanceOf(address(this))
                .add(underlyingBalanceInPool());
    }

    function balanceInPool() public view returns (uint256) {
        return ICrvDeposit(bCrvGauge).balanceOf(address(this)).mul(ICrvPoolUnderlying(busdPool).get_virtual_price()).div(1e18);
    }

    function underlyingBalanceInPool() public view returns (uint256) {
        uint balance = ICrvDeposit(bCrvGauge).balanceOf(address(this));
        if (balance == 0) {
            return 0;
        }
        uint balanceVirtual = balance.mul(ICrvPoolUnderlying(busdPool).get_virtual_price()).div(1e18);
        uint balanceUnderlying = ICrvPoolZap(busdPoolZap).calc_withdraw_one_coin(balance, tokenIndexBusd);
        return Math.min(balanceVirtual, balanceUnderlying);
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function changeManageFee(uint256 newManageFee) external {
        require(msg.sender == governance, "!governance");
        require(newManageFee <= 100, "must less than 100%!");
        manageFee = newManageFee;
    }

    function changeBelWantRatio(uint256 newToBella, uint256 newToWant) external {
        require(msg.sender == governance, "!governance");
        require(newToBella.add(newToWant) == 100, "must divide all the pool");
        toBella = newToBella;
        toWant = newToWant;
    }

    function setDistributionAndBurnRatio(uint256 newDistributionPercent, uint256 newBurnPercent) external{
        require(msg.sender == governance, "!governance");
        require(newDistributionPercent.add(newBurnPercent) == 100, "must be 100% total");
        distributionPercent = newDistributionPercent;
        burnPercent = newBurnPercent;
    }

    function setBurnAddress(address _burnAddress) public{
        require(msg.sender == governance, "!governance");
        require(_burnAddress != address(0), "cannot send bella to 0 address");
        burnAddress = _burnAddress;
    }

    function setWithdrawCompensation(uint256 _withdrawCompensation) public {
        require(msg.sender == governance, "!governance");
        require(_withdrawCompensation <= 100, "too much compensation");
        withdrawCompensation = _withdrawCompensation;
    }

    /**
    * @dev Wraps the coin amount in the array for interacting with the Curve protocol
    */
    function wrapCoinAmount(uint256 amount, uint56 index) internal pure returns (uint256[4] memory) {
        uint256[4] memory amounts = [uint256(0), uint256(0), uint256(0), uint256(0)];
        amounts[index] = amount;
        return amounts;
    }
}