// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "TimeLoans::SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
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
    function mod(uint a, uint b) internal pure returns (uint) {
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
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
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

interface IUniswapOracleRouter {
    function quote(address tokenIn, address tokenOut, uint amountIn) external view returns (uint amountOut);
}

contract TimeLoanPair {
    using SafeMath for uint;
    
    /// @notice EIP-20 token name for this token
    string public constant name = "Time Loan Pair LP";

    /// @notice EIP-20 token symbol for this token
    string public symbol;

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;
    
    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0; // Initial 0
    
    mapping (address => mapping (address => uint)) internal allowances;
    mapping (address => uint) internal balances;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint amount);

    /// @notice Uniswap V2 Router used for all swaps and liquidity management
    IUniswapV2Router02 public constant UNI = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    /// @notice Uniswap Oracle Router used for all 24 hour TWAP price metrics
    IUniswapOracleRouter public constant ORACLE = IUniswapOracleRouter(0x0b5A6b318c39b60e7D8462F888e7fbA89f75D02F);
    
    /// @notice The underlying Uniswap Pair used for loan liquidity
    address public pair;
    
    /// @notice The token0 of the Uniswap Pair
    address public token0;
    
    /// @notice The token1 of the Uniswap Pair
    address public token1;
    
   
    /// @notice Deposited event for creditor/LP
    event Deposited(address indexed creditor, address indexed collateral, uint shares, uint credit);
    /// @notice Withdawn event for creditor/LP
    event Withdrew(address indexed creditor, address indexed collateral, uint shares, uint credit);
    
    /// @notice The borrow event for any borrower
    event Borrowed(uint id, address indexed borrower, address indexed collateral, address indexed borrowed, uint creditIn, uint amountOut, uint created, uint expire);
    /// @notice The close loan event when processing expired loans
    event Repaid(uint id, address indexed borrower, address indexed collateral, address indexed borrowed, uint creditIn, uint amountOut, uint created, uint expire);
    /// @notice The close loan event when processing expired loans
    event Closed(uint id, address indexed borrower, address indexed collateral, address indexed borrowed, uint creditIn, uint amountOut, uint created, uint expire);
    
    /// @notice 0.6% initiation fee for all loans
    uint public constant FEE = 600; // 0.6% loan initiation fee
    
    /// @notice 105% liquidity buffer on withdrawing liquidity
    uint public constant BUFFER = 105000; // 105% liquidity buffer
    
    /// @notice 80% loan to value ratio
    uint public constant LTV = 80000; // 80% loan to value ratio
    
    /// @notice base for all % based calculations 
    uint public constant BASE = 100000;
    
    /// @notice the delay for a position to be closed
    uint public constant DELAY = 6600; // ~24 hours till position is closed
    
    
    struct position {
        address owner;
        address collateral;
        address borrowed;
        uint creditIn;
        uint amountOut;
        uint liquidityInUse;
        uint created;
        uint expire;
        bool open;
    }
    
    /// @notice array of all loan positions
    position[] public positions;
    
    /// @notice the tip index of the positions array
    uint public nextIndex;
    
    /// @notice the last index processed by the contract
    uint public processedIndex;
    
    /// @notice mapping of loans assigned to users
    mapping(address => uint[]) public loans;
    
    /// @notice constructor takes a uniswap pair as an argument to set its 2 borrowable assets
    constructor(IUniswapV2Pair _pair) public {
        symbol = string(abi.encodePacked(IUniswapV2Pair(_pair.token0()).symbol(), "-", IUniswapV2Pair(_pair.token1()).symbol()));
        pair = address(_pair);
        token0 = _pair.token0();
        token1 = _pair.token1();
    }
    
    /// @notice total liquidity deposited
    uint public liquidityDeposits;
    /// @notice total liquidity withdrawn
    uint public liquidityWithdrawals;
    /// @notice total liquidity added via addLiquidity
    uint public liquidityAdded;
    /// @notice total liquidity removed via removeLiquidity
    uint public liquidityRemoved;
    /// @notice total liquidity currently in use by pending loans
    uint public liquidityInUse;
    /// @notice total liquidity freed up from closed loans
    uint public liquidityFreed;
    
    /**
     * @notice the current net liquidity positions
     * @return the net liquidity sum
     */
    function liquidityBalance() public view returns (uint) {
        return liquidityDeposits
                .sub(liquidityWithdrawals)
                .add(liquidityAdded)
                .sub(liquidityRemoved)
                .add(liquidityInUse)
                .sub(liquidityFreed);
    }
    
    function _mint(address dst, uint amount) internal {
        // mint the amount
        totalSupply = totalSupply.add(amount);

        // transfer the amount to the recipient
        balances[dst] = balances[dst].add(amount);
        emit Transfer(address(0), dst, amount);
    }
    
    function _burn(address dst, uint amount) internal {
        // burn the amount
        totalSupply = totalSupply.sub(amount, "TimeLoans::_burn: underflow");

        // transfer the amount to the recipient
        balances[dst] = balances[dst].sub(amount, "TimeLoans::_burn: underflow");
        emit Transfer(dst, address(0), amount);
    }
    
    /**
     * @notice withdraw all liquidity from msg.sender shares
     * @return success/failure
     */
    function withdrawAll() external returns (bool) {
        return withdraw(balances[msg.sender]);
    }
    
    /**
     * @notice withdraw `_shares` amount of liquidity for user
     * @param _shares the amount of shares to burn for liquidity
     * @return success/failure
     */
    function withdraw(uint _shares) public returns (bool) {
        uint r = liquidityBalance().mul(_shares).div(totalSupply);
        _burn(msg.sender, _shares);
        
        require(IERC20(pair).balanceOf(address(this)) > r, "TimeLoans::withdraw: insufficient liquidity to withdraw, try depositLiquidity()");
        
        IERC20(pair).transfer(msg.sender, r);
        liquidityWithdrawals = liquidityWithdrawals.add(r);
        emit Withdrew(msg.sender, pair, _shares, r);
        return true;
    }
    
    /**
     * @notice deposit all liquidity from msg.sender
     * @return success/failure
     */
    function depositAll() external returns (bool) {
        return deposit(IERC20(pair).balanceOf(msg.sender));
    }
    
    /**
     * @notice deposit `amount` amount of liquidity for user
     * @param amount the amount of liquidity to add for shares
     * @return success/failure
     */
    function deposit(uint amount) public returns (bool) {
        IERC20(pair).transferFrom(msg.sender, address(this), amount);
        uint _shares = 0;
        if (liquidityBalance() == 0) {
            _shares = amount;
        } else {
            _shares = amount.mul(totalSupply).div(liquidityBalance());
        }
        _mint(msg.sender, _shares);
        liquidityDeposits = liquidityDeposits.add(amount);
        emit Deposited(msg.sender, pair, _shares, amount);
        return true;
    }
    
    /**
     * @notice batch close any pending open loans that have expired
     * @param size the maximum size of batch to execute
     * @return the last index processed
     */
    function closeInBatches(uint size) external returns (uint) {
        uint i = processedIndex;
        for (; i < size; i++) {
            close(i);
        }
        processedIndex = i;
        return processedIndex;
    }
    
    /**
     * @notice iterate through all open loans and close
     * @return the last index processed
     */
    function closeAllOpen() external returns (uint) {
        uint i = processedIndex;
        for (; i < nextIndex; i++) {
            close(i);
        }
        processedIndex = i;
        return processedIndex;
    }
    
    /**
     * @notice close a specific loan based on id
     * @param id the `id` of the given loan to close
     * @return success/failure
     */
    function close(uint id) public returns (bool) {
        position storage _pos = positions[id];
        if (_pos.owner == address(0x0)) {
            return false;
        }
        if (!_pos.open) {
            return false;
        }
        if (_pos.expire < block.number) {
            return false;
        }
        _pos.open = false;
        liquidityInUse = liquidityInUse.sub(_pos.liquidityInUse, "TimeLoans::close: liquidityInUse overflow");
        liquidityFreed = liquidityFreed.add(_pos.liquidityInUse);
        emit Closed(id, _pos.owner, _pos.collateral, _pos.borrowed, _pos.creditIn, _pos.amountOut, _pos.created, _pos.expire);
        return true;
    }
        
    /**
     * @notice returns the available liquidity (including LP tokens) for a given asset
     * @param asset the asset to calculate liquidity for
     * @return the amount of liquidity available
     */
    function liquidityOf(address asset) public view returns (uint) {
        return IERC20(asset).balanceOf(address(this)).
                add(IERC20(asset).balanceOf(pair)
                    .mul(IERC20(pair).balanceOf(address(this)))
                    .div(IERC20(pair).totalSupply()));
    }
    
    /**
     * @notice calculates the amount of liquidity to burn to get the amount of asset
     * @param amount the amount of asset required as output 
     * @return the amount of liquidity to burn
     */
    function calculateLiquidityToBurn(address asset, uint amount) public view returns (uint) {
        return IERC20(pair).balanceOf(address(this))
                .mul(amount)
                .div(IERC20(asset).balanceOf(pair));
    }
    
    /**
     * @notice withdraw liquidity to get the amount of tokens required to borrow
     * @param asset the asset output required
     * @param amount the amount of asset required as output
     */
    function _withdrawLiquidity(address asset, uint amount) internal returns (uint withdrew) {
        withdrew = calculateLiquidityToBurn(asset, amount);
        withdrew = withdrew.mul(BUFFER).div(BASE);
        
        uint _amountAMin = 0;
        uint _amountBMin = 0;
        if (asset == token0) {
            _amountAMin = amount;
        } else if (asset == token1) {
            _amountBMin = amount;
        }
        IERC20(pair).approve(address(UNI), withdrew);
        UNI.removeLiquidity(token0, token1, withdrew, _amountAMin, _amountBMin, address(this), now.add(1800));
        liquidityRemoved = liquidityRemoved.add(withdrew);
    }
    
    /**
     * @notice Provides a quote of how much output can be expected given the inputs
     * @param collateral the asset being used as collateral
     * @param borrow the asset being borrowed
     * @param amount the amount of collateral being provided
     * @return minOut the minimum amount of liquidity to borrow
     */
    function quote(address collateral, address borrow, uint amount) external view returns (uint minOut) {
        uint _received = (amount.sub(amount.mul(FEE).div(BASE))).mul(LTV).div(BASE);
        return ORACLE.quote(collateral, borrow, _received);
    }
    
    /**
     * @notice deposit available liquidity in the system into the Uniswap Pair, manual for now, require keepers in later iterations
     */
    function depositLiquidity() external {
        require(msg.sender == tx.origin, "TimeLoans::depositLiquidity: not an EOA keeper");
        IERC20(token0).approve(address(UNI), IERC20(token0).balanceOf(address(this)));
        IERC20(token1).approve(address(UNI), IERC20(token1).balanceOf(address(this)));
        (,,uint _added) = UNI.addLiquidity(token0, token1, IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), 0, 0, address(this), now.add(1800));
        liquidityAdded = liquidityAdded.add(_added);
    }
    
    /**
     * @notice Returns greater than `outMin` amount of `borrow` based on `amount` of `collateral supplied
     * @param collateral the asset being used as collateral
     * @param borrow the asset being borrowed
     * @param amount the amount of collateral being provided
     * @param outMin the minimum amount of liquidity to borrow
     */
    function loan(address collateral, address borrow, uint amount, uint outMin) external returns (uint) {
        uint _before = IERC20(collateral).balanceOf(address(this));
        IERC20(collateral).transferFrom(msg.sender, address(this), amount);
        uint _after = IERC20(collateral).balanceOf(address(this));
        
        uint _received = _after.sub(_before);
        uint _fee = _received.mul(FEE).div(BASE);
        _received = _received.sub(_fee);
        
        uint _ltv = _received.mul(LTV).div(BASE);
        
        uint _amountOut = ORACLE.quote(collateral, borrow, _ltv);
        require(_amountOut >= outMin, "TimeLoans::loan: slippage");
        require(liquidityOf(borrow) > _amountOut, "TimeLoans::loan: insufficient liquidity");
        
        uint _available = IERC20(borrow).balanceOf(address(this));
        uint _withdrew = 0;
        if (_available < _amountOut) {
            _withdrew = _withdrawLiquidity(borrow, _amountOut.sub(_available));
            liquidityInUse = liquidityInUse.add(_withdrew);
        }
        
        positions.push(position(msg.sender, collateral, borrow, _received, _amountOut, _withdrew, block.number, block.number.add(DELAY), true));
        loans[msg.sender].push(nextIndex);
        
        IERC20(borrow).transfer(msg.sender, _amountOut);
        emit Borrowed(nextIndex, msg.sender, collateral, borrow, _received, _amountOut, block.number, block.number.add(DELAY));
        return nextIndex++;
    }
    
    /**
     * @notice Repay a pending loan with `id` anyone can repay, no owner check
     * @param id the id of the loan to close
     * @return true/false if loan was successfully closed
     */
    function repay(uint id) external returns (bool) {
        position storage _pos = positions[id];
        require(_pos.open, "TimeLoans::repay: position is already closed");
        require(_pos.expire < block.number, "TimeLoans::repay: position already expired");
        IERC20(_pos.borrowed).transferFrom(msg.sender, address(this), _pos.amountOut);
        uint _available = IERC20(_pos.collateral).balanceOf(address(this));
        if (_available < _pos.creditIn) {
            _withdrawLiquidity(_pos.collateral, _pos.creditIn.sub(_available));
        }
        IERC20(_pos.collateral).transfer(msg.sender, _pos.creditIn);
        _pos.open = false;
        positions[id] = _pos;
        emit Repaid(id, _pos.owner, _pos.collateral, _pos.borrowed, _pos.creditIn, _pos.amountOut, _pos.created, _pos.expire);
        return true;
    }
    
    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "TimeLoans::permit: invalid signature");
        require(signatory == owner, "TimeLoans::permit: unauthorized");
        require(now <= deadline, "TimeLoans::permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint amount) public returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint(-1)) {
            uint newAllowance = spenderAllowance.sub(amount, "TimeLoans::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        require(src != address(0), "TimeLoans::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "TimeLoans::_transferTokens: cannot transfer to the zero address");
        
        balances[src] = balances[src].sub(amount, "TimeLoans::_transferTokens: transfer amount exceeds balance");
        balances[dst] = balances[dst].add(amount, "TimeLoans::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

contract TimeLoanPairFactory {
    mapping(address => address) pairs;
    
    function deploy(IUniswapV2Pair _pair) external {
        require(pairs[address(_pair)] == address(0x0), "TimeLoanPairFactory::deploy: pair already created");
        pairs[address(_pair)] = address(new TimeLoanPair(_pair));
    }
}