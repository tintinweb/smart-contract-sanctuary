pragma solidity ^0.4.24;

pragma solidity ^0.4.24;

pragma solidity ^0.4.20;

contract CutieCoreInterface
{
    function isCutieCore() pure public returns (bool);

    function transferFrom(address _from, address _to, uint256 _cutieId) external;
    function transfer(address _to, uint256 _cutieId) external;

    function ownerOf(uint256 _cutieId)
        external
        view
        returns (address owner);

    function getCutie(uint40 _id)
        external
        view
        returns (
        uint256 genes,
        uint40 birthTime,
        uint40 cooldownEndTime,
        uint40 momId,
        uint40 dadId,
        uint16 cooldownIndex,
        uint16 generation
    );

    function getGenes(uint40 _id)
        public
        view
        returns (
        uint256 genes
    );


    function getCooldownEndTime(uint40 _id)
        public
        view
        returns (
        uint40 cooldownEndTime
    );

    function getCooldownIndex(uint40 _id)
        public
        view
        returns (
        uint16 cooldownIndex
    );


    function getGeneration(uint40 _id)
        public
        view
        returns (
        uint16 generation
    );

    function getOptional(uint40 _id)
        public
        view
        returns (
        uint64 optional
    );


    function changeGenes(
        uint40 _cutieId,
        uint256 _genes)
        public;

    function changeCooldownEndTime(
        uint40 _cutieId,
        uint40 _cooldownEndTime)
        public;

    function changeCooldownIndex(
        uint40 _cutieId,
        uint16 _cooldownIndex)
        public;

    function changeOptional(
        uint40 _cutieId,
        uint64 _optional)
        public;

    function changeGeneration(
        uint40 _cutieId,
        uint16 _generation)
        public;
}

pragma solidity ^0.4.20;


pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

pragma solidity ^0.4.24;

/// @title Auction Market for Blockchain Cuties.
/// @author https://BlockChainArchitect.io
contract MarketInterface 
{
    function withdrawEthFromBalance() external;    

    function createAuction(uint40 _cutieId, uint128 _startPrice, uint128 _endPrice, uint40 _duration, address _seller) public payable;

    function bid(uint40 _cutieId) public payable;

    function cancelActiveAuctionWhenPaused(uint40 _cutieId) public;

	function getAuctionInfo(uint40 _cutieId)
        public
        view
        returns
    (
        address seller,
        uint128 startPrice,
        uint128 endPrice,
        uint40 duration,
        uint40 startedAt,
        uint128 featuringFee,
        bool tokensAllowed
    );
}

pragma solidity ^0.4.24;

// https://etherscan.io/address/0x4118d7f757ad5893b8fa2f95e067994e1f531371#code
interface ERC20 {
	
	 /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

	function approveAndCall(address _spender, uint256 _value, bytes _extraData) external
        returns (bool success);

	/**
	 * Transfer tokens
	 *
	 * Send `_value` tokens to `_to` from your account
	 *
	 * @param _to The address of the recipient
	 * @param _value the amount to send
	 */
	function transfer(address _to, uint256 _value) external;

    /// @notice Count all tokens assigned to an owner
    function balanceOf(address _owner) external view returns (uint256);
}

pragma solidity ^0.4.24;

// https://etherscan.io/address/0x3127be52acba38beab6b4b3a406dc04e557c037c#code
contract PriceOracleInterface {

    // How much TOKENs you get for 1 ETH, multiplied by 10^18
    uint256 public ETHPrice;
}

pragma solidity ^0.4.24;

interface TokenRecipientInterface
{
        function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}


