/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

abstract contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _transferOwnership(msg.sender);
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

abstract contract PokeMeReady {
  address payable public pokeMe;

  constructor(address payable _pokeMe) {
    pokeMe = _pokeMe;
  }

  modifier onlyPokeMe() {
    require(msg.sender == pokeMe, "PokeMeReady: onlyPokeMe");
    _;
  }
}

contract SimpleOracle is PokeMeReady, Ownable {
    uint constant public decimals = 6;
    string[] public supportedCoins;
    mapping (string=>bool) private isCoinSupported;
    mapping (string=>uint256) private coinPrices;

    event UpdateCoinPrice(string coin, uint256 price);

    constructor(string[] memory _supportedCoins, address payable _pokeMe) PokeMeReady(_pokeMe) {
      for (uint256 i = 0; i < _supportedCoins.length; i++) {
        isCoinSupported[_supportedCoins[i]] = true;
        supportedCoins.push(_supportedCoins[i]);
      }
    }

    function addNewCoin(string memory coin) public onlyOwner {
      require(!isCoinSupported[coin], "SimpleOracle: coin already supported");
      isCoinSupported[coin] = true;
      supportedCoins.push(coin);
    }

    function updatePokeMe(address payable _pokeMe) public onlyOwner {
      pokeMe = _pokeMe;
    }

    function getCoinPrice(string memory _coin) public view returns (uint256) {
      require(isCoinSupported[_coin], "SimpleOracle: getCoinPrice: coin not supported");
      return coinPrices[_coin];
    }

    function updateCoinPrices(string[] memory _coins, uint256[] memory _prices) public onlyPokeMe {
      require(_coins.length == _prices.length, "SimpleOracle: updateCoinPrice: coins and prices must have the same length");
      for (uint256 i = 0; i < _coins.length; i++) {
        require(isCoinSupported[_coins[i]], "SimpleOracle: updateCoinPrice: coin not supported");
        coinPrices[_coins[i]] = _prices[i];
        emit UpdateCoinPrice(_coins[i], _prices[i]);
      }
    }
}