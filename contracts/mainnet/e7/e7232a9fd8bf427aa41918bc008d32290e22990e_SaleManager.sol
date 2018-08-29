pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }
}

/* Controls game play state and access rights for game functions
 * @title Operational Control
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 * Inspired and adapted from contract created by OpenZeppelin
 * Ref: https://github.com/OpenZeppelin/zeppelin-solidity/
 */
contract OperationalControl {
    // Facilitates access & control for the game.
    // Roles:
    //  -The Game Managers (Primary/Secondary): Has universal control of all game elements (No ability to withdraw)
    //  -The Banker: The Bank can withdraw funds and adjust fees / prices.

    /// @dev Emited when contract is upgraded
    event ContractUpgrade(address newContract);

    mapping (address => bool) allowedAddressList;
    

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public gameManagerPrimary;
    address public gameManagerSecondary;
    address public bankManager;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Operation modifiers for limiting access
    modifier onlyGameManager() {
        require(msg.sender == gameManagerPrimary || msg.sender == gameManagerSecondary);
        _;
    }

    /// @dev Operation modifiers for limiting access to only Banker
    modifier onlyBanker() {
        require(msg.sender == bankManager);
        _;
    }

    /// @dev Operation modifiers for access to any Manager
    modifier anyOperator() {
        require(
            msg.sender == gameManagerPrimary ||
            msg.sender == gameManagerSecondary ||
            msg.sender == bankManager
        );
        _;
    }

    /// @dev Assigns a new address to act as the GM.
    function setPrimaryGameManager(address _newGM) external onlyGameManager {
        require(_newGM != address(0));

        gameManagerPrimary = _newGM;
    }

    /// @dev Assigns a new address to act as the GM.
    function setSecondaryGameManager(address _newGM) external onlyGameManager {
        require(_newGM != address(0));

        gameManagerSecondary = _newGM;
    }

    /// @dev Assigns a new address to act as the Banker.
    function setBanker(address _newBK) external onlyBanker {
        require(_newBK != address(0));

        bankManager = _newBK;
    }

    function updateAllowedAddressesList (address _newAddress, bool _value) external onlyGameManager {

        require (_newAddress != address(0));

        allowedAddressList[_newAddress] = _value;
        
    }

    modifier canTransact() { 
        require (msg.sender == gameManagerPrimary
            || msg.sender == gameManagerSecondary
            || allowedAddressList[msg.sender]); 
        _; 
    }
    

    /*** Pausable functionality adapted from OpenZeppelin ***/

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

    /// @dev Called by any Operator role to pause the contract.
    /// Used only if a bug or exploit is discovered (Here to limit losses / damage)
    function pause() external onlyGameManager whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function unpause() public onlyGameManager whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
}

