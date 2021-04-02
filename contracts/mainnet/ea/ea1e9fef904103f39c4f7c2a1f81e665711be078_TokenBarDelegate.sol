/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// File: contracts/interface/TokenBarInterfaces.sol

pragma solidity 0.6.12;

contract TokenBarAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;
    /**
     * @notice Governance for this contract which has the right to adjust the parameters of TokenBar
     */
    address public governance;

    /**
     * @notice Active brains of TokenBar
     */
    address public implementation;
}

contract xSHDStorage {
    string public name = "ShardingBar";
    string public symbol = "xSHD";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
}

contract ITokenBarStorge is TokenBarAdminStorage {
    //lock period :60*60*24*7
    uint256 public lockPeriod = 604800;
    address public SHDToken;
    mapping(address => mapping(address => address)) public routerMap;
    address public marketRegulator;
    address public weth;
    mapping(address => uint256) public lockDeadline;
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol



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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol



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

// File: contracts/xSHDToken.sol

pragma solidity 0.6.12;



contract xSHDToken is xSHDStorage {
    using SafeMath for uint256;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }
}

// File: contracts/interface/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: contracts/interface/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {}

// File: contracts/interface/IMarketRegulator.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IMarketRegulator {
    function IsInWhiteList(address wantToken)
        external
        view
        returns (bool inTheList);

    function IsInBlackList(uint256 _shardPoolId)
        external
        view
        returns (bool inTheList);

    function getWantTokenWhiteList()
        external
        view
        returns (whiteListToken[] memory _wantTokenWhiteList);

    struct whiteListToken {
        address token;
        string symbol;
    }
}

// File: contracts/TokenBarDelegate.sol

pragma solidity 0.6.12;







