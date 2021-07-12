/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

// File: openzeppelin-contracts-2.5.1/contracts/token/ERC20/IERC20.sol

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

// File: openzeppelin-contracts-2.5.1/contracts/math/SafeMath.sol

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

// File: openzeppelin-contracts-2.5.1/contracts/math/Math.sol

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

// File: openzeppelin-contracts-2.5.1/contracts/utils/Address.sol

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

// File: openzeppelin-contracts-2.5.1/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




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

// File: interfaces/yearn/IController.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface IController {
    function withdraw(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function earn(address, uint256) external;

    function want(address) external view returns (address);

    function rewards() external view returns (address);

    function vaults(address) external view returns (address);

    function strategies(address) external view returns (address);
}

// File: contracts/strategies/StrategyACryptoS0V6_ACS.sol

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;







contract StrategyACryptoS0V6_ACS {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Math for uint256;

    address public constant want = address(0x4197C6EF3879a08cD51e5560da5064B773aa1d29); //ACS

    struct BlpToLiquidate {
        address pool;
        address tokenOut; //token to get
    }
    struct PairToLiquidate {
        address pair;
        address tokenA;
        address tokenB;
        address router;
    }
    struct SsToLiquidate {
        address pool;
        address lpToken;
        int128 i; //token to get
    }
    struct TokenToSwap {
        address tokenIn;
        address tokenOut;
        address router;
    }
    struct SsTokenToSwap {
        address tokenIn;
        address pool;
        bool underlying;
        int128 i;
        int128 j;
    }
    struct BlpTokenToSwap {
        address pool;
        address tokenIn;
        address tokenOut;
    }
    address public blpFeesCollector;
    address[] public blpFeesTokensToCollect;
    address[] public ssToWithdraw; //StableSwap pools to withdraw admin fees from
    BlpToLiquidate[] public blpsToLiquidate;
    SsToLiquidate[] public ssToLiquidate;
    PairToLiquidate[] public pairsToLiquidate;
    SsTokenToSwap[] public ssTokensToSwap;
    TokenToSwap[] public tokensToSwap0;
    TokenToSwap[] public tokensToSwap1;
    BlpTokenToSwap[] public blpTokensToSwap0;
    BlpTokenToSwap[] public blpTokensToSwap1;

    address public governance;
    address public controller;
    address public strategist;

    uint256 public withdrawalFee = 1000; //10%
    uint256 public harvesterReward = 30;
    uint256 public constant FEE_DENOMINATOR = 10000;

    constructor(address _controller, address _governance) public {
      strategist = msg.sender;
      governance = _governance;
      controller = _controller;

      ssTokensToSwap.push(SsTokenToSwap({
        tokenIn: address(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3), //dai
        pool: address(0xb3F0C9ea1F05e312093Fdb031E789A756659B0AC), //ACS4 StableSwap
        underlying: false,
        i: 2,
        j: 0
      }));

      ssTokensToSwap.push(SsTokenToSwap({
        tokenIn: address(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d), //usdc
        pool: address(0xb3F0C9ea1F05e312093Fdb031E789A756659B0AC), //ACS4 StableSwap
        underlying: false,
        i: 3,
        j: 0
      }));

      ssTokensToSwap.push(SsTokenToSwap({
        tokenIn: address(0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7), //vai
        pool: address(0x191409D5A4EfFe25b0f4240557BA2192D18a191e), //ACS4VAI StableSwap
        underlying: true,
        i: 0,
        j: 1
      }));

      ssTokensToSwap.push(SsTokenToSwap({
        tokenIn: address(0x23396cF899Ca06c4472205fC903bDB4de249D6fC), //ust
        pool: address(0x99c92765EfC472a9709Ced86310D64C4573c4b77), //ACS4UST StableSwap
        underlying: true,
        i: 0,
        j: 1
      }));



      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x1B96B92314C44b159149f7E0303511fB2Fc4774f),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x610e7a287c27dfFcaC0F0a94f547Cc1B770cF483),
        tokenA: address(0x4B0F1812e5Df2A09796481Ff14017e6005508003), // twt
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xA527a61703D82139F8a06Bc30097cC9CAA2df5A6),
        tokenA: address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82), // cake
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x41182c32F854dd97bA0e0B1816022e0aCB2fc0bb),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63), // xvs
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x70D8929d04b60Af4fb9B58713eBcf18765aDE422),
        tokenA: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x7561EEe90e24F3b348E1087A005F78B4c8453524),
        tokenA: address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c), // btcb
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x752E713fB70E3FA1Ac08bCF34485F14A986956c4),
        tokenA: address(0x47BEAd2563dCBf3bF2c9407fEa4dC236fAbA485A), // sxp
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xfF17ff314925Dff772b71AbdFF2782bC913B3575),
        tokenA: address(0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7), // vai
        tokenB: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x680Dd100E4b394Bda26A59dD5c119A391e747d18),
        tokenA: address(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d), // usdc
        tokenB: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xc15fa3E22c912A276550F3E5FE3b0Deb87B55aCd),
        tokenA: address(0x55d398326f99059fF775485246999027B3197955), // usdt
        tokenB: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x3aB77e40340AB084c3e23Be8e5A6f7afed9D41DC),
        tokenA: address(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3), // dai
        tokenB: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x91589786D36fEe5B27A5539CfE638a5fc9834665),
        tokenA: address(0x78650B139471520656b9E7aA7A5e9276814a38e9), // btcst
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xBc765Fd113c5bDB2ebc25F711191B56bB8690aec),
        tokenA: address(0x4338665CBB7B2485A8855A139b75D5e34AB0DB94), // ltc
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xbEA35584b9a88107102ABEf0BDeE2c4FaE5D8c31),
        tokenA: address(0x728C5baC3C3e370E372Fc4671f9ef6916b814d8B), // unfi
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xBA51D1AB95756ca4eaB8737eCD450cd8F05384cF),
        tokenA: address(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47), // ada
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x68Ff2ca47D27db5Ac0b5c46587645835dD51D3C1),
        tokenA: address(0x88f1A5ae2A3BF98AEAF342D26B30a79438c9142e), // yfi
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x99d865Ed50D2C32c1493896810FA386c1Ce81D91),
        tokenA: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        tokenB: address(0x250632378E573c6Be1AC2f97Fcdf00515d0Aa91B), // beth
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x0392957571F28037607C14832D16f8B653eDd472),
        tokenA: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        tokenB: address(0x52CE071Bd9b1C4B00A0b92D298c512478CaD67e8), // comp
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x17580340F3dAEDAE871a8C21D15911742ec79e0F),
        tokenA: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        tokenB: address(0x947950BcC74888a40Ffa2593C5798F11Fc9124C4), // sushi
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xcBe2cF3bd012e9C1ADE2Ee4d41DB3DaC763e78F3),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xD41FDb03Ba84762dD66a0af1a6C8540FF1ba5dfb), // sfp
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x4269e7F43A63CEA1aD7707Be565a94a9189967E9),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xBf5140A22578168FD562DCcF235E5D43A02ce9B1), // uni
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x36b7D2e5C7877392Fb17f9219efaD56F3D794700),
        tokenA: address(0x928e55daB735aa8260AF3cEDadA18B5f70C72f1b), // front
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xbCD62661A6b1DEd703585d3aF7d7649Ef4dcDB5c),
        tokenA: address(0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402), // dot
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xaeBE45E3a03B734c68e5557AE04BFC76917B4686),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD), // link
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xc639187ef82271D8f517de6FEAE4FaF5b517533c),
        tokenA: address(0xAD6cAEb32CD2c308980a548bD0Bc5AA4306c6c18), // band
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x20bCC3b8a0091dDac2d0BC30F68E6CBb97de59Cd),
        tokenA: address(0x55d398326f99059fF775485246999027B3197955), // usdt
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x4576C456AF93a37a096235e5d83f812AC9aeD027),
        tokenA: address(0x71DE20e0C4616E7fcBfDD3f875d568492cBE4739), // swingby
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x4db28767D1527bA545CA5bbdA1C96a94ED6ff242),
        tokenA: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        tokenB: address(0xECa41281c24451168a37211F0bc2b8645AF45092), // tpt
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xC7b4B32A3be2cB6572a1c9959401F832Ce47a6d2),
        tokenA: address(0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE), // xrp
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xfEc200A5E3adDD4a7915a556DDe3F5850e644020),
        tokenA: address(0x658A109C5900BC6d2357c87549B651670E5b0539), // fort
        tokenB: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xe022baa3E5E87658f789c9132B10d7425Fd3a389),
        tokenA: address(0xAC51066d7bEC65Dc4589368da368b212745d63E8), // alice
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xdC6C130299E53ACD2CC2D291fa10552CA2198a6b),
        tokenA: address(0x7A9f28EB62C791422Aa23CeAE1dA9C847cBeC9b0), // watch
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xc746337b5F800a0e19eD4eB3bda03FF1401B8167),
        tokenA: address(0xb86AbCb37C3A4B64f74f59301AFF131a1BEcC787), // zil
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x496a8b716A3A3410B16e71E3c906968CE4488e52),
        tokenA: address(0x9f589e3eabe42ebC94A44727b3f3531C0c877809), // tko
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xb5F6f7dAD23132d40d778085D795BD0FD4B859CD),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xeD28A457A5A76596ac48d87C0f577020F6Ea1c4C), // pbtc
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xf64a269F0A06dA07D23F43c1Deb217101ee6Bee7),
        tokenA: address(0x23396cF899Ca06c4472205fC903bDB4de249D6fC), // ust
        tokenB: address(0x5B6DcF557E2aBE2323c48445E8CC948910d8c2c9), // mir
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x34e821e785A93261B697eBD2797988B3AA78ca33),
        tokenA: address(0x2222227E22102Fe3322098e4CBfE18cFebD57c95), // tlm
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) // pancakeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xF570d6e751976D0d10aa64ACfa829A5ea4a51727),
        tokenA: address(0x47BEAd2563dCBf3bF2c9407fEa4dC236fAbA485A), // sxp
        tokenB: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        router: address(0x816278BbBCc529f8cdEE8CC72C226fb01def6E6C) // swipeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xB450606703743D557a1c8384Fffe6b941F8f60F4),
        tokenA: address(0x47BEAd2563dCBf3bF2c9407fEa4dC236fAbA485A), // sxp
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x816278BbBCc529f8cdEE8CC72C226fb01def6E6C) // swipeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x70b31Abf9Be826eDc188A15fC35cc6037103a58F),
        tokenA: address(0x47BEAd2563dCBf3bF2c9407fEa4dC236fAbA485A), // sxp
        tokenB: address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c), // btcb
        router: address(0x816278BbBCc529f8cdEE8CC72C226fb01def6E6C) // swipeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xC61FB584DAf69Bedf912768AEdc0658B11A1A75C),
        tokenA: address(0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7), // vai
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x816278BbBCc529f8cdEE8CC72C226fb01def6E6C) // swipeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xef82bD8287dA9700b004657170746968CF5cA04a),
        tokenA: address(0x4197C6EF3879a08cD51e5560da5064B773aa1d29), // acs
        tokenB: address(0x47BEAd2563dCBf3bF2c9407fEa4dC236fAbA485A), // sxp
        router: address(0x816278BbBCc529f8cdEE8CC72C226fb01def6E6C) // swipeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x55d398326f99059fF775485246999027B3197955), // usdt
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x74E4716E431f45807DCF19f284c7aA99F18a4fbc),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x61EB789d75A95CAa3fF50ed7E47b96c132fEc082),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c), // btcb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x0362ba706DFE8ED12Ec1470aB171d8Dcb1C72B8D),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xeD28A457A5A76596ac48d87C0f577020F6Ea1c4C), // pbtc
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x71b01eBdDD797c8E9E0b003ea2f4FD207fBF46cC),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x4338665CBB7B2485A8855A139b75D5e34AB0DB94), // ltc
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xCE383277847f8217392eeA98C5a8B4a7D27811b0),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x88f1A5ae2A3BF98AEAF342D26B30a79438c9142e), // yfi
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x28415ff2C35b65B9E5c7de82126b4015ab9d031F),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47), // ada
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x014608E87AF97a054C9a49f81E1473076D51d9a3),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xBf5140A22578168FD562DCcF235E5D43A02ce9B1), // uni
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xDd5bAd8f8b360d76d12FdA230F8BAF42fe0022CF),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402), // dot
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x03F18135c44C64ebFdCBad8297fe5bDafdBbdd86),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE), // xrp
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x824eb9faDFb377394430d2744fa7C42916DE3eCe),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD), // link
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x168B273278F3A8d302De5E879aA30690B7E6c28f),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xAD6cAEb32CD2c308980a548bD0Bc5AA4306c6c18), // band
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x6A97867a4b7Eb7646ffB1F359ad582e9903aa1C2),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xb86AbCb37C3A4B64f74f59301AFF131a1BEcC787), // zil
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x3DcB1787a95D2ea0Eb7d00887704EeBF0D79bb13),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x4B0F1812e5Df2A09796481Ff14017e6005508003), // twt
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x44EA47F2765fd5D26b7eF0222736AD6FD6f61950),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x728C5baC3C3e370E372Fc4671f9ef6916b814d8B), // unfi
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xB2678C414ebC63c9CC6d1a0fC45f43E249B50fdE),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x78650B139471520656b9E7aA7A5e9276814a38e9), // btcst
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x942b294e59a8c47a0F7F20DF105B082710F7C305),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xD41FDb03Ba84762dD66a0af1a6C8540FF1ba5dfb), // sfp
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xFFd4B200d3C77A0B691B5562D804b3bd54294e6e),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x9f589e3eabe42ebC94A44727b3f3531C0c877809), // tko
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xE6b421a4408c82381b226Ab5B6F8C4b639044359),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x2222227E22102Fe3322098e4CBfE18cFebD57c95), // tlm
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xcAD7019D6d84a3294b0494aEF02e73BD0f2572Eb),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xAC51066d7bEC65Dc4589368da368b212745d63E8), // alice
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xC6b668548aA4A56792e8002A920d3159728121D5),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x928e55daB735aa8260AF3cEDadA18B5f70C72f1b), // front
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x13321AcfF4A27f3d2bcA64b8bEaC6e5FdAAAf12C),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x7A9f28EB62C791422Aa23CeAE1dA9C847cBeC9b0), // watch
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x4Fd6D315bEf387fAD2322fbc64368fC443F0886D),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x71DE20e0C4616E7fcBfDD3f875d568492cBE4739), // swingby
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x7EFaEf62fDdCCa950418312c6C91Aef321375A00),
        tokenA: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        tokenB: address(0x55d398326f99059fF775485246999027B3197955), // usdt
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xE60B4e87645093A42fa9dcC5d0C8Df6E67f1f9d2),
        tokenA: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        tokenB: address(0x658A109C5900BC6d2357c87549B651670E5b0539), // fort
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x6D0c831254221ba121fB53fb44Df289A6558867d),
        tokenA: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        tokenB: address(0xECa41281c24451168a37211F0bc2b8645AF45092), // tpt
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x89666d026696660e93Bf6edf57B71A68615768B7),
        tokenA: address(0x23396cF899Ca06c4472205fC903bDB4de249D6fC), // ust
        tokenB: address(0x5B6DcF557E2aBE2323c48445E8CC948910d8c2c9), // mir
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x37908620dEf1491Dd591b5a2d16022A33cDDA415),
        tokenA: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        tokenB: address(0x52CE071Bd9b1C4B00A0b92D298c512478CaD67e8), // comp
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x16aFc4F2Ad82986bbE2a4525601F8199AB9c832D),
        tokenA: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        tokenB: address(0x947950BcC74888a40Ffa2593C5798F11Fc9124C4), // sushi
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xACF47CBEaab5c8A6Ee99263cfE43995f89fB3206),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xa1faa113cbE53436Df28FF0aEe54275c13B40975), // alpha
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xd63b5CecB1f40d626307B92706Df357709D05827),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xF21768cCBC73Ea5B6fd3C687208a7c2def2d966e), // reef
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x460b4193Ec4C1a17372Aa5FDcd44c520ba658646),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xA8c2B8eec3d368C0253ad3dae65a5F2BBB89c929), // ctk
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xF45cd219aEF8618A92BAa7aD848364a158a24F33),
        tokenA: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        tokenB: address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c), // btcb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x0eD7e52944161450477ee417DE9Cd3a859b14fD0),
        tokenA: address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82), // cake
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x7EB5D86FD78f3852a3e0e064f2842d45a3dB6EA2),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63), // xvs
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xD8E2F8b6Db204c405543953Ef6359912FE3A88d6),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x47BEAd2563dCBf3bF2c9407fEa4dC236fAbA485A), // sxp
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x478d6c9FFa3609Faa1bfc4afc2770447CA327705),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x4197C6EF3879a08cD51e5560da5064B773aa1d29), // acs
        router: address(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8) // mdexRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xAf9Aa53146C5752BF6068A84B970E9fBB22a87bc),
        tokenA: address(0x9C65AB58d8d978DB963e63f2bfB7121627e3a739), // mdx
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8) // mdexRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xa12128Bbb1C24Fb851d8BA6EC6836f00916712c2),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c), // btcb
        router: address(0x816278BbBCc529f8cdEE8CC72C226fb01def6E6C) // swipeSwapRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x804678fa97d91B974ec2af3c843270886528a9E6),
        tokenA: address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82), // cake
        tokenB: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xEf5212aDa83EC2cc105C409DF10b8806D20E3b35),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x5F84ce30DC3cF7909101C69086c50De191895883), // vrt
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xBA68d6beE4f433630DeE22C248A236c8f6EAe246),
        tokenA: address(0x9C65AB58d8d978DB963e63f2bfB7121627e3a739), // mdx
        tokenB: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        router: address(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8) // mdexRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x1c0276642f2A7cbcf6624d511F34811cDC65212C),
        tokenA: address(0x9C65AB58d8d978DB963e63f2bfB7121627e3a739), // mdx
        tokenB: address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c), // btcb
        router: address(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8) // mdexRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x223740a259E461aBeE12D84A9FFF5Da69Ff071dD),
        tokenA: address(0x9C65AB58d8d978DB963e63f2bfB7121627e3a739), // mdx
        tokenB: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        router: address(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8) // mdexRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x2E28b9B74D6d99D4697e913b82B41ef1CAC51c6C),
        tokenA: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        tokenB: address(0x14016E85a25aeb13065688cAFB43044C2ef86784), // tusd
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xEa26B78255Df2bBC31C1eBf60010D78670185bD0),
        tokenA: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        tokenB: address(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d), // usdc
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x82E8F9e7624fA038DfF4a39960F5197A43fa76aa),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        router: address(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8) // mdexRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x969f2556F786a576F32AeF6c1D6618f0221Ec70e),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c), // btcb
        router: address(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8) // mdexRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xda28Eb7ABa389C1Ea226A420bCE04Cb565Aafb85),
        tokenA: address(0x55d398326f99059fF775485246999027B3197955), // usdt
        tokenB: address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c), // btcb
        router: address(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8) // mdexRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x0FB881c078434b1C0E4d0B64d8c64d12078b7Ce2),
        tokenA: address(0x55d398326f99059fF775485246999027B3197955), // usdt
        tokenB: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        router: address(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8) // mdexRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x577d005912C49B1679B4c21E334FdB650E92C077),
        tokenA: address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c), // btcb
        tokenB: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        router: address(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8) // mdexRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xA39Af17CE4a8eb807E076805Da1e2B8EA7D0755b),
        tokenA: address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82), // cake
        tokenB: address(0x55d398326f99059fF775485246999027B3197955), // usdt
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x76AE2c33bcce5A45128eF2060C6280a452568396),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x728C5baC3C3e370E372Fc4671f9ef6916b814d8B), // unfi
        router: address(0xBE930734eDAfc41676A76d2240f206Ed36dafbA2) // unifiRouter
      }));

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x2bCc1FeF8F31A1E4cf8C85f96F00C543b98dA74e),
        tokenA: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        tokenB: address(0x4197C6EF3879a08cD51e5560da5064B773aa1d29), // acs
        router: address(0xBE930734eDAfc41676A76d2240f206Ed36dafbA2) // unifiRouter
      }));





      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x88f1A5ae2A3BF98AEAF342D26B30a79438c9142e), // yfi
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x55d398326f99059fF775485246999027B3197955), // usdt
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x4B0F1812e5Df2A09796481Ff14017e6005508003), // twt
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x78650B139471520656b9E7aA7A5e9276814a38e9), // btcst
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x4338665CBB7B2485A8855A139b75D5e34AB0DB94), // ltc
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47), // ada
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xD41FDb03Ba84762dD66a0af1a6C8540FF1ba5dfb), // sfp
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xBf5140A22578168FD562DCcF235E5D43A02ce9B1), // uni
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD), // link
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xeD28A457A5A76596ac48d87C0f577020F6Ea1c4C), // pbtc
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x928e55daB735aa8260AF3cEDadA18B5f70C72f1b), // front
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402), // dot
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xAD6cAEb32CD2c308980a548bD0Bc5AA4306c6c18), // band
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x71DE20e0C4616E7fcBfDD3f875d568492cBE4739), // swingby
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE), // xrp
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xAC51066d7bEC65Dc4589368da368b212745d63E8), // alice
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x7A9f28EB62C791422Aa23CeAE1dA9C847cBeC9b0), // watch
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xb86AbCb37C3A4B64f74f59301AFF131a1BEcC787), // zil
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x9f589e3eabe42ebC94A44727b3f3531C0c877809), // tko
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x2222227E22102Fe3322098e4CBfE18cFebD57c95), // tlm
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x658A109C5900BC6d2357c87549B651670E5b0539), // for
        tokenOut: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xECa41281c24451168a37211F0bc2b8645AF45092), // tpt
        tokenOut: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x52CE071Bd9b1C4B00A0b92D298c512478CaD67e8), // comp
        tokenOut: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x947950BcC74888a40Ffa2593C5798F11Fc9124C4), // sushi
        tokenOut: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x5B6DcF557E2aBE2323c48445E8CC948910d8c2c9), // mir
        tokenOut: address(0x23396cF899Ca06c4472205fC903bDB4de249D6fC), // ust
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xa1faa113cbE53436Df28FF0aEe54275c13B40975), // alpha
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xF21768cCBC73Ea5B6fd3C687208a7c2def2d966e), // reef
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xA8c2B8eec3d368C0253ad3dae65a5F2BBB89c929), // ctk
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x8fF795a6F4D97E7887C79beA79aba5cc76444aDf), // bch
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8) // mdexRouter
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x14016E85a25aeb13065688cAFB43044C2ef86784), // tusd
        tokenOut: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), // busd
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x0D8Ce2A99Bb6e3B7Db580eD848240e4a0F9aE153), // fil
        tokenOut: address(0x55d398326f99059fF775485246999027B3197955), // usdt
        router: address(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8) // mdexRouter
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xbA2aE424d960c26247Dd6c32edC70B295c744C43), // doge
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0x10ED43C718714eb63d5aA57B78B54704E256024E) // pancakeSwapV2Router
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xb4E8D978bFf48c2D8FA241C0F323F71C1457CA81), // up
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0xBE930734eDAfc41676A76d2240f206Ed36dafbA2) // unifiRouter
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x728C5baC3C3e370E372Fc4671f9ef6916b814d8B), // unfi
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), // wbnb
        router: address(0xBE930734eDAfc41676A76d2240f206Ed36dafbA2) // unifiRouter
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x250632378E573c6Be1AC2f97Fcdf00515d0Aa91B), // beth
        tokenOut: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), // eth
        router: address(0xCDe540d7eAFE93aC5fE6233Bee57E1270D3E330F) // bakerySwapRouter
      }));


      blpTokensToSwap0.push(BlpTokenToSwap({
        pool: address(0xDfd7684dbd0C31a302aBaC3a4b62caAdD1235E7F), //acsiXvsSxpVrtVaiBnb
        tokenIn: address(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63), // xvs
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c) // wbnb
      }));
      blpTokensToSwap0.push(BlpTokenToSwap({
        pool: address(0xDfd7684dbd0C31a302aBaC3a4b62caAdD1235E7F), //acsiXvsSxpVrtVaiBnb
        tokenIn: address(0x47BEAd2563dCBf3bF2c9407fEa4dC236fAbA485A), // sxp
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c) // wbnb
      }));
      blpTokensToSwap0.push(BlpTokenToSwap({
        pool: address(0xDfd7684dbd0C31a302aBaC3a4b62caAdD1235E7F), //acsiXvsSxpVrtVaiBnb
        tokenIn: address(0x5F84ce30DC3cF7909101C69086c50De191895883), // vrt
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c) // wbnb
      }));

      blpTokensToSwap0.push(BlpTokenToSwap({
        pool: address(0x56C4F0984Ce2c82e340E697210984Fc9b1532eE6), //acsiCakeMdxHmdxBakeAcsiBnb
        tokenIn: address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82), // cake
        tokenOut: address(0x5b17b4d5e4009B5C43e3e3d63A5229F794cBA389) //acsi
      }));
      blpTokensToSwap0.push(BlpTokenToSwap({
        pool: address(0x56C4F0984Ce2c82e340E697210984Fc9b1532eE6), //acsiCakeMdxHmdxBakeAcsiBnb
        tokenIn: address(0x9C65AB58d8d978DB963e63f2bfB7121627e3a739), // mdx
        tokenOut: address(0x5b17b4d5e4009B5C43e3e3d63A5229F794cBA389) //acsi
      }));

      blpTokensToSwap0.push(BlpTokenToSwap({
        pool: address(0x7ea9F435c7CcB2eEF266F5366fe13ea6C9F3e245), //acs3
        tokenIn: address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c), //btcb
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c) //wbnb
      }));
      blpTokensToSwap0.push(BlpTokenToSwap({
        pool: address(0x7ea9F435c7CcB2eEF266F5366fe13ea6C9F3e245), //acs3
        tokenIn: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), //eth
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c) //wbnb
      }));


      blpTokensToSwap1.push(BlpTokenToSwap({
        pool: address(0x894eD9026De37AfD9CCe1E6C0BE7d6b510e3FfE5), //a2b2
        tokenIn: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), //wbnb
        tokenOut: address(0x4197C6EF3879a08cD51e5560da5064B773aa1d29) //acs
      }));
      blpTokensToSwap1.push(BlpTokenToSwap({
        pool: address(0x894eD9026De37AfD9CCe1E6C0BE7d6b510e3FfE5), //a2b2
        tokenIn: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), //busd
        tokenOut: address(0x4197C6EF3879a08cD51e5560da5064B773aa1d29) //acs
      }));
      blpTokensToSwap1.push(BlpTokenToSwap({
        pool: address(0x894eD9026De37AfD9CCe1E6C0BE7d6b510e3FfE5), //a2b2
        tokenIn: address(0x5b17b4d5e4009B5C43e3e3d63A5229F794cBA389), //acsi
        tokenOut: address(0x4197C6EF3879a08cD51e5560da5064B773aa1d29) //acs
      }));

    }

    function getName() external pure returns (string memory) {
        return "StrategyACryptoS0V6_ACS";
    }

    function deposit() public {
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external {
      require(msg.sender == controller, "!controller");
      uint256 _balance = IERC20(want).balanceOf(address(this));
      if (_balance < _amount) {
          _amount = _balance;
      }

      uint256 _fee = _amount.mul(withdrawalFee).div(FEE_DENOMINATOR);

      address _vault = IController(controller).vaults(address(want));
      require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
      IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
      require(msg.sender == controller || msg.sender == strategist || msg.sender == governance, "!authorized");

      balance = IERC20(want).balanceOf(address(this));

      address _vault = IController(controller).vaults(address(want));
      require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
      IERC20(want).safeTransfer(_vault, balance);
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function harvest() public returns (uint harvesterRewarded) {
      require(msg.sender == tx.origin, "not eoa");

      uint _before = IERC20(want).balanceOf(address(this));
      _convertAllToWant();
      uint _harvested = IERC20(want).balanceOf(address(this)).sub(_before);

      if (_harvested > 0) {
        uint256 _harvesterReward = _harvested.mul(harvesterReward).div(FEE_DENOMINATOR);
        IERC20(want).safeTransfer(msg.sender, _harvesterReward);
        return _harvesterReward;
      }
    }


    function _convertAllToWant() internal {
      if(blpFeesTokensToCollect.length > 0) _collectBlpFees();

      for (uint i=ssToWithdraw.length; i>0; i--) {
        IStableSwap(ssToWithdraw[i-1]).withdraw_admin_fees();
      }

      for (uint i=blpsToLiquidate.length; i>0; i--) {
        _liquidateBlp(blpsToLiquidate[i-1]);
      }

      for (uint i=ssToLiquidate.length; i>0; i--) {
        _liquidateSs(ssToLiquidate[i-1]);
      }

      for (uint i=pairsToLiquidate.length; i>0; i--) {
        _liquidatePair(pairsToLiquidate[i-1].pair, pairsToLiquidate[i-1].tokenA, pairsToLiquidate[i-1].tokenB, pairsToLiquidate[i-1].router);
      }

      for (uint i=ssTokensToSwap.length; i>0; i--) {
        _swapSs(ssTokensToSwap[i-1]);
      }

      for (uint i=tokensToSwap0.length; i>0; i--) {
        _convertToken(tokensToSwap0[i-1].tokenIn, tokensToSwap0[i-1].tokenOut, tokensToSwap0[i-1].router);
      }

      for (uint i=blpTokensToSwap0.length; i>0; i--) {
        _swapBlpToken(blpTokensToSwap0[i-1]);
      }

      for (uint i=tokensToSwap1.length; i>0; i--) {
        _convertToken(tokensToSwap1[i-1].tokenIn, tokensToSwap1[i-1].tokenOut, tokensToSwap1[i-1].router);
      }

      for (uint i=blpTokensToSwap1.length; i>0; i--) {
        _swapBlpToken(blpTokensToSwap1[i-1]);
      }

    }

    function _swapBlpToken(BlpTokenToSwap memory _blpTokenToSwap) internal {
      uint256 _amount = IERC20(_blpTokenToSwap.tokenIn).balanceOf(address(this));
      if(_amount > 0) {
        address _vault = IBlpPool(_blpTokenToSwap.pool).getVault();
        IERC20(_blpTokenToSwap.tokenIn).safeApprove(_vault, 0);
        IERC20(_blpTokenToSwap.tokenIn).safeApprove(_vault, _amount);
        IBlpVault(_vault).swap(
          IBlpVault.SingleSwap({
            poolId: IBlpPool(_blpTokenToSwap.pool).getPoolId(),
            kind: IBlpVault.SwapKind.GIVEN_IN,
            assetIn: _blpTokenToSwap.tokenIn,
            assetOut: _blpTokenToSwap.tokenOut,
            amount: _amount,
            userData: ''
          }),
          IBlpVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: address(this),
            toInternalBalance: false
          }),
          0,                //limit
          now.add(1800)     // deadline
        );
      }      
    }

    function _liquidateBlp(BlpToLiquidate memory _blpToLiquidate) internal {
      uint256 _amount = IERC20(_blpToLiquidate.pool).balanceOf(address(this));
      if(_amount > 0) {
        address _vault = IBlpPool(_blpToLiquidate.pool).getVault();
        IERC20(_blpToLiquidate.pool).safeApprove(_vault, 0);
        IERC20(_blpToLiquidate.pool).safeApprove(_vault, _amount);

        bytes32 poolId = IBlpPool(_blpToLiquidate.pool).getPoolId();
        (address[] memory assets,,) = IBlpVault(_vault).getPoolTokens(poolId);

        uint256[] memory minAmountsOut = new uint256[](assets.length);

        uint256 tokenIndex;
        for(uint i = 0; i < assets.length; i++) {
          if(assets[i] == _blpToLiquidate.tokenOut) {
            tokenIndex = i;
            break;
          }
        }

        IBlpVault(_vault).exitPool(
          poolId,
          address(this), //sender
          address(this), //recipient
          IBlpVault.ExitPoolRequest({
            assets: assets,  
            minAmountsOut: minAmountsOut,
            userData: abi.encode(IBlpPool.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, _amount, tokenIndex),
            toInternalBalance: false
          })
        );
      }
    }

    function _collectBlpFees() internal {
      IBlpFeesCollector(blpFeesCollector).withdrawCollectedFees(
        blpFeesTokensToCollect,
        IBlpFeesCollector(blpFeesCollector).getCollectedFeeAmounts(blpFeesTokensToCollect),
        address(this)
      );
    }

    function _liquidateSs(SsToLiquidate memory _ssToLiquidate) internal {
      uint256 _amount = IERC20(_ssToLiquidate.lpToken).balanceOf(address(this));
      if(_amount > 0) {
        IERC20(_ssToLiquidate.lpToken).safeApprove(_ssToLiquidate.pool, 0);
        IERC20(_ssToLiquidate.lpToken).safeApprove(_ssToLiquidate.pool, _amount);
        IStableSwap(_ssToLiquidate.pool).remove_liquidity_one_coin(_amount, _ssToLiquidate.i, 0);
      }
    }

    function _swapSs(SsTokenToSwap memory _ssTokenToSwap) internal {
      uint256 _amount = IERC20(_ssTokenToSwap.tokenIn).balanceOf(address(this));
      if(_amount > 0) {
        IERC20(_ssTokenToSwap.tokenIn).safeApprove(_ssTokenToSwap.pool, 0);
        IERC20(_ssTokenToSwap.tokenIn).safeApprove(_ssTokenToSwap.pool, _amount);
        if(_ssTokenToSwap.underlying) {
          IStableSwap(_ssTokenToSwap.pool).exchange_underlying(_ssTokenToSwap.i, _ssTokenToSwap.j, _amount, 0);            
        } else {
          IStableSwap(_ssTokenToSwap.pool).exchange(_ssTokenToSwap.i, _ssTokenToSwap.j, _amount, 0);            
        }
      }      
    }

    function _liquidatePair(address _pair, address _tokenA, address _tokenB, address _router) internal {
      uint256 _amount = IERC20(_pair).balanceOf(address(this));
      if(_amount > 0 ) {
        IERC20(_pair).safeApprove(_router, 0);
        IERC20(_pair).safeApprove(_router, _amount);

        IUniswapRouter(_router).removeLiquidity(
            _tokenA, // address tokenA,
            _tokenB, // address tokenB,
            _amount, // uint liquidity,
            0, // uint amountAMin,
            0, // uint amountBMin,
            address(this), // address to,
            now.add(1800) // uint deadline
          );
      }
    }

    function _convertToken(address _tokenIn, address _tokenOut, address _router) internal {
      uint256 _amount = IERC20(_tokenIn).balanceOf(address(this));
      if(_amount > 0 ) {
        IERC20(_tokenIn).safeApprove(_router, 0);
        IERC20(_tokenIn).safeApprove(_router, _amount);

        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        IUniswapRouter(_router).swapExactTokensForTokens(_amount, uint256(0), path, address(this), now.add(1800));
      }
    }

    function balanceOf() public view returns (uint256) {
      return balanceOfWant();
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setBlpFeesCollector(address _blpFeesCollector) external {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      blpFeesCollector = _blpFeesCollector;
    }

    function addBlpFeesTokensToCollect(address[] calldata _blpFeesTokensToCollect) external {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      for (uint i=0; i < _blpFeesTokensToCollect.length; i++) {
        blpFeesTokensToCollect.push(_blpFeesTokensToCollect[i]);
      }
    }

    function addSsToWithdraw(address[] calldata _ssToWithdraw) external {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      for (uint i=0; i < _ssToWithdraw.length; i++) {
        ssToWithdraw.push(_ssToWithdraw[i]);
      }
    }

    function addBlpsToLiquidate(BlpToLiquidate[] memory _blpsToLiquidate) public {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      for (uint i=0; i < _blpsToLiquidate.length; i++) {
        blpsToLiquidate.push(_blpsToLiquidate[i]);
      }
    }

    function addSsToLiquidate(SsToLiquidate[] memory _ssToLiquidate) public {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      for (uint i=0; i < _ssToLiquidate.length; i++) {
        ssToLiquidate.push(_ssToLiquidate[i]);
      }
    }

    function addPairsToLiquidate(PairToLiquidate[] memory _pairsToLiquidate) public {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      for (uint i=0; i < _pairsToLiquidate.length; i++) {
        pairsToLiquidate.push(_pairsToLiquidate[i]);
      }
    }

    function addSsTokensToSwap(SsTokenToSwap[] memory _ssTokensToSwap) public {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      for (uint i=0; i < _ssTokensToSwap.length; i++) {
        ssTokensToSwap.push(_ssTokensToSwap[i]);
      }
    }

    function addTokensToSwap0(TokenToSwap[] memory _tokensToSwap) public {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      for (uint i=0; i < _tokensToSwap.length; i++) {
        tokensToSwap0.push(_tokensToSwap[i]);
      }
    }

    function addTokensToSwap1(TokenToSwap[] memory _tokensToSwap) public {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      for (uint i=0; i < _tokensToSwap.length; i++) {
        tokensToSwap1.push(_tokensToSwap[i]);
      }
    }

    function addBlpTokensToSwap0(BlpTokenToSwap[] memory _blpTokensToSwap) public {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      for (uint i=0; i < _blpTokensToSwap.length; i++) {
        blpTokensToSwap0.push(_blpTokensToSwap[i]);
      }
    }

    function addBlpTokensToSwap1(BlpTokenToSwap[] memory _blpTokensToSwap) public {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      for (uint i=0; i < _blpTokensToSwap.length; i++) {
        blpTokensToSwap1.push(_blpTokensToSwap[i]);
      }
    }

    function deleteBlpFeesTokensToCollect() external {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      delete blpFeesTokensToCollect;
    }

    function deleteSsToWithdraw() external {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      delete ssToWithdraw;
    }

    function deleteBlpsToLiquidate() external {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      delete blpsToLiquidate;
    }

    function deleteSsToLiquidate() external {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      delete ssToLiquidate;
    }

    function deletePairsToLiquidate() external {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      delete pairsToLiquidate;
    }

    function deleteSsTokensToSwap() external {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      delete ssTokensToSwap;
    }

    function deleteTokensToSwap0() external {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      delete tokensToSwap0;
    }

    function deleteTokensToSwap1() external {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      delete tokensToSwap1;
    }

    function deleteBlpTokensToSwap0() external {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      delete blpTokensToSwap0;
    }

    function deleteBlpTokensToSwap1() external {
      require(msg.sender == strategist || msg.sender == governance, "!authorized");
      delete blpTokensToSwap1;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }

    function setHarvesterReward(uint256 _harvesterReward) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        harvesterReward = _harvesterReward;
    }

    //In case anything goes wrong.
    //This does not increase user risk. Governance already controls funds via strategy upgrade, and is behind timelock and/or multisig.
    function executeTransaction(address target, uint value, string memory signature, bytes memory data) public payable returns (bytes memory) {
        require(msg.sender == governance, "!governance");

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        return returnData;
    }
}



