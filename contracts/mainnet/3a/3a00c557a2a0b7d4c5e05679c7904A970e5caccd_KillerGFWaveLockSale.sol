/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

//             ((((((((((((((((((.                                             
//         ((((((((((((((((((((((((((*                                         
//      /(((((((((((((((((((((((((((((((*                                      
//     ((((((((((((#             #(((((((((                                    
//   (((((((((((                     ((((((((((((((((((((((,                   
//   ((((((((#         ((((((((((       (((((((((((((((((((((((((              
//  *(((((((       #(((((((((((((((((               /(((((((((((((((           
//  *((((((/     #((((((#        .((((((                 .((((((((((((.        
//   ((((((.    ((((((               #(((((((((((((#         (((((((((((       
//   ((((((/    ((((/                         .((((((((.      .((((((((((      
//   *((((((    ((((                              (((((((       ((((((((((     
//    ((((((,   ,(((.                               ((((((      .(((((((((     
//     ((((((    ((((                                (((((*      (((((((((     
//      ((((((    ((((                              ((((((      #(((((((((     
//       ((((((    #(((                            #(((((      ((((((((((      
//        ((((((/   .(((.                        ((((((,      ((((((((((       
//          ((((((    ((((                    (((((((       ((((((((((         
//           ((((((    /(((             ,((((((((        ((((((((((/           
//            /(((((#    ((((     ((((((((((         #(((((((((((              
//              ((((((    ((((((((((((          #((((((((((((*                 
//               ((((((/    ((,           (((((((((((((((                      
//                 ((((((          ,(((((((((((((((/                           
//                  ((((((*(((((((((((((((((((                                 
//                   ,(((((((((((((((((*                                       
//                     (((((((((,  
//           
// Killer GF by Zeronis and uwulabs                                  
// Made with love <3                                            


// SPDX-License-Identifier: MIT

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Supply is IERC165 {
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
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);
    
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

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

interface Minter {
  function MAX_SUPPLY() external returns (uint256);
  function mintNFTs(address to, uint256[] memory tokenId) external;
  function owner() external returns (address);
}

