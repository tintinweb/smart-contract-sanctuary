pragma solidity ^0.5.0;

contract PaymentSharer {
  mapping(uint => uint) splits;
  mapping(uint => uint) deposits;
  mapping(uint => address payable) first;
  mapping(uint => address payable) second;

  function init(uint id, address payable _first, address payable _second) public {
    require(first[id] == address(0) && second[id] == address(0));
    require(first[id] == address(0) && second[id] == address(0));
    first[id] = _first;
    second[id] = _second;
  }

  function deposit(uint id) public payable {
    deposits[id] += msg.value;
  }

  function updateSplit(uint id, uint split) public {
    require(split <= 100);
    splits[id] = split;
  }

  function splitFunds(uint id) public {
    // Here would be: 
    // Signatures that both parties agree with this split

    // Split
    address payable a = first[id];
    address payable b = second[id];
    uint depo = deposits[id];
    deposits[id] = 0;

    a.transfer(depo * splits[id] / 100);
    b.transfer(depo * (100 - splits[id]) / 100);
  }
}