interface IUniswapRouter {
  function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
  function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IStableSwap {
  function withdraw_admin_fees() external;
  function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external;
  function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256 dy);
  function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256 dy);
}

interface IBlpVault {
  function getPoolTokens(bytes32 poolId)
      external
      view
      returns (
          address[] memory tokens,
          uint256[] memory balances,
          uint256 lastChangeBlock
      );

  function exitPool(
      bytes32 poolId,
      address sender,
      address recipient,
      ExitPoolRequest calldata request
  ) external;

  struct ExitPoolRequest {
      address[] assets;
      uint256[] minAmountsOut;
      bytes userData;
      bool toInternalBalance;
  }

  function swap(
      SingleSwap calldata singleSwap,
      FundManagement calldata funds,
      uint256 limit,
      uint256 deadline
  ) external payable returns (uint256);

  struct SingleSwap {
      bytes32 poolId;
      SwapKind kind;
      address assetIn;
      address assetOut;
      uint256 amount;
      bytes userData;
  }

  enum SwapKind { GIVEN_IN, GIVEN_OUT }

  struct FundManagement {
      address sender;
      bool fromInternalBalance;
      address recipient;
      bool toInternalBalance;
  }
}

interface IBlpPool {
  enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

  function getVault() external view returns (address);
  function getPoolId() external view returns (bytes32);
}

interface IBlpFeesCollector {
  function withdrawCollectedFees(
      address[] calldata tokens,
      uint256[] calldata amounts,
      address recipient
  ) external;

  function getCollectedFeeAmounts(address[] calldata tokens) external view returns (uint256[] memory feeAmounts);
}