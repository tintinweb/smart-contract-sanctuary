/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

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
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

interface IERC20Burnable {
    function burnFrom(address _address, uint256 _amount) external;

    function mint(address _address, uint256 m_amount) external;
}

interface IOracle {
    function consult(uint256 _amountIn)
        external
        view
        returns (uint256 _amountOut);
}

contract Bank is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;

    // STATE VARIABLES
    address public shareOracle;
    address public dollar;
    address public collateral;
    address public share;
    address public gov;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e18;
    uint256 private constant COLLATERAL_RATIO_PRECISION = 1e18;
    uint256 private constant COLLATERAL_RATIO_MAX = 1e18;

    mapping(address => uint256) public last_interaction;
    uint256 public interaction_delay;

    // Number of decimals needed to get to 18
    uint256 private missing_decimals;

    // Number of blocks to wait before being able to collectRedemption()
    uint256 public redemption_delay = 1;

    uint256 public tcr; // 90%
    uint256 public ecr; // 90%

    uint256 public minting_fee; // 0.2%
    uint256 public redemption_fee; // 0.4%

    address public reserve_addr;

    uint256 public constant REDEMPTION_FEE_MAX = 1e16; // 1%
    uint256 public constant MINTING_FEE_MAX = 1e16; // 1%

    bool public mint_paused = false;
    bool public redeem_paused = false;

    uint256 public max_redeem_amount = 1e21; // 1000
    uint256 public constant MIN_REDEEM_LIMIT = 1e21; // 1000
    uint256 public _numDollarToBuyBackmADB = 1e20; // 100

    event Mint(
        uint256 collateral_amount,
        uint256 share_amount,
        uint256 dollar_out
    );
    event Redeem(
        uint256 collateral_out,
        uint256 share_amount,
        uint256 dollar_amount
    );

    IUniswapV2Router02 public immutable uniswapV2Router;

    constructor(
        address _shareOracle,
        address _dollar,
        address _collateral,
        address _share,
        address _gov,
        address _reserve_addr
    ) public {
        shareOracle = _shareOracle;
        dollar = _dollar;
        collateral = _collateral;
        share = _share;
        gov = _gov;
        tcr = 9e17;
        ecr = 9e17;
        minting_fee = 2e15; //0.2%
        redemption_fee = 4e15; //0.4%
        reserve_addr = _reserve_addr;
        missing_decimals = 18 - IERC20Metadata(_collateral).decimals();
        interaction_delay = 1; //block

        //Set Router
        IUniswapV2Router02 _uniswapV2Router =
            IUniswapV2Router02(0xC3E6E90d7C64f96FD2CEc9Abb2e4392387c39432);
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
    }

    function info()
        external
        view
        returns (
            uint256,
            uint256,
            bool,
            bool
        )
    {
        return (
            getCollateralPrice(), // collateral price
            getSharePrice(), // share price
            mint_paused,
            redeem_paused
        );
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function totalCollateralBalance() public view returns (uint256 _collateral_balance) {
        _collateral_balance = IERC20(collateral).balanceOf(address(this));
    }

    function totalShareBalance() public view returns (uint256 _share_balance) {
        _share_balance = IERC20(share).balanceOf(address(this));
    }

    function getCollateralPrice() public view returns (uint256 _price) {
        _price = 10**uint256(IERC20Metadata(collateral).decimals());
    }

    function getSharePrice() public view returns (uint256) {
        return
            IOracle(shareOracle).consult(
                10**uint256(IERC20Metadata(share).decimals())
            );
    }

    function checkAvailability() private view {
        require(
            last_interaction[msg.sender] + interaction_delay <= block.number,
            "< interaction_delay"
        );
    }

    function swapTokensFormADB() private {
        uint256 dollar_balance = IERC20(dollar).balanceOf(address(this));

        if (dollar_balance >= _numDollarToBuyBackmADB) {
            // generate pair path of token -> share
            address[] memory path = new address[](3);
            path[0] = dollar;
            path[1] = gov;
            path[2] = share;

            IERC20(dollar).approve(address(uniswapV2Router), dollar_balance);

            // make the swap
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                dollar_balance,
                0,
                path,
                address(this),
                block.timestamp
            );
        } else {
            return;
        }
    }

    function mint(
        uint256 _collateral_amount,
        uint256 _share_amount,
        uint256 _dollar_out_min
    ) external nonReentrant {
        require(mint_paused == false, "Minting is paused");
        checkAvailability();

        uint256 _price_collateral = getCollateralPrice();
        uint256 _total_dollar_value = 0;
        uint256 _required_share_amount = 0;
        uint256 _share_price = getSharePrice();

        uint256 _collateral_value = getProductOf(
            _collateral_amount.mul((10**missing_decimals)),
            _price_collateral
        );

        _total_dollar_value = getRatioOf(_collateral_value, tcr);

        _required_share_amount = getRatioOf(
            _total_dollar_value.sub(_collateral_value),
            _share_price
        );

        uint256 _fee = getProductOf(_total_dollar_value, minting_fee);
        uint256 _actual_dollar_amount = _total_dollar_value.sub(_fee);

        require(_dollar_out_min <= _actual_dollar_amount, "slippage");

        last_interaction[msg.sender] = block.number;

        if (_collateral_amount > 0) {
            IERC20(collateral).transferFrom(msg.sender, address(this), _collateral_amount);
        }
        if (_required_share_amount > 0) {
            require(_required_share_amount <= _share_amount, "Not enough SHARE input");
            IERC20(share).transferFrom(msg.sender, address(this), _required_share_amount);
        }

        IERC20Burnable(dollar).mint(msg.sender, _actual_dollar_amount);
        if (_fee > 0) {
            uint256 half = _fee.div(2);
            uint256 otherHalf = _fee.sub(half);

            IERC20Burnable(dollar).mint(reserve_addr, otherHalf);
            //Buy back mADB
            IERC20Burnable(dollar).mint(address(this), half);
            swapTokensFormADB();
        }

        emit Mint(
            _collateral_amount,
            _required_share_amount,
            _actual_dollar_amount
        );
    }

    function redeem(
        uint256 _dollar_amount,
        uint256 _share_out_min,
        uint256 _collateral_out_min
    ) external nonReentrant {
        require(redeem_paused == false, "Redeeming is paused");
        require(_dollar_amount <= max_redeem_amount, "Exceeded the max redemption amount");
        checkAvailability();

        uint256 _dollar_totalSupply = IERC20(dollar).totalSupply();
        // Check if collateral balance meets and meet output expectation
        uint256 _total_collateral_balance = totalCollateralBalance();
        uint256 _total_share_balance = totalShareBalance();

        uint256 _dollar_amount_pre_fee = _dollar_amount;
        uint256 _share_return_ratio = getRatioOf(_dollar_amount_pre_fee, _dollar_totalSupply);

        uint256 _collateral_price = getCollateralPrice();
        require(_collateral_price > 0, "Invalid collateral price");
        uint256 _fee = getProductOf(_dollar_amount_pre_fee, redemption_fee);
        uint256 _dollar_amount_post_fee = _dollar_amount_pre_fee.sub(_fee);
        uint256 _collateral_output_amount = 0;
        uint256 _share_output_amount = 0;
        uint256 _share_fee = 0;
        uint256 _collateral_fee = 0;

        if (ecr < COLLATERAL_RATIO_MAX) {
            uint256 _share_output_amount_pre_fee = _total_share_balance.mul(_share_return_ratio);

            _share_fee = getProductOf(
                redemption_fee,
                _share_output_amount_pre_fee
            );

            _share_output_amount = _share_output_amount_pre_fee.sub(_share_fee);
        }

        if (ecr > 0) {
            uint256 _collateral_output_pre_fee_value = (
                getProductOf(_dollar_amount_pre_fee, ecr)
            )
            .div(10**missing_decimals);

            uint256 _collateral_output_value = (
                getProductOf(_dollar_amount_post_fee, ecr)
            )
            .div(10**missing_decimals);

            _collateral_output_amount = getRatioOf(
                _collateral_output_value,
                _collateral_price
            );
            uint256 _collateral_output_pre_fee_amount = getRatioOf(
                _collateral_output_pre_fee_value,
                _collateral_price
            );

            _collateral_fee = getProductOf(
                redemption_fee,
                _collateral_output_pre_fee_amount
            );
        }

        require(_collateral_output_amount <= _total_collateral_balance, "< collateralBalance");
        require(_share_output_amount <= _total_share_balance, "< shareBalance");
        require(_collateral_out_min <= _collateral_output_amount && _share_out_min <= _share_output_amount, "> slippage");

        last_interaction[msg.sender] = block.number;

        if (_collateral_output_amount > 0) {
            IERC20(collateral).transfer(msg.sender, _collateral_output_amount);
        }

        if (_share_output_amount > 0) {
            IERC20(share).transfer(msg.sender, _share_output_amount);
        }

        IERC20Burnable(dollar).burnFrom(msg.sender, _dollar_amount_pre_fee);
        
        if (_share_fee > 0) {
            IERC20(share).transfer(address(this), _share_fee);
        }
        if (_collateral_fee > 0) {
            IERC20(collateral).transfer(reserve_addr, _collateral_fee);
        }

        emit Redeem(
            _collateral_output_amount,
            _share_output_amount,
            _dollar_amount_pre_fee
        );
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setInteractionDelay(uint256 _interaction_delay)
        external
        onlyOwner
    {
        require(_interaction_delay > 0, "delay should be higher than 0");
        interaction_delay = _interaction_delay;
    }

    function toggleMinting() external onlyOwner {
        mint_paused = !mint_paused;
    }

    function toggleRedeeming() external onlyOwner {
        redeem_paused = !redeem_paused;
    }

    function setShareOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Invalid address");
        shareOracle = _oracle;
    }

    function setMaxRedemption(uint256 _max_redemption) public onlyOwner {
        require(_max_redemption >= MIN_REDEEM_LIMIT, "< MIN_REDEMPTION_LIMIT");
        max_redeem_amount = _max_redemption;
    }

    function setRedemptionFee(uint256 _redemption_fee) public onlyOwner {
        require(_redemption_fee <= REDEMPTION_FEE_MAX, "> REDEMPTION_FEE_MAX");
        redemption_fee = _redemption_fee;
    }

    function setMintingFee(uint256 _minting_fee) public onlyOwner {
        require(_minting_fee <= MINTING_FEE_MAX, "> MINTING_FEE_MAX");
        minting_fee = _minting_fee;
    }

    function setReserveAddress(address _reserve_addr) public onlyOwner {
        require(_reserve_addr != address(0), "Invalid address");
        reserve_addr = _reserve_addr;
    }

    function setNumDollarToBuyBackmADB(uint256 numDollarToBuyBackmADB) public onlyOwner {
        _numDollarToBuyBackmADB = numDollarToBuyBackmADB;
    }

    function setTCRandECR(uint256 _tcr, uint256 _ecr) public onlyOwner {
        require(_tcr <= COLLATERAL_RATIO_MAX, "> COLLATERAL_RATIO_MAX");
        require(_ecr <= COLLATERAL_RATIO_MAX, "> COLLATERAL_RATIO_MAX");

        tcr = _tcr;
        ecr = _ecr;
    }

    function getProductOf(uint256 _amount, uint256 _multiplier)
        public
        pure
        returns (uint256)
    {
        return (_amount.mul(_multiplier)).div(PRICE_PRECISION);
    }

    function getRatioOf(uint256 _amount, uint256 _divider)
        public
        pure
        returns (uint256)
    {
        return
            (
                ((_amount.mul(PRICE_PRECISION)).div(_divider)).mul(
                    PRICE_PRECISION
                )
            )
                .div(PRICE_PRECISION);
    }
}