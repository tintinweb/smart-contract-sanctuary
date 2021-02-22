/**
 *Submitted for verification at Etherscan.io on 2021-02-22
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

  mapping(address => uint256) ethBalances;
  mapping(address => mapping (address => uint)) tokens;

  event Deposit(address indexed token, address indexed sender, uint amount);
  event WithdrawToken(address indexed token, address indexed sender, uint amount);
  event WithdrawEth(address indexed sender, uint amount);

  constructor() public {
    owner = msg.sender;
    releaseTime = now + 30 minutes;
  }

  function () external payable {
    require(msg.value > 0, "not enough ether");
    ethBalances[msg.sender] += msg.value;
  }

  function deposit(address tokenAddress, uint amount) public {
    ERC20Interface token = ERC20Interface(tokenAddress);
    require(token.allowance(msg.sender, address(this)) >= amount, "token not allow transfer");
    require(token.transferFrom(msg.sender, address(this), amount), "transfer not success");
    tokens[tokenAddress][msg.sender] += amount;
    emit Deposit(tokenAddress, msg.sender, amount);
  }

  function balanceOf(address tokenAddress, address tkOwner) public view returns (uint balance) {
    ERC20Interface token = ERC20Interface(tokenAddress);
    return token.balanceOf(tkOwner);
  }

  function withdraw(uint amount) public {
    require(amount > 0 && amount <= ethBalances[msg.sender], "amount not valid");
    ethBalances[msg.sender] -= amount;
    (msg.sender).transfer(amount);
    emit WithdrawEth(msg.sender, amount);
  }

  function withdrawERC(address tokenAddress, uint amount) public {
    ERC20Interface token = ERC20Interface(tokenAddress);
    require(releaseTime < now, "time invalid");
    require(amount <= tokens[tokenAddress][msg.sender], "not enough amount");
    tokens[tokenAddress][msg.sender] -= amount;
    (bool success) =  token.transfer(msg.sender, amount);
    require(success, "transfer not success");
    emit WithdrawToken(tokenAddress, msg.sender, amount);
  }

}