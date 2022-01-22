// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

/*
 ▄████▄   ██▀███   ▄▄▄      ▒███████▒▓██   ██▓
▒██▀ ▀█  ▓██ ▒ ██▒▒████▄    ▒ ▒ ▒ ▄▀░ ▒██  ██▒
▒▓█    ▄ ▓██ ░▄█ ▒▒██  ▀█▄  ░ ▒ ▄▀▒░   ▒██ ██░
▒▓▓▄ ▄██▒▒██▀▀█▄  ░██▄▄▄▄██   ▄▀▒   ░  ░ ▐██▓░
▒ ▓███▀ ░░██▓ ▒██▒ ▓█   ▓██▒▒███████▒  ░ ██▒▓░
░ ░▒ ▒  ░░ ▒▓ ░▒▓░ ▒▒   ▓▒█░░▒▒ ▓░▒░▒   ██▒▒▒
  ░  ▒     ░▒ ░ ▒░  ▒   ▒▒ ░░░▒ ▒ ░ ▒ ▓██ ░▒░
░          ░░   ░   ░   ▒   ░ ░ ░ ░ ░ ▒ ▒ ░░
░ ░         ░           ░  ░  ░ ░     ░ ░
░                           ░         ░ ░
 ▄████▄   ██▓     ▒█████   █     █░ ███▄    █   ██████
▒██▀ ▀█  ▓██▒    ▒██▒  ██▒▓█░ █ ░█░ ██ ▀█   █ ▒██    ▒
▒▓█    ▄ ▒██░    ▒██░  ██▒▒█░ █ ░█ ▓██  ▀█ ██▒░ ▓██▄
▒▓▓▄ ▄██▒▒██░    ▒██   ██░░█░ █ ░█ ▓██▒  ▐▌██▒  ▒   ██▒
▒ ▓███▀ ░░██████▒░ ████▓▒░░░██▒██▓ ▒██░   ▓██░▒██████▒▒
░ ░▒ ▒  ░░ ▒░▓  ░░ ▒░▒░▒░ ░ ▓░▒ ▒  ░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░
  ░  ▒   ░ ░ ▒  ░  ░ ▒ ▒░   ▒ ░ ░  ░ ░░   ░ ▒░░ ░▒  ░ ░
░          ░ ░   ░ ░ ░ ▒    ░   ░     ░   ░ ░ ░  ░  ░
░ ░          ░  ░    ░ ░      ░             ░       ░
░

Crazy Clowns Insane Asylum
2021, V1.1
https://ccia.io
*/

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/ICrazyClown.sol';

