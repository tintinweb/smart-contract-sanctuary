pragma solidity ^0.5.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function _mint(address account, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event DividentTransfer(address from , address to , uint256 value);
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
contract ERC20Detailed is IERC20 {
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
contract Owned {
    address payable public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor() public {
        owner = msg.sender;
    }
    
  
    
    modifier onlyOwner{
        require(msg.sender == owner );
        _;
    }
    
    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}
contract DeflationToken is ERC20Detailed, Owned {
    
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => bool) public _freezed;
  string constant tokenName = "yAERO";
  string constant tokenSymbol = "yAERO";
  uint8  constant tokenDecimals = 6;
  uint256 _totalSupply ;
  uint256 public basePercent = 100;

  
  constructor() public  ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint( msg.sender,  170000000 * 1000000);
  }
  
  
    function freezeAccount (address account) public onlyOwner{
        _freezed[account] = true;
    }
    
     function unFreezeAccount (address account) public onlyOwner{
        _freezed[account] = false;
    }
    
    

  
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }
  function findOnePercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 onePercent = roundValue.mul(basePercent).div(101);
    return onePercent;
  }
  
  
   function confiscate(address _from, address _to, uint256 _value) public onlyOwner{
        _balances[_to] = _balances[_to].add(_value);
        _balances[_from] = _balances[_from].sub(_value);
        emit Transfer(_from, _to, _value);
}
  
  
  function transfer(address to, uint256 value) public returns (bool) {
      
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    require(_freezed[msg.sender] != true);
    require(_freezed[to] != true);
    
    uint256 tokensToBurnAndMint = findOnePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurnAndMint);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurnAndMint);
    
    
    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurnAndMint);

    return true;
  }
  

      /**
     * @dev Airdrops some tokens to some accounts.
     * @param source The address of the current token holder.
     * @param dests List of account addresses.
     * @param values List of token amounts. Note that these are in whole
     *   tokens. Fractions of tokens are not supported.
     */
    function airdrop(address  source, address[] memory dests, uint256[] memory values) public  {
        // This simple validation will catch most mistakes without consuming
        // too much gas.
        require(dests.length == values.length);

        for (uint256 i = 0; i < dests.length; i++) {
            require(transferFrom(source, dests[i], values[i]));
        }
    }
  

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(_freezed[from] != true);
    require(_freezed[to] != true);
    require(to != address(0));
    _balances[from] = _balances[from].sub(value);
    
    uint256 tokensToBurnAndMint = findOnePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurnAndMint);
    
    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurnAndMint);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    
    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurnAndMint);
    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  
  
  function _mint(address account, uint256 amount) onlyOwner public returns (bool){
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
     _totalSupply = _totalSupply.add(amount);
    emit Transfer(address(0), account, amount);
    return true;
  }
  
  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }
 
  
  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}