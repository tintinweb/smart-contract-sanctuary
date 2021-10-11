/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]



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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File contracts/interfaces/IBEP20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/interfaces/IDividendDistributor.sol


pragma solidity ^0.8.0;

interface IDividendDistributor {
    function deposit() external payable;
    function process() external;
    function setShare(address shareholder, uint256 amount) external;
}


// File contracts/dividends/DividendDistributor.sol



pragma solidity ^0.8.0;


contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public constant DIVIDENDS_PER_SHARE_ACCURACY_FACTOR = 10 ** 36;

    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor () {
        _token = msg.sender;
    }

    function getCurrentIndex() external onlyToken view returns (uint256) {
        return currentIndex;
    }

    function setShare(address shareholder, uint256 amount) public override onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() public payable override onlyToken {
        uint256 amount = msg.value;
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(DIVIDENDS_PER_SHARE_ACCURACY_FACTOR.mul(amount).div(totalShares));
    }

    function process() public override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0)
            return;

        uint256 iterations = 0;

        while (gasleft() > 100000 && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (getUnpaidEarnings(shareholders[currentIndex]) > 0) {
                distributeDividend(shareholders[currentIndex]);
            }

            currentIndex++;
            iterations++;
        }
    }

    function distributeDividend(address shareholder) private {
        if (shares[shareholder].amount == 0)
            return;

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            (bool success,) = payable(shareholder).call{value: amount, gas: 30000}("");
            require(success, "distributeDividend: Could not transfer funds!");

            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() public {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0)
            return 0;

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded)
            return 0;

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) private view returns (uint256) {
        return share.mul(dividendsPerShare).div(DIVIDENDS_PER_SHARE_ACCURACY_FACTOR);
    }

    function addShareholder(address shareholder) private {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) private {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}


// File contracts/interfaces/IUniswap.sol



pragma solidity ^0.8.0;


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


// File contracts/HuhToken.sol



pragma solidity ^0.8.0;


//      ██╗  ██╗██╗   ██╗██╗  ██╗    ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗
//      ██║  ██║██║   ██║██║  ██║    ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║
//      ███████║██║   ██║███████║       ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║
//      ██╔══██║██║   ██║██╔══██║       ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║
//      ██║  ██║╚██████╔╝██║  ██║       ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║
//      ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝






