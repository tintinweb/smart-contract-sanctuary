/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IEnsRegistry {
  function resolver(bytes32 node) external view returns (address);
}

interface IEnsResolver {
  function addr(bytes32 node) external view returns (address);
}

interface IOracle {
  function latestAnswer() external view returns (uint256);
}

contract CalculationsChainlink {
  address public ownerAddress;
  address public ensRegistryAddress =
    0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
  mapping(address => bytes32) public oracleNamehashes;

  constructor() public {
    ownerAddress = msg.sender;
  }

  struct Namehash {
    address tokenAddress;
    bytes32 namehash;
  }

  function setNamehash(address tokenAddress, bytes32 namehash) public {
    require(msg.sender == ownerAddress, "Ownable: Admin only");
    oracleNamehashes[tokenAddress] = namehash;
  }

  function setNamehashes(Namehash[] memory namehashes) public {
    require(msg.sender == ownerAddress, "Ownable: Admin only");
    for (uint256 i = 0; i < namehashes.length; i++) {
      setNamehash(namehashes[i].tokenAddress, namehashes[i].namehash);
    }
  }

  function resolveEnsNodeHash(bytes32 node) public view returns (address) {
    return
      IEnsResolver(IEnsRegistry(ensRegistryAddress).resolver(node)).addr(node);
  }

  function priceUsdc(address tokenAddress) public view returns (uint256) {
    bytes32 namehash = oracleNamehashes[tokenAddress];
    address resolverAddress = resolveEnsNodeHash(namehash);
    return IOracle(resolverAddress).latestAnswer() / 10**2;
  }

  function pricesUsdc(address[] memory tokensAddresses)
    external
    view
    returns (uint256[] memory)
  {
    uint256[] memory _pricesUsdc = new uint256[](tokensAddresses.length);
    for (uint256 tokenIdx; tokenIdx < tokensAddresses.length; tokenIdx++) {
      uint256 price = priceUsdc(tokensAddresses[tokenIdx]);
      _pricesUsdc[tokenIdx] = price;
    }
    return _pricesUsdc;
  }

  /**
   * Allow storage slots to be manually updated
   */
  function updateSlot(bytes32 slot, bytes32 value) external {
    require(msg.sender == ownerAddress, "Ownable: Admin only");
    assembly {
      sstore(slot, value)
    }
  }
}