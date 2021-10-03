pragma solidity >=0.4.22 <0.9.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./IYaaasExchangeMultiple.sol";
import "./SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

contract YaaasExchangeMultiple is
    Ownable,
    IYaaasExchangeMultiple
{
    using SafeMath for uint256;


    //ERC1155
    mapping(uint256 => Offer) public offers;
    // For auctions bid by bider, collection and assetId
    mapping(uint256 => mapping(address => Bid)) public bidforAuctions;

    mapping(uint256 => uint256) public shares;

    constructor() {
        shares[1] = 1;
        shares[2] = 2;
        shares[3] = 2;
        shares[4] = 2;
        shares[5] = 2;
    }
    /**
    * @dev Create new offer
    * @param id an unique offer id
    * @param _seller the token owner
    * @param _collection the ERC1155 address
    * @param _assertId the NFT id
    * @param _isEther if sale in ether price
    * @param _price the sale price
    * @param _amount the amount of tokens owner wants to put in sale.
    * @param _isForSell if the token in direct sale
    * @param _isForAuction if the token in auctions
    * @param _expiresAt the offer's exprice date.
    * @param _shareIndex the percentage the contract owner earns in every sale
    */
    function addOffer(
        uint256 id,
        address _seller,
        address _collection,
        uint256 _assertId,
        bool _isEther,
        uint256 _price,
        uint256 _amount,
        bool _isForSell,
        bool _isForAuction,
        uint256 _expiresAt,
        uint256 _shareIndex
    ) public returns (bool success) {
        // get NFT asset from seller
        IERC1155Upgradeable nftCollection = IERC1155Upgradeable(_collection);
        require(
            nftCollection.balanceOf(_msgSender(), _assertId) >= _amount,
            "Insufficient token balance"
        );
        
        require(_seller == _msgSender(), "Seller should be equals owner");
       require(
            nftCollection.isApprovedForAll(_msgSender(), address(this)),
            "Contract not approved"
        );
        
        offers[id] = Offer(
            _seller,
            _collection,
            _assertId,
            _isEther,
            _price,
            _amount,
            _isForSell,
            _isForAuction,
            _expiresAt,
            _shareIndex
        );
        
        //nftCollection.safeTransferFrom(_seller, address(this), _assetId);
        emit Listed(_seller, _collection, _assertId, _amount, _price);
        return true;
    }

    function setOfferPrice(
        uint256 id,
        uint256 price
    ) public returns (bool) {
        Offer storage offer = _getOwnerOffer(id);
        offer.price = price;
        return true;
    }

    function setForSell(
        uint256 projectID,
        bool isForSell
    ) public returns (bool) {
        Offer storage offer = _getOwnerOffer(projectID);
        offer.isForSell = isForSell;
        return true;
    }

    function setForAuction(
        uint256 projectID,
        bool isForAuction
    ) public returns (bool) {
        Offer storage offer = _getOwnerOffer(projectID);
        offer.isForAuction = isForAuction;
        return true;
    }

    function setExpiresAt(
        uint256 projectID,
        uint256 expiresAt
    ) public returns (bool) {
        Offer storage offer = _getOwnerOffer(projectID);
        offer.expiresAt = expiresAt;
        return true;
    }

    function _getOwnerOffer(uint256 id)
        internal
        view
        returns (Offer storage)
    {
        Offer storage offer = offers[id];
        require(_msgSender() == offer.seller, "Marketplace: invalid owner");
        return offer;
    }

    function buyOffer(uint256 id, uint256 amount)
        public
        payable
        returns (bool success)
    {
        Offer storage offer = offers[id];
        require(msg.value > 0, "price must be >0");
        require(offer.isForSell, "Offer not for sell");
        _buyOffer(offer, offer.collection, amount);
        emit Swapped(
            _msgSender(),
            offer.seller,
            offer.collection,
            offer.assetId,
            msg.value
        );
        return true;
    }

    function _buyOffer(Offer storage offer, address collection, uint256 amount) internal {
        IERC1155Upgradeable nftCollection = IERC1155Upgradeable(collection);
        require(msg.value >= offer.price.mul(amount),"Yaaas: Insufficient funds");
        uint256 ownerBenif = (msg.value).mul(shares[offer.shareIndex]).div(100);
        uint256 sellerAmount = (msg.value).sub(ownerBenif);
        address _to = offer.seller;
        if (offer.isEther) {
            require(
                offer.price <= sellerAmount,
                "price should equal or upper to offer price"
            );
            (bool sent, ) = _to.call{value: sellerAmount}("");
            (bool benifSent, ) = owner().call{value: ownerBenif}("");
            require(sent, "Failed to send Ether");
            require(benifSent, "Failed to send Ether");
        }
        nftCollection.safeTransferFrom(_to, _msgSender(), offer.assetId, amount, "");
    }

    function safePlaceBid(
        uint256 _offer_id,
        address _token,
        uint256 _price,
        uint256 _amount,
        uint256 _expiresAt
    ) public {
        _createBid(_offer_id, _token, _price, _amount,_expiresAt);
    }

    function setOwnerShare(uint256 index, uint256 newShare) public onlyOwner {
        require(newShare >= 0 && newShare <= 100, "Owner Share must be >= 0 and <= 100");
        shares[index] = newShare;
    }

    function _createBid(
        uint256 offerID,
        address _token,
        uint256 _price,
        uint256 _amount,
        uint256 _expiresAt
    ) internal {
        // Checks order validity
        Offer memory offer = offers[offerID];
        // check on expire time
        if (_expiresAt > offer.expiresAt) {
            _expiresAt = offer.expiresAt;
        }
        // Check price if theres previous a bid
        Bid memory bid = bidforAuctions[offerID][_msgSender()];
        require(bid.id == 0, "bid already exists");
        require(offer.isForAuction, "NFT Marketplace: NFT token not in sell");
        require(
            IERC20(_token).allowance(_msgSender(), address(this)) >= _price,
            "NFT Marketplace: Allowance error"
        );
        // Create bid
        bytes32 bidId = keccak256(
            abi.encodePacked(block.timestamp, msg.sender, _price, _expiresAt)
        );

        // Save Bid for this order
        bidforAuctions[offerID][_msgSender()] = Bid({
            id: bidId,
            bidder: _msgSender(),
            token: _token,
            price: _price,
            amount: _amount,
            expiresAt: _expiresAt
        });

        emit BidCreated(
            bidId,
            offer.collection,
            offer.assetId,
            _msgSender(), // bidder
            _token,
            _price,
            _amount,
            _expiresAt
        );
    }

    function cancelBid(
        uint256 _offerId,
        address _bidder
    ) external returns (bool) {
        Offer memory offer = offers[_offerId];
        require(
            _bidder == _msgSender() ||
                _msgSender() == offer.seller,
            "Marketplace: Unauthorized operation"
        );
        Bid memory bid = bidforAuctions[_offerId][_msgSender()];
        delete bidforAuctions[_offerId][_bidder];
        emit BidCancelled(bid.id);
        return true;
    }

    function acceptBid(
        uint256 _offerID,
        address _bidder
    ) public {
        //get offer
        Offer memory offer = offers[_offerID];
        // get bid to accept
        Bid memory bid = bidforAuctions[_offerID][_bidder];

        // get service fees
        uint256 ownerBenif = (bid.price).div(100).mul(shares[offer.shareIndex]);
        uint256 sellerAmount = (bid.price).sub(ownerBenif);
        // check seller
        require(
            offer.seller == _msgSender(),
            "Marketplace: unauthorized sender"
        );
        require(offer.isForAuction, "Marketplace: offer not in auction");

        require(
            bid.expiresAt <= block.timestamp,
            "Marketplace: the bid expired"
        );

        delete bidforAuctions[_offerID][_bidder];
        emit BidAccepted(bid.id);
        // transfer escrowed bid amount minus market fee to seller
        IERC20(bid.token).transferFrom(bid.bidder, _msgSender(), sellerAmount);
        IERC20(bid.token).transferFrom(bid.bidder, owner(), ownerBenif);

        delete offers[_offerID];
        // Transfer NFT asset
        IERC1155Upgradeable(offer.collection).safeTransferFrom(
            offer.seller,
            bid.bidder,
            offer.assetId,
            bid.amount,
            ""
        );
        // Notify ..
        emit BidSuccessful(
            offer.collection,
            offer.assetId,
            bid.token,
            bid.bidder,
            bid.price,
            bid.amount
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
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
interface IERC165Upgradeable {
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

pragma solidity >=0.4.22 <0.9.0;

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
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
    constructor () {
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

pragma solidity >=0.4.22 <0.9.0;
contract IYaaasExchangeMultiple{
     event Swapped(
        address  buyer,
        address  seller,
        address  token,
        uint256  assetId,
        uint256  price
    );
    event Listed(
        address seller,
        address collection,
        uint256 assetId,
        uint256 price,
        uint256 amount
    );
    struct Offer{
        address seller;
        address collection;
        uint256 assetId;
        bool isEther;
        uint256 price;
        uint256 amount;
        bool isForSell;
        bool isForAuction;
        uint256 expiresAt;
        uint shareIndex;
    }
    struct Bid{
        bytes32 id;
        address bidder;
        address token;
        uint256 price;
        uint256 amount;
        uint256 expiresAt;
    }
    // BID EVENTS
    event BidCreated(
      bytes32 id,
      address indexed collection,
      uint256 indexed assetId,
      address indexed bidder,
      address  token,
      uint256 price,
      uint256 amount,
      uint256 expiresAt
    );
    event BidSuccessful(
        address collection,
        uint256 assetId,
        address token,
        address bidder,
        uint256 price,
        uint256 amount
    );
    event BidAccepted(bytes32 id);
    event BidCancelled(bytes32 id);
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}