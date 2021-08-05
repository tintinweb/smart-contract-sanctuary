/**
 *Submitted for verification at Etherscan.io on 2020-09-22
*/

/*
 * @title: LAMBO
 * @website: lambotoken.finance
 * @telegram: @lambotokenofficial
 *   _        _______  _______  ______   _______
 * ( \      (  ___  )(       )(  ___ \ (  ___  )
 * | (      | (   ) || () () || (   ) )| (   ) |
 * | |      | (___) || || || || (__/ / | |   | |
 * | |      |  ___  || |(_)| ||  __ (  | |   | |
 * | |      | (   ) || |   | || (  \ \ | |   | |
 * | (____/\| )   ( || )   ( || )___) )| (___) |
 * (_______/|/     \||/     \||/ \___/ (_______)
 *
 * 1.5% burned with every transaction to inject nitrous oxide into our engines
 * On a mission to make 1 Lambo worth 1 Lamborghini
 */



pragma solidity ^0.7.1;
interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, uint256 _extraData) external;
}
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
library SafeMath { //Safe Maths
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
contract LAMBO is IERC20 {
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  string constant tokenName = "LAMBOtoken.finance";
  string constant tokenSymbol = "LAMBO";
  uint8  constant tokenDecimals = 18;
  address addrOwner;
  address payable payOwner;
  uint256 private _totalSupply = 1000000000000000000000;
  uint256 private constant _supplyCap = 2000000000000000000000;
  uint256 public basePercent = 150;
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  string private _description;
  constructor() {
    addrOwner = msg.sender;
    _issue(addrOwner, _totalSupply);
    _name = "LAMBOtoken.finance";
    _symbol = "LAMBO";
    _decimals = 18;
    _description = "On a mission to make 1 Lambo worth 1 Lamborghini.";
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

  modifier onlyOwner() {
    require(msg.sender == addrOwner);
    _;
  }
   function supplyCap() public pure returns (uint256) {
     return _supplyCap;
   }
  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address owner) public override view returns (uint256) {
    return _balances[owner];
  }
  function allowance(address owner, address spender) public override view returns (uint256) {
    return _allowed[owner][spender];
  }
  function slash(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 slashValue = roundValue.mul(basePercent).div(10000); //Burn
    return slashValue;
  }
  function transfer(address to, uint256 value) public override returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    uint256 tokensToBurn = slash(value);  // Burn on transfer
    uint256 tokensToTransfer = value.sub(tokensToBurn);
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurn);
    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (
    _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (
    _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
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
    require(to != address(0));
    _balances[from] = _balances[from].sub(value);
    uint256 tokensToBurn = slash(value);  //Burn on transfer
    uint256 tokensToTransfer = value.sub(tokensToBurn);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurn);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurn);
    return true;
  }
  function _issue(address account, uint256 amount) internal {
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
  function _mint(address account, uint256 value) internal {
    require(account != address(0));
    require(totalSupply().add(value) <= _supplyCap);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }
  function mint(address to, uint256 value) public onlyOwner returns (bool) {
    _mint(to, value);
    return true;
  }
  receive() external payable {
  }
  function withdrawTRX() public onlyOwner {
    payOwner.transfer(address(this).balance);
  }
  function setOwner(address _newOwner) external onlyOwner {
    require(_newOwner != address(0) && _newOwner != addrOwner);
    addrOwner = _newOwner;
  }
}