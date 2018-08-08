// CryptoRabbit Source code

pragma solidity ^0.4.20;


/**
 * 
 * @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
 * @author cuilichen
 */
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint total);
    function balanceOf(address _owner) public view returns (uint balance);
    function ownerOf(uint _tokenId) external view returns (address owner);
    function approve(address _to, uint _tokenId) external;
    function transfer(address _to, uint _tokenId) external;
    function transferFrom(address _from, address _to, uint _tokenId) external;

    // Events
    event Transfer(address indexed from, address indexed to, uint tokenId);
    event Approval(address indexed owner, address indexed approved, uint tokenId);
    
}



/// @title A base contract to control ownership
/// @author cuilichen
contract OwnerBase {

    // The addresses of the accounts that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;
    
    /// constructor
    function OwnerBase() public {
       ceoAddress = msg.sender;
       cfoAddress = msg.sender;
       cooAddress = msg.sender;
    }

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }


    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCFO The address of the new COO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCOO whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCOO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
	
	
	/// @dev check wether target address is a contract or not
    function isNotContract(address addr) internal view returns (bool) {
        uint size = 0;
        assembly { 
		    size := extcodesize(addr) 
		} 
        return size == 0;
    }
}




/**
 * 
 * @title Interface for contracts conforming to fighters camp
 * @author cuilichen
 */
contract FighterCamp {
    
    //
    function isCamp() public pure returns (bool);
    
    // Required methods
    function getFighter(uint _tokenId) external view returns (uint32);
    
}

/// @title Base contract for CryptoRabbit. Holds all common structs, events and base variables.
/// @author cuilichen
/// @dev See the RabbitCore contract documentation to understand how the various contract facets are arranged.
contract RabbitBase is ERC721, OwnerBase, FighterCamp {

    /*** EVENTS ***/
    /// @dev The Birth event is fired whenever a new rabbit comes into existence. 
    event Birth(address owner, uint rabbitId, uint32 star, uint32 explosive, uint32 endurance, uint32 nimble, uint64 genes, uint8 isBox);

    /*** DATA TYPES ***/
    struct RabbitData {
        //genes for rabbit
        uint64 genes;
        //
        uint32 star;
        //
        uint32 explosive;
        //
        uint32 endurance;
        //
        uint32 nimble;
        //birth time 
        uint64 birthTime;
    }

    /// @dev An array containing the Rabbit struct for all rabbits in existence. The ID
    ///  of each rabbit is actually an index into this array. 
    RabbitData[] rabbits;

    /// @dev A mapping from rabbit IDs to the address that owns them. 
    mapping (uint => address) rabbitToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint) howManyDoYouHave;

    /// @dev A mapping from RabbitIDs to an address that has been approved to call
    ///  transfeFrom(). Each Rabbit can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint => address) public rabbitToApproved;

	
	
    /// @dev Assigns ownership of a specific Rabbit to an address.
    function _transItem(address _from, address _to, uint _tokenId) internal {
        // Since the number of rabbits is capped to 2^32 we can&#39;t overflow this
        howManyDoYouHave[_to]++;
        // transfer ownership
        rabbitToOwner[_tokenId] = _to;
        // When creating new rabbits _from is 0x0, but we can&#39;t account that address.
        if (_from != address(0)) {
            howManyDoYouHave[_from]--;
        }
        // clear any previously approved ownership exchange
        delete rabbitToApproved[_tokenId];
        
        // Emit the transfer event.
		if (_tokenId > 0) {
			emit Transfer(_from, _to, _tokenId);
		}
    }

    /// @dev An internal method that creates a new rabbit and stores it. This
    ///  method doesn&#39;t do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Birth event
    ///  and a Transfer event.
    function _createRabbit(
        uint _star,
        uint _explosive,
        uint _endurance,
        uint _nimble,
        uint _genes,
        address _owner,
		uint8 isBox
    )
        internal
        returns (uint)
    {
        require(_star >= 1 && _star <= 5);
		
		RabbitData memory _tmpRbt = RabbitData({
            genes: uint64(_genes),
            star: uint32(_star),
            explosive: uint32(_explosive),
            endurance: uint32(_endurance),
            nimble: uint32(_nimble),
            birthTime: uint64(now)
        });
        uint newRabbitID = rabbits.push(_tmpRbt) - 1;
        
        
        /* */

        // emit the birth event
        emit Birth(
            _owner,
            newRabbitID,
            _tmpRbt.star,
            _tmpRbt.explosive,
            _tmpRbt.endurance,
            _tmpRbt.nimble,
            _tmpRbt.genes,
			isBox
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        if (_owner != address(0)){
            _transItem(0, _owner, newRabbitID);
        } else {
            _transItem(0, ceoAddress, newRabbitID);
        }
        
        
        return newRabbitID;
    }
    
    /// @notice Returns all the relevant information about a specific rabbit.
    /// @param _tokenId The ID of the rabbit of interest.
    function getRabbit(uint _tokenId) external view returns (
        uint32 outStar,
        uint32 outExplosive,
        uint32 outEndurance,
        uint32 outNimble,
        uint64 outGenes,
        uint64 outBirthTime
    ) {
        RabbitData storage rbt = rabbits[_tokenId];
        outStar = rbt.star;
        outExplosive = rbt.explosive;
        outEndurance = rbt.endurance;
        outNimble = rbt.nimble;
        outGenes = rbt.genes;
        outBirthTime = rbt.birthTime;
    }
	
	
    function isCamp() public pure returns (bool){
        return true;
    }
    
    
    /// @dev An external method that get infomation of the fighter
    /// @param _tokenId The ID of the fighter.
    function getFighter(uint _tokenId) external view returns (uint32) {
        RabbitData storage rbt = rabbits[_tokenId];
        uint32 strength = uint32(rbt.explosive + rbt.endurance + rbt.nimble); 
		return strength;
    }

}