/// @title Auction Market for Blockchain Cuties.
/// @author https://BlockChainArchitect.io
contract Market is MarketInterface, Pausable, TokenRecipientInterface
{
    // Shows the auction on an Cutie Token
    struct Auction {
        // Price (in wei or tokens) at the beginning of auction
        uint128 startPrice;
        // Price (in wei or tokens) at the end of auction
        uint128 endPrice;
        // Current owner of Token
        address seller;
        // Auction duration in seconds
        uint40 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint40 startedAt;
        // Featuring fee (in wei, optional)
        uint128 featuringFee;
        // is it allowed to bid with erc20 tokens
        bool tokensAllowed;
    }

    // Reference to contract that tracks ownership
    CutieCoreInterface public coreContract;

    // Cut owner takes on each auction, in basis points - 1/100 of a per cent.
    // Values 0-10,000 map to 0%-100%
    uint16 public ownerFee;

    // Map from token ID to their corresponding auction.
    mapping (uint40 => Auction) public cutieIdToAuction;
    mapping (address => PriceOracleInterface) public priceOracle;


    address operatorAddress;

    event AuctionCreated(uint40 indexed cutieId, uint128 startPrice, uint128 endPrice, uint40 duration, uint128 fee, bool tokensAllowed);
    event AuctionSuccessful(uint40 indexed cutieId, uint128 totalPriceWei, address indexed winner);
    event AuctionSuccessfulForToken(uint40 indexed cutieId, uint128 totalPriceWei, address indexed winner, uint128 priceInTokens, address indexed token);
    event AuctionCancelled(uint40 indexed cutieId);

    modifier onlyOperator() {
        require(msg.sender == operatorAddress || msg.sender == owner);
        _;
    }

    function setOperator(address _newOperator) public onlyOwner {
        require(_newOperator != address(0));

        operatorAddress = _newOperator;
    }

    /// @dev disables sending fund to this contract
    function() external {}

    modifier canBeStoredIn128Bits(uint256 _value) 
    {
        require(_value <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        _;
    }

    // @dev Adds to the list of open auctions and fires the
    //  AuctionCreated event.
    // @param _cutieId The token ID is to be put on auction.
    // @param _auction To add an auction.
    // @param _fee Amount of money to feature auction
    function _addAuction(uint40 _cutieId, Auction _auction) internal
    {
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_auction.duration >= 1 minutes);

        cutieIdToAuction[_cutieId] = _auction;
        
        emit AuctionCreated(
            _cutieId,
            _auction.startPrice,
            _auction.endPrice,
            _auction.duration,
            _auction.featuringFee,
            _auction.tokensAllowed
        );
    }

    // @dev Returns true if the token is claimed by the claimant.
    // @param _claimant - Address claiming to own the token.
    function _isOwner(address _claimant, uint256 _cutieId) internal view returns (bool)
    {
        return (coreContract.ownerOf(_cutieId) == _claimant);
    }

    // @dev Transfers the token owned by this contract to another address.
    // Returns true when the transfer succeeds.
    // @param _receiver - Address to transfer token to.
    // @param _cutieId - Token ID to transfer.
    function _transfer(address _receiver, uint40 _cutieId) internal
    {
        // it will throw if transfer fails
        coreContract.transfer(_receiver, _cutieId);
    }

    // @dev Escrows the token and assigns ownership to this contract.
    // Throws if the escrow fails.
    // @param _owner - Current owner address of token to escrow.
    // @param _cutieId - Token ID the approval of which is to be verified.
    function _escrow(address _owner, uint40 _cutieId) internal
    {
        // it will throw if transfer fails
        coreContract.transferFrom(_owner, this, _cutieId);
    }

    // @dev just cancel auction.
    function _cancelActiveAuction(uint40 _cutieId, address _seller) internal
    {
        _removeAuction(_cutieId);
        _transfer(_seller, _cutieId);
        emit AuctionCancelled(_cutieId);
    }

    // @dev Calculates the price and transfers winnings.
    // Does not transfer token ownership.
    function _bid(uint40 _cutieId, uint128 _bidAmount)
        internal
        returns (uint128)
    {
        // Get a reference to the auction struct
        Auction storage auction = cutieIdToAuction[_cutieId];

        require(_isOnAuction(auction));

        // Check that bid > current price
        uint128 price = _currentPrice(auction);
        require(_bidAmount >= price);

        // Provide a reference to the seller before the auction struct is deleted.
        address seller = auction.seller;

        _removeAuction(_cutieId);

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            uint128 fee = _computeFee(price);
            uint128 sellerValue = price - fee;

            seller.transfer(sellerValue);
        }

        emit AuctionSuccessful(_cutieId, price, msg.sender);

        return price;
    }

    // @dev Removes from the list of open auctions.
    // @param _cutieId - ID of token on auction.
    function _removeAuction(uint40 _cutieId) internal
    {
        delete cutieIdToAuction[_cutieId];
    }

    // @dev Returns true if the token is on auction.
    // @param _auction - Auction to check.
    function _isOnAuction(Auction storage _auction) internal view returns (bool)
    {
        return (_auction.startedAt > 0);
    }

    // @dev calculate current price of auction. 
    //  When testing, make this function public and turn on
    //  `Current price calculation` test suite.
    function _computeCurrentPrice(
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration,
        uint40 _secondsPassed
    )
        internal
        pure
        returns (uint128)
    {
        if (_secondsPassed >= _duration) {
            return _endPrice;
        } else {
            int256 totalPriceChange = int256(_endPrice) - int256(_startPrice);
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);
            uint128 currentPrice = _startPrice + uint128(currentPriceChange);
            
            return currentPrice;
        }
    }
    // @dev return current price of token.
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint128)
    {
        uint40 secondsPassed = 0;

        uint40 timeNow = uint40(now);
        if (timeNow > _auction.startedAt) {
            secondsPassed = timeNow - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startPrice,
            _auction.endPrice,
            _auction.duration,
            secondsPassed
        );
    }

    // @dev Calculates owner&#39;s cut of a sale.
    // @param _price - Sale price of cutie.
    function _computeFee(uint128 _price) internal view returns (uint128)
    {
        return _price * ownerFee / 10000;
    }

    // @dev Remove all Ether from the contract with the owner&#39;s cuts. Also, remove any Ether sent directly to the contract address.
    //  Transfers to the token contract, but can be called by
    //  the owner or the token contract.
    function withdrawEthFromBalance() external
    {
        address coreAddress = address(coreContract);

        require(
            msg.sender == owner ||
            msg.sender == coreAddress
        );
        coreAddress.transfer(address(this).balance);
    }

    // @dev create and begin new auction.
    function createAuction(uint40 _cutieId, uint128 _startPrice, uint128 _endPrice, uint40 _duration, address _seller)
        public whenNotPaused payable
    {
        require(_isOwner(msg.sender, _cutieId));
        _escrow(msg.sender, _cutieId);

        bool allowTokens = _duration < 0x8000000000; // first bit of duration is boolean flag (1 to disable tokens)
        _duration = _duration % 0x8000000000; // clear flag from duration

        Auction memory auction = Auction(
            _startPrice,
            _endPrice,
            _seller,
            _duration,
            uint40(now),
            uint128(msg.value),
            allowTokens
        );
        _addAuction(_cutieId, auction);
    }

    // @dev Set the reference to cutie ownership contract. Verify the owner&#39;s fee.
    //  @param fee should be between 0-10,000.
    function setup(address _coreContractAddress, uint16 _fee) public onlyOwner
    {
        require(_fee <= 10000);

        ownerFee = _fee;
        
        CutieCoreInterface candidateContract = CutieCoreInterface(_coreContractAddress);
        require(candidateContract.isCutieCore());
        coreContract = candidateContract;
    }

    // @dev Set the owner&#39;s fee.
    //  @param fee should be between 0-10,000.
    function setFee(uint16 _fee) public onlyOwner
    {
        require(_fee <= 10000);

        ownerFee = _fee;
    }

    // @dev bid on auction. Complete it and transfer ownership of cutie if enough ether was given.
    function bid(uint40 _cutieId) public payable whenNotPaused canBeStoredIn128Bits(msg.value)
    {
        // _bid throws if something failed.
        _bid(_cutieId, uint128(msg.value));
        _transfer(msg.sender, _cutieId);
    }

    function getPriceInToken(ERC20 _tokenContract, uint128 priceWei)
        public
        view
        returns (uint128)
    {
        PriceOracleInterface oracle = priceOracle[address(_tokenContract)];
        require(address(oracle) != address(0));

        uint256 ethPerToken = oracle.ETHPrice();
        return uint128(uint256(priceWei) * ethPerToken / 1 ether);
    }

    function getCutieId(bytes _extraData) internal returns (uint40)
    {
        return
            uint40(_extraData[0]) +
            uint40(_extraData[1]) * 0x100 +
            uint40(_extraData[2]) * 0x10000 +
            uint40(_extraData[3]) * 0x100000 +
            uint40(_extraData[4]) * 0x10000000;
    }

    // https://github.com/BitGuildPlatform/Documentation/blob/master/README.md#2-required-game-smart-contract-changes
    // Function that is called when trying to use PLAT for payments from approveAndCall
    function receiveApproval(address _sender, uint256 _value, address _tokenContract, bytes _extraData)
        external
        canBeStoredIn128Bits(_value)
        whenNotPaused
    {
        ERC20 tokenContract = ERC20(_tokenContract);

        require(_extraData.length == 5); // 40 bits
        uint40 cutieId = getCutieId(_extraData);

        // Get a reference to the auction struct
        Auction storage auction = cutieIdToAuction[cutieId];
        require(auction.tokensAllowed); // buy for token is allowed

        require(_isOnAuction(auction));

        uint128 priceWei = _currentPrice(auction);

        uint128 priceInTokens = getPriceInToken(tokenContract, priceWei);

        // Check that bid > current price
        //require(_value >= priceInTokens);

        // Provide a reference to the seller before the auction struct is deleted.
        address seller = auction.seller;

        _removeAuction(cutieId);

        // Transfer proceeds to seller (if there are any!)
        if (priceInTokens > 0) {
            uint128 fee = _computeFee(priceInTokens);
            uint128 sellerValue = priceInTokens - fee;

            require(tokenContract.transferFrom(_sender, address(this), priceInTokens));
            tokenContract.transfer(seller, sellerValue);
        }
        emit AuctionSuccessfulForToken(cutieId, priceWei, _sender, priceInTokens, _tokenContract);
        _transfer(_sender, cutieId);
    }

    // @dev Returns auction info for a token on auction.
    // @param _cutieId - ID of token on auction.
    function getAuctionInfo(uint40 _cutieId)
        public
        view
        returns
    (
        address seller,
        uint128 startPrice,
        uint128 endPrice,
        uint40 duration,
        uint40 startedAt,
        uint128 featuringFee,
        bool tokensAllowed
    ) {
        Auction storage auction = cutieIdToAuction[_cutieId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startPrice,
            auction.endPrice,
            auction.duration,
            auction.startedAt,
            auction.featuringFee,
            auction.tokensAllowed
        );
    }

    // @dev Returns auction info for a token on auction.
    // @param _cutieId - ID of token on auction.
    function isOnAuction(uint40 _cutieId)
        public
        view
        returns (bool) 
    {
        return cutieIdToAuction[_cutieId].startedAt > 0;
    }

