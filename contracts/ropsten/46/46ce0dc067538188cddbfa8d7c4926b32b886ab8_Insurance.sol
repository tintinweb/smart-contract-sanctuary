pragma solidity ^0.4.24;

contract Insurance {
  address public insurer;
  address public oracle;
  address public insured;

  uint256 public subscriptionPrice = 0.01 ether;

  uint8 public currentTemperature;
  uint8 public claimTemperature = 0;
  uint8 public dangerTemperature = 3;

  constructor (address _insurer, address _oracle, uint8 _currentTemperature) payable public {
    insurer = _insurer;
    oracle = _oracle;
    currentTemperature = _currentTemperature;
  }

  function updateTemperature(uint8 _newTemperature) public {
    require(msg.sender == oracle);
    currentTemperature = _newTemperature;
  }

  function subscribe() public payable {
    require(currentTemperature > dangerTemperature);
    require(insured == address(0));
    require(msg.value > subscriptionPrice);
    insured = msg.sender;
  }

  function claim() public {
    require(currentTemperature < claimTemperature);
    require(msg.sender == insured);
    insured.transfer(address(this).balance);
  }
}