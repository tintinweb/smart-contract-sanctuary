/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT

// File contracts/interface/IWallet.sol
pragma solidity ^0.8.0;

interface IERC721Token {
  function initialize(
    address _owner,
    string memory _name,
    string memory _symbol
  ) external;
}

contract CloneFactory {
  function clone(address implementation, bytes32 salt) internal returns (address instance) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(ptr, 0x14), shl(0x60, implementation))
      mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      instance := create2(0, ptr, 0x37, salt)
    }
    require(instance != address(0), "ERC1167: create2 failed");
  }

  function computeClone(
    address implementation,
    bytes32 salt,
    address deployer
  ) internal pure returns (address computed) {
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(ptr, 0x14), shl(0x60, implementation))
      mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
      mstore(add(ptr, 0x38), shl(0x60, deployer))
      mstore(add(ptr, 0x4c), salt)
      mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
      computed := keccak256(add(ptr, 0x37), 0x55)
    }
  }
}

contract ERC721Factory is CloneFactory {
  address public implementation;

  event ERC721Created(address erc721Token);

  constructor(address _implementation) {
    implementation = _implementation;
  }

  function createERC721(
    address _owner,
    string memory _name,
    string memory _symbol
  ) external returns (address erc721) {
    bytes32 finalSalt = keccak256(abi.encodePacked(_owner, _name, _symbol));
    erc721 = clone(implementation, finalSalt);
    IERC721Token(erc721).initialize(_owner, _name, _symbol);
    emit ERC721Created(erc721);
  }

  function getERC721Address(
    address _owner,
    string memory _name,
    string memory _symbol
  ) external view returns (address erc721) {
    bytes32 finalSalt = keccak256(abi.encodePacked(_owner, _name, _symbol));
    return computeClone(implementation, finalSalt, address(this));
  }
}