/*
    /// @dev Import cuties from previous version of Core contract.
    /// @param _oldAddress Old core contract address
    /// @param _fromIndex (inclusive)
    /// @param _toIndex (inclusive)
    function migrate(address _oldAddress, uint40 _fromIndex, uint40 _toIndex) public onlyOwner whenPaused
    {
        Market old = Market(_oldAddress);

        for (uint40 i = _fromIndex; i <= _toIndex; i++)
        {
            if (coreContract.ownerOf(i) == _oldAddress)
            {
                address seller;
                uint128 startPrice;
                uint128 endPrice;
                uint40 duration;
                uint40 startedAt;
                uint128 featuringFee;   
                (seller, startPrice, endPrice, duration, startedAt, featuringFee) = old.getAuctionInfo(i);

                Auction memory auction = Auction({
                    seller: seller, 
                    startPrice: startPrice, 
                    endPrice: endPrice, 
                    duration: duration, 
                    startedAt: startedAt, 
                    featuringFee: featuringFee
                });
                _addAuction(i, auction);
            }
        }
    }*/

    // @dev Returns the current price of an auction.
    function getCurrentPrice(uint40 _cutieId)
        public
        view
        returns (uint128)
    {
        Auction storage auction = cutieIdToAuction[_cutieId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

    // @dev Cancels unfinished auction and returns token to owner. 
    // Can be called when contract is paused.
    function cancelActiveAuction(uint40 _cutieId) public
    {
        Auction storage auction = cutieIdToAuction[_cutieId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelActiveAuction(_cutieId, seller);
    }

    // @dev Cancels auction when contract is on pause. Option is available only to owners in urgent situations. Tokens returned to seller.
    //  Used on Core contract upgrade.
    function cancelActiveAuctionWhenPaused(uint40 _cutieId) whenPaused onlyOwner public
    {
        Auction storage auction = cutieIdToAuction[_cutieId];
        require(_isOnAuction(auction));
        _cancelActiveAuction(_cutieId, auction.seller);
    }

        // @dev Cancels unfinished auction and returns token to owner. 
    // Can be called when contract is paused.
    function cancelCreatorAuction(uint40 _cutieId) public onlyOperator
    {
        Auction storage auction = cutieIdToAuction[_cutieId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(seller == address(coreContract));
        _cancelActiveAuction(_cutieId, msg.sender);
    }

    // @dev Transfers to _withdrawToAddress all tokens controlled by
    // contract _tokenContract.
    function withdrawTokenFromBalance(ERC20 _tokenContract, address _withdrawToAddress) external
    {
        address coreAddress = address(coreContract);

        require(
            msg.sender == owner ||
            msg.sender == operatorAddress ||
            msg.sender == coreAddress
        );
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(_withdrawToAddress, balance);
    }

    /// @dev Allow buy cuties for token
    function addToken(ERC20 _tokenContract, PriceOracleInterface _priceOracle) external onlyOwner
    {
        priceOracle[address(_tokenContract)] = _priceOracle;
    }

    /// @dev Disallow buy cuties for token
    function removeToken(ERC20 _tokenContract) external onlyOwner
    {
        delete priceOracle[address(_tokenContract)];
    }
}


/// @title Auction market for cuties sale 
/// @author https://BlockChainArchitect.io
contract SaleMarket is Market
{
    // @dev Sanity check reveals that the
    //  auction in our setSaleAuctionAddress() call is right.
    bool public isSaleMarket = true;
    

    // @dev create and start a new auction
    // @param _cutieId - ID of cutie to auction, sender must be owner.
    // @param _startPrice - Price of item (in wei) at the beginning of auction.
    // @param _endPrice - Price of item (in wei) at the end of auction.
    // @param _duration - Length of auction (in seconds).
    // @param _seller - Seller
    function createAuction(
        uint40 _cutieId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration,
        address _seller
    )
        public
        payable
    {
        require(msg.sender == address(coreContract));
        _escrow(_seller, _cutieId);

        bool allowTokens = _duration < 0x8000000000; // first bit of duration is boolean flag (1 to disable tokens)
        _duration = _duration % 0x8000000000; // clear flag from duration

        Auction memory auction = Auction(
            _startPrice,
            _endPrice,
            _seller,
            _duration,
            uint40(now),
            uint128(msg.value),
            allowTokens
        );
        _addAuction(_cutieId, auction);
    }

    // @dev LastSalePrice is updated if seller is the token contract.
    // Otherwise, default bid method is used.
    function bid(uint40 _cutieId)
        public
        payable
        canBeStoredIn128Bits(msg.value)
    {
        // _bid verifies token ID size
        _bid(_cutieId, uint128(msg.value));
        _transfer(msg.sender, _cutieId);
    }
}