/* @title Interface for MLBNFT Contract
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 */
contract MLBNFT {
    function exists(uint256 _tokenId) public view returns (bool _exists);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function approve(address _to, uint256 _tokenId) public;
    function setApprovalForAll(address _to, bool _approved) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function createPromoCollectible(uint8 _teamId, uint8 _posId, uint256 _attributes, address _owner, uint256 _gameId, uint256 _playerOverrideId, uint256 _mlbPlayerId) external returns (uint256);
    function createSeedCollectible(uint8 _teamId, uint8 _posId, uint256 _attributes, address _owner, uint256 _gameId, uint256 _playerOverrideId, uint256 _mlbPlayerId) public returns (uint256);
    function checkIsAttached(uint256 _tokenId) public view returns (uint256);
    function getTeamId(uint256 _tokenId) external view returns (uint256);
    function getPlayerId(uint256 _tokenId) external view returns (uint256 playerId);
    function getApproved(uint256 _tokenId) public view returns (address _operator);
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

/* @title Interface for ETH Escrow Contract
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 */
contract LSEscrow {
    function escrowTransfer(address seller, address buyer, uint256 currentPrice, uint256 marketsCut) public returns(bool);
}



/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
contract ERC721Receiver {
    /**
    * @dev Magic value to be returned upon successful reception of an NFT
    *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
    *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    */
    bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

    /**
    * @notice Handle the receipt of an NFT
    * @dev The ERC721 smart contract calls this function on the recipient
    *  after a `safetransfer`. This function MAY throw to revert and reject the
    *  transfer. This function MUST use 50,000 gas or less. Return of other
    *  than the magic value MUST result in the transaction being reverted.
    *  Note: the contract address is always the message sender.
    * @param _from The sending address
    * @param _tokenId The NFT identifier which is being transfered
    * @param _data Additional data with no specified format
    * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _data
    )
        public
        returns(bytes4);
}

contract ERC721Holder is ERC721Receiver {
    function onERC721Received(address,address, uint256, bytes) public returns(bytes4) {
        return ERC721_RECEIVED;
    }
}

/* Contains models, variables, and internal methods for the ERC-721 sales.
 * @title Sale Base
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 */
contract SaleBase is OperationalControl, ERC721Holder {
    using SafeMath for uint256;
    
    /// EVENTS 

    event SaleCreated(uint256 tokenID, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt);
    event TeamSaleCreated(uint256[9] tokenIDs, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt);
    event SaleWinner(uint256 tokenID, uint256 totalPrice, address winner);
    event TeamSaleWinner(uint256[9] tokenIDs, uint256 totalPrice, address winner);
    event SaleCancelled(uint256 tokenID, address sellerAddress);
    event EtherWithdrawed(uint256 value);

    /// STORAGE

    /**
     * @dev        Represents an Sale on MLB CryptoBaseball (ERC721)
     */
    struct Sale {
        // Current owner of NFT (ERC721)
        address seller;
        // Price (in wei) at beginning of sale
        uint256 startingPrice;
        // Price (in wei) at end of sale
        uint256 endingPrice;
        // Duration (in seconds) of sale
        uint256 duration;
        // Time when sale started
        // NOTE: 0 if this sale has been concluded
        uint256 startedAt;
        // ERC721 AssetID
        uint256[9] tokenIds;
    }

    /**
     * @dev        Reference to contract tracking ownership & asset details
     */
    MLBNFT public nonFungibleContract;

    /**
     * @dev        Reference to contract tracking ownership & asset details
     */
    LSEscrow public LSEscrowContract;

    /**
     * @dev   Defining a GLOBAL delay time for the auctions to start accepting bidExcess
     * @notice This variable is made to delay the bid process.
     */
    uint256 public BID_DELAY_TIME = 0;

    // Cut owner takes on each sale, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut = 500; //5%

    // Map from token to their corresponding sale.
    mapping (uint256 => Sale) tokenIdToSale;

    /**
     * @dev        Returns true if the claimant owns the token.
     * @param      _claimant  The claimant
     * @param      _tokenId   The token identifier
     */
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    /**
     * @dev        Internal function to ESCROW
     * @notice     Escrows the ERC721 Token, assigning ownership to this contract. Throws if the escrow fails.
     * @param      _owner    The owner
     * @param      _tokenId  The token identifier
     */
    function _escrow(address _owner, uint256 _tokenId) internal {
        nonFungibleContract.safeTransferFrom(_owner, this, _tokenId);
    }

    /**
     * @dev        Internal Transfer function
     * @notice     Transfers an ERC721 Token owned by this contract to another address. Returns true if the transfer succeeds.
     * @param      _owner     The owner
     * @param      _receiver  The receiver
     * @param      _tokenId   The token identifier
     */
    function _transfer(address _owner, address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.transferFrom(_owner, _receiver, _tokenId);
    }

    /**
     * @dev        Internal Function to add Sale, which duration check (atleast 1 min duration required)
     * @notice     Adds an sale to the list of open sales. Also fires the SaleCreated event.
     * @param      _tokenId  The token identifier
     * @param      _sale     The sale
     */
    function _addSale(uint256 _tokenId, Sale _sale) internal {
        // Require that all sales have a duration of
        // at least one minute.
        require(_sale.duration >= 1 minutes);
        
        tokenIdToSale[_tokenId] = _sale;

        emit SaleCreated(
            uint256(_tokenId),
            uint256(_sale.startingPrice),
            uint256(_sale.endingPrice),
            uint256(_sale.duration),
            uint256(_sale.startedAt)
        );
    }

    /**
     * @dev        Internal Function to add Team Sale, which duration check (atleast 1 min duration required)
     * @notice     Adds an sale to the list of open sales. Also fires the SaleCreated event.
     * @param      _tokenIds  The token identifiers
     * @param      _sale      The sale
     */
    function _addTeamSale(uint256[9] _tokenIds, Sale _sale) internal {
        // Require that all sales have a duration of
        // at least one minute.
        require(_sale.duration >= 1 minutes);
        
        for(uint ii = 0; ii < 9; ii++) {
            require(_tokenIds[ii] != 0);
            require(nonFungibleContract.exists(_tokenIds[ii]));

            tokenIdToSale[_tokenIds[ii]] = _sale;
        }

        emit TeamSaleCreated(
            _tokenIds,
            uint256(_sale.startingPrice),
            uint256(_sale.endingPrice),
            uint256(_sale.duration),
            uint256(_sale.startedAt)
        );
    }

    /**
     * @dev        Facilites Sale cancellation. Also removed the Sale from the array
     * @notice     Cancels an sale (given the collectibleID is not 0). SaleCancelled Event
     * @param      _tokenId  The token identifier
     * @param      _seller   The seller
     */
    function _cancelSale(uint256 _tokenId, address _seller) internal {
        Sale memory saleItem = tokenIdToSale[_tokenId];

        //Check for team sale
        if(saleItem.tokenIds[1] != 0) {
            for(uint ii = 0; ii < 9; ii++) {
                _removeSale(saleItem.tokenIds[ii]);
                _transfer(address(this), _seller, saleItem.tokenIds[ii]);
            }
            emit SaleCancelled(_tokenId, _seller);
        } else {
            _removeSale(_tokenId);
            _transfer(address(this), _seller, _tokenId);
            emit SaleCancelled(_tokenId, _seller);
        }
    }

    /**
     * @dev        Computes the price and transfers winnings. Does NOT transfer ownership of token.
     * @notice     Internal function, helps in making the bid and transferring asset if successful
     * @param      _tokenId    The token identifier
     * @param      _bidAmount  The bid amount
     */
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        // Get a reference to the sale struct
        Sale storage _sale = tokenIdToSale[_tokenId];
        uint256[9] memory tokenIdsStore = tokenIdToSale[_tokenId].tokenIds;
        
        // Explicitly check that this sale is currently live.
        require(_isOnSale(_sale));

        // Check that the bid is greater than or equal to the current price
        uint256 price = _currentPrice(_sale);
        require(_bidAmount >= price);

        // Grab a reference to the seller before the sale struct
        // gets deleted.
        address seller = _sale.seller;

        // The bid is good! Remove the sale before sending the fees
        // to the sender so we can&#39;t have a reentrancy attack.
        if(tokenIdsStore[1] > 0) {
            for(uint ii = 0; ii < 9; ii++) {
                _removeSale(tokenIdsStore[ii]);
            }
        } else {
            _removeSale(_tokenId);
        }

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            // Calculate the marketplace&#39;s cut.
            // (NOTE: _computeCut() is guaranteed to return a
            // value <= price)
            uint256 marketsCut = _computeCut(price);
            uint256 sellerProceeds = price.sub(marketsCut);

            seller.transfer(sellerProceeds);
        }

        // Calculate any excess funds included with the bid. If the excess
        // is anything worth worrying about, transfer it back to bidder.
        uint256 bidExcess = _bidAmount.sub(price);

        // Return the funds. Similar to the previous transfer.
        msg.sender.transfer(bidExcess);

        // Tell the world!
        // uint256 assetID, uint256 totalPrice, address winner, uint16 generation
        if(tokenIdsStore[1] > 0) {
            emit TeamSaleWinner(tokenIdsStore, price, msg.sender);
        } else {
            emit SaleWinner(_tokenId, price, msg.sender);
        }
        
        return price;
    }

    /**
     * @dev        Removes an sale from the list of open sales.
     * @notice     Internal Function to remove sales
     * @param      _tokenId  The token identifier
     */
    function _removeSale(uint256 _tokenId) internal {
        delete tokenIdToSale[_tokenId];
    }

    /**
     * @dev        Returns true if the FT (ERC721) is on sale.
     * @notice     Internal function to check if an
     * @param      _sale  The sale
     */
    function _isOnSale(Sale memory _sale) internal pure returns (bool) {
        return (_sale.startedAt > 0);
    }

    /** @dev Returns current price of an FT (ERC721) on sale. Broken into two
     *  functions (this one, that computes the duration from the sale
     *  structure, and the other that does the price computation) so we
     *  can easily test that the price computation works correctly.
     */
    function _currentPrice(Sale memory _sale)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

        // A bit of insurance against negative values (or wraparound).
        // Probably not necessary (since Ethereum guarnatees that the
        // now variable doesn&#39;t ever go backwards).
        if (now > _sale.startedAt.add(BID_DELAY_TIME)) {
            secondsPassed = now.sub(_sale.startedAt.add(BID_DELAY_TIME));
        }

        return _computeCurrentPrice(
            _sale.startingPrice,
            _sale.endingPrice,
            _sale.duration,
            secondsPassed
        );
    }

    /** @dev Computes the current price of an sale. Factored out
     *  from _currentPrice so we can run extensive unit tests.
     *  When testing, make this function public and turn on
     *  `Current price computation` test suite.
     */
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
        // NOTE: We don&#39;t use SafeMath (or similar) in this function because
        //  all of our public functions carefully cap the maximum values for
        //  time (at 64-bits) and currency (at 128-bits). _duration is
        //  also known to be non-zero (see the require() statement in
        //  _addSale())
        if (_secondsPassed >= _duration) {
            // We&#39;ve reached the end of the dynamic pricing portion
            // of the sale, just return the end price.
            return _endingPrice;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

            // This multiplication can&#39;t overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    /**
     * @dev        Computes owner&#39;s cut of a sale.
     * @param      _price  The price
     */
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price.mul(ownerCut).div(10000);
    }
}

