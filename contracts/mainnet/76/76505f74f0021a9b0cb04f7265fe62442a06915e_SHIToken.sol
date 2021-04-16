/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity 0.8.3;

abstract contract ERC20Interface {
  function totalSupply() public view virtual returns (uint);
  function balanceOf(address tokenOwner) public view virtual returns (uint balance);
  function allowance(address tokenOwner, address spender) public view virtual returns (uint remaining);
  function transfer(address payable to, uint tokens) public virtual returns (bool success);
  function approve(address spender, uint tokens) public virtual returns (bool success);
  function transferFrom(address payable from, address payable to, uint tokens) public virtual returns (bool success);
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SHIToken is ERC20Interface {
  string public symbol;
  string public  name;
  uint8 public decimals;
  uint256 public supply;
  address payable public owner;
  uint256 private _guardCounter;
  address payable public contractAddress;

  mapping(address => uint) public balances;
  mapping(address => mapping(address => uint)) public allowed;

  constructor() public {
    symbol = "SHIT";
    name = "SHIToken (SHIT token)";
    decimals = 18;
    supply = 1000000000e18;
    owner = payable(msg.sender);
    _guardCounter = 1;
    balances[owner] = supply;
    contractAddress = payable(address(this));

    emit Transfer(address(0), owner, supply);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier nonReentrancyGaurd() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

  function totalSupply() public override view returns (uint) {
    return supply - balances[owner];
  }


  function balanceOf(address tokenOwner) public view override returns (uint balance) {
    return balances[tokenOwner];
  }

  function transfer(address payable to, uint tokens) public override returns (bool success) {
    require(tokens <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender] - tokens;
    balances[to] = balances[to] + tokens;
    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  function approve(address spender, uint tokens) public override returns (bool success) {
    //prevent front-running attach
    require(tokens ==0 || allowed[msg.sender][spender]==0);
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(address payable from, address payable to, uint tokens) public override returns (bool success) {
    require(tokens <= balances[from]);
    require(tokens <= allowed[from][msg.sender]);
    balances[from] = balances[from] - tokens;
    allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
    balances[msg.sender] = balances[msg.sender] - tokens;
    balances[to] = balances[to] + tokens;

    emit Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }

  fallback() external payable {
    revert();
  }

  function getContractBalance() public view returns(uint) {
    uint256 balance = contractAddress.balance;
    return balance;
  }

  function transferBalance() onlyOwner() public {
    owner.transfer(address(this).balance);
  }
}