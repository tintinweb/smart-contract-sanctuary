/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/pixelPawn.sol

//  SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

////////////////////////////////////////////////////////////////
////////////  Pixel Pawn - We buy your hot garbage  ////////////
////////////////////////////////////////////////////////////////
// Did you buy an NFT at the top?                             //
// Is it literally worthless and you can't even give it away? //
// Maybe it's time to accept your losses and move on          //
// This contract will buy any garbage NFT for 0.0005 eth      //
// If for some reason you want your garbage back,             //
// you can buy it back for 0.005 eth.                         //
// After 7 days, your garbage goes up for sale to anyone who  //
// is willing to pay  0.005 eth.                              //
////////////////////////////////////////////////////////////////






contract PIXEL_PAWN is ERC1155Holder, Ownable {
    event Received(address, uint);

    event SoldToShop721(uint32 saleId, address nftAddress, address seller, uint256 tokenId);
    event BoughtFromShop721(uint32 saleId, address nftAddress, address buyer, uint256 tokenId);

    event SoldToShop1155(uint32 saleId, address nftAddress, address seller, uint256 tokenId, uint256 tokenCount);
    event BoughtFromShop1155(uint32 saleId, address nftAddress, address buyer, uint256 tokenId, uint256 tokenCount);

    struct ContractSales721{
      uint8 derp;
      mapping(uint256 => Sale721) tokenSales; // 721 maps a token id to a sale, each token has a single sale
    }

    struct Sale721 {
      address seller;
      uint32 saleId;
      uint32 unlockedBlock;
    }

    struct ContractSales1155{
      uint8 derp;
      mapping(uint256 => SaleMap1155) tokenSales; // 1155 maps a token id to a sale map
    }

    struct SaleMap1155 {
      uint8 derp;
      mapping(address => Sale1155) sale;
    }

    struct Sale1155 {
      uint32 saleId;
      uint32 unlockedBlock;
      uint256 tokenCount;
    }

    mapping(address => ContractSales721) public _shop721;
    mapping(address => ContractSales1155) public _shop1155;
    mapping(address => uint32) public _lastPawn;
    mapping(address => uint8) public _antiRug;

    uint32 _unlockDelta = 12721;//12721; //~2d //44500; ~7d
    uint32 _nextSaleId = 1;
    address payable _dAddress = payable(0xF7a26a24eb5dd146Ea00D7fC9dC4Ec1c474eeF03); //DerpDAO Address

    function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data ) public returns (bytes4) {
      return this.onERC721Received.selector;
  }

  receive() external payable {
      emit Received(msg.sender, msg.value);
  }

    function sell721(address nftAddress, uint256 tokenId) public{
      require(_antiRug[msg.sender] < 5, "Only 5 sales in a row.  Buy something instead");
      _antiRug[msg.sender] = _antiRug[msg.sender] + 1;
      require(_lastPawn[msg.sender] < block.number, "Only one sale per address per block is allowed");
      _lastPawn[msg.sender] = uint32(block.number);
      IERC721 nftContract = IERC721(nftAddress);
      nftContract.safeTransferFrom(msg.sender, address(this) ,tokenId);
      payable(msg.sender).transfer((5* (10 ** 14))); // 0.0005 eth
      _shop721[nftAddress].tokenSales[tokenId].seller = msg.sender;
      _shop721[nftAddress].tokenSales[tokenId].unlockedBlock = uint32(block.number) + _unlockDelta;
      _shop721[nftAddress].tokenSales[tokenId].saleId = _nextSaleId;
      emit SoldToShop721(_nextSaleId, nftAddress, msg.sender, tokenId);
      _nextSaleId = _nextSaleId + 1;
    }

    function sell1155(address nftAddress, uint256 tokenId, uint256 tokenCount) public{
      require(_antiRug[msg.sender] < 5, "Only 5 sales in a row.  Buy something instead");
      _antiRug[msg.sender] = _antiRug[msg.sender] + 1;
      require(_lastPawn[msg.sender] < block.number, "Only one sale per address per block is allowed");
      _lastPawn[msg.sender] = uint32(block.number);
      IERC1155 nftContract = IERC1155(nftAddress);
      nftContract.safeTransferFrom(msg.sender, address(this) ,tokenId, tokenCount, "");
      payable(msg.sender).transfer((5* (10 ** 14))); // 0.0005 eth
      require(_shop1155[nftAddress].tokenSales[tokenId].sale[msg.sender].unlockedBlock == 0, "You are only allowed to have 1 active sale per token ID");
      _shop1155[nftAddress].tokenSales[tokenId].sale[msg.sender].unlockedBlock = uint32(block.number) + _unlockDelta;
      _shop1155[nftAddress].tokenSales[tokenId].sale[msg.sender].saleId = _nextSaleId;
      _shop1155[nftAddress].tokenSales[tokenId].sale[msg.sender].tokenCount = tokenCount;
      emit SoldToShop1155(_nextSaleId, nftAddress, msg.sender, tokenId, tokenCount);
      _nextSaleId = _nextSaleId + 1;
    }


    function buy721(address nftAddress, uint256 tokenId) public payable {
      if(block.number < (_shop721[nftAddress].tokenSales[tokenId].unlockedBlock))
        require(_shop721[nftAddress].tokenSales[tokenId].seller == msg.sender, "NFT not yet up for sale");

      require(msg.value >= (50* (10 ** 14)));

      IERC721 nftContract = IERC721(nftAddress);
      nftContract.safeTransferFrom(address(this), msg.sender ,tokenId);
      emit BoughtFromShop721(_shop721[nftAddress].tokenSales[tokenId].saleId, nftAddress, msg.sender, tokenId);
      _shop721[nftAddress].tokenSales[tokenId].seller = address(0);
      _shop721[nftAddress].tokenSales[tokenId].unlockedBlock = 0;
      _shop721[nftAddress].tokenSales[tokenId].saleId = 0;
      _antiRug[msg.sender] = 0;
      if(address(this).balance > (3* (10 ** 17)))// if the contact has more than 0.3eth, send everything above 0.2 to derpDAO
        _dAddress.transfer(address(this).balance-(2* (10 ** 17)));
    }

    function buy1155(address nftAddress, uint256 tokenId, address tokenSeller) public payable {
      require(_shop1155[nftAddress].tokenSales[tokenId].sale[tokenSeller].unlockedBlock > 0, "Invalid token reference");
      if(block.number < (_shop1155[nftAddress].tokenSales[tokenId].sale[tokenSeller].unlockedBlock))
        require(tokenSeller == msg.sender, "NFT not yet up for sale");

      require(msg.value >= (50* (10 ** 14)));

      IERC1155 nftContract = IERC1155(nftAddress);
      nftContract.safeTransferFrom(address(this), msg.sender , tokenId, _shop1155[nftAddress].tokenSales[tokenId].sale[tokenSeller].tokenCount, "");
      emit BoughtFromShop1155(_shop1155[nftAddress].tokenSales[tokenId].sale[tokenSeller].saleId, nftAddress, msg.sender, tokenId, _shop1155[nftAddress].tokenSales[tokenId].sale[tokenSeller].tokenCount);
      _shop1155[nftAddress].tokenSales[tokenId].sale[tokenSeller].unlockedBlock = 0;
      _shop1155[nftAddress].tokenSales[tokenId].sale[tokenSeller].saleId = 0;
      _shop1155[nftAddress].tokenSales[tokenId].sale[tokenSeller].tokenCount = 0;
      _antiRug[msg.sender] = 0;
      if(address(this).balance > (3* (10 ** 17)))// if the contact has more than 0.2eth, send everything above 0.2 to derpDAO
        _dAddress.transfer(address(this).balance-(2* (10 ** 17)));
    }

}