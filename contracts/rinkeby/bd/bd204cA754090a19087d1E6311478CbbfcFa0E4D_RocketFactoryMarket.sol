// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RocketFactoryMarket is Ownable, IERC721Receiver, ReentrancyGuard {
    /*
        EVENTS
    */
    event ItemOnAuction(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Auction auction
    );
    event ItemClaimed(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Auction auction
    );
    event ItemBidded(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Auction auction
    );
    event ItemForSale(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Sale sale
    );
    event ItemSold(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        address buyer,
        Sale sale
    );
    event ItemSaleCancelled(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Sale sale
    );
    event TradeCreated(uint256 timestamp, Trade trade);
    event TradeAccepted(uint256 timestamp, Trade trade);
    event TradeCancelled(uint256 timestamp, Trade trade);
    event TradeRejected(uint256 timestamp, Trade trade);
    event OfferCreated(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Offer offer
    );
    event OfferAccepted(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Offer offer
    );
    event OfferCancelled(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Offer offer
    );
    event OfferRejected(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Offer offer
    );

    /*
        STRUCTS
    */
    struct Sale {
        address seller;
        address erc20;
        uint256 itemId;
        uint8 itemType;
        uint256 price;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 duration;
    }

    struct Auction {
        address seller;
        address erc20;
        uint256 itemId;
        uint8 itemType;
        uint256 startPrice;
        uint256 startTimestamp;
        uint256 endTimestamp;
        address maxBidderAddress;
        uint256 maxBidTimestamp;
        uint256 maxBidAmount;
    }

    struct Item {
        uint256 itemId;
        uint8 itemType;
    }

    struct Trade {
        address offerer;
        address offeree;
        Item[] offering;
        Item[] requesting;
    }

    struct Offer {
        address offerer;
        address offeree;
        uint256 itemId;
        uint8 itemType;
        uint256 price;
        address erc20;
    }

    mapping(uint8 => mapping(uint256 => Auction)) public itemsToAuction;
    mapping(uint8 => mapping(uint256 => Sale)) public itemsToSale;
    mapping(address => mapping(address => Trade)) public trades;
    mapping(uint8 => mapping(uint256 => mapping(address => Offer))) public offers;
    mapping(uint8 => address) itemTypeToTokenAddress;
    mapping(address => bool) allowedErc20;

    /* 
        MODIFIERS
    */
    modifier itemForSale(uint256 _itemId, uint8 _itemType) {
        require(
            itemsToSale[_itemType][_itemId].seller != address(0x0),
            "The item is not for sale"
        );
        _;
    }

    modifier itemNotForSale(uint256 _itemId, uint8 _itemType) {
        require(
            itemsToSale[_itemType][_itemId].seller == address(0x0),
            "The item is for sale"
        );
        _;
    }

    modifier itemOnAuction(uint256 _itemId, uint8 _itemType) {
        require(
            itemsToAuction[_itemType][_itemId].seller != address(0x0),
            "The item is not on auction"
        );
        _;
    }

    modifier itemNotOnAuction(uint256 _itemId, uint8 _itemType) {
        require(
            itemsToAuction[_itemType][_itemId].seller == address(0x0),
            "The item is on auction"
        );
        _;
    }

    modifier itemTypeExists(uint8 _itemType) {
        require(
            itemTypeToTokenAddress[_itemType] != address(0x0),
            "The item type does not exist"
        );
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /* 
        MANAGEMENT METHODS 
    */
    constructor() {
        allowedErc20[address(0x0)] = true;
    }

    function setItemTokenAddress(uint8 _itemType, address _itemTokenAddress)
        public
        onlyOwner
    {
        itemTypeToTokenAddress[_itemType] = _itemTokenAddress;
    }

    function setAllowedERC20(address _erc20, bool _allowed) public onlyOwner {
        allowedErc20[_erc20] = _allowed;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /* 
        SALES
    */
    function createSale(
        uint256 _itemId,
        uint8 _itemType,
        uint256 _price,
        uint256 _duration,
        address _erc20
    )
        public
        itemTypeExists(_itemType)
        itemNotOnAuction(_itemId, _itemType)
        itemNotForSale(_itemId, _itemType)
    {
        IERC721 token = IERC721(itemTypeToTokenAddress[_itemType]);
        require(
            allowedErc20[_erc20] == true,
            "The specified ERC20 token is not allowed"
        );
        require(
            token.ownerOf(_itemId) == msg.sender,
            "Only the item owner can create an auction"
        );
        require(_price > 0, "Minimum price must be above 0");

        token.safeTransferFrom(msg.sender, address(this), _itemId);

        Sale storage sale = itemsToSale[_itemType][_itemId];

        sale.seller = msg.sender;
        sale.erc20 = _erc20;
        sale.itemId = _itemId;
        sale.itemType = _itemType;
        sale.price = _price;
        sale.startTimestamp = block.timestamp;
        sale.endTimestamp = _duration == 0 ? 0 : block.timestamp + _duration;
        sale.duration = _duration;

        emit ItemForSale(block.timestamp, _itemId, _itemType, sale);
    }

    function buy(
        uint256 _itemId,
        uint8 _itemType,
        address _erc20
    )
        public
        payable
        callerIsUser()
        itemTypeExists(_itemType)
        itemForSale(_itemId, _itemType)
    {
        Sale memory sale = itemsToSale[_itemType][_itemId];
        require(
            sale.erc20 == _erc20,
            "The specified ERC20 token is not allowed for this sale"
        );

        // require(msg.sender != sale.seller, "Cant buy on your own sale"); TODO

        if (sale.duration != 0) {
            require(
                block.timestamp > sale.startTimestamp &&
                    (block.timestamp < sale.endTimestamp ||
                        sale.endTimestamp == 0),
                "Sale has finished already"
            );
        }

        if (_erc20 == address(0x0)) {
            require(
                msg.value >= sale.price,
                "Not enough Ether sent to complete the sale"
            );

            if (msg.value > sale.price) {
                uint256 refund = msg.value - sale.price;
                payable(msg.sender).transfer(refund);
            }

            payable(sale.seller).transfer(sale.price);
        } else {
            IERC20(_erc20).transferFrom(msg.sender, sale.seller, sale.price);
        }

        delete itemsToSale[_itemType][_itemId];

        IERC721(itemTypeToTokenAddress[_itemType]).safeTransferFrom(
            address(this),
            msg.sender,
            _itemId
        );

        emit ItemSold(block.timestamp, _itemId, _itemType, msg.sender, sale);
    }

    function cancelSale(uint256 _itemId, uint8 _itemType)
        public
        itemTypeExists(_itemType)
        itemForSale(_itemId, _itemType)
    {
        Sale memory sale = itemsToSale[_itemType][_itemId];
        require(
            sale.seller == msg.sender,
            "Only the creator can cancel the sale"
        );
        delete itemsToSale[_itemType][_itemId];
        IERC721(itemTypeToTokenAddress[_itemType]).safeTransferFrom(
            address(this),
            msg.sender,
            _itemId
        );
        emit ItemSaleCancelled(block.timestamp, _itemId, _itemType, sale);
    }

    /*
       AUCTIONS
    */
    function createAuction(
        uint256 _itemId,
        uint8 _itemType,
        uint256 _startPrice,
        uint256 _duration,
        address _erc20
    )
        public
        itemTypeExists(_itemType)
        itemNotOnAuction(_itemId, _itemType)
        itemNotForSale(_itemId, _itemType)
    {
        IERC721 token = IERC721(itemTypeToTokenAddress[_itemType]);
        require(
            token.ownerOf(_itemId) == msg.sender,
            "Only the item owner can create an auction"
        );
        require(
            allowedErc20[_erc20] == true,
            "The specified ERC20 token is not allowed"
        );

        token.safeTransferFrom(msg.sender, address(this), _itemId);

        Auction storage auction = itemsToAuction[_itemType][_itemId];
        auction.seller = msg.sender;
        auction.itemId = _itemId;
        auction.itemType = _itemType;
        auction.startPrice = _startPrice;
        auction.maxBidAmount = _startPrice;
        auction.endTimestamp = block.timestamp + _duration;
        auction.startTimestamp = block.timestamp;
        auction.erc20 = _erc20;

        emit ItemOnAuction(block.timestamp, _itemId, _itemType, auction);
    }

    function placeBid(
        uint256 _itemId,
        uint8 _itemType,
        uint256 _bid,
        address _erc20
    )
        public
        payable
        callerIsUser()
        nonReentrant()
        itemTypeExists(_itemType)
        itemOnAuction(_itemId, _itemType)
    {
        Auction storage auction = itemsToAuction[_itemType][_itemId];

        require(msg.sender != auction.seller, "Cant bid on your own auction");
        require(
            block.timestamp >= auction.startTimestamp &&
                block.timestamp <= auction.endTimestamp,
            "Auction has finished already"
        );
        require(
            auction.erc20 == _erc20,
            "The specified ERC20 token is not allowed for this auction"
        );

        uint256 bid = _erc20 == address(0x0) ? msg.value : _bid;

        require(
            auction.maxBidderAddress != msg.sender,
            "You are the winning bidder"
        );
        require(
            bid > auction.maxBidAmount,
            "Not enough to top the current bid"
        );

        if (_erc20 != address(0x0)) {
            IERC20(_erc20).transferFrom(msg.sender, address(this), bid);
        }

        if (auction.maxBidderAddress != address(0x0)) {
            if (auction.erc20 == address(0x0)) {
                payable(auction.maxBidderAddress).transfer(
                    auction.maxBidAmount
                );
            } else {
                IERC20(_erc20).transfer(
                    auction.maxBidderAddress,
                    auction.maxBidAmount
                );
            }
        }

        auction.maxBidderAddress = msg.sender;
        auction.maxBidAmount = bid;
        auction.maxBidTimestamp = block.timestamp;

        emit ItemBidded(block.timestamp, _itemId, _itemType, auction);
    }

    function claim(uint256 _itemId, uint8 _itemType)
        public
        callerIsUser()
        itemTypeExists(_itemType)
        itemOnAuction(_itemId, _itemType)
    {
        Auction memory auction = itemsToAuction[_itemType][_itemId];
        require(
            block.timestamp > auction.endTimestamp,
            "Auction is not finished"
        );
        require(
            auction.maxBidderAddress == msg.sender ||
                (auction.maxBidderAddress == address(0x0) &&
                    auction.seller == msg.sender),
            "Only the winner can claim the item"
        );

        delete itemsToAuction[_itemType][_itemId];

        if (auction.seller != msg.sender) {
            if (auction.erc20 != address(0x0)) {
                IERC20(auction.erc20).transfer(
                    auction.seller,
                    auction.maxBidAmount
                );
            } else {
                payable(auction.seller).transfer(auction.maxBidAmount);
            }
        }

        IERC721(itemTypeToTokenAddress[_itemType]).safeTransferFrom(
            address(this),
            msg.sender,
            _itemId
        );
        emit ItemClaimed(block.timestamp, _itemId, _itemType, auction);
    }

    /*
       TRADES
    */
    function proposeTrade(
        Item[] memory _offers,
        Item[] memory _requests,
        address _offeree
    ) public callerIsUser() {
        Trade storage trade = trades[_offeree][msg.sender];

        require(
            trade.offerer == address(0x0),
            "There is already a trade offering for the specified recipient"
        );

        for (uint256 i = 0; i < _offers.length; i++) {
            require(
                itemTypeToTokenAddress[_offers[i].itemType] != address(0x0),
                "The item type does not exist"
            );
            IERC721(itemTypeToTokenAddress[_offers[i].itemType])
                .safeTransferFrom(msg.sender, address(this), _offers[i].itemId);
            trade.offering.push(Item(_offers[i].itemId, _offers[i].itemType));
        }

        for (uint256 i = 0; i < _requests.length; i++) {
            require(
                itemTypeToTokenAddress[_requests[i].itemType] != address(0x0),
                "The item type does not exist"
            );
            require(
                IERC721(itemTypeToTokenAddress[_requests[i].itemType]).ownerOf(
                    _requests[i].itemId
                ) == _offeree,
                "A requested item does not belong to the specified wallet"
            );
            trade.requesting.push(
                Item(_requests[i].itemId, _requests[i].itemType)
            );
        }

        trade.offerer = msg.sender;
        trade.offeree = _offeree;

        emit TradeCreated(block.timestamp, trade);
    }

    function acceptTrade(address _offerer) public callerIsUser() {
        Trade memory trade = trades[msg.sender][_offerer];

        require(
            trade.offerer != address(0x0),
            "No received trade offering found for the specified address"
        );

        delete trades[msg.sender][_offerer];

        for (uint256 i = 0; i < trade.offering.length; i++) {
            IERC721(itemTypeToTokenAddress[trade.offering[i].itemType])
                .safeTransferFrom(
                address(this),
                msg.sender,
                trade.offering[i].itemId
            );
        }

        for (uint256 i = 0; i < trade.requesting.length; i++) {
            IERC721(itemTypeToTokenAddress[trade.requesting[i].itemType])
                .safeTransferFrom(
                msg.sender,
                trade.offerer,
                trade.requesting[i].itemId
            );
        }

        emit TradeAccepted(block.timestamp, trade);
    }

    function cancelTrade(address _offeree) public callerIsUser() {
        Trade memory trade = trades[_offeree][msg.sender];

        require(
            trade.offerer != address(0x0),
            "No sent trade offering found for the specified address"
        );

        delete trades[_offeree][msg.sender];

        for (uint256 i = 0; i < trade.offering.length; i++) {
            IERC721(itemTypeToTokenAddress[trade.offering[i].itemType])
                .safeTransferFrom(
                address(this),
                trade.offerer,
                trade.offering[i].itemId
            );
        }

        emit TradeCancelled(block.timestamp, trade);
    }

    function rejectTrade(address _offerer) public callerIsUser() {
        Trade memory trade = trades[msg.sender][_offerer];

        require(
            trade.offerer != address(0x0),
            "No received trade offering found for the specified address"
        );

        delete trades[msg.sender][_offerer];

        for (uint256 i = 0; i < trade.offering.length; i++) {
            IERC721(itemTypeToTokenAddress[trade.offering[i].itemType])
                .safeTransferFrom(
                address(this),
                trade.offerer,
                trade.offering[i].itemId
            );
        }

        emit TradeRejected(block.timestamp, trade);
    }

    /*
       OFFERS
    */
    function makeAnOffer(
        uint256 _itemId,
        uint8 _itemType,
        uint256 _price,
        address _erc20
    ) public payable callerIsUser() nonReentrant() {
        require(
            itemTypeToTokenAddress[_itemType] != address(0x0),
            "The item type does not exist"
        );

        address tokenOwner = IERC721(itemTypeToTokenAddress[_itemType]).ownerOf(_itemId);

        uint256 price = _erc20 == address(0x0) ? msg.value : _price;

        Offer storage offer = offers[_itemType][_itemId][msg.sender];
        offer.offerer = msg.sender;
        offer.offeree = tokenOwner;
        offer.price = price;
        offer.itemId = _itemId;
        offer.itemType = _itemType;
        offer.erc20 = _erc20;


        if (_erc20 != address(0x0)) {
            IERC20(_erc20).transferFrom(msg.sender, address(this), price);
        }

        emit OfferCreated(block.timestamp, offer.itemId, offer.itemType, offer);
    }

    function cancelOffer(uint8 _itemType, uint256 _itemId)
        public
        callerIsUser()
        nonReentrant()
    {
        Offer memory offer = offers[_itemType][_itemId][msg.sender];
        delete offers[_itemType][_itemId][msg.sender];
         // NOTE: Should check offer exists before
        if (offer.erc20 != address(0x0)) {
            IERC20(offer.erc20).transfer(msg.sender, offer.price);
        } else {
            payable(msg.sender).transfer(offer.price);
        }

        emit OfferCancelled(
            block.timestamp,
            offer.itemId,
            offer.itemType,
            offer
        );
    }

    function acceptOffer(address _offerer, uint8 _itemType, uint256 _itemId) public callerIsUser() {
        Offer memory offer = offers[_itemType][_itemId][_offerer];
        delete offers[_itemType][_itemId][_offerer];

        IERC721(itemTypeToTokenAddress[offer.itemType]).safeTransferFrom(
            msg.sender,
            offer.offerer,
            offer.itemId
        );

        if (offer.erc20 != address(0x0)) {
            IERC20(offer.erc20).transfer(msg.sender, offer.price);
        } else {
            payable(msg.sender).transfer(offer.price);
        }

        emit OfferAccepted(
            block.timestamp,
            offer.itemId,
            offer.itemType,
            offer
        );
    }

    function rejectOffer(address _offerer, uint8 _itemType, uint256 _itemId)
        public
        callerIsUser()
        nonReentrant()
    {
        Offer memory offer = offers[_itemType][_itemId][_offerer];
        delete offers[_itemType][_itemId][_offerer];

        if (offer.erc20 != address(0x0)) {
            IERC20(offer.erc20).transfer(offer.offerer, offer.price);
        } else {
            payable(offer.offerer).transfer(offer.price);
        }

        emit OfferRejected(
            block.timestamp,
            offer.itemId,
            offer.itemType,
            offer
        );
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

    constructor () {
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

// SPDX-License-Identifier: MIT

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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