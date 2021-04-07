/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity ^0.7.0;
//SPDX-License-Identifier: UNLICENSED

// Telegram https://t.me/FirestarterNFT

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

contract FIRE is IERC20, Context {
    
    using SafeMath for uint;
    IUNIv2 constant uniswap =  IUNIv2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory constant uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUnicrypt constant unicrypt = IUnicrypt(0x5f5410d4993bFf5b72d0E2588D76903f3d7e1f8C);
    string public _symbol;
    string public _name;
    uint8 public _decimals;
    uint _totalSupply;
    
    uint public tokensBought;
    bool public isStopped = false;
    bool public teamClaimed = false;
    bool public moonMissionStarted = false;

    uint constant tokensForUniswap = 1500 ether;
    uint constant teamTokens = 375 ether;
    uint constant tokensForStakingAndMarketining = 775 ether;
    uint constant tokensForNftVault = 1500 ether;
    uint constant tokensForPartnerships = 350 ether;
    address vault;
    
    address payable owner;
    address payable constant owner2 = 0x7781b7780B8E02b89994fDa7034EF659d4C292BA;
    address payable constant owner3 = 0x4ebbE7c22CD00f6411F0994161A5d4539CaF081B;
    address payable constant multisig = 0x251CfD87CE1AA5A07E7bfcA004895E965B47eCBD;
    
    address public pool;
    
    uint256 public liquidityUnlock;
    uint256 constant StakingAndMarketiningWithdrawDate = 1608422400; // 12/20/2020 @ 12:00am (UTC)
    
    uint256 public ethSent;
    uint256 constant tokensPerETH = 10;
    bool transferPaused;
    bool presaleStarted; 
    uint256 public lockedLiquidityAmount;
    
    // Will prevent burning when calling addLiquidity()
    bool public burning;
    

    
    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;
    mapping(address => uint) ethSpent;

     modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
    constructor(address _vault) {
        vault = _vault;
        owner = msg.sender; 
        _symbol = "$FIRE";
        _name = "FireStarter";
        _decimals = 18;
        _totalSupply = 7500 ether;
        uint tokensForContract = _totalSupply.sub(tokensForNftVault).sub(tokensForPartnerships); 
        _balances[address(this)] = tokensForContract;
        _balances[vault] = tokensForNftVault;
        _balances[multisig] = tokensForPartnerships;
        transferPaused = true;
        liquidityUnlock = block.timestamp.add(1 hours);
        
        emit Transfer(address(0), address(this), tokensForContract);
        emit Transfer(address(0), vault, tokensForNftVault);
        emit Transfer(address(0), multisig, tokensForPartnerships);
        setUniswapPool();
    }
    
    
    receive() external payable {
        
        buyTokens();
    }
    
    
    function lockWithUnicrypt() external onlyOwner {
        IERC20 liquidityTokens = IERC20(pool);
        uint256 liquidityBalance = liquidityTokens.balanceOf(address(this));
        uint256 timeToLuck = liquidityUnlock;
        liquidityTokens.approve(address(unicrypt), liquidityBalance);

        unicrypt.depositToken{value: 0} (pool, liquidityBalance, timeToLuck);
        lockedLiquidityAmount = lockedLiquidityAmount.add(liquidityBalance);
    }
    
    function withdrawFromUnicrypt(uint256 amount) external onlyOwner{
        unicrypt.withdrawToken(pool, amount);
    }
    
    function setUniswapPool() public {
        require(pool == address(0), "The pool is already created");
        pool = uniswapFactory.createPair(address(this), uniswap.WETH());
    }
    
    function claimTeamFeeAndAddLiquidity() external onlyOwner {
       require(!teamClaimed);
       uint256 amountETH = address(this).balance.mul(5).div(100); // 5% for the each of the owners 
       uint256 forMultisig = address(this).balance.mul(35).div(100); // 35%
       owner.transfer(amountETH);
       owner2.transfer(amountETH);
       owner3.transfer(amountETH);
       multisig.transfer(forMultisig);
       teamClaimed = true;
       
       addLiquidity();
    }
    
    function startPresale() external onlyOwner { 
        presaleStarted = true;
    }
    function buyTokens() public payable {
        require(presaleStarted == true, "Preale didn't start yet");
        require(!isStopped);
        require(msg.value >= 0.01 ether, "You sent less than 1 ETH");
        require(msg.value <= 10 ether, "You sent more than 10 ETH");
        require(ethSent < 300 ether, "Hard cap reached");
        require(ethSpent[msg.sender].add(msg.value) <= 10 ether, "You can't buy more");
        uint256 tokens = msg.value.mul(tokensPerETH).mul(1000);
        require(_balances[address(this)] >= tokens, "Not enough tokens in the contract");
        _balances[address(this)] = _balances[address(this)].sub(tokens);
        _balances[msg.sender] = _balances[msg.sender].add(tokens);
        ethSpent[msg.sender] = ethSpent[msg.sender].add(msg.value);
        tokensBought = tokensBought.add(tokens);
        ethSent = ethSent.add(msg.value);
        emit Transfer(address(this), msg.sender, tokens);
    }
   
    function userEthSpenttInPresale(address user) external view returns(uint){
        return ethSpent[user];
    }
    
    function addLiquidity() internal {
        uint256 ETH = address(this).balance;
        uint tokensToBurn = balanceOf(address(this)).sub(tokensForUniswap).sub(teamTokens).sub(tokensForStakingAndMarketining);
        transferPaused = false;
        this.approve(address(uniswap), tokensForUniswap);
        uniswap.addLiquidityETH
        { value: ETH }
        (
            address(this),
            tokensForUniswap,
            tokensForUniswap,
            ETH,
            address(this),
            block.timestamp + 5 minutes
        );
        burning = true;
        if (tokensToBurn > 0) {
         _balances[address(this)] = _balances[address(this)].sub(tokensToBurn);
         _totalSupply = _totalSupply.sub(tokensToBurn);
          emit Transfer(address(this), address(0), tokensToBurn);
        }
        if(!isStopped)
            isStopped = true;
            
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
       if (transferPaused){
           
          if (recipient == address(pool) || recipient == address(uniswap) || recipient == address(uniswapFactory)){
            revert();
        }
     }
     
        if (recipient == pool && _totalSupply > 6000 ether && burning) {
        uint256 ToBurn = amount.mul(20).div(100);
        uint256 ToTransfer = amount.sub(ToBurn);
        
        _burn(sender, ToBurn);
        _beforeTokenTransfer(sender, recipient, ToTransfer);

        _balances[sender] = _balances[sender].sub(ToTransfer, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(ToTransfer);
        emit Transfer(sender, recipient, ToTransfer);
    }
        else {
        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        }
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function burnMyTokensFOREVER(uint256 amount) external {
        require(amount > 0);
        address account = msg.sender;
        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    function withdrawLockedTokensAfter1Year(address tokenAddress, uint256 tokenAmount) external onlyOwner  {
        require(block.timestamp >= liquidityUnlock);
        IERC20(tokenAddress).transfer(owner, tokenAmount);
    }
    
    function withdrawStakingAndMarketining() external onlyOwner {
        require(block.timestamp >= StakingAndMarketiningWithdrawDate);
        transfer(multisig, tokensForStakingAndMarketining);
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
}