pragma solidity ^0.5.0;

contract ListingServiceRegistration {
  event Log(bytes32 indexed data);

  function logEthTx(bytes32 _data) public {
    emit Log(_data);
  }
}