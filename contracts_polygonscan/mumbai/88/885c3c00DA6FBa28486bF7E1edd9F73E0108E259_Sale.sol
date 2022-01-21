// SPDX-License-Identifier:  GNU General Public License v3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IKeys} from "./interface/IKeys.sol";
import {IScroll} from "./interface/IScroll.sol";

/// @title A controller for the entire club sale
/// @notice Contract can be used for the claiming the keys for Atlantis World, and redeeming the keys for scrolls later
/// @author Rachit Anand Srivastava, Carlo Miguel Dy
/// @dev All function calls are implemented with side effects on the key and scroll contracts
contract Sale is Ownable, Pausable, ReentrancyGuard {
  /**
   * @notice Key contracts
   */
  IKeys private _keysContract;
  IScroll private _scrollContract;

  /**
   * @notice All the merkle roots - whitelist address and advisor addresses
   */
  bytes32 private whitelistMerkleRoot;
  bytes32 private advisorMerkleRoot;

  address private publicVerificationAddress;

  /**
   * @notice The mint price for a key = 0.22 ETH
   */
  uint256 public constant MINT_PRICE = (22 * 1e18) / 100;

  /// @notice WETH Contract
  IERC20 WETH;

  /**
   * @notice 9700 + 299 = 9999 Total Supply
   * @notice `PUBLIC_KEY_LIMIT` + `ADVISORY_KEY_LIMIT` = `TOTAL_SUPPLY` Total Supply
   */
  uint256 public constant PUBLIC_KEY_LIMIT = 9700;
  uint256 public constant ADVISORY_KEY_LIMIT = 299;
  uint256 public constant TOTAL_SUPPLY = PUBLIC_KEY_LIMIT + ADVISORY_KEY_LIMIT;

  /**
   * @notice The current mint count from public users
   */
  uint256 public publicKeyMintCount = 0;

  /**
   * @notice The current mint count from advisory users
   */
  uint256 public advisoryKeyLimitCount = 0;

  /**
   * @notice The timestamp for when the alpha sale launches
   */
  uint256 public startSaleBlockTimestamp;

  /**
   * @notice The timestamp for when the alpha sale stops
   */
  uint256 public stopSaleBlockTimestamp;

  /// @notice For assigning an address the right to withdraw funds
  address private targetAddress;

  /// @notice to keep track if the advisor / user whitelisted has already claimed the NFT
  mapping(address => bool) private _publicSaleClaimedStatus;
  mapping(address => bool) private _advisoryClaimedStatus;

  /// @notice to keep track of used nonces during the public sale
  mapping(string => bool) private _usedNonces;

  /// @dev Keeps track of the mint count for the minter address
  mapping(address => uint256) private _addressToMintCount;

  /**
   * @notice The timestamp for when swapping keys for a scroll begins
   */
  uint256 public startKeyToScrollSwapTimestamp;

  /**
   * @param _whitelistMerkleRoot The merkle root of whitelisted candidates
   * @param _advisorMerkleRoot The merkle root of advisor addresses
   * @param _startSaleBlockTimestamp The start sale timestamp
   * @param _stopSaleBlockTimestamp The stop sale timestamp
   */
  constructor(
    bytes32 _whitelistMerkleRoot,
    bytes32 _advisorMerkleRoot,
    uint256 _startSaleBlockTimestamp,
    uint256 _stopSaleBlockTimestamp,
    address _publicVerification,
    IERC20 _WETH
  ) {
    require(_startSaleBlockTimestamp >= block.timestamp, "Invalid start date");
    require(
      _stopSaleBlockTimestamp >= block.timestamp &&
        _stopSaleBlockTimestamp > _startSaleBlockTimestamp,
      "Invalid stop date"
    );

    publicVerificationAddress = _publicVerification;
    whitelistMerkleRoot = _whitelistMerkleRoot;
    advisorMerkleRoot = _advisorMerkleRoot;

    startSaleBlockTimestamp = _startSaleBlockTimestamp;
    stopSaleBlockTimestamp = _stopSaleBlockTimestamp;
    WETH = _WETH;
  }

  /**
   * @notice Emits an event when an advisor have minted
   */
  event KeyAdvisorMinted(address indexed sender);

  /**
   * @notice Emits an event when a whitelisted user have minted
   */
  event KeyWhitelistMinted(address indexed sender);

  /**
   * @notice Emits an event when someone have minted after the sale
   */
  event KeyPublicMinted(address indexed sender);

  /**
   * @notice Emits an event when a key has been swapped for a scroll
   */
  event KeySwapped(address indexed sender, uint256 indexed tokenId);

  /**
   * @notice Emits an event when a new Keys contract address has been set
   */
  event NewKeysAddress(address indexed keys);

  /**
   * @notice Emits an event when a new Scroll contract address has been set
   */
  event NewScrollAddress(address indexed scroll);

  /// @notice When a new whitelist merkle root is set
  event NewWhitelistMerkleRootSet(uint256 indexed timestamp);

  /// @notice When a new advisory merkle root is set
  event NewAdvisoryMerkleRootSet(uint256 indexed timestamp);

  /**
   * @notice Validates if the given address is not an empty address
   */
  modifier notAddressZero(address _address) {
    require(address(0x0) != _address, "Must not be an empty address");
    _;
  }

  /**
   * @notice Validates if the current block timestamp is still under the sale timestamp range
   */
  modifier isSaleOnGoing() {
    require(
      block.timestamp >= startSaleBlockTimestamp,
      "Sale has not started yet"
    );
    require(block.timestamp <= stopSaleBlockTimestamp, "Sale is over");
    _;
  }

  /**
   * @notice Validates if the current block timestamp is outside the sale timestamp range
   */
  modifier hasSaleEnded() {
    require(saleEnded(), "Sale is ongoing");
    _;
  }

  /**
   * @dev Lookup function to check if the Alpha Sale is on-going.
   */
  function saleOnGoing() public view returns (bool) {
    return
      block.timestamp >= startSaleBlockTimestamp &&
      block.timestamp <= stopSaleBlockTimestamp;
  }

  /**
   * @dev Lookup function to check if the Alpha Sale has ended.
   */
  function saleEnded() public view returns (bool) {
    return block.timestamp > stopSaleBlockTimestamp;
  }

  /**
   * @dev Gets the current mint count of an address.
   * @param minter The minter's address
   */
  function getAddressMintCount(address minter) external view returns (uint256) {
    return _addressToMintCount[minter];
  }

  /**
   * @dev Checks if the sender is whitelisted
   */
  function isAlphaSaleWhitelist(bytes32[] calldata _proof)
    public
    view
    returns (bool)
  {
    return MerkleProof.verify(_proof, whitelistMerkleRoot, _leaf(msg.sender));
  }

  /**
   * @dev Checks if the sender is whitelisted
   */
  function isAdvisoryWhitelist(bytes32[] calldata _proof)
    public
    view
    returns (bool)
  {
    return MerkleProof.verify(_proof, advisorMerkleRoot, _leaf(msg.sender));
  }

  /// @notice compares the recovered signer address using the hash to the public address of the signing key
  function matchAddressSigner(bytes32 hash, bytes memory signature)
    public
    view
    returns (bool)
  {
    return ECDSA.recover(hash, signature) == (publicVerificationAddress);
  }

  /**
   * @notice Mints key, and sends them to the calling user if they are in the Advisory Whitelist
   * @param _proof Merkle proof for the advisory list merkle root
   */
  function advisoryMint(bytes32[] calldata _proof)
    external
    whenNotPaused
    nonReentrant
  {
    require(isAdvisoryWhitelist(_proof), "Not in the advisory list");
    require(!_advisoryClaimedStatus[msg.sender], "Already claimed");
    require(
      advisoryKeyLimitCount < ADVISORY_KEY_LIMIT,
      "Advisory mint limit reached"
    );

    advisoryKeyLimitCount++;
    _advisoryClaimedStatus[msg.sender] = true;
    _addressToMintCount[msg.sender]++;

    _keysContract.mintKeyToUser(msg.sender);

    emit KeyAdvisorMinted(msg.sender);
  }

  /**
   * @notice For buying during the public sale, for whitelisted addresses for the sale
   * @param _proof Merkle proof for the whitelist merkle root
   */
  function buyKeyFromSale(bytes32[] calldata _proof)
    external
    nonReentrant
    isSaleOnGoing
  {
    require(isAlphaSaleWhitelist(_proof), "Not eligible");
    require(!_publicSaleClaimedStatus[msg.sender], "Already claimed");
    require(publicKeyMintCount < PUBLIC_KEY_LIMIT, "All minted");
    require(
      WETH.transferFrom(msg.sender, address(this), MINT_PRICE),
      "Not allowed or low funds"
    );

    publicKeyMintCount++;
    _publicSaleClaimedStatus[msg.sender] = true;
    _addressToMintCount[msg.sender]++;

    _keysContract.mintKeyToUser(msg.sender);

    emit KeyWhitelistMinted(msg.sender);
  }

  /**
   * @notice
   * For general public to mint tokens, who weren't listed in the
   * whitelist. Will only work for a max of 9696 keys.
   */
  function buyKeyPostSale(string calldata nonce, bytes calldata signature)
    external
    nonReentrant
    hasSaleEnded
    whenNotPaused
  {
    require(publicKeyMintCount < PUBLIC_KEY_LIMIT, "Mint limit reached");
    require(
      matchAddressSigner(hashTransaction(msg.sender, nonce), signature),
      "Signature Verification Failed"
    );
    require(_addressToMintCount[msg.sender] <= 3, "You can only mint 3 times.");
    require(!_usedNonces[nonce], "Hash Already Used");
    require(
      WETH.transferFrom(msg.sender, address(this), MINT_PRICE),
      "Not allowed or low funds"
    );

    _usedNonces[nonce] = true;
    publicKeyMintCount++;
    _addressToMintCount[msg.sender]++;

    _keysContract.mintKeyToUser(msg.sender);

    emit KeyPublicMinted(msg.sender);
  }

  /**
   * @notice To swap the key for scroll on reveal
   */
  function sellKeyForScroll(uint256 _tokenId)
    external
    nonReentrant
    whenNotPaused
  {
    _keysContract.burnKeyOfUser(_tokenId, msg.sender);

    bool isAdvisoryMinter = _advisoryClaimedStatus[msg.sender];

    _scrollContract.mint(msg.sender, isAdvisoryMinter);

    emit KeySwapped(msg.sender, _tokenId);
  }

  /**
   * @notice Minting unminted tokens to treasury
   * @dev EIP2309 hasn't been implemented due to lack of clarity on implementation. The EIP only specifies the event, not the implementation.
   * @param _treasuryAddress The treasury address for Atlantis World
   */
  function mintLeftOvers(address _treasuryAddress)
    external
    onlyOwner
    whenNotPaused
  {
    for (
      uint256 i = 0;
      i < TOTAL_SUPPLY - (publicKeyMintCount + advisoryKeyLimitCount);
      i++
    ) _keysContract.mintKeyToUser(_treasuryAddress);

    publicKeyMintCount = PUBLIC_KEY_LIMIT;
    advisoryKeyLimitCount = ADVISORY_KEY_LIMIT;
  }

  /// @notice to generate the hash using the nonce and the msg.sender
  function hashTransaction(address sender, string memory nonce)
    private
    pure
    returns (bytes32)
  {
    bytes32 hash = keccak256(abi.encodePacked(sender, nonce));

    return ECDSA.toEthSignedMessageHash(hash);
  }

  // *************
  // SET FUNCTIONS
  // *************

  /**
   * @notice Sets a new merkle root for all whitelisted addresses
   */
  function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    whitelistMerkleRoot = _merkleRoot;

    emit NewWhitelistMerkleRootSet(block.timestamp);
  }

  /**
   * @notice Sets a new merkle root for the advisory list
   */
  function setAdvisorMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    advisorMerkleRoot = _merkleRoot;

    emit NewAdvisoryMerkleRootSet(block.timestamp);
  }

  /**
   * @param _address Key contract address
   */
  function setKeysAddress(address _address)
    external
    onlyOwner
    notAddressZero(_address)
  {
    _keysContract = IKeys(_address);

    emit NewKeysAddress(_address);
  }

  /**
   * @param _address Scroll contract address
   */
  function setScrollAddress(address _address)
    external
    onlyOwner
    notAddressZero(_address)
  {
    _scrollContract = IScroll(_address);

    emit NewScrollAddress(_address);
  }

  // ***************
  // PAUSE FUNCTIONS
  // ***************

  function pauseContract() external onlyOwner whenNotPaused {
    _pause();
  }

  function unpauseContract() external onlyOwner whenPaused {
    _unpause();
  }

  /**
   * @param _sender The address whose leaf hash needs to be generated
   * @return The hash value of the sender address
   */
  function _leaf(address _sender) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_sender));
  }

  /**
   * @dev Set the address to where funds gets transferred into.
   */
  function setWithdrawalAddress(address _targetAddress) external onlyOwner {
    targetAddress = _targetAddress;
  }

  /**
   * @dev Withdraws the amount of funds received to the `targetAddress`
   */
  function withdraw() external onlyOwner {
    require(msg.sender == targetAddress, "Not the assigned address.");
    require(
      targetAddress != address(0),
      "The assigned address is an empty address."
    );

    WETH.transferFrom(
      address(this),
      targetAddress,
      WETH.balanceOf(address(this))
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

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
abstract contract Pausable is Context {
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
    constructor() {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IKeys {
  function mintKeyToUser(address) external;

  function burnKeyOfUser(uint256, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IScroll {
  function mint(address, bool) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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