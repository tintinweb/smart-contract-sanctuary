pragma solidity ^0.4.22;

contract MultiEthSender {

  uint256 constant private ethInWei = 10**18;
  mapping(address => uint256) private balance;
  address public owner;

  event Send(uint256 _amount, address indexed receiver);

  constructor() public payable {
    owner = msg.sender;
    balance[msg.sender] = msg.value;
  }

  function multiSendEth(uint256 amount, address[] list) public returns (bool) {
    uint256 amountInWei = amount * ethInWei;
    require(amountInWei * list.length <= balance[msg.sender], "the contract balance is not enough");
    for (uint256 i = 0; i < list.length; i++) {
      emit Send(amount, list[i]);
      uint256 res = balance[msg.sender];
      balance[msg.sender] = res - amountInWei;
      list[i].transfer(amountInWei);
    }
    return true;
  }

  function deposit() public payable returns (uint256) {
    balance[msg.sender] += msg.value;
    return balance[msg.sender];
  }

  function getBalance() public constant returns (uint256) {
      return balance[msg.sender];
  }

  function() public payable { }
}