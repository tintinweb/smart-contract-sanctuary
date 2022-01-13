/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

/**
HuskyInu
$HINU

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPinkAntiBot {
    function setTokenOwner(address owner) external;

    function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
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
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
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
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address _owner)
        external
        view
        returns (uint256);

    function withdrawnDividendOf(address _owner)
        external
        view
        returns (uint256);

    function accumulativeDividendOf(address _owner)
        external
        view
        returns (uint256);
}

interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns (uint256);

    function distributeDividends() external payable;

    function withdrawDividend() external;

    event DividendsDistributed(address indexed from, uint256 weiAmount);

    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

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

contract DividendPayingToken is
    ERC20,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
{
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 internal constant magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    receive() external payable {
        distributeDividends();
    }

    function distributeDividends() public payable override {
        require(totalSupply() > 0);

        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (msg.value).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, msg.value);

            totalDividendsDistributed = totalDividendsDistributed.add(
                msg.value
            );
        }
    }

    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user)
        internal
        virtual
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            emit DividendWithdrawn(user, _withdrawableDividend);
            (bool success, ) = user.call{
                value: _withdrawableDividend,
                gas: 3000
            }("");

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return
            magnifiedDividendPerShare
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256Safe() / magnitude;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare
            .mul(value)
            .toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from]
            .add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(
            _magCorrection
        );
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

contract HuskyInu is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;

    IPinkAntiBot public pinkAntiBot;
    bool public pinkAntiBotEnabled = true;

    address public uniswapV2Pair;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    bool private swapping;
    bool private stakingEnabled = false;
    bool public tradingEnabled = false;

    uint256 public sellAmount = 0;
    uint256 public buyAmount = 0;

    uint256 private totalSellFees;
    uint256 private totalBuyFees;

    HuskyInuDividendTracker public dividendTracker;

    address payable public marketingWallet;

    // Max tx, dividend threshold and tax variables
    uint256 public maxWallet;
    uint256 public swapTokensAtAmount;
    uint256 public sellRewardsFee;
    uint256 public sellDeadFees;
    uint256 public sellMarketingFees;
    uint256 public sellLiquidityFee;
    uint256 public buyDeadFees;
    uint256 public buyMarketingFees;
    uint256 public buyLiquidityFee;
    uint256 public buyRewardsFee;

    bool public swapAndLiquifyEnabled = true;

    // gas for processing auto claim dividends 
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;

    /* store addresses of automated market maker pairs. Any transfer to these addresses
    could be subject to a maximum transfer amount */
    mapping(address => bool) public automatedMarketMakerPairs;

    // staking variables
    mapping(address => uint256) public stakingBonus;
    mapping(address => uint256) public stakingUntilDate;
    mapping(uint256 => uint256) public stakingAmounts;

    //for allowing specific address to trade while trading has not been enabled yet 
    mapping(address => bool) private canTransferBeforeTradingIsEnabled;

    // Limit variables for bot protection
    bool public limitsInEffect = true; //boolean used to turn limits on and off
    uint256 private gasPriceLimit = 10 * 1 gwei; 
    mapping(address => uint256) private _holderLastTransferBlock; // for 1 tx per block
    mapping(address => uint256) private _holderLastTransferTimestamp; // for sell cooldown timer
    uint256 public cooldowntimer = 60; //default cooldown 60s

    // LAUNCH Implement access control modifiers

    event EnableAccountStaking(address indexed account, uint256 duration);
    event UpdateStakingAmounts(uint256 duration, uint256 amount);

    event EnableSwapAndLiquify(bool enabled);
    event EnableStaking(bool enabled);

    event SetPreSaleWallet(address wallet);
    event updateMarketingWallet(address wallet);

    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event TradingEnabled();

    event UpdateFees(
        uint256 sellDeadFees,
        uint256 sellMarketingFees,
        uint256 sellLiquidityFee,
        uint256 sellRewardsFee,
        uint256 buyDeadFees,
        uint256 buyMarketingFees,
        uint256 buyLiquidityFee,
        uint256 buyRewardsFee
    );

    event Airdrop(address holder, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(uint256 amount, uint256 opAmount, bool success);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    event UpdatePayoutToken(address token);

    constructor() ERC20("HuskyInu", "HINU") {
        marketingWallet = payable(0xB9f920e71A570b991687C5a0e60d75Cc1D22feAe); 
        address router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

        buyDeadFees = 0;
        sellDeadFees = 0;
        buyMarketingFees = 6;
        sellMarketingFees = 6;
        buyLiquidityFee = 4;
        sellLiquidityFee = 4;
        buyRewardsFee = 4;
        sellRewardsFee = 4;

        totalBuyFees = buyRewardsFee
            .add(buyLiquidityFee)
            .add(buyDeadFees)
            .add(buyMarketingFees);
        totalSellFees = sellRewardsFee
            .add(sellLiquidityFee)
            .add(sellDeadFees)
            .add(sellMarketingFees);

        dividendTracker = new HuskyInuDividendTracker(
            payable(this),
            router,
            0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56,
            "HuskyInuTRACKER",
            "HINUTRACKER"
        );

        uniswapV2Router = IUniswapV2Router02(router);
        pinkAntiBot = IPinkAntiBot(0x8EFDb3b642eb2a20607ffe0A56CFefF6a95Df002);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(DEAD);
        dividendTracker.excludedFromDividends(address(0));
        dividendTracker.excludeFromDividends(router);
        dividendTracker.excludeFromDividends(marketingWallet);
        dividendTracker.excludeFromDividends(owner());

        // exclude from paying fees or having max transaction amount
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(dividendTracker)] = true;
        _isExcludedFromFees[msg.sender] = true;

        uint256 totalTokenSupply = (100_000_000) * (10**18);
        _mint(owner(), totalTokenSupply); // create supply only called here and never again
        maxWallet = totalTokenSupply / 100; // 1%
        swapTokensAtAmount = totalTokenSupply / 25; // 4%;
        canTransferBeforeTradingIsEnabled[owner()] = true;
        canTransferBeforeTradingIsEnabled[address(this)] = true;
        pinkAntiBot.setTokenOwner(msg.sender);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    receive() external payable {}

    function updateStakingAmounts(uint256 duration, uint256 bonus)
        public
        onlyOwner
    {
        require(stakingAmounts[duration] != bonus);
        require(bonus <= 100, "Staking bonus can't exceed 100");
        stakingAmounts[duration] = bonus;
        emit UpdateStakingAmounts(duration, bonus);
    }

    // writeable function to enable trading, can only enable, trading can never be disabled
    function enableTrading() external onlyOwner {
        require(!tradingEnabled);
        tradingEnabled = true;
        emit TradingEnabled();
    }
    // use for pre sale wallet, adds all exclusions to it
    function setPresaleWallet(address wallet) external onlyOwner {
        canTransferBeforeTradingIsEnabled[wallet] = true;
        _isExcludedFromFees[wallet] = true;
        dividendTracker.excludeFromDividends(wallet);
        emit SetPreSaleWallet(wallet);
    }
    // change marketing wallet, just in case something goes wrong with the multi sig wallet
    function setMarketingWallet(address wallet) external onlyOwner {
        _isExcludedFromFees[wallet] = true;
        dividendTracker.excludeFromDividends(wallet);
        marketingWallet = payable(wallet);
        emit updateMarketingWallet(wallet);
    }
    
    // exclude a wallet from fees 
    function setExcludeFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    // exclude from dividends (rewards)
    function setExcludeDividends(address account) public onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    // include in dividends 
    function setIncludeDividends(address account) public onlyOwner {
        dividendTracker.includeFromDividends(account);
        dividendTracker.setBalance(account, getStakingBalance(account));
    }

    //allow a wallet to trade before trading enabled
    function setCanTransferBefore(address wallet, bool enable)
        external
        onlyOwner
    {
        canTransferBeforeTradingIsEnabled[wallet] = enable;
    }

    // turn limits on and off
    function setLimitsInEffect(bool value) external onlyOwner {
        limitsInEffect = value;
    }

    // set cooldown timer, can only be between 0 and 300 seconds (5 mins max)
    function setcooldowntimer(uint256 value) external onlyOwner {
        require(value <= 300, "cooldown timer cannot exceed 5 minutes");
        cooldowntimer = value;
    }

    
    function enableStaking(bool enable) public onlyOwner {
        require(stakingEnabled != enable);
        stakingEnabled = enable;
        emit EnableStaking(enable);
    }

    function stake(uint256 duration) public {
        require(stakingEnabled, "Staking is not enabled");
        require(stakingAmounts[duration] != 0, "Invalid staking duration");
        require(
            stakingUntilDate[_msgSender()] < block.timestamp.add(duration),
            "already staked for a longer duration"
        );
        stakingBonus[_msgSender()] = stakingAmounts[duration];
        stakingUntilDate[_msgSender()] = block.timestamp.add(duration);
        dividendTracker.setBalance(
            _msgSender(),
            getStakingBalance(_msgSender())
        );
        emit EnableAccountStaking(_msgSender(), duration);
    }

    // rewards threshold
    function setSwapTriggerAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount;
    }

    function enableSwapAndLiquify(bool enabled) public onlyOwner {
        require(swapAndLiquifyEnabled != enabled);
        swapAndLiquifyEnabled = enabled;
        emit EnableSwapAndLiquify(enabled);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function setAllowCustomTokens(bool allow) public onlyOwner {
        dividendTracker.setAllowCustomTokens(allow);
    }

    function setAllowAutoReinvest(bool allow) public onlyOwner {
        dividendTracker.setAllowAutoReinvest(allow);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 1000000);
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function transferAdmin(address newOwner) public onlyOwner {
        dividendTracker.excludeFromDividends(newOwner);
        _isExcludedFromFees[newOwner] = true;
        transferOwnership(newOwner);
    }

    function updateFees(
        uint256 deadBuy,
        uint256 deadSell,
        uint256 marketingBuy,
        uint256 marketingSell,
        uint256 liquidityBuy,
        uint256 liquiditySell,
        uint256 RewardsBuy,
        uint256 RewardsSell
    ) public onlyOwner {
        require(liquidityBuy <= 10 && liquiditySell <= 10, "Liquidity fees can't exceed 10%");
        require(deadBuy <= 3 && deadSell <= 3, "Burn fees can't exceed 3%");
        require(RewardsBuy <= 10 && RewardsSell <= 10, "Reward fees cannot exceed 10%");
        require(marketingBuy <= 7 && marketingSell <= 7, "Marketing fees can't exceed 7%");
        buyDeadFees = deadBuy;
        buyMarketingFees = marketingBuy;
        buyLiquidityFee = liquidityBuy;
        buyRewardsFee = RewardsBuy;
        sellDeadFees = deadSell;
        sellMarketingFees = marketingSell;
        sellLiquidityFee = liquiditySell;
        sellRewardsFee = RewardsSell;

        totalSellFees = sellRewardsFee
            .add(sellLiquidityFee)
            .add(sellDeadFees)
            .add(sellMarketingFees);
        totalBuyFees = buyRewardsFee
            .add(buyLiquidityFee)
            .add(buyDeadFees)
            .add(buyMarketingFees);

        emit UpdateFees(
            sellDeadFees,
            sellMarketingFees,
            sellLiquidityFee,
            sellRewardsFee,
            buyDeadFees,
            buyMarketingFees,
            buyLiquidityFee,
            buyRewardsFee
        );
    }

    function getStakingInfo(address account)
        external
        view
        returns (uint256, uint256)
    {
        return (stakingUntilDate[account], stakingBonus[account]);
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function setAutoClaim(bool value) external {
        dividendTracker.setAutoClaim(msg.sender, value);
    }

    function setReinvest(bool value) external {
        dividendTracker.setReinvest(msg.sender, value);
    }

    function setDividendsPaused(bool value) external onlyOwner {
        dividendTracker.setDividendsPaused(value);
    }

    function setEnableAntiBot(bool _enable) external onlyOwner {
        pinkAntiBotEnabled = _enable;
    }

    function isExcludedFromAutoClaim(address account)
        external
        view
        returns (bool)
    {
        return dividendTracker.isExcludedFromAutoClaim(account);
    }

    function isReinvest(address account) external view returns (bool) {
        return dividendTracker.isReinvest(account);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 RewardsFee;
        uint256 deadFees;
        uint256 marketingFees;
        uint256 liquidityFee;
        if (!canTransferBeforeTradingIsEnabled[from]) {
            require(tradingEnabled, "Trading has not yet been enabled");
            if (pinkAntiBotEnabled) {
                pinkAntiBot.onPreTransferCheck(from, to, amount);
            }
        }
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        } else if (
            !swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]
        ) {
            bool isSelling = automatedMarketMakerPairs[to];
            if (!automatedMarketMakerPairs[from] && stakingEnabled) {
                require(
                    stakingUntilDate[from] <= block.timestamp,
                    "Tokens are staked and locked!"
                );
                if (stakingUntilDate[from] != 0) {
                    stakingUntilDate[from] = 0;
                    stakingBonus[from] = 0;
                }
            }

            if (isSelling) {
                RewardsFee = sellRewardsFee;
                deadFees = sellDeadFees;
                marketingFees = sellMarketingFees;
                liquidityFee = sellLiquidityFee;

                if (limitsInEffect) {
                require(
                    block.timestamp >= _holderLastTransferTimestamp[tx.origin] + cooldowntimer,
                    "cooldown period active"
                );
                _holderLastTransferTimestamp[tx.origin] = block.timestamp;
                }
            } else {
                RewardsFee = buyRewardsFee;
                deadFees = buyDeadFees;
                marketingFees = buyMarketingFees;
                liquidityFee = buyLiquidityFee;

                if (limitsInEffect) {
                require(
                    tx.gasprice <= gasPriceLimit,
                    "Gas price exceeds limit."
                );
                require(
                    _holderLastTransferBlock[tx.origin] != block.number,
                    "Too many TX in block"
                );
                _holderLastTransferBlock[tx.origin] = block.number;
            }
            uint256 contractBalanceRecipient = balanceOf(to);
            require(
                contractBalanceRecipient + amount <= maxWallet,
                "Exceeds maximum wallet token amount." );
            }

            uint256 totalFees = RewardsFee
                .add(liquidityFee)
                .add(deadFees)
                .add(marketingFees);

            uint256 contractTokenBalance = balanceOf(address(this));

            bool canSwap = contractTokenBalance >= swapTokensAtAmount;

            if (canSwap && !automatedMarketMakerPairs[from]) {
                swapping = true;

                if (swapAndLiquifyEnabled) {
                    uint256 totalBuySell = buyAmount.add(sellAmount);
                    uint256 swapAmountBought = contractTokenBalance
                        .mul(buyAmount)
                        .div(totalBuySell);
                    uint256 swapAmountSold = contractTokenBalance
                        .mul(sellAmount)
                        .div(totalBuySell);

                    uint256 swapBuyTokens = swapAmountBought
                        .mul(liquidityFee)
                        .div(totalBuyFees);

                    uint256 swapSellTokens = swapAmountSold
                        .mul(liquidityFee)
                        .div(totalSellFees);

                    uint256 swapTokens = swapSellTokens.add(swapBuyTokens);

                    swapAndLiquify(swapTokens);
                }

                uint256 remainingBalance = balanceOf(address(this));
                swapAndSendDividends(remainingBalance);
                buyAmount = 0;
                sellAmount = 0;
                swapping = false;
            }

            uint256 fees = amount.mul(totalFees).div(100);

            amount = amount.sub(fees);

            if (isSelling) {
                sellAmount = sellAmount.add(fees);
            } else {
                buyAmount = buyAmount.add(fees);
            }

            super._transfer(from, address(this), fees);

            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch {}
        }

        super._transfer(from, to, amount);
        dividendTracker.setBalance(from, getStakingBalance(from));
        dividendTracker.setBalance(to, getStakingBalance(to));
    }

    function getStakingBalance(address account) private view returns (uint256) {
        return
            stakingEnabled
                ? balanceOf(account).mul(stakingBonus[account].add(100)).div(
                    100
                )
                : balanceOf(account);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
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
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function updatePayoutToken(address token) public onlyOwner {
        dividendTracker.updatePayoutToken(token);
        emit UpdatePayoutToken(token);
    }

    function getPayoutToken() public view returns (address) {
        return dividendTracker.getPayoutToken();
    }

    function setMinimumTokenBalanceForAutoDividends(uint256 value)
        public
        onlyOwner
    {
        dividendTracker.setMinimumTokenBalanceForAutoDividends(value);
    }

    function setMinimumTokenBalanceForDividends(uint256 value)
        public
        onlyOwner
    {
        dividendTracker.setMinimumTokenBalanceForDividends(value);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function forceSwapAndSendDividends(uint256 tokens) public onlyOwner {
        uint256 totalAmount = buyAmount.add(sellAmount);
        uint256 fromBuy = tokens.mul(buyAmount).div(totalAmount);
        uint256 fromSell = tokens.mul(sellAmount).div(totalAmount);

        swapAndSendDividends(tokens);

        buyAmount = buyAmount.sub(fromBuy);
        sellAmount = sellAmount.sub(fromSell);
    }

    function swapAndSendDividends(uint256 tokens) private {
        if (tokens == 0) {
            return;
        }
        swapTokensForEth(tokens);
        uint256 totalAmount = buyAmount.add(sellAmount);

        uint256 dividendsFromBuy = address(this)
            .balance
            .mul(buyAmount)
            .div(totalAmount)
            .mul(buyRewardsFee)
            .div(buyRewardsFee.add(buyDeadFees + buyMarketingFees));

        uint256 dividendsFromSell = address(this)
            .balance
            .mul(sellAmount)
            .div(totalAmount)
            .mul(sellRewardsFee)
            .div(sellRewardsFee.add(sellDeadFees + sellMarketingFees));

        uint256 dividends = dividendsFromBuy.add(dividendsFromSell);
        bool success = true;
        bool successOp1 = true;
        bool successOp2 = true;
        if (dividends > 0) {
            (success, ) = address(dividendTracker).call{value: dividends}("");
        }
        uint256 _marketDeadTotal = sellMarketingFees.add(sellDeadFees) +
            buyMarketingFees.add(buyDeadFees);

        uint256 feePortions;
        if (_marketDeadTotal > 0) {
            feePortions = address(this).balance.div(_marketDeadTotal);
        }
        uint256 marketingPayout = buyMarketingFees.add(sellMarketingFees) *
            feePortions;
        uint256 deadPayout = buyDeadFees.add(sellDeadFees) * feePortions;

        if (deadPayout > 0) {
            (successOp1, ) = address(DEAD).call{value: deadPayout}("");
        }
        if (marketingPayout > 0) {
            (successOp2, ) = address(marketingWallet).call{
                value: marketingPayout
            }("");
        }

        emit SendDividends(
            dividends,
            deadPayout + marketingPayout,
            success && successOp1 && successOp2
        );
    }

    function multiSend(
        address[] memory _contributors,
        uint256[] memory _balances
    ) public onlyOwner {
        require(
            _contributors.length == _balances.length,
            "Contributors and balances must be same size"
        );
        // Max 200 sends in bulk, uint8 in loop limited to 255
        require(
            _contributors.length <= 200,
            "Contributor list length must be <= 200"
        );
        uint256 sumOfBalances = 0;
        for (uint8 i = 0; i < _balances.length; i++) {
            sumOfBalances = sumOfBalances.add(_balances[i]);
        }
        require(
            balanceOf(msg.sender) >= sumOfBalances,
            "Account balance must be >= sum of balances. "
        );
        require(
            allowance(msg.sender, address(this)) >= sumOfBalances,
            "Contract allowance must be >= sum of balances. "
        );
        address contributor;
        uint256 origBalance;
        for (uint8 j; j < _contributors.length; j++) {
            contributor = _contributors[j];
            require(
                contributor != address(0) &&
                    contributor != 0x000000000000000000000000000000000000dEaD,
                "Cannot airdrop to a dead address"
            );
            origBalance = balanceOf(contributor);
            this.transferFrom(msg.sender, contributor, _balances[j]);
            require(
                balanceOf(contributor) == origBalance + _balances[j],
                "Contributor must recieve full balance of airdrop"
            );
            emit Airdrop(contributor, _balances[j]);
        }
    }

    function airdropToWallets(
        address[] memory airdropWallets,
        uint256[] memory amount
    ) external onlyOwner {
        require(
            airdropWallets.length == amount.length,
            "Arrays must be the same length"
        );
        for (uint256 i = 0; i < airdropWallets.length; i++) {
            address wallet = airdropWallets[i];
            uint256 airdropAmount = amount[i];
            super._transfer(msg.sender, wallet, airdropAmount);
            dividendTracker.setBalance(payable(wallet), balanceOf(wallet));
        }
    }
}

contract HuskyInuDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;
    mapping(address => bool) public excludedFromAutoClaim;
    mapping(address => bool) public autoReinvest;
    address public defaultToken; // BUSD
    bool public allowCustomTokens;
    bool public allowAutoReinvest;
    bool public dividendsPaused = false;

    string private trackerName;
    string private trackerTicker;

    IUniswapV2Router02 public uniswapV2Router;

    HuskyInu public HuskyInuContract;

    mapping(address => uint256) public lastClaimTimes;

    uint256 private minimumTokenBalanceForAutoDividends;
    uint256 private minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event DividendReinvested(
        address indexed acount,
        uint256 value,
        bool indexed automatic
    );
    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );
    event DividendsPaused(bool paused);
    event SetAllowCustomTokens(bool allow);
    event SetAllowAutoReinvest(bool allow);

    constructor(
        address payable mainContract,
        address router,
        address token,
        string memory _name,
        string memory _ticker
    ) DividendPayingToken(_name, _ticker) {
        trackerName = _name;
        trackerTicker = _ticker;
        defaultToken = token;
        HuskyInuContract = HuskyInu(mainContract);
        minimumTokenBalanceForAutoDividends = 10_000_000000000000000000; // 10,000
        minimumTokenBalanceForDividends = minimumTokenBalanceForAutoDividends;

        uniswapV2Router = IUniswapV2Router02(router);
        allowCustomTokens = true;
        allowAutoReinvest = false;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function name() public view virtual override returns (string memory) {
        return trackerName;
    }

    function symbol() public view virtual override returns (string memory) {
        return trackerTicker;
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "HuskyInu_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(
            false,
            "HuskyInu_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main HuskyInu contract."
        );
    }

    function isExcludedFromAutoClaim(address account)
        external
        view
        onlyOwner
        returns (bool)
    {
        return excludedFromAutoClaim[account];
    }

    function isReinvest(address account)
        external
        view
        onlyOwner
        returns (bool)
    {
        return autoReinvest[account];
    }

    function setAllowCustomTokens(bool allow) external onlyOwner {
        require(allowCustomTokens != allow);
        allowCustomTokens = allow;
        emit SetAllowCustomTokens(allow);
    }

    function setAllowAutoReinvest(bool allow) external onlyOwner {
        require(allowAutoReinvest != allow);
        allowAutoReinvest = allow;
        emit SetAllowAutoReinvest(allow);
    }

    function excludeFromDividends(address account) external onlyOwner {
        //require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function includeFromDividends(address account) external onlyOwner {
        excludedFromDividends[account] = false;
    }

    function setAutoClaim(address account, bool value) external onlyOwner {
        excludedFromAutoClaim[account] = value;
    }

    function setReinvest(address account, bool value) external onlyOwner {
        autoReinvest[account] = value;
    }

    function setMinimumTokenBalanceForAutoDividends(uint256 value)
        external
        onlyOwner
    {
        minimumTokenBalanceForAutoDividends = value;
    }

    function setMinimumTokenBalanceForDividends(uint256 value)
        external
        onlyOwner
    {
        minimumTokenBalanceForDividends = value;
    }

    function setDividendsPaused(bool value) external onlyOwner {
        require(dividendsPaused != value);
        dividendsPaused = value;
        emit DividendsPaused(value);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime
        )
    {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(
                    int256(lastProcessedIndex)
                );
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
                    lastProcessedIndex
                    ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
                    : 0;

                iterationsUntilProcessed = index.add(
                    int256(processesUntilEndOfArray)
                );
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];
    }

    function getAccountAtIndex(uint256 index)
        public
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256
        )
    {
        if (index >= tokenHoldersMap.size()) {
            return (
                0x0000000000000000000000000000000000000000,
                -1,
                -1,
                0,
                0,
                0
            );
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function setBalance(address account, uint256 newBalance)
        external
        onlyOwner
    {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance < minimumTokenBalanceForDividends) {
            tokenHoldersMap.remove(account);
            _setBalance(account, 0);

            return;
        }

        _setBalance(account, newBalance);

        if (newBalance >= minimumTokenBalanceForAutoDividends) {
            tokenHoldersMap.set(account, newBalance);
        } else {
            tokenHoldersMap.remove(account);
        }
    }

    function process(uint256 gas)
        public
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0 || dividendsPaused) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= numberOfTokenHolders) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (!excludedFromAutoClaim[account]) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic)
        public
        onlyOwner
        returns (bool)
    {
        if (dividendsPaused) {
            return false;
        }

        bool reinvest = autoReinvest[account];

        if (automatic && reinvest && !allowAutoReinvest) {
            return false;
        }

        uint256 amount = reinvest
            ? _reinvestDividendOfUser(account)
            : _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            if (reinvest) {
                emit DividendReinvested(account, amount, automatic);
            } else {
                emit Claim(account, amount, automatic);
            }
            return true;
        }

        return false;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function updatePayoutToken(address token) public onlyOwner {
        defaultToken = token;
    }

    function getPayoutToken() public view returns (address) {
        return defaultToken;
    }

    function _reinvestDividendOfUser(address account)
        private
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(account);
        if (_withdrawableDividend > 0) {
            bool success;

            withdrawnDividends[account] = withdrawnDividends[account].add(
                _withdrawableDividend
            );

            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = address(HuskyInuContract);

            uint256 prevBalance = HuskyInuContract.balanceOf(address(this));

            // make the swap
            try
                uniswapV2Router
                    .swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: _withdrawableDividend
                }(
                    0, // accept any amount of Tokens
                    path,
                    address(this),
                    block.timestamp
                )
            {
                uint256 received = HuskyInuContract
                    .balanceOf(address(this))
                    .sub(prevBalance);
                if (received > 0) {
                    success = true;
                    HuskyInuContract.transfer(account, received);
                } else {
                    success = false;
                }
            } catch {
                success = false;
            }

            if (!success) {
                withdrawnDividends[account] = withdrawnDividends[account].sub(
                    _withdrawableDividend
                );
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function _withdrawDividendOfUser(address payable user)
        internal
        override
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );

            address tokenAddress = defaultToken;
            bool success;

            if (tokenAddress == address(0)) {
                (success, ) = user.call{
                    value: _withdrawableDividend,
                    gas: 3000
                }("");
            } else {
                address[] memory path = new address[](2);
                path[0] = uniswapV2Router.WETH();
                path[1] = tokenAddress;
                try
                    uniswapV2Router
                        .swapExactETHForTokensSupportingFeeOnTransferTokens{
                        value: _withdrawableDividend
                    }(
                        0, // accept any amount of Tokens
                        path,
                        user,
                        block.timestamp
                    )
                {
                    success = true;
                } catch {
                    success = false;
                }
            }

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
                return 0;
            } else {
                emit DividendWithdrawn(user, _withdrawableDividend);
            }
            return _withdrawableDividend;
        }
        return 0;
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        internal
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        internal
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}