contract MerkleMint is Ownable, Pausable {
  bytes32 public merkleRoot;

  //Address => tokenIDs
  mapping(address => uint256) public mintRecords;

  //Crazy Clown interface
  ICrazyClown public crazyClown;

  constructor(address _crazyClown, bytes32 _hash) {
    crazyClown = ICrazyClown(_crazyClown);
    merkleRoot = _hash;
    _pause();
  }

  function merkleMint(
    uint256 numberOfTokens,
    uint256 maxQuantity,
    bytes32[] memory _merkleProof
  ) public whenNotPaused {
    require(crazyClown.totalSupply() + numberOfTokens <= crazyClown.maxSupply(), 'Mint would exceed max supply');

    bytes32 node = keccak256(abi.encode(msg.sender, maxQuantity));
    require(MerkleProof.verify(_merkleProof, merkleRoot, node), 'Address not eligible for mint');

    uint256 mintedNum = mintRecords[msg.sender];
    require(mintedNum + numberOfTokens <= maxQuantity, 'Mint would exceed max allowed');

    mintRecords[msg.sender] = mintRecords[msg.sender] + numberOfTokens;

    crazyClown.sendReserve(msg.sender, numberOfTokens);
  }

  function getMintRecord(address _minter) public view returns (uint256) {
    return mintRecords[_minter];
  }

  function setMerkleRoot(bytes32 _hash) external onlyOwner {
    merkleRoot = _hash;
  }

  function setMintContract(address _contract) external onlyOwner {
    crazyClown = ICrazyClown(_contract);
  }

  function togglePause() public onlyOwner {
    if (paused() == true) {
      require(crazyClown.saleStarted() == true, 'Public Sale not started');
      _unpause();
    } else {
      _pause();
    }
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

/*
 ▄████▄   ██▀███   ▄▄▄      ▒███████▒▓██   ██▓
▒██▀ ▀█  ▓██ ▒ ██▒▒████▄    ▒ ▒ ▒ ▄▀░ ▒██  ██▒
▒▓█    ▄ ▓██ ░▄█ ▒▒██  ▀█▄  ░ ▒ ▄▀▒░   ▒██ ██░
▒▓▓▄ ▄██▒▒██▀▀█▄  ░██▄▄▄▄██   ▄▀▒   ░  ░ ▐██▓░
▒ ▓███▀ ░░██▓ ▒██▒ ▓█   ▓██▒▒███████▒  ░ ██▒▓░
░ ░▒ ▒  ░░ ▒▓ ░▒▓░ ▒▒   ▓▒█░░▒▒ ▓░▒░▒   ██▒▒▒
  ░  ▒     ░▒ ░ ▒░  ▒   ▒▒ ░░░▒ ▒ ░ ▒ ▓██ ░▒░
░          ░░   ░   ░   ▒   ░ ░ ░ ░ ░ ▒ ▒ ░░
░ ░         ░           ░  ░  ░ ░     ░ ░
░                           ░         ░ ░
 ▄████▄   ██▓     ▒█████   █     █░ ███▄    █   ██████
▒██▀ ▀█  ▓██▒    ▒██▒  ██▒▓█░ █ ░█░ ██ ▀█   █ ▒██    ▒
▒▓█    ▄ ▒██░    ▒██░  ██▒▒█░ █ ░█ ▓██  ▀█ ██▒░ ▓██▄
▒▓▓▄ ▄██▒▒██░    ▒██   ██░░█░ █ ░█ ▓██▒  ▐▌██▒  ▒   ██▒
▒ ▓███▀ ░░██████▒░ ████▓▒░░░██▒██▓ ▒██░   ▓██░▒██████▒▒
░ ░▒ ▒  ░░ ▒░▓  ░░ ▒░▒░▒░ ░ ▓░▒ ▒  ░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░
  ░  ▒   ░ ░ ▒  ░  ░ ▒ ▒░   ▒ ░ ░  ░ ░░   ░ ▒░░ ░▒  ░ ░
░          ░ ░   ░ ░ ░ ▒    ░   ░     ░   ░ ░ ░  ░  ░
░ ░          ░  ░    ░ ░      ░             ░       ░
░

Crazy Clowns Insane Asylum
2021, V1.1
https://ccia.io
*/

interface ICrazyClown {
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

  function MINTER_ROLE() external view returns (bytes32);

  function PublicRevealStatus() external view returns (bool);

  function _changeBioFee() external view returns (uint256);

  function _changeNameFee() external view returns (uint256);

  function getTokenBio(uint256 _tokenId) external view returns (string memory);

  function getTokenName(uint256 _tokenId) external view returns (string memory);

  // function addAttributes ( tuple[] _attributes ) external;
  function addContractToWhitelist(address _contract) external;

  function addMinterRole(address _address) external;

  function addToPreSaleList(address[] memory entries) external;

  // function addTokenIdHash ( tuple[] _hashList ) external;
  function approve(address to, uint256 tokenId) external;

  function attributes(string memory)
    external
    view
    returns (
      string memory id,
      string memory trait_type,
      string memory value
    );

  function balanceOf(address owner) external view returns (uint256);

  // function buildTokenUri ( tuple meta ) external view returns ( string );
  function burn(uint256 tokenId) external;

  function changeBio(uint256 _tokenId, string memory _bio) external;

  function changeName(uint256 _tokenId, string memory _name) external;

  function contractURI() external view returns (string memory);

  function dataURI(uint256 tokenId) external view returns (string memory);

  function evolve_mint(address _user) external;

  function flipPreSaleStatus() external;

  function flipPublicSaleStarted() external;

  // function genericDataURI ( string name, string description, string external_url, string imageUrl, uint256 mintDate, tuple[] attributesData ) external view returns ( string );
  function getApproved(uint256 tokenId) external view returns (address);

  function getPreSalePrice() external view returns (uint256);

  function getPrice() external view returns (uint256);

  function getReservedLeft() external view returns (uint256);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function grantRole(bytes32 role, address account) external;

  function hasRole(bytes32 role, address account) external view returns (bool);

  function hashList(uint256) external view returns (string memory);

  function isApprovedForAll(address owner, address operator) external view returns (bool);

  function isPreSaleApproved(address addr) external view returns (bool);

  function maxSupply() external view returns (uint256);

  function mint(uint256 _nbTokens, bool _allowStaking) external;

  function mintListPurchases(address) external view returns (uint256);

  function name() external view returns (string memory);

  function ownerOf(uint256 tokenId) external view returns (address);

  function placeHolderURI() external view returns (string memory);

  function preSaleListPurchases(address) external view returns (uint256);

  function preSaleLive() external view returns (bool);

  function preSaleMintLimit() external view returns (uint256);

  function preSalePrice() external view returns (uint256);

  function preSaleWhitelist(address) external view returns (bool);

  function price() external view returns (uint256);

  function provenanceHash() external view returns (string memory);

  function publicMintLimit() external view returns (uint256);

  function publicSaleTransLimit() external view returns (uint256);

  function removeContractFromWhitelist(address _contract) external;

  function removeFromPreSaleList(address[] memory entries) external;

  function renounceRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) external;

  function saleStarted() external view returns (bool);

  function sendReserve(address _receiver, uint256 _nbTokens) external;

  function setApprovalForAll(address operator, bool approved) external;

  function setBaseURI(string memory _URI) external;

  function setChangeBioFee(uint256 _fee) external;

  function setChangeNameFee(uint256 _fee) external;

  function setContractURI(string memory _URI) external;

  function setPlaceholderURI(string memory uri) external;

  function setPreSaleMintLimit(uint256 _newPresaleMintLimit) external;

  function setPreSalePrice(uint256 _newPreSalePrice) external;

  function setPrice(uint256 _newPrice) external;

  function setProvenanceHash(string memory _provenanceHash) external;

  function setPublicMintLimit(uint256 limit) external;

  function setPublicSaleTransLimit(uint256 limit) external;

  function setReservedSupply(uint256 _newReservedSupply) external;

  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  function symbol() external view returns (string memory);

  function togglePublicReveal() external;

  function tokenByIndex(uint256 index) external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function totalSupply() external view returns (uint256);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function utilityToken() external view returns (address);

  function walletOfOwner(address _owner) external view returns (uint256[] memory);

  function withdraw(address _receiver) external;
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