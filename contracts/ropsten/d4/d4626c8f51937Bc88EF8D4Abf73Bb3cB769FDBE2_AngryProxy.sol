/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// File: @openzeppelin\contracts\utils\cryptography\ECDSA.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: ..\src\Proxy.sol


pragma solidity ^0.8.4;


/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view virtual returns (address);

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  fallback() payable external {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
  
  receive() external payable {
  }  
}

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
  /**
   * @dev This event will be emitted every time the implementation gets upgraded
   * @param implementation representing the address of the upgraded implementation
   */
  event Upgraded(address indexed implementation, uint256 version);

  // Storage position of the address of the current implementation
  bytes32 private constant implementationPosition = keccak256("angry.app.proxy.implementation");

  /**
   * @dev Constructor function
   */
  constructor() {}

  function implementation() public view override returns (address impl) {
    bytes32 position = implementationPosition;
    address tmp;
    assembly {
      tmp := sload(position)
    }
    impl = tmp;
  }

  /**
   * @dev Sets the address of the current implementation
   * @param _newImplementation address representing the new implementation to be set
   */
  function _setImplementation(address _newImplementation) internal {
    bytes32 position = implementationPosition;
    assembly {
      sstore(position, _newImplementation)
    }
  }

  /**
   * @dev Upgrades the implementation address
   * @param _newImplementation representing the address of the new implementation to be set
   */
  function _upgradeTo(address _newImplementation, uint256 _newVersion) internal {
    address currentImplementation = implementation();
    require(currentImplementation != _newImplementation, "Same Implementation!");
    _setImplementation(_newImplementation);
    emit Upgraded( _newImplementation, _newVersion);
  }
}

contract AngryProxy is UpgradeabilityProxy {
  using ECDSA for bytes32;
  
  bytes32 private constant proxyAdmin1Position = keccak256("angry.app.proxy.admin1");
  bytes32 private constant proxyAdmin2Position = keccak256("angry.app.proxy.admin2");
  bytes32 private constant proxyAdmin3Position = keccak256("angry.app.proxy.admin3");
  bytes32 private constant proxyAdmin4Position = keccak256("angry.app.proxy.admin4");
  bytes32 private constant proxyAdmin5Position = keccak256("angry.app.proxy.admin5");
  bytes32 private constant proxyVersionPosition = keccak256("angry.app.proxy.data");

  function _loadUINT256(bytes32 position) private view returns(uint256 _data){
    bytes32 d;
    assembly {
      d := sload(position)
    }
    _data = uint256(d);
  }
  
  function _loadADDRESS(bytes32 position) private view returns(address _data){
    address d;
    assembly {
      d := sload(position)
    }
    _data = d;
  }
  
  function _saveUINT256(bytes32 position, uint256 _data) private {
    assembly {
      sstore(position, _data)
    }
  }
  
  function _saveADDRESS(bytes32 position, address _data) private {
    assembly {
      sstore(position, _data)
    }
  }
  
  function getVersion() public view returns(uint256 _data){
    return _loadUINT256(proxyVersionPosition);
  }
  
  function setVersion(uint256 _data) private {
    _saveUINT256(proxyVersionPosition, _data);
  }

  /**
  * @dev the constructor sets the original owner of the contract to the sender account.
  */
  constructor(address _implementation, uint256 _version, address _admin1, address _admin2, address _admin3, address _admin4, address _admin5) {
    setVersion(_version);
    _upgradeTo(_implementation, _version);
    _saveADDRESS(proxyAdmin1Position, _admin1);
    _saveADDRESS(proxyAdmin2Position, _admin2);
    _saveADDRESS(proxyAdmin3Position, _admin3);
    _saveADDRESS(proxyAdmin4Position, _admin4);
    _saveADDRESS(proxyAdmin5Position, _admin5);
  }
  
  function verifySig(address _implementation, uint256 _newVersion, bytes[] memory _sigs) private view returns(bool){
    bool[5] memory flags = [false,false,false,false,false];
    bytes32 hash = keccak256(abi.encodePacked(_implementation,_newVersion));
    for(uint256 i = 0;i < _sigs.length; i++){
      address signer = hash.recover(_sigs[i]);
      if(signer == _loadADDRESS(proxyAdmin1Position)){
        flags[0] = true;
      }else if(signer == _loadADDRESS(proxyAdmin2Position)){
        flags[1] = true;
      }else if(signer == _loadADDRESS(proxyAdmin3Position)){
        flags[2] = true;
      }else if(signer == _loadADDRESS(proxyAdmin4Position)){
        flags[3] = true;
      }else if(signer == _loadADDRESS(proxyAdmin5Position)){
        flags[4] = true;
      }
    }
    uint256 cnt = 0; 
    for(uint256 i = 0; i < 5; i++){
      if(flags[i]) cnt += 1;
    }
    if(cnt >= 3) return true;
    return false;
  }

  /**
   * @dev Allows the proxy owner to upgrade the current version of the proxy.
   * @param _implementation representing the address of the new implementation to be set.
   */
  function upgradeTo(address _implementation, uint256 _newVersion, bytes[] memory _sigs) public {
    uint256 currVer = getVersion();
    require( _newVersion > currVer, "Invalid Version!" );
    require( verifySig(_implementation, _newVersion, _sigs), "Verify sig fail!" );
    setVersion(_newVersion);
    _upgradeTo(_implementation, _newVersion);
  }
}