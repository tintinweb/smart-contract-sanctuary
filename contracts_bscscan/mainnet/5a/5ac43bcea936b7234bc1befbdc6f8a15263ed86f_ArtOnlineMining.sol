/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}





contract ArtOnlineMiningStorage {
  uint256 internal _blockTime = 60;
  uint internal unlocked = 1;

  uint256[] internal _items;
  uint256[] internal _pools;
  uint256 internal _tax;

  mapping(uint256 => uint256) internal _totalMiners;
  mapping(uint256 => uint256) internal _maxReward;
  mapping(uint256 => address) internal _currency;
  mapping(uint256 => mapping(address => uint256)) internal _miners;
  mapping(uint256 => address[]) internal _miner;
  mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal _bonuses;

  mapping(uint256 => mapping(uint256 => uint256)) internal _mining;
  mapping(uint256 => mapping(uint256 => uint256)) internal _activated;
  mapping(uint256 => mapping(address => uint256)) internal _rewards;
  mapping(uint256 => mapping(address => uint256)) internal _startTime;
  mapping(uint256 => uint256) internal _halvings;
  mapping(uint256 => uint256) internal _nextHalving;
  mapping(uint256 => uint256) internal _activationPrice;

  event AddItem(string name, uint256 id, uint256 maxReward, uint256 halving, address currency, uint256 index);
  event AddPool(string name, uint256 id, uint256 maxReward, uint256 halving, address currency, uint256 index);
  event Activate(address indexed account, uint256 id, uint256 tokenId);
  event Deactivate(address indexed account, uint256 id, uint256 tokenId);
  event ActivateItem(address indexed account, uint256 id, uint256 itemId, uint256 tokenId);
  event DeactivateItem(address indexed account, uint256 id, uint256 itemId, uint256 tokenId);
  event Reward(address account, uint256 id, uint256 reward, address);
  event StakeReward(address account, uint256 id, uint256 reward, bytes32, address);
}


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)



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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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




contract EIP712 {
  bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
  uint256 private immutable _CACHED_CHAIN_ID;

  bytes32 private immutable _HASHED_NAME;
  bytes32 private immutable _HASHED_VERSION;
  bytes32 private immutable _TYPE_HASH;

  constructor(string memory name, string memory version) {
    bytes32 hashedName = keccak256(bytes(name));
    bytes32 hashedVersion = keccak256(bytes(version));
    bytes32 typeHash = keccak256(
      'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
    );
    _HASHED_NAME = hashedName;
    _HASHED_VERSION = hashedVersion;
    _CACHED_CHAIN_ID = block.chainid;
    _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
    _TYPE_HASH = typeHash;
  }

  function _domainSeparatorV4() internal view returns (bytes32) {
    if (block.chainid == _CACHED_CHAIN_ID) {
      return _CACHED_DOMAIN_SEPARATOR;
    } else {
      return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
    }
  }

  function _buildDomainSeparator(bytes32 typeHash, bytes32 nameHash, bytes32 versionHash) private view returns (bytes32) {
    return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
  }

  function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
    return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
  }
}





interface IArtOnline {
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}




interface IArtOnlineBridger {
  function setArtOnline(address _address) external;
  function artOnline() external view returns (address);

  function setArtOnlineExchange(address _address) external;
  function artOnlineExchange() external view returns (address);

  function setArtOnlinePlatform(address _address) external;
  function artOnlinePlatform() external view returns (address);

  function setArtOnlineBlacklist(address _address) external;
  function artOnlineBlacklist() external view returns (address);

  function setArtOnlineMining(address _address) external;
  function artOnlineMining() external view returns (address);

  function setArtOnlineBridge(address _address) external;
  function artOnlineBridge() external view returns (address);

  function setArtOnlineFactory(address _address) external;
  function artOnlineFactory() external view returns (address);

  function setArtOnlineStaking(address _address) external;
  function artOnlineStaking() external view returns (address);

  function setArtOnlineAccess(address _address) external;
  function artOnlineAccess() external view returns (address);

  function setArtOnlineExchangeFactory(address _address) external;
  function artOnlineExchangeFactory() external view returns (address);
}





interface IArtOnlinePlatform {
  function mintAsset(address to, uint256 id) external returns (uint256);
  function ownerOf(uint256 id, uint256 tokenId) external view returns (address);
  function safeTransferFrom(
      address from,
      address to,
      uint256 id,
      uint256 amount,
      bytes memory data
  ) external ;
  function safeBatchTransferFrom(
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
  ) external ;
}




interface IArtOnlineAccess {
  function isAdmin(address account) external returns (bool);
  function isMinter(address account) external returns (bool);
}




