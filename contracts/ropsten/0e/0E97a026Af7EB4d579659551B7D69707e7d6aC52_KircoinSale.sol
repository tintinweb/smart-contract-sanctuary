/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8 values);
  function totalSupply() external view returns (uint256 amount);

  function balanceOf(address account) external view returns (uint256 balance);
  function transfer(address recipient, uint256 amount) external returns (bool success);
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 amount) external returns (bool success);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Kircoin is IERC20 {
  //Token info
  string public constant override name = "Kircoin";
  string public constant override symbol = "KC";
  uint8 public constant override decimals = 3;
  uint256 public override totalSupply;

  //Mappings
  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;

  constructor(uint256 total) {
    totalSupply = total;
    balances[msg.sender] = total;
  }

  //Check the valance of an account
  function balanceOf(address tokenOwner) override external view returns (uint) {
    return balances[tokenOwner];
  }

  //Transfer tokens to another account
  function transfer(address receiver, uint numTokens) override external returns (bool) {
    require(numTokens <= balances[msg.sender], "not enough balance");

    balances[msg.sender] -= numTokens;
    balances[receiver] += numTokens;
    emit Transfer(msg.sender, receiver, numTokens);
    return true;
  }

  //Get the tokens approved for withdrawal
  function allowance(address owner, address delegate) override external view returns (uint) {
    return allowed[owner][delegate];
  }

  //Approve a delegate to withdraw tokens
  function approve(address delegate, uint numTokens) override external returns (bool) {
    allowed[msg.sender][delegate] = numTokens;
    emit Approval(msg.sender, delegate, numTokens);
    return true;
  }

  //Transfer between accounts as a delegate
  function transferFrom(address owner, address buyer, uint amount) override external returns (bool) {
    require(amount <= balances[owner], "not enough balance");
    require(amount <= allowed[owner][msg.sender], "approved amount is not enough");

    balances[owner] -= amount;
    allowed[owner][msg.sender] -= amount;
    balances[buyer] += amount;
    emit Transfer(owner, buyer, amount);
    return true;
  }
}

interface Sale {
  function buyTokens() external payable;
  function getRate() external view returns (uint256);
  function withdrawEth() external payable;
}

contract KircoinSale is Sale {
  address owner;
  IERC20 token;
  uint256 rate;

  constructor(address tokenAddr, uint256 _rate) {
    owner = msg.sender;
    token = IERC20(tokenAddr);
    rate = _rate;
  }
  modifier ownerOnly() {
    require(msg.sender == owner, "only the owner is allow to execute this function");
    _;
  }

  function buyTokens() override public payable {
    uint amount = msg.value * rate;
    require(amount > 0, "not enough ether");
    token.transferFrom(owner, msg.sender, amount); //using this contract as delegate
  }

  function getRate() override external view returns (uint256) {
    return rate;
  }

  function withdrawEth() override external payable ownerOnly {
    payable(owner).transfer(address(this).balance);
  }

  receive() external payable {
    buyTokens();
  }

  fallback() external payable {
    buyTokens();
  }
}