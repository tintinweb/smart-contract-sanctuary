//SPDX-License-Identifier: MIT
// contracts/ERC721.sol

pragma solidity >=0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IBrainDrops {
   function mint(address recipient, uint _projectId) external payable returns (uint256);

   function updateProjectArtistName(uint256 _projectId, string memory _projectArtistName) external;

   function updateProjectDescription(uint256 _projectId, string memory _projectDescription) external;

   function updateProjectWebsite(uint256 _projectId, string memory _projectWebsite) external;

   function updateProjectLicense(uint256 _projectId, string memory _projectLicense) external;

   function updateProjectBaseURI(uint256 _projectId, string memory _projectBaseURI) external;

   function toggleProjectIsPaused(uint256 _projectId) external;

   function setProvenanceHash(uint256 _projectId, string memory provenanceHash) external;

   function tokenIdToProjectId(uint256 tokenId) external view returns (uint256 projectId);

   function projectIdToBaseURI(uint256 projectId) external view returns (string memory baseURI);

   function balanceOf(address owner) external view returns (uint256 balance);

   function ownerOf(uint256 tokenId) external view returns (address owner);

   function transferFrom(address from, address to, uint256 tokenId) external;

   function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract ArtistProxy is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    constructor(address _braindrops) {
      // TODO: refer to original whitelist instead? (shared whitelist)
      isWhitelisted[msg.sender] = true;
      braindrops = IBrainDrops(_braindrops);
    }

    IBrainDrops public braindrops;

    mapping(uint256 => mapping(address => bool)) public  projectIdToGenesisDropAddressMinted;
    mapping(uint256 => mapping(address => bool)) public projectIdToProjectAntiBotAddressMinted;

    mapping(uint256 => address) public projectIdToArtistAddress;
    mapping(uint256 => bool) public projectIdToProjectActivated;
    mapping(uint256 => bool) public projectIdToProjectAntiBotActivated;
    mapping(uint256 => bool) public projectIdToHolderActivated;
    mapping(uint256 => bool) public projectIdToGenesisDropActivated;

    mapping(uint256 => uint256) public projectIdToOlderProjectId;
    mapping(uint256 => uint256) public projectIdToBurnableProjectId;
    mapping(uint256 => address) public projectIdToBotPreventionAddress;

    mapping(address => bool) public isWhitelisted;

    address public signingAddress;

    modifier onlyArtist(uint256 _projectId) {
        require(msg.sender == projectIdToArtistAddress[_projectId], "Only artist");
        _;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted[msg.sender], "Only whitelisted");
        _;
    }

    modifier onlyHolders(uint256 _projectId) {
        require(braindrops.balanceOf(msg.sender) > 0, "Holders only");
        _;
    }

    function setSigningAddress(address _signingAddress) public onlyWhitelisted {
        signingAddress = _signingAddress;
    }

    function setArtist(uint projectId, address artistAddress) public onlyWhitelisted {
        // todo: require project is not locked // whatever bd does
        projectIdToArtistAddress[projectId] = artistAddress;
    }

    function updateProjectArtistName(uint256 _projectId, string memory _projectArtistName) onlyArtist(_projectId) public {
        braindrops.updateProjectArtistName(_projectId, _projectArtistName);
    }

    function updateProjectDescription(uint256 _projectId, string memory _projectDescription) onlyArtist(_projectId) public {
        braindrops.updateProjectDescription(_projectId, _projectDescription);
    }

    function updateProjectWebsite(uint256 _projectId, string memory _projectWebsite) onlyArtist(_projectId) public {
        braindrops.updateProjectWebsite(_projectId, _projectWebsite);
    }

    function updateProjectLicense(uint256 _projectId, string memory _projectLicense) onlyArtist(_projectId) public {
        braindrops.updateProjectLicense(_projectId, _projectLicense);
    }

    function updateProjectBaseURI(uint256 _projectId, string memory _projectBaseURI) onlyArtist(_projectId) public {
        braindrops.updateProjectBaseURI(_projectId, _projectBaseURI);
    }

    // allows unpausing of OG drop mechanics.
    function toggleProjectIsPaused(uint256 _projectId) public onlyArtist(_projectId) {
        braindrops.toggleProjectIsPaused(_projectId);
    }

    function setProvenanceHash(uint256 _projectId, string memory provenanceHash) public onlyArtist(_projectId) {
        braindrops.setProvenanceHash(_projectId, provenanceHash);
    }

    function toggleProjectIsActive(uint256 _projectId) public onlyArtist(_projectId) {
        projectIdToProjectActivated[_projectId] = true;
    }

    function toggleProjectAntiBotActivated(uint256 _projectId) public onlyArtist(_projectId) {
        projectIdToProjectAntiBotActivated[_projectId] = true;
    }

    function toggleProjectIsHolderActive(uint256 _projectId) public onlyArtist(_projectId) {
        projectIdToHolderActivated[_projectId] = true;
    }

    function toggleProjectIsGenesisDropActive(uint256 _projectId) public onlyArtist(_projectId) {
        projectIdToGenesisDropActivated[_projectId] = true;
    }

    function setProjectIdToOlderProjectId(uint256 _projectId, uint256 _olderProjectId) public onlyArtist(_projectId) {
        projectIdToOlderProjectId[_projectId] = _olderProjectId;
    }

    function setProjectIdToBurnableProjectId(uint256 _projectId, uint256 _olderProjectId) public onlyArtist(_projectId) {
        projectIdToBurnableProjectId[_projectId] = _olderProjectId;
    }

    function _validatePurchaseRequest(bytes32 message, bytes calldata signature, uint _projectId) internal virtual {
        require(projectIdToProjectAntiBotAddressMinted[_projectId][msg.sender] == false, "Cannot replay transaction");

        bytes32 expectedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", '20', msg.sender));

        require(message == expectedMessage, "Malformed message");

        address signer = message.recover(signature);
        require(signer == signingAddress, "Invalid signature");

        projectIdToProjectAntiBotAddressMinted[_projectId][msg.sender] = true;
    }

  function mintForServerSigned(address recipient, uint _projectId, bytes32 message, bytes calldata signature)
        public
        payable
        nonReentrant
        returns (uint256)
      {
          require(projectIdToProjectAntiBotActivated[_projectId], "Project must be active for anti-bot minting");
          _validatePurchaseRequest(message, signature, _projectId);

          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  // allows project-specific holders to mint on burn
  function mintForProjectBurnersOnly(address recipient, uint _projectId, uint _tokenId)
        public
        payable
        nonReentrant
        returns (uint256)
      {
          uint burnableProjectId = projectIdToBurnableProjectId[_projectId];
          require(burnableProjectId > 0, "Project must be active for project-holder burn-mints");

          require(braindrops.tokenIdToProjectId(_tokenId) == burnableProjectId, "token must belong to burnable project");
          require(braindrops.ownerOf(_tokenId) == msg.sender, "token to burn must belong to msg.sender");

          // TODO: approve first.
          //   braindrops.transferFrom(msg.sender, address(0), _tokenId);

          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  // allows artists to mint while project is not fully activated
  function mintForArtistsOnly(address recipient, uint _projectId)
        public
        payable
        onlyArtist(_projectId)
        returns (uint256)
      {
          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  // allows project-specific holders to mint
  function mintForProjectSpecificHoldersOnly(address recipient, uint _projectId)
        public
        payable
        nonReentrant
        returns (uint256)
      {
          uint olderProjectId = projectIdToOlderProjectId[_projectId];
          require(olderProjectId > 0, "Project must be active for project-holder specific mints");

          uint senderBalance = braindrops.balanceOf(msg.sender);

          bool olderProjectHolder = false;

          for (uint i = 0; i < senderBalance; i++) {
            uint ownedProjectId = braindrops.tokenIdToProjectId(braindrops.tokenOfOwnerByIndex(msg.sender, i));

            if (ownedProjectId == olderProjectId) {
                olderProjectHolder = true;
                break;
            }
          }

          require(olderProjectHolder, "Project specific holders only");

          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  // allows genesis drop holders to mint
  function mintForGenesisDropHoldersOnly(address recipient, uint _projectId)
        public
        payable
        nonReentrant
        returns (uint256)
      {
          require(projectIdToGenesisDropActivated[_projectId], "Project must be active for genesis set holders");
          require(projectIdToGenesisDropAddressMinted[_projectId][msg.sender] == false, "One mint per address");

          uint senderBalance = braindrops.balanceOf(msg.sender);
          require(senderBalance > 2, "Full genesis drop holders only");

          bool project1Owner = false;
          bool project2Owner = false;
          bool project3Owner = false;

          for (uint i = 0; i < senderBalance; i++) {
            uint ownedProjectId = braindrops.tokenIdToProjectId(braindrops.tokenOfOwnerByIndex(msg.sender, i));

            if (ownedProjectId == 1) {
                project1Owner = true;
            } else if (ownedProjectId == 2) {
                project2Owner = true;
            } else if (ownedProjectId == 3) {
                project3Owner = true;
            }

            if (project1Owner && project2Owner && project3Owner) {
                break;
            }
          }

          require((project1Owner && project2Owner && project3Owner), "Full genesis drop holders only");

          projectIdToGenesisDropAddressMinted[_projectId][msg.sender] = true;
          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  // allows holders to mint
  function mintForHoldersOnly(address recipient, uint _projectId)
        public
        payable
        nonReentrant
        onlyHolders(_projectId)
        returns (uint256)
      {
          require(projectIdToHolderActivated[_projectId], "Project must be active for holders");

          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

  // allows anyone to mint once the project has been activated by the artist
  function mint(address recipient, uint _projectId)
        public
        payable
        nonReentrant
        returns (uint256)
      {
          require(projectIdToProjectActivated[_projectId] || msg.sender == projectIdToArtistAddress[_projectId], "Project must be active");

          return braindrops.mint{value: msg.value}(recipient, _projectId);
      }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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