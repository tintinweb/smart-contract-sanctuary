// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

abstract contract PokeMeReady {
  address payable public immutable pokeMe;

  constructor(address payable _pokeMe) {
    pokeMe = _pokeMe;
  }

  modifier onlyPokeMe() {
    require(msg.sender == pokeMe, "PokeMeReady: onlyPokeMe");
    _;
  }
}

contract SimpleOracle is PokeMeReady {
    uint public price;
    constructor(address payable _pokeMe) PokeMeReady(_pokeMe) {}

    function updateETHPrice(uint _price) external onlyPokeMe {
        price = _price;
    }
}