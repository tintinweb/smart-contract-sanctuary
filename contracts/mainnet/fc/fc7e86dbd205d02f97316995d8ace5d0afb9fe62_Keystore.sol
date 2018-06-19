pragma solidity ^0.4.19;

contract Keystore {
  address[] public owners;
  uint public ownersNum;
  address public developer = 0x2c3b0F6E40d61FEb9dEF9DEb1811ea66485B83E7;
  event QuantumPilotKeyPurchased(address indexed buyer);

  function buyKey() public payable returns (bool success)  {
    require(msg.value >= 1000000000000000);
    owners.push(msg.sender);
    ownersNum = ownersNum + 1;
    emit QuantumPilotKeyPurchased(msg.sender);
    return true;
  }

  function payout() public returns (bool success) {
    address c = this;
    require(c.balance >= 1000000000000000);
    developer.transfer(c.balance);
    return true;
  }
}