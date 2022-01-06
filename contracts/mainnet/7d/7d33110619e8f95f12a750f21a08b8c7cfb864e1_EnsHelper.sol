/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IEnsRegistry {
  function resolver(bytes32 node) external view returns (address);

  function owner(bytes32 node) external view returns (address);
}

interface IEnsResolver {
  function addr(bytes32 node) external view returns (address);
}

interface IStringSplit {
  function splitStringByDeliminator(
    string memory input,
    string memory deliminator
  ) external view returns (string[] memory);
}

library EnsHelper {
  address public constant registryAddress =
    0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
  address private constant splitStringAddress =
    0x1C0EeEF670d82498F7547062Aac7eE2143eC52ff;

  function resolvedAddressByNamehash(bytes32 namehash)
    public
    view
    returns (address resolvedAddress)
  {
    address resolverAddress = resolverAddressByNamehash(namehash);
    resolvedAddress = IEnsResolver(resolverAddress).addr(namehash);
  }

  function resolvedAddressByName(string memory name)
    public
    view
    returns (address resolvedAddress)
  {
    bytes32 namehash = namehashByName(name);
    resolvedAddress = resolvedAddressByNamehash(namehash);
  }

  function resolverAddressByNamehash(bytes32 namehash)
    public
    view
    returns (address resolverAddress)
  {
    resolverAddress = IEnsRegistry(registryAddress).resolver(namehash);
  }

  function resolverAddressByName(string memory name)
    public
    view
    returns (address resolverAddress)
  {
    bytes32 namehash = namehashByName(name);
    resolverAddress = resolverAddressByNamehash(namehash);
  }

  function namehashByName(string memory name)
    public
    view
    returns (bytes32 namehash)
  {
    string[] memory parts = IStringSplit(splitStringAddress)
      .splitStringByDeliminator(name, ".");
    for (uint256 partIdx = parts.length - 1; partIdx >= 0; partIdx--) {
      string memory part = parts[partIdx];
      namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(bytes(part))))
      );
      if (partIdx == 0) {
        break;
      }
    }
  }

  function ownerAddressByNamehash(bytes32 namehash)
    public
    view
    returns (address ownerAddress)
  {
    ownerAddress = IEnsRegistry(registryAddress).owner(namehash);
  }

  function ownerAddressByName(string memory name)
    public
    view
    returns (address ownerAddress)
  {
    bytes32 namehash = namehashByName(name);
    ownerAddress = IEnsRegistry(registryAddress).owner(namehash);
  }
}