contract TokenBarDelegate is ITokenBarStorge, xSHDToken {
    using SafeMath for uint256;

    event Deposit(address user, uint256 SHDAmountIn, uint256 xSHDAmountOut);

    event Withdraw(
        address user,
        uint256 xSHDAmountIn,
        uint256 SHDAmountOut,
        bool isUpdateSHDInBar
    );

    constructor() public {}

    function initialize(
        address _SHDToken,
        address _marketRegulator,
        address _weth
    ) public {
        require(weth == address(0), "already initialize");
        require(msg.sender == admin, "unauthorized");
        SHDToken = _SHDToken;
        marketRegulator = _marketRegulator;
        weth = _weth;
    }

    //user operation
    //enter the bar. Get the xSHDToken
    function deposit(uint256 _SHDAmountIn) public {
        require(_SHDAmountIn > 0, "Insufficient SHDToken");

        uint256 totalSHD = IERC20(SHDToken).balanceOf(address(this));
        uint256 totalShares = totalSupply;

        lockDeadline[msg.sender] = now.add(lockPeriod);

        uint256 xSHDAmountOut;
        if (totalShares == 0 || totalSHD == 0) {
            xSHDAmountOut = _SHDAmountIn;
            _mint(msg.sender, _SHDAmountIn);
        } else {
            xSHDAmountOut = _SHDAmountIn.mul(totalShares).div(totalSHD);
            _mint(msg.sender, xSHDAmountOut);
        }
        IERC20(SHDToken).transferFrom(msg.sender, address(this), _SHDAmountIn);
        emit Deposit(msg.sender, _SHDAmountIn, xSHDAmountOut);
    }

    // Leave the bar. Claim back your SHDTokens.
    function withdraw(uint256 _xSHDAmountIn, bool _isUpdateSHDInBar) public {
        require(_xSHDAmountIn > 0, "Insufficient xSHDToken");
        if (_isUpdateSHDInBar) {
            swapAllForSHD();
        }
        uint256 timeForWithdraw = lockDeadline[msg.sender];
        require(now > timeForWithdraw, "still locked");
        uint256 totalShares = totalSupply;
        uint256 SHDBalance = IERC20(SHDToken).balanceOf(address(this));
        uint256 SHDAmountOut = _xSHDAmountIn.mul(SHDBalance).div(totalShares);
        _burn(msg.sender, _xSHDAmountIn);
        IERC20(SHDToken).transfer(msg.sender, SHDAmountOut);
        emit Withdraw(
            msg.sender,
            _xSHDAmountIn,
            SHDAmountOut,
            _isUpdateSHDInBar
        );
    }

    function swapAllForSHD() public {
        IMarketRegulator.whiteListToken[] memory wantTokenWhiteList =
            IMarketRegulator(marketRegulator).getWantTokenWhiteList();
        for (uint256 i = 0; i < wantTokenWhiteList.length; i++) {
            address wantToken = wantTokenWhiteList[i].token;
            if (wantToken != weth) {
                swap(wantToken, weth);
            }
        }
        swap(weth, SHDToken);
    }

    function swapExactTokenForSHD(address wantToken) public {
        if (wantToken != weth) {
            swap(wantToken, weth);
        }
        swap(weth, SHDToken);
    }

    function swap(address from, address to) internal {
        uint256 balance = IERC20(from).balanceOf(address(this));
        if (balance > 0) {
            address router = routerMap[from][to];
            require(router != address(0), "router hasn't been set");
            address[] memory path = new address[](2);
            path[0] = from;
            path[1] = to;
            IERC20(from).approve(router, balance);
            IUniswapV2Router02(router).swapExactTokensForTokens(
                balance,
                0,
                path,
                address(this),
                now.add(60)
            );
        }
    }

    //admin operation
    function setRouter(
        address fromToken,
        address ToToken,
        address router
    ) public {
        require(msg.sender == admin, "unauthorized");
        routerMap[fromToken][ToToken] = router;
    }

    function setMarketRegulator(address _marketRegulator) public {
        require(msg.sender == admin, "unauthorized");
        marketRegulator = _marketRegulator;
    }

    //goverance operation
    function setLockPeriod(uint256 _lockPeriod) public {
        require(msg.sender == governance, "unauthorized");
        lockPeriod = _lockPeriod;
    }

    //view function
    function getxSHDAmountOut(uint256 SHDAmountIn)
        public
        view
        returns (uint256 xSHDAmountOut)
    {
        uint256 totalSHD = IERC20(SHDToken).balanceOf(address(this));
        uint256 totalShares = totalSupply;
        if (totalShares == 0 || totalSHD == 0) {
            xSHDAmountOut = SHDAmountIn;
        } else {
            xSHDAmountOut = SHDAmountIn.mul(totalShares).div(totalSHD);
        }
    }

    function getSHDAmountOut(uint256 xSHDAmountIn)
        public
        view
        returns (uint256 SHDAmountOut)
    {
        uint256 totalShares = totalSupply;
        uint256 SHDBalance = IERC20(SHDToken).balanceOf(address(this));
        SHDAmountOut = xSHDAmountIn.mul(SHDBalance).div(totalShares);
    }

    function getSHDAmountOutAfterSwap(uint256 xSHDAmountIn)
        public
        view
        returns (uint256 SHDAmountOut)
    {
        IMarketRegulator.whiteListToken[] memory wantTokenWhiteList =
            IMarketRegulator(marketRegulator).getWantTokenWhiteList();

        uint256 balanceOfWeth = IERC20(weth).balanceOf(address(this));

        for (uint256 i = 0; i < wantTokenWhiteList.length; i++) {
            address wantToken = wantTokenWhiteList[i].token;
            if (wantToken != weth) {
                uint256 balance = IERC20(wantToken).balanceOf(address(this));
                uint256 wethAmountOut = getSwapAmount(wantToken, weth, balance);
                balanceOfWeth = balanceOfWeth.add(wethAmountOut);
            }
        }

        uint256 SHDBalance = IERC20(SHDToken).balanceOf(address(this));
        uint256 SHDTokenAmountOut =
            getSwapAmount(weth, SHDToken, balanceOfWeth);
        SHDBalance = SHDBalance.add(SHDTokenAmountOut);

        uint256 totalShares = totalSupply;
        SHDAmountOut = xSHDAmountIn.mul(SHDBalance).div(totalShares);
    }

    function getSwapAmount(
        address from,
        address to,
        uint256 fromAmountIn
    ) internal view returns (uint256 amountOut) {
        if (fromAmountIn > 0) {
            address router = routerMap[from][to];
            require(router != address(0), "router hasn't been set");
            address[] memory path = new address[](2);
            path[0] = from;
            path[1] = to;
            uint256[] memory amounts =
                IUniswapV2Router02(router).getAmountsOut(fromAmountIn, path);
            amountOut = amounts[1];
        }
    }
}