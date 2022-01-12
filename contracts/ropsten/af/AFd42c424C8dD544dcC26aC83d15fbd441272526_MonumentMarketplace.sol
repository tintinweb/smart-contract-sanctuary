// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PermissionManagement.sol";
import "./MonumentArtifacts.sol";
import "./utils/Payable.sol";
import "./utils/MaxGasPrice.sol";

/// @title Monument Marketplace Contract
/// @author [email protected]
/// @notice In Monument.app context, this contract becomes an Automated Market Maker for the Artifacts minted in the Monument Metaverse
contract MonumentMarketplace is Payable, MaxGasPrice, ReentrancyGuard {
  PermissionManagement private permissionManagement;
  using SafeMath for uint;



  constructor (
    address _permissionManagementContractAddress,
    address payable _allowedNFTContractAddress
  )
  Payable(_permissionManagementContractAddress)
  MaxGasPrice(_permissionManagementContractAddress)
  payable
  {
    permissionManagement = PermissionManagement(_permissionManagementContractAddress);
    
    allowedNFTContractAddress = _allowedNFTContractAddress;
    allowedNFTContract = MonumentArtifacts(_allowedNFTContractAddress);

    // create a genesis fake auction that expires quickly for avoiding out of bounds error
    _enableAuction(10 ** 18, 0, 0);

    // create a genesis $0 fake internal order that expires in 60 seconds for avoiding blank zero mapping conflict
    _placeOrder(0, 60);
    orders[0].tokenId = 10 ** 18;
  }




  // Auction IDs Counter
  using Counters for Counters.Counter;
  Counters.Counter public totalAuctions;




  // Manage what NFTs can be bought and sold in the marketplace
  address public allowedNFTContractAddress;
  MonumentArtifacts allowedNFTContract;
  
  function changeAllowedNFTContract(address payable _nftContractAddress) 
    external
    returns(address)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    allowedNFTContractAddress = _nftContractAddress;
    allowedNFTContract = MonumentArtifacts(_nftContractAddress);
    return _nftContractAddress;
  }




  // Taxes
  uint256 public taxOnEverySaleInPermyriad = 100;

  function changeTaxOnEverySaleInPermyriad(uint256 _taxOnEverySaleInPermyriad) 
    external
    returns(uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    require(_taxOnEverySaleInPermyriad <= 10000, "Permyriad value out of bounds");
    taxOnEverySaleInPermyriad = _taxOnEverySaleInPermyriad;
    return _taxOnEverySaleInPermyriad;
  }




  // Events
  event EnabledAuction(
    uint256 indexed _tokenId,
    uint256 _basePrice,
    uint256 _auctionExpiryTime,
    address indexed _enabledBy
  );
  event EndedAuction(
    uint256 indexed _tokenId,
    address indexed _endedBy
  );
  event EnabledAutoSell(
    uint256 indexed _tokenId,
    uint256 _price,
    address indexed _enabledBy
  );
  event DisabledAutoSell(
    uint256 indexed _tokenId,
    address indexed _disabledBy
  );
  event OrderPlaced(
    uint256 indexed id,
    address indexed buyer,
    uint256 indexed tokenId,
    uint256 price,
    uint256 expiresAt,
    address placedBy
  );
  event OrderExecuted(
    uint256 indexed id
  );
  event OrderCancelled(
    uint256 indexed id
  );




  // Enable/Disable Autosell, and Auction Management

  struct Auction {
    uint256 id;
    uint256 tokenId;
    uint256 basePrice;
    uint256 highestBidOrderId;
    uint256 startTime;
    uint256 expiryTime;
  }
  Auction[] public auctions;

  mapping(uint256 => uint256) public getTokenPrice;
  mapping(uint256 => bool) public isTokenAutoSellEnabled;

  mapping(uint256 => bool) public isTokenAuctionEnabled;
  mapping(uint256 => uint256) public getLatestAuctionIDByTokenID;
  mapping(uint256 => uint256[]) public getAuctionIDsByTokenID;

  /// @notice Allows Token Owner to List the Token on the Marketplace with Auction Enabled
  /// @param _tokenId ID of the Token to List on the Market with Selling Auto-Enabled
  /// @param _basePrice Minimum Price one must put to Bid in the Auction.
  /// @param _auctionExpiresIn Set an End Time for the Auction
  function enableAuction(
    uint256 _tokenId,
    uint256 _basePrice,
    uint256 _auctionExpiresIn
  ) external returns(uint256, uint256) {
    permissionManagement.adhereToBanMethod(msg.sender);

    require(
      allowedNFTContract.ownerOf(_tokenId) == msg.sender ||
      allowedNFTContract.getApproved(_tokenId) == msg.sender ||
      permissionManagement.moderators(msg.sender) == true, 
      "You cant enableAuction for this token"
    );

    // if auction is already on, err
    require(isTokenAuctionEnabled[_tokenId] != true, "Token is already in an auction");

    _enableAuction(
      _tokenId,
      _basePrice,
      _auctionExpiresIn
    );

    return (_tokenId, _basePrice);
  }

  function _enableAuction(
    uint256 _tokenId,
    uint256 _basePrice,
    uint256 _auctionExpiresIn
  ) validGasPrice private returns(uint256, uint256, uint256) {
    getTokenPrice[_tokenId] = _basePrice;
    isTokenAutoSellEnabled[_tokenId] = false;

    uint256 newAuctionId = totalAuctions.current();
    totalAuctions.increment();

    isTokenAuctionEnabled[_tokenId] = true;
    auctions.push(
      Auction(
        newAuctionId,
        _tokenId,
        _basePrice,
        0,
        block.timestamp,
        block.timestamp.add(_auctionExpiresIn)
      )
    );
    getLatestAuctionIDByTokenID[_tokenId] = newAuctionId;
    getAuctionIDsByTokenID[_tokenId].push(newAuctionId);

    emit EnabledAuction(
      _tokenId,
      _basePrice,
      block.timestamp.add(_auctionExpiresIn),
      msg.sender
    );

    return (_tokenId, _basePrice, _auctionExpiresIn);
  }

  /// @notice Allows Token Owner or the Auction Winner to Execute the Auction of their Token
  /// @param _tokenId ID of the Token whose Auction to end
  function executeAuction(
    uint256 _tokenId
  ) validGasPrice nonReentrant external returns(uint256, uint256) {
    permissionManagement.adhereToBanMethod(msg.sender);

    // cant execute an auction that never started
    require(isTokenAuctionEnabled[_tokenId] == true, "Token not auctioned");

    // if auction didn't end by time yet
    if (block.timestamp <= auctions[getLatestAuctionIDByTokenID[_tokenId]].expiryTime) {
      // allow only moderators or owner or approved to execute the auction
      require(
        permissionManagement.moderators(msg.sender) == true || 
        allowedNFTContract.ownerOf(_tokenId) == msg.sender || 
        allowedNFTContract.getApproved(_tokenId) == msg.sender, 
        "You cant execute this auction just yet"
      );

    // if auction expired/ended
    } else {
      // allow only auction winner or moderators or owner or approved to execute the auction
      require(
        permissionManagement.moderators(msg.sender) == true || 
        allowedNFTContract.ownerOf(_tokenId) == msg.sender || 
        allowedNFTContract.getApproved(_tokenId) == msg.sender ||
        orders[auctions[getLatestAuctionIDByTokenID[_tokenId]].highestBidOrderId].buyer == msg.sender,
        "You arent allowed to execute this auction"
      );
    }

    return _executeAuction(_tokenId);
  }

  function _executeAuction(
    uint256 _tokenId
  ) validGasPrice private returns(uint256, uint256) {
    // if there is a valid highest bid
    uint256 _orderId;
    if (auctions[getLatestAuctionIDByTokenID[_tokenId]].highestBidOrderId != 0) {
        // check if auction winner funded more than or equal to the base price
        if (
          orders[
            auctions[getLatestAuctionIDByTokenID[_tokenId]].highestBidOrderId
          ].price
            >=
          auctions[getLatestAuctionIDByTokenID[_tokenId]].basePrice
        ) {
          // give the token to the auction winner and carry the transaction
          _orderId = _executeOrder(auctions[getLatestAuctionIDByTokenID[_tokenId]].highestBidOrderId);
        }
    }

    isTokenAutoSellEnabled[_tokenId] = false;
    isTokenAuctionEnabled[_tokenId] = false;

    emit EndedAuction(
      _tokenId,
      msg.sender
    );
    
    return (_tokenId, _orderId);
  }

  /// @notice Allows Token Owner to List the Token on the Marketplace with Automated Selling
  /// @param _tokenId ID of the Token to List on the Market with Selling Auto-Enabled
  /// @param _pricePerToken At what Price in Wei, if an Order recevied, should be automatically executed?
  function enableAutoSell(
    uint256 _tokenId,
    uint256 _pricePerToken
  ) external returns(uint256, uint256) {
    permissionManagement.adhereToBanMethod(msg.sender);

    require(
      allowedNFTContract.ownerOf(_tokenId) == msg.sender ||
      allowedNFTContract.getApproved(_tokenId) == msg.sender ||
      permissionManagement.moderators(msg.sender) == true, 
      "You cant enableAutoSell for this token"
    );

    // if auction is already on, it must be executed first
    require(isTokenAuctionEnabled[_tokenId] != true, "Token is already in an auction");

    getTokenPrice[_tokenId] = _pricePerToken;
    isTokenAutoSellEnabled[_tokenId] = true;
    isTokenAuctionEnabled[_tokenId] = false;

    emit EnabledAutoSell(
      _tokenId,
      _pricePerToken,
      msg.sender
    );

    return (_tokenId, _pricePerToken);
  }

  /// @notice Allows Token Owner to Disable Auto Selling of their Token
  /// @param _tokenId ID of the Token to List on the Market with Auto-Selling Disabled
  function disableAutoSell(
    uint256 _tokenId
  ) external returns(uint256) {
    permissionManagement.adhereToBanMethod(msg.sender);
    require(
      allowedNFTContract.ownerOf(_tokenId) == msg.sender ||
      allowedNFTContract.getApproved(_tokenId) == msg.sender ||
      permissionManagement.moderators(msg.sender) == true, 
      "You cant disableAutoSell for this token"
    );

    // if auction is already on, it must be executed first
    require(isTokenAuctionEnabled[_tokenId] != true, "Token is in an auction");

    return _disableAutoSell(_tokenId);
  }

  function _disableAutoSell(
    uint256 _tokenId
  ) internal returns(uint256) {
    isTokenAutoSellEnabled[_tokenId] = false;
    isTokenAuctionEnabled[_tokenId] = false;

    emit DisabledAutoSell(
      _tokenId,
      msg.sender
    );

    return _tokenId;
  }




  // Orders Management

  struct Order {
    uint256 id;
    address payable buyer;
    uint256 tokenId;
    uint256 price;
    uint256 expiresAt;
    address payable placedBy;
    bool isDuringAuction;
  }

  enum OrderStatus { PLACED, EXECUTED, CANCELLED }

  Order[] public orders;

  // tokenId to orderId[] mapping
  mapping (uint256 => uint256[]) public getOrderIDsByTokenID;

  // orderId to OrderStatus mapping
  mapping (uint256 => OrderStatus) public getOrderStatus;




  // Internal Functions relating to Order Management

  function _placeOrder(
    uint256 _tokenId,
    uint256 _expireInSeconds
  ) validGasPrice private returns(uint256) {
    require(allowedNFTContract.ownerOf(_tokenId) != msg.sender, "You cant place an order on your own token");

    uint256 _orderId = orders.length;

    Order memory _order = Order({
      id: _orderId,
      buyer: payable(msg.sender),
      tokenId: _tokenId,
      price: msg.value,
      expiresAt: block.timestamp + _expireInSeconds,
      placedBy: payable(msg.sender),
      isDuringAuction: isTokenAuctionEnabled[_tokenId]
    });

    orders.push(_order);
    getOrderIDsByTokenID[_tokenId].push(_order.id);
    getOrderStatus[_orderId] = OrderStatus.PLACED;

    if (msg.value > orders[auctions[getLatestAuctionIDByTokenID[_tokenId]].highestBidOrderId].price) {
      auctions[getLatestAuctionIDByTokenID[_tokenId]].highestBidOrderId = _orderId;
    }

    emit OrderPlaced(
      _order.id,
      _order.buyer,
      _order.tokenId,
      _order.price,
      _order.expiresAt,
      _order.placedBy
    );

    return _orderId;
  }

  function _placeOffer(
    uint256 _tokenId,
    uint256 _expireInSeconds,
    address _buyer,
    uint256 _price
  ) validGasPrice private returns(uint256) {
    require(
      allowedNFTContract.ownerOf(_tokenId) == msg.sender || 
      allowedNFTContract.getApproved(_tokenId) == msg.sender ||
      permissionManagement.moderators(msg.sender) == true, 
      "You do not have rights to offer this token"
    );
    require(_buyer != msg.sender, "You cant make an offer to yourself");

    uint256 _orderId = orders.length;

    Order memory _order = Order({
      id: _orderId,
      buyer: payable(_buyer),
      tokenId: _tokenId,
      price: _price,
      expiresAt: block.timestamp + _expireInSeconds,
      placedBy: payable(msg.sender),
      isDuringAuction: isTokenAuctionEnabled[_tokenId]
    });

    orders.push(_order);
    getOrderIDsByTokenID[_tokenId].push(_order.id);
    getOrderStatus[_orderId] = OrderStatus.PLACED;

    emit OrderPlaced(
      _order.id,
      _order.buyer,
      _order.tokenId,
      _order.price,
      _order.expiresAt,
      _order.placedBy
    );

    return _orderId;
  } 

  function _executeOrder(
    uint256 _orderId
  ) validGasPrice private returns(uint256) {
    require(getOrderStatus[_orderId] != OrderStatus.CANCELLED, "Order already cancelled");
    require(getOrderStatus[_orderId] != OrderStatus.EXECUTED, "Order already executed");

    // order that is the current highest bid made during an auction cannot expire
    require(
      block.timestamp <= orders[_orderId].expiresAt || 
      (
        orders[_orderId].isDuringAuction == true && 
        auctions[getLatestAuctionIDByTokenID[orders[_orderId].tokenId]].highestBidOrderId == _orderId
      ), 
      "Order expired"
    );

    require(orders[_orderId].price <= msg.value || orders[_orderId].price <= getBalance(), "Insufficient Contract Balance");

    if (orders[_orderId].price > 0) {
      // calculate and split royalty
      (
        address royaltyReceiver, 
        uint256 royaltyAmount
      ) = allowedNFTContract.royaltyInfo(
        orders[_orderId].tokenId,
        orders[_orderId].price
      );

      if (royaltyAmount > 0 && royaltyReceiver != address(0)) {
        // pay the Splits contract
        (bool success1, ) = payable(royaltyReceiver).call{value: royaltyAmount}("");
        require(success1, "Transfer to Splits Contract failed.");
      }

      uint256 beneficiaryPay = SafeMath.div(orders[_orderId].price.sub(royaltyAmount).mul(taxOnEverySaleInPermyriad), 10000);

      // pay taxes
      (bool success2, ) = permissionManagement.beneficiary().call{value: beneficiaryPay}("");
      require(success2, "Transfer to Beneficiary failed.");

      // pay the owner
      (bool success3, ) = payable(allowedNFTContract.ownerOf(orders[_orderId].tokenId)).call{value: orders[_orderId].price.sub(beneficiaryPay).sub(royaltyAmount)}("");
      require(success3, "Transfer to Token Owner failed.");
    }

    getOrderStatus[_orderId] = OrderStatus.EXECUTED;

    _disableAutoSell(orders[_orderId].tokenId);

    emit OrderExecuted(_orderId);

    return _orderId;
  }

  function _cancelOrder(
    uint256 _orderId
  ) validGasPrice private returns(uint256) {
    require(getOrderStatus[_orderId] != OrderStatus.CANCELLED, "Order already cancelled");
    require(getOrderStatus[_orderId] != OrderStatus.EXECUTED, "Order was already executed, cant be cancelled now");
    require(getOrderStatus[_orderId] == OrderStatus.PLACED, "Order must be placed to cancel it");

    if (orders[_orderId].price != 0 && orders[_orderId].placedBy == orders[_orderId].buyer) {
      (bool success, ) = orders[_orderId].buyer.call{value: orders[_orderId].price}("");
      require(success, "Transfer to Buyer failed.");
    }

    getOrderStatus[_orderId] = OrderStatus.CANCELLED;

    emit OrderCancelled(_orderId);

    return _orderId;
  }




  // Public Marketplace Functions

  /// @notice Places Order on a Token
  /// @dev Creates an Order
  /// @param _tokenId Token ID to place an Order On.
  /// @param _expireInSeconds Seconds you want the Order to Expire in.
  function placeOrder(
    uint256 _tokenId,
    uint256 _expireInSeconds
  ) validGasPrice nonReentrant external payable returns(uint256) {
    permissionManagement.adhereToBanMethod(msg.sender);
    require(_expireInSeconds >= 60, "Order must not expire within 60 seconds");
    require(msg.value >= 1, "A non-zero value must be paid");

    uint256 _orderId = _placeOrder(_tokenId, _expireInSeconds);

    // check if token is sellable
    address payable tokenOwner = payable(allowedNFTContract.ownerOf(_tokenId));

    // if sellable, buy
    if (isTokenAutoSellEnabled[_tokenId] == true) {
      // if free, complete transaction
      if (getTokenPrice[_tokenId] == 0) {
        _executeOrder(_orderId);
        allowedNFTContract.marketTransfer(tokenOwner, msg.sender, _tokenId);
        return _orderId;
      }

      // check if offerPrice matches getTokenPrice, if yes, complete transaction.
      if (msg.value >= getTokenPrice[_tokenId]) {
        _executeOrder(_orderId);
        allowedNFTContract.marketTransfer(tokenOwner, msg.sender, _tokenId);
        return _orderId;
      }
    }

    return _orderId;
  }

  /// @notice For Token Owner to Offer a Token to someone
  /// @dev Creates an Offer Order
  /// @param _tokenId Token ID to place an Order On.
  /// @param _expireInSeconds Seconds you want the Order to Expire in.
  /// @param _buyer Prospective Buyer Address
  /// @param _price Price at which the Token Owner aims to sell the Token to the Buyer
  function placeOffer(
    uint256 _tokenId,
    uint256 _expireInSeconds,
    address _buyer,
    uint256 _price
  ) validGasPrice external returns(uint256) {
    permissionManagement.adhereToBanMethod(msg.sender);

    require(_expireInSeconds >= 60, "Offer must not expire within 60 seconds");

    // if auction is on, token owner cant place offers
    require(isTokenAuctionEnabled[_tokenId] != true, "Cant offer tokens during auction");

    uint256 _orderId = _placeOffer(_tokenId, _expireInSeconds, _buyer, _price);

    return _orderId;
  }

  /// @notice For Token Owner to Approve an Order, or for Buyer to Accept an Offer
  /// @dev Executes an Order on Valid Acceptance
  /// @param _orderId ID of the Order to Accept
  function acceptOffer(
    uint256 _orderId
  ) validGasPrice nonReentrant external payable returns(uint256) {
    permissionManagement.adhereToBanMethod(msg.sender);

    Order memory _order = orders[_orderId];
    address tokenOwner = allowedNFTContract.ownerOf(_order.tokenId);
    address tokenApprovedAddress = allowedNFTContract.getApproved(_order.tokenId);

    require(_order.placedBy != msg.sender, "You cant accept your own offer");

    // if auction is on, you cant accept random offers
    require(isTokenAuctionEnabled[_order.tokenId] != true, "Cant accept offers on a token during auction");

    // if buyer booked an order for the token owner to approve
    if (_order.placedBy == _order.buyer) {
      require(
        tokenOwner == msg.sender || 
        tokenApprovedAddress == msg.sender ||
        permissionManagement.moderators(msg.sender) == true, 
        "Only token owner can accept this offer"
      );

      _executeOrder(_orderId);
      allowedNFTContract.marketTransfer(tokenOwner, _order.buyer, _order.tokenId);
    } else {
      // if token owner/approved address, offered the buyer
      require(_order.buyer == msg.sender, "Only the address that was offered can accept this offer");
      require(_order.placedBy == tokenOwner, "Offer expired as the token is no more owned by the original offerer");

      // require offer price
      require(msg.value >= _order.price, "Insufficient amount sent");

      _executeOrder(_orderId);
      allowedNFTContract.marketTransfer(tokenOwner, _order.buyer, _order.tokenId);

      return _orderId;
    }

    return _orderId;
  }

  /// @notice Allows either party in an Order to cancel the Order
  /// @dev Cancels an Order
  /// @param _orderId ID of the Order to Cancel
  function cancelOffer(
    uint256 _orderId
  ) validGasPrice external returns(uint256) {
    permissionManagement.adhereToBanMethod(msg.sender);

    Order memory _order = orders[_orderId];
    address tokenOwner = allowedNFTContract.ownerOf(_order.tokenId);
    address tokenApprovedAddress = allowedNFTContract.getApproved(_order.tokenId);

    require(
      _order.placedBy == msg.sender || 
      tokenOwner == msg.sender || 
      tokenApprovedAddress == msg.sender ||
      permissionManagement.moderators(msg.sender) == true, 
      "You do not have the right to cancel this offer"
    );

    // if your bid was the highest on an auctioned token, then you cannot cancel
    if (auctions[getLatestAuctionIDByTokenID[_order.tokenId]].highestBidOrderId == _orderId && _order.isDuringAuction == true) {
      revert("Highest Bid cant be cancelled during an Auction");
    }

    _cancelOrder(_orderId);

    return _orderId;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
pragma solidity >=0.4.22 <0.9.0;

/**
 * Author: Kumar Abhirup (kumareth)
 * Version: 1.0.1
 * Compiles best with: 0.7.6

 * Many contracts have ownerOnly functions, 
 * but I believe it's safer to have multiple owner addresses
 * to fallback to, in case you lose one.

 * You can inherit this PermissionManagement contract
 * to let multiple people do admin operations on your contract effectively.

 * You can add & remove admins and moderators.
 * You can transfer ownership (basically you can change the founder).
 * You can change the beneficiary (the prime payable wallet) as well.

 * You can also ban & unban addresses,
 * to restrict certain features on your contract for certain addresses.

 * Use modifiers like "founderOnly", "adminOnly", "moderatorOnly" & "adhereToBan"
 * in your contract to put the permissions to use.

 * Code: https://ipfs.io/ipfs/QmbVZevdhRwXfoeVti9GLo7tESUrSg7b2psHxugz9Dx1cg
 * IPFS Metadata: https://ipfs.io/ipfs/Qmdh8DC3FHxCPEVEvhXzZWMHZ8y3Dbavzvtib7s7rEBmcs

 * Access the Contract on the Ethereum Ropsten Testnet Network
 * https://ropsten.etherscan.io/address/0xceaef9490f7516914c056bc5902633e76790a999
 */

/// @title PermissionManagement Contract
/// @author [email protected]
/// @notice Like Openzepplin Ownable, but with many Admins and Moderators.
/// @dev Like Openzepplin Ownable, but with many Admins and Moderators.
/// In Monument.app context, It's recommended that all the admins except the Market Contract give up their admin perms later down the road, or maybe delegate those powers to another transparent contract to ensure trust.
contract PermissionManagement {
  address public founder = msg.sender;
  address payable public beneficiary = payable(msg.sender);

  mapping(address => bool) public admins;
  mapping(address => bool) public moderators;
  mapping(address => bool) public bannedAddresses;

  enum RoleChange { 
    MADE_FOUNDER, 
    MADE_BENEFICIARY, 
    PROMOTED_TO_ADMIN, 
    PROMOTED_TO_MODERATOR, 
    DEMOTED_TO_MODERATOR, 
    KICKED_FROM_TEAM, 
    BANNED, 
    UNBANNED 
  }

  event PermissionsModified(address _address, RoleChange _roleChange);

  constructor (
    address[] memory _admins, 
    address[] memory _moderators
  ) {
    // require more admins for safety and backup
    require(_admins.length > 0, "Admin addresses not provided");

    // make founder the admin and moderator
    admins[founder] = true;
    moderators[founder] = true;
    emit PermissionsModified(founder, RoleChange.MADE_FOUNDER);

    // give admin privileges, and also make admins moderators.
    for (uint256 i = 0; i < _admins.length; i++) {
      admins[_admins[i]] = true;
      moderators[_admins[i]] = true;
      emit PermissionsModified(_admins[i], RoleChange.PROMOTED_TO_ADMIN);
    }

    // give moderator privileges
    for (uint256 i = 0; i < _moderators.length; i++) {
      moderators[_moderators[i]] = true;
      emit PermissionsModified(_moderators[i], RoleChange.PROMOTED_TO_MODERATOR);
    }
  }

  modifier founderOnly() {
    require(
      msg.sender == founder,
      "This function is restricted to the contract's founder."
    );
    _;
  }

  modifier adminOnly() {
    require(
      admins[msg.sender] == true,
      "This function is restricted to the contract's admins."
    );
    _;
  }

  modifier moderatorOnly() {
    require(
      moderators[msg.sender] == true,
      "This function is restricted to the contract's moderators."
    );
    _;
  }

  modifier adhereToBan() {
    require(
      bannedAddresses[msg.sender] != true,
      "You are banned from accessing this function in the contract."
    );
    _;
  }

  modifier addressMustNotBeFounder(address _address) {
    require(
      _address != founder,
      "Address must not be the Founder's address."
    );
    _;
  }

  modifier addressMustNotBeAdmin(address _address) {
    require(
      admins[_address] != true,
      "Address must not be an Admin's address."
    );
    _;
  }

  modifier addressMustNotBeModerator(address _address) {
    require(
      moderators[_address] != true,
      "Address must not be a Moderator's address."
    );
    _;
  }

  modifier addressMustNotBeBeneficiary(address _address) {
    require(
      _address != beneficiary,
      "Address must not be a Beneficiary's address."
    );
    _;
  }

  function founderOnlyMethod(address _address) public view {
    require(
      _address == founder,
      "This function is restricted to the contract's founder."
    );
  }

  function adminOnlyMethod(address _address) public view {
    require(
      admins[_address] == true,
      "This function is restricted to the contract's admins."
    );
  }

  function moderatorOnlyMethod(address _address) public view {
    require(
      moderators[_address] == true,
      "This function is restricted to the contract's moderators."
    );
  }

  function adhereToBanMethod(address _address) public view {
    require(
      bannedAddresses[_address] != true,
      "You are banned from accessing this function in the contract."
    );
  }

  function addressMustNotBeFounderMethod(address _address) public view {
    require(
      _address != founder,
      "Address must not be the Founder's address."
    );
  }

  function addressMustNotBeAdminMethod(address _address) public view {
    require(
      admins[_address] != true,
      "Address must not be an Admin's address."
    );
  }

  function addressMustNotBeModeratorMethod(address _address) public view {
    require(
      moderators[_address] != true,
      "Address must not be a Moderator's address."
    );
  }

  function addressMustNotBeBeneficiaryMethod(address _address) public view {
    require(
      _address != beneficiary,
      "Address must not be a Beneficiary's address."
    );
  }

  function transferFoundership(address payable _founder) 
    public 
    founderOnly
    addressMustNotBeFounder(_founder)
    returns(address)
  {
    require(_founder != msg.sender, "You cant make yourself the founder.");
    
    founder = _founder;
    admins[_founder] = true;
    moderators[_founder] = true;

    emit PermissionsModified(_founder, RoleChange.MADE_FOUNDER);

    return founder;
  }

  function changeBeneficiary(address payable _beneficiary) 
    public
    adminOnly
    returns(address)
  {
    require(_beneficiary != msg.sender, "You cant make yourself the beneficiary.");
    
    beneficiary = _beneficiary;
    emit PermissionsModified(_beneficiary, RoleChange.MADE_BENEFICIARY);

    return beneficiary;
  }

  function addAdmin(address _admin) 
    public 
    adminOnly
    returns(address) 
  {
    admins[_admin] = true;
    moderators[_admin] = true;
    emit PermissionsModified(_admin, RoleChange.PROMOTED_TO_ADMIN);
    return _admin;
  }

  function removeAdmin(address _admin) 
    public 
    adminOnly
    addressMustNotBeFounder(_admin)
    returns(address) 
  {
    require(_admin != msg.sender, "You cant remove yourself from the admin role.");
    delete admins[_admin];
    emit PermissionsModified(_admin, RoleChange.DEMOTED_TO_MODERATOR);
    return _admin;
  }

  function addModerator(address _moderator) 
    public 
    adminOnly
    returns(address) 
  {
    moderators[_moderator] = true;
    emit PermissionsModified(_moderator, RoleChange.PROMOTED_TO_MODERATOR);
    return _moderator;
  }

  function removeModerator(address _moderator) 
    public 
    adminOnly
    addressMustNotBeFounder(_moderator)
    addressMustNotBeAdmin(_moderator)
    returns(address) 
  {
    require(_moderator != msg.sender, "You cant remove yourself from the moderator role.");
    delete moderators[_moderator];
    emit PermissionsModified(_moderator, RoleChange.KICKED_FROM_TEAM);
    return _moderator;
  }

  function ban(address _ban) 
    public 
    moderatorOnly
    addressMustNotBeFounder(_ban)
    addressMustNotBeAdmin(_ban)
    addressMustNotBeModerator(_ban)
    addressMustNotBeBeneficiary(_ban)
    returns(address) 
  {
    bannedAddresses[_ban] = true;
    emit PermissionsModified(_ban, RoleChange.BANNED);
    return _ban;
  }

  function unban(address _ban) 
    public 
    moderatorOnly
    returns(address) 
  {
    bannedAddresses[_ban] = false;
    emit PermissionsModified(_ban, RoleChange.UNBANNED);
    return _ban;
  }
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0 <0.9.0;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./utils/NFT.sol";
import "./utils/Taxes.sol";
import "./Splits.sol";

/// @title MonumentArtifacts Contract
/// @author [email protected]
/// @notice This contract shall be the prime Monument NFT contract consisting of all the Artifacts in the Metaverse.
contract MonumentArtifacts is NFT, Taxes, ReentrancyGuard {
  // PermissionManagement internal permissionManagement; <- No need for this as `permissionManagement` is already accessible from the `NFT`.
  using SafeMath for uint;



  /// @notice Constructor function for the MonumentArtifacts Contract
  /// @dev Constructor function for the MonumentArtifacts ERC721 Contract
  /// @param name_ Name of the Monument artifact Collection
  /// @param symbol_ Symbol for the Monument
  /// @param _permissionManagementContractAddress Address of the PermissionManagement Contract that manages Permissions.
  constructor(
    string memory name_, 
    string memory symbol_,
    address _permissionManagementContractAddress
  )
  NFT(name_, symbol_, _permissionManagementContractAddress)
  Taxes(_permissionManagementContractAddress)
  payable
  {
    // Build Genesis Artifact and Zero Token
    _mintArtifact("https://monument.app/artifacts/0.json", 1, block.timestamp);
  }




  // token IDs counter
  using Counters for Counters.Counter;
  Counters.Counter public totalArtifacts;
  Counters.Counter public totalTokensMinted;




  // Artifacts
  struct Artifact {
    uint256 id;
    string metadata;
    uint256 supply; // editions
    uint256 blockTimestamp;
    uint256 artifactTimestamp;
    address author;
  }
  Artifact[] public artifacts;
  mapping(address => uint256[]) public getArtifactIDsByAuthor;

  // Track Artifact Tokens
  mapping(uint256 => uint256[]) public getTokenIDsByArtifactID;
  mapping(uint256 => uint256) public getArtifactIDByTokenID;
  mapping(address => uint256[]) public getTokenIDsByAuthor;
  mapping(uint256 => address) public getAuthorByTokenID;

  // Artifact Metadata Mapping
  mapping(string => bool) public artifactMetadataExists;
  mapping(string => uint256) public getArtifactIDByMetadata;

  // Store Royalty Permyriad for Artifacts
  mapping(uint256 => uint256) public getRoyaltyPermyriadByArtifactID;

  // Artifact Fork Data
  mapping(uint256 => uint256[]) public getForksOfArtifact;
  mapping(uint256 => uint256) public getArtifactForkedFrom;

  // Mentions (for on-chain tagging)
  mapping(uint256 => address[]) public getMentionsByArtifactID;
  mapping(address => uint256[]) public getArtifactsMentionedInByAddress;




  // Used to Split Royalty
  // See EIP-2981 for more information: https://eips.ethereum.org/EIPS/eip-2981
  struct RoyaltyInfo {
    address reciever;
    uint256 percent; // it's actually a permyriad (parts per ten thousand)
  }
  mapping(uint256 => RoyaltyInfo) getRoyaltyInfoByArtifactId;

  /// @notice returns royalties info for the given Artifact ID
  /// @dev can be used by other contracts to get royaltyInfo
  /// @param _tokenID Token ID of which royaltyInfo is to be fetched
  /// @param _salePrice Desired Sale Price of the token to run calculations on
  function royaltyInfo(uint256 _tokenID, uint256 _salePrice)
  	external
  	view
  	returns (address receiver, uint256 royaltyAmount)
  {
    RoyaltyInfo memory rInfo = getRoyaltyInfoByArtifactId[getArtifactIDByTokenID[_tokenID]];
	if (rInfo.reciever == address(0)) return (address(0), 0);
	uint256 amount = SafeMath.div(_salePrice.mul(rInfo.percent), 10000);
	return (payable(rInfo.reciever), amount);
  }




  // Events
  event MintArtifact (
    uint256 indexed id,
    string metadata,
    uint256 supply,
    address indexed author,
    uint256 paidAmount
  );




  // Public Functions

  /// @notice Creates an Artifact on a Monument
  /// @param metadata IPFS / Arweave / Custom URL
  /// @param supply A non-zero value of NFTs to mint for this Artifact
  /// @param mentions Array of addresses to Mention in the Artifact
  /// @param forkOf Artifact ID of the Artifact you want to create a Fork of. 0 for nothing.
  /// @param artifactTimestamp Date the Artifact corelates to.
  /// @param royaltyPermyriad Permyriad of Royalty tagged people wish to collectively collect on NFT sale in the market
  /// @param splitBeneficiaries An array of Beneficiaries to Split Royalties among
  /// @param permyriadsCorrespondingToSplitBeneficiaries An array specifying how much portion of the total royalty each split beneficiary gets
  /// @param splitsContractAddress If a Split Contract is already minted, specify its address, in that case, splitBeneficiaries & permyriadsCorrespondingToSplitBeneficiaries parameters shall be ignored
  function mintArtifact(
      string memory metadata,
      uint256 supply,
      address[] memory mentions,
      uint256 forkOf,
      uint256 artifactTimestamp,
      uint256 royaltyPermyriad,
      address[] memory splitBeneficiaries,
      uint256[] memory permyriadsCorrespondingToSplitBeneficiaries,
      address splitsContractAddress
    )
    external
    payable
    nonReentrant
    returns(uint256)
  {
    permissionManagement.adhereToBanMethod(msg.sender);
    
    // royaltyPermyriad should be 0-10000 only
    require(royaltyPermyriad >= 0 && royaltyPermyriad <= 10000, "Invalid Royalty Permyriad value");

    // splitBeneficiaries & permyriadsCorrespondingToSplitBeneficiaries Array length should be equal
    require(splitBeneficiaries.length == permyriadsCorrespondingToSplitBeneficiaries.length, "Invalid Beneficiary Data");

    // sum of permyriadsCorrespondingToSplitBeneficiaries must be 10k
    uint256 _totalPermyriad;
    for (uint256 i = 0; i < splitBeneficiaries.length; i++) {
      require(splitBeneficiaries[i] != address(0));
      require(permyriadsCorrespondingToSplitBeneficiaries[i] > 0);
      require(permyriadsCorrespondingToSplitBeneficiaries[i] <= 10000);
      _totalPermyriad += permyriadsCorrespondingToSplitBeneficiaries[i];
    }
    require(_totalPermyriad == 10000, "Total Permyriad must be 10000");

    // metadata must not be empty
    require(bytes(metadata).length > 0, "Empty Metadata");

    // make sure another artifact with the same metadata does not exist
    require(artifactMetadataExists[metadata] != true, "Artifact already minted");

    // forkOf must be a valid Artifact ID
    require(artifacts[forkOf].blockTimestamp > 0, "Invalid forkOf Artifact");

    // supply cant be 0
    require(supply > 0, "Supply must be non-zero");

    // charge taxes (if any)
    _chargeArtifactTax();

	uint256 artifactID = _mintArtifact(metadata, supply, artifactTimestamp);
	getRoyaltyPermyriadByArtifactID[artifactID] = royaltyPermyriad;

    if (royaltyPermyriad == 0) {
      getRoyaltyInfoByArtifactId[artifactID] = RoyaltyInfo(address(0), 0);
    } else if (splitsContractAddress != address(0)) {
      getRoyaltyInfoByArtifactId[artifactID] = RoyaltyInfo(splitsContractAddress, royaltyPermyriad);
    } else {
      // Mint a new Splits contract
      Splits splits = new Splits(splitBeneficiaries, permyriadsCorrespondingToSplitBeneficiaries);
      
      // Populate royalties map for new Artifact ID
      getRoyaltyInfoByArtifactId[artifactID] = RoyaltyInfo(address(splits), royaltyPermyriad);
    }

    // Mention
    getMentionsByArtifactID[artifactID] = mentions;
    for (uint256 i = 0; i < mentions.length; i++) {
      getArtifactsMentionedInByAddress[mentions[i]].push(artifactID);
    }

    // Attach Forks
    getForksOfArtifact[forkOf].push(artifactID);
    getArtifactForkedFrom[artifactID] = forkOf;

    return artifactID;
  }




  // Functions for Internal Use

  /// @dev Builds an Artifact with no checks. For internal use only.
  function _mintArtifact(
    string memory metadata,
    uint256 supply,
    uint256 artifactTimestamp
  )
    internal
    returns(uint256)
  {
    uint256 newId = totalArtifacts.current();
    totalArtifacts.increment();

    artifacts.push(
      Artifact(
        newId,
        metadata,
        supply,
        block.timestamp,
        artifactTimestamp,
        msg.sender
      )
    );
    artifactMetadataExists[metadata] = true;
    getArtifactIDByMetadata[metadata] = newId;
    getArtifactIDsByAuthor[msg.sender].push(newId);

    // Mint tokens
    for (uint256 i = 0; i < supply; i++) {
      uint256 newTokenId = totalTokensMinted.current();
      totalTokensMinted.increment();

      _mint(msg.sender, newTokenId);
      _setTokenURI(newTokenId, metadata);
      
      getTokenIDsByArtifactID[newId].push(newTokenId);
      getArtifactIDByTokenID[newTokenId] = newId;

      getTokenIDsByAuthor[msg.sender].push(newTokenId);
      getAuthorByTokenID[newTokenId] = msg.sender;
    }

    // Emit Event
    emit MintArtifact (
      newId,
      metadata,
      supply,
      msg.sender,
      msg.value
    );

    return newId;
  }
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC721/IERC721.sol";
import "../PermissionManagement.sol";

/// @title Payable Contract
/// @author [email protected]
/// @notice If this abstract contract is inherited, the Contract becomes payable, it also allows Admins to manage Assets owned by the Contract.
abstract contract Payable {
  PermissionManagement private permissionManagement;

  constructor (
    address _permissionManagementContractAddress
  ) {
    permissionManagement = PermissionManagement(_permissionManagementContractAddress);
  }

  event ReceivedFunds(
    address indexed by,
    uint256 fundsInwei,
    uint256 timestamp
  );

  event SentToBeneficiary(
    address indexed actionCalledBy,
    address indexed beneficiary,
    uint256 fundsInwei,
    uint256 timestamp
  );

  event ERC20SentToBeneficiary(
    address indexed actionCalledBy,
    address indexed beneficiary,
    address indexed erc20Token,
    uint256 tokenAmount,
    uint256 timestamp
  );

  event ERC721SentToBeneficiary(
    address indexed actionCalledBy,
    address indexed beneficiary,
    address indexed erc721ContractAddress,
    uint256 tokenId,
    uint256 timestamp
  );

  function getBalance() public view returns(uint256) {
    return address(this).balance;
  }

  /// @notice To pay the contract
  function fund() external payable {
    emit ReceivedFunds(msg.sender, msg.value, block.timestamp);
  }

  fallback() external virtual payable {
    emit ReceivedFunds(msg.sender, msg.value, block.timestamp);
  }

  receive() external virtual payable {
    emit ReceivedFunds(msg.sender, msg.value, block.timestamp);
  }

  /// So the Admins can maintain control over all the Funds the Contract might own in future
  /// @notice Sends Wei the Contract might own, to the Beneficiary
  /// @param _amountInWei Amount in Wei you think the Contract has, that you want to send to the Beneficiary
  function sendToBeneficiary(uint256 _amountInWei) external returns(uint256) {
    permissionManagement.adminOnlyMethod(msg.sender);

    payable(permissionManagement.beneficiary()).transfer(_amountInWei);
    
    emit SentToBeneficiary(msg.sender, permissionManagement.beneficiary(), _amountInWei, block.timestamp);
    return _amountInWei;
  }

  /// So the Admins can maintain control over all the ERC20 Tokens the Contract might own in future
  /// @notice Sends ERC20 tokens the Contract might own, to the Beneficiary
  /// @param _erc20address Address of the ERC20 Contract
  /// @param _tokenAmount Amount of Tokens you wish to send to the Beneficiary.
  function sendERC20ToBeneficiary(address _erc20address, uint256 _tokenAmount) external returns(address, uint256) {
    permissionManagement.adminOnlyMethod(msg.sender);

    IERC20 erc20Token;
    erc20Token = IERC20(_erc20address);

    erc20Token.transferFrom(address(this), permissionManagement.beneficiary(), _tokenAmount);

    emit ERC20SentToBeneficiary(msg.sender, permissionManagement.beneficiary(), _erc20address, _tokenAmount, block.timestamp);

    return (_erc20address, _tokenAmount);
  }

  /// So the Admins can maintain control over all the ERC721 Tokens the Contract might own in future.
  /// @notice Sends ERC721 tokens the Contract might own, to the Beneficiary
  /// @param _erc721address Address of the ERC721 Contract
  /// @param _tokenId ID of the Token you wish to send to the Beneficiary.
  function sendERC721ToBeneficiary(address _erc721address, uint256 _tokenId) external returns(address, uint256) {
    permissionManagement.adminOnlyMethod(msg.sender);

    IERC721 erc721Token;
    erc721Token = IERC721(_erc721address);

    erc721Token.safeTransferFrom(address(this), permissionManagement.beneficiary(), _tokenId);

    emit ERC721SentToBeneficiary(msg.sender, permissionManagement.beneficiary(), _erc721address, _tokenId, block.timestamp);

    return (_erc721address, _tokenId);
  }
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.4.22 <0.9.0;

import "../PermissionManagement.sol";

/// @title Max Gas Price Checker
/// @author [email protected]
/// @notice Used to stop Front Runner attacks in a Market
/// @dev Admins can set MaxGasPrice, allowing Functions to fail if the set Gas Price exceeds.
abstract contract MaxGasPrice {
  PermissionManagement private permissionManagement;

  constructor (
    address _permissionManagementContractAddress
  ) {
    permissionManagement = PermissionManagement(_permissionManagementContractAddress);
  }

  uint256 public maxGasPrice = 1 * 10 ** 18;

  modifier validGasPrice() {
    require(
        tx.gasprice <= maxGasPrice,
        "Max Gas Price Exceeded"
    );
    _;
  }

  function setMaxGasPrice(uint256 newMax)
    public
    returns (bool) 
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    maxGasPrice = newMax;
    return true;
  }
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.4.22 <0.9.0;

import "./AdminOps.sol";
import "./ERC721/extensions/ERC721Enumerable.sol";
import "../PermissionManagement.sol";
import "./Payable.sol";

/// @title NFT Contract
/// @author [email protected]
/// @notice An ERC721 Inheritable Contract with many features (like, ERC721Enumerable, accepting payments, admin ability to transfer tokens, etc.)
abstract contract NFT is AdminOps, ERC721Enumerable, Payable {
  PermissionManagement internal permissionManagement;

  constructor (
    string memory name_, 
    string memory symbol_,
    address _permissionManagementContractAddress
  )
  ERC721(name_, symbol_)
  AdminOps(_permissionManagementContractAddress)
  Payable(_permissionManagementContractAddress)
  {
    permissionManagement = PermissionManagement(_permissionManagementContractAddress);
  }

  string public baseURI = ""; //-> could have been "https://monument.app/artifacts/"

  function _baseURI() internal view virtual override(ERC721) returns (string memory) {
    return baseURI;
  }

  function changeBaseURI(string memory baseURI_) public returns (string memory) {
    permissionManagement.adminOnlyMethod(msg.sender);
    baseURI = baseURI_;
    return baseURI;
  }

  function exists(uint256 tokenId) public view returns (bool) {
    return _exists(tokenId);
  }

  /* Extend AdminOps.sol */
  function godlySetTokenURI(uint256 _tokenId, string memory _tokenURI) 
    public
    returns(uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    _setTokenURI(_tokenId, _tokenURI);
    return _tokenId;
  }

  /* Overridings */
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  mapping(uint256 => string) private _tokenURIs;

  /// @notice Fetch URL of the Token
  /// @dev From OpenZepplin
  /// @param tokenId ID of the Token whose URI to fetch
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "URI query for nonexistent token");

      string memory _tokenURI = _tokenURIs[tokenId];
      string memory base = _baseURI();

      // If there is no base URI, return the token URI.
      if (bytes(base).length == 0) {
          return _tokenURI;
      }
      
      // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
      if (bytes(_tokenURI).length > 0) {
          return string(abi.encodePacked(base, _tokenURI));
      }

      return super.tokenURI(tokenId);
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
      require(_exists(tokenId), "URI set of nonexistent token");
      _tokenURIs[tokenId] = _tokenURI;
  }

  function _burn(uint256 tokenId) internal virtual override {
      super._burn(tokenId);

      if (bytes(_tokenURIs[tokenId]).length != 0) {
          delete _tokenURIs[tokenId];
      }
  }
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.4.22 <0.9.0;

import "../PermissionManagement.sol";

/// @title Taxes Contract
/// @author [email protected]
/// @notice In Monument.app context, this contract allows the Beneficiary to collect taxes everytime a Monument or an Artifact is minted.
abstract contract Taxes {
  PermissionManagement private permissionManagement;

  constructor (
    address _permissionManagementContractAddress
  ) {
    permissionManagement = PermissionManagement(_permissionManagementContractAddress);
  }

  event TaxesChanged (
    uint256 newTaxOnMintingAnArtifact,
    address indexed actionedBy
  );

  uint256 public taxOnMintingAnArtifact = 0; // `26 * (10 ** 13)` was around $1 in Oct 2021

  /// @notice To set new taxes for Building and Minting
  /// @param _onMintingArtifact Tax in wei, for minting an Artifact.
  function setTaxes(uint256 _onMintingArtifact)
    public
    returns (uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);

    taxOnMintingAnArtifact = _onMintingArtifact;

    emit TaxesChanged (
      _onMintingArtifact,
      msg.sender
    );

    return _onMintingArtifact;
  }

  /// @notice Taxes are sent to the Beneficiary
  function _chargeArtifactTax()
    internal
    returns (bool)
  {
    require(
      msg.value >= taxOnMintingAnArtifact || 
      permissionManagement.moderators(msg.sender), // moderators dont pay taxes
      "Insufficient amount sent"
    );

    if (msg.value >= taxOnMintingAnArtifact) {
      (bool success, ) = permissionManagement.beneficiary().call{value: taxOnMintingAnArtifact}("");
      require(success, "Transfer to Beneficiary failed");
    }
    
    return true;
  }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title The Splits Contract Instance
/// @author [email protected]
/// @notice This contract shall be deployed everytime a user mints an artifact. This contract will manage the split sharing of royalty fee that it receives.
contract Splits is ReentrancyGuard {
    mapping(address => uint256) public royalties;

    address[] public splitters;
    uint256[] public permyriads;

    /// @notice Constructor function for the Splits Contract Instances
    /// @dev Takes in the array of Splitters and Permyriads, fills the storage, to set the Split rules accordingly.
    /// @param _splitters An array of addresses that shall be entitled to some permyriad share of the total royalty supplied to the contract, from the market, preferrably.
    /// @param _permyriads An array of numbers that represent permyriads, all its elements must add up to a total of 10000, and must be in order of splitters supplied during construction of the contract.
    constructor(address[] memory _splitters, uint256[] memory _permyriads) payable {
        require(_splitters.length == _permyriads.length);

        uint256 _totalPermyriad;

        for (uint256 i = 0; i < _splitters.length; i++) {
            require(_splitters[i] != address(0));
            require(_permyriads[i] > 0);
            require(_permyriads[i] <= 10000);
            _totalPermyriad += _permyriads[i];
        }

        require(_totalPermyriad == 10000, "Total permyriad must be 10000");

        for (uint256 i = 0; i < _splitters.length; i++) {
            royalties[_splitters[i]] = _permyriads[i];
        }

        splitters = _splitters;
        permyriads = _permyriads;
    }

    /// @notice Get Balance of the Split Contract
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    // Events
    event ReceivedFunds(
        address indexed by,
        uint256 fundsInwei,
        uint256 timestamp
    );
    event DistributedERC20(
        address indexed erc20address,
        uint256 amountDistributed,
        uint256 timestamp
    );

    /// @notice Allow this contract to split funds everytime it receives it
    fallback() external virtual nonReentrant payable {
        emit ReceivedFunds(msg.sender, msg.value, block.timestamp);
        distributeFunds();
    }

    /// @notice Allow this contract to split funds everytime it receives it
    receive() external virtual nonReentrant payable {
        emit ReceivedFunds(msg.sender, msg.value, block.timestamp);
        distributeFunds();
    }

    /// @notice This is a payable function that distributes whatever amount it gets, to all the addresses in the splitters array, according to their royalty permyriad share set in royalties mapping.
    function distributeFunds() public nonReentrant payable {
        require(msg.value > 0, "funds must be more than 0 to be distributed");

        emit ReceivedFunds(msg.sender, msg.value, block.timestamp);

        for (uint256 i = 0; i < splitters.length; i++) {
            payable(splitters[i]).transfer((msg.value / 10000) * permyriads[i]);
        }
    }

    /// @notice This is a function that distributes any ERC20 tokens that the contract may own, to all the addresses in the splitters array, according to their royalty permyriad share set in royalties mapping.
    function distributeERC20(address _erc20address) public nonReentrant returns (address, uint256) {
        IERC20 erc20Token;
        erc20Token = IERC20(_erc20address);

        require(erc20Token.balanceOf(address(this)) > 0, "must have more than 0 tokens to be distributed");

        for (uint256 i = 0; i < splitters.length; i++) {
            erc20Token.transferFrom(
                address(this), 
                splitters[i], 
                (erc20Token.balanceOf(address(this)) / 10000) * permyriads[i]
            );
        }

        emit DistributedERC20(
            _erc20address,
            erc20Token.balanceOf(address(this)),
            block.timestamp
        );

        return (_erc20address, erc20Token.balanceOf(address(this)));
    }

    /// @notice Takes in an address and returns how much permyriad share of the total royalty the address was originally entitled to.
    /// @param _address Address whose royalty precentage share information to fetch.
    /// @return uint256 - Permyriad Royalty the address was originally entitled to.
    function royaltySplitInfo(address _address) public view returns (uint256) {
        uint256 royaltyPermyriad = royalties[_address];
        return royaltyPermyriad;
    }
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721/ERC721.sol";
import "../PermissionManagement.sol";

/// @title Admin Operations Contract
/// @author [email protected]
/// @notice An ERC721 Inheritable contract that provides Admins the ability to have ultimate permissions over all the Tokens of this contract
/// @dev Monument Market Contract will use `marketTransfer` function to be able to transfer tokens without explicit approval.
abstract contract AdminOps is ERC721 {
  PermissionManagement private permissionManagement;

  constructor (
    address _permissionManagementContractAddress
  ) {
    permissionManagement = PermissionManagement(_permissionManagementContractAddress);
  }

  // function intended to be used, only by the market contract  
  function marketTransfer(address _from, address _to, uint256 _tokenId) 
    public 
    returns(uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    _transfer(_from, _to, _tokenId);
    return _tokenId;
  }

  // all functions below this give permissions to the admins to have complete access to tokens in the project
  // its use is heavily discouraged in a decentralised ecosystem
  // it's recommended that all admins except the market contract give up their admin perms later down the road, or maybe delegate those powers to another transparent contract to ensure trust.
  function godlyTransfer(address _from, address _to, uint256 _tokenId) 
    public 
    returns(uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    _transfer(_from, _to, _tokenId);
    return _tokenId;
  }

  function godlyMint(address _to, uint256 _tokenId) 
    public
    returns(uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    _mint(_to, _tokenId);
    return _tokenId;
  }

  function godlyBurn(uint256 _tokenId) 
    public
    returns(uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    _burn(_tokenId);
    return _tokenId;
  }

  function godlyApprove(address _to, uint256 _tokenId) 
    public
    returns(uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    _approve(_to, _tokenId);
    return _tokenId;
  }

  function godlyApproveForAll(address _owner, address _operator, bool _shouldApprove) 
    public
    returns(address)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    _setApprovalForAll(_owner, _operator, _shouldApprove);
    return _owner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    // /**
    //  * @dev See {IERC165-supportsInterface}.
    //  */
    // function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
    //     return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    // }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "./utils/Address.sol";
import "./utils/Context.sol";
import "./utils/Strings.sol";
import "./utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        // _operatorApprovals[_msgSender()][operator] = approved;
        // emit ApprovalForAll(_msgSender(), operator, approved);

        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/introspection/IERC165.sol";

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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