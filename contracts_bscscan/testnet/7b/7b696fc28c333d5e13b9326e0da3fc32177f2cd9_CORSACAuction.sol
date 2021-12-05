/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

pragma solidity ^0.6.8;
library EnumerableUintSet {
    struct Set {
        bytes32[] _values;
        uint256[] _collection;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value, uint256 savedValue) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._collection.push(savedValue);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastValue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastValue;
            set._values.pop();

            uint256 lastvalueAddress = set._collection[lastIndex];
            set._collection[toDeleteIndex] = lastvalueAddress;
            set._collection.pop();

            set._indexes[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _collection(Set storage set) private view returns (uint256[] memory) {
        return set._collection;    
    }

    function _at(Set storage set, uint256 index) private view returns (uint256) {
        require(set._collection.length > index, "EnumerableSet: index out of bounds");
        return set._collection[index];
    }
    struct UintSet {
        Set _inner;
    }
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)), value);
    }
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function collection(UintSet storage set) internal view returns (uint256[] memory) {
        return _collection(set._inner);
    }
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return _at(set._inner, index);
    }
}
pragma solidity ^0.6.8;
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        address[] _collection;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value, address addressValue) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._collection.push(addressValue);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastValue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastValue;
            set._values.pop();

            address lastvalueAddress = set._collection[lastIndex];
            set._collection[toDeleteIndex] = lastvalueAddress;
            set._collection.pop();

            set._indexes[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            delete set._indexes[value];
//            for(uint256 i = 0; i < set._collection.length; i++) {
//                if (set._collection[i] == addressValue) {
//                    _removeIndexArray(i, set._collection);
//                    break;
//                }
//            }
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _collection(Set storage set) private view returns (address[] memory) {
        return set._collection;    
    }
//    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
//        for(uint256 i = index; i < array.length-1; i++) {
//            array[i] = array[i+1];
//        }
//        array.pop();
//    }
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)), value);
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function collection(AddressSet storage set) internal view returns (address[] memory) {
        return _collection(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }
}
pragma solidity ^0.6.8;
library SafeMath {
     function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

pragma solidity >=0.6.0 <0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

pragma solidity ^0.6.8;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
pragma solidity ^0.6.8;

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


pragma solidity ^0.6.8;

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

pragma solidity >=0.6.0 <0.8.0;
/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

pragma solidity >=0.6.2 <0.8.0;
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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
     * @dev xref:ROOT:ERC1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:ERC1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

pragma solidity ^0.6.8;

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code

contract CORSACAuction is IERC721Receiver,IERC1155Receiver {

    address private _CSCT;
    constructor (
        address csct
    ) public {
        _CSCT = csct;
    }

    using SafeMath for uint256;

    using EnumerableUintSet for EnumerableUintSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Auction {
        address seller;
        address latestBidder;
        uint256 latestBidTime;
        uint256 deadline;
        uint256 price;
    }

    mapping(uint256 => Auction) private _contractsPlusTokenIdsAuction;
    mapping(address => EnumerableUintSet.UintSet) private _contractsTokenIdsList;
    mapping(address => uint256) private _consumersDealFirstDate;
    mapping(uint256 => address) private _auctionIDtoSellerAddress;

    function getNFTsAuctionList( address _contractNFT) public view returns (uint256[] memory) {
        return _contractsTokenIdsList[_contractNFT].collection();
    }
    function sellerAddressFor( uint256 _auctionID) public view returns (address) {
        return _auctionIDtoSellerAddress[_auctionID];
    }
    function getAuction(
        address _contractNFT,
        uint256 _tokenId
    ) public view returns
    (
        address seller,
        address latestBidder,
        uint256 latestBidTime,
        uint256 deadline,
        uint price
    ) {
        uint256 index = uint256(_contractNFT).add(_tokenId);
        return 
        (
            _contractsPlusTokenIdsAuction[index].seller,
            _contractsPlusTokenIdsAuction[index].latestBidder,
            _contractsPlusTokenIdsAuction[index].latestBidTime,
            _contractsPlusTokenIdsAuction[index].deadline,
            _contractsPlusTokenIdsAuction[index].price
        );
    }

    function sell( address _contractNFT, uint256 _tokenId, uint256 _price, bool _isERC1155 ) public {
        require(!_contractsTokenIdsList[_contractNFT].contains(uint256(msg.sender).add(_tokenId)), "CORSAC: auction is already created");
        // require(IERC20(_CSCT).balanceOf(msg.sender) >= (10 ** uint256(18)), "CORSAC: you must have 1 CSCT on account to start"); // For test. U must change 18 to 9 for CSCT.
        if (_isERC1155) {
            IERC1155(_contractNFT).safeTransferFrom( msg.sender, address(this), _tokenId,1, "0x0");
        } else {
            IERC721(_contractNFT).safeTransferFrom( msg.sender, address(this), _tokenId);
        }
        Auction memory _auction = Auction({
            seller: msg.sender,
            latestBidder: address(0),
            latestBidTime: 0,
            deadline: 0,
            price:_price
        });
        _contractsPlusTokenIdsAuction[uint256(_contractNFT).add(_tokenId)] = _auction;
        _auctionIDtoSellerAddress[uint256(msg.sender).add(_tokenId)] = msg.sender;
        _contractsTokenIdsList[_contractNFT].add(uint256(msg.sender).add(_tokenId));
        // IERC20(_CSCT).transferFrom(msg.sender, address(this), 10 ** uint256(18));
        // emit AuctionNFTCreated( _contractNFT, _tokenId, _price, 0, _isERC1155, msg.sender);
    }

    function buy (
        bool _isERC1155,
        address _contractNFT,
        uint256 _tokenId,
        uint256 _price
    ) public  {
        Auction storage auction = _contractsPlusTokenIdsAuction[uint256(_contractNFT).add(_tokenId)];
        require(auction.seller != address(0), "CORSAC: wrong seller address");
        require(IERC20(_CSCT).balanceOf(msg.sender) >= _price, "CORSAC: you have not enough CORSAC");
        require(_contractsTokenIdsList[_contractNFT].contains(uint256(auction.seller).add(_tokenId)), "CORSAC: auction is not created"); // ERC1155 can have more than 1 auction with same ID and , need mix tokenId with seller address
        require(_price >= auction.price, "CORSAC: price must be more than previous bid");
        if (_isERC1155) {
            IERC1155(_contractNFT).safeTransferFrom( address(this), msg.sender, _tokenId, 1, "0x0");
        } else {
            IERC721(_contractNFT).safeTransferFrom( address(this), msg.sender, _tokenId);
        }
        IERC20(_CSCT).transferFrom(msg.sender, auction.seller, _price);
        emit AuctionNFTBid(_contractNFT,_tokenId,_price,0,_isERC1155,msg.sender,auction.seller, true);
        delete _contractsPlusTokenIdsAuction[ uint256(_contractNFT).add(_tokenId)];
        delete _auctionIDtoSellerAddress[uint256(auction.seller).add(_tokenId)];
        _contractsTokenIdsList[_contractNFT].remove(uint256(auction.seller).add(_tokenId));
    }
    event AuctionNFTCreated(address indexed contractNFT, uint256 tokenId,uint256 price,uint256 deadline, bool isERC1155,address seller);

    function createAuction( address _contractNFT, uint256 _tokenId, uint256 _price, uint256 _deadline, bool _isERC1155 ) public {
        require(!_contractsTokenIdsList[_contractNFT].contains(uint256(msg.sender).add(_tokenId)), "CORSAC: auction is already created");
        // require(IERC20(_CSCT).balanceOf(msg.sender) >= (10 ** uint256(18)), "CORSAC: you must have 1 CSCT on account to start"); // For test. U must change 18 to 9 for CSCT.
        if (_isERC1155) {
            IERC1155(_contractNFT).safeTransferFrom( msg.sender, address(this), _tokenId,1, "0x0");
        } else {
            IERC721(_contractNFT).safeTransferFrom( msg.sender, address(this), _tokenId);
        }
        Auction memory _auction = Auction({
            seller: msg.sender,
            latestBidder: address(0),
            latestBidTime: 0,
            deadline: _deadline,
            price:_price
        });
        _contractsPlusTokenIdsAuction[uint256(_contractNFT).add(_tokenId)] = _auction;
        _auctionIDtoSellerAddress[uint256(msg.sender).add(_tokenId)] = msg.sender;
        _contractsTokenIdsList[_contractNFT].add(uint256(msg.sender).add(_tokenId));
        // IERC20(_CSCT).transferFrom(msg.sender, address(this), 10 ** uint256(18));
        emit AuctionNFTCreated( _contractNFT, _tokenId, _price, _deadline, _isERC1155, msg.sender);
    }
   
    event AuctionNFTBid(address indexed contractNFT, uint256 tokenId,uint256 price,uint256 deadline, bool isERC1155,address buyer,address seller, bool isDeal);

    function _bidWin (
        bool _isERC1155,
        address _contractNFT,
        address _sender,
        uint256 _tokenId,
        address _auctionSeller,
        uint256 _price,
        uint256 _deadline

    ) private  {
        if (_isERC1155) {
            IERC1155(_contractNFT).safeTransferFrom( address(this), _sender, _tokenId, 1, "0x0");
        } else {
            IERC721(_contractNFT).safeTransferFrom( address(this), _sender, _tokenId);
        }
        IERC20(_CSCT).transferFrom(_sender, _auctionSeller, _price);
        emit AuctionNFTBid(_contractNFT,_tokenId,_price,_deadline,_isERC1155,_sender,_auctionSeller, true);
        delete _contractsPlusTokenIdsAuction[ uint256(_contractNFT).add(_tokenId)];
        delete _auctionIDtoSellerAddress[uint256(_auctionSeller).add(_tokenId)];
        _contractsTokenIdsList[_contractNFT].remove(uint256(_auctionSeller).add(_tokenId));
    }

    function bid( address _contractNFT,uint256 _tokenId, uint256 _price, bool _isERC1155 ) public returns (bool, uint256, address) {
        
        Auction storage auction = _contractsPlusTokenIdsAuction[uint256(_contractNFT).add(_tokenId)];
        require(auction.seller != address(0), "CORSAC: wrong seller address");
        require(IERC20(_CSCT).balanceOf(msg.sender) >= _price, "CORSAC: you have not enough CORSAC");
        require(_contractsTokenIdsList[_contractNFT].contains(uint256(auction.seller).add(_tokenId)), "CORSAC: auction is not created"); // ERC1155 can have more than 1 auction with same ID and , need mix tokenId with seller address
        require(_price >= auction.price, "CORSAC: price must be more than previous bid");

        if (block.timestamp > auction.deadline) {
            address auctionSeller = address(auction.seller);
            _bidWin(
                _isERC1155,
                _contractNFT,
                msg.sender,
                _tokenId,
                auctionSeller,
                _price,
                auction.deadline
            );
            return (true,0,auctionSeller);
        } else {
            auction.price = _price;
            auction.latestBidder = msg.sender;
            auction.latestBidTime = block.timestamp;
            
            emit AuctionNFTBid(_contractNFT,_tokenId,_price,auction.deadline,_isERC1155,msg.sender,auction.seller, false);
            if (auction.latestBidder != address(0)) {
                return (false,auction.price,auction.latestBidder);
            }
        }
        return (false,0, address(0));
    }
    event AuctionNFTCanceled(address indexed contractNFT, uint256 tokenId,uint256 price,uint256 deadline, bool isERC1155,address seller);

    function _cancelAuction( address _contractNFT, uint256 _tokenId, address _sender, bool _isERC1155, bool _isAdmin ) private {
        uint256 index = uint256(_contractNFT).add(_tokenId);

        Auction storage auction = _contractsPlusTokenIdsAuction[index];
        if (!_isAdmin) require(auction.seller == _sender, "CORSAC: only seller can cancel");
        if (_isERC1155) {
            IERC1155(_contractNFT).safeTransferFrom(address(this),auction.seller, _tokenId,1,"0x0");
        } else {
            IERC721(_contractNFT).safeTransferFrom(address(this),auction.seller, _tokenId);
        }
        address auctionSeller = address(auction.seller);
        emit AuctionNFTCanceled(_contractNFT,_tokenId,auction.price,auction.deadline,_isERC1155,auction.seller);
        delete _contractsPlusTokenIdsAuction[index];
        delete _auctionIDtoSellerAddress[uint256(auctionSeller).add(_tokenId)];
        _contractsTokenIdsList[_contractNFT].remove(uint256(auctionSeller).add(_tokenId));
    }

    function cancelAuction( address _contractNFT, uint256 _tokenId, bool _isERC1155 ) public {
        
        require(_contractsTokenIdsList[_contractNFT].contains(uint256(msg.sender).add(_tokenId)), "CORSAC: auction is not created");
        _cancelAuction( _contractNFT, _tokenId, msg.sender, _isERC1155, false );
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata 
    )
    external
    override
    returns(bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address ,
        address ,
        uint256[] calldata,
        uint256[] calldata ,
        bytes calldata 
    )
    external
    override
    returns(bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return this.supportsInterface(interfaceId);
    }
}