interface IArtOnlineStakingInterface {
  function stake(address account, uint256 amount, address) external returns (bytes32);
  function holders(address) external returns (address[] memory);
}




interface IArtOnlineBlacklist {
  function blacklist(address account, bool blacklist_) external;
  function blacklisted(address account) external view returns (bool);
}








contract SetArtOnlineMining {

  IArtOnline internal _artOnlineInterface;
  IArtOnlineBridger internal _artOnlineBridgerInterface;
  IArtOnlinePlatform internal _artOnlinePlatformInterface;
  IArtOnlineStakingInterface internal _artOnlineStakingInterface;
  IArtOnlineAccess internal _artOnlineAccessInterface;
  IArtOnlineBlacklist internal _artOnlineBlacklistInterface;

  modifier isWhiteListed(address account) {
    require(_artOnlineBlacklistInterface.blacklisted(account) == false, 'BLACKLISTED');
    _;
  }

  modifier onlyAdmin() {
    require(_artOnlineAccessInterface.isAdmin(msg.sender) == true, 'NO_PERMISSION');
    _;
  }

  modifier onlyMinter() {
    require(_artOnlineAccessInterface.isMinter(msg.sender) == true, 'NO_PERMISSION');
    _;
  }

  constructor(address artOnlineBridger_, address artOnlineAccess_) {
    _artOnlineBridgerInterface = IArtOnlineBridger(artOnlineBridger_);
    _artOnlineAccessInterface = IArtOnlineAccess(artOnlineAccess_);
  }

  function artOnlineBridgerInterface() external view returns (address) {
    return address(_artOnlineBridgerInterface);
  }

  function artOnlineInterface() external view  returns (address) {
    return address(_artOnlineInterface);
  }

  function artOnlinePlatformInterface() external view  returns (address) {
    return address(_artOnlinePlatformInterface);
  }

  function artOnlineStakingInterface() external view  returns (address) {
    return address(_artOnlineStakingInterface);
  }

  function artOnlineAccessInterface() external view  returns (address) {
    return address(_artOnlineAccessInterface);
  }

  function setArtOnlineBridgerInterface(address _artOnlineBridger) external onlyAdmin() {
    _artOnlineBridgerInterface = IArtOnlineBridger(_artOnlineBridger);
    address _artOnline = _artOnlineBridgerInterface.artOnline();
    address _artOnlinePlatform = _artOnlineBridgerInterface.artOnlinePlatform();
    address _artOnlineStaking = _artOnlineBridgerInterface.artOnlineStaking();
    address _artOnlineAccess = _artOnlineBridgerInterface.artOnlineAccess();
    address _artOnlineBlacklist = _artOnlineBridgerInterface.artOnlineBlacklist();

    if (address(_artOnlineInterface) != _artOnline) {
      _setArtOnlineInterface(_artOnline);
    }
    if (address(_artOnlinePlatformInterface) != _artOnlinePlatform) {
      _setArtOnlinePlatformInterface(_artOnlinePlatform);
    }
    if (address(_artOnlineStakingInterface) != _artOnlineStaking) {
      _setArtOnlineStakingInterface(_artOnlineStaking);
    }
    if (address(_artOnlineAccessInterface) != _artOnlineAccess) {
      _setArtOnlineAccessInterface(_artOnlineAccess);
    }

    if (address(_artOnlineBlacklistInterface) != _artOnlineBlacklist) {
      _setArtOnlineBlacklistInterface(_artOnlineBlacklist);
    }
  }

  function _setArtOnlineInterface(address _artOnline) internal {
    _artOnlineInterface = IArtOnline(_artOnline);
  }

  function _setArtOnlinePlatformInterface(address _artOnlinePlatform) internal {
    _artOnlinePlatformInterface = IArtOnlinePlatform(_artOnlinePlatform);
  }

  function _setArtOnlineStakingInterface(address _artOnlineStaking) internal {
    _artOnlineStakingInterface = IArtOnlineStakingInterface(_artOnlineStaking);
  }

  function _setArtOnlineAccessInterface(address _artOnlineAccess) internal {
    _artOnlineAccessInterface = IArtOnlineAccess(_artOnlineAccess);
  }

  function _setArtOnlineBlacklistInterface(address _artOnlineBlacklist) internal {
    _artOnlineBlacklistInterface = IArtOnlineBlacklist(_artOnlineBlacklist);
  }

  function setArtOnlineInterface(address _address) external onlyAdmin() {
    _setArtOnlineInterface(_address);
  }

  function setArtOnlinePlatformInterface(address _address) external onlyAdmin() {
    _setArtOnlinePlatformInterface(_address);
  }

  function setArtOnlineStakingInterface(address _address) external onlyAdmin() {
    _setArtOnlineStakingInterface(_address);
  }

  function setArtOnlineAccessInterface(address _address) external onlyAdmin() {
    _setArtOnlineAccessInterface(_address);
  }

  function setArtOnlineBlacklistInterface(address _address) external onlyAdmin() {
    _setArtOnlineBlacklistInterface(_address);
  }
}








