pragma solidity ^0.4.19;

contract ERC20 {
  function balanceOf(address _owner) public constant returns (uint256 balance);
}

contract GetManyBalances {
  function getManyBalances(address[] addresses)
      public view returns (uint256[]) {
    return _getManyBalances(addresses);
  }

  function getManyTokenBalances(address[] addresses, ERC20 token)
      public view returns (uint256[]) {
    return _getManyTokenBalances(addresses, token);
  }

  function getManyBalancesPacked(bytes addressesPacked, ERC20 token)
      public view returns (uint256 []) {
    uint256 len = addressesPacked.length;
    require(len % 20 == 0);
    uint256 numAddresses = len / 20;

    address[] memory addresses = new address[](numAddresses);
    uint256 out;
    uint256 outEnd;

    assembly {
      out := add(addresses, 32)
      outEnd := add(out, mul(32, numAddresses))
    }

    while (out < outEnd) {
      assembly {
          addressesPacked := add(addressesPacked, 20)
          mstore(out, mload(addressesPacked))
          out := add(out, 32)
      }
    }

    return _getManyTokenBalances(addresses, token);
  }

  function _getManyBalances(address[] memory addresses)
      internal view returns (uint256[]) {
    uint[] memory b = new uint[](addresses.length);
    for (uint i = 0; i < addresses.length; ++i) {
        b[i] = addresses[i].balance;
    }
    return b;
  }

  function _getManyTokenBalances(address[] memory addresses, ERC20 token)
      internal view returns (uint256[]) {
    if (token == ERC20(0)) {
      return _getManyBalances(addresses);
    }
    uint[] memory b = new uint[](addresses.length);
    for (uint i = 0; i < addresses.length; ++i) {
        b[i] = token.balanceOf(addresses[i]);
    }
    return b;
  }
}