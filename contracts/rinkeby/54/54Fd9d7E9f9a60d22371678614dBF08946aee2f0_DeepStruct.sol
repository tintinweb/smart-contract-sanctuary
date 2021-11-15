// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

contract DeepStruct {
  /**
  * @dev Creates a new token type and assigns _initialSupply to an address
  * @param _creator address of the first owner of the token
  * @param _initialSupply amount to supply the first owner
  * @param _fees structure [[address, permille][address, permille]]
  * @param _hash bytes32 hash of the metadata file for ipfs
  * @param _data Data to pass if receiver is contract
  * @return The newly created token ID
  */
  function create(address _creator,uint256 _initialSupply, LibPart.Part[] memory _fees, bytes32 _hash, bytes calldata _data)
  external returns (uint256) {
    return 42;
  }
}

