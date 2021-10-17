/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.3;

interface ERC20Interface {
  function totalSupply() external view returns (uint supply);
  function balanceOf(address tokenOwner) external view returns (uint balance);
  function allowance(address tokenOwner, address spender) external view returns (uint remaining);
  function transfer(address payable to, uint tokens) external returns (bool success);
  function approve(address spender, uint tokens) external returns (bool success);
  function transferFrom(address payable from, address payable to, uint tokens) external returns (bool success);
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

  constructor() {
    symbol = "SH*T";
    name = "SHIToken";
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

  function totalSupply() external override view returns (uint) {
    return supply - balances[owner];
  }


  function balanceOf(address tokenOwner) external view override returns (uint balance) {
    return balances[tokenOwner];
  }

  function transfer(address payable to, uint tokens) external override returns (bool success) {
    require(tokens <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender] - tokens;
    balances[to] = balances[to] + tokens;
    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  function approve(address spender, uint tokens) external override returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(address payable from, address payable to, uint tokens) external override returns (bool success) {
    require(tokens <= balances[from]);
    require(tokens <= allowed[from][msg.sender]);
    balances[from] = balances[from] - tokens;
    allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
    balances[to] = balances[to] + tokens;

    emit Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender) external view override returns (uint remaining) {
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