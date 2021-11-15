// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor () {
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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity 0.8.0;
// SPDX-License-Identifier: GPL - author: @DrGorilla_md (Tg/Twtr)

/// @author DrGorilla_md
/// @title $REUM - presale and autoliq contract.
/// @notice 3 differents quotas -> whitelisted, "private" (ie any non-whitelisted address) and "reserved" for public listing
/// whitelisted and presale are independent quotas.
/// When presale is over (owner is calling concludeAndAddLiquidity), the liquidity quota is
/// paired with appropriate amount of BNB (if not enough BNB, less token then) -> public price is the constraint
/// + a fixed part is transered to the main token contract as initial reward pool.
/// Claim() is then possible (AFTER the initial liquidity is added).
/// This contract will then remains at least a week, for late claims (it can be then, manually, destruct -> token left
/// are transfered to the dev multisig.

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Reum_presale is Ownable {

  mapping (address => uint256) public amountBought;
  mapping (address => bool) public whiteListed;

  enum status {
    beforeSale,
    ongoingSale,
    postSale
  }

  status public sale_status;

  uint256 public presale_end_ts;
  uint256 public presale_token_per_BNB = 630;  //pre-sale price (630B/1BNB) AKA (630*10**9*10**9)/10**18
  uint256 public whitelist_token_per_BNB = 665;
  uint256 public public_token_per_BNB = 595; //public pancake listing

  uint256 public total_bought;
  uint256 public total_claimed;

  struct track { //use to be uint128, but totalSupply's are growing exponentially...
    uint256 whiteQuota;      //16625 * 10**10 * 10**9; 166.25T whitelist
    uint256 presaleQuota;    //189 * 10**12 * 10**9; 189 presale
    uint256 liquidityQuota;  //229075 * 10**9 * 10**9;  229.075 public
    uint256 sold_in_private; //track the amount bought by non-whitelisted
    uint256 sold_in_whitelist;
  }

  track public Quotas = track(16625 * 10**10 * 10**9, 189 * 10**12 * 10**9, 229075 * 10**9 * 10**9, 0, 0);
  
  IERC20 public token_interface;
  IUniswapV2Router02 router;
  IUniswapV2Pair pair;

  event Buy(address, uint256, uint256);
  event LiquidityTransferred(uint256, uint256);
  event Claimable(address, uint256, uint256);

  modifier beforeSale() {
    require(sale_status == status.beforeSale, "Sale: already started");
    _;
  }

  modifier ongoingSale() {
    require(sale_status == status.ongoingSale, "Sale: already started");
    _;
  }

  modifier postSale() {
    require(sale_status == status.postSale, "Sale: not ended yet");
    _;
  }
  
  /// @dev this contract should be excluded in the main contract
  constructor(address _router, address _token_address) {
      router = IUniswapV2Router02(_router);
      require(router.WETH() != address(0), 'Router error');

      IUniswapV2Factory factory = IUniswapV2Factory(router.factory());

      address pair_adr = factory.getPair(router.WETH(), _token_address);
      pair = IUniswapV2Pair(pair_adr);
      require(pair_adr != address(0), 'Pair error');

      token_interface = IERC20(_token_address);
      sale_status = status.beforeSale;
  }

// -- before sale --

  /// @dev retain capacity to whitelist during the sale (ie too much "zombies" not coming)
  function addWhitelist(address[] calldata _adr) external onlyOwner {
    for(uint256 i=0; i< _adr.length; i++) {
      if(whiteListed[_adr[i]] == false) {
        whiteListed[_adr[i]] = true;
      }
    }
  }

  function isWhitelisted() external view returns (bool){
    return whiteListed[msg.sender];
  }

  function saleStatus() external view returns(uint256) {
    return uint256(sale_status);
  }

// -- Presale launch --

  function startSale() external beforeSale onlyOwner {
    require(token_interface.balanceOf(address(this)) >= Quotas.whiteQuota + Quotas.presaleQuota + Quotas.liquidityQuota, "Presale: not enough token");
    sale_status = status.ongoingSale;
  }

// -- Presale flow --

  /// @dev will revert when quotas are emptied
  function tokenLeftForPrivateSale() public view returns (uint256) {
    require(Quotas.presaleQuota >= Quotas.sold_in_private, "Private sale: No more token to sell");
    unchecked {
      return Quotas.presaleQuota - Quotas.sold_in_private;
    }
  }

  function tokenLeftForWhitelistSale() public view returns (uint256) {
    require(Quotas.whiteQuota >= Quotas.sold_in_whitelist, "Whitelist: No more token to sell");
    unchecked {
      return Quotas.whiteQuota - Quotas.sold_in_whitelist;
    }
  }


  function buy() external payable ongoingSale {
    require(msg.value >= 2 * 10**17, "Sale: Under min amount"); // <0.2 BNB
    require(amountBought[msg.sender] + msg.value <= 2*10**18, "Sale: above max amount"); // >2bnb

    bool whiteListed_adr = whiteListed[msg.sender];
    uint256 amountToken;

    if(whiteListed_adr) {
      amountToken = msg.value * whitelist_token_per_BNB;
      require(amountToken <= tokenLeftForWhitelistSale(), "Sale: No token left in whitelist");
      Quotas.sold_in_whitelist += amountToken;
    }
    else {
      amountToken = msg.value * presale_token_per_BNB;
      require(amountToken <= tokenLeftForPrivateSale(), "Sale: No token left in presale");
      Quotas.sold_in_private += amountToken;
    }

    amountBought[msg.sender] = amountBought[msg.sender] + msg.value;
    total_bought += amountToken;
    emit Claimable(msg.sender, msg.value, amountToken);
  }

  function allowanceLeftInBNB() external view returns (uint256) {
    return 2*10**18 - amountBought[msg.sender];
  }
  
  function amountTokenBought() external view returns (uint256) {
    uint256 amountToken = whiteListed[msg.sender] ? whitelist_token_per_BNB * amountBought[msg.sender] : presale_token_per_BNB * amountBought[msg.sender];
    return amountToken;
  }


// -- post sale --

  function claim() external postSale {
    require(amountBought[msg.sender] > 0, "0 tokens to claim");
    uint256 amountToken = whiteListed[msg.sender] ? whitelist_token_per_BNB * amountBought[msg.sender] : presale_token_per_BNB * amountBought[msg.sender];
    amountBought[msg.sender] = 0;
    total_claimed += amountToken;
    token_interface.transfer(msg.sender, amountToken);
  }

  /// @dev convert BNB received and token left in pool liquidity. LP send to owner.
  ///     Uni Router handles both scenario : existing and non-existing pair
  /// not in postSale scope to avoid having claim and third-party liq before calling it
  /// @param portion_for_reward_in_percent % of BNB transfered to the token contract as initial reward pool
  /// @param emergency_slippage modify the token amount desired in addLiquidity
  /// @param correcting_ratio bool to trigger the "anti-pool-spam" mechanism (rebalance and atomically sync)
  /// @param left_over_address dest address for leftover BNB (left over token are only withdrawable after a week, for late claimers)
  function concludeAndAddLiquidity(uint256 portion_for_reward_in_percent, uint256 emergency_slippage, bool correcting_ratio, address left_over_address) external onlyOwner {

    address token = payable(address(token_interface));
    uint256 to_transfer = address(this).balance * portion_for_reward_in_percent / 100;
    (bool success,) = token.call{value: to_transfer}(new bytes(0));
    require(success, 'TransferHelper: ETH_TRANSFER_FAILED');

    if(address(pair).balance > 0 && correcting_ratio) { // pair contract spammed with BNB ?
      uint256 to_add = address(pair).balance * public_token_per_BNB;
      token_interface.transfer(address(pair), to_add);
      pair.sync();
    }

    uint256 balance_BNB = address(this).balance;
    uint256 balance_token = token_interface.balanceOf(address(this));

    if(balance_token > Quotas.liquidityQuota) balance_token = Quotas.liquidityQuota; //public capped at Quotas.liquidityQuota

    if(balance_token / balance_BNB >= public_token_per_BNB) { // too much token for BNB
        balance_token = public_token_per_BNB * balance_BNB;
      }
      else { // too much BNB for token left
        balance_BNB = balance_token / public_token_per_BNB;
      }
    
    token_interface.approve(address(router), balance_token);
    router.addLiquidityETH{value: balance_BNB}(
        address(token_interface),
        balance_token,
        balance_token - (balance_token * emergency_slippage / 100),
        balance_BNB,
        address(0x000000000000000000000000000000000000dEaD), //liquidity tokens are burned
        block.timestamp
    );

    sale_status = status.postSale;
    presale_end_ts = block.timestamp;
    
    //safeTransfer
    address to = payable(left_over_address);  //multisig (should be 0)
    (bool success2,) = to.call{value: address(this).balance}(new bytes(0));
    require(success2, 'TransferHelper: ETH_TRANSFER_FAILED');

    emit LiquidityTransferred(balance_BNB, balance_token);
      
  }

/// @dev wait min 1 week after presale ending, for "late claimers", before destroying the
/// contract and emptying it.
  function finalClosure(address leftover_dest) external onlyOwner {
    require(block.timestamp >= presale_end_ts + 604800, "finalClosure: grace period");

    if(token_interface.balanceOf(address(this)) != 0) {
      token_interface.transfer(leftover_dest, token_interface.balanceOf(address(this)));
    }

    selfdestruct(payable(leftover_dest));
  }

  fallback () external payable {
    revert("Don't you dare");
  }

}

