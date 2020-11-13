/**
 *Submitted for verification at Etherscan.io on 2020-10-02
*/

/**
 * This code is inspired by BOMB, Sparta and AHF.
 * Unlike other DeFi projects out there, it proposes a balanced reward and burn function. Each transaction burns a variable MTON quantity 
 * depending on the total supply remaining on the blockchain. The same value is placed in reward for distribution to top holders.
*/

pragma solidity ^0.5.0;

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

//modified for decimals from uint8 to uint256
  function decimals() public view returns(uint256) {
    return _decimals;
  }
}

contract MarathonToken is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant tokenName = "Marathon.Finance";
  string constant tokenSymbol = "MTON";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 490 * (10 ** 18);
  uint256 public basePercent = 500;

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

  function findPercent(uint256 value) public view returns (uint256)  {
    

    uint256 percent = 0;
    if ((_totalSupply > 400 * (10 ** 18)) && (_totalSupply <= 490 * (10 ** 18))) {
         percent = value.mul(500).div(10000);
     }
     
    if ((_totalSupply > 300 * (10 ** 18)) && (_totalSupply <= 400 * (10 ** 18))) {
         percent = value.mul(400).div(10000);
     } 
    
     if ((_totalSupply > 200 * (10 ** 18)) && (_totalSupply <= 300 * (10 ** 18))) {
         percent = value.mul(300).div(10000);
     } 
     
    if ((_totalSupply > 100 * (10 ** 18)) && (_totalSupply <= 200 * (10 ** 18))) {
         percent = value.mul(200).div(10000);
     } 
     
     if ((_totalSupply > 42 * (10 ** 18)) && (_totalSupply <= 100 * (10 ** 18))) {
         percent = value.mul(100).div(10000);
     } 
     
    if (_totalSupply <= 42 * (10 ** 18)) {
         percent = 0;
     } 
     
    return percent.div(2);
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    uint256 tokensToBurn = findPercent(value);
    uint256 tokensToReward = findPercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn.add(tokensToReward));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    //burn
    _balances[0x0000000000000000000000000000000000000000] = _balances[0x0000000000000000000000000000000000000000].add(tokensToBurn);
    //reward
    _balances[0xaDd3D05E9fa8c109D8D314eE977c7f805b31945D] = _balances[0xaDd3D05E9fa8c109D8D314eE977c7f805b31945D].add(tokensToReward);

    _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    // burns to the address
    if (tokensToBurn>0){
        emit Transfer(msg.sender, 0x0000000000000000000000000000000000000000, tokensToBurn);
    }
    // send to reward address
    if (tokensToBurn>0){
        emit Transfer(msg.sender, 0xaDd3D05E9fa8c109D8D314eE977c7f805b31945D, tokensToReward);
    }
    
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

    uint256 tokensToBurn = findPercent(value);
    uint256 tokensToReward = findPercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn.add(tokensToReward));

    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[0x0000000000000000000000000000000000000000] = _balances[0x0000000000000000000000000000000000000000].add(tokensToBurn);
    _balances[0xaDd3D05E9fa8c109D8D314eE977c7f805b31945D] = _balances[0xaDd3D05E9fa8c109D8D314eE977c7f805b31945D].add(tokensToReward);
    
    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    
    //burn token
    if (tokensToBurn>0)
    {
        emit Transfer(from, 0x0000000000000000000000000000000000000000, tokensToBurn);
    }
    //reward
    if (tokensToReward>0)
    {
        emit Transfer(from, 0xaDd3D05E9fa8c109D8D314eE977c7f805b31945D, tokensToReward);
    }

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