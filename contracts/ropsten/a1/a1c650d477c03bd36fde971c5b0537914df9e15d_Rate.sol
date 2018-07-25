pragma solidity 0.4.24;

contract Rate {
  mapping(uint => mapping(bytes32 => uint)) public rates;

  function setRates(uint time, bytes32[] names, uint[] amounts) external {
    require(time % 5 == 0);
    require(names.length == amounts.length);
    for (uint i = 0; i < names.length; i++) {
      rates[time][names[i]] = amounts[i];
    }
  }

  function getRate(uint time, bytes32 name) public view returns (uint) {
    return rates[time][name];
  }

  function getRates(uint time, bytes32[] memory names) public view returns (uint[]) {
    uint[] memory amounts = new uint[](names.length);

    for (uint i = 0; i < names.length; i++) {
      amounts[i] = rates[time][names[i]];
    }

    return amounts;
  }
}