contract KillerGFWaveLockSale is Ownable, ReentrancyGuard {
  uint256 constant BASE = 1e18;

  uint256 constant TEAM_INDEX = 0;
  uint256 constant UWULIST_INDEX = 1;
  uint256 constant WHITELIST_INDEX = 2;

  uint256 constant SLOT_COUNT = 256/32;
  uint256 constant MAX_WAVES = 6;
  uint256 constant PRESALE_SLOT_INDEX = 0;
  uint256 constant MINTED_SLOT_INDEX = 6;
  uint256 constant BALANCE_SLOT_INDEX = 7;
  
  bytes32 public teamRoot;
  bytes32 public uwuRoot;
  bytes32 public whitelistRoot;

  address public nft; 
  uint256 public amountForSale;
  uint256 public amountSold;
  uint256 public devSupply;
  uint256 public devMinted;

  uint64 public teamMinted;
  uint64 public uwuMinted;
  uint64 public whitelistMinted;

  uint256 public buyPrice = 0.08 ether;
  uint256 public uwuPrice = 0.065 ether;
  
  uint256 public startTime = type(uint256).max;
  uint256 public constant waveTimeLength = 5 minutes;

  // Purchases are compressed into a single uint256, after 6 rounds the limit is simply removed anyways.
  // The last uint32 slot is reserved for their balance. (left-most bytes first)
  mapping(address => uint256) purchases;

  event Reserved(address sender, uint256 count);
  event Minted(address sender, uint256 count);

  constructor(address _nft, address _owner, uint256 _startTime, uint256 saleCount, uint256 _ownerCount) Ownable() ReentrancyGuard() {
    require(_startTime != 0, "No start time");
    nft = _nft;
    startTime = _startTime;
    amountForSale = saleCount;
    devSupply = _ownerCount;
    transferOwnership(_owner);
  }

  function withdrawETH() external onlyOwner {
    uint256 fullAmount = address(this).balance;
    sendValue(payable(msg.sender), fullAmount*700/1000);
    sendValue(payable(0x354A70969F0b4a4C994403051A81C2ca45db3615), address(this).balance);
  }

  function setStartTime(uint256 _startTime) external onlyOwner {
    startTime = _startTime;
  }

  function setPresaleRoots(bytes32 _whitelistRoot, bytes32 _uwulistRoot, bytes32 _teamRoot) external onlyOwner {
    whitelistRoot = _whitelistRoot;
    uwuRoot = _uwulistRoot;
    teamRoot = _teamRoot;
  }

  function setNFT(address _nft) external onlyOwner {
    nft = _nft;
  }
  
  function devMint(uint256 count) public onlyOwner {
    devMintTo(msg.sender, count);
  }

  function devMintTo(address to, uint256 count) public onlyOwner {
    uint256 _devMinted = devMinted;
    uint256 remaining = devSupply - _devMinted;
    require(remaining != 0, "No more dev minted");
    if (count > remaining) {
      count = remaining;
    } 
    devMinted = _devMinted + count;

    uint256[] memory ids = new uint256[](count);
    for (uint256 i; i < count; ++i) {
      ids[i] = _devMinted+i+1;
    }
    Minter(nft).mintNFTs(to, ids);
  }
  
  function presaleBuy(uint256[3] calldata amountsToBuy, uint256[3] calldata amounts, uint256[3] calldata indexes, bytes32[][3] calldata merkleProof) external payable { 
    require(block.timestamp < startTime, "Presale has ended");
    require(amountsToBuy.length == 3, "Not right length");
    require(amountsToBuy.length == amounts.length, "Not equal amounts");
    require(amounts.length == indexes.length, "Not equal indexes");
    require(indexes.length == merkleProof.length, "Not equal proof");

    uint256 purchaseInfo = purchases[msg.sender];
    require(!hasDoneWave(purchaseInfo, PRESALE_SLOT_INDEX), "Already whitelist minted");

    uint256 expectedPayment;
    if (merkleProof[UWULIST_INDEX].length != 0) {
      expectedPayment += amountsToBuy[UWULIST_INDEX]*uwuPrice;
    }
    if (merkleProof[WHITELIST_INDEX].length != 0) {
      expectedPayment += amountsToBuy[WHITELIST_INDEX]*buyPrice;
    } 
    require(msg.value == expectedPayment, "Not right ETH sent");

    uint256 count;
    if (merkleProof[TEAM_INDEX].length != 0) {
      require(teamRoot.length != 0, "team root not assigned");
      bytes32 node = keccak256(abi.encodePacked(indexes[TEAM_INDEX], msg.sender, amounts[TEAM_INDEX]));
      require(MerkleProof.verify(merkleProof[TEAM_INDEX], teamRoot, node), 'MerkleProof: Invalid team proof.');
      require(amountsToBuy[TEAM_INDEX] <= amounts[TEAM_INDEX], "Cant buy this many");
      count += amountsToBuy[TEAM_INDEX];
      teamMinted += uint64(amountsToBuy[TEAM_INDEX]);
    }
    if (merkleProof[UWULIST_INDEX].length != 0) {
      require(uwuRoot.length != 0, "uwu root not assigned");
      bytes32 node = keccak256(abi.encodePacked(indexes[UWULIST_INDEX], msg.sender, amounts[UWULIST_INDEX]));
      require(MerkleProof.verify(merkleProof[UWULIST_INDEX], uwuRoot, node), 'MerkleProof: Invalid uwu proof.');
      require(amountsToBuy[UWULIST_INDEX] <= amounts[UWULIST_INDEX], "Cant buy this many");
      count += amountsToBuy[UWULIST_INDEX];
      uwuMinted += uint64(amountsToBuy[UWULIST_INDEX]);
    }
    if (merkleProof[WHITELIST_INDEX].length != 0) {
      require(whitelistRoot.length != 0, "wl root not assigned");
      bytes32 node = keccak256(abi.encodePacked(indexes[WHITELIST_INDEX], msg.sender, amounts[WHITELIST_INDEX]));
      require(MerkleProof.verify(merkleProof[WHITELIST_INDEX], whitelistRoot, node), 'MerkleProof: Invalid wl proof.');
      require(amountsToBuy[WHITELIST_INDEX] <= amounts[WHITELIST_INDEX], "Cant buy this many");
      count += amountsToBuy[WHITELIST_INDEX];
      whitelistMinted += uint64(amountsToBuy[WHITELIST_INDEX]);
    }  

    uint256 startSupply = currentMintIndex();
    uint256 _amountSold = amountSold;
    amountSold = _amountSold + count;
    purchases[msg.sender] = _createNewPurchaseInfo(purchaseInfo, PRESALE_SLOT_INDEX, startSupply, count);

    emit Reserved(msg.sender, count);
  }

  /*
   * DM TylerTakesATrip#9279 he looks submissive and breedable.
   */
  function buyKGF(uint256 count) external payable nonReentrant {
    uint256 _amountSold = amountSold;
    uint256 _amountForSale = amountForSale;
    uint256 remaining = _amountForSale - _amountSold;
    require(remaining != 0, "Sold out! Sorry!");

    require(block.timestamp >= startTime, "Sale has not started");
    require(tx.origin == msg.sender, "Only direct calls pls");
    require(count > 0, "Cannot mint 0");

    uint256 wave = currentWave();
    require(count <= maxPerTX(wave), "Max for TX in this wave");
    require(wave < MAX_WAVES, "Not in main sale");
    require(msg.value == count * buyPrice, "Not enough ETH");

    // Adjust for the last mint being incomplete.
    uint256 ethAmountOwed;
    if (count > remaining) {
      ethAmountOwed = buyPrice * (count - remaining);
      count = remaining;
    }

    uint256 purchaseInfo = purchases[msg.sender];
    require(!hasDoneWave(purchaseInfo, wave), "Already purchased this wave");

    uint256 startSupply = currentMintIndex();
    amountSold = _amountSold + count;
    purchases[msg.sender] = _createNewPurchaseInfo(purchaseInfo, wave, startSupply, count);
    
    emit Reserved(msg.sender, count);

    if (ethAmountOwed > 0) {
      sendValue(payable(msg.sender), ethAmountOwed);
    }
  }

  // just mint, no tickets
  // There is not enough demand if the sale is still incomplete at this point.  
  // So just resort to a normal sale. 
  function buyKGFPostSale(uint256 count) external payable {
    uint256 _amountSold = amountSold;
    uint256 _amountForSale = amountForSale;
    uint256 remaining = _amountForSale - _amountSold;
    require(remaining != 0, "Sold out! Sorry!");
    require(block.timestamp >= startTime, "Sale has not started");

    require(count > 0, "Cannot mint 0");
    require(count <= remaining, "Just out");
    require(tx.origin == msg.sender, "Only direct calls pls");
    require(msg.value == count * buyPrice, "Not enough ETH");

    uint256 wave = currentWave();
    require(count <= maxPerTX(wave), "Max for TX in this wave");
    require(wave >= MAX_WAVES, "Not in post sale");

    uint256 startSupply = currentMintIndex();
    amountSold = _amountSold + count;
    uint256[] memory ids = new uint256[](count);
    for (uint256 i; i < count; ++i) {
      ids[i] = startSupply + i;
    }
    Minter(nft).mintNFTs(msg.sender, ids);
  }

  function mint(uint256 count) external nonReentrant {
    _mintFor(msg.sender, count, msg.sender);
  }

  function devMintFrom(address from, uint256 count) public onlyOwner {
    require(block.timestamp > startTime + 3 days, "Too soon");
    _mintFor(from, count, msg.sender);
  }

  function devMintsFrom(address[] calldata froms, uint256[] calldata counts) public onlyOwner {
    for (uint256 i; i < froms.length; ++i) {
      devMintFrom(froms[i], counts[i]);
    }
  }

  function _mintFor(address account, uint256 count, address to) internal {
    require(count > 0, "0?");
    require(block.timestamp >= startTime, "Can only mint after the sale has begun");

    uint256 purchaseInfo = purchases[account];
    uint256 _mintedBalance =_getSlot(purchaseInfo, MINTED_SLOT_INDEX);
    uint256[] memory ids = _allIdsPurchased(purchaseInfo);
    require(count <= ids.length-_mintedBalance, "Not enough balance");

    uint256 newMintedBalance = _mintedBalance + count;
    purchases[account] = _writeDataSlot(purchaseInfo, MINTED_SLOT_INDEX, newMintedBalance);

    uint256[] memory mintableIds = new uint256[](count);
    for (uint256 i; i < count; ++i) {
      mintableIds[i] = ids[_mintedBalance+i];
    }

    // Mint to the owner.
    Minter(nft).mintNFTs(to, mintableIds);
    
    emit Minted(account, count);
  }

  function wavePurchaseInfo(uint256 wave, address who) external view returns (uint256, uint256) {
    uint256 cache = purchases[who];
    return _getInfo(cache, wave);
  }

  function currentMaxPerTX() external view returns (uint256) {
    return maxPerTX(currentWave());
  } 

  function allIdsPurchasedBy(address who) external view returns (uint256[] memory) {
    uint256 cache = purchases[who];
    return _allIdsPurchased(cache);
  } 
  
  function mintedBalance(address who) external view returns (uint256) {
    uint256 cache = purchases[who];
    uint256 _mintedBalance =_getSlot(cache, MINTED_SLOT_INDEX);
    return _mintedBalance;
  }

  function currentWave() public view returns (uint256) {
    if (block.timestamp < startTime) {
      return 0;
    }
    uint256 timeSinceStart = block.timestamp - startTime;
    uint256 _currentWave = timeSinceStart/waveTimeLength;
    return _currentWave;
  }

  function currentMintIndex() public view returns (uint256) {
    return amountSold + devSupply + 1;
  }

  function maxPerTX(uint256 _wave) public pure returns (uint256) {
    if (_wave == 0) {
      return 1;
    } else if (_wave == 1) {
      return 2;
    } else if (_wave == 2) {
      return 4;
    } else {
      return 8;
    }
  }

  function hasDoneWave(uint256 purchaseInfo, uint256 wave) public pure returns (bool) {
    uint256 slot = _getSlot(purchaseInfo, wave);
    return slot != 0;
  }

  function balanceOf(address who) public view returns (uint256) {
    uint256 cache = purchases[who];
    uint256 currentBalance = _getSlot(cache, BALANCE_SLOT_INDEX);
    uint256 _mintedBalance = _getSlot(cache, MINTED_SLOT_INDEX);
    return currentBalance-_mintedBalance;
  }

  function _createNewPurchaseInfo(uint256 purchaseInfo, uint256 wave, uint256 _startingSupply, uint256 count) internal pure returns (uint256) {
    require(wave < MAX_WAVES, "Not a wave index");
    uint256 purchase = _startingSupply<<8;
    purchase |= count;
    uint256 newWaveSlot = _writeWaveSlot(purchaseInfo, wave, purchase);
    uint256 newBalance = _getBalance(purchaseInfo) + count;
    return _writeDataSlot(newWaveSlot, BALANCE_SLOT_INDEX, newBalance);
  }

  function _allIdsPurchased(uint256 purchaseInfo) internal pure returns (uint256[] memory) {
    uint256 currentBalance = _getBalance(purchaseInfo);
    if (currentBalance == 0) {
      uint256[] memory empty;
      return empty;
    }

    uint256[] memory ids = new uint256[](currentBalance);

    uint256 index;
    for (uint256 wave; wave < MAX_WAVES; ++wave) {
      (uint256 supply, uint256 count) = _getInfo(purchaseInfo, wave);
      if (count == 0)
        continue;
      for (uint256 i; i < count; ++i) {
        ids[index] = supply + i;
        ++index;
      }
    }
    require(index == ids.length, "not all");

    return ids;
  }

  function _getInfo(uint256 purchaseInfo, uint256 wave) internal pure returns (uint256, uint256) {
    require(wave < MAX_WAVES, "Not a wave index");
    uint256 slot = _getSlot(purchaseInfo, wave);
    uint256 supply = slot>>8;
    uint256 count = uint256(uint8(slot));
    return (supply, count);
  } 

  function _getBalance(uint256 purchaseInfo) internal pure returns (uint256) {
    return _getSlot(purchaseInfo, BALANCE_SLOT_INDEX);
  }

  function _writeWaveSlot(uint256 purchase, uint256 index, uint256 data) internal pure returns (uint256) {
    require(index < MAX_WAVES, "not valid index");
    uint256 writeIndex = 256 - ((index+1) * 32);
    require(uint32(purchase<<writeIndex) == 0, "Cannot write in wave slot twice");
    uint256 newSlot = data<<writeIndex;
    uint256 newPurchase = purchase | newSlot;
    return newPurchase;
  }

  function _writeDataSlot(uint256 purchase, uint256 index, uint256 data) internal pure returns (uint256) {
    require(index == MINTED_SLOT_INDEX || index == BALANCE_SLOT_INDEX, "not valid index");
    uint256 writeIndex = 256 - ((index+1) * 32);
    uint256 newSlot = uint256(uint32(data))<<writeIndex;
    uint256 newPurchase = purchase>>(writeIndex+32)<<(writeIndex+32);
    if (index == MINTED_SLOT_INDEX) 
      newPurchase |= _getSlot(purchase, BALANCE_SLOT_INDEX);
    newPurchase |= newSlot;
    return newPurchase;
  }

  function _getSlot(uint256 purchase, uint256 index) internal pure returns (uint256) {
    require(index < SLOT_COUNT, "not valid index");
    uint256 writeIndex = 256 - ((index+1) * 32);
    uint256 slot = uint32(purchase>>writeIndex);
    return slot;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }
}