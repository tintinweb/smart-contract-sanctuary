/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// File: https://github.com/AkredD/TBL-token/blob/main/common/Stackable.sol

// File @openzeppelin/contracts/utils/[email protected]
/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.4;

interface IStackable {
    function stack(address recipient, uint256 amount) external returns (bool);
    
    event Stack(address to, uint256 value);
}
// File: https://github.com/AkredD/TBL-token/blob/main/util/SafeMath.sol

// File @openzeppelin/contracts/access/[email protected]
/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


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
// File: https://github.com/AkredD/TBL-token/blob/main/uniswap/IUniswapV2Factory.sol

/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.4;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}
// File: https://github.com/AkredD/TBL-token/blob/main/uniswap/IUniswapV2Router01.sol

/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.4;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}
// File: https://github.com/AkredD/TBL-token/blob/main/uniswap/IUniswapV2Router02.sol

/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.4;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
// File: https://github.com/AkredD/TBL-token/blob/main/common/Life.sol

/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.4;

interface ILife {
    event SetLifeCompanies(LifeRow[] lifeCompanies);
    
    struct LifeRow {
        address lifeAddress;
        uint part;
    }
    
    function setLifeCompanies(LifeRow[] memory lifeCompanies) external;

    function getLifeCompamies() external view returns (LifeRow[] memory);
}
// File: https://github.com/AkredD/TBL-token/blob/main/util/Context.sol

// File @openzeppelin/contracts/utils/[email protected]
/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


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
// File: https://github.com/AkredD/TBL-token/blob/main/util/Ownable.sol

// File @openzeppelin/contracts/access/[email protected]
/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


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
// File: https://github.com/AkredD/TBL-token/blob/main/common/Fee.sol

/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.4;

interface IFee {
    event SetLiquidityFee(uint liquidityFee);
    event SetBurnFee(uint burnFee);
    event SetLifeFee(uint lifeFee);
    
    function getAllFee() external view returns (uint);
    
    function setLiquidityFee(uint _liquidityFee) external;
    
    function setBurnFee(uint _burnFee) external;
    
    function setLifeFee(uint _lifeFee) external;
}


abstract contract Fee is Ownable, IFee {
    uint public liquidityFee = 0; 
    uint public burnFee = 5 * 10**3; 
    uint public lifeFee = 0; 
    
    function getAllFee() external override view returns (uint) {
        return liquidityFee + burnFee + lifeFee;
    }
    
    function setLiquidityFee(uint _liquidityFee) external onlyOwner override {
        require(checkLimitFee(_liquidityFee, burnFee, lifeFee), "Expire fee limit");
        liquidityFee = _liquidityFee;
        emit SetLiquidityFee(_liquidityFee);
    }
    
    function setBurnFee(uint _burnFee) external onlyOwner override {
        require(checkLimitFee(liquidityFee, _burnFee, lifeFee), "Expire fee limit");
        burnFee = _burnFee;
        emit SetBurnFee(_burnFee);
    }
    
    function setLifeFee(uint _lifeFee) external onlyOwner override {
        require(checkLimitFee(liquidityFee, burnFee, _lifeFee), "Expire fee limit");
        lifeFee = _lifeFee;
        emit SetLifeFee(_lifeFee);
    }
    
    function checkLimitFee(uint _liquidityFee, uint _burnFee, uint _lifeFee) private pure returns (bool) {
        return _liquidityFee + _burnFee + _lifeFee <= 5 * 10**3;
    }
}
// File: https://github.com/AkredD/TBL-token/blob/main/common/ERC20WithComission.sol

/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


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

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity ^0.8.0;



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

abstract contract ERC20 is Context, IERC20, IERC20Metadata {
    
}

pragma solidity ^0.8.4;






