// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./GaiminERC1155Ids.sol";
import "./IGaiminERC1155.sol";



contract GaiminICO is Ownable, GaiminERC1155Ids, ReentrancyGuard, ERC1155Holder {

  IGaiminERC1155 public token;

  uint256 public salesEndPeriod;
  uint256 public rarityPrice;
  
  uint256 public totalUnknownRarityMinted = 0;
  bool public whitelistingEnabled = true;

  uint8 public constant MAX_NFTS_PER_ACCOUNT = 20;

  bytes32 whiteslitedAddressesMerkleRoot = 0x00;

  mapping (uint256 => uint256) public mintedRarity;

  event PurchaseRarity(
    address indexed user, 
    uint256 purchasedRarity,
    uint256 etherToRefund,
    uint256 etherUsed,
    uint256 etherSent,
    uint256 timestamp
  );  

  event DelegatePurchase(
    address[] indexed users, 
    uint256[] amounts,
    uint256 timestamp
  );  

  event AllocateRarity(
    address[] indexed receivers, 
    uint256[] amounts,
    uint256 timestamp
  );  

  event Withdraw(
    address indexed user, 
    uint256 amount,
    uint256 timestamp
  );  

  event UpdateMerkleRoot(
    bytes32 indexed newRoot, 
    uint256 timestamp
  );  

  event UpdateSalesEndPeriod(
    uint256 indexed newSalesEndPeriod, 
    uint256 timestamp
  );  

  constructor(address token_, uint256 salesEndPeriod_, uint256 rarityPrice_) {
    require(token_ != address(0), "Not a valid token address");
    require(rarityPrice_ > 0, "Rarity Price can not be equal to zero");
    require(salesEndPeriod_ > block.timestamp, "Distribution date is in the past");

    token = IGaiminERC1155(token_);
    salesEndPeriod = salesEndPeriod_;
    rarityPrice = rarityPrice_;
  }

  receive() external payable {
    revert();
  }

  function purchaseRarity(bytes32[] memory proof) external payable nonReentrant {
    require(block.timestamp <= salesEndPeriod, "Rarity sale period have ended");
    require(msg.value >= rarityPrice, "Price must be greather than or equal to the rarity price");

    require(token.balanceOf(msg.sender, UNKNOWN) != MAX_NFTS_PER_ACCOUNT, "Receiver have reached the allocated limit");

    if (whitelistingEnabled) {
      require(proof.length > 0, "Proof length can not be zero");
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      bool iswhitelisted = verifyProof(leaf, proof);
      require(iswhitelisted, "User not whitelisted");
    } 

    uint256 numOfRarityPerPrice = msg.value / rarityPrice;

    uint256 numOfEligibleRarityToPurchase = MAX_NFTS_PER_ACCOUNT - token.balanceOf(msg.sender, UNKNOWN);
    uint256 numOfRarityPurchased = numOfRarityPerPrice > numOfEligibleRarityToPurchase ? numOfEligibleRarityToPurchase : numOfRarityPerPrice;
        
    require((token.balanceOf(msg.sender, UNKNOWN) + numOfRarityPurchased) <= MAX_NFTS_PER_ACCOUNT, "Receiver total rarity plus the rarity you want to purchase exceed your limit");
    require((totalUnknownRarityMinted + numOfRarityPurchased) <= MAX_TOTAL_UNKNOWN, "The amount of rarity you want to purchase plus the total rarity minted exceed the total unknown rarity");

    uint256 totalEtherUsed = numOfRarityPurchased * rarityPrice;

    // calculate and send the remaining ether balance
    uint256 etherToRefund = _transferBalance(msg.value, payable(msg.sender), totalEtherUsed);

    totalUnknownRarityMinted += numOfRarityPurchased;

    // MINT NFT;
    token.mint(msg.sender, UNKNOWN, numOfRarityPurchased, "0x0");

    emit PurchaseRarity(msg.sender, UNKNOWN, etherToRefund, totalEtherUsed, msg.value, block.timestamp);
  }

  function _transferBalance(uint256 totalEtherSpent, address payable user, uint256 totalEtherUsed) internal returns(uint256) {
    uint256 balance = 0;
    if (totalEtherSpent > totalEtherUsed) {
      balance = totalEtherSpent - totalEtherUsed;
      (bool sent, ) = user.call{value: balance}("");
      require(sent, "Failed to send remaining Ether balance");
    } 
    return balance;
  }

  function delegatePurchase(address[] memory newUsers, uint256[] memory amounts) external onlyOwner nonReentrant{
    require(newUsers.length == amounts.length, "newUsers and amounts length mismatch");

    uint256 _totalUnknownRarityMinted = totalUnknownRarityMinted;

    for (uint256 i = 0; i < newUsers.length; i++) {

      address newUser = newUsers[i];
      uint256 amount = amounts[i];

      require(newUser != address(0), "Not a valid address");
      require(amount != 0, "Rarity mint amount can not be zero");
      require((_totalUnknownRarityMinted + amount) <= MAX_TOTAL_UNKNOWN, "Rarity to be minted will exceed maximum total UNKNOWN rarity");

      _totalUnknownRarityMinted += amount;
      // MINT NFT;
      token.mint(newUser, UNKNOWN, amount, "0x0");
 
    }
    totalUnknownRarityMinted = _totalUnknownRarityMinted;
    emit DelegatePurchase(newUsers, amounts, block.timestamp);

  }

  function allocateRarity(uint256[] memory amounts, address[] memory receivers) external onlyOwner nonReentrant {

    require(amounts.length == receivers.length, "amounts and receivers length mismatch");
    require(block.timestamp > salesEndPeriod, "Rarity can not be distributed now");

    uint256 randomNumber = uint256(blockhash(block.number - 1) ^ blockhash(block.number - 2) ^ blockhash(block.number - 3));

    for (uint256 i = 0; i < receivers.length; i++) {
      
      address receiver = receivers[i];
      uint256 amount = amounts[i];

      uint256[] memory purchasedRarity = new uint[](amount);
      uint256[] memory amountPerRarity = new uint[](amount);

      require(receiver != address(0), "Not a valid address");
      require(amount != 0, "Rarity mint amount can not be zero");

      for (uint256 j = 0; j < amount; j++) {

        // There will be mathemtical overflow below, which is fine we want it.
        unchecked {
          randomNumber += uint256(blockhash(block.number - 4));  
        }

        uint256 remainingSilver = (MAX_TOTAL_SILVER - mintedRarity[SILVER]);
        uint256 remainingGold = (MAX_TOTAL_GOLD - mintedRarity[GOLD]);
        uint256 remainingBlackgold = (MAX_TOTAL_BLACKGOLD - mintedRarity[BLACKGOLD]);

        uint256 remainingSupply = remainingSilver + remainingGold + remainingBlackgold;

        uint256 raritySlot = (randomNumber % remainingSupply);

        uint256 rarity;
        
        if (raritySlot < remainingSilver) {
          rarity = SILVER;
        } else if (raritySlot < (remainingSilver + remainingGold)) {
          rarity = GOLD;
        } else {
          rarity = BLACKGOLD;
        }

        purchasedRarity[j] = rarity;
        amountPerRarity[j] = 1; 
        mintedRarity[rarity]++;

      }

      // BURN UNKNOWN NFT;
      token.burn(receiver, UNKNOWN, amount);

      // MINT NFT in Batch;
      token.mintBatch(receiver, purchasedRarity, amountPerRarity, "0x0");

    }

    emit AllocateRarity(receivers, amounts, block.timestamp);

  } 

  function verifyProof(bytes32 leaf, bytes32[] memory proof) public view returns (bool) {

    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash <= proofElement) {
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    return computedHash == whiteslitedAddressesMerkleRoot;
  }

  function withdrawEther(address payable receiver) external onlyOwner nonReentrant {
    require(receiver != address(0), "Not a valid address");
    require(address(this).balance > 0, "Contract have zero balance");

    (bool sent, ) = receiver.call{value: address(this).balance}("");
    require(sent, "Failed to send ether");
    emit Withdraw(receiver, address(this).balance, block.timestamp);
  }

  function updateMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
    require(newMerkleRoot.length > 0, "New merkle tree is empty");
    whiteslitedAddressesMerkleRoot = newMerkleRoot;
    emit UpdateMerkleRoot(newMerkleRoot, block.timestamp);
  } 

  function updateSalesEndPeriod(uint256 newSalesEndPeriod) external onlyOwner{
    require(newSalesEndPeriod > block.timestamp, "New sale end period is in the past");
    salesEndPeriod = newSalesEndPeriod;
    emit UpdateSalesEndPeriod(newSalesEndPeriod, block.timestamp);
  } 

  function toggleWhitelist() external onlyOwner {
    whitelistingEnabled = !whitelistingEnabled;
  }

  function getBalance() external view returns (uint) {
    return address(this).balance;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract GaiminERC1155Ids {
  uint16 public constant MAX_TOTAL_UNKNOWN = 8888;
  uint16 public constant MAX_TOTAL_SILVER = 6000;
  uint16 public constant MAX_TOTAL_GOLD = 2800;
  uint16 public constant MAX_TOTAL_BLACKGOLD = 88;

  uint16 public constant UNKNOWN = 0;
  uint16 public constant SILVER = 1;
  uint16 public constant GOLD = 2;
  uint16 public constant BLACKGOLD = 3;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IGaiminERC1155 is IERC1155 {
  function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
  
  function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

  function burn(address account, uint256 id, uint256 value) external;


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}