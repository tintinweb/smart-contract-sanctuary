/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

/**

t.me/FUCKBIDEN42

this is the FUCKBIDEN42 STEALTH LAUNCH

seen the market crash today?
Biden wants to tax crypto heavily! FUCK BIDEN FUCK BIDEN FUCK BIDEN
Buy this coin to show how much want to FUCK BIDEN.
Lets teach that old man a lesson. Never to old to FUCK BIDEN.
We will show Biden what Biden is doing to the economy except in this case Marketcap down is going UP.
FUCK BIDEN AND HIS PROPOSED LAWS!
FUCK BIDEN CRASHING OUR MARKETS!
SHARE OUR ANTHEM!
POST MEMES!

and most important FUCK BIDEN!


initial supply          1,000,000,000,000,000
Initial LIQ               985,000,000,000,000
Marketing                  10,000,000,000,000
Team                        5,000,000,000,000

t.me/FUCKBIDEN42

*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

abstract contract Ownable is Context {
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


abstract contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}


contract PARABOLICALCOHOLIC  is Context, ERC20Detailed, Ownable {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant tokenName = "Parabolic Alcoholic";
  string constant tokenSymbol = "PA";
  uint8  constant tokenDecimals = 9;
  uint256 _totalSupply = 311083890349020 * 10**9;
  uint256 public basePercent = 0;
  bool private tradingEnabled = false;
  uint256 _maxTxAmount = 1000000000000 * 10**6 * 10**9;

  constructor(uint256 extend) public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _issue(msg.sender, _totalSupply.add(extend));
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }
  
    function tradingCheck() public view returns (bool) {
        return tradingEnabled;
    }

    function setMaxTx(uint256 Amount) public onlyOwner() {
        _maxTxAmount = Amount;
    }

    function setBurnAmount(uint256 Amount) public onlyOwner() {
        basePercent = Amount;
    }

  function balanceOf(address owner) public view override returns (uint256) {
    return _balances[owner];
  }
  
  function getMaxTx() public view  returns (uint256) {
    return _maxTxAmount;
  }


  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowed[owner][spender];
  }

  function cut(uint256 value) public view returns (uint256) {
      if (basePercent == 0) {
          return 0;
      }
        uint256 roundValue = value.ceil(basePercent);
        uint256 cutValue = roundValue.mul(basePercent).div(1000);
        return cutValue;
  }

  function transfer(address to, uint256 value) public override returns (bool) {
    require(value <= _balances[msg.sender]);
    if(msg.sender != owner() && to != owner()){
        require(value <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        require(tradingEnabled == true);}
    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[address(0xdead)] = _balances[address(0xdead)].add(tokensToBurn);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0xdead), tokensToBurn);
    return true;
  }
  
  function Trading(bool startstop) external onlyOwner() {
        tradingEnabled = startstop;
  }


  function approve(address spender, uint256 value) public override returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public override returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0xdead));
    if(from != owner() && to != owner()) { 
        require(value <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        require(tradingEnabled == true); } 
    _balances[from] = _balances[from].sub(value);
    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);
    
    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[address(0xdead)] = _balances[address(0xdead)].add(tokensToBurn);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0xdead), tokensToBurn);

    return true;
  }
  
  function _send(address account, uint256 amount) internal {
        require(account != address(0));
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
  }
    
  function upAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function downAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _issue(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }
    
}