abstract contract ERC20WithComission is Context, Fee, IERC20, ILife, IERC20Metadata {
    using SafeMath for uint256;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    uint256 private numTokensSellToAddToLiquidity = 12500 * 10**6 * 10**9;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    

    mapping (address => uint256) internal  _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    LifeRow[] private lifeCompanies;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    
    
    bool inSwapAndLiquify;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
     /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        
        IUniswapV2Router02 _uniswapV2Router =
            IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
    }
    
    receive() external payable {}


    // test show
    function pair() public view returns (address) {
        return uniswapV2Pair;
    }

    function setNumTokenToSell(uint256 numToken) external {
        numTokensSellToAddToLiquidity = numToken;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    
    
    function setLifeCompanies(LifeRow[] memory _lifeCompanies) external override onlyOwner {
        delete lifeCompanies;
        if (_lifeCompanies.length == 0) {
            return;
        }
        
        uint totalPercent = 0;
        for (uint i = 0; i < _lifeCompanies.length; i++) {
            lifeCompanies.push(_lifeCompanies[i]);
            totalPercent += _lifeCompanies[i].part;
        }
        
        require(totalPercent == 100, "Sum of part is not equal to 100 percent");
        emit SetLifeCompanies(lifeCompanies);
    }

    function getLifeCompamies() external view override returns (LifeRow[] memory) {
        return lifeCompanies;
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
    
    function takeLife(address from, uint256 lifeFee) private {
        for (uint i = 0; i < lifeCompanies.length; i++) {
            uint256 lifeFeePart = lifeFee.mul(lifeCompanies[i].part).div(100);
            address lifeAddress = lifeCompanies[i].lifeAddress;
            
            _balances[lifeAddress] += lifeFeePart;
            emit Transfer(from, lifeAddress, lifeFeePart);
        }
    }
    
    function takeLiquidity(address from, uint256 liquidity) private {
        uint256 contractTokenBalance = _balances[address(this)];
        
        if (contractTokenBalance >= numTokensSellToAddToLiquidity) {
            swapAndLiquify(numTokensSellToAddToLiquidity);
        }
        
        _balances[address(this)] = _balances[address(this)] + liquidity;
        emit Transfer(from, address(this), liquidity);
    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _msgSender(),
            block.timestamp
        );
    }
    
    function _getValues(uint256 amount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _resultAmount = amount.mul(10**5 - liquidityFee - lifeFee - burnFee).div(10**5);
        uint256 _liquidityFeeAmount = amount.mul(liquidityFee).div(10**5);
        uint256 _lifeFeeAmount = amount.mul(lifeFee).div(10**5);
        uint256 _burnFeeAmount = amount.mul(burnFee).div(10**5);
        return (
            _resultAmount,
            _liquidityFeeAmount,
            _lifeFeeAmount,
            _burnFeeAmount
        );
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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


        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        uint256 resultAmount = amount;
        
        if (!inSwapAndLiquify &&
            sender != uniswapV2Pair &&
            sender != owner() &&
            recipient != owner()) {
            (uint256 transferAmount, uint256 _liquidityFee, uint256 _lifeFee, uint256 _burnFee) = _getValues(amount);
            resultAmount = transferAmount;
            
            if (_burnFee != 0) {
                _burn(sender, _burnFee);
            }
            
            if (_liquidityFee != 0) {
                takeLiquidity(sender, _liquidityFee);
            }
            
            if (_lifeFee != 0) {
                takeLife(sender, _lifeFee);
            }
        }
        
        _transfer(sender, recipient, amount, resultAmount);
    }
    
    function _transfer(address sender, address recipient, uint256 credit, uint256 debit) internal virtual {
        _balances[sender] -= credit;
        _balances[recipient] += debit;

        emit Transfer(sender, recipient, debit);
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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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
}
// File: TBLCore.sol

/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]




interface ICoreStackable {
    event SetStackableContractAddress(address stackableContractAddress);
    event Stack(address owner, uint256 balance, uint256 stackValue);
    event AddToStackable(address owner, uint blockNumber, uint256 value);
    event RemoveFromStackable(address owner, uint256 value);
    
    struct StackRow { 
      uint blockNumber;
      uint256 amount;
    }
    struct StackTable {
        uint256 balance;
        StackRow[] rows;
    }
    
    function linkStackableToken(address stackableContractAddress) external returns (bool);
    
    function transferToStask(uint256 amount) external returns (bool);
    
    function transferFromStack(uint256 amount) external returns (bool);
    
    function viewStack() external view returns (StackTable memory);
    
    function triggerStack() external returns (bool);
}

interface ITransfereWithLock {
    event CreateTransferWithLock(address sender, address recipient, uint256 amount, uint blockTimestamp, uint blockSeconds);
    event UnlockTransfers(address recipient, uint256 amount);
    
    struct TransferLockRow {
        uint blockTimestamp;
        uint blockSeconds;
        bool received;
        uint256 amount;
    }

    struct CreateTransferLockRow {
        address recipient;
        uint blockMinutes;
        uint256 amount;
    }
    
    struct TransferLockTable {
        TransferLockRow[] rows;
    }

    function transferWithLockDays(address recipient, uint256 amount, uint blockDays) external returns (bool);
    
    function transferWithLockHours(address recipient, uint256 amount, uint blockHours) external returns (bool);

    function transferWithLockMinutes(address recipient, uint256 amount, uint blockMinutes) external returns (bool);

    function massTransferWithLockMinutes(CreateTransferLockRow[] memory massLocks) external returns (bool);
        
    function receiveLockedTransfers() external returns (uint256);
    
    function viewUnreceivedTransfersWithLock() external view returns (TransferLockRow[] memory);
}

pragma solidity ^0.8.4;



