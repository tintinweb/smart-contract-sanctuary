/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

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


interface IController {
    function withdraw(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function earn(address, uint256) external;

    function want(address) external view returns (address);

    function rewards() external view returns (address);

    function vaults(address) external view returns (address);

    function strategies(address) external view returns (address);
}


// NOTE: Basically an alias for Vaults
interface yERC20 {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function getPricePerFullShare() external view returns (uint256);
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
}

contract StrategyACryptoS0V3 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Math for uint256;

    address public constant want = address(0x4197C6EF3879a08cD51e5560da5064B773aa1d29); //ACS
    address public constant pancakeSwapRouter = address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);

    struct PairToLiquidate {
        address pair;
        address tokenA;
        address tokenB;
        address router;
    }
    struct TokenToSwap {
        address tokenIn;
        address tokenOut;
        address router;
    }
    address[] public ssToWithdraw; //StableSwap pools to withdraw admin fees from
    PairToLiquidate[] public pairsToLiquidate;
    TokenToSwap[] public tokensToSwap0;
    TokenToSwap[] public tokensToSwap1;

    address public governance;
    address public controller;
    address public strategist;

    uint256 public withdrawalFee = 1000; //10%
    uint256 public harvesterReward = 30;
    uint256 public constant FEE_DENOMINATOR = 10000;

    constructor(address _controller) public {
      governance = msg.sender;
      strategist = msg.sender;
      controller = _controller;

      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x7561EEe90e24F3b348E1087A005F78B4c8453524), //btc-bnb
        tokenA: address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c), //btcb
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), //wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) //pancake
      }));
      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x70D8929d04b60Af4fb9B58713eBcf18765aDE422), //eth-bnb
        tokenA: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), //eth
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), //wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) //pancake
      }));
      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x41182c32F854dd97bA0e0B1816022e0aCB2fc0bb), //xvs-bnb
        tokenA: address(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63), //xvs
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), //wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) //pancake
      }));
      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x752E713fB70E3FA1Ac08bCF34485F14A986956c4), //sxp-bnb
        tokenA: address(0x47BEAd2563dCBf3bF2c9407fEa4dC236fAbA485A), //sxp
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), //wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) //pancake
      }));
      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0x1B96B92314C44b159149f7E0303511fB2Fc4774f), //busd-bnb
        tokenA: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), //busd
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), //wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) //pancake
      }));
      pairsToLiquidate.push(PairToLiquidate({
        pair: address(0xA527a61703D82139F8a06Bc30097cC9CAA2df5A6), //cake-bnb
        tokenA: address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82), //cake
        tokenB: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), //wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) //pancake
      }));

      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82), //cake
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), //wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) //pancake
      }));
      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c), //btc
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), //wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) //pancake
      }));
      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8), //eth
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), //wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) //pancake
      }));
      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63), //xvs
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), //wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) //pancake
      }));
      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0x47BEAd2563dCBf3bF2c9407fEa4dC236fAbA485A), //sxp
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), //wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) //pancake
      }));
      tokensToSwap0.push(TokenToSwap({
        tokenIn: address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56), //busd
        tokenOut: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), //wbnb
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) //pancake
      }));
      
      tokensToSwap1.push(TokenToSwap({
        tokenIn: address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), //wbnb
        tokenOut: address(0x4197C6EF3879a08cD51e5560da5064B773aa1d29), //acs
        router: address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F) //pancake
      }));
    }

    function getName() external pure returns (string memory) {
        return "StrategyACryptoS0V3";
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
      require(msg.sender == controller, "!controller");

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
      for (uint i=0; i<ssToWithdraw.length; i++) {
        IStableSwap(ssToWithdraw[i]).withdraw_admin_fees();
      }

      for (uint i=0; i<pairsToLiquidate.length; i++) {
        _liquidatePair(pairsToLiquidate[i].pair, pairsToLiquidate[i].tokenA, pairsToLiquidate[i].tokenB, pairsToLiquidate[i].router);
      }

      for (uint i=0; i<tokensToSwap0.length; i++) {
        _convertToken(tokensToSwap0[i].tokenIn, tokensToSwap0[i].tokenOut, tokensToSwap0[i].router);
      }

      for (uint i=0; i<tokensToSwap1.length; i++) {
        _convertToken(tokensToSwap1[i].tokenIn, tokensToSwap1[i].tokenOut, tokensToSwap1[i].router);
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



    function addSsToWithdraw(address _ss) external {
      require(msg.sender == governance, "!governance");
      ssToWithdraw.push(_ss);
    }

    function addPairToLiquidate(address _pair, address _tokenA, address _tokenB, address _router) external {
      require(msg.sender == governance, "!governance");
      pairsToLiquidate.push(PairToLiquidate({
          pair: _pair,
          tokenA: _tokenA,
          tokenB: _tokenB,
          router: _router
      }));
    }

    function addTokenToSwap0(address _tokenIn, address _tokenOut, address _router) external {
      require(msg.sender == governance, "!governance");
      tokensToSwap0.push(TokenToSwap({
          tokenIn: _tokenIn,
          tokenOut: _tokenOut,
          router: _router
      }));
    }

    function addTokenToSwap1(address _tokenIn, address _tokenOut, address _router) external {
      require(msg.sender == governance, "!governance");
      tokensToSwap1.push(TokenToSwap({
          tokenIn: _tokenIn,
          tokenOut: _tokenOut,
          router: _router
      }));
    }

    function deleteSsToWithdraw() external {
      require(msg.sender == governance, "!governance");
      delete ssToWithdraw;
    }

    function deletePairsToLiquidate() external {
      require(msg.sender == governance, "!governance");
      delete pairsToLiquidate;
    }

    function deleteTokensToSwap0() external {
      require(msg.sender == governance, "!governance");
      delete tokensToSwap0;
    }

    function deleteTokensToSwap1() external {
      require(msg.sender == governance, "!governance");
      delete tokensToSwap1;
    }
}