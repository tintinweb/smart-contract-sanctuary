pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./UseAccessControl.sol";
import "./DerivedMetadataRegistry.sol";
import "./mixin/MixinSignature.sol";
import "./mixin/MixinPausable.sol";
import "./interface/IERC20.sol";
import "./mixin/MixinOwnable.sol";

contract AffirmationWriter is Ownable, MixinSignature, MixinPausable, UseAccessControl {

  DerivedMetadataRegistry public derivedMetadataRegistry;

  bytes32 public immutable organizerRole;
  bytes32 public immutable historianRole;

  IERC20 public immutable tipToken;

  uint256 public minimumQuorumAffirmations;
  
  uint256 public constant VERSION = 2;

  address payable public historianTipJar;

  mapping(bytes32 => bool) public affirmationHashRegistry;
  mapping(bytes32 => bool) public tipHashRegistry;
  

  constructor(
    address _accessControl,
    address _derivedMetadataRegistry,
    address payable _historianTipJar,
    address _tipToken,
    bytes32 _organizerRole,
    bytes32 _historianRole
  ) UseAccessControl(_accessControl) {
    derivedMetadataRegistry = DerivedMetadataRegistry(_derivedMetadataRegistry);
    organizerRole = _organizerRole;
    historianRole = _historianRole;
    historianTipJar = _historianTipJar;
    tipToken = IERC20(_tipToken);
  }

	struct Affirmation {
		uint256 salt;
    address signer;
    bytes signature;
	}

	struct Tip {
    uint256 version;
		bytes32 writeHash;
    address tipper;
    uint256 value;
    bytes signature;
	}

	struct Write {
    uint256 tokenId;
    string key;
		string text;
    uint256 salt;
	}

  event Affirmed(
      uint256 indexed tokenId,
      address indexed signer,
      string indexed key,
      bytes32 affirmationHash,
      uint256 salt,
      bytes signature
  );

  event Tipped(
      bytes32 indexed writeHash,
      address indexed tipper,
      uint256 value,
      bytes signature
  );

  function getWriteHash(Write calldata _write) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_write.tokenId, _write.key, _write.text, _write.salt));
  }

  function getAffirmationHash(bytes32 _writeHash, Affirmation calldata _affirmation) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_writeHash, _affirmation.signer, _affirmation.salt));
  }

  function getTipHash(Tip calldata _tip) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_tip.version, _tip.writeHash, _tip.tipper, _tip.value));
  }

  function verifyAffirmation(
    bytes32 writeHash, Affirmation calldata _affirmation 
  ) public pure returns (bool) {
    bytes32 signedHash = getAffirmationHash(writeHash, _affirmation);
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_affirmation.signature);
    return isSigned(_affirmation.signer, signedHash, v, r, s);
  }

  function verifyTip(
    Tip calldata _tip 
  ) public pure returns (bool) {
    bytes32 signedHash = getTipHash(_tip);
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_tip.signature);
    return _tip.version == VERSION && isSigned(_tip.tipper, signedHash, v, r, s);
  }

  function updateMinimumQuorumAffirmations(uint256 _minimumQuorumAffirmations) public onlyRole(organizerRole) {
    minimumQuorumAffirmations = _minimumQuorumAffirmations;
  }

  function updateHistorianTipJar(address payable _historianTipJar) public onlyRole(organizerRole) {
    historianTipJar = _historianTipJar;
  }

  function pause() public onlyRole(organizerRole) {
    _pause();
  }

  function unpause() public onlyRole(organizerRole) {
    _unpause();
  } 

  function write(Write calldata _write, Affirmation[] calldata _affirmations, Tip calldata _tip) public whenNotPaused {
    bytes32 writeHash = getWriteHash(_write);

    uint256 numValidAffirmations = 0;
    for (uint256 i = 0; i < _affirmations.length; ++i) {
      Affirmation calldata affirmation = _affirmations[i];
      // once an affirmation is created and used on-chain it can't be used again
      bytes32 affirmationHash = getAffirmationHash(writeHash, affirmation);
      require(affirmationHashRegistry[affirmationHash] == false, "Affirmation has already been received");
      affirmationHashRegistry[affirmationHash] = true;
      require(verifyAffirmation(writeHash, affirmation) == true, "Affirmation doesn't have valid signature");
      _checkRole(historianRole, affirmation.signer);
      numValidAffirmations++;
      emit Affirmed(_write.tokenId, affirmation.signer, _write.key, affirmationHash, affirmation.salt, affirmation.signature ); 
    }

    require(numValidAffirmations >= minimumQuorumAffirmations, "Minimum affirmations not met");
    _writeDocument(_write);
    _settleTip(writeHash, _tip);
  }

  function _writeDocument(Write calldata _write) internal {
    string[] memory keys = new string[](1);
    string[] memory texts = new string[](1);
    address[] memory writers = new address[](1);
    keys[0] = _write.key;
    texts[0] = _write.text;
    writers[0] = address(this);
    derivedMetadataRegistry.writeDocuments(_write.tokenId, keys, texts, writers); 
  }

  function settleTip(bytes32 writeHash, Tip calldata _tip) public onlyRole(historianRole) {
    _settleTip(writeHash, _tip);
  }

  function _settleTip(bytes32 writeHash, Tip calldata _tip) internal {
    if (_tip.value != 0) {
      require (writeHash == _tip.writeHash, 'Tip is not for write');
      bytes32 tipHash = getTipHash(_tip);
      require(tipHashRegistry[tipHash] == false, "Tip has already been used");
      tipHashRegistry[tipHash] = true;
      require(verifyTip(_tip) == true, "Tip doesn't have valid signature");
      tipToken.transferFrom(_tip.tipper, historianTipJar, _tip.value);
      emit Tipped(_tip.writeHash, _tip.tipper, _tip.value, _tip.signature);
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./interface/IAccessControl.sol";
import "./utils/Strings.sol";

contract UseAccessControl {
  IAccessControl public accessControl;

  constructor(address _accessControl) {
    accessControl = IAccessControl(_accessControl);
  }

  modifier onlyRole(bytes32 role) {
      _checkRole(role, msg.sender);
      _;
  }

  function _checkRole(bytes32 role, address account) internal view {
    if (!accessControl.hasRole(role, account)) {
        revert(
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(uint160(account), 20),
                    " is missing role ",
                    Strings.toHexString(uint256(role), 32)
                )
            )
        );
    }
  }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./mixin/MixinOwnable.sol";
import "./library/LibString.sol";
import "./interface/IMetadataRegistry.sol";

contract DerivedMetadataRegistry is Ownable, IMetadataRegistry {
  IMetadataRegistry public immutable sourceRegistry;

  mapping(uint256 => mapping(string => IMetadataRegistry.Document)) public tokenIdToDocumentMap;
  mapping(address => bool) public permissedWriters;

  constructor(address sourceRegistry_) {
    sourceRegistry = IMetadataRegistry(sourceRegistry_);
  }

  event UpdatedDocument(
      uint256 indexed tokenId,
      address indexed writer,
      string indexed key,
      string text
  );

  function updatePermissedWriterStatus(address _writer, bool status) public onlyOwner {
    permissedWriters[_writer] = status;
  }

  modifier onlyIfPermissed(address writer) {
    require(permissedWriters[writer] == true, "writer can't write to registry");
    _;
  }

  function writeDocuments(uint256 tokenId, string[] memory keys, string[] memory texts, address[] memory writers) public onlyIfPermissed(msg.sender) {
    require(keys.length == texts.length, "keys and txHashes size mismatch");
    require(writers.length == texts.length, "writers and texts size mismatch");
    for (uint256 i = 0; i < keys.length; ++i) {
      string memory key = keys[i];
      string memory text = texts[i];
      address writer = writers[i];
      tokenIdToDocumentMap[tokenId][key] = IMetadataRegistry.Document(writer, text, block.timestamp);
      emit UpdatedDocument(tokenId, writer, key, text); 
    }
  }

  function tokenIdToDocument(uint256 tokenId, string memory key) override external view returns (IMetadataRegistry.Document memory) {
    IMetadataRegistry.Document memory sourceDoc = sourceRegistry.tokenIdToDocument(tokenId, key);
    if (bytes(sourceDoc.text).length == 0) {
      return IMetadataRegistry.Document(address(0), "", 0);
    }
    IMetadataRegistry.Document memory doc = tokenIdToDocumentMap[tokenId][sourceDoc.text];
    return doc; 
  }
}

pragma solidity ^0.7.0;


contract MixinSignature {
  function splitSignature(bytes memory sig)
      public pure returns (bytes32 r, bytes32 s, uint8 v)
  {
      require(sig.length == 65, "invalid signature length");

      assembly {
          r := mload(add(sig, 32))
          s := mload(add(sig, 64))
          v := byte(0, mload(add(sig, 96)))
      }

      if (v < 27) v += 27;
  }

  function isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) public pure returns (bool) {
      return _isSigned(_address, messageHash, v, r, s) || _isSignedPrefixed(_address, messageHash, v, r, s);
  }

  function _isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
      internal pure returns (bool)
  {
      return ecrecover(messageHash, v, r, s) == _address;
  }

  function _isSignedPrefixed(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
      internal pure returns (bool)
  {
      bytes memory prefix = "\x19Ethereum Signed Message:\n32";
      return _isSigned(_address, keccak256(abi.encodePacked(prefix, messageHash)), v, r, s);
  }
  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract MixinPausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

library LibString {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function uint2hexstr(uint i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            uint curr = (i & mask);
            bstr[k--] = curr > 9 ? byte(uint8(55 + curr)) : byte(uint8(48 + curr));
            i = i >> 4;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IMetadataRegistry {
  struct Document {
		address writer;
		string text;
		uint256 creationTime;
	}

  function tokenIdToDocument(uint256 tokenId, string memory key) external view returns (Document memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/*
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

    function _txOrigin() internal view virtual returns (address) {
        return tx.origin;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}