/* Clock sales functions and interfaces
 * @title SaleManager
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 */
contract SaleManager is SaleBase {

    /// @dev MAPINGS
    mapping (uint256 => uint256[3]) public lastTeamSalePrices;
    mapping (uint256 => uint256) public lastSingleSalePrices;
    mapping (uint256 => uint256) public seedTeamSaleCount;
    uint256 public seedSingleSaleCount = 0;

    /// @dev CONSTANTS
    uint256 public constant SINGLE_SALE_MULTIPLIER = 35;
    uint256 public constant TEAM_SALE_MULTIPLIER = 12;
    uint256 public constant STARTING_PRICE = 10 finney;
    uint256 public constant SALES_DURATION = 1 days;

    bool public isBatchSupported = true;

    /**
     * @dev        Constructor creates a reference to the MLB_NFT Sale Manager contract
     */
    constructor() public {
        require(ownerCut <= 10000); // You can&#39;t collect more than 100% silly ;)
        require(msg.sender != address(0));
        paused = true;
        gameManagerPrimary = msg.sender;
        gameManagerSecondary = msg.sender;
        bankManager = msg.sender;
    }

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can&#39;t have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function unpause() public onlyGameManager whenPaused {
        require(nonFungibleContract != address(0));

        // Actually unpause the contract.
        super.unpause();
    }

    /** @dev Remove all Ether from the contract, which is the owner&#39;s cuts
     *  as well as any Ether sent directly to the contract address.
     *  Always transfers to the NFT (ERC721) contract, but can be called either by
     *  the owner or the NFT (ERC721) contract.
     */
    function _withdrawBalance() internal {
        // We are using this boolean method to make sure that even if one fails it will still work
        bankManager.transfer(address(this).balance);
    }


    /** @dev Reject all Ether from being sent here, unless it&#39;s from one of the
     *  contracts. (Hopefully, we can prevent user accidents.)
     *  @notice No tipping!
     */
    function() external payable {
        address nftAddress = address(nonFungibleContract);
        require(
            msg.sender == address(this) || 
            msg.sender == gameManagerPrimary ||
            msg.sender == gameManagerSecondary ||
            msg.sender == bankManager ||
            msg.sender == nftAddress ||
            msg.sender == address(LSEscrowContract)
        );
    }

    /**
     * @dev        Creates and begins a new sale.
     * @param      _tokenId        The token identifier
     * @param      _startingPrice  The starting price
     * @param      _endingPrice    The ending price
     * @param      _duration       The duration
     * @param      _seller         The seller
     */
    function _createSale(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        internal
    {
        Sale memory sale = Sale(
            _seller,
            _startingPrice,
            _endingPrice,
            _duration,
            now,
            [_tokenId,0,0,0,0,0,0,0,0]
        );
        _addSale(_tokenId, sale);
    }

    /**
     * @dev        Internal Function, helps in creating team sale
     * @param      _tokenIds       The token identifiers
     * @param      _startingPrice  The starting price
     * @param      _endingPrice    The ending price
     * @param      _duration       The duration
     * @param      _seller         The seller
     */
    function _createTeamSale(
        uint256[9] _tokenIds,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller)
        internal {

        Sale memory sale = Sale(
            _seller,
            _startingPrice,
            _endingPrice,
            _duration,
            now,
            _tokenIds
        );

        /// Add sale obj to all tokens
        _addTeamSale(_tokenIds, sale);
    }

    /** @dev            Cancels an sale that hasn&#39;t been won yet. Returns the MLBNFT (ERC721) to original owner.
     *  @notice         This is a state-modifying function that can be called while the contract is paused.
     */
    function cancelSale(uint256 _tokenId) external whenNotPaused {
        Sale memory sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        address seller = sale.seller;
        require(msg.sender == seller);
        _cancelSale(_tokenId, seller);
    }

    /** @dev        Cancels an sale that hasn&#39;t been won yet. Returns the MLBNFT (ERC721) to original owner.
     *  @notice     This is a state-modifying function that can be called while the contract is paused. Can be only called by the GameManagers
     */
    function cancelSaleWhenPaused(uint256 _tokenId) external whenPaused onlyGameManager {
        Sale memory sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        address seller = sale.seller;
        _cancelSale(_tokenId, seller);
    }

    /** 
     * @dev    Returns sales info for an CSLCollectibles (ERC721) on sale.
     * @notice Fetches the details related to the Sale
     * @param  _tokenId    ID of the token on sale
     */
    function getSale(uint256 _tokenId) external view returns (address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt, uint256[9] tokenIds) {
        Sale memory sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        return (
            sale.seller,
            sale.startingPrice,
            sale.endingPrice,
            sale.duration,
            sale.startedAt,
            sale.tokenIds
        );
    }

    /**
     * @dev        Returns the current price of an sale.
     * @param      _tokenId  The token identifier
     */
    function getCurrentPrice(uint256 _tokenId) external view returns (uint256) {
        Sale memory sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        return _currentPrice(sale);
    }

    /** @dev Calculates the new price for Sale Item
     * @param   _saleType     Sale Type Identifier (0 - Single Sale, 1 - Team Sale)
     * @param   _teamId       Team Identifier
     */
    function _averageSalePrice(uint256 _saleType, uint256 _teamId) internal view returns (uint256) {
        uint256 _price = 0;
        if(_saleType == 0) {
            for(uint256 ii = 0; ii < 10; ii++) {
                _price = _price.add(lastSingleSalePrices[ii]);
            }
            _price = _price.mul(SINGLE_SALE_MULTIPLIER).div(100);
        } else {
            for (uint256 i = 0; i < 3; i++) {
                _price = _price.add(lastTeamSalePrices[_teamId][i]);
            }
        
            _price = _price.mul(TEAM_SALE_MULTIPLIER).div(30);
            _price = _price.mul(9);
        }

        return _price;
    }
    
    /**
     * @dev        Put a Collectible up for sale. Does some ownership trickery to create sale in one tx.
     * @param      _tokenId        The token identifier
     * @param      _startingPrice  The starting price
     * @param      _endingPrice    The ending price
     * @param      _duration       The duration
     * @param      _owner          Owner of the token
     */
    function createSale(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _owner) external whenNotPaused {
        require(msg.sender == address(nonFungibleContract));

        // Check whether the collectible is inPlay. If inPlay cant put it on Sale
        require(nonFungibleContract.checkIsAttached(_tokenId) == 0);
        
        _escrow(_owner, _tokenId);

        // Sale throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the CSLCollectible.
        _createSale(
            _tokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            _owner
        );
    }

    /**
     * @dev        Put a Collectible up for sale. Only callable, if user approved contract for 1/All Collectibles
     * @param      _tokenId        The token identifier
     * @param      _startingPrice  The starting price
     * @param      _endingPrice    The ending price
     * @param      _duration       The duration
     */
    function userCreateSaleIfApproved (uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external whenNotPaused {
        
        require(nonFungibleContract.getApproved(_tokenId) == address(this) || nonFungibleContract.isApprovedForAll(msg.sender, address(this)));
        
        // Check whether the collectible is inPlay. If inPlay cant put it on Sale
        require(nonFungibleContract.checkIsAttached(_tokenId) == 0);
        
        _escrow(msg.sender, _tokenId);

        // Sale throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the CSLCollectible.
        _createSale(
            _tokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    /** 
     * @dev        Transfers the balance of the sales manager contract to the CSLCollectible contract. We use two-step withdrawal to
     *              prevent two transfer calls in the sale bid function.
     */
    function withdrawSaleManagerBalances() public onlyBanker {
        _withdrawBalance();
    }

    /** 
     *  @dev Function to chnage the OwnerCut only accessible by the Owner of the contract
     *  @param _newCut - Sets the ownerCut to new value
     */
    function setOwnerCut(uint256 _newCut) external onlyBanker {
        require(_newCut <= 10000);
        ownerCut = _newCut;
    }
    
    /**
     * @dev        Facilitates seed collectible auction creation. Enforces strict check on the data being passed
     * @notice     Creates a new Collectible and creates an auction for it.
     * @param      _teamId            The team identifier
     * @param      _posId             The position identifier
     * @param      _attributes        The attributes
     * @param      _playerOverrideId  The player override identifier
     * @param      _mlbPlayerId       The mlb player identifier
     * @param      _startPrice        The start price
     * @param      _endPrice          The end price
     * @param      _saleDuration      The sale duration
     */
    function createSingleSeedAuction(
        uint8 _teamId,
        uint8 _posId,
        uint256 _attributes,
        uint256 _playerOverrideId,
        uint256 _mlbPlayerId,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _saleDuration)
        public
        onlyGameManager
        whenNotPaused {
        // Check to see the NFT address is not 0
        require(nonFungibleContract != address(0));
        require(_teamId != 0);

        uint256 nftId = nonFungibleContract.createSeedCollectible(_teamId,_posId,_attributes,address(this),0, _playerOverrideId, _mlbPlayerId);

        uint256 startPrice = 0;
        uint256 endPrice = 0;
        uint256 duration = 0;
        
        if(_startPrice == 0) {
            startPrice = _computeNextSeedPrice(0, _teamId);
        } else {
            startPrice = _startPrice;
        }

        if(_endPrice != 0) {
            endPrice = _endPrice;
        } else {
            endPrice = 0;
        }

        if(_saleDuration == 0) {
            duration = SALES_DURATION;
        } else {
            duration = _saleDuration;
        }

        _createSale(
            nftId,
            startPrice,
            endPrice,
            duration,
            address(this)
        );
    }

    /**
     * @dev        Facilitates promo collectible auction creation. Enforces strict check on the data being passed
     * @notice     Creates a new Collectible and creates an auction for it.
     * @param      _teamId            The team identifier
     * @param      _posId             The position identifier
     * @param      _attributes        The attributes
     * @param      _playerOverrideId  The player override identifier
     * @param      _mlbPlayerId       The mlb player identifier
     * @param      _startPrice        The start price
     * @param      _endPrice          The end price
     * @param      _saleDuration      The sale duration
     */
    function createPromoSeedAuction(
        uint8 _teamId,
        uint8 _posId,
        uint256 _attributes,
        uint256 _playerOverrideId,
        uint256 _mlbPlayerId,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _saleDuration)
        public
        onlyGameManager
        whenNotPaused {
        // Check to see the NFT address is not 0
        require(nonFungibleContract != address(0));
        require(_teamId != 0);

        uint256 nftId = nonFungibleContract.createPromoCollectible(_teamId, _posId, _attributes, address(this), 0, _playerOverrideId, _mlbPlayerId);

        uint256 startPrice = 0;
        uint256 endPrice = 0;
        uint256 duration = 0;
        
        if(_startPrice == 0) {
            startPrice = _computeNextSeedPrice(0, _teamId);
        } else {
            startPrice = _startPrice;
        }

        if(_endPrice != 0) {
            endPrice = _endPrice;
        } else {
            endPrice = 0;
        }

        if(_saleDuration == 0) {
            duration = SALES_DURATION;
        } else {
            duration = _saleDuration;
        }

        _createSale(
            nftId,
            startPrice,
            endPrice,
            duration,
            address(this)
        );
    }

    /**
     * @dev        Creates Team Sale Auction
     * @param      _teamId        The team identifier
     * @param      _tokenIds      The token identifiers
     * @param      _startPrice    The start price
     * @param      _endPrice      The end price
     * @param      _saleDuration  The sale duration
     */
    function createTeamSaleAuction(
        uint8 _teamId,
        uint256[9] _tokenIds,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _saleDuration)
        public
        onlyGameManager
        whenNotPaused {

        require(_teamId != 0);

        // Helps in not creating sale with wrong team and player combination
        for(uint ii = 0; ii < _tokenIds.length; ii++){
            require(nonFungibleContract.getTeamId(_tokenIds[ii]) == _teamId);
        }
        
        uint256 startPrice = 0;
        uint256 endPrice = 0;
        uint256 duration = 0;
        
        if(_startPrice == 0) {
            startPrice = _computeNextSeedPrice(1, _teamId).mul(9);
        } else {
            startPrice = _startPrice;
        }

        if(_endPrice != 0) {
            endPrice = _endPrice;
        } else {
            endPrice = 0;
        }

        if(_saleDuration == 0) {
            duration = SALES_DURATION;
        } else {
            duration = _saleDuration;
        }

        _createTeamSale(
            _tokenIds,
            startPrice,
            endPrice,
            duration,
            address(this)
        );
    }

    /**
     * @dev        Computes the next auction starting price
     * @param      _saleType     The sale type
     * @param      _teamId       The team identifier
     */
    function _computeNextSeedPrice(uint256 _saleType, uint256 _teamId) internal view returns (uint256) {
        uint256 nextPrice = _averageSalePrice(_saleType, _teamId);

        // Sanity check to ensure we don&#39;t overflow arithmetic
        require(nextPrice == nextPrice);

        // We never auction for less than starting price
        if (nextPrice < STARTING_PRICE) {
            nextPrice = STARTING_PRICE;
        }

        return nextPrice;
    }

    /**
     * @dev        Sanity check that allows us to ensure that we are pointing to the right sale call.
     */
    bool public isSalesManager = true;

    /**
     * @dev        works the same as default bid method.
     * @param      _tokenId  The token identifier
     */
    function bid(uint256 _tokenId) public whenNotPaused payable {
        
        Sale memory sale = tokenIdToSale[_tokenId];
        address seller = sale.seller;

        // This check is added to give all users a level playing field to think & bid on the player
        require (now > sale.startedAt.add(BID_DELAY_TIME));
        
        uint256 price = _bid(_tokenId, msg.value);

        //If multi token sale
        if(sale.tokenIds[1] > 0) {
            
            for (uint256 i = 0; i < 9; i++) {
                _transfer(address(this), msg.sender, sale.tokenIds[i]);
            }

            // Avg price
            price = price.div(9);
        } else {
            
            _transfer(address(this), msg.sender, _tokenId);
        }
        
        // If not a seed, exit
        if (seller == address(this)) {
            if(sale.tokenIds[1] > 0){
                uint256 _teamId = nonFungibleContract.getTeamId(_tokenId);

                lastTeamSalePrices[_teamId][seedTeamSaleCount[_teamId] % 3] = price;

                seedTeamSaleCount[_teamId]++;
            } else {
                lastSingleSalePrices[seedSingleSaleCount % 10] = price;
                seedSingleSaleCount++;
            }
        }
    }
    
    /**
     * @dev        Sets the address for the NFT Contract
     * @param      _nftAddress  The nft address
     */
    function setNFTContractAddress(address _nftAddress) public onlyGameManager {
        require (_nftAddress != address(0));        
        nonFungibleContract = MLBNFT(_nftAddress);
    }

    /**
     * @dev        Added this module to allow retrieve of accidental asset transfer to contract
     * @param      _to       { parameter_description }
     * @param      _tokenId  The token identifier
     */
    function assetTransfer(address _to, uint256 _tokenId) public onlyGameManager {
        require(_tokenId != 0);
        nonFungibleContract.transferFrom(address(this), _to, _tokenId);
    }

     /**
     * @dev        Added this module to allow retrieve of accidental asset transfer to contract
     * @param      _to       { parameter_description }
     * @param      _tokenIds  The token identifiers
     */
    function batchAssetTransfer(address _to, uint256[] _tokenIds) public onlyGameManager {
        require(isBatchSupported);
        require (_tokenIds.length > 0);
        
        for(uint i = 0; i < _tokenIds.length; i++){
            require(_tokenIds[i] != 0);
            nonFungibleContract.transferFrom(address(this), _to, _tokenIds[i]);
        }
    }

    /**
     * @dev        Creates new Seed Team Collectibles
     * @notice     Creates a team and transfers all minted assets to SaleManager
     * @param      _teamId       The team identifier
     * @param      _attributes   The attributes
     * @param      _mlbPlayerId  The mlb player identifier
     */
    function createSeedTeam(uint8 _teamId, uint256[9] _attributes, uint256[9] _mlbPlayerId) public onlyGameManager whenNotPaused {
        require(_teamId != 0);
        
        for(uint ii = 0; ii < 9; ii++) {
            nonFungibleContract.createSeedCollectible(_teamId, uint8(ii.add(1)), _attributes[ii], address(this), 0, 0, _mlbPlayerId[ii]);
        }
    }

    /**
     * @dev            Cancels an sale that hasn&#39;t been won yet. Returns the MLBNFT (ERC721) to original owner.
     * @notice         This is a state-modifying function that can be called while the contract is paused.
     */
    function batchCancelSale(uint256[] _tokenIds) external whenNotPaused {
        require(isBatchSupported);
        require(_tokenIds.length > 0);

        for(uint ii = 0; ii < _tokenIds.length; ii++){
            Sale memory sale = tokenIdToSale[_tokenIds[ii]];
            require(_isOnSale(sale));
            
            address seller = sale.seller;
            require(msg.sender == seller);

            _cancelSale(_tokenIds[ii], seller);
        }
    }

    /**
     * @dev        Helps to toggle batch supported flag
     * @param      _flag  The flag
     */
    function updateBatchSupport(bool _flag) public onlyGameManager {
        isBatchSupported = _flag;
    }

    /**
     * @dev        Batching Operation: Creates a new Collectible and creates an auction for it.
     * @notice     Helps in creating single seed auctions in batches
     * @param      _teamIds            The team identifier
     * @param      _posIds            The position identifier
     * @param      _attributes        The attributes
     * @param      _playerOverrideIds  The player override identifier
     * @param      _mlbPlayerIds       The mlb player identifier
     * @param      _startPrice         The start price
     */
    function batchCreateSingleSeedAuction(
        uint8[] _teamIds,
        uint8[] _posIds,
        uint256[] _attributes,
        uint256[] _playerOverrideIds,
        uint256[] _mlbPlayerIds,
        uint256 _startPrice)
        public
        onlyGameManager
        whenNotPaused {

        require (isBatchSupported);

        require (_teamIds.length > 0 &&
            _posIds.length > 0 &&
            _attributes.length > 0 &&
            _playerOverrideIds.length > 0 &&
            _mlbPlayerIds.length > 0 );
        
        // Check to see the NFT address is not 0
        require(nonFungibleContract != address(0));
        
        uint256 nftId;

        require (_startPrice != 0);

        for(uint ii = 0; ii < _mlbPlayerIds.length; ii++){
            require(_teamIds[ii] != 0);

            nftId = nonFungibleContract.createSeedCollectible(
                        _teamIds[ii],
                        _posIds[ii],
                        _attributes[ii],
                        address(this),
                        0,
                        _playerOverrideIds[ii],
                        _mlbPlayerIds[ii]);

            _createSale(
                nftId,
                _startPrice,
                0,
                SALES_DURATION,
                address(this)
            );
        }
    }

    /**
     * @dev        Helps in incrementing the delay time to start bidding for any auctions
     * @notice     Function helps to update the delay time for bidding
     * @param      _newDelay       The new Delay time
     */
    function updateDelayTime(uint256 _newDelay) public onlyGameManager whenNotPaused {

        BID_DELAY_TIME = _newDelay;
    }

    function bidTransfer(uint256 _tokenId, address _buyer, uint256 _bidAmount) public canTransact {

        Sale memory sale = tokenIdToSale[_tokenId];
        address seller = sale.seller;

        // This check is added to give all users a level playing field to think & bid on the player
        require (now > sale.startedAt.add(BID_DELAY_TIME));
        
        uint256[9] memory tokenIdsStore = tokenIdToSale[_tokenId].tokenIds;
        
        // Explicitly check that this sale is currently live.
        require(_isOnSale(sale));

        // Check that the bid is greater than or equal to the current price
        uint256 price = _currentPrice(sale);
        require(_bidAmount >= price);

        // The bid is good! Remove the sale before sending the fees
        // to the sender so we can&#39;t have a reentrancy attack.
        if(tokenIdsStore[1] > 0) {
            for(uint ii = 0; ii < 9; ii++) {
                _removeSale(tokenIdsStore[ii]);
            }
        } else {
            _removeSale(_tokenId);
        }

        uint256 marketsCut = 0;
        uint256 sellerProceeds = 0;

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            // Calculate the marketplace&#39;s cut.
            // (NOTE: _computeCut() is guaranteed to return a
            // value <= price)
            marketsCut = _computeCut(price);
            sellerProceeds = price.sub(marketsCut);
        }

        //escrowTransfer(address seller, address buyer, uint256 currentPrice) public returns(bool);
        require (LSEscrowContract.escrowTransfer(seller, _buyer, sellerProceeds, marketsCut));
        
        // Tell the world!
        // uint256 assetID, uint256 totalPrice, address winner, uint16 generation
        if(tokenIdsStore[1] > 0) {
            emit TeamSaleWinner(tokenIdsStore, price, _buyer);
        } else {
            emit SaleWinner(_tokenId, price, _buyer);
        }

        //If multi token sale
        if(sale.tokenIds[1] > 0) {
            
            for (uint256 i = 0; i < 9; i++) {
                _transfer(address(this), _buyer, sale.tokenIds[i]);
            }

            // Avg price
            price = price.div(9);
        } else {
            
            _transfer(address(this), _buyer, _tokenId);
        }
        
        // If not a seed, exit
        if (seller == address(this)) {
            if(sale.tokenIds[1] > 0) {
                uint256 _teamId = nonFungibleContract.getTeamId(_tokenId);

                lastTeamSalePrices[_teamId][seedTeamSaleCount[_teamId] % 3] = price;

                seedTeamSaleCount[_teamId]++;
            } else {
                lastSingleSalePrices[seedSingleSaleCount % 10] = price;
                seedSingleSaleCount++;
            }
        }
    }

    /**
     * @dev        Sets the address for the LS Escrow Contract
     * @param      _lsEscrowAddress  The nft address
     */
    function setLSEscrowContractAddress(address _lsEscrowAddress) public onlyGameManager {
        require (_lsEscrowAddress != address(0));        
        LSEscrowContract = LSEscrow(_lsEscrowAddress);
    }
}