/**
 *Submitted for verification at Etherscan.io on 2020-05-06
*/

pragma solidity ^0.6.0;

/**
 * @title KeyMap
 * @author https://github.com/d1ll0n
 * This contracts maps addresses to public keys.
 * Public keys for Secp256k1 are always 64 bytes.
 * To save gas, this contract stores them as an array of two bytes32 words.
 */
contract KeyMap {
  mapping(address => bytes32[2]) private mappedKeys;

  /**
   * @dev mapKey
   * Calculates the address for a public key, then saves the mapping from address to public key.
   * @notice This overload reduces the calldata cost of submission.
   * @param slice0 - first 32 bytes of the public key
   * @param slice1 - second 32 bytes of the public key
   * @return _address - calculated address
   */
  function mapKey(bytes32 slice0, bytes32 slice1) external returns(address _address) {
    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0x04, 0x40)
      let mask := 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
      _address := and(mask, keccak256(ptr, 0x40))
      calldatacopy(ptr, calldatasize(), 0x40)
    }
    mappedKeys[_address][0] = slice0;
    mappedKeys[_address][1] = slice1;
  }

  /**
   * @dev mapKey
   * Calculates the address for a public key, then saves the mapping from address to public key.
   * @notice This overload is somewhat simpler to use, but has a higher calldata cost.
   * @param _pubKey - ABI encoded 64 byte public key
   * @return _address - calculated address
   */
  function mapKey(bytes calldata _pubKey) external returns(address _address) {
    require(_pubKey.length == 64, "Invalid public key.");
    bytes32[2] memory pubKey;
    assembly {
      calldatacopy(pubKey, 0x44, 0x40)
      let mask := 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
      _address := and(mask, keccak256(pubKey, 0x40))
    }
    mappedKeys[_address][0] = pubKey[0];
    mappedKeys[_address][1] = pubKey[1];
  }

  /**
   * @dev getKey
   * Retrieves the public key for the given address.
   * @notice Throws an error if the key is not registered.
   * @param _address - address to query
   * @return pubKey - ABI encoded public key retrieved from storage
   */
  function getKey(address _address) public view returns (bytes memory pubKey) {
    pubKey = new bytes(64);
    bytes32[2] memory key = mappedKeys[_address];
    require(key[0] != bytes32(0), "Key not mapped.");
    assembly {
      mstore(add(pubKey, 32), mload(key))
      mstore(add(pubKey, 64), mload(add(key, 32)))
    }
  }
}