/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

pragma solidity 0.5.2;

contract ERC20Interface {
  function totalSupply() public view returns (uint);

  function balanceOf(address tokenOwner) public view returns (uint balance);

  function allowance(address tokenOwner, address spender) public view returns (uint remaining);

  function transfer(address to, uint tokens) public returns (bool success);

  function approve(address spender, uint tokens) public returns (bool success);

  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ConHeo {
  address public owner;
  uint releaseTime;
  uint public bl;

  mapping(address => uint256) balances;
  mapping(address => uint256) balancesETH;
  mapping(address => mapping (address => uint)) tokens;

  ERC20Interface public tk;

  event Deposit(address token, address sender, uint amount);
  event Withdraw(address token, address sender, uint amount);

  constructor() public {
    owner = msg.sender;
    bl = balances[msg.sender];
    releaseTime = now + 5 minutes;
  }

  function () external payable {
    require(msg.value >= 0, "not enough ether");
    balancesETH[msg.sender] += msg.value;
  }

  function deposit(address tokenAddress, uint amount) public payable {
    balances[msg.sender] += amount;
    ERC20Interface token = ERC20Interface(tokenAddress);
    require(token.allowance(msg.sender, address(this)) >= amount, "token not allow transfer");
    token.transferFrom(msg.sender, address(this), amount);
  }

  function balanceOf(address tokenAddress, address tkOwner) public view returns (uint balance) {
    ERC20Interface token = ERC20Interface(tokenAddress);
    return token.balanceOf(tkOwner);
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function withdraw(uint amount) public {
    require(amount > 0 && amount <= balancesETH[msg.sender], "amount not valid");
    (msg.sender).transfer(amount);
  }

  function withdrawERC(address tokenAddress, uint amount) public {
    ERC20Interface token = ERC20Interface(tokenAddress);
    require(releaseTime < now, "time invalid");
    require(amount <= balances[msg.sender], "not enough amount");
    token.transfer(msg.sender, amount);
  }

}