contract TBLCore is ERC20WithComission, ICoreStackable, ITransfereWithLock {
    uint256 constant NULL = 0;
   
    mapping (address => StackTable) private stackList;
    mapping (address => TransferLockTable) private lockedTransfers;
    

    IStackable public tblGame;
    
    
    constructor() ERC20WithComission("TinyBlastCore", "TBLC") {
        _mint(msg.sender, 2* 10**9 * 10**18);
    }

    function massTransferWithLockMinutes(CreateTransferLockRow[] memory massLocks) external override returns (bool) {
        for (uint i = 0; i < massLocks.length; ++i) {
            CreateTransferLockRow memory row = massLocks[i];
            transferWithLock(row.recipient, row.amount, row.blockMinutes * 60);
        }
        return true;
    }

    function transferWithLockDays(address recipient, uint256 amount, uint blockDays) external override returns (bool) {
        return transferWithLock(recipient, amount, blockDays * 24 * 60 * 60);
    }
    
    function transferWithLockHours(address recipient, uint256 amount, uint blockHours) external override returns (bool){
         return transferWithLock(recipient, amount, blockHours * 60 * 60);
    }

    function transferWithLockMinutes(address recipient, uint256 amount, uint blockMinutes) external override returns (bool){
         return transferWithLock(recipient, amount, blockMinutes * 60);
    }
    
    function transferWithLock(address recipient, uint256 amount, uint blockSeconds) private returns (bool) {
        address sender = _msgSender();
        uint256 balance = balanceOf(sender);
        require(balance >= amount, "TransferWithLockCore: transfer with lock amount exceeds balance");
        
        _balances[sender] = balance - amount;
        lockedTransfers[recipient].rows.push(TransferLockRow(block.timestamp, blockSeconds, false, amount));
        emit CreateTransferWithLock(sender, recipient, amount, block.timestamp, blockSeconds);
        
        return true;
    }
     
    function receiveLockedTransfers() external override returns (uint256) {
        address sender = _msgSender();
        uint currentTimestamp = block.timestamp;
        uint256 receivedAmount = 0;
        
        for (uint i = 0; i < lockedTransfers[sender].rows.length; i++) {
            TransferLockRow storage row = lockedTransfers[sender].rows[i];
            if (currentTimestamp - row.blockTimestamp > row.blockSeconds && !row.received) {
                row.received = true;
                receivedAmount += row.amount;
            }
        }
        
        require(receivedAmount > 0, "TransferWithLockCore: no transfers with lock can be unlocked");
        _balances[sender] = _balances[sender] + receivedAmount;
        emit UnlockTransfers(sender, receivedAmount);
        
        return 0;   
    }
     
    function viewUnreceivedTransfersWithLock() external view override returns (TransferLockRow[] memory) {
        address sender = _msgSender();
        
        uint unreceivedSize;
        for (uint i = 0; i < lockedTransfers[sender].rows.length; i++) {
            TransferLockRow memory row = lockedTransfers[sender].rows[i];
            if (!row.received) {
                unreceivedSize++;
            }
        }
        
        TransferLockRow[] memory unreceivedRows = new TransferLockRow[](unreceivedSize);

        for (uint i = 0; i < lockedTransfers[sender].rows.length; i++) {
            TransferLockRow memory row = lockedTransfers[sender].rows[i];
            if (!row.received) {
                unreceivedRows[--unreceivedSize] = row;
            }
        }
        
        return unreceivedRows;
    }
    

    function linkStackableToken(address stackableContractAddress) external override onlyOwner returns (bool) {
        tblGame = IStackable(stackableContractAddress);
        emit SetStackableContractAddress(stackableContractAddress);
        return true;
    }
    
    
    function transferToStask(uint256 amount) external override returns (bool) {
        address sender = _msgSender();
        uint256 balance = balanceOf(sender);
        require(balance >= amount, "StackableCore: transfer to stack amount exceeds balance");
        

        stackList[sender].rows.push(StackRow(block.number, amount));
        stackList[sender].balance += amount;

        
        emit AddToStackable(sender, block.number, amount);
        
        _balances[sender] = balance - amount;
        
        return true;
    }
    
    function transferFromStack(uint256 amount) external override returns (bool) {
        address sender = _msgSender();
        uint256 stackBalance = stackList[sender].balance;
        require(stackBalance >= amount, "StackableCore: transfer from stack amount exceeds stack balance");
        
        
        uint256 leftAmount = amount;
        while (leftAmount != 0) {
            StackRow memory lastRow = stackList[sender].rows[stackList[sender].rows.length - 1];
            stackList[sender].rows.pop();
            if (lastRow.amount > leftAmount) {
                lastRow.amount -= leftAmount;
                leftAmount = 0;
                stackList[sender].rows.push(lastRow);
            } else {
                leftAmount -= lastRow.amount;
            }
        }
        stackList[sender].balance -= amount;
        emit RemoveFromStackable(sender, amount);
        
        return true;
    }
    
    function viewStack() external view override returns (StackTable memory) {
        return stackList[_msgSender()];
    }
    
    function triggerStack() external override returns (bool) {
        uint currentBlock = block.number;
        uint256 stackedValue = 0;
        address sender = _msgSender();
        
        require(stackList[sender].balance > 0, "StackableCore: stack balance is 0");
        
        while(stackList[sender].rows.length != 0) {
            StackRow memory lastRow = stackList[sender].rows[stackList[sender].rows.length - 1];
            stackList[sender].rows.pop();
            
            // main stack logic (v0.02)
            stackedValue += (lastRow.amount * ((uint256(currentBlock - lastRow.blockNumber) * 1000000000) / uint256(6 * 60 * 24 * 365))) / 1000000000;
        }
        
        tblGame.stack(sender, stackedValue);
        emit Stack(_msgSender(), stackList[sender].balance, stackedValue);
        
        stackList[sender].rows.push(StackRow(currentBlock, stackList[sender].balance));
        return true;
    }

}