/// @title The facet of the CryptoRabbit core contract that manages ownership, ERC-721 (draft) compliant.
/// @author cuilichen
/// @dev Ref: https://github.com/ethereum/EIPs/issues/721
///  See the RabbitCore contract documentation to understand how the various contract facets are arranged.
contract RabbitOwnership is RabbitBase {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public name;
    string public symbol;
    
    //identify this is ERC721
    function isERC721() public pure returns (bool) {
        return true;
    }

    // Internal utility functions: These functions all assume that their input arguments
    // are valid. We leave it to public methods to sanitize their inputs and follow
    // the required logic.

    /// @dev Checks if a given address is the current owner of a particular Rabbit.
    /// @param _owner the address we are validating against.
    /// @param _tokenId rabbit id, only valid when > 0
    function _owns(address _owner, uint _tokenId) internal view returns (bool) {
        return rabbitToOwner[_tokenId] == _owner;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Rabbit.
    /// @param _claimant the address we are confirming rabbit is approved for.
    /// @param _tokenId rabbit id, only valid when > 0
    function _approvedFor(address _claimant, uint _tokenId) internal view returns (bool) {
        return rabbitToApproved[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transfeFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
    ///  _approve() and transfeFrom() are used together for putting rabbits on auction, and
    ///  there is no value in spamming the log with Approval events in that case.
    function _approve(uint _tokenId, address _to) internal {
        rabbitToApproved[_tokenId] = _to;
    }

    /// @notice Returns the number of rabbits owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint count) {
        return howManyDoYouHave[_owner];
    }

    /// @notice Transfers a Rabbit to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  CryptoRabbit specifically) or your Rabbit may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the Rabbit to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint _tokenId
    )
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
		
		// Disallow transfers to this contract to prevent accidental misuse.
		require(_to != address(this));
        
        // You can only send your own rabbit.
        require(_owns(msg.sender, _tokenId));
        
        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transItem(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific Rabbit via
    ///  transfeFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Rabbit that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint _tokenId
    )
        external
        whenNotPaused
    {   
        require(_owns(msg.sender, _tokenId));    // Only an owner can grant transfer approval.
        require(msg.sender != _to);     // can not approve to itself;

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        emit Approval(msg.sender, _to, _tokenId);
    }

    /// @notice Transfer a Rabbit owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the Rabbit to be transfered.
    /// @param _to The address that should take ownership of the Rabbit. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the Rabbit to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint _tokenId
    )
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        
        //
        require(_owns(_from, _tokenId));
        
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        
        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transItem(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of rabbits currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return rabbits.length - 1;
    }

    /// @notice Returns the address currently assigned ownership of a given Rabbit.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint _tokenId)
        external
        view
        returns (address owner)
    {
        owner = rabbitToOwner[_tokenId];

        require(owner != address(0));
    }

    /// @notice Returns a list of all Rabbit IDs assigned to an address.
    /// @param _owner The owner whose rabbits we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
    ///  expensive (it walks the entire Rabbit array looking for rabbits belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint[] ownerTokens) {
        uint tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint totalCats = totalSupply();
            uint resultIndex = 0;

            // We count on the fact that all rabbits have IDs starting at 1 and increasing
            // sequentially up to the totalCat count.
            uint rabbitId;

            for (rabbitId = 1; rabbitId <= totalCats; rabbitId++) {
                if (rabbitToOwner[rabbitId] == _owner) {
                    result[resultIndex] = rabbitId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

}

/// @title all functions related to creating rabbits and sell rabbits
contract RabbitMinting is RabbitOwnership {
    
    // Price (in wei) for star5 rabbit 
    uint public priceStar5Now = 1 ether;
    
    // Price (in wei) for star4 rabbit 
    uint public priceStar4 = 100 finney;
    
    // Price (in wei) for star3 rabbit 
    uint public priceStar3 = 5 finney;    
    
    
    uint private priceStar5Min = 1 ether;
    uint private priceStar5Add = 2 finney;
    
    //rabbit box1 
    uint public priceBox1 = 10 finney;
    uint public box1Star5 = 50;
    uint public box1Star4 = 500;
	
	//rabbit box2
	uint public priceBox2 = 100 finney;
    uint public box2Star5 = 500;
	
    
    
    // Limits the number of star5 rabbits can ever create.
    uint public constant LIMIT_STAR5 = 2000;
	
	// Limits the number of star4 rabbits can ever create.
    uint public constant LIMIT_STAR4 = 20000;
    
    // Limits the number of rabbits the contract owner can ever create.
    uint public constant LIMIT_PROMO = 5000;
    
    // Counts the number of rabbits of star 5
    uint public CREATED_STAR5;
	
	// Counts the number of rabbits of star 4
    uint public CREATED_STAR4;
    
    // Counts the number of rabbits the contract owner has created.
    uint public CREATED_PROMO;
    
    //an secret key used for random
    uint private secretKey = 392828872;
    
    //box is on sale
    bool private box1OnSale = true;
	
	//box is on sale
    bool private box2OnSale = true;
	
	//record any task id for updating datas;
	mapping(uint => uint8) usedSignId;
   
    
    /// @dev set base infomation by coo
    function setBaseInfo(uint val, bool _onSale1, bool _onSale2) external onlyCOO {
        secretKey = val;
		box1OnSale = _onSale1;
        box2OnSale = _onSale2;
    }
    
    /// @dev we can create promo rabbits, up to a limit. Only callable by COO
    function createPromoRabbit(uint _star, address _owner) whenNotPaused external onlyCOO {
        require (_owner != address(0));
        require(CREATED_PROMO < LIMIT_PROMO);
       
        if (_star == 5){
            require(CREATED_STAR5 < LIMIT_STAR5);
        } else if (_star == 4){
            require(CREATED_STAR4 < LIMIT_STAR4);
        }
        CREATED_PROMO++;
        
        _createRabbitInGrade(_star, _owner, 0);
    }
    
    
    
    /// @dev create a rabbit with grade, and set its owner.
    function _createRabbitInGrade(uint _star, address _owner, uint8 isBox) internal {
        uint _genes = uint(keccak256(uint(_owner) + secretKey + rabbits.length));
        uint _explosive = 50;
        uint _endurance = 50;
        uint _nimble = 50;
        
        if (_star < 5) {
            uint tmp = _genes; 
            tmp = uint(keccak256(tmp));
            _explosive =  1 + 10 * (_star - 1) + tmp % 10;
            tmp = uint(keccak256(tmp));
            _endurance = 1 + 10 * (_star - 1) + tmp % 10;
            tmp = uint(keccak256(tmp));
            _nimble = 1 + 10 * (_star - 1) + tmp % 10;
        } 
		
		uint64 _geneShort = uint64(_genes);
		if (_star == 5){
			CREATED_STAR5++;
			priceStar5Now = priceStar5Min + priceStar5Add * CREATED_STAR5;
			_geneShort = uint64(_geneShort - _geneShort % 2000 + CREATED_STAR5);
		} else if (_star == 4){
			CREATED_STAR4++;
		} 
		
        _createRabbit(
            _star, 
            _explosive, 
            _endurance, 
            _nimble, 
            _geneShort, 
            _owner,
			isBox);
    }
    
    
        
    /// @notice customer buy a rabbit
    /// @param _star the star of the rabbit to buy
    function buyOneRabbit(uint _star) external payable whenNotPaused returns (bool) {
		require(isNotContract(msg.sender));
		
        uint tmpPrice = 0;
        if (_star == 5){
            tmpPrice = priceStar5Now;
			require(CREATED_STAR5 < LIMIT_STAR5);
        } else if (_star == 4){
            tmpPrice = priceStar4;
			require(CREATED_STAR4 < LIMIT_STAR4);
        } else if (_star == 3){
            tmpPrice = priceStar3;
        } else {
			revert();
		}
        
        require(msg.value >= tmpPrice);
        _createRabbitInGrade(_star, msg.sender, 0);
        
        // Return the funds. 
        uint fundsExcess = msg.value - tmpPrice;
        if (fundsExcess > 1 finney) {
            msg.sender.transfer(fundsExcess);
        }
        return true;
    }
    
    
        
    /// @notice customer buy a box
    function buyBox1() external payable whenNotPaused returns (bool) {
		require(isNotContract(msg.sender));
        require(box1OnSale);
        require(msg.value >= priceBox1);
		
        uint tempVal = uint(keccak256(uint(msg.sender) + secretKey + rabbits.length));
        tempVal = tempVal % 10000;
        uint _star = 3; //default
        if (tempVal <= box1Star5){
            _star = 5;
			require(CREATED_STAR5 < LIMIT_STAR5);
        } else if (tempVal <= box1Star5 + box1Star4){
            _star = 4;
			require(CREATED_STAR4 < LIMIT_STAR4);
        } 
        
        _createRabbitInGrade(_star, msg.sender, 2);
        
        // Return the funds. 
        uint fundsExcess = msg.value - priceBox1;
        if (fundsExcess > 1 finney) {
            msg.sender.transfer(fundsExcess);
        }
        return true;
    }
	
	    
    /// @notice customer buy a box
    function buyBox2() external payable whenNotPaused returns (bool) {
		require(isNotContract(msg.sender));
        require(box2OnSale);
        require(msg.value >= priceBox2);
		
        uint tempVal = uint(keccak256(uint(msg.sender) + secretKey + rabbits.length));
        tempVal = tempVal % 10000;
        uint _star = 4; //default
        if (tempVal <= box2Star5){
            _star = 5;
			require(CREATED_STAR5 < LIMIT_STAR5);
        } else {
			require(CREATED_STAR4 < LIMIT_STAR4);
		}
        
        _createRabbitInGrade(_star, msg.sender, 3);
        
        // Return the funds. 
        uint fundsExcess = msg.value - priceBox2;
        if (fundsExcess > 1 finney) {
            msg.sender.transfer(fundsExcess);
        }
        return true;
    }
	
}





/// @title all functions related to creating rabbits and sell rabbits
contract RabbitAuction is RabbitMinting {
    
    //events about auctions
    event AuctionCreated(uint tokenId, uint startingPrice, uint endingPrice, uint duration, uint startTime, uint32 explosive, uint32 endurance, uint32 nimble, uint32 star);
    event AuctionSuccessful(uint tokenId, uint totalPrice, address winner);
    event AuctionCancelled(uint tokenId);
	event UpdateComplete(address account, uint tokenId);
    
    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in wei) at beginning of auction
        uint128 startingPrice;
        // Price (in wei) at end of auction
        uint128 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        uint64 startedAt;
    }

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint public masterCut = 200;

    // Map from token ID to their corresponding auction.
    mapping (uint => Auction) tokenIdToAuction;
    
    
    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    function createAuction(
        uint _tokenId,
        uint _startingPrice,
        uint _endingPrice,
        uint _duration
    )
        external whenNotPaused
    {
		require(isNotContract(msg.sender));
        require(_endingPrice >= 1 finney);
        require(_startingPrice >= _endingPrice);
        require(_duration <= 100 days); 
        require(_owns(msg.sender, _tokenId));
        
		//assigning the ownship to this contract,
        _transItem(msg.sender, this, _tokenId);
        
        Auction memory auction = Auction(
            msg.sender,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }
    
    
    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuctionData(uint _tokenId) external view returns (
        address seller,
        uint startingPrice,
        uint endingPrice,
        uint duration,
        uint startedAt,
        uint currentPrice
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(auction.startedAt > 0);
        seller = auction.seller;
        startingPrice = auction.startingPrice;
        endingPrice = auction.endingPrice;
        duration = auction.duration;
        startedAt = auction.startedAt;
        currentPrice = _calcCurrentPrice(auction);
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint _tokenId) external payable whenNotPaused {
		require(isNotContract(msg.sender));
		
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(auction.startedAt > 0);

        // Check that the bid is greater than or equal to the current price
        uint price = _calcCurrentPrice(auction);
        require(msg.value >= price);

        // Grab a reference to the seller before the auction struct gets deleted.
        address seller = auction.seller;
		
		//
		require(_owns(this, _tokenId));

        // The bid is good! Remove the auction before sending the fees
        // to the sender so we can&#39;t have a reentrancy endurance.
        delete tokenIdToAuction[_tokenId];

        if (price > 0) {
            // Calculate the auctioneer&#39;s cut.
            uint auctioneerCut = price * masterCut / 10000;
            uint sellerProceeds = price - auctioneerCut;
			require(sellerProceeds <= price);

            // Doing a transfer() after removing the auction
            seller.transfer(sellerProceeds);
        }

        // Calculate any excess funds included with the bid. 
        uint bidExcess = msg.value - price;

        // Return the funds. 
		if (bidExcess >= 1 finney) {
			msg.sender.transfer(bidExcess);
		}

        // Tell the world!
        emit AuctionSuccessful(_tokenId, price, msg.sender);
        
        //give goods to bidder.
        _transItem(this, msg.sender, _tokenId);
    }

    /// @dev Cancels an auction that hasn&#39;t been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint _tokenId) external whenNotPaused {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(auction.startedAt > 0);
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionByMaster(uint _tokenId)
        external onlyCOO whenPaused
    {
        _cancelAuction(_tokenId);
    }
	
    
    /// @dev Adds an auction to the list of open auctions. Also fires an event.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(uint _tokenId, Auction _auction) internal {
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;
        
        RabbitData storage rdata = rabbits[_tokenId];

        emit AuctionCreated(
            uint(_tokenId),
            uint(_auction.startingPrice),
            uint(_auction.endingPrice),
            uint(_auction.duration),
            uint(_auction.startedAt),
            uint32(rdata.explosive),
            uint32(rdata.endurance),
            uint32(rdata.nimble),
            uint32(rdata.star)
        );
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint _tokenId) internal {
	    Auction storage auction = tokenIdToAuction[_tokenId];
		_transItem(this, auction.seller, _tokenId);
        delete tokenIdToAuction[_tokenId];
        emit AuctionCancelled(_tokenId);
    }

    /// @dev Returns current price of an NFT on auction. 
    function _calcCurrentPrice(Auction storage _auction)
        internal
        view
        returns (uint outPrice)
    {
        int256 duration = _auction.duration;
        int256 price0 = _auction.startingPrice;
        int256 price2 = _auction.endingPrice;
        require(duration > 0);
        
        int256 secondsPassed = int256(now) - int256(_auction.startedAt);
        require(secondsPassed >= 0);
        if (secondsPassed < _auction.duration) {
            int256 priceChanged = (price2 - price0) * secondsPassed / duration;
            int256 currentPrice = price0 + priceChanged;
            outPrice = uint(currentPrice);
        } else {
            outPrice = _auction.endingPrice;
        }
    }
    
	
	
	
	/// @dev tranfer token to the target, in case of some error occured.
    ///  Only the coo may do this.
	/// @param _to The target address.
	/// @param _to The id of the token.
	function transferOnError(address _to, uint _tokenId) external onlyCOO {
		require(_owns(this, _tokenId));		
		Auction storage auction = tokenIdToAuction[_tokenId];
		require(auction.startedAt == 0);
		
		_transItem(this, _to, _tokenId);
	}
	
	
	/// @dev allow the user to draw a rabbit, with a signed message from coo
	function getFreeRabbit(uint32 _star, uint _taskId, uint8 v, bytes32 r, bytes32 s) external {
		require(usedSignId[_taskId] == 0);
		uint[2] memory arr = [_star, _taskId];
		string memory text = uint2ToStr(arr);
		address signer = verify(text, v, r, s);
		require(signer == cooAddress);
		
		_createRabbitInGrade(_star, msg.sender, 4);
		usedSignId[_taskId] = 1;
	}
	
	
	/// @dev allow any user to set rabbit data, with a signed message from coo
	function setRabbitData(
		uint _tokenId, 
		uint32 _explosive, 
		uint32 _endurance, 
		uint32 _nimble,
		uint _taskId,
		uint8 v, 
		bytes32 r, 
		bytes32 s
	) external {
		require(usedSignId[_taskId] == 0);
		
		Auction storage auction = tokenIdToAuction[_tokenId];
		require (auction.startedAt == 0);
		
		uint[5] memory arr = [_tokenId, _explosive, _endurance, _nimble, _taskId];
		string memory text = uint5ToStr(arr);
		address signer = verify(text, v, r, s);
		require(signer == cooAddress);
		
		RabbitData storage rdata = rabbits[_tokenId];
		rdata.explosive = _explosive;
		rdata.endurance = _endurance;
		rdata.nimble = _nimble;
		rabbits[_tokenId] = rdata;		
		
		usedSignId[_taskId] = 1;
		emit UpdateComplete(msg.sender, _tokenId);
	}
	
	/// @dev werify wether the message is form coo or not.
	function verify(string text, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {		
		bytes32 hash = keccak256(text);
		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
		bytes32 prefixedHash = keccak256(prefix, hash);
		address tmp = ecrecover(prefixedHash, v, r, s);
		return tmp;
	}
    
	/// @dev create an string according to the array
    function uint2ToStr(uint[2] arr) internal pure returns (string){
    	uint length = 0;
    	uint i = 0;
    	uint val = 0;
    	for(; i < arr.length; i++){
    		val = arr[i];
    		while(val >= 10) {
    			length += 1;
    			val = val / 10;
    		}
    		length += 1;//for single 
    		length += 1;//for comma
    	}
    	length -= 1;//remove last comma
    	
    	//copy char to bytes
    	bytes memory bstr = new bytes(length);
        uint k = length - 1;
        int j = int(arr.length - 1);
    	while (j >= 0) {
    		val = arr[uint(j)];
    		if (val == 0) {
    			bstr[k] = byte(48);
    			if (k > 0) {
    			    k--;
    			}
    		} else {
    		    while (val != 0){
    				bstr[k] = byte(48 + val % 10);
    				val /= 10;
    				if (k > 0) {
        			    k--;
        			}
    			}
    		}
    		
    		if (j > 0) { //add comma
				assert(k > 0);
    			bstr[k] = byte(44);
    			k--;
    		}
    		
    		j--;
    	}
    	
        return string(bstr);
    }
	
	/// @dev create an string according to the array
    function uint5ToStr(uint[5] arr) internal pure returns (string){
    	uint length = 0;
    	uint i = 0;
    	uint val = 0;
    	for(; i < arr.length; i++){
    		val = arr[i];
    		while(val >= 10) {
    			length += 1;
    			val = val / 10;
    		}
    		length += 1;//for single 
    		length += 1;//for comma
    	}
    	length -= 1;//remove last comma
    	
    	//copy char to bytes
    	bytes memory bstr = new bytes(length);
        uint k = length - 1;
        int j = int(arr.length - 1);
    	while (j >= 0) {
    		val = arr[uint(j)];
    		if (val == 0) {
    			bstr[k] = byte(48);
    			if (k > 0) {
    			    k--;
    			}
    		} else {
    		    while (val != 0){
    				bstr[k] = byte(48 + val % 10);
    				val /= 10;
    				if (k > 0) {
        			    k--;
        			}
    			}
    		}
    		
    		if (j > 0) { //add comma
				assert(k > 0);
    			bstr[k] = byte(44);
    			k--;
    		}
    		
    		j--;
    	}
    	
        return string(bstr);
    }

}


/// @title CryptoRabbit: Collectible, oh-so-adorable rabbits on the Ethereum blockchain.
/// @author cuilichen
/// @dev The main CryptoRabbit contract, keeps track of rabbits so they don&#39;t wander around and get lost.
/// This is the main CryptoRabbit contract. In order to keep our code seperated into logical sections.
contract RabbitCore is RabbitAuction {
    
    event ContractUpgrade(address newContract);

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    /// @notice Creates the main CryptoRabbit smart contract instance.
    function RabbitCore(string _name, string _symbol) public {
        name = _name;
        symbol = _symbol;
        
        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
        
        //first rabbit in this world
        _createRabbit(5, 50, 50, 50, 1, msg.sender, 0);
    }
    

    /// @dev Used to mark the smart contract as upgraded.
    /// @param _v2Address new address
    function upgradeContract(address _v2Address) external onlyCOO whenPaused {
        // See README.md for updgrade plan
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }


    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can&#39;t have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function unpause() public onlyCOO {
        require(newContractAddress == address(0));
        
        // Actually unpause the contract.
        super.unpause();
    }

    // @dev Allows the CEO to capture the balance available to the contract.
    function withdrawBalance() external onlyCFO {
        address tmp = address(this);
        cfoAddress.transfer(tmp.balance);
    }
}