contract ArtOnlineMining is Context, EIP712, SetArtOnlineMining, ArtOnlineMiningStorage  {
  using Address for address;

  modifier lock() {
    require(unlocked == 1, 'LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
  }

  constructor(string memory name, string memory version, address bridger, address access)
    EIP712(name, version)
    SetArtOnlineMining(bridger, access) {}

  function mining(uint256 id, uint256 tokenId) external view virtual returns (uint256) {
    return _mining[id][tokenId];
  }

  function _addAsset(uint256 id, uint256 maxReward_, uint256 halving, address currency_) internal {
    require(_maxReward[id] == 0, 'ASSET_EXISTS');
    _maxReward[id] = maxReward_;
    _halvings[id] = halving;
    unchecked {
      _nextHalving[id] = block.timestamp + halving;
    }
    _currency[id] = currency_;
  }

  function addItem(string memory name, uint256 id, uint256 bonus, uint256 halving, address currency_) public onlyAdmin() {
    _addAsset(id, bonus, halving, currency_);
    _items.push(id);
    emit AddItem(name, id, bonus, halving, currency_, _items.length - 1);
  }

  function addPool(string memory name, uint256 id, uint256 maxReward, uint256 halving, address currency_) public onlyAdmin() {
    _addAsset(id, maxReward, halving, currency_);
    _pools.push(id);
    emit AddPool(name, id, maxReward, halving, currency_, _pools.length - 1);
  }

  function _rewardPerGPU(uint256 id) internal view returns (uint256) {
    if (_totalMiners[id] == 0) {
      return 0;
    }
    return _maxReward[id] / _totalMiners[id];
  }

  function setActivationPrice(uint256 id, uint256 price) external onlyAdmin() {
    _activationPrice[id] = price;
  }

  function activationPrice(uint256 id) public view returns (uint256) {
    return _activationPrice[id];
  }

  function setHalvings(uint256 id, uint256 halving_) external onlyAdmin() {
    _halvings[id] = halving_;
  }

  function getHalvings(uint256 id) public view returns (uint256) {
    return _halvings[id];
  }

  function getNextHalving(uint256 id) public view returns (uint256) {
    return _nextHalving[id];
  }

  function rewards(address account, uint256 id) public view returns (uint256) {
    return _rewards[id][account];
  }

  function rewardPerGPU(uint256 id) public view returns (uint256) {
    return _rewardPerGPU(id);
  }

  function getMaxReward(uint256 id) public view returns (uint256) {
    return _maxReward[id];
  }

  function earned(address account, uint256 id) public returns (uint256) {
    return _calculateReward(account, id);
  }

  function miners(uint256 id) public view virtual returns (uint256) {
    return _totalMiners[id];
  }

  function _updateRewards(address sender, uint256 id) internal returns (uint256 reward) {
    for (uint256 i = 0; i < _miner[id].length; i++) {
      address account = _miner[id][i];
      if (account == sender) {
        reward = _calculateReward(account, id);
      } else {
        _calculateReward(account, id);
      }
    }
    return reward;
  }

  function activateGPUBatch(address sender, uint256[] memory ids, uint256[] memory amounts) external {
    for (uint256 i = 0; i < ids.length; i++) {
      activateGPU(sender, ids[i], amounts[i]);
    }
  }

  function deactivateGPUBatch(address sender, uint256[] memory ids, uint256[] memory amounts) external {
    for (uint256 i = 0; i < ids.length; i++) {
      deactivateGPU(sender, ids[i], amounts[i]);
    }
  }

  function activateGPU(address sender, uint256 id, uint256 tokenId) public isWhiteListed(sender) lock {
    _beforeAction(sender, id, tokenId);
    _updateRewards(sender, id);
    _activateGPU(sender, id, tokenId);
    emit Activate(sender, id, tokenId);
  }

  function deactivateGPU(address sender, uint256 id, uint256 tokenId) public isWhiteListed(sender) lock {
    _beforeAction(sender, id, tokenId);
    _updateRewards(sender, id);
    _deactivateGPU(sender, id, tokenId);
    emit Deactivate(sender, id, tokenId);
  }

  function activateItem(address sender, uint256 id, uint256 itemId, uint256 tokenId) external isWhiteListed(sender) lock {
    _beforeAction(sender, itemId, tokenId);
    uint256 price = activationPrice(itemId);
    _artOnlineInterface.burn(sender, price);
    _updateRewards(sender, id);
    _activateItem(sender, id, itemId, tokenId);
    emit ActivateItem(sender, id, itemId, tokenId);
  }

  function deactivateItem(address sender, uint256 id, uint256 itemId, uint256 tokenId) external isWhiteListed(sender) lock {
    _beforeAction(sender, itemId, tokenId);
    uint256 price = activationPrice(itemId);
    _artOnlineInterface.burn(sender, price);
    _updateRewards(sender, id);
    _deactivateItem(sender, id, itemId, tokenId);
    emit DeactivateItem(sender, id, itemId, tokenId);
  }

  function getReward(address sender, uint256 id) public isWhiteListed(sender) {
    uint256 reward = _calculateReward(sender, id);
    if (reward > 0) {
      uint256 taxed = (reward / 100) * _tax;
      IArtOnline minter = IArtOnline(_currency[id]);
      minter.mint(sender, reward - taxed);

      address[] memory holders_ = _artOnlineStakingInterface.holders(_currency[id]);
      if (holders_.length > 0) {
        uint256 dividends = (taxed / 100) * 5;
        uint256 dividend = dividends / holders_.length;
        for (uint256 i = 0; i < holders_.length; i++) {
          minter.mint(holders_[i], dividend);
        }
      }
      _rewards[id][sender] = 0;
      _startTime[id][sender] = block.timestamp;
      emit Reward(sender, id, reward - taxed, _currency[id]);
    }
  }

  function stakeReward(address sender, uint256 id) external isWhiteListed(sender) lock returns (bytes32) {
    bytes32 stakeId;
    uint256 reward = _calculateReward(sender, id);
    if (reward > 0) {
      stakeId = _artOnlineStakingInterface.stake(sender, reward, _currency[id]);
      _rewards[id][sender] = 0;
      _startTime[id][sender] = block.timestamp;
      emit StakeReward(sender, id, reward, stakeId, _currency[id]);
    }
    return stakeId;
  }

  function stakeRewardBatch(address sender, uint256[] memory ids) external isWhiteListed(sender) lock returns (bytes32[] memory stakeIds) {
    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 reward = _calculateReward(sender, id);
      if (reward > 0) {
        _artOnlineInterface.mint(sender, reward);
        bytes32 stakeId = _artOnlineStakingInterface.stake(sender, reward, _currency[id]);
        stakeIds[i] = stakeId;
        _rewards[id][sender] = 0;
        _startTime[id][sender] = block.timestamp;
        emit StakeReward(sender, id, reward, stakeId, _currency[id]);
      }
    }
  }

  function getRewardBatch(address sender, uint256[] memory ids) external isWhiteListed(sender) {
    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 reward = _calculateReward(sender, id);
      if (reward > 0) {
        uint256 taxed = (reward / 100) * _tax;
        uint256 dividends = (taxed / 100) * 5;
        IArtOnline minter = IArtOnline(_currency[id]);
        minter.mint(sender, reward - taxed);
        address[] memory holders_ = _artOnlineStakingInterface.holders(_currency[id]);
        if (holders_.length > 0) {
          uint256 dividend = dividends / holders_.length;
          for (uint256 holder = 0; holder < holders_.length; holder++) {
            minter.mint(holders_[holder], dividend);
          }
        }
        _rewards[id][sender] = 0;
        _startTime[id][sender] = block.timestamp;
        emit Reward(sender, id, reward - taxed, _currency[id]);
      }
    }
  }

  function itemBonus(uint256 id) external view returns (uint256) {
    return _maxReward[id];
  }

  function _itemBonuses(address sender, uint256 id) internal view returns (uint256) {
    uint256 percentage;

    for (uint256 i = 0; i < _items.length; i++) {
      uint256 itemId = _items[i];
      if (_bonuses[id][sender][itemId] > 0) {
        percentage = percentage + (_maxReward[itemId] * _bonuses[id][sender][itemId]);
      }

    }
    return percentage;
  }

  function _calculateReward(address sender, uint256 id) internal returns (uint256) {
    uint256 startTime = _startTime[id][sender];
    if (block.timestamp > startTime + _blockTime) {
      unchecked {
        uint256 remainder = block.timestamp - startTime;
        uint256 reward = (_rewardPerGPU(id) * _miners[id][sender]) * remainder;
        _rewards[id][sender] = _rewards[id][sender] + (reward + ((reward / 100) * _itemBonuses(sender, id)));
      }
      _startTime[id][sender] = block.timestamp;
    }
    return _rewards[id][sender];
  }

  function _beforeAction(address account, uint256 id, uint256 tokenId) internal {
    require(tokenId > 0, "NO_ZERO");
    if (_artOnlineAccessInterface.isAdmin(msg.sender) != true) {
      require(_artOnlinePlatformInterface.ownerOf(id, tokenId) == account, 'NOT_OWNER');
    }
  }

  function _activateItem(address account, uint256 id, uint256 itemId, uint256 tokenId) internal {
    require(_miners[id][account] > _bonuses[id][account][itemId], 'UPGRADE_CAP');
    require(_activated[itemId][tokenId] == 0, 'DEACTIVATE_FIRST');
    unchecked {
      _bonuses[id][account][itemId] += 1;
      _activated[itemId][tokenId] = 1;
    }
    _checkHalving(id);
    _rewardPerGPU(id);
  }

  function _deactivateItem(address account, uint256 id, uint256 itemId, uint256 tokenId) internal {
    require(_activated[itemId][tokenId] == 0, 'NOT_ACTIVATED');
    unchecked {
      _bonuses[id][account][itemId] -= 1;
      _activated[itemId][tokenId] = 0;
    }
    _checkHalving(id);
    _rewardPerGPU(id);
  }

  function _activateGPU(address account, uint256 id, uint256 tokenId) internal {
    if (_miners[id][account] == 0) {
      _miner[id].push(account);
    }
    unchecked {
      _startTime[id][account] = block.timestamp;
      _miners[id][account] += 1;
      _miner[id].push(account);
    }
    _mining[id][tokenId] = 1;
    _totalMiners[id] += 1;
    _checkHalving(id);
    _rewardPerGPU(id);
  }

  function _removeMiner(address account, uint256 id) internal {
    uint256 index;
    for (uint256 i = 0; i < _miner[id].length; i++) {
      if (_miner[id][i] == account) {
        index = i;
      }
    }
    if (index >= _miner[id].length) return;
    _miner[id][index] = _miner[id][_miner[id].length - 1];
    _miner[id].pop();
  }

  function _deactivateGPU(address account, uint256 id, uint256 tokenId) internal {
    unchecked {
      _miners[id][account] -= 1;
      _totalMiners[id] -= 1;
      _mining[id][tokenId] = 0;
    }

    if (_miners[id][account] == 0) {
      delete _startTime[id][account];
      _removeMiner(account, id);
    } else {
      _startTime[id][account] = block.timestamp;
    }
    for (uint256 i = 0; i < _items.length; i++) {
      uint256 itemId = _items[i];
      require(_bonuses[id][account][itemId] == 0, 'Deactivate upgrades first');
    }
    _checkHalving(id);
    _rewardPerGPU(id);
  }

  function _checkHalving(uint256 id) internal {
    uint256 timestamp = block.timestamp;
    if (timestamp > _nextHalving[id]) {
      unchecked {
        _nextHalving[id] = timestamp + _halvings[id];
        _maxReward[id] = _maxReward[id] / 2;
      }
    }
  }

  function poolsLength() external view virtual returns (uint256) {
    return _pools.length;
  }

  function itemsLength() external view virtual returns (uint256) {
    return _items.length;
  }

  function pools() external view virtual returns (uint256[] memory) {
    return _pools;
  }

  function items() external view virtual returns (uint256[] memory) {
    return _items;
  }

  function pool(uint256 id) external view virtual returns (uint256) {
    return _pools[id];
  }

  function item(uint256 id) external view virtual returns (uint256) {
    return _items[id];
  }

  function bonuses(uint256 id, address account, uint256 tokenId) external view returns (uint256) {
    return _bonuses[id][account][tokenId];
  }

  function activated(uint256 id, uint256 tokenId) external view returns (uint256) {
    return _activated[id][tokenId];
  }

  function poolInfo(address sender, uint256 id) external returns (uint256[] memory) {
    uint256[] memory _poolInfo = new uint256[](4);
    _poolInfo[0] = _totalMiners[id];
    _poolInfo[1] = _maxReward[id];
    _poolInfo[2] = _calculateReward(sender, id);
    _poolInfo[3] = _nextHalving[id];
    return _poolInfo;
  }

  function setTax(uint256 tax_) external onlyAdmin() {
    _tax = tax_;
  }

  function tax() external view returns (uint256) {
    return _tax;
  }

}