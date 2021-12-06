// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IAlunaverse.sol";

/// @title Alunaverse Minter
/// @notice Minter contract for Alunaverse NFT collection, supports ECDSA Signature based whitelist minting, and public access minting.
contract AlunaverseMinter is Ownable {
  using ECDSA for bytes32;

  /// @dev The Alunaverse ERC1155 contract
  IAlunaverse public Alunaverse;

  /// @dev Mapping between tokenId and mint price
  mapping(uint256 => uint256) public tokenMintPrice;

  /// @dev Mapping between tokenId and whether public minting is enabled, if false the only whitelisted minting is permitted
  mapping(uint256 => bool) public tokenPublicSaleEnabled;

  /// @dev Keeps track of how many of each token a wallet has minted, used for enforing wallet limits for whitelist minting
  mapping(address => mapping(uint256 => uint256)) public whitelistMinted;

  /// @dev The public address of the authorized signer used to create the whitelist mint signature
  address public whitelistSigner;

  address payable public withdrawalAddress;

  /// @dev used for decoding the whitelist mint signature
  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private WHITELIST_TYPEHASH =
    keccak256("whitelistMint(address buyer,uint256 tokenId,uint256 limit)");

  constructor(address alunaverseAddress) {
    Alunaverse = IAlunaverse(alunaverseAddress);

    withdrawalAddress = payable(msg.sender);

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("AlunaverseMinter")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  /// @notice Allows the contract owner to update the mint price for the specified token
  /// @param tokenId The token to update
  /// @param mintPrice The new mint price
  function updateTokenMintPrice(uint256 tokenId, uint256 mintPrice)
    public
    onlyOwner
  {
    tokenMintPrice[tokenId] = mintPrice;
  }

  /// @notice Allows the contract owner to toggle whether public minting is permitted for the specified token
  /// @param tokenId The token to update
  function toggleTokenPublicSale(uint256 tokenId) public onlyOwner {
    tokenPublicSaleEnabled[tokenId] = !tokenPublicSaleEnabled[tokenId];
  }

  /// @notice Allows the contract owner to set a new whitelist signer
  /// @dev The corresponding private key of the whitelist signer should be used to generate the signature for whitelisted addresses
  /// @param newWhitelistSigner Address of the new whitelist signer
  function updateWhitelistSigner(address newWhitelistSigner) public onlyOwner {
    whitelistSigner = newWhitelistSigner;
  }

  /// @notice Allows the contract owner to set the address where withdrawals should go
  /// @param newAddress The new withdrawal address
  function updateWithdrawalAddress(address payable newAddress)
    external
    onlyOwner
  {
    withdrawalAddress = newAddress;
  }

  /// @notice External function for whitelisted addresses to mint
  /// @param signature The signature produced by the whitelist signer to validate that the msg.sender is on the approved whitelist
  /// @param tokenId The token to mint
  /// @param numberOfTokens The number of tokens to mint
  /// @param approvedLimit The total approved number of tokens that the msg.sender is allowed to mint, this number is also validated by the signature
  function whitelistMint(
    bytes memory signature,
    uint256 tokenId,
    uint256 numberOfTokens,
    uint256 approvedLimit
  ) external payable {
    require(whitelistSigner != address(0), "NO_WHITELIST_SIGNER");
    require(
      msg.value == tokenMintPrice[tokenId] * numberOfTokens,
      "INCORRECT_PAYMENT"
    );
    require(
      (whitelistMinted[msg.sender][tokenId] + numberOfTokens) <= approvedLimit,
      "WALLET_LIMIT_EXCEEDED"
    );
    whitelistMinted[msg.sender][tokenId] =
      whitelistMinted[msg.sender][tokenId] +
      numberOfTokens;

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(WHITELIST_TYPEHASH, msg.sender, tokenId, approvedLimit)
        )
      )
    );

    address signer = digest.recover(signature);

    require(
      signer != address(0) && signer == whitelistSigner,
      "INVALID_SIGNATURE"
    );

    Alunaverse.mint(msg.sender, tokenId, numberOfTokens);
  }

  /// @notice External function for anyone to mint, as long as tokenPublicSaleEnabled = true
  /// @param tokenId The token to mint
  /// @param numberOfTokens The number of tokens to mint
  function publicMint(uint256 tokenId, uint256 numberOfTokens)
    external
    payable
  {
    require(tokenPublicSaleEnabled[tokenId], "PUBLIC_SALE_DISABLED");
    require(
      msg.value == tokenMintPrice[tokenId] * numberOfTokens,
      "INCORRECT_PAYMENT"
    );

    Alunaverse.mint(msg.sender, tokenId, numberOfTokens);
  }

  /// @notice Allows the contract owner to withdraw the current balance stored in this contract into withdrawalAddress
  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "ZERO_BALANCE");

    (bool success, ) = withdrawalAddress.call{ value: address(this).balance }(
      ""
    );
    require(success, "WITHDRAWAL_FAILED");
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

// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

interface IAlunaverse {

  /// @notice Mint a specified amount of a single token to a single address
  /// @param to The recipient address for the newly minted tokens
  /// @param tokenId The token to mint
  /// @param amount The number of tokens to mint
  function mint(
    address to,
    uint256 tokenId,
    uint256 amount
  ) external;

  /// @notice Mint specified amounts of multiple tokens in one transaction to a single address
  /// @param to The recipient address for the newly minted tokens
  /// @param tokenIds An array of IDs for tokens to mint
  /// @param amounts As array of amounts of tokens to mint, corresponding to the tokenIds
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external;

  /// @notice Mint specified amounts of a single token to multiple addresses
  /// @param recipients An array of addresses to received the newly minted tokens
  /// @param tokenId The token to mint
  /// @param amounts As array of the number of tokens to mint to each address
  function mintToMany(
    address[] calldata recipients,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external;

  function totalSupply(uint256 tokenId) external view returns (uint256);
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