/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// 
/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// 
/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
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

// 
/********************************************************************
 * This smart contract was developed and deployed by: collectID, AG *
 * Please send any and all inquiries to: [email protected]          *
 ********************************************************************/
interface ICollectIdEvents {

  event EnableType(
    uint256 indexed typeId
  );

  event CreateEvent(
    uint256 indexed eventId,
    uint256 indexed tokenId,
    uint256 indexed typeId,
    bytes data
  );

  event Endorse(
    address indexed endorser,
    uint256 indexed eventId
  );

  function eventIds(
    uint256 _tokenId
  ) external view returns (uint256[] memory);

  function typeId(
    uint256 _eventId
  ) external view returns (uint256);

  function eventData(
    uint256 _eventId
  ) external view returns (bytes memory);

  function eventEndorsers(
    uint256 _eventId
  ) external view returns (address[] memory);

  function enableType(
    uint256 _typeId
  ) external;

  function createEvent(
    uint256 _tokenId,
    uint256 _typeId,
    bytes calldata _data
  ) external;

  function endorse(
    uint256 _eventId
  ) external;

  function safeEndorse(
    uint256 _eventId,
    uint256 _tokenId,
    uint256 _typeId
  ) external;

  function createEventFor(
    bytes calldata _delegationSig,
    uint256 _tokenId,
    uint256 _typeId,
    bytes calldata _data,
    address _endorser
  ) external;

  function mintAndCreateEventFor(
    address _to,
    string calldata _tokenURI,
    bytes calldata _delegationSig,
    uint256 _tokenId,
    uint256 _typeId,
    bytes calldata _data,
    address _endorser
  ) external;

  function endorseFor(
    bytes calldata _delegationSig,
    uint256 _eventId,
    address _endorser
  ) external;

  function safeEndorseFor(
    bytes calldata _delegationSig,
    uint256 _eventId,
    uint256 _tokenId,
    uint256 _typeId,
    address _endorser
  ) external;
}

// 
/********************************************************************
 * This smart contract was developed and deployed by: collectID, AG *
 * Please send any and all inquiries to: [email protected]          *
 ********************************************************************/
interface ICollectIdCore {
  event DelegateTransfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  function exists(uint256 _tokenId) external view returns (bool);
  function tokenURI(uint256 _tokenId) external view returns (string memory);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function supportsInterface(bytes4 _interfaceId) external returns (bool);

  function burn(
    uint256 _tokenId
  ) external;

  function mint(
    address _to,
    uint256 _tokenId
  ) external;

  function mint(
    address _to,
    uint256 _tokenId,
    string calldata _tokenURI
  ) external;

  function mintMany(
    address _to,
    uint256[] calldata _tokenIds,
    string[] calldata _tokenURIs
  ) external;

  function transferFor(
    bytes calldata _delegationSig,
    address _from,
    address _to,
    uint256 _tokenId
  ) external;
}

// 
/********************************************************************
 * This smart contract was developed and deployed by: collectID, AG *
 * Please send any and all inquiries to: [email protected]          *
 ********************************************************************/
