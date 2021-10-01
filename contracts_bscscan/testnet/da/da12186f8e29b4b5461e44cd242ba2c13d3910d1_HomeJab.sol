// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

import "./SafeMath.sol";

// Link to Payment token
interface IBEP20TOKEN {

    // Transfer Payment token
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns(bool);
    
}

/**
 * @title HomeJab Marketplace version 1.0
 *
 * @author HomeJab(Joe Jesuele)
 */
contract HomeJab is ERC721Enumerable {

    using SafeMath for uint256;

    // Address of owner of the contract
    address public owner;

    // Contract address of payment token
    IBEP20TOKEN public PaymentToken;

    // Marketplace fee in terms of percentage
    uint256 public marketplaceFee;

    // Maximum batch size allowed
    uint256 public batchSize;

    // Mapping from token Id to address of creator 
    mapping(uint256 => address) public creator;

    // Mapping from token Id to royalty fee associated with
    mapping(uint256 => uint256) public royalty;

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
        uint256 _royaltyFee
    );

    /**
	 * @dev Fired in listForSell() when NFT listed for sell 
	 *
	 * @param _by an address of NFT owner
	 * @param _id token Id of listed NFT 
     * @param _price sell price for the NFT
	 */
    event Listed(
        address indexed _by,
        uint256 indexed _id,
        uint256 _price
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
	 * @param _by an address of buyer
	 * @param _id token Id of sold NFT 
     * @param _price price paid by buyer 
     * @param _marketplaceFee fees charged by marketplace 
     * @param _royaltyFee fees charged as royalty
	 */
    event Bought(
        address indexed _from,
        address indexed _by,
        uint256 indexed _id,
        uint256 _price,
        uint256 _marketplaceFee,
        uint256 _royaltyFee
    );

    // To check ownership for restricted access functions
    modifier onlyOwner {

        require(
            _msgSender() == owner,
            "HomeJab: Not an owner"
        );
    
        _;

    }

    // To check batch request lies within limits
    modifier batchLimit(uint256 length_) {

        require(
            length_ <= batchSize,
            "HomeJab: Invalid batch size");

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
        uint256 fee_,
        uint256 batchSize_,
        string memory baseURI_,
        address paymentToken_
    ) ERC721("HomeJab Market","REAL") {
        
        require(
            fee_ <= 10 && paymentToken_ != address(0),
            "HomeJab: Invalid input"
        );
        
        //----------Set Internal State----------//
        owner = _msgSender();

        marketplaceFee = fee_;

        batchSize = batchSize_;

        URI = baseURI_;

        PaymentToken = IBEP20TOKEN(paymentToken_);

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
        
        royaltyAmount_ = price_.mul(royalty[id_]).div(100);

    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner_`).
     * Can only be called by the current owner.
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
    function setMarketplaceFee(uint256 fee_) 
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
    function setBatchSize(uint256 batchSize_) 
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

        PaymentToken = IBEP20TOKEN(paymentToken_);
    
    }

    /**
    * @dev Mint new NFT
    *
    * @param royalty_ defines royalty fee in terms of percentage
    * @return id_ defines token id that is minted for creator
    */
    function mint(uint256 royalty_) public returns(uint256 id_) {

        require(royalty_ <= 10, "HomeJab: Invalid royalty fee");

        // Get Id
        uint256 _id = totalSupply().add(1);

        // Record creator address
        creator[_id] = _msgSender();

        // Record royalty fee
        royalty[_id] = royalty_;

        // Mint token with given Id
        _safeMint(_msgSender(), _id);

        // Emit an event
        emit Minted(_msgSender(), _id, royalty_);

        return _id;

    }

    /**
    * @dev Mints new NFTs in batch
    *
    * @param amount_ defines amount of NFTs to be minted for creator
    * @param royalty_ defines royalty fee per NFT in terms of percentage
    */
    function mintBatch(uint8 amount_, uint256 royalty_)
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

        require(_msgSender() == ownerOf(id_), "HomeJab: only NFT owner can list NFT for sell");

        require(!sellData[id_].forSell, "HomeJab: Sell is active");

        // Record sell data
        sellData[id_] = Sell(price_, true);

        // Emit an event
        emit Listed(_msgSender(), id_, price_);

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
    * @dev Mint a NFT and List it for sell at fixed price
    *
    * @param royalty_ defines royalty fee in terms of percentage
    * @param price_ defines desired sell price of NFT
    */
    function mintAndList(uint256 royalty_, uint256 price_)
        public
    {
        
        // Mint new NFT and record Id
        uint256 _id = mint(royalty_);

        // List NFT for sell
        listForSell(_id, price_);
        
    }

    /**
    * @dev Mint NFTs and List them for sell at fixed price
    *
    * @param amount_ defines amount of NFTs minted and listed
    * @param royalty_ defines royalty fee per NFT in terms of percentage
    * @param price_ defines desired sell price per NFT
    */
    function mintAndListBatch(uint8 amount_, uint256 royalty_, uint256 price_)
        external
        batchLimit(amount_)
    {
        
        for(uint8 i; i < amount_; i++) {

            mintAndList(royalty_, price_);

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

        require(_msgSender() == ownerOf(id_), "HomeJab: only NFT owner can revoke sell");

        require(sellData[id_].forSell, "HomeJab: Sell is not active");

        // Record sell data
        sellData[id_] = Sell(0, false);

        // Emit an event
        emit Delisted(_msgSender(), id_);   

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
        require(_msgSender() == ownerOf(id_), "HomeJab: only NFT owner can edit price");

        require(sellData[id_].forSell, "HomeJab: Sell is not active");
        
        // Get old price
        uint256 _oldPrice = sellData[id_].price;
        
        // Record new price
        sellData[id_].price = newPrice_;

        // Emit an event
        emit Relisted(_msgSender(), id_, _oldPrice, newPrice_);

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
        uint256 _marketplaceFee = _price.mul(marketplaceFee).div(100);
        
        // Calculate royalty fee
        uint256 _royaltyFee = _price.mul(royalty[id_]).div(100);

        //------------------ Transfer price and fees ------------------//    
        PaymentToken.transferFrom(
            _msgSender(),
            _seller,
            _price.sub(_marketplaceFee.add(_royaltyFee))
        );

        PaymentToken.transferFrom(_msgSender(), owner, _marketplaceFee);
        
        PaymentToken.transferFrom(_msgSender(), creator[id_], _royaltyFee);

        // Record sell data
        sellData[id_] = Sell(0, false);

        // Transfer NFT to buyer
        _transfer(_seller, _msgSender(), id_);

        // Emit an event
        emit Bought(_seller, _msgSender(), id_, _price, _marketplaceFee, _royaltyFee);

    }

}