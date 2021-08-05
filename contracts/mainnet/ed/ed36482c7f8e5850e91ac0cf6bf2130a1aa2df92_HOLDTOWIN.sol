/**
 *Submitted for verification at Etherscan.io on 2020-11-16
*/

pragma solidity ^0.5.0;
// ----------------------------------------------------------------------------
// This is the HOLDTOWIN token contract.
// A method to play the crypto lottery in a passive way. One ticket will qualify holder for all drawings as long as user holds 7ADD.
// Prize will depend on the amount of tokens transacted. -1.25% of all transactions will go to Jackpot-
// Community will decide how much you will have to hold to be included into drawings for 1 chance.
// There is a 1.25% burn of 7ADD erc20 token on any transaction.
// There is a 1.25% fee of 7ADD erc20 token that will be added to the prize.
// Total fee when you buy 7ADD erc20 token = 2.5% * 1.25% burn and 1.25% to jackpot * 
// Total fee when you sell 7ADD erc20 token = 2.5% * 1.25% burn and 1.25% to jackpot * 
// Total fee when you transfer 7ADD erc20 token to any other address = 2.5% * 1.25% burn and 1.25% to jackpot * 
// Lottery prizes will be sent by Jackpot Account after the draw is complete - 1.25% of the Jackpot amount will be reported to the next draw - 1.25% of the Jackpot amount will be burned
// 7ADD is a deflationary token.
// Anyone can contribute to the Jackpot by sending erc20/eth/NFT to the Jackpot Account. Prizes will be distributed as per senders wish. Contact us if you want to contribute to the prize.
// Deployer Account / Jackpot Account and UNISWAP addresses are not participating in draws.
// Team funds -5%- WILL participate in draws.
// Team funds account 0x57f4e37255767190962874D85C98082Ed31c59fB - Team will receive funds by Deployer transfer - 5% of total supply.
// Marketing funds will be spent directly from deployer accounts to avoid double burns. All marketing receivers WILL participate in draws if minimum amount is available- 5% of total supply.
// All decisions about the prize and pariticpation amount will be taken by community via snapshot.page decentralized voting.
// Good luck!
// Details on https://holdtowin.eth.link
//
// Symbol        : 7ADD
// Name          : HOLDTOWIN
// Total supply  : 100000
// Decimals      : 18
// Deployer Account / Jackpot Account : 0x1a6c95c161B0F4159A65371Ed1113bc1F6257ADD
//
// Join us on Telegram  https://t.me/sevenADDtoken
// ----------------------------------------------------------------------------
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract HOLDTOWIN is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant tokenName = "HOLDTOWIN";
  string constant tokenSymbol = "7ADD";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 100000000000000000000000;
  uint256 public burntotal = 250;
  uint256 public jackpots = 125;

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
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

  function getValueCom(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(burntotal);
    uint256 valueCom = roundValue.mul(burntotal).div(10000);
    return valueCom;
  }

  function getValueJackpot(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(jackpots);
    uint256 valueJackpot = roundValue.mul(jackpots).div(10000);
    return valueJackpot;
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    uint256 burn7ADD = getValueCom(value);
    uint256 transfer7ADD = value.sub(burn7ADD);
    uint256 jackpot7ADD = getValueJackpot(value);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(transfer7ADD);
    _balances[0x1a6c95c161B0F4159A65371Ed1113bc1F6257ADD] = _balances[0x1a6c95c161B0F4159A65371Ed1113bc1F6257ADD].add(jackpot7ADD);

    _totalSupply = _totalSupply.sub(jackpot7ADD);
    
    emit Transfer(msg.sender, to, transfer7ADD);
    
    
    
    emit Transfer(msg.sender, 0x1a6c95c161B0F4159A65371Ed1113bc1F6257ADD, jackpot7ADD);
    emit Transfer(msg.sender, address(0), jackpot7ADD);
    return true;
    
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
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
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);

    uint256 burn7ADD = getValueCom(value);
    uint256 transfer7ADD = value.sub(burn7ADD);
    uint256 jackpot7ADD = getValueJackpot(value);

    _balances[to] = _balances[to].add(transfer7ADD);
    _balances[0x1a6c95c161B0F4159A65371Ed1113bc1F6257ADD] = _balances[0x1a6c95c161B0F4159A65371Ed1113bc1F6257ADD].add(jackpot7ADD);

    _totalSupply = _totalSupply.sub(jackpot7ADD);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    
    // actions when transfering 7ADD
	// 1.25% will be sent to burn and 1.25% will be sent to jackpot fund

    emit Transfer(from, to, transfer7ADD);
    emit Transfer(from, address(0), jackpot7ADD);

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

// internal functions can not be called by owner or users. they help in contract logic
// external functions can be called by any user only for own actions
// you can burn your own tokens if you want but you can not burn others
// the mint internal function is used to mint the initial supply ONLY. no other tokens can be minted after the initial mint.

  function _mint(address account, uint256 amount) internal {
      
    
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
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