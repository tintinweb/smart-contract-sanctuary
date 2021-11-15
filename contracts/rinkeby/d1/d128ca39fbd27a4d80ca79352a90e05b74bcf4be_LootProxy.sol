// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external {
        _fallback();
    }
}

interface ILoot {
  function getWeapon(uint256 tokenId) external view returns (string memory);
  function getChest(uint256 tokenId) external view returns (string memory);
  function getHead(uint256 tokenId) external view returns (string memory);
  function getWaist(uint256 tokenId) external view returns (string memory);
  function getFoot(uint256 tokenId) external view returns (string memory);
  function getHand(uint256 tokenId) external view returns (string memory);
  function getNeck(uint256 tokenId) external view returns (string memory);
  function getRing(uint256 tokenId) external view returns (string memory);
}

contract LootProxy is Proxy {
  address immutable _impl;

  string private _name;
  string private _symbol;
  uint private _slot2;
  uint private _slot3;
  uint private _slot4;
  uint private _slot5;
  uint private _slot6;
  uint private _slot7;
  uint private _slot8;
  uint private _slot9;
  uint private _slot10;
  address private _owner;

  /**
    * @dev Converts a `uint256` to its ASCII `string` decimal representation.
    */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
        return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
    }
    return string(buffer);
  }

  constructor(address impl) {
    _impl = impl;
    _name = "Loot ExplorerTH";
    _symbol = "LETH";
    _owner = msg.sender;
  }

  function getWeapon(uint256 tokenId) public view returns (string memory) {
    return ILoot(_impl).getWeapon(tokenId);
  }
  
  function getChest(uint256 tokenId) public view returns (string memory) {
    return ILoot(_impl).getChest(tokenId);
  }
  
  function getHead(uint256 tokenId) public view returns (string memory) {
    return ILoot(_impl).getHead(tokenId);
  }
  
  function getWaist(uint256 tokenId) public view returns (string memory) {
    return ILoot(_impl).getWaist(tokenId);
  }

  function getFoot(uint256 tokenId) public view returns (string memory) {
    return ILoot(_impl).getFoot(tokenId);
  }
  
  function getHand(uint256 tokenId) public view returns (string memory) {
    return ILoot(_impl).getHand(tokenId);
  }
  
  function getNeck(uint256 tokenId) public view returns (string memory) {
    return ILoot(_impl).getNeck(tokenId);
  }
  
  function getRing(uint256 tokenId) public view returns (string memory) {
    return ILoot(_impl).getRing(tokenId);
  }

  function tokenURI(uint256 tokenId) public pure returns (string memory) {
    return string(abi.encodePacked("https://bafybeialjg77lu5soroaqnbjczlcqa72gvtg3c3m2rj4tgjo2sash44mka.ipfs.cf-ipfs.com/", toString(tokenId)));
  }

  function contractURI() external pure returns (string memory) {
    return "https://bafybeid2o3idv4xqdig6yfvexjflllpmlxkobftfbx6jblqwadculcthxi.ipfs.cf-ipfs.com/";
  }

  function _implementation() internal view override returns (address) {
    return _impl;
  }

  function claim(uint256) external {
    _fallback();
  }
}

