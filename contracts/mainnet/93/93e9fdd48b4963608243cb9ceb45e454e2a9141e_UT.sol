/**
 *Submitted for verification at Etherscan.io on 2020-11-29
*/

pragma solidity ^0.7.0;
//SPDX-License-Identifier: UNLICENSED

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
interface IUNIv2 {
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
    external 
    payable 
    returns (uint amountToken, uint amountETH, uint liquidity);
    
    function WETH() external pure returns (address);

}

interface IUnicrypt {
    event onDeposit(address, uint256, uint256);
    event onWithdraw(address, uint256);
    function depositToken(address token, uint256 amount, uint256 unlock_date) external payable; 
    function withdrawToken(address token, uint256 amount) external;

}

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract UT is IERC20, Context {
    
    using SafeMath for uint;
    IUNIv2 uniswap = IUNIv2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUnicrypt unicrypt = IUnicrypt(0x17e00383A843A9922bCA3B280C0ADE9f8BA48449);
    string public _symbol;
    string public _name;
    uint8 public _decimals;
    uint _totalSupply;
    address payable owner;
    address public pool;
    uint256 public liquidityUnlock;

    
    uint256 lockedLiquidityAmount;
    
     
    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;

   receive () external payable{
       
   }
    

     modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
    constructor() {
        owner = msg.sender; 
        _symbol = "UT";
        _name = "UnicryptTest";
        _decimals = 18;
        _totalSupply = 400 ether;
        _balances[address(this)] = _totalSupply;
        liquidityUnlock = block.timestamp + 2 hours;

        emit Transfer(address(0),address(this), _totalSupply);
        setUniswapPool();
    }
    
    
   
    function lockWithUnicrypt() external onlyOwner {
        IERC20 liquidityTokens = IERC20(pool);
        uint256 liquidityBalance = liquidityTokens.balanceOf(address(this));
        uint256 timeToLuck = block.timestamp + 2 hours;
        liquidityTokens.approve(address(unicrypt), liquidityBalance);

        unicrypt.depositToken{value: 0} (pool, liquidityBalance, timeToLuck);
        lockedLiquidityAmount = lockedLiquidityAmount.add(liquidityBalance);
    }
    
    function withdrawFromUnicrypt(uint256 amount) external onlyOwner{
        unicrypt.withdrawToken(pool, amount);
    }
    
    function setUniswapPool() public {
        require(pool == address(0), "the pool already created");
        pool = uniswapFactory.createPair(address(this), uniswap.WETH());
    }

    
    
    function addLiquidity() external onlyOwner {
        uint256 ETH = address(this).balance;
        this.approve(address(uniswap), balanceOf(address(this)));
        uniswap.addLiquidityETH
        { value: ETH }
        (
            address(this),
            balanceOf(address(this)),
            balanceOf(address(this)),
            ETH,
            address(this),
            block.timestamp + 5 minutes
       );
       
        
   }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
    
     
        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        
    }

    function _approve(address _owner, address spender, uint256 amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner  {
        require(block.timestamp >= liquidityUnlock);
        IERC20(tokenAddress).transfer(owner, tokenAmount);
    }

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
}