contract CollectIdEvents is ICollectIdEvents {
  using ECDSA for bytes32;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
  bytes32 public constant ENDORSER_ROLE = keccak256("ENDORSER_ROLE");

  ICollectIdCore public core;
  IAccessControl public accessControl;
  uint256 public totalEvents;
  mapping(uint256 => bool) public typeEnabled;

  mapping(uint256 => uint256) private _eventTypeIds;
  mapping(uint256 => bytes) private _eventData;
  mapping(uint256 => address[]) private _eventEndorsers;
  mapping(uint256 => uint256[]) private _tokenEventIds;

  constructor(address _core) {
    core = ICollectIdCore(_core);
    accessControl = IAccessControl(_core);
  }

  /*****************************************************************
   * @dev Modifier than reverts if referenced token does not exist *
   * @param _tokenId uint256 ID of the token                       *
   *****************************************************************/
  modifier tokenExists(uint256 _tokenId) {
    core.ownerOf(_tokenId);
    _;
  }

  /********************************************************************
   * @dev Modifier than reverts if caller does not have specific role *
   * @param _role bytes32 hash unique identifying the role            *
   ********************************************************************/
  modifier onlyRole(bytes32 _role) {
    require(accessControl.hasRole(_role, msg.sender), "Insufficient permissions");
    _;
  }

  /*****************************************************************************************
   * @dev Returns an array of event IDs associated with a specified collectID token        *
   * @dev Returns an empty array if token ID does not exist in the collectID core contract *
   * @param _tokenId uint256 ID of the token                                               *
   *****************************************************************************************/
  function eventIds(uint256 _tokenId) public view override returns (uint256[] memory) {
    return _tokenEventIds[_tokenId];
  }

  /******************************************************
   * @dev Returns the type ID of a specified event      *
   * @dev Reverts if the specified event does not exist *
   * @param _eventId uint256 ID of the event            *
   ******************************************************/
  function typeId(uint256 _eventId) public view override returns (uint256) {
    require(_eventId < totalEvents, "Event ID is out of range");

    return _eventTypeIds[_eventId];
  }

  /******************************************************
   * @dev Returns the byte data of a specified event    *
   * @dev Reverts if the specified event does not exist *
   * @param _eventId uint256 ID of the event            *
   ******************************************************/
  function eventData(uint256 _eventId) public view override returns (bytes memory) {
    require(_eventId < totalEvents, "Event ID is out of range");

    return _eventData[_eventId];
  }

  /***********************************************************
   * @dev Returns the list of endorsers of a specified event *
   * @dev Reverts if the specified event does not exist      *
   * @param _eventId uint256 ID of the event                 *
   ***********************************************************/
  function eventEndorsers(uint256 _eventId) public view override returns (address[] memory) {
    require(_eventId < totalEvents, "Event ID is out of range");

    return _eventEndorsers[_eventId];
  }

  /******************************************************************
   * @dev Only admin function for setting the core contract         *
   * @param _contract address to be set as the core ERC721 contract *
   ******************************************************************/
  function setCore(address _contract) public onlyRole(DEFAULT_ADMIN_ROLE) {
    core = ICollectIdCore(_contract);
  }

  /*********************************************************************
   * @dev Only admin function for setting the access control contract  *
   * @param _contract address to be set as the access control contract *
   *********************************************************************/
  function setAccessControl(address _contract) public onlyRole(DEFAULT_ADMIN_ROLE) {
    accessControl = IAccessControl(_contract);
  }

  /*****************************************************************
   * @dev Public function to create a new event type               *
   * @dev Emits a EnableType event that includes the ID            *
   * @param _typeId uint256 keccak256 hash of the type description *
   *****************************************************************/
  function enableType(uint256 _typeId)
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(!typeEnabled[_typeId], "Type already enabled");

    typeEnabled[_typeId] = true;

    emit EnableType(_typeId);
  }

  /****************************************************
   * @dev Private function to create a new event type *
   ****************************************************/
  function _createEvent(
    uint256 _tokenId,
    uint256 _typeId,
    bytes memory _data,
    address _endorser
  ) private {
    require(typeEnabled[_typeId], "Type is not enabled");

    uint256 eventId = totalEvents;
    _tokenEventIds[_tokenId].push(eventId);
    _eventTypeIds[eventId] = _typeId;
    _eventData[eventId] = _data;
    totalEvents += 1;

    emit CreateEvent(eventId, _tokenId, _typeId, _data);

    _endorse(eventId, _endorser);
  }

  /****************************************************************************************
   * @dev Public function to create a new event; sender is the initial endorser           *
   * @dev Emits a CreateEvent event that includes the ID, token ID, type ID, and data     *
   * @dev Reverts if the specified event type ID does not exist                           *
   * @dev Reverts if the specified token ID does not exist in the collectID core contract *
   * @param _tokenId uint256 ID of the token associated with the event                    *
   * @param _typeId uint256 ID of the event type                                          *
   * @param _data bytes data for additional event details                                 *
   ****************************************************************************************/
  function createEvent(
    uint256 _tokenId,
    uint256 _typeId,
    bytes memory _data
  )
    public
    override
    onlyRole(ENDORSER_ROLE)
    tokenExists(_tokenId)
  {
    _createEvent(_tokenId, _typeId, _data, msg.sender);
  }

  /***********************************************************************
   * @dev Public function to endorse a specified event                   *
   * @dev Emits an Endorse event that includes the endorser and event ID *
   * @dev Reverts if the specified event ID does not exist               *
   * @param _eventId uint256 ID of the event to endorse                  *
   ***********************************************************************/
  function endorse(uint256 _eventId)
    public
    override
    onlyRole(ENDORSER_ROLE)
  {
    _endorse(_eventId, msg.sender);
  }

  /******************************************************
   * @dev Private function to endorse a specified event *
   ******************************************************/
  function _endorse(uint256 _eventId, address _endorser) private {
    require(_eventId < totalEvents, "Event ID is out of range");

    _eventEndorsers[_eventId].push(_endorser);

    emit Endorse(_endorser, _eventId);
  }

  /******************************************************************************************
   * @dev Public function to safely endorse a specified event at a higher gas cost          *
   * @dev Emits an Endorse event that includes the endorser and event ID                    *
   * @dev Reverts if the specified event ID does not exist                                  *
   * @dev Reverts if the specified event type ID does not match that of the specified event *
   * @dev Reverts if the specified token ID is not associated with the specified event      *
   * @dev Reverts if the sender address has already endorsed the specified event            *
   * @param _eventId uint256 ID of the event to endorse                                     *
   * @param _tokenId uint256 ID of the token associated with the event                      *
   * @param _typeId uint256 ID of the event type                                            *
   ******************************************************************************************/
  function safeEndorse(
    uint256 _eventId,
    uint256 _tokenId,
    uint256 _typeId
  )
    public
    override
    onlyRole(ENDORSER_ROLE)
    tokenExists(_tokenId)
  {
    _safeEndorse(_eventId, _tokenId, _typeId, msg.sender);
  }

  /**********************************************************************************
   * @dev Private function to safely endorse a specified event at a higher gas cost *
   **********************************************************************************/
  function _safeEndorse(
    uint256 _eventId,
    uint256 _tokenId,
    uint256 _typeId,
    address _endorser
  ) private {
    require(_eventTypeIds[_eventId] == _typeId, "Event is not the expected type");
    require(_eventExists(_eventId, _tokenId), "Event is not associated with this token ID");

    _endorse(_eventId, _endorser);
  }

  /***************************************************************************************************
   * @dev Private function that returns whether or not an event is associated with a specified token *
   * @dev Returns false if the specified token does not exist in the collectID core contract         *
   ***************************************************************************************************/
  function _eventExists(uint256 _eventId, uint256 _tokenId) private view returns (bool) {
    for (uint8 i = 0; i < _tokenEventIds[_tokenId].length; i++) {
      if (_tokenEventIds[_tokenId][i] == _eventId) {
        return true;
      }
    }
    return false;
  }

  /********************************************************************************************
   * @dev Private function to verify that the address recovered from the delegation signature *
   * @dev matches the signer address claimed by the transaction sender                        *
   * @dev Reverts if the recovered signer does not match the claimed signer                   *
   ********************************************************************************************/
  function _verifySigner(
    bytes32 _delegationDigest,
    bytes memory _delegationSig,
    address _claimedSigner
  ) private pure {
    address _signer = ECDSA.recover(_delegationDigest, _delegationSig);
    require(_claimedSigner == _signer, "Signature does not match claimed signer address");
  }

  /*****************************************************************************************************
   * @dev Public function to call "createEvent" on behalf of another address                           *
   * @dev The address that signed the delegation signature is the initial endorser                     *
   * @dev Reverts if the decoded delegation signature does not match the provided function argument    *
   * @dev Emits a CreateEvent event that includes the ID, token ID, type ID, and data                  *
   * @param _delegationSig bytes transaction data encoded as ['CreateEvent', _tokenId, _typeId, _data] *
   * @param _tokenId uint256 ID of the token associated with the event                                 *
   * @param _typeId uint256 ID of the event type                                                       *
   * @param _data bytes data for additional event details                                              *
   * @param _creator address that signed the delegation signature                                      *
   *****************************************************************************************************/
  function createEventFor(
    bytes memory _delegationSig,
    uint256 _tokenId,
    uint256 _typeId,
    bytes memory _data,
    address _creator
  )
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    bytes32 _delegationDigest = ECDSA.toEthSignedMessageHash(
      keccak256(abi.encode("CreateEvent", _tokenId, _typeId, _data))
    );
    _verifySigner(_delegationDigest, _delegationSig, _creator);
    _createEvent(_tokenId, _typeId, _data, _creator);
  }

  function mintAndCreateEventFor(
    address _to,
    string memory _tokenURI,
    bytes memory _delegationSig,
    uint256 _tokenId,
    uint256 _typeId,
    bytes memory _data,
    address _creator
  )
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    core.mint(_to, _tokenId, _tokenURI);
    createEventFor(_delegationSig, _tokenId, _typeId, _data, _creator);
  }

  /***************************************************************************************************
   * @dev Public function to call "endorse" on behalf of another address                             *
   * @dev Reverts if the decoded delegation signature does not match the provided function arguments *
   * @dev Emits an Endorse event that includes the endorser and event ID                             *
   * @param _delegationSig bytes transaction data encoded as ['Endorse', _eventId]                   *
   * @param _eventId uint256 ID of the event to endorse                                              *
   * @param _endorser address that signed the delegation signature                                   *
   ***************************************************************************************************/
  function endorseFor(
    bytes memory _delegationSig,
    uint256 _eventId,
    address _endorser
  )
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    bytes32 _delegationDigest = ECDSA.toEthSignedMessageHash(
      keccak256(abi.encode("Endorse", _eventId))
    );
    _verifySigner(_delegationDigest, _delegationSig, _endorser);
    _endorse(_eventId, _endorser);
  }

  /********************************************************************************************************
   * @dev Public function to call "safeEndorse" on behalf of another address                              *
   * @dev Reverts if the decoded delegation signature does not match the provided function arguments      *
   * @dev Emits an Endorse event that includes the endorser and event ID                                  *
   * @param _delegationSig bytes transaction data encoded as ['SafeEndorse', _eventId, _tokenId, _typeId] *
   * @param _eventId uint256 ID of the event to endorse                                                   *
   * @param _tokenId uint256 ID of the token associated with the event                                    *
   * @param _typeId uint256 ID of the event type                                                          *
   * @param _endorser address that signed the delegation signature                                        *
   ********************************************************************************************************/
  function safeEndorseFor(
    bytes memory _delegationSig,
    uint256 _eventId,
    uint256 _tokenId,
    uint256 _typeId,
    address _endorser
  )
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    bytes32 _delegationDigest = ECDSA.toEthSignedMessageHash(
      keccak256(abi.encode("SafeEndorse", _eventId, _tokenId, _typeId))
    );
    _verifySigner(_delegationDigest, _delegationSig, _endorser);
    _safeEndorse(_eventId, _tokenId, _typeId, _endorser);
  }
}