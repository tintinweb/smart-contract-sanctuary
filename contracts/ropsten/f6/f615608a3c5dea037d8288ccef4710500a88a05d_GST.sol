/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

pragma solidity ^0.5.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract GST is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  
  string constant tokenName 	 = "Gemstone Token";
  string constant tokenSymbol 	 = "GST";
  uint8  constant tokenDecimals  = 18;
  uint256 _totalSupply 			 = 15000000*10**18;
  uint256 _exchangeSupply 	     = 6000000*10**18;
  uint256 _burnSupply 	         = 1500000*10**18;
  uint256 _burnPerMonth 	     = 150000*10**18;
  uint256 _marketingSupply 	     = 2250000*10**18;
  uint256 _airdropSupply 	     = 1500000*10**18;
  uint256 _teamSupply 	         = 3750000*10**18;
  uint256 public basePercent 	 = 5;
  uint256 public totalBurn 	     = 0;
  uint256 public toBurn 	     = 1000000*10**18;
  uint256 public monthlyBurn     = 0;
  uint256 public contractTime 	 = block.timestamp-60 days;
  uint256 public nextBurnTime 	 = block.timestamp+90 days;
  
  address payable public exchangeAddress     = 0x738CDD9461d0a218287123b2384d38610A447e21;
  address payable public monthlyBurnAddress  = 0x4BD40924ecca9630a826C2DACB49De426c8b1Ab7;
  address payable public marketingAddress    = 0x14401Ea8aCc28da8b7BcCdeBBa4f1A5ee8aF0328;
  address payable public airdropAddress      = 0xb32Ba22e21bE47a3558Aa836415D9A9E6F2C75D6;
  address payable public teamAddress         = 0xFdc60D1652BfA0333977740E1697A57a04Af1E6F;
  
  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
      _mint(exchangeAddress, _exchangeSupply);
	  _mint(monthlyBurnAddress, _burnSupply);
	  _mint(marketingAddress, _marketingSupply);
	  _mint(airdropAddress, _airdropSupply);
	  _mint(teamAddress, _teamSupply);
  }
  
  function totalSupply() public view returns (uint256) {
     return _totalSupply;
  }
  
  function balanceOf(address owner) public view returns (uint256) 
  {
    return _balances[owner];
  }
  
  function findFivePercent(uint256 value) public view returns (uint256) 
  {
      uint256 roundValue = value.ceil(basePercent);
      uint256 fivePercent = roundValue.mul(basePercent).div(100);
      return fivePercent;
  }
  
  function transfer(address to, uint256 value) public returns (bool) 
  {
	  require(value <= _balances[msg.sender]);
	  require(to != address(0));
	  require(msg.sender != monthlyBurnAddress);
	  _balances[msg.sender] = _balances[msg.sender].sub(value);
	  _balances[to] = _balances[to].add(value);
	  if(msg.sender==exchangeAddress)
	  {
	      uint256 tokensToBurn = findFivePercent(value);
		  uint256 checkToBurn  = totalBurn.add(tokensToBurn);
		  if(toBurn < checkToBurn)
		  {
		      tokensToBurn = toBurn.sub(totalBurn);
		  }
		  require(tokensToBurn <= _balances[exchangeAddress]);
		  _balances[exchangeAddress] = _balances[exchangeAddress].sub(tokensToBurn);
		  _totalSupply = _totalSupply.sub(tokensToBurn);
		  totalBurn = totalBurn.add(tokensToBurn);
		  emit Transfer(exchangeAddress, address(0), tokensToBurn);
	  }
	  emit Transfer(msg.sender, to, value);
	  return true;
  }
  
  function airdrop(address[] memory receivers, uint256 amount) public {
    require(msg.sender == airdropAddress);
    for (uint256 i = 0; i < receivers.length; i++) {
       transfer(receivers[i], amount);
    }
  }
  
  function _mint(address account, uint256 amount) internal {
     require(amount != 0);
     _balances[account] = _balances[account].add(amount);
     emit Transfer(address(0), account, amount);
  }
  
  function burnMonthlyToken() public {
     require(msg.sender == monthlyBurnAddress);
	 uint256 currenttime = now;
	 uint months = uint(((currenttime - contractTime) / 60 / 60 / 24))/30; 
	 uint256 burnLimit   = _burnPerMonth.mul(months);
	 uint256 toNextBurn  = burnLimit.sub(monthlyBurn);
	 monthlyBurn = burnLimit;
	 nextBurnTime = contractTime+(months*30 days);
	 _balances[monthlyBurnAddress] = _balances[monthlyBurnAddress].sub(toNextBurn);
	 emit Transfer(monthlyBurnAddress, address(0), toNextBurn);
  }
  
}