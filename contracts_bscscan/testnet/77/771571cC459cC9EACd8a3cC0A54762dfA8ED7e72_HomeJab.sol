// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

// Link to Payment token
interface IBEP20TOKEN {

    // Transfer Payment token
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns(bool);
    
    // Return spending allowance
    function allowance(
      address _owner,
      address _spender
    ) external returns (uint256);

}

/**
 * @title HomeJab Marketplace version 1.0
 *
 * @author HomeJab(Joe Jesuele)
 */
contract HomeJab is ERC721Enumerable {

    // Address of owner of the contract
    address public owner;

    // Marketplace fee in terms of percentage
    uint8 public marketplaceFee;

    // Maximum batch size allowed
    uint8 public batchSize;

    // Contract address of payment token
    address public paymentToken;

    // Record bidder address and bidding amount
    struct Bid {
        address from;
        uint256 amount;
    }

    // Mapping from token Id to address of creator 
    mapping(uint256 => address) public creator;

    // Mapping from token Id to royalty fee associated with
    mapping(uint256 => uint8) public royalty;

    // Mapping from token Id to user bids
    mapping(uint256 => Bid[]) public auctionBids;

    /**
	 * @dev Fired in transferOwnership() when ownership transfered 
	 *
	 * @param _previousOwner an address of previous owner
	 * @param _newOwner an address of new owner
	 */
    event OwnershipTransferred(
        address indexed _previousOwner,
        address indexed _newOwner
    );

    /**
	 * @dev Fired in mint() when NFT minted
	 *
	 * @param _to an address of NFT minted to
	 * @param _id token Id of minted NFT 
     * @param _royaltyFee fees charged as royalty in terms of percentage
	 */
    event Minted(
        address indexed _to,
        uint256 indexed _id,
        uint8 _royaltyFee
    );

    /**
	 * @dev Fired in listForSell() when NFT listed for sell 
	 *
	 * @param _by an address of NFT owner
	 * @param _id token Id of listed NFT 
     * @param _price sell price for the NFT
     * @param _type sell type (0 = fixed price, 1 = english auction)
	 */
    event Listed(
        address indexed _by,
        uint256 indexed _id,
        uint256 _price,
        uint8 _type
    );

    /**
	 * @dev Fired in revokeSell() when NFT delisted  
	 *
	 * @param _by an address of NFT owner
	 * @param _id token Id of minted NFT
     */
    event Delisted(
        address indexed _by,
        uint256 indexed _id
    );

    /**
	 * @dev Fired in editPrice() when NFT relisted at new price 
	 *
	 * @param _by an address of NFT owner
	 * @param _id token Id of relisted NFT
     * @param _oldPrice sell price before relisting
     * @param _newPrice sell price after relisting
	 */
    event Relisted(
        address indexed _by,
        uint256 indexed _id,
        uint256 _oldPrice,
        uint256 _newPrice
    );

    /**
	 * @dev Fired in buy() when NFT bought 
	 *
     * @param _from an address of seller
	 * @param _to an address of buyer
	 * @param _id token Id of sold NFT 
     * @param _price price paid by buyer 
     * @param _marketplaceFee fees charged by marketplace 
     * @param _royaltyFee fees charged as royalty
	 */
    event Bought(
        address indexed _from,
        address indexed _to,
        uint256 indexed _id,
        uint256 _price,
        uint256 _marketplaceFee,
        uint256 _royaltyFee
    );

    /**
	 * @dev Fired in bidOnAuction() when bid is placed
	 *      for english auction successfully
	 *
	 * @param _from an address of bidder
	 * @param _id token Id of bidded NFT
	 * @param _amount defines bid amount to be paid
	 */
    event BidSuccess(
        address indexed _from,
        uint256 indexed _id,
        uint256 _amount
    );

    // To check ownership for restricted access functions
    modifier onlyOwner {

        verifyOwner();
    
        _;

    }

    // To check batch request lies within limits
    modifier batchLimit(uint256 length_) {

        verifyBatchLimit(length_);

        _;

    }

    /**
	 * @dev Creates/deploys HomeJab Marketplace
	 *
	 * @param fee_ marketplace fee in terms of percentage
	 * @param batchSize_ maximum allowed amount in a batch
	 * @param baseURI_ base URL for token metadata end point
	 * @param paymentToken_ address of BEP20 token for payments
	 */
    constructor(
        uint8 fee_,
        uint8 batchSize_,
        string memory baseURI_,
        address paymentToken_
    ) ERC721("HomeJab Market","REAL") {
        
        require(
            fee_ <= 10 && paymentToken_ != address(0),
            "HomeJab: Invalid input"
        );
        
        //----------Set Internal State----------//
        owner = msg.sender;

        marketplaceFee = fee_;

        batchSize = batchSize_;

        URI = baseURI_;

        paymentToken = paymentToken_;

    }

    /**
     * @dev Returns address of the owner
     */
    function getOwner() external view returns(address) {
        return owner;
    }    

    /**
     * @dev Returns royalty info as par the NFT Royalty Standard(EIP-2981) 
     * 
     * @notice Called with the sale price to determine how much royalty
     *          is owed and to whom.
     * @param id_ the NFT asset queried for royalty information
     * @param price_ the sale price of the NFT asset specified by id_
     * @return receiver_ address of who should be sent the royalty payment
     * @return royaltyAmount_ the royalty payment amount for price_
     */
    function royaltyInfo(uint256 id_, uint256 price_)
        external
        view
        returns (address receiver_, uint256 royaltyAmount_)
    {
    
        receiver_ = creator[id_];
        
        royaltyAmount_ = (price_ * royalty[id_]) / 100;

    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner_`).
     *      Can only be called by the current owner.
     * 
     * @param newOwner_ address of new owner
     */
    function transferOwnership(address newOwner_) external onlyOwner {
        
        require(
            newOwner_ != address(0),
            "HomeJab: new owner is the zero address"
        );

        emit OwnershipTransferred(owner, newOwner_);
        
        owner = newOwner_;
        
    }

    /**
     * @dev Sets marketplace fee 
     *
     * @notice Restricted access function, should be called by owner only 
     * @param fee_ defines marketplace fee in terms of percentage
     */
    function setMarketplaceFee(uint8 fee_) 
        external 
        onlyOwner
    {
        
        require(fee_ <= 10, "HomeJab: Invalid input");
        
        marketplaceFee = fee_;

    }

    /**
     * @dev Sets batch size for batch operations 
     *
     * @notice Restricted access function, should be called by owner only 
     * @param batchSize_ defines batch size
     */
    function setBatchSize(uint8 batchSize_) 
        external 
        onlyOwner
    {    
        batchSize = batchSize_;
    }

    /**
     * @dev Sets base URI for token metadata 
     *
     * @notice Restricted access function, should be called by owner only 
     * @param baseURI_ defines base URI
     */
    function setBaseURI(string memory baseURI_) 
        external 
        onlyOwner
    {
        URI = baseURI_;
    }

    /**
     * @dev Sets payment token interface 
     *
     * @notice Restricted access function, should be called by owner only 
     * @param paymentToken_ defines contract address of BEP20 token
     */
    function setPaymentInterface(address paymentToken_) 
        external 
        onlyOwner
    {
        
        require(paymentToken_ != address(0), "HomeJab: Invalid input");

        paymentToken = paymentToken_;
    
    }

    /**
     * @dev Mint new NFT
     *
     * @param royalty_ defines royalty fee in terms of percentage
     * @return id_ defines token id that is minted for creator
     */
    function mint(uint8 royalty_) public returns(uint256 id_) {

        require(royalty_ <= 10, "HomeJab: Invalid royalty fee");

        // Get Id
        uint256 _id = totalSupply() + 1;

        // Record creator address
        creator[_id] = msg.sender;

        // Record royalty fee
        royalty[_id] = royalty_;

        // Mint token with given Id
        _safeMint(msg.sender, _id);

        // Emit an event
        emit Minted(msg.sender, _id, royalty_);

        return _id;

    }

    /**
     * @dev Mints new NFTs in batch
     *
     * @param amount_ defines amount of NFTs to be minted for creator
     * @param royalty_ defines royalty fee per NFT in terms of percentage
     */
    function mintBatch(uint8 amount_, uint8 royalty_)
        external
        batchLimit(amount_)  
    {

        for(uint8 i; i < amount_; i++) {
            
            mint(royalty_);

        }

    }

    /**
     * @dev List NFT for sell at fixed price
     *
     * @param id_ defines token Id to be listed for sell
     * @param price_ defines desired sell price of NFT
     */
    function listForSell(uint256 id_, uint256 price_)
        public
    {

        require(msg.sender == ownerOf(id_), "HomeJab: only NFT owner can list NFT for sell");

        require(!sellData[id_].forSell, "HomeJab: Sell is active");

        // Record sell data
        sellData[id_] = Sell(price_, true, 0, 0);

        // Emit an event
        emit Listed(msg.sender, id_, price_, 0);

    }

    /**
     * @dev List NFTs for sell at fixed price
     *
     * @param id_ defines array of token Ids to be listed for sell
     * @param price_ defines desired sell price per NFT
     */
    function listForSellBatch(uint256[] memory id_, uint256 price_)
        external
        batchLimit(id_.length)
    {
        
        for(uint8 i; i < id_.length; i++) {

            listForSell(id_[i], price_);

        }

    } 
    
    /**
     * @dev Mint a NFT and List it for sell at fixed price/ base price(english auction)
     *
     * @param royalty_ defines royalty fee in terms of percentage
     * @param price_ defines desired sell price/ base price of NFT
     * @param endTime_ defines auction ending time in timestamp(Value must be '0' For fixed price sell)
     */
    function mintAndList(uint8 royalty_, uint256 price_, uint64 endTime_)
        public
    {
        
        // Mint new NFT and record Id
        uint256 _id = mint(royalty_);

        if(endTime_ == 0) {

            // List NFT for fixed price sell
            listForSell(_id, price_);

        } else {
            
            // List NFT for english auction
            listForEnglishAuction(_id, price_, endTime_);

        }

    }

    /**
     * @dev Mint NFTs and List them for sell at fixed price/ base price(english auction)
     *
     * @param amount_ defines amount of NFTs minted and listed
     * @param royalty_ defines royalty fee per NFT in terms of percentage
     * @param price_ defines desired sell price/ base price per NFT
     */
    function mintAndListBatch(uint8 amount_, uint8 royalty_, uint256 price_, uint64 endTime_)
        external
        batchLimit(amount_)
    {
        
        for(uint8 i; i < amount_; i++) {

            mintAndList(royalty_, price_, endTime_);

        }

    }

    /**
     * @dev Ends ongoing sell for given NFT
     *
     * @param id_ defines token Id of NFT
     */
    function revokeSell(uint256 id_) 
        external
    {

        require(msg.sender == ownerOf(id_), "HomeJab: only NFT owner can revoke sell");

        require(sellData[id_].forSell, "HomeJab: Sell is not active");

        // Remove sell data
        sellData[id_] = Sell(0, false, 0, 0);

        // Clear Bidding information in case of English auction
        delete auctionBids[id_];
        
        // Emit an event
        emit Delisted(msg.sender, id_);   

    }

    /**
     * @dev Edit sell price for given NFT
     *
     * @param id_ defines token Id of NFT
     * @param newPrice_ defines new price to be set for sell
     */
    function editPrice(uint256 id_, uint256 newPrice_) 
        external
    {
        require(msg.sender == ownerOf(id_), "HomeJab: only NFT owner can edit price");

        require(
            sellData[id_].forSell && sellData[id_].sellType == 0,
            "HomeJab: Fixed price sell is not active"
        );
        
        // Get old price
        uint256 _oldPrice = sellData[id_].price;
        
        // Record new price
        sellData[id_].price = newPrice_;

        // Emit an event
        emit Relisted(msg.sender, id_, _oldPrice, newPrice_);

    }    

    /**
     * @dev Buy given NFT
     *
     * @param id_ defines token Id of NFT
     */
    function buy(uint256 id_)
        external
    {
        
        require(sellData[id_].forSell, "HomeJab: Sell is not active");

        // Get address of seller
        address _seller = ownerOf(id_);

        // Get sell price of given NFT
        uint256 _price = sellData[id_].price;

        // Calculate marketplace fee
        uint256 _marketplaceFee = (_price * marketplaceFee) / 100;
        
        // Calculate royalty fee
        uint256 _royaltyFee = (_price * royalty[id_]) / 100;

        //------------------ Transfer price and fees ------------------//    
        IBEP20TOKEN(paymentToken).transferFrom(
            msg.sender,
            _seller,
            _price - (_marketplaceFee + _royaltyFee)
        );

        IBEP20TOKEN(paymentToken).transferFrom(msg.sender, owner, _marketplaceFee);
        
        IBEP20TOKEN(paymentToken).transferFrom(msg.sender, creator[id_], _royaltyFee);

        // Remove sell data
        sellData[id_] = Sell(0, false, 0, 0);

        // Transfer NFT to buyer
        _transfer(_seller, msg.sender, id_);

        // Emit an event
        emit Bought(_seller, msg.sender, id_, _price, _marketplaceFee, _royaltyFee);

    }

    //--------------Auction functions-----------start--------from------here---------//

    /**
     * @dev List NFT for sell on english auction
     *
     * @param id_ defines token Id to be listed for sell
     * @param basePrice_ defines desired base price of NFT
     * @param endTime_ defines auction ending time in timestamp
     */
    function listForEnglishAuction(
        uint256 id_,
        uint256 basePrice_,
        uint64 endTime_
    ) public {
        
        require(msg.sender == ownerOf(id_), "HomeJab: only NFT owner can list NFT for sell");

        require(!sellData[id_].forSell, "HomeJab: Sell is active");

        require(endTime_ > block.timestamp, "HomeJab: Past time");

        // Record sell data
        sellData[id_] = Sell(basePrice_, true, 1, endTime_);

        // Emit an event
        emit Listed(msg.sender, id_, basePrice_, 1);

    }
    
    /**
     * @dev List NFTs for sell on english auction
     *
     * @param id_ defines array of token Ids to be listed for sell
     * @param basePrice_ defines desired base price per NFT
     * @param endTime_ defines auction ending time in timestamp
     */
    function listForEnglishAuctionBatch(
        uint256[] memory id_,
        uint256 basePrice_,
        uint64 endTime_
    )
        external
        batchLimit(id_.length)
    {

        for(uint8 i; i < id_.length; i++) {

            listForEnglishAuction(id_[i], basePrice_, endTime_);

        }

    }

    /** 
     * @dev returns bid count of NFT listed in english auction
     * 
     * @param _id unsigned integer defines token Id 
     */
    function getBidCount(uint256 _id) public view returns (uint256) {
      return auctionBids[_id].length;
    }

    /** 
     * @dev Bid for NFT listed in english auction
     *
     * @param id_ defines token Id of auctioned NFT 
     * @param bidPrice_ defines number of payment tokens offered for bid  
     */
    function bidOnAuction(
        uint256 id_,
        uint256 bidPrice_
    ) external {

        require(
            isAuctionActive(id_),
            "HomeJab: Auction is not active"
        );

        // Get last bid amount
        uint256 _lastBid = (getBidCount(id_) == 0) ?
                            sellData[id_].price : auctionBids[id_][getBidCount(id_) - 1].amount;  

        require(
            bidPrice_ > _lastBid &&
            IBEP20TOKEN(paymentToken).allowance(msg.sender, address(this)) > bidPrice_,
            "HomeJab: Bid price is less than last bid price / base price"
        );

        // Wrap bid information
        Bid memory newBid = Bid(msg.sender, bidPrice_);

        // Record bid information
        auctionBids[id_].push(newBid);
        
        // Emit an event
        emit BidSuccess(msg.sender, id_, bidPrice_);

    }

    /**
     * @dev Accept bid for NFT listed in english auction 
     *
     * @notice on success NFT is transfered to bidder and seller gets the amount
     * @notice limited access function that can be called by seller only
     * 
     * @param id_ defines token Id of auctioned NFT
     * @param bidIndex_ defines index of given bid to accept for finalize auction
     */
    function acceptBid(
        uint256 id_,
        uint256 bidIndex_
    ) external {

        require(
            sellData[id_].forSell && sellData[id_].sellType == 1,
            "HomeJab: Not listed for auction"
        );
        
        require(msg.sender == ownerOf(id_), "HomeJab: Not an owner of NFT");

        // Get address of bidder
        address _bidder = auctionBids[id_][bidIndex_].from;

        // Get bid amount of given index
        uint256 _price = auctionBids[id_][bidIndex_].amount;

        // Calculate marketplace fee
        uint256 _marketplaceFee = (_price * marketplaceFee) / 100;
        
        // Calculate royalty fee
        uint256 _royaltyFee = (_price * royalty[id_]) / 100;

        //------------------ Transfer price and fees ------------------//    
        IBEP20TOKEN(paymentToken).transferFrom(
            _bidder,
            msg.sender,
            _price - (_marketplaceFee + _royaltyFee)
        );

        IBEP20TOKEN(paymentToken).transferFrom(_bidder, owner, _marketplaceFee);
        
        IBEP20TOKEN(paymentToken).transferFrom(_bidder, creator[id_], _royaltyFee);

        // Remove sell data
        sellData[id_] = Sell(0, false, 0, 0);

        // Clear Bidding information
        delete auctionBids[id_];

        // Transfer NFT to buyer
        _transfer(msg.sender, _bidder, id_);
        
        // Emit an event
        emit Bought(msg.sender, _bidder, id_, _price, _marketplaceFee, _royaltyFee);
        
    }

    /**
     * @dev Called internally to verify that function is being called by HomeJab owner
     */
    function verifyOwner() internal view {

        require(
            msg.sender == owner,
            "HomeJab: Not an owner"
        );
        
    }
    
    /**
     * @dev Called internally to verify that batch request lies within permissible limit
     */
    function verifyBatchLimit(uint256 length_) internal view {

        require(
            length_ <= batchSize,
            "HomeJab: Invalid batch size"
        );

    }

    /**
     * @dev Called internally to verify that english auction is running and active
     */
    function isAuctionActive(uint256 id_) internal view returns(bool) {
        return sellData[id_].forSell && sellData[id_].sellType == 1 && sellData[id_].endTime > block.timestamp;
    }

}