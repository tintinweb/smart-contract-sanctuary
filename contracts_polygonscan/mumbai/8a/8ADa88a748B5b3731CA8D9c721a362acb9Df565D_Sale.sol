// SPDX-License-Identifier:  GNU General Public License v3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IKeys} from "./interface/IKeys.sol";
import {IScroll} from "./interface/IScroll.sol";

/// @title A controller for the entire club sale
/// @notice Contract can be used for the claiming the keys for Atlantis World, and redeeming the keys for scrolls later
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

  /**
   * @notice The mint price for a key
   */
  uint256 public constant MINT_PRICE = 0.2 ether;

  /**
   * @notice `PUBLIC_KEY_LIMIT` + `ADVISORY_KEY_LIMIT` = `TOTAL_SUPPLY` Total Supply
   */
  uint256 public constant PUBLIC_KEY_LIMIT = 6666;
  uint256 public constant ADVISORY_KEY_LIMIT = 303;
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

  /// @notice to keep track if the advisor / user whitelisted has already claimed the NFT
  mapping(address => bool) private _publicSaleClaimedStatus;
  mapping(address => bool) private _advisoryClaimedStatus;

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
    uint256 _stopSaleBlockTimestamp
  ) {
    require(_startSaleBlockTimestamp >= block.timestamp, "Invalid start date");
    require(
      _stopSaleBlockTimestamp >= block.timestamp &&
        _stopSaleBlockTimestamp > _startSaleBlockTimestamp,
      "Invalid stop date"
    );

    whitelistMerkleRoot = _whitelistMerkleRoot;
    advisorMerkleRoot = _advisorMerkleRoot;

    startSaleBlockTimestamp = _startSaleBlockTimestamp;
    stopSaleBlockTimestamp = _stopSaleBlockTimestamp;
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

  /**
   * @notice Emits an event when a timestamp for key swapping for scroll has been set
   */
  event NewStartKeyToScrollSwapTimestamp(uint256 indexed timestamp);

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
   * @notice Validates if the sender has enough ether to mint a key
   */
  modifier canAffordMintPrice() {
    require(msg.value >= MINT_PRICE, "Insufficient payment");
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
    require(block.timestamp > stopSaleBlockTimestamp, "Sale is ongoing");
    _;
  }

  /**
   * @notice Validates if the swapping of key for a scroll is enabled or for when a date is set
   */
  modifier canKeySwapped() {
    require(
      // TODO: To verify with team
      startKeyToScrollSwapTimestamp != 0,
      "A date for swapping hasn't been set"
    );
    require(
      block.timestamp >= startKeyToScrollSwapTimestamp,
      "Please wait for the swapping to begin"
    );
    _;
  }

  /**
   * @notice Mints key, and sends them to the calling user if they are in the Advisory Whitelist
   * @param _proof Merkle proof for the advisory list merkle root
   */
  function preMint(bytes32[] calldata _proof)
    external
    whenNotPaused
    nonReentrant
  {
    require(
      MerkleProof.verify(_proof, advisorMerkleRoot, _leaf(msg.sender)),
      "Not in the advisory list"
    );
    require(!_advisoryClaimedStatus[msg.sender], "Already claimed");
    require(
      advisoryKeyLimitCount < ADVISORY_KEY_LIMIT,
      "Advisory mint limit reached"
    );

    advisoryKeyLimitCount++;
    _advisoryClaimedStatus[msg.sender] = true;

    _keysContract.mintKeyToUser(msg.sender);

    emit KeyAdvisorMinted(msg.sender);
  }

  /**
   * @notice For buying during the public sale, for whitelisted addresses for the sale
   * @param _proof Merkle proof for the whitelist merkle root
   */
  function buyKeyFromSale(bytes32[] calldata _proof)
    external
    payable
    nonReentrant
    canAffordMintPrice
    isSaleOnGoing
  {
    require(
      MerkleProof.verify(_proof, whitelistMerkleRoot, _leaf(msg.sender)),
      "Not eligible"
    );
    require(!_publicSaleClaimedStatus[msg.sender], "Already claimed");
    require(publicKeyMintCount < PUBLIC_KEY_LIMIT, "All minted");

    publicKeyMintCount++;
    _publicSaleClaimedStatus[msg.sender] = true;

    _keysContract.mintKeyToUser(msg.sender);

    emit KeyWhitelistMinted(msg.sender);
  }

  /**
   * @notice
   * For general public to mint tokens, who weren't listed in the
   * whitelist. Will only work for a max of 6969 keys.
   */
  function buyKeyPostSale()
    external
    payable
    nonReentrant
    canAffordMintPrice
    hasSaleEnded
    whenNotPaused
  {
    require(
      publicKeyMintCount + advisoryKeyLimitCount < PUBLIC_KEY_LIMIT,
      "Mint limit reached"
    );

    publicKeyMintCount++;

    _keysContract.mintKeyToUser(msg.sender);

    emit KeyPublicMinted(msg.sender);
  }

  /**
   * @notice To swap the key for scroll on reveal
   */
  function sellKeyForScroll(uint256 _tokenId)
    external
    nonReentrant
    canKeySwapped
    whenNotPaused
  {
    _keysContract.burnKeyOfUser(_tokenId, msg.sender);

    _scrollContract.mint(msg.sender, _tokenId);

    emit KeySwapped(msg.sender, _tokenId);
  }

  /**
   * @notice Minting unminted tokens to treasury
   * @param _treasuryAddress The treasury address for Atlantis World
   */
  function mintLeftOvers(address _treasuryAddress)
    external
    onlyOwner
    whenNotPaused
  {
    // TODO: EIP 2809 implementation
    for (
      uint256 i = 0;
      i < TOTAL_SUPPLY - (publicKeyMintCount + advisoryKeyLimitCount);
      i++
    ) _keysContract.mintKeyToUser(_treasuryAddress);

    publicKeyMintCount = PUBLIC_KEY_LIMIT;
    advisoryKeyLimitCount = ADVISORY_KEY_LIMIT;
  }

  // *************
  // SET FUNCTIONS
  // *************

  /**
   * @notice It sets the timestamp for when key swapping for scrolls is available
   * @dev I noticed that the property `startKeyToScrollSwapTimestamp` was never set anywhere else
   */
  function setStartKeyToScrollSwapTimestamp(uint256 _timestamp)
    external
    onlyOwner
  {
    require(_timestamp >= block.timestamp, "Invalid timestamp");

    startKeyToScrollSwapTimestamp = _timestamp;

    emit NewStartKeyToScrollSwapTimestamp(_timestamp);
  }

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

  function withdraw(address _targetAddress) external onlyOwner {
    address payable targetAddress = payable(_targetAddress);
    targetAddress.transfer(address(this).balance);
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
  function mint(address, uint256) external;
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