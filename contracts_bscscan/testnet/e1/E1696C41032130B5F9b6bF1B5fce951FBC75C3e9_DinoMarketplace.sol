// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
/// @title Clock auction for non-fungible tokens.
import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

interface IDinoLandNFT is IERC721 {
    function createDino(uint256 _dinoGenes, address _ownerAddress) external returns(uint256);
}

contract DinoMarketplace is Pausable, Ownable {
  using SafeMath for uint256;
  
  struct Egg {
      uint256 genes;
      address owner;
      uint256 createdAt;
      uint256 readyHatchAt;
      bool isAvailable;
  }
  
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
    // NOTE: 0 if this auction has been concluded
    uint64 startedAt;
  }

  // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
  // Values 0-10,000 map to 0%-100%
  uint256 public ownerCut;
  address public tokenAddress;
  address public nftAddress;
  address public adminAddress;
  uint256 public defaultEggPrice = 7500 * 1e18;
  uint256 public incubationTime = 6 hours;
  uint256 public skipHatchCooldownPrice = 500 * 1e18;
  mapping(uint256 => uint256) public totalSellingEggByGenes;
  mapping(uint256 => uint256) public eggPriceByGenes;
  mapping(address => uint256[]) public userOwnedEggs;
  
  Egg[] public eggs;

  // Map from token ID to their corresponding auction.
  mapping (address => mapping (uint256 => Auction)) public auctions;
    
  event DinoSpawned(
    uint256 _id,
    uint256 _genes
  );
  
  event AuctionCreated(
    uint256 indexed _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    address _seller
  );

  event AuctionSuccessful(
    uint256 indexed _tokenId,
    uint256 _totalPrice,
    address _winner
  );

  event EggBought(
     uint256 indexed _eggGenes,
     uint256 indexed _eggAmount,
     address indexed _owner
  );
  
  event EggCreated(
    uint256 eggId,
    uint256 genes
  );
      
  event AuctionCancelled(
    uint256 indexed _tokenId
  );

  /// @dev Constructor creates a reference to the NFT ownership contract
  ///  and verifies the owner cut is in the valid range.
  /// @param _ownerCut - percent cut the owner takes on each auction, must be
  ///  between 0-10,000.
  constructor(uint256 _ownerCut, address _tokenAddress, address _nftAddress) {
    require(_ownerCut <= 10000);
    ownerCut = _ownerCut;
    tokenAddress = _tokenAddress;
    nftAddress = _nftAddress;
  }

  /// @dev DON'T give me your money.
  receive () external payable {}

  // Modifiers to check that inputs can be safely stored with a certain
  // number of bits. We use constants and multiple modifiers to save gas.
  modifier canBeStoredWith64Bits(uint256 _value) {
    require(_value <= 18446744073709551615);
    _;
  }

  modifier canBeStoredWith128Bits(uint256 _value) {
    require(_value < 340282366920938463463374607431768211455);
    _;
  }
  
  modifier onlyAdmin {
        require(msg.sender == adminAddress, "need_admin_permission");
        _;
  }
  
  modifier onlyAdminOrOwner {
        require(msg.sender == adminAddress || msg.sender == owner(), "need_admin_or_owner_permission");
        _;
  }
  
  modifier onlyEggOwner(uint256 _eggId) {
      require(eggs[_eggId].owner == msg.sender, "need_egg_owner_permission");
      _;
  }
  /// @dev Set new admin address
  /// @param _newAdminAddress - Address of new admin.
  function setAdminAddress(address _newAdminAddress) external onlyOwner {
      adminAddress = _newAdminAddress;
  }
  
  /// @dev Set new token address
  /// @param _newTokenAddress - Address of new erc20 token.
  function setTokenAddress(address _newTokenAddress) external onlyOwner {
      tokenAddress = _newTokenAddress;
  }
  
  /// @dev Set new nft address
  /// @param _newNftAddress - Address of new erc721 token.
  function setNftAddress(address _newNftAddress) external onlyOwner {
      nftAddress = _newNftAddress;
  }
  
  
  /// @dev Set new egg price 
  /// @param _newEggPrice - Set new value for egg price
  function setDefaultEggPrice(uint256 _newEggPrice) external onlyAdminOrOwner {
      defaultEggPrice = _newEggPrice;
  }
  
  /// @dev Set egg price by genes
  /// @param _eggGenes - Egg genes.
  /// @param _eggPrice - Price of this egg genes.
  function setEggPriceByGenes(uint256 _eggGenes, uint256 _eggPrice) external onlyAdminOrOwner {
      eggPriceByGenes[_eggGenes] = _eggPrice;
  }
  
  function setIncubationTime(uint256 _incubationTime) external onlyAdminOrOwner {
      incubationTime = _incubationTime;
  }
  
  /// @dev Set total egg by genes of market
  /// @param _eggGenes - Dino egg genes
  /// @param _total - Total egg by genes
  function setTotalSellingEggByGenes(uint256 _eggGenes, uint256 _total) external onlyAdminOrOwner {
      totalSellingEggByGenes[_eggGenes] = _total;
  }
  
  function setSkipHatchCooldownPrice(uint256 _newSkipHatchCooldownPrice) external onlyAdminOrOwner {
      skipHatchCooldownPrice = _newSkipHatchCooldownPrice;
  }
  
  function getTotalSellingEggByGenes(uint256 _eggGenes) external view returns(uint256) {
      return totalSellingEggByGenes[_eggGenes];
  }
  
  function getEggPriceByGenes(uint256 _eggGenes) external view returns(uint256) {
      uint256 eggPrice = eggPriceByGenes[_eggGenes] == 0 ? defaultEggPrice : eggPriceByGenes[_eggGenes];
      return eggPrice;
  }
  
  function getTotalEgg() external view returns(uint256) {
      return eggs.length;
  }
  
  function getEggDetail(uint256 _eggId) external view returns(uint256 genes, address owner, uint256 createdAt, uint256 readyHatchAt, bool isAvailable) {
      Egg storage egg = eggs[_eggId];
      return (egg.genes, egg.owner, egg.createdAt, egg.readyHatchAt, egg.isAvailable);
  }
  
  function updateEggStatus(uint256 _eggId, bool _isAvailable) external onlyAdminOrOwner returns(uint256) {
      require(_eggId <= eggs.length -1, "egg_not_exist");
      eggs[_eggId].isAvailable = _isAvailable;
      return _eggId;
  }
  
  function disableEggAndCreateDino(uint256 _eggId, uint256 _dinoGenes, address _ownerAddress) external onlyAdminOrOwner returns(uint256) {
      require(_eggId <= eggs.length -1, "egg_not_exist");
      eggs[_eggId].isAvailable = false;
      uint256 newDinoId = IDinoLandNFT(nftAddress).createDino(_dinoGenes, _ownerAddress);
      emit DinoSpawned(newDinoId, _dinoGenes);
      return newDinoId;
  }
  
  
  /// @dev Get current balance holding in market
  function getMarketManagerBalance() public view returns (uint256) {
      return IERC20(tokenAddress).balanceOf(address(this));
  }

   function skipEggCooldown(uint256 _eggId) external onlyEggOwner(_eggId) {
       Egg storage egg = eggs[_eggId];
       IERC20(tokenAddress).transferFrom(msg.sender, address(this), skipHatchCooldownPrice);
       egg.readyHatchAt = block.timestamp;
   }
   /// @dev Buy egg by genes logic, transfer DNL from buyer address to market
  /// @param _eggGenes - Current buying egg genes
  /// @param _eggAmount - Amount of egg to buy
  function buyEgg(uint256 _eggGenes, uint256 _eggAmount) external {
      require(totalSellingEggByGenes[_eggGenes] >= _eggAmount, "egg_sold_out");
      if(eggPriceByGenes[_eggGenes] > 0) {
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _eggAmount.mul(eggPriceByGenes[_eggGenes]));
      } else {
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _eggAmount.mul(defaultEggPrice));
      }
      
      totalSellingEggByGenes[_eggGenes] = totalSellingEggByGenes[_eggGenes].sub(_eggAmount);
      //Create new egg
      uint256 readyHatchAt = block.timestamp + incubationTime;
      for(uint i=0; i < _eggAmount; i++) {
        uint256 newEggId = _createEgg(_eggGenes, readyHatchAt);
        userOwnedEggs[msg.sender].push(newEggId);
        emit EggCreated(newEggId, _eggGenes);
      }
      
      emit EggBought(_eggGenes, _eggAmount, msg.sender);
  }
  
  /// @dev Create egg
  function _createEgg(uint256 _eggGenes, uint256 _readyHatchAt) private returns(uint256) {
      Egg memory newEgg = Egg(_eggGenes, msg.sender, block.timestamp, _readyHatchAt, true);
      eggs.push(newEgg);
      uint256 _eggId = eggs.length - 1;
      return _eggId;
  }
 
  /// @dev Withdraw balance of market to specific address
  /// @param _to - Receiver address
  /// @param _amount - Token amount
  function withdrawBalance(address _to, uint256 _amount) external onlyAdminOrOwner returns(bool) {
      IERC20(tokenAddress).transfer(_to, _amount);
      return true;
  }
    
  /// @dev Withdraw all balance of market to specific address
  /// @param _to - Receiver address
  function withdrawAllBalance(address _to) external onlyAdminOrOwner returns(bool) {
      uint256 marketManagerBalance = getMarketManagerBalance();
      return IERC20(tokenAddress).transfer(_to, marketManagerBalance);
  }
  
  /// @dev Returns auction info for an NFT on auction.
  /// @param _tokenId - ID of NFT on auction.
  function getAuction(
    uint256 _tokenId
  )
    external
    view
    returns (
      address seller,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 duration,
      uint256 startedAt
    )
  {
    Auction storage _auction = auctions[nftAddress][_tokenId];
    require(_isOnAuction(_auction));
    return (
      _auction.seller,
      _auction.startingPrice,
      _auction.endingPrice,
      _auction.duration,
      _auction.startedAt
    );
  }

  /// @dev Returns the current price of an auction.
  /// @param _tokenId - ID of the token price we are checking.
  function getCurrentPrice(
    uint256 _tokenId
  )
    external
    view
    returns (uint256)
  {
    Auction storage _auction = auctions[nftAddress][_tokenId];
    require(_isOnAuction(_auction));
    return _getCurrentPrice(_auction);
  }

  /// @dev Creates and begins a new auction.
  ///  the Nonfungible Interface.
  /// @param _tokenId - ID of token to auction, sender must be owner.
  /// @param _startingPrice - Price of item (in wei) at beginning of auction.
  /// @param _endingPrice - Price of item (in wei) at end of auction.
  /// @param _duration - Length of time to move between starting
  ///  price and ending price (in seconds).
  function createAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration
  )
    external
    whenNotPaused
    canBeStoredWith128Bits(_startingPrice)
    canBeStoredWith128Bits(_endingPrice)
    canBeStoredWith64Bits(_duration)
  {
    address _seller = msg.sender;
    require(_owns(_seller, _tokenId), "you_dont_have_permission");
    _escrow(nftAddress, _seller, _tokenId);
    Auction memory _auction = Auction(
      _seller,
      uint128(_startingPrice),
      uint128(_endingPrice),
      uint64(_duration),
      uint64(block.timestamp)
    );
    _addAuction(nftAddress, _tokenId, _auction, _seller);
  }

  /// @dev Bids on an open auction, completing the auction and transferring
  ///  ownership of the NFT if enough Ether is supplied.
  ///  the Nonfungible Interface.
  /// @param _tokenId - ID of token to bid on.
  function bid(
    uint256 _tokenId,
    uint256 _amount
  )
    external
    whenNotPaused
  {
    // _bid will throw if the bid or funds transfer fails
    _bid(_tokenId, _amount);
    _transfer(nftAddress, msg.sender, _tokenId);
  }

  /// @dev Cancels an auction that hasn't been won yet.
  ///  Returns the NFT to original owner.
  /// @notice This is a state-modifying function that can
  ///  be called while the contract is paused.
  /// @param _tokenId - ID of token on auction
  function cancelAuction(uint256 _tokenId) external {
    Auction storage _auction = auctions[nftAddress][_tokenId];
    require(_isOnAuction(_auction), "is_not_on_auction");
    require(msg.sender == _auction.seller || msg.sender == adminAddress || msg.sender == owner(), "dont_have_pemission");
    _cancelAuction(_tokenId, _auction.seller);
  }

  /// @dev Cancels an auction when the contract is paused.
  ///  Only the owner may do this, and NFTs are returned to
  ///  the seller. This should only be used in emergencies.
  /// @param _nftAddress - Address of the NFT.
  /// @param _tokenId - ID of the NFT on auction to cancel.
  function cancelAuctionWhenPaused(
    address _nftAddress,
    uint256 _tokenId
  )
    external
    whenPaused
    onlyOwner
  {
    Auction storage _auction = auctions[_nftAddress][_tokenId];
    require(_isOnAuction(_auction));
    _cancelAuction(_tokenId, _auction.seller);
  }

  /// @dev Returns true if the NFT is on auction.
  /// @param _auction - Auction to check.
  function _isOnAuction(Auction storage _auction) internal view returns (bool) {
    return (_auction.startedAt > 0);
  }

  /// @dev Gets the NFT object from an address, validating that implementsERC721 is true.
  /// @param _nftAddress - Address of the NFT.
  function _getNftContract(address _nftAddress) internal pure returns (IERC721) {
    IERC721 candidateContract = IERC721(_nftAddress);
    // require(candidateContract.implementsERC721());
    return candidateContract;
  }

  /// @dev Returns current price of an NFT on auction. Broken into two
  ///  functions (this one, that computes the duration from the auction
  ///  structure, and the other that does the price computation) so we
  ///  can easily test that the price computation works correctly.
  function _getCurrentPrice(
    Auction storage _auction
  )
    internal
    view
    returns (uint256)
  {
    uint256 _secondsPassed = 0;

    // A bit of insurance against negative values (or wraparound).
    // Probably not necessary (since Ethereum guarantees that the
    // now variable doesn't ever go backwards).
    if (block.timestamp > _auction.startedAt) {
      _secondsPassed = block.timestamp - _auction.startedAt;
    }

    return _computeCurrentPrice(
      _auction.startingPrice,
      _auction.endingPrice,
      _auction.duration,
      _secondsPassed
    );
  }

  /// @dev Computes the current price of an auction. Factored out
  ///  from _currentPrice so we can run extensive unit tests.
  ///  When testing, make this function external and turn on
  ///  `Current price computation` test suite.
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
    // NOTE: We don't use SafeMath (or similar) in this function because
    //  all of our external functions carefully cap the maximum values for
    //  time (at 64-bits) and currency (at 128-bits). _duration is
    //  also known to be non-zero (see the require() statement in
    //  _addAuction())
    if (_secondsPassed >= _duration) {
      // We've reached the end of the dynamic pricing portion
      // of the auction, just return the end price.
      return _endingPrice;
    } else {
      // Starting price can be higher than ending price (and often is!), so
      // this delta can be negative.
      int256 _totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

      // This multiplication can't overflow, _secondsPassed will easily fit within
      // 64-bits, and _totalPriceChange will easily fit within 128-bits, their product
      // will always fit within 256-bits.
      int256 _currentPriceChange = _totalPriceChange * int256(_secondsPassed) / int256(_duration);

      // _currentPriceChange can be negative, but if so, will have a magnitude
      // less that _startingPrice. Thus, this result will always end up positive.
      int256 _currentPrice = int256(_startingPrice) + _currentPriceChange;

      return uint256(_currentPrice);
    }
  }

  /// @dev Returns true if the claimant owns the token.
  /// @param _claimant - Address claiming to own the token.
  /// @param _tokenId - ID of token whose ownership to verify.
  function _owns(address _claimant, uint256 _tokenId) private view returns (bool) {
    IERC721 _nftContract = _getNftContract(nftAddress);
    return (_nftContract.ownerOf(_tokenId) == _claimant);
  }

  /// @dev Adds an auction to the list of open auctions. Also fires the
  ///  AuctionCreated event.
  /// @param _tokenId The ID of the token to be put on auction.
  /// @param _auction Auction to add.
  function _addAuction(
    address _nftAddress,
    uint256 _tokenId,
    Auction memory _auction,
    address _seller
  ) internal {
    // Require that all auctions have a duration of
    // at least one minute. (Keeps our math from getting hairy!)
    require(_auction.duration >= 1 minutes, "duration_need_at_least_1min");

    auctions[_nftAddress][_tokenId] = _auction;

    emit AuctionCreated(
      _tokenId,
      uint256(_auction.startingPrice),
      uint256(_auction.endingPrice),
      uint256(_auction.duration),
      _seller
    );
  }

  /// @dev Removes an auction from the list of open auctions.
  /// @param _tokenId - ID of NFT on auction.
  function _removeAuction(uint256 _tokenId) internal {
    delete auctions[nftAddress][_tokenId];
  }

  /// @dev Cancels an auction unconditionally.
  function _cancelAuction(uint256 _tokenId, address _seller) internal {
    _removeAuction(_tokenId);
    _transfer(nftAddress, _seller, _tokenId);
    emit AuctionCancelled(_tokenId);
  }

  /// @dev Escrows the NFT, assigning ownership to this contract.
  /// Throws if the escrow fails.
  /// @param _nftAddress - The address of the NFT.
  /// @param _owner - Current owner address of token to escrow.
  /// @param _tokenId - ID of token whose approval to verify.
  function _escrow(address _nftAddress, address _owner, uint256 _tokenId) internal {
    IERC721 _nftContract = IERC721(_nftAddress);

    // It will throw if transfer fails
    _nftContract.transferFrom(_owner, address(this), _tokenId);
  }

  /// @dev Transfers an NFT owned by this contract to another address.
  /// Returns true if the transfer succeeds.
  /// @param _nftAddress - The address of the NFT.
  /// @param _receiver - Address to transfer NFT to.
  /// @param _tokenId - ID of token to transfer.
  function _transfer(address _nftAddress, address _receiver, uint256 _tokenId) internal {
    IERC721 _nftContract = IERC721(_nftAddress);

    // It will throw if transfer fails
    _nftContract.transferFrom(address(this), _receiver, _tokenId);
  }

  /// @dev Computes owner's cut of a sale.
  /// @param _price - Sale price of NFT.
  function _computeCut(uint256 _price) internal view returns (uint256) {
    // NOTE: We don't use SafeMath (or similar) in this function because
    //  all of our entry functions carefully cap the maximum values for
    //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
    //  statement in the ClockAuction constructor). The result of this
    //  function is always guaranteed to be <= _price.
    return _price * ownerCut / 10000;
  }

  /// @dev Computes the price and transfers winnings.
  /// Does NOT transfer ownership of token.
  function _bid(
    uint256 _tokenId,
    uint256 _bidAmount
  )
    internal
    returns (uint256)
  {
    // Get a reference to the auction struct
    Auction storage _auction = auctions[nftAddress][_tokenId];

    // Explicitly check that this auction is currently live.
    // (Because of how Ethereum mappings work, we can't just count
    // on the lookup above failing. An invalid _tokenId will just
    // return an auction object that is all zeros.)
    // require(_isOnAuction(_auction), "Is not on auction");
    require(_auction.startedAt > 0, "is_not_on_auction");

    // Check that the incoming bid is higher than the current
    // price
    uint256 _price = _getCurrentPrice(_auction);
    require(_bidAmount >= _price, "bid_amount_is_not_enough");

    // Grab a reference to the seller before the auction struct
    // gets deleted.
    address _seller = _auction.seller;

    // The bid is good! Remove the auction before sending the fees
    // to the sender so we can't have a reentrancy attack.
    _removeAuction(_tokenId);

    // Transfer proceeds to seller (if there are any!)
    if (_price > 0) {
      //  Calculate the auctioneer's cut.
      // (NOTE: _computeCut() is guaranteed to return a
      //  value <= price, so this subtraction can't go negative.)
      uint256 _auctioneerCut = _computeCut(_price);
      uint256 _sellerProceeds = _price - _auctioneerCut;

      // NOTE: Doing a transfer() in the middle of a complex
      // method like this is generally discouraged because of
      // reentrancy attacks and DoS attacks if the seller is
      // a contract with an invalid fallback function. We explicitly
      // guard against reentrancy attacks by removing the auction
      // before calling transfer(), and the only thing the seller
      // can DoS is the sale of their own asset! (And if it's an
      // accident, they can call cancelAuction(). )
      IERC20(tokenAddress).transferFrom(msg.sender, address(this), _auctioneerCut);
      
      IERC20(tokenAddress).transferFrom(msg.sender, _seller, _sellerProceeds);
    }

    // if (_bidAmount > _price) {
    //   // Calculate any excess funds included with the bid. If the excess
    //   // is anything worth worrying about, transfer it back to bidder.
    //   // NOTE: We checked above that the bid amount is greater than or
    //   // equal to the price so this cannot underflow.
    //   uint256 _bidExcess = _bidAmount - _price;

    //   // Return the funds. Similar to the previous transfer, this is
    //   // not susceptible to a re-entry attack because the auction is
    //   // removed before any transfers occur.
    //   IERC20(tokenAddress).transfer(msg.sender, _bidExcess);
    // }

    // Tell the world!
    emit AuctionSuccessful(_tokenId, _price, msg.sender);

    return _price;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}