contract HuhToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    string constant _NAME = "Hah Token 1";
    string constant _SYMBOL = "HAH1";
    uint8 constant _DECIMALS = 9;

    uint256 private constant _MAX = ~uint256(0);
    uint256 private _tTotal = 1 * 10 ** 15 * ( 10** _DECIMALS); // 1 Quadrilion HUH
    uint256 private _rTotal = (_MAX - (_MAX % _tTotal));
    uint256 private _tFeeTotal;


    //  +---------------------------+------+-----+------+------------+--------------+---------+
    //  |                           | BNB% | LP% | HUH% | Marketing% | Layer 2 BNB% | Total % |
    //  +---------------------------+------+-----+------+------------+--------------+---------+
    //  | Normal Buy                | 5    | 1   | 8    | 1          |              | 15      |
    //  | Whitelisted Buy (layer 1) | 10   | 1   | 3    | 1          |              | 15      |
    //  | Whitelisted Buy (layer 2) | 10   | 1   | 1    | 1          | 2            | 15      |
    //  | Normal Sell               | 5    | 1   | 8    | 1          |              | 15      |
    //  | Whitelisted Sell          | 5    | 1   | 3    | 1          |              | 10      |
    //  +---------------------------+------+-----+------+------------+--------------+---------+

    uint8 public liquidityFeeOnBuy = 1;
    uint8 public BNBreflectionFeeOnBuy = 5;
    uint8 public marketingFeeOnBuy = 1;
    uint8 public HuHdistributionFeeOnBuy = 8;

    uint8 public liquidityFeeOnBuyWhiteListed_A = 1;
    uint8 public BNBrewardFor1stPerson_A = 10;
    uint8 public marketingFeeOnBuyWhiteListed_A = 1;
    uint8 public HuHdistributionFeeOnBuyWhiteListed_A = 3;

    uint8 public liquidityFeeOnBuyWhiteListed_B = 1;
    uint8 public BNBrewardFor1stPerson_B = 10;
    uint8 public BNBrewardFor2ndPerson_B = 2;
    uint8 public marketingFeeOnBuyWhiteListed_B = 1;
    uint8 public HuHdistributionFeeOnBuyWhiteListed_B = 1;

    uint8 public liquidityFeeOnSell = 1;
    uint8 public BNBreflectionFeeOnSell = 5;
    uint8 public marketingFeeOnSell = 1;
    uint8 public HuHdistributionFeeOnSell = 8;

    uint8 public liquidityFeeOnSellWhiteListed = 1;
    uint8 public BNBreflectionFeeOnSellWhiteListed = 5;
    uint8 public marketingFeeOnSellWhiteListed = 1;
    uint8 public HuHdistributionFeeOnSellWhiteListed = 3;

    uint256 public launchedAt;
    uint256 public distributorGas = 500000;
    uint256 public minTokenAmountForGetReward = 10000 * (10 ** _DECIMALS);

    address public refCodeRegistrator;  // Address who allowed to register code for users (will be used later)
    address public marketingFeeReceiver;
    address private constant _DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromDividend;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    mapping(address => bytes) public referCodeForUser;
    mapping(bytes => address) public referUserForCode;
    mapping(address => address) public referParent;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isFirstBuy;

    IUniswapV2Router02 public pcsV2Router;
    address public pcsV2Pair;

    IDividendDistributor public distributor;

    address [] public rewardReferParents;
    mapping(address => uint256) public rewardAmount;

    bool public swapEnabled = true;
    uint256 public swapThreshold = 200000 * (10 ** _DECIMALS); // Swap every 200k tokens
    uint256 private _liquidityAccumulated;

    bool private _inSwap;
    modifier swapping() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    event UserWhitelisted(address account, address referee);
    event CodeRegisterred(address account, bytes code);
    event SwapAndLiquify(
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );


    //  -----------------------------
    //  CONSTRUCTOR
    //  -----------------------------


    constructor() {
        IUniswapV2Router02 _pancakeswapV2Router =
            IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // Create a uniswap pair for this new token
        pcsV2Pair = IUniswapV2Factory(_pancakeswapV2Router.factory()).createPair(
            address(this),
            _pancakeswapV2Router.WETH()
        );
        pcsV2Router = _pancakeswapV2Router;
        _allowances[address(this)][address(pcsV2Router)] = _MAX;
        distributor = IDividendDistributor(new DividendDistributor());

        _rOwned[msg.sender] = _rTotal;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromDividend[address(this)] = true;
        _isExcludedFromDividend[pcsV2Pair] = true;
        _isExcludedFromDividend[address(0)] = true;

        marketingFeeReceiver = msg.sender;

        emit Transfer(address(0), msg.sender, _tTotal);
    }

    receive() external payable {}

    fallback() external payable {}


    //  -----------------------------
    //  SETTERS (PROTECTED)
    //  -----------------------------


    function excludeFromReward(address account) public onlyOwner {
        _excludeFromReward(account);
    }

    function includeInReward(address account) external onlyOwner {
        _includeInReward(account);
    }

    function setIsExcludedFromFee(address account, bool flag) external onlyOwner {
        _setIsExcludedFromFee(account, flag);
    }

    function setIsExcludedFromDividend (address account, bool flag) external onlyOwner {
        _setIsExcludedFromDividend(account, flag);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        distributorGas = gas;
    }

    function changeMinAmountForReward(uint256 amount) external onlyOwner {
        minTokenAmountForGetReward = amount * (10 ** _DECIMALS);
    }

    function changeFeesForNormalBuy(
        uint8 _liquidityFeeOnBuy,
        uint8 _BNBreflectionFeeOnBuy,
        uint8 _marketingFeeOnBuy,
        uint8 _HuHdistributionFeeOnBuy
    ) external onlyOwner {
        liquidityFeeOnBuy = _liquidityFeeOnBuy;
        BNBreflectionFeeOnBuy = _BNBreflectionFeeOnBuy;
        marketingFeeOnBuy = _marketingFeeOnBuy;
        HuHdistributionFeeOnBuy = _HuHdistributionFeeOnBuy;
    }

    function changeFeesForWhiteListedBuy_1_RefererOnly(
        uint8 _liquidityFeeOnBuy,
        uint8 _BNBFeeOnBuy,
        uint8 _marketingFeeOnBuy,
        uint8 _HuHdistributionFeeOnBuy
    ) external onlyOwner {
        liquidityFeeOnBuyWhiteListed_A = _liquidityFeeOnBuy;
        BNBrewardFor1stPerson_A = _BNBFeeOnBuy;
        marketingFeeOnBuyWhiteListed_A = _marketingFeeOnBuy;
        HuHdistributionFeeOnBuyWhiteListed_A = _HuHdistributionFeeOnBuy;
    }

    function changeFeesForWhiteListedBuy_2_Referers(
        uint8 _liquidityFeeOnBuy,
        uint8 _BNB1stPersonFeeOnBuy,
        uint8 _BNB2ndPersonFeeOnBuy,
        uint8 _marketingFeeOnBuy,
        uint8 _HuHdistributionFeeOnBuy
    ) external onlyOwner {
        liquidityFeeOnBuyWhiteListed_B = _liquidityFeeOnBuy;
        BNBrewardFor1stPerson_B = _BNB1stPersonFeeOnBuy;
        BNBrewardFor2ndPerson_B = _BNB2ndPersonFeeOnBuy;
        marketingFeeOnBuyWhiteListed_B = _marketingFeeOnBuy;
        HuHdistributionFeeOnBuyWhiteListed_B = _HuHdistributionFeeOnBuy;
    }

    function changeFeesForNormalSell(
        uint8 _liquidityFeeOnSell,
        uint8 _BNBreflectionFeeOnSell,
        uint8 _marketingFeeOnSell,
        uint8 _HuHdistributionFeeOnSell
    ) external onlyOwner {
        liquidityFeeOnSell = _liquidityFeeOnSell;
        BNBreflectionFeeOnSell = _BNBreflectionFeeOnSell;
        marketingFeeOnSell = _marketingFeeOnSell;
        HuHdistributionFeeOnSell = _HuHdistributionFeeOnSell;
    }

    function changeFeesForWhitelistedSell(
        uint8 _liquidityFeeOnSellWhiteListed,
        uint8 _BNBreflectionFeeOnSellWhiteListed,
        uint8 _marketingFeeOnSellWhiteListed,
        uint8 _HuHdistributionFeeOnSellWhiteListed
    ) external onlyOwner {
        liquidityFeeOnSellWhiteListed = _liquidityFeeOnSellWhiteListed;
        BNBreflectionFeeOnSellWhiteListed = _BNBreflectionFeeOnSellWhiteListed;
        marketingFeeOnSellWhiteListed = _marketingFeeOnSellWhiteListed;
        HuHdistributionFeeOnSellWhiteListed = _HuHdistributionFeeOnSellWhiteListed;
    }

    function changeMarketingWallet(address marketingFeeReceiver_) external onlyOwner {
        require(marketingFeeReceiver_ != address(0), "Zero address not allowed!");
        marketingFeeReceiver = marketingFeeReceiver_;
    }

    function setRefCodeRegistrator(address refCodeRegistrator_) external onlyOwner {
        require(refCodeRegistrator_ != address(0), "setRefCodeRegistrator: Zero address not allowed!");
        refCodeRegistrator = refCodeRegistrator_;
    }

    function changeSwapThreshold(uint256 swapThreshold_) external onlyOwner {
        swapThreshold = swapThreshold_ * (10 ** _DECIMALS);
    }

    function registerCodeForOwner(address account, string memory code) external {
        require(msg.sender == refCodeRegistrator || msg.sender == owner(), "Not autorized!");

        bytes memory code_ = bytes(code);
        require(code_.length > 0, "Invalid code!");
        require(referUserForCode[code_] == address(0), "Code already used!");
        require(referCodeForUser[account].length == 0, "User already generated code!");

        _registerCode(account, code_);
        _rewardReferParents();
    }

    function registerCode(string memory code) external {
        bytes memory code_ = bytes(code);
        require(code_.length > 0, "Invalid code!");
        require(referUserForCode[code_] == address(0), "Code already used!");
        require(referCodeForUser[msg.sender].length == 0, "User already generated code!");

        _registerCode(msg.sender, code_);
        if (rewardReferParents.length > 0)
            _rewardReferParents();
    }


    //  -----------------------------
    //  SETTERS
    //  -----------------------------


    function whitelist(string memory refCode) external {
        bytes memory refCode_ = bytes(refCode);
        require(refCode_.length > 0, "Invalid code!");
        require(!isWhitelisted[msg.sender], "Already whitelisted!");
        require(referUserForCode[refCode_] != address(0), "Non used code!");
        require(referUserForCode[refCode_] != msg.sender, "Invalid code, A -> A refer!");
        require(referParent[referUserForCode[refCode_]] != msg.sender, "Invalid code, A -> B -> A refer!");

        _whitelistWithRef(msg.sender, referUserForCode[refCode_]);
        if (rewardReferParents.length > 0)
            _rewardReferParents();
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }


    //  -----------------------------
    //  GETTERS
    //  -----------------------------


    function name() public pure override returns (string memory) {
        return _NAME;
    }

    function symbol() public pure override returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public pure override returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account])
            return _tOwned[account];

        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount)
        public
        view
        returns (uint256)
    {
        uint256 rAmount = tAmount.mul(_getRate());
        return rAmount;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }


    //  -----------------------------
    //  INTERNAL
    //  -----------------------------


    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply)
                return (_rTotal, _tTotal);

            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }

        if (rSupply < _rTotal.div(_tTotal)) {
            return (_rTotal, _tTotal);
        }

        return (rSupply, tSupply);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "BEP20: Transfer amount must be greater than zero");

        if (_inSwap) {
            _basicTransfer(sender, recipient, amount);
            return;
        }

        if (rewardReferParents.length > 0 && sender != pcsV2Pair && recipient != pcsV2Pair) {
            _rewardReferParents();
        }

        if (_shouldSwapBack() && sender != pcsV2Pair && recipient != pcsV2Pair)
            _swapBack();

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            _basicTransfer(sender, recipient, amount);
        } else {
            if (recipient == pcsV2Pair) {
                if (isWhitelisted[sender]) {
                    _whitelistedSell(sender, recipient, amount);
                } else {
                    _normalSell(sender, recipient, amount);
                }
            } else if (sender == pcsV2Pair) {
                if (isWhitelisted[recipient] && isFirstBuy[recipient]) {
                    _whitelistedBuy(sender, recipient, amount);
                    isFirstBuy[recipient] = false;
                } else {
                    _normalBuy(sender, recipient, amount);
                }
            } else {
                _basicTransfer(sender, recipient, amount);
            }
        }

        if (!_isExcludedFromDividend[sender])
            try distributor.setShare(sender, balanceOf(sender)) {} catch {}
        if (!_isExcludedFromDividend[recipient])
            try distributor.setShare(recipient, balanceOf(recipient)) {} catch {}

        if (balanceOf(sender) < minTokenAmountForGetReward && !_isExcluded[sender]) {
            _excludeFromReward(sender);
            _setIsExcludedFromDividend(sender, true);
        }

        if (balanceOf(recipient) >= minTokenAmountForGetReward && _isExcluded[recipient]) {
            _includeInReward(sender);
            _setIsExcludedFromDividend(recipient, false);
        }

        if (launchedAt > 0) {
            uint256 gas = distributorGas;
            require(gasleft() >= gas, "Out of gas, please increase gas limit and retry!");
            try distributor.process{gas:distributorGas}() {} catch {}
        }

        if (launchedAt == 0 && recipient == pcsV2Pair) {
            launchedAt = block.number;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) private {
        uint256 rAmount = reflectionFromToken(amount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(amount);
        if (_isExcluded[recipient]) _tOwned[recipient] = _tOwned[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _normalBuy(address sender, address recipient, uint256 amount) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);
        uint256 rBNBreflectionFee = amount.div(100).mul(BNBreflectionFeeOnBuy).mul(currentRate);
        uint256 rLiquidityFee = amount.div(100).mul(liquidityFeeOnBuy).mul(currentRate);
        uint256 rHuhdistributionFee = amount.div(100).mul(HuHdistributionFeeOnBuy).mul(currentRate);
        uint256 rMarketingFee = amount.div(100).mul(marketingFeeOnBuy).mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rBNBreflectionFee).sub(rLiquidityFee).sub(rHuhdistributionFee).sub(rMarketingFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[address(this)] = _rOwned[address(this)].add(rBNBreflectionFee).add(rLiquidityFee);
        if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(amount);
        if (_isExcluded[recipient]) _tOwned[recipient] = _tOwned[recipient].add(rTransferAmount.div(currentRate));
        if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(rBNBreflectionFee.div(currentRate)).add(rLiquidityFee.div(currentRate));
        _liquidityAccumulated = _liquidityAccumulated.add(rLiquidityFee.div(currentRate));
        _rOwned[marketingFeeReceiver] = _rOwned[marketingFeeReceiver].add(rMarketingFee);
        if (_isExcluded[marketingFeeReceiver]) _tOwned[marketingFeeReceiver] = _tOwned[marketingFeeReceiver].add(rMarketingFee.div(currentRate));

        emit Transfer(sender, recipient, rTransferAmount.div(currentRate));
        emit Transfer(sender, address(this), (rBNBreflectionFee.add(rLiquidityFee)).div(currentRate));
        emit Transfer(sender, marketingFeeReceiver, rMarketingFee.div(currentRate));

        _reflectFee(rHuhdistributionFee, rHuhdistributionFee.div(currentRate));
    }

    function _whitelistedBuy(address sender, address recipient, uint256 amount) private {
        if (referParent[referParent[recipient]] == address(0)) {
            uint256 currentRate = _getRate();
            uint256 rAmount = amount.mul(currentRate);
            uint256 rBNBreward1stPerson = amount.div(100).mul(BNBrewardFor1stPerson_A).mul(currentRate);
            uint256 rLiquidityFee = amount.div(100).mul(liquidityFeeOnBuyWhiteListed_A).mul(currentRate);
            uint256 rHuhdistributionFee = amount.div(100).mul(HuHdistributionFeeOnBuyWhiteListed_A).mul(currentRate);
            uint256 rMarketingFee = amount.div(100).mul(marketingFeeOnBuyWhiteListed_A).mul(currentRate);
            uint256 rTransferAmount = rAmount.sub(rBNBreward1stPerson).sub(rLiquidityFee).sub(rHuhdistributionFee).sub(rMarketingFee);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _rOwned[address(this)] = _rOwned[address(this)].add(rBNBreward1stPerson).add(rLiquidityFee);
            if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(amount);
            if (_isExcluded[recipient]) _tOwned[recipient] = _tOwned[recipient].add(rTransferAmount.div(currentRate));
            if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(rBNBreward1stPerson.div(currentRate)).add(rLiquidityFee.div(currentRate));
            if (rewardAmount[referParent[recipient]] > 0){
                rewardAmount[referParent[recipient]] = rewardAmount[referParent[recipient]].add(rBNBreward1stPerson.div(currentRate));
            } else {
                rewardReferParents.push(referParent[recipient]);
                rewardAmount[referParent[recipient]] = rBNBreward1stPerson.div(currentRate);
            }
            _liquidityAccumulated = _liquidityAccumulated.add(rLiquidityFee.div(currentRate));
            _rOwned[marketingFeeReceiver] = _rOwned[marketingFeeReceiver].add(rMarketingFee);
            if (_isExcluded[marketingFeeReceiver]) _tOwned[marketingFeeReceiver] = _tOwned[marketingFeeReceiver].add(rMarketingFee.div(currentRate));

            emit Transfer(sender, recipient, rTransferAmount.div(currentRate));
            emit Transfer(sender, address(this), (rBNBreward1stPerson.add(rLiquidityFee)).div(currentRate));
            emit Transfer(sender, marketingFeeReceiver, rMarketingFee.div(currentRate));

            _reflectFee(rHuhdistributionFee, rHuhdistributionFee.div(currentRate));
        } else {
            uint256 currentRate = _getRate();
            uint256 rAmount = amount.mul(currentRate);
            uint256 rBNBreward1stPerson = amount.div(100).mul(BNBrewardFor1stPerson_B).mul(currentRate);
            uint256 rBNBreward2ndPerson = amount.div(100).mul(BNBrewardFor2ndPerson_B).mul(currentRate);
            uint256 rLiquidityFee = amount.div(100).mul(liquidityFeeOnBuyWhiteListed_B).mul(currentRate);
            uint256 rHuhdistributionFee = amount.div(100).mul(HuHdistributionFeeOnBuyWhiteListed_B).mul(currentRate);
            uint256 rMarketingFee = amount.div(100).mul(marketingFeeOnBuyWhiteListed_B).mul(currentRate);
            uint256 rTransferAmount = rAmount.sub(rBNBreward1stPerson);
            rTransferAmount = rTransferAmount.sub(rBNBreward2ndPerson).sub(rLiquidityFee).sub(rHuhdistributionFee).sub(rMarketingFee);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _rOwned[address(this)] = _rOwned[address(this)].add(rBNBreward1stPerson).add(rBNBreward2ndPerson).add(rLiquidityFee);
            if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(amount);
            if (_isExcluded[recipient]) _tOwned[recipient] = _tOwned[recipient].add(rTransferAmount.div(currentRate));
            if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(rBNBreward1stPerson.div(currentRate)).add(rBNBreward2ndPerson.div(currentRate)).add(rLiquidityFee.div(currentRate));
            if (rewardAmount[referParent[recipient]] > 0){
                rewardAmount[referParent[recipient]] = rewardAmount[referParent[recipient]].add(rBNBreward1stPerson.div(currentRate));
            } else {
                rewardReferParents.push(referParent[recipient]);
                rewardAmount[referParent[recipient]] = rBNBreward1stPerson.div(currentRate);
            }
            address referParent2ndPerson = referParent[referParent[recipient]];
            if (rewardAmount[referParent2ndPerson] > 0){
                rewardAmount[referParent2ndPerson] = rewardAmount[referParent2ndPerson].add(rBNBreward2ndPerson.div(currentRate));
            } else {
                rewardReferParents.push(referParent2ndPerson);
                rewardAmount[referParent2ndPerson] = rBNBreward2ndPerson.div(currentRate);
            }
            _liquidityAccumulated = _liquidityAccumulated.add(rLiquidityFee.div(currentRate));
            _rOwned[marketingFeeReceiver] = _rOwned[marketingFeeReceiver].add(rMarketingFee);
            if (_isExcluded[marketingFeeReceiver]) _tOwned[marketingFeeReceiver] = _tOwned[marketingFeeReceiver].add(rMarketingFee.div(currentRate));

            emit Transfer(sender, recipient, rTransferAmount.div(currentRate));
            emit Transfer(sender, address(this), (rBNBreward1stPerson.add(rBNBreward2ndPerson).add(rLiquidityFee)).div(currentRate));
            emit Transfer(sender, marketingFeeReceiver, rMarketingFee.div(currentRate));

            _reflectFee(rHuhdistributionFee, rHuhdistributionFee.div(currentRate));
        }
    }

    function _normalSell(address sender, address recipient, uint256 amount) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);
        uint256 rBNBreflectionFee = amount.div(100).mul(BNBreflectionFeeOnSell).mul(currentRate);
        uint256 rLiquidityFee = amount.div(100).mul(liquidityFeeOnSell).mul(currentRate);
        uint256 rHuhdistributionFee = amount.div(100).mul(HuHdistributionFeeOnSell).mul(currentRate);
        uint256 rMarketingFee = amount.div(100).mul(marketingFeeOnSell).mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rBNBreflectionFee).sub(rLiquidityFee).sub(rHuhdistributionFee).sub(rMarketingFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[address(this)] = _rOwned[address(this)].add(rBNBreflectionFee).add(rLiquidityFee);
        if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(amount);
        if (_isExcluded[recipient]) _tOwned[recipient] = _tOwned[recipient].add(rTransferAmount.div(currentRate));
        if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(rBNBreflectionFee.div(currentRate)).add(rLiquidityFee.div(currentRate));
        _liquidityAccumulated = _liquidityAccumulated.add(rLiquidityFee.div(currentRate));
        _rOwned[marketingFeeReceiver] = _rOwned[marketingFeeReceiver].add(rMarketingFee);
        if (_isExcluded[marketingFeeReceiver]) _tOwned[marketingFeeReceiver] = _tOwned[marketingFeeReceiver].add(rMarketingFee.div(currentRate));

        emit Transfer(sender, recipient, rTransferAmount.div(currentRate));
        emit Transfer(sender, address(this), (rBNBreflectionFee.add(rLiquidityFee)).div(currentRate));
        emit Transfer(sender, marketingFeeReceiver, rMarketingFee.div(currentRate));

        _reflectFee(rHuhdistributionFee, rHuhdistributionFee.div(currentRate));
    }

    function _whitelistedSell(address sender, address recipient, uint256 amount) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);
        uint256 rBNBreflectionFee = amount.div(100).mul(BNBreflectionFeeOnSellWhiteListed).mul(currentRate);
        uint256 rLiquidityFee = amount.div(100).mul(liquidityFeeOnSellWhiteListed).mul(currentRate);
        uint256 rHuhdistributionFee = amount.div(100).mul(HuHdistributionFeeOnSellWhiteListed).mul(currentRate);
        uint256 rMarketingFee = amount.div(100).mul(marketingFeeOnSellWhiteListed).mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rBNBreflectionFee).sub(rLiquidityFee).sub(rHuhdistributionFee).sub(rMarketingFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[address(this)] = _rOwned[address(this)].add(rBNBreflectionFee).add(rLiquidityFee);
        if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(amount);
        if (_isExcluded[recipient]) _tOwned[recipient] = _tOwned[recipient].add(rTransferAmount.div(currentRate));
        if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(rBNBreflectionFee.div(currentRate)).add(rLiquidityFee.div(currentRate));
        _liquidityAccumulated = _liquidityAccumulated.add(rLiquidityFee.div(currentRate));
        _rOwned[marketingFeeReceiver] = _rOwned[marketingFeeReceiver].add(rMarketingFee);
        if (_isExcluded[marketingFeeReceiver]) _tOwned[marketingFeeReceiver] = _tOwned[marketingFeeReceiver].add(rMarketingFee.div(currentRate));

        emit Transfer(sender, recipient, rTransferAmount.div(currentRate));
        emit Transfer(sender, address(this), (rBNBreflectionFee.add(rLiquidityFee)).div(currentRate));
        emit Transfer(sender, marketingFeeReceiver, rMarketingFee.div(currentRate));

        _reflectFee(rHuhdistributionFee, rHuhdistributionFee.div(currentRate));
    }

    function _swapAndSend(address recipient, uint256 amount) private swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pcsV2Router.WETH();

        pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            recipient,
            block.timestamp
        );
    }

    function _shouldSwapBack() private view returns (bool) {
        return msg.sender != pcsV2Pair
            && launchedAt > 0
            && !_inSwap
            && swapEnabled
            && balanceOf(address(this)) >= swapThreshold;
    }

    function _swapBack() private swapping {
        uint256 amountToSwap = _liquidityAccumulated.div(2);
        uint256 amountAnotherHalf = _liquidityAccumulated.sub(amountToSwap);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pcsV2Router.WETH();

        uint256 balanceBefore = address(this).balance;

        pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 differenceBnb = address(this).balance.sub(balanceBefore);

        pcsV2Router.addLiquidityETH{value: differenceBnb}(
            address(this),
            amountAnotherHalf,
            0,
            0,
            _DEAD_ADDRESS,
            block.timestamp
        );

        emit SwapAndLiquify(differenceBnb, amountToSwap);

        amountToSwap = balanceOf(address(this));
        pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        _liquidityAccumulated = 0;

        differenceBnb = address(this).balance;
        try distributor.deposit{value: differenceBnb}() {} catch {}
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _excludeFromReward(address account) private {
        // require(account !=  0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude PancakeSwap router.');
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function _includeInReward(address account) private {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[account] = reflectionFromToken(_tOwned[account]);
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _setIsExcludedFromFee(address account, bool flag) private {
        _isExcludedFromFee[account] = flag;
    }

    function _setIsExcludedFromDividend(address account, bool flag) private {
        _isExcludedFromDividend[account] = flag;
    }

    function _whitelistWithRef(address account, address referee) private {
        isFirstBuy[account] = true;
        isWhitelisted[msg.sender] = true;
        referParent[msg.sender] = referee;

        emit UserWhitelisted(account, referee);
    }

    function _registerCode(address account, bytes memory code) private {
        referUserForCode[code] = account;
        referCodeForUser[account] = code;

        emit CodeRegisterred(account, code);
    }
    
    function _rewardReferParents() private {
        if (launchedAt > 0 && rewardReferParents.length > 0){
            while(rewardReferParents.length > 0){
                _swapAndSend(rewardReferParents[rewardReferParents.length - 1], rewardAmount[rewardReferParents[rewardReferParents.length - 1]]);
                rewardAmount[rewardReferParents[rewardReferParents.length - 1]] = 0;
                rewardReferParents.pop();
            }
        }
    }
}