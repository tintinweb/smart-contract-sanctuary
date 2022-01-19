// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ECDA.sol";

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

    /**
	 * @notice EIP-712 contract's domain typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 *
	 * @dev Note: we do not include version into the domain typehash/separator,
	 *      it is implied version is concatenated to the name field, like "AliERC721v1"
	 */
	// keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)")
	bytes32 public constant DOMAIN_TYPEHASH = 0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866;

	/**
	 * @notice EIP-712 contract's domain separator,
	 *      see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
	 */
	bytes32 public immutable DOMAIN_SEPARATOR;

	/**
	 * @notice EIP-712 permit (EIP-2612) struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("Permit(address owner,address operator,uint256 tokenId,uint256 nonce,uint256 deadline)")
	bytes32 public constant PERMIT_TYPEHASH = 0xee2282d7affd5a432b221a559e429129347b0c19a3f102179a5fb1859eef3d29;
    
    /**
	 * @dev A record of nonces for signing/validating signatures in EIP-712 based
	 *      `permit` and `permitForAll` functions
	 *
	 * @dev Each time the nonce is used, it is increased by one, meaning reordering
	 *      of the EIP-712 transactions is not possible
	 *
	 * @dev Inspired by EIP-2612 extension for ERC20 token standard
	 *
	 * @dev Maps token owner address => token owner nonce
	 */
	mapping(address => uint256) public permitNonces;

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
	 * @dev Fired in bidOnAuction() and revokeBid() when bid is placed/revoked
	 *      for english auction successfully
	 *
	 * @param _from an address of bidder
	 * @param _id token Id of bidded NFT
	 * @param _amount defines bid amount to be paid (zero if bid is revoked)
	 */
    event BidUpdate(
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

        // build the EIP-712 contract domain separator, see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
		// note: we specify contract version in its name
		DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("HomeJab")), block.chainid, address(this)));

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
     * @dev Mints new NFT to creator and transfer it to buyer
     *
     * @param creator_ defines address creator
     * @param royalty_ defines royalty fee per NFT in terms of percentage
     * @param price_ defines price of given NFT 
     */
    function lazyMint(address creator_, uint8 royalty_, uint256 price_) public {
        
        require(royalty_ <= 10, "HomeJab: Invalid royalty fee");

        // Get Id
        uint256 _id = totalSupply() + 1;

        // Record creator address
        creator[_id] = creator_;

        // Record royalty fee
        royalty[_id] = royalty_;

        // Mint token with given Id
        _safeMint(creator_, _id);

        // Emit an event
        emit Minted(creator_, _id, royalty_);
        
        // Calculates marketplace fee
        uint256 _marketplaceFee = (price_ * marketplaceFee) / 100; 
        
        //------------------ Transfer price and fees ------------------//
        IBEP20TOKEN(paymentToken).transferFrom(msg.sender, owner, _marketplaceFee);

        IBEP20TOKEN(paymentToken).transferFrom(msg.sender, creator_, price_ - _marketplaceFee);
        
        // Transfer NFT to buyer
        _transfer(creator_, msg.sender, _id);

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
     * @param id_ unsigned integer defines token Id 
     */
    function getBidCount(uint256 id_) public view returns (uint256) {
      return auctionBids[id_].length;
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
                            sellData[id_].price - 1 : auctionBids[id_][getBidCount(id_) - 1].amount;  

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
        emit BidUpdate(msg.sender, id_, bidPrice_);

    }

    /** 
     * @dev Revoke existing Bid for NFT listed in english auction
     *
     * @param id_ defines token Id of auctioned NFT 
     * @param bidIndex_ defines index of bid to be revoked 
     */
    function revokeBid(
        uint256 id_,
        uint256 bidIndex_
    ) external {

        require(
            isAuctionActive(id_),
            "HomeJab: Auction is not active"
        );

        require(
            msg.sender == auctionBids[id_][bidIndex_].from,
            "HomeJab: Invalid bidder"
        );

        // Get last index
        uint256 _lastIndex = getBidCount(id_) - 1;
        
        // Remove given bid index by shifting elements from right to left
        for(uint i = bidIndex_; i < _lastIndex; i++) {
            auctionBids[id_][i] = auctionBids[id_][i + 1];
        }
        
        // Remove last index
        auctionBids[id_].pop();

        // Emit an event
        emit BidUpdate(msg.sender, id_, 0);

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
     * @param endTime_ defines auction ending time in timestamp(Value must be '0' For fixed price sell)
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
     * @dev Called internally to verify that english auction is running and active
     */
    function isAuctionActive(uint256 id_) internal view returns(bool) {
        return sellData[id_].forSell && sellData[id_].sellType == 1 && sellData[id_].endTime > block.timestamp;
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

    // ===== End: ERC721 mutative functions (transfers, approvals) =====

	// ===== Start: Meta-transactions Support =====

	/**
	 * @notice Change or reaffirm the approved address for an NFT on behalf
	 *
	 * @dev Executes approve(_operator, _tokenId) on behalf of the token owner
	 *      who EIP-712 signed the transaction, i.e. as if transaction sender is the EIP712 signer
	 *
	 * @dev Sets the `_tokenId` as the allowance of `_operator` over `_owner` token,
	 *      given `_owner` EIP-712 signed approval
	 *
	 * @dev Emits `Approval` event in the same way as `approve` does
	 *
	 * @dev Requires:
	 *     - `_operator` to be non-zero address
	 *     - `_exp` to be a timestamp in the future
	 *     - `v`, `r` and `s` to be a valid `secp256k1` signature from `_owner`
	 *        over the EIP712-formatted function arguments.
	 *     - the signature to use `_owner` current nonce (see `permitNonces`).
	 *
	 * @dev For more information on the signature format, see the
	 *      https://eips.ethereum.org/EIPS/eip-2612#specification
	 *
	 * @param _owner owner of the token to set approval on behalf of,
	 *      an address which signed the EIP-712 message
	 * @param _operator new approved NFT controller
	 * @param _tokenId token ID to approve
	 * @param _exp signature expiration time (unix timestamp)
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function permit(address _owner, address _operator, uint256 _tokenId, uint256 _exp, uint8 v, bytes32 r, bytes32 s) public {
		// derive signer of the EIP712 Permit message, and
		// update the nonce for that particular signer to avoid replay attack!!! ----------->>> ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
		address signer = __deriveSigner(abi.encode(PERMIT_TYPEHASH, _owner, _operator, _tokenId, permitNonces[_owner]++, _exp), v, r, s);

		// perform message integrity and security validations
		require(signer == _owner, "invalid signature");
		require(block.timestamp < _exp, "signature expired");

		// delegate call to `__approve` - execute the logic required
		_approve(_operator, _tokenId);
	}

    /**
	 * @dev Auxiliary function to verify structured EIP712 message signature and derive its signer
	 *
	 * @param abiEncodedTypehash abi.encode of the message typehash together with all its parameters
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function __deriveSigner(bytes memory abiEncodedTypehash, uint8 v, bytes32 r, bytes32 s) private view returns(address) {
		// build the EIP-712 hashStruct of the message
		bytes32 hashStruct = keccak256(abiEncodedTypehash);

		// calculate the EIP-712 digest "\x19\x01" ‖ domainSeparator ‖ hashStruct(message)
		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

		// recover the address which signed the message with v, r, s
		address signer = ECDSA.recover(digest, v, r, s);

		// return the signer address derived from the signature
		return signer;
	}

}