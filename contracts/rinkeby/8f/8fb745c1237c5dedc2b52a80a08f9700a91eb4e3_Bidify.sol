// SPDX-License-Identifier: MIT

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IDecimals.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

pragma solidity ^0.8.0;

contract Bidify is ReentrancyGuard, Ownable, IERC165 {
  using SafeERC20 for IERC20;

  // All prices will now be 0.0001, 0.0002, 0.0010...
  // For coins with less accuracy, such as USD stablecoins, it'll be 0.01, 0.02...
  uint8 constant DECIMAL_ACCURACY = 4;

  // Time to extend the auction by if a last minute bid appears
  uint256 constant EXTENSION_TIMER = 3 minutes;

  mapping(address => uint256) private _balances;

  // Lack of payable on addresses due to usage of call
  struct Listing {
    address creator;
    address currency;
    IERC721 platform;
    uint256 token;
    uint256 price;
    address referrer;
    bool allowMarketplace;
    address marketplace;
    address highBidder;
    uint256 endTime;
    bool paidOut;
  }

  mapping(uint256 => Listing) private _listings;
  uint64 private _nextListing;
  uint256 _lastReceived;

  event ListingCreated(uint64 indexed id, address indexed creator, address currency,
                         address indexed platform, uint256 token, uint256 price,
                         uint8 timeInDays, address referrer);
  event Bid(uint64 indexed id, address indexed bidder, uint256 price);
  event AuctionExtended(uint64 indexed id, uint256 time);
  event AuctionFinished(uint64 indexed id, address indexed nftRecipient, uint256 price);

  // Fallbacks to return ETH flippantly sent
  receive() payable external {
    require(false);
  }
  fallback() payable external {
    require(false);
  }

  constructor() Ownable() {}

  // Support receiving NFTs
  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == 0x150b7a02;
  }
  function onERC721Received(address operator, address, uint256 tokenId, bytes calldata) external returns (bytes4) {
    require(operator == address(this), "someone else sent us a NFT");
    _lastReceived = tokenId;
    return IERC721Receiver.onERC721Received.selector;
  }

  // Get the minimum accuracy unit for a given accuracy
  function getPriceUnit(address currency) public view returns (uint256) {
    if (currency == address(0)) {
      return 10 ** (18 - DECIMAL_ACCURACY);
    }

    // This technically doesn't work with all ERC20s
    // The decimals method is optional, hence the custom interface
    // That said, it is in almost every ERC20, a requirement for this, and needed for feasible operations with wrapped coins
    uint256 decimals = IDecimals(currency).decimals();

    if (decimals <= DECIMAL_ACCURACY) {
      return 1;
    }
    return 10 ** (decimals - DECIMAL_ACCURACY);
  }

  // Only safe to call once per function due to how ETH is handled
  // transferFrom(5) + transferFrom(5) is just 5 on ETH; not 10
  function universalSingularTransferFrom(address currency, uint256 amount) internal {
    if (currency == address(0)) {
      require(msg.value == amount, "invalid ETH value");
    } else {
      IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);
    }
  }

  function universalTransfer(address currency, address dest, uint256 amount) internal {
    if (currency == address(0)) {
      _balances[dest] = _balances[dest] + amount;
    } else {
      IERC20(currency).safeTransfer(dest, amount);
    }
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  // This guard shouldn't be needed, at all, due to the CEI pattern
  // This function is too critical to not warrant the extra gas though
  function withdraw(address account) external nonReentrant {
    uint256 balance = _balances[account];
    _balances[account] = 0;
    (bool success,) = account.call{value: balance}("");
    require(success);
  }

  function getListing(uint256 id) external view returns (Listing memory) {
    return _listings[id];
  }

  function list(address currency, IERC721 platform, uint256 token, uint256 price,
                  uint8 timeInDays, address referrer, bool allowMarketplace) external nonReentrant returns (uint64) {
    // Make sure platform is a valid ERC721 contract
    // The usage of safeTransferFrom should handle this, but this never hurts
    require(platform.supportsInterface(0x80ac58cd), "platform isn't an ERC721 contract");

    uint256 unit = getPriceUnit(currency);
    // Minimum price check to ensure getNextBid doesn't flatline
    require(price >= (20 * unit), "price is too low");
    // Ensure it's a multiple of the price unit
    require(((price / unit) * unit) == price, "price isn't a valid multiple of this currency's price unit");
    require(timeInDays <= 30, "auction is too long");

    uint64 id = _nextListing;
    _nextListing = _nextListing + 1;

    // Re-entrancy opportunity
    // Given the usage of _lastReceived when we create the listing object, this does need the guard
    platform.safeTransferFrom(msg.sender, address(this), token);

    _listings[id] = Listing(
      msg.sender,
      currency,
      platform,
      _lastReceived,
      price,
      referrer,
      allowMarketplace,
      address(0),
      address(0),
      block.timestamp + (timeInDays * (1 days)),
      false
    );
    emit ListingCreated(id, msg.sender, currency, address(platform), token, price, timeInDays, referrer);

    return id;
  }

  function getNextBid(uint64 id) public view returns (uint256) {
    // Increment by 5% at a time, rounding to the price unit
    // This has two effects; stopping micro-bids, which isn't too relevant due to Eth gas fees
    // It also damages marking up. If a NFT is at 1 ETH, this prevents doing 1.0001 ETH to immediately resell
    // This requires doing at least 1.05 ETH, a much more noticeable amount
    // This would risk flatlining (1 -> 1 -> 1) except there is a minimal list price of 20 units
    Listing memory listing = _listings[id];
    if (listing.highBidder == address(0)) {
      return listing.price;
    }
    uint256 round = getPriceUnit(listing.currency);
    return ((listing.price + (listing.price / 20)) / round) * round;
  }

  function bid(uint64 id, address marketplace) external payable nonReentrant {
    // Make sure the auction exists
    // Only works because list and bid have a shared reentrancy guard
    require(id < _nextListing, "listing doesn't exist");
    Listing storage listing = _listings[id];

    require(listing.highBidder != msg.sender, "already the high bidder");
    require(block.timestamp < listing.endTime, "listing ended");
    if (!listing.allowMarketplace) {
      require(marketplace == address(0), "marketplaces aren't allowed on this auction");
    }

    uint256 nextBid = getNextBid(id);
    // This loses control of execution, yet no variables are set yet
    // This means no interim state will be represented if asked
    // Combined with the re-entrancy guard, this is secure
    universalSingularTransferFrom(listing.currency, nextBid);

    // We could grab price below, and then set, yet the lost contract execution is risky
    // Despite the lack of re-entrancy, the metadata would be wrong, if asked for
    uint256 oldPrice = listing.price;
    address oldBidder = listing.highBidder;

    // Note the new highest bidder
    listing.price = nextBid;
    listing.highBidder = msg.sender;
    listing.marketplace = marketplace;
    emit Bid(id, msg.sender, listing.price);

    // Prevent sniping via extending the bid timer, if this was last-minute
    if ((block.timestamp + EXTENSION_TIMER) > listing.endTime) {
      listing.endTime = block.timestamp + EXTENSION_TIMER;
      emit AuctionExtended(id, listing.endTime);
    }

    // Pay back the old bidder who is now out of the game
    // Okay to lose execution as this is the end of the function
    if (oldBidder != address(0)) {
      universalTransfer(listing.currency, oldBidder, oldPrice);
    }
  }

  function finish(uint64 id) external nonReentrant {
    require(id < _nextListing, "listing doesn't exist");

    Listing storage listing = _listings[id];
    require(listing.endTime <= block.timestamp, "listing has yet to end");

    // These two lines make re-entrancy a non-issue
    // That said, this is critical to no be re-entrant, hence why the guard remains
    // It should only removed to save a microscopic amount of gas
    // Speaking of re-entrancy, any external contract which gains control will mis-interpret the metadata
    // Since we do multiple partial payouts, we can either claim not paid out or paid out and be incorrect either way
    // Or we can add a third state "paying out" for an extremely niche mid-payout re-entrant (on the contract level) case
    // This just claims paid out and moves on
    require(!listing.paidOut, "listing was already paid out");
    listing.paidOut = true;

    // The NFT goes to someone, yet if it's the creator/highBidder is undetermined
    address nftRecipient;
    // Set to 0 if there were no bidders
    uint256 sellPrice = listing.price;
    // If there was a bidder...
    if (listing.highBidder != address(0)) {
      // 4% fee
      uint256 originalFees = listing.price / 25;
      uint256 ownerFees = originalFees;

      // Half goes to the referrer, if one exists
      if (listing.referrer != address(0)) {
        ownerFees /= 2;
        uint256 referrerFees = ownerFees;
        // If a marketplace (the referrer for the bidder, versus the seller) exists
        // They get half the referral fees
        if (listing.marketplace != address(0)) {
          referrerFees /= 2;
          universalTransfer(listing.currency, listing.marketplace, referrerFees);
        }
        universalTransfer(listing.currency, listing.referrer, referrerFees);
      } else {
        // Handle no referrer yet marketplace
        if (listing.marketplace != address(0)) {
          ownerFees /= 2;
          // Misuse of ownerFees variable, yet avoids the referrerFees variable definition
          universalTransfer(listing.currency, listing.marketplace, ownerFees);
        }
      }

      // Rest of the fees goes to the platform's creators
      universalTransfer(listing.currency, owner(), ownerFees);

      // Pay out the listing (post fees)
      universalTransfer(listing.currency, listing.creator, listing.price - originalFees);

      // Note the NFT recipient
      nftRecipient = listing.highBidder;
    // Else, restore ownership to the owner
    } else {
      nftRecipient = listing.creator;
      sellPrice = 0;
    }

    listing.platform.safeTransferFrom(address(this), nftRecipient, listing.token);
    emit AuctionFinished(id, nftRecipient, sellPrice);
  }
}