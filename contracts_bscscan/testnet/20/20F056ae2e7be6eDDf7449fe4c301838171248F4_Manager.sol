/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity >=0.6.2 <0.8.0;


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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol



pragma solidity >=0.6.2 <0.8.0;


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

// File: contracts/interfaces/ICryptoDogeNFT.sol



pragma solidity ^0.6.12;


interface ICryptoDogeNFT is IERC721Enumerable {

    function layEgg(address receiver, uint8[] memory tribes) external;

    function evolve(uint256 tokenId, address owner, uint256 dna) external;

    function changeTribe(uint256 tokenId, address owner, uint8 tribe) external;

    function upgradeGeneration(uint256 tokenId, address owner, uint256 generation) external;

    function getdoger(uint256 tokenId) external view returns (uint256, uint8, uint256, uint256, uint256, uint256, uint256);

    function latestTokenId() external view returns (uint256);

    function getRare(uint256 tokenId) external view returns (uint256);

    function exp(uint256 tokenId, uint256 _exp) external;

    function marketsSize() external view returns (uint256);

    function orders(address account) external view returns (uint256);

    function tokenSaleByIndex(uint256 index) external view returns (uint256);

    function tokenSaleOfOwnerByIndex(address seller, uint256 index) external view returns (uint256);

    function getSale(uint256 tokenId) external view returns (uint256, address, uint256);
    
}

// File: contracts/Manager.sol


pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;



contract Manager is Ownable {
  mapping (address => bool) public battlefields;
  mapping (address => bool) public evolvers;
  mapping (address => bool) public markets;
  mapping (address => bool) public farmOwners;

  uint256 public priceEgg;
  uint256 public priceStone;
  uint256 public feeMarketRate;
  uint256 public feeEvolve;
  uint256 public feeChangeTribe;
  address public feeAddress;
  uint256 public divPercent;
  uint256 public generation;
  uint256 public feeUpgradeGeneration;
  ICryptoDogeNFT public nft;
  
  struct MarketInfo {
    uint256 tokenId;
    uint256 generation;
    uint8 tribe;
    uint256 className;
    uint256 exp;
    uint256 dna;
    uint256 farmTime;
    uint256 bornTime;
    address owner;
    uint256 price;
  }

  constructor(address _nft, uint256 _priceEgg) public {
    nft = ICryptoDogeNFT(_nft);
    priceEgg = _priceEgg;
    divPercent = 1000;
    feeAddress = msg.sender;
    feeMarketRate = 0;
  }

  function addBattlefield(address _battlefield) external onlyOwner {
    assert(battlefields[_battlefield] == false);
    battlefields[_battlefield] = true;
  }

  function addEvolver(address _evolver) external onlyOwner {
    assert(evolvers[_evolver] == false);
    evolvers[_evolver] = true;
  }

  function addMarkets(address _market) external onlyOwner {
    assert(markets[_market] == false);
    markets[_market] = true;
  }

  function addFarmOwners(address _farmOwner) external onlyOwner {
    assert(farmOwners[_farmOwner] == false);
    farmOwners[_farmOwner] = true;
  }

  function removeBattlefield(address _battlefield) external onlyOwner {
    assert(battlefields[_battlefield] == true);
    battlefields[_battlefield] = false;
  }

  function removeEvolver(address _evolver) external onlyOwner {
    assert(evolvers[_evolver] == true);
    evolvers[_evolver] = false;
  }

  function removeMarkets(address _market) external onlyOwner {
    assert(markets[_market] == true);
    markets[_market] = false;
  }

  function removeFarmOwners(address _farmOwner) external onlyOwner {
    assert(farmOwners[_farmOwner] == true);
    farmOwners[_farmOwner] = false;
  }

  function setPriceEgg(uint256 _priceEgg) external onlyOwner {
    priceEgg = _priceEgg;
  }
  
  function setPriceStone(uint256 _price) external onlyOwner {
    priceStone = _price;
  }

  function setFeeEvolve(uint256 _fee) external onlyOwner {
    feeEvolve = _fee;
  }

  function setFeeChangeTribe(uint256 _fee) external onlyOwner {
    feeChangeTribe = _fee;
  }

  function setFeeMarketRate(uint256 _feeMarketRate) external onlyOwner {
    feeMarketRate = _feeMarketRate;
  }

  function setFeeAddress(address _feeAddress) external onlyOwner {
    feeAddress = _feeAddress;
  }

  function setDivPercent(uint256 _divPercent) external onlyOwner {
    divPercent = _divPercent;
  }

  function setGeneration(uint256 _generation) external onlyOwner {
    generation = _generation;
  }

  function setFeeUpgradeGeneration(uint256 _feeUpgradeGeneration) external onlyOwner {
    feeUpgradeGeneration = _feeUpgradeGeneration;
  }

  function getMarketList() external view returns (MarketInfo[] memory) {
    uint256 marketsSize = nft.marketsSize();
    MarketInfo[] memory marketList = new MarketInfo[](marketsSize);
    for(uint i = 0; i < marketsSize; i++) {
      MarketInfo memory marketInfo;
      marketInfo.tokenId = nft.tokenSaleByIndex(i);
      (, marketInfo.owner, marketInfo.price) = nft.getSale(marketInfo.tokenId);
      (
        marketInfo.generation, 
        marketInfo.tribe, 
        marketInfo.className, 
        marketInfo.exp, 
        marketInfo.dna, 
        marketInfo.farmTime, 
        marketInfo.bornTime
      ) = nft.getdoger(marketInfo.tokenId);
      marketList[i] = marketInfo;
    }

    return marketList;
  }

  function getNftsOwned(address account) external view returns (MarketInfo[] memory) {
    uint256 balance = nft.balanceOf(account);
    uint256 onSaleBalance = nft.orders(account);
    uint256 totalBalance = balance + onSaleBalance;
    MarketInfo[] memory marketList = new MarketInfo[](totalBalance);
    for (uint i = 0; i < balance; i++) {
      MarketInfo memory marketInfo;
      marketInfo.tokenId = nft.tokenOfOwnerByIndex(account, i);
      (, , marketInfo.price) = nft.getSale(marketInfo.tokenId);
      (
        marketInfo.generation, 
        marketInfo.tribe, 
        marketInfo.className, 
        marketInfo.exp, 
        marketInfo.dna, 
        marketInfo.farmTime, 
        marketInfo.bornTime
      ) = nft.getdoger(marketInfo.tokenId);
      marketList[i] = marketInfo;
    }

    for (uint i = balance; i < totalBalance; i++) {
      MarketInfo memory marketInfo;
      marketInfo.tokenId = nft.tokenSaleOfOwnerByIndex(account, i - balance);
      (
        marketInfo.generation, 
        marketInfo.tribe, 
        marketInfo.className, 
        marketInfo.exp, 
        marketInfo.dna, 
        marketInfo.farmTime, 
        marketInfo.bornTime
      ) = nft.getdoger(marketInfo.tokenId);
      marketList[i] = marketInfo;
    }

    return marketList;
  }
}