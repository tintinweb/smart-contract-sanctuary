// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IHNDGame.sol";
import "./interfaces/IKingdom.sol";
import "./interfaces/ITraits.sol";
import "./interfaces/Iexp.sol";
import "./interfaces/IHND.sol";
import "./interfaces/IShop.sol";



contract HNDGame is IHNDGame, Ownable, ReentrancyGuard, Pausable {

  event MintCommitted(address indexed owner, uint256 indexed amount);
  event MintRevealed(address indexed owner, uint256 indexed amount);

  struct MintCommit {
    bool stake;
    uint16 amount;
  }

  // Maximum price in EXP of the final game mints
  uint256 private maxExpCost = 105000 ether;

  // pricing
  uint256 public presalePrice = 0.07 ether;
  uint256 public publicSalePrice = 0.08 ether;


  // address -> commit # -> commits
  mapping(address => mapping(uint16 => MintCommit)) private _mintCommits;

  // address -> commit num of commit need revealed for account
  mapping(address => uint16) private _pendingCommitId;

  // commit # -> offchain random
  mapping(uint16 => uint256) private _commitRandoms;


  // whitelisted address => number of tokens minted during whitelist.
  // if address did not mint then they will not be in this list.
  mapping(address => uint256) private _whitelistClaims;

  // root of the merkle trie constructed from whitelist claimants
  bytes32 private whitelistMerkleRoot;

  uint16 private _commitBatch = 1;

  uint16 private pendingMintAmt;

  bool public isPublicSale;

  // address => can call addCommitRandom
  mapping(address => bool) private admins;


  // reference to the Kingdom for choosing random Demon thieves
  IKingdom public kingdom;

  ITraits public traits;

  IEXP public expToken;

  IHND public HNDNFT;

  address private kingdomAddr;

  address private treasury;

  // reference to loot
  IShop public shop;

  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(expToken) != address(0) && address(traits) != address(0) 
        && address(expToken) != address(0) && address(kingdom) != address(0) && address(shop) != address(0)
        , "Contracts not set");
      _;
  }

  modifier requireEOA() {
    require(tx.origin == _msgSender(), "Only EOA");

    _;
  }

  function setContracts(address _exp, address _traits, address _HND, address _kingdom, address _shop) external onlyOwner {
    expToken = IEXP(_exp);
    traits = ITraits(_traits);
    HNDNFT = IHND(_HND);
    kingdom = IKingdom(_kingdom);
    kingdomAddr = _kingdom;
    shop = IShop(_shop);
  }


  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  function setWhitelistMerkleRoot(bytes32 root) external onlyOwner {
    whitelistMerkleRoot = root;
  }

  /** EXTERNAL */

  function getPendingMint(address addr) external view returns (MintCommit memory) {
    require(_pendingCommitId[addr] != 0, "no pending commits");
    return _mintCommits[addr][_pendingCommitId[addr]];
  }

  function hasMintPending(address addr) external view returns (bool) {
    return _pendingCommitId[addr] != 0;
  }

  function canMint(address addr) external view returns (bool) {
    return _pendingCommitId[addr] != 0 && _commitRandoms[_pendingCommitId[addr]] > 0;
  }

  // Seed the current commit id so that pending commits can be revealed
  function addCommitRandom(uint256 seed, bytes32 parentBlockHash) external {
    require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");

    if (parentBlockHash != "") {
      // we poll to get the previous blockhash and continually submit tx until it's included
      // no gas waste as flashbots rpc fails if tx will revert
      require(blockhash(block.number - 1) == parentBlockHash, "block was uncled");
    }
    _commitRandoms[_commitBatch] = seed;
    _commitBatch += 1;
  }

  function deleteCommit(address addr) external {
    require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");
    uint16 commitIdCur = _pendingCommitId[_msgSender()];
    require(commitIdCur > 0, "No pending commit");
    delete _mintCommits[addr][commitIdCur];
    delete _pendingCommitId[addr];
  }

  function forceRevealCommit(address addr) external {
    require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");
    reveal(addr);
  }



  /** Initiate the start of a mint during the whitelisted minting period **/

  function whitelistMintCommit(uint256 index, uint256 a, uint256 amount, bytes32[] calldata merkleProof, bool stake) external payable whenNotPaused nonReentrant requireEOA {
    
    require(_pendingCommitId[_msgSender()] == 0, "Already have pending mints");
    require(_whitelistClaims[_msgSender()] + amount <= 2, "exceeds whitelist mint limit");
    // all whitelist mints take place during the presale phase, no need to check for other prices.
    require(amount * presalePrice == msg.value, "Invalid payment amount");

    
    // verify merkle proof
    bytes32 node = keccak256(abi.encodePacked(index, _msgSender(), a));
    require(MerkleProof.verify(merkleProof, whitelistMerkleRoot, node), "Not on Whitelist: Invalid Merkle proof.");  
  
    _whitelistClaims[_msgSender()] += amount;

    uint16 amt = uint16(amount);
    _mintCommits[_msgSender()][_commitBatch] = MintCommit(stake, amt);
    _pendingCommitId[_msgSender()] = _commitBatch;
    pendingMintAmt += amt;
    emit MintCommitted(_msgSender(), amount);

  }

  /** Initiate the start of a mint. This action burns $EXP, as the intent of committing is that you cannot back out once you've started.
    * This will add users into the pending queue, to be revealed after a random seed is generated and assigned to the commit id this
    * commit was added to. */
  function mintCommit(uint256 amount, bool stake) external payable whenNotPaused nonReentrant requireEOA {
    require(isPublicSale == true, "Public Sale not started!");
    require(_pendingCommitId[_msgSender()] == 0, "Already have pending mints");
    uint16 minted = HNDNFT.minted();
    uint256 maxTokens = HNDNFT.getMaxTokens();
    uint256 paidTokens = HNDNFT.getPaidTokens();
    require(minted + pendingMintAmt + amount <= maxTokens, "All tokens minted");
    require(amount <= 10, "HNDGame: Maximum mint amount of 10");

    if (minted < paidTokens) {
      require(minted + amount <= paidTokens, "HNDGame: Paid tokens sold out");
      require(amount * publicSalePrice == msg.value, "HNDGame: Invalid payment amount");
    } else {
      require(msg.value == 0);
      uint256 totalExpCost = 0;
      // Loop through the amount of 
      for (uint i = 1; i <= amount; i++) {
        totalExpCost += mintCost(minted + pendingMintAmt + i, maxTokens);
      }

      if (totalExpCost > 0) {
        // burn 30% (and the recycled 35%)
        expToken.burn(_msgSender(), totalExpCost * 13 / 20);
        
        // recycle the 35%
        kingdom.recycleExp(totalExpCost * 7/20);

        // 35% to treasury
        expToken.transferFrom(_msgSender(), treasury, totalExpCost * 7 / 20);


        expToken.updateOriginAccess();
      }
    }

    uint16 amt = uint16(amount);
    _mintCommits[_msgSender()][_commitBatch] = MintCommit(stake, amt);
    _pendingCommitId[_msgSender()] = _commitBatch;
    pendingMintAmt += amt;
    emit MintCommitted(_msgSender(), amount);
  }

  /** Reveal the commits for this user. This will be when the user gets their NFT, and can only be done when the commit id that
    * the user is pending for has been assigned a random seed. */
  function mintReveal() external whenNotPaused nonReentrant requireEOA {
    reveal(_msgSender());
  }

  function reveal(address addr) internal {
    uint16 commitIdCur = _pendingCommitId[addr];
    require(commitIdCur > 0, "No pending commit");
    require(_commitRandoms[commitIdCur] > 0, "random seed not set");
    uint16 minted = HNDNFT.minted();
    MintCommit memory commit = _mintCommits[addr][commitIdCur];
    pendingMintAmt -= commit.amount;
    uint16[] memory tokenIds = new uint16[](commit.amount);
    uint256 seed = _commitRandoms[commitIdCur];
    for (uint k = 0; k < commit.amount; k++) {
      minted++;

      // change seed per mint
      seed = uint256(keccak256(abi.encode(seed, addr)));
      address recipient = selectRecipient(seed);

      tokenIds[k] = minted;
      if (!commit.stake || recipient != addr) {
        HNDNFT.mint(recipient, seed);
      } else {
        HNDNFT.mint(address(kingdom), seed);
      }
    }
    HNDNFT.updateOriginAccess(tokenIds);
    if(commit.stake) {
      kingdom.addManyToKingdom(addr, tokenIds);
    }
    delete _mintCommits[addr][commitIdCur];
    delete _pendingCommitId[addr];
    emit MintCommitted(addr, tokenIds.length);
  }

  /** 
   * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
  function mintCost(uint256 tokenId, uint256 maxTokens) public view returns (uint256) {
    if (tokenId <= maxTokens * 2 / 5) return 20000 ether;
    if (tokenId <= maxTokens * 3 / 5) return 45000 ether;
    if (tokenId <= maxTokens * 4 / 5) return 80000 ether;
    if (tokenId <= maxTokens)         return 105000 ether; 
    return maxExpCost;
  }

  /** INTERNAL */

  /**
   * the first 20% (ETH purchases) go to the minter
   * the remaining 80% have a 10% chance to be given to a random staked demon
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Demon thief's owner)
   */
  function selectRecipient(uint256 seed) internal view returns (address) {
    if (((seed >> 245) % 10) != 0) return _msgSender(); // top 10 bits haven't been used
    address thief = kingdom.randomDemonOwner(seed >> 144); // 144 bits reserved for trait selection
    if (thief == address(0x0)) return _msgSender();
    return thief;
  }

  /** ADMIN */

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function startPublicSale(bool _saleStarted) external onlyOwner {
    isPublicSale = _saleStarted;
  }

  function setMaxExpCost(uint256 _amount) external requireContractsSet onlyOwner {
    maxExpCost = _amount;
  } 


  /** Allow the contract owner to set the pending mint amount.
    * This allows any long-standing pending commits to be overwritten, say for instance if the max supply has been 
    *  reached but there are many stale pending commits, it could be used to free up those spaces if needed/desired by the community.
    * This function should not be called lightly, this will have negative consequences on the game. */
  function setPendingMintAmt(uint256 pendingAmt) external onlyOwner {
    pendingMintAmt = uint16(pendingAmt);
  }

  /**
  * enables an address to mint / burn
  * @param addr the address to enable
  */
  function addAdmin(address addr) external onlyOwner {
      admins[addr] = true;
  }

  /**
  * disables an address from minting / burning
  * @param addr the address to disbale
  */
  function removeAdmin(address addr) external onlyOwner {
      admins[addr] = false;
  }

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IShop {
    function mint(uint256 typeId, uint16 qty, address recipient) external;
    function burn(uint256 typeId, uint16 qty, address burnFrom) external;
    function updateOriginAccess() external;
    function balanceOf(address account, uint256 id) external returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IHND is IERC721Enumerable {

    // game data storage
    struct HeroDemon {
        bool isHero;
        bool isFemale;
        uint8 body;
        uint8 face;
        uint8 eyes;
        uint8 headpiecehorns;
        uint8 gloves;
        uint8 armor;
        uint8 weapon;
        uint8 shield;
        uint8 shoes;
        uint8 tailflame;
        uint8 rankIndex;
    }

    function minted() external returns (uint16);
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function getMaxTokens() external view returns (uint256);
    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (HeroDemon memory);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function isHero(uint256 tokenId) external view returns(bool);
  
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IEXP {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IKingdom {
  function addManyToKingdom(address account, uint16[] calldata tokenIds) external;
  function randomDemonOwner(uint256 seed) external view returns (address);
  function recycleExp(uint256 amount) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IHNDGame {
  
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}