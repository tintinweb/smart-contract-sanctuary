/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Required interface of an ERC1155 compliant contract.
 */
interface IERC1155{
    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);
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
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}



// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

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


// For future use to allow buyers to receive a discount depending on staking or other rules.
interface IDiscountManager {
    function getDiscount(address buyer) external view returns (uint256 discount);
}


contract NFTMarket is ReentrancyGuard {
    
    using SafeMath for uint256;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
    _;
    }
    
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds; // Id for each individual item
    Counters.Counter private _itemsSold; // Number of items sold
    Counters.Counter private _itemsCancelled; // Number of items sold


    Counters.Counter private _offerIds; // Tracking offers

    address payable public owner; // The owner of the NFTMarket contract 
    address public discountManager = address(0x0); // a contract that can be callled to discover if there is a discount on the transaction fee.

    uint256 public saleFeePercentage = 5; // Percentage fee paid to team for each sale
    uint256 public volumeTraded = 0; // Total amount traded

    constructor() {
    }


    struct MarketOffer {
        uint256 offerId;
        address payable bidder;
        uint256 offerAmount;
        uint256 offerTime;
        bool cancelled;
        bool accepted;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        uint256 amount;
        address payable seller;
        address payable buyer;
        string category;
        uint256 price;
        bool isSold;
        bool cancelled;
    }

    mapping(uint256 => MarketItem) public idToMarketItem;
    mapping(address => mapping(uint256 => uint256[])) public contractToTokenToItemId;

    mapping(uint256 => MarketOffer[]) private idToMarketOffers;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        string category,
        uint256 price
    );
    
     event MarketSaleCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        string category,
        uint256 price
    );

    event ItemOfferCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        address owner,
        address bidder,
        uint256 bidAmount
    );

    // offers
     function makeOffer(uint256 itemId) public payable nonReentrant{
        require(itemId > 0 && itemId<=_itemIds.current(), "Invalid item id.");
        require(idToMarketItem[itemId].isSold==false && idToMarketItem[itemId].cancelled==false , "This item is not for sale.");
        require(idToMarketItem[itemId].seller!=msg.sender , "Can't bid on your own item.");
        require(msg.value>0, "Can't offer nothing.");
        uint256 offerIndex = idToMarketOffers[itemId].length;
        idToMarketOffers[itemId].push(MarketOffer(offerIndex,payable(msg.sender),msg.value,block.timestamp,false, false));
    }
        
    function acceptOffer(uint256 itemId, uint256 offerIndex) public nonReentrant{
        require(offerIndex<=idToMarketOffers[itemId].length, "Invalid offer index");
        require(idToMarketItem[itemId].isSold==false && idToMarketItem[itemId].cancelled==false , "This item is not for sale.");
        require(idToMarketOffers[itemId][offerIndex].accepted==false && idToMarketOffers[itemId][offerIndex].cancelled==false, "Already accepted or cancelled.");
        
        uint256 price = idToMarketOffers[itemId][offerIndex].offerAmount;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        address bidder = payable(idToMarketOffers[itemId][offerIndex].bidder);
        
        uint256 fees = SafeMath.div(price,100).mul(saleFeePercentage);

        idToMarketOffers[itemId][offerIndex].accepted = true;

        if (discountManager!=address(0x0)){
            // how much discount does this user get?
            uint256 feeDiscountPercent = IDiscountManager(discountManager).getDiscount(msg.sender);
            fees = fees.div(100).mul(feeDiscountPercent);
        }
        
        uint256 saleAmount = price.sub(fees);
        
        idToMarketItem[itemId].seller.transfer(saleAmount);
        
        IERC1155(idToMarketItem[itemId].nftContract).safeTransferFrom(address(this),  bidder, tokenId, idToMarketItem[itemId].amount, "");
        
        idToMarketItem[itemId].isSold = true;
        idToMarketItem[itemId].buyer = payable(bidder);
        _itemsSold.increment();

        uint256[] storage marketItems = contractToTokenToItemId[idToMarketItem[itemId].nftContract][idToMarketItem[itemId].tokenId];
        for(uint i =0; i <= marketItems.length; i++)
        {
            if(marketItems[i] == itemId)
            {
                marketItems[i] = marketItems[marketItems.length-1];
                marketItems.pop();
                break;
            }
        }

        emit MarketSaleCreated(
            itemId,
            idToMarketItem[itemId].nftContract,
            tokenId,
            idToMarketItem[itemId].seller,
            msg.sender,
            idToMarketItem[itemId].category,
            price
        );
        
    }
    
    function cancelOffer(uint256 itemId, uint256 offerIndex) public nonReentrant{
        require(idToMarketOffers[itemId][offerIndex].bidder==msg.sender && idToMarketOffers[itemId][offerIndex].cancelled==false , "Wrong bidder or offer is already cancelled");
        require(idToMarketOffers[itemId][offerIndex].accepted==false, "Already accepted.");
        
        address bidder = idToMarketOffers[itemId][offerIndex].bidder;

        idToMarketOffers[itemId][offerIndex].cancelled = true;
        payable(bidder).transfer(idToMarketOffers[itemId][offerIndex].offerAmount);

        //TODO emit
    }

    function getMarketOffers(uint256 itemId) public view returns (MarketOffer[] memory) {
        
        uint256 openOfferCount = 0;
        uint256 currentIndex = 0;
        MarketOffer[] memory marketOffers = idToMarketOffers[itemId];

        for (uint256 i = 0; i < marketOffers.length; i++) {
            if (marketOffers[i].accepted==false && marketOffers[i].cancelled==false){
                openOfferCount++;
            }
        }
          
        MarketOffer[] memory openOffers =  new MarketOffer[](openOfferCount);
        
        for (uint256 i = 0; i < marketOffers.length; i++) {
            if (marketOffers[i].accepted==false && marketOffers[i].cancelled==false){
                MarketOffer memory currentItem = marketOffers[i];
                openOffers[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        
        return openOffers;
    }


    // returns the total number of items sold
    function getItemsSold() public view returns(uint256){
        return _itemsSold.current();
    }
    
    // returns the current number of listed items
    function numberOfItemsListed() public view returns(uint256){
        uint256 unsoldItemCount = _itemIds.current() - (_itemsSold.current()+_itemsCancelled.current());
        return unsoldItemCount;
    }

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        string calldata category
    ) public payable nonReentrant {
        require(price > 0, "No item for free here");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            amount,
            payable(msg.sender),
            payable(address(0)), // No owner for the item
            category,
            price,
            false,
            false
        );
        IERC1155(nftContract).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        contractToTokenToItemId[nftContract][tokenId].push(itemId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            category,
            price
        );
    }
    
    // cancels a market item that's for sale
    function cancelMarketItem(uint256 itemId) public {
        require(itemId <=_itemIds.current());
        require(idToMarketItem[itemId].seller==msg.sender);
        require(idToMarketItem[itemId].cancelled==false && idToMarketItem[itemId].isSold==false);
        require(IERC1155(idToMarketItem[itemId].nftContract).balanceOf(address(this), idToMarketItem[itemId].tokenId) > 0); // should never fail
        idToMarketItem[itemId].cancelled=true;
         _itemsCancelled.increment();
        IERC1155(idToMarketItem[itemId].nftContract).safeTransferFrom(address(this), msg.sender, idToMarketItem[itemId].tokenId, idToMarketItem[itemId].amount, "");
        uint256[] storage marketItems = contractToTokenToItemId[idToMarketItem[itemId].nftContract][idToMarketItem[itemId].tokenId];
        for(uint i =0; i <= marketItems.length; i++)
        {
            if(marketItems[i] == itemId)
            {
                marketItems[i] = marketItems[marketItems.length-1];
                marketItems.pop();
                break;
            }
        }

        //TODO emit
    }

    function createMarketSale(uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        uint256 amount = idToMarketItem[itemId].amount;
        require(
            msg.value == price,
            "Please make the price to be same as listing price"
        );
        require(idToMarketItem[itemId].isSold==false, "This item is already sold.");
        require(idToMarketItem[itemId].cancelled==false, "This item is not for sale.");
        require(idToMarketItem[itemId].seller!=msg.sender , "Cannot buy your own item.");

        // take fees and transfer the balance to the seller (TODO)
        uint256 fees = SafeMath.div(price,100).mul(saleFeePercentage);

        if (discountManager!=address(0x0)){
            // how much discount does this user get?
            uint256 feeDiscountPercent = IDiscountManager(discountManager).getDiscount(msg.sender);
            fees = fees.div(100).mul(feeDiscountPercent);
        }
        
        uint256 saleAmount = price.sub(fees);
        idToMarketItem[itemId].seller.transfer(saleAmount);
        IERC1155(idToMarketItem[itemId].nftContract).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        idToMarketItem[itemId].isSold = true;
        idToMarketItem[itemId].buyer = payable(msg.sender);
        _itemsSold.increment();
        uint256[] storage marketItems = contractToTokenToItemId[idToMarketItem[itemId].nftContract][idToMarketItem[itemId].tokenId];
        for(uint i =0; i <= marketItems.length; i++)
        {
            if(marketItems[i] == itemId)
            {
                marketItems[i] = marketItems[marketItems.length-1];
                marketItems.pop();
                break;
            }
        }

        emit MarketSaleCreated(
            itemId,
            idToMarketItem[itemId].nftContract,
            tokenId,
            idToMarketItem[itemId].seller,
            msg.sender,
            idToMarketItem[itemId].category,
            price
        );
        
    }

    // returns all of the current items for sale
    // 
    function getMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() - (_itemsSold.current()+_itemsCancelled.current());
        uint256 currentIndex = 0;

        MarketItem[] memory marketItems = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].buyer == address(0) && idToMarketItem[i + 1].cancelled==false && idToMarketItem[i + 1].isSold==false) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                marketItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return marketItems;
    }

    // returns the purchased items for this user
    function fetchPurchasedNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].buyer == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory marketItems = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].buyer == msg.sender) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                marketItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return marketItems;
    }


    // returns all items created by this user regardless of status (forsale, sold, cancelled)
    function fetchCreateNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1; // No dynamic length. Predefined length has to be made
            }
        }

        MarketItem[] memory marketItems = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                marketItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return marketItems;
    }

    // Get items by category
    // This could be used with different collections
    function getItemsByCategory(string calldata category)
        public
        view
        returns (MarketItem[] memory)
    {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                keccak256(abi.encodePacked(idToMarketItem[i + 1].category)) ==
                keccak256(abi.encodePacked(category)) &&
                idToMarketItem[i + 1].buyer == address(0) &&
                idToMarketItem[i + 1].cancelled == false &&
                idToMarketItem[i + 1].isSold == false
            ) {
                itemCount += 1;
            }
        }

        MarketItem[] memory marketItems = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                keccak256(abi.encodePacked(idToMarketItem[i + 1].category)) ==
                keccak256(abi.encodePacked(category)) &&
                idToMarketItem[i + 1].buyer == address(0) &&
                idToMarketItem[i + 1].cancelled == false &&
                idToMarketItem[i + 1].isSold == false
            ) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                marketItems[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return marketItems;
    }
    
    // administration functions
    function setSalePercentageFee(uint256 _amount) public onlyOwner{
        require(_amount<=5, "5% maximum fee allowed.");
        saleFeePercentage = _amount;
    }
    
    function setOwner(address _owner) public onlyOwner{
        require(_owner!=address(0x0), "0x0 address not permitted");
        owner = payable(_owner);
    }
    
    function setDiscountManager(address _discountManager) public onlyOwner{
        require(_discountManager!=address(0x0), "0x0 address not permitted");
        discountManager = _discountManager;
    }
    
    
}


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}