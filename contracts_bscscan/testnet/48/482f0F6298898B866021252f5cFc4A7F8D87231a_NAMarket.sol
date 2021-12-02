// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title ERC1155 Receiver contract
 * @dev Contract implementing the IERC1155Receiver interface
 * 
 * This contract is meant to be used as a base contract for 
 * other contracts, to enable them to receive ERC1155 transfers.
 * Attempting transfer of ERC1155 tokens to contracts that don't
 * implement this interface will lead to transaction revertion.
 */
contract ERC1155Receiver is IERC1155Receiver, ERC165  {
    
    event ERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes data
    );

    event ERC1155BatchReceived(
        address operator,
        address from,
        uint256[] ids,
        uint256[] values,
        bytes data
    );

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4){
        emit ERC1155Received(operator, from, id, value, data);
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4){
        emit ERC1155BatchReceived(operator, from, ids, values, data);
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./ERC1155Receiver.sol";



/**
 * @title NFT Auction Market
 * Sellers can choose a minimum, starting bid, an expiry time when the auction ends
 * Before creating an auction the seller has to approve this contract for the respective token,
 * which will be held in contract until the auction ends.
 * bid price = price + fee 
 * which he will be refunded in case he gets outbid.
 * After the specified expiry date of an auction anyone can trigger the settlement 
 * Not only will we transfer tokens to new owners, but we will also transfer sales money to sellers.
 * All comissions will be credited to the owner / deployer of the marketplace contract.
 */
contract NAMarket is Ownable, ReentrancyGuard, ERC1155Receiver {

  // Protect against overflow
  using SafeMath for uint256;
  // Add math utilities missing in solidity
  using Math for uint256;
  
  /* Constructor parameters */
  // minBidSize,minAuctionLiveness, GAS_SIZE, feePercentage
  address public adminAddress; 

  // Minimum amount by which a new bid has to exceed previousBid 0.0001 = 1
  uint256 public minBidSize = 1;
  /* Minimum duration in seconds for which the auction has to be live
   * timestamp 1h = 3600s
   * default mainnet 10h / testnet 10m
  */
  uint256 public minAuctionLiveness = 10 * 60;
    
  //transfer gas
  uint16 public GAS_SIZE = 21000;
  // update fee address only owner
  address public feeAddress;
  // default fee percentage : 2.5%
  uint256 public feePercentage = 250;
  //total volume
  uint256 public totalMarketVolume;
  //total Sales
  uint256 public totalSales;
  //create auction on/off default = true
  bool public marketStatus = true;


  // Save Users credit balances (to be used when they are outbid)
  mapping(address => uint256) public userPriceList;

  using Counters for Counters.Counter;
  // Number of auctions ever listed
  Counters.Counter private totalAuctionCount;
  // Number of auctions already sold
  Counters.Counter private closedAuctionCount;

  enum TokenType { NONE, ERC721, ERC1155 }
  enum AuctionStatus { NONE, OPEN, CLOSE, SETTLED, CANCELED }
  enum Categories { NONE, Art, Sports, Gaming, Music, Entertainment, TradingCards, Collectibles }
  enum Sreach { Top, ALL, Art, Sports, Gaming, Music, Entertainment, TradingCards, Collectibles }
  enum Sort { ASC, DESC, NEW, END }
  enum FileType { Img, video, Audio }



  struct Auction {
      address contractAddress;
      uint256 tokenId;
      uint256 currentPrice;
      uint256 buyNowPrice;
      address seller;
      address highestBidder;
      string auctionTitle;
      Categories category;
      AuctionStatus status;
      uint256 expiryDate;
      uint256 auctionId;
      FileType fileType;
      TokenType tokenType;
      uint256 quantity;
  }

  mapping(uint256 => Auction) public auctions;
  //bid
  struct Bid {
        uint256 bidId;
        address bidder;
        uint256 price;
        uint256 timestamp;
  }

  mapping (uint256 => Bid[]) public bidList;

  // Unique seller address
  address[] public uniqSellerList;

  struct SellerSale {
    address seller;
    uint256 price;
    uint256 timestamp;
  }

  mapping (address => SellerSale[]) private sellerSales;


  // EVENTS
  event AuctionCreated(
      uint256 auctionId,
      address contractAddress,
      uint256 tokenId,
      uint256 startingPrice,
      address seller,
      uint256 expiryDate
  );
  event NFTApproved(
      address nftContract
  );


  event AuctionCanceled(
      uint256 auctionId
  );

  event AuctionSettled(
      uint256 auctionId,
      bool sold
  );

  event BidPlaced(
      uint256 auctionId,
      uint256 bidPrice
  );
  event BidFailed(
      uint256 auctionId,
      uint256 bidPrice
  );

  event UserCredited(
     address creditAddress,
     uint256 amount
  );

  // MODIFIERS

  modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

  modifier openAuction(uint256 auctionId) {
      require(auctions[auctionId].status == AuctionStatus.OPEN, "Transaction only permissible for open Auctions");
        _;
  }

  modifier settleStatusCheck(uint256 auctionId) {
    AuctionStatus auctionStatus = auctions[auctionId].status;
      require( auctionStatus != AuctionStatus.SETTLED || 
        auctionStatus != AuctionStatus.CANCELED, "Transaction only permissible for open or close Auctions");

      if (auctionStatus == AuctionStatus.OPEN) {
        require(auctions[auctionId].expiryDate < block.timestamp, "Transaction only valid for expired Auctions");
      }
    _;
  }

  modifier nonExpiredAuction(uint256 auctionId) {
      require(auctions[auctionId].expiryDate >= block.timestamp, "Transaction not valid for expired Auctions");
        _;
  }

  modifier onlyExpiredAuction(uint256 auctionId) {
      require(auctions[auctionId].expiryDate < block.timestamp, "Transaction only valid for expired Auctions");
        _;
  }

  modifier noBids(uint256 auctionId) {
      require(auctions[auctionId].highestBidder == address(0), "Auction has bids already");
        _;
  }

  modifier sellerOnly(uint256 auctionId) {
      require(msg.sender == auctions[auctionId].seller, "Caller is not Seller");
        _;
  }

  modifier marketStatusCheck() {
      require(marketStatus, "Market is closed");
        _;
  }
  // Update market status
  function setMarkStatus(bool _marketStatus) public onlyOwner {
        marketStatus = _marketStatus;
  }
  
  // Update only owner 
  function setFeePercentage(address _feeAddress) public onlyOwner {
        require(_feeAddress != address(0), "Invalid Address");
        feeAddress = _feeAddress;
  }
  // Update admin address 
  function setAdmin(address _adminAddress) public onlyOwner {
        adminAddress = _adminAddress;
  }
  // gas price update default 21000
  function setGasSize(uint16 _gasSize) public onlyAdmin {
        GAS_SIZE = _gasSize;
  }

  // Update minBidSize 
  function setMinBidSize(uint256 _minBidSize) public onlyAdmin {
        minBidSize = _minBidSize;
  }
  // Update minAuctionLiveness 
  function setMinAuctionLiveness(uint256 _minAuctionLiveness) public onlyAdmin {
        minAuctionLiveness = _minAuctionLiveness;
  }
  // Update Fee percentages 
  function setFeePercentage(uint256 _feePercentage) public onlyAdmin {
        require(_feePercentage <= 10000, "Fee percentages exceed max");
        feePercentage = _feePercentage;
  }

  // Calculate fee due for an auction based on its feePrice
  function calculateFee(uint256 _cuPrice) private view returns(uint256 fee){
      fee  = _cuPrice.mul(feePercentage).div(10000);
  }


  /*
  * AUCTION MANAGEMENT
  * Creates a new auction and transfers the token to the contract to be held in escrow until the end of the auction.
  * Requires this contract to be approved for the token to be auctioned.
  */

  function createAuction(address _contractAddress, uint256 _tokenId, uint256 _startingPrice, string memory auctionTitle,
    uint256 _buyNowPrice, uint256 expiryDate, Categories _category, FileType _fileType, TokenType _tokenType,
    uint256 _quantity
    ) public marketStatusCheck() nonReentrant 
    returns(uint256 auctionId){

      require(expiryDate.sub(minAuctionLiveness) > block.timestamp, "Expiry date is not far enough in the future");
      require(_tokenType != TokenType.NONE, "Invalid token type provided");

      uint256 quantity = 1;
      if(_tokenType == TokenType.ERC1155){
        quantity = _quantity;
      }

      // Generate Auction Id
      totalAuctionCount.increment();
      auctionId = totalAuctionCount.current();


      // Register new Auction
      auctions[auctionId] = Auction(_contractAddress, _tokenId, _startingPrice, _buyNowPrice, msg.sender,
       address(0), auctionTitle, _category, AuctionStatus.OPEN, expiryDate, auctionId, _fileType, _tokenType, quantity);
      

      // Transfer Token
      transferToken(auctionId, msg.sender, address(this));


      emit AuctionCreated(auctionId, _contractAddress, _tokenId, _startingPrice, msg.sender, expiryDate);
  }



  /**
   * Cancels an auction and returns the token to the original owner.
   * Requires the caller to be the seller who created the auction, the auction to be open and no bids having been placed on it.
   */
  function cancelAuction(uint256 auctionId) public openAuction(auctionId) noBids(auctionId) sellerOnly(auctionId) nonReentrant{
      auctions[auctionId].status = AuctionStatus.CANCELED;
      closedAuctionCount.increment();
      transferToken(auctionId, address(this), msg.sender);
      emit AuctionCanceled(auctionId);
  }

  /**
   * Settles an auction.
   * If at least one bid has been placed the token will be transfered to its new owner, the seller will be credited the sale price
   * and the contract owner will be credited the fee.
   * If no bid has been placed on the token it will just be transfered back to its original owner.
   */
  function settleAuction(uint256 auctionId) public settleStatusCheck(auctionId) onlyExpiredAuction(auctionId) nonReentrant{
      Auction storage auction = auctions[auctionId];
      auction.status = AuctionStatus.SETTLED;
      closedAuctionCount.increment();
      
      bool sold = auction.highestBidder != address(0);
      if(sold){
        // If token was sold transfer it to its new owner and credit seller / contractOwner with price / fee
        transferToken(auctionId, address(this), auction.highestBidder);
        creditUser(auction.seller, auction.currentPrice);
        creditUser(owner(), calculateFee(auction.currentPrice));
        //TODO: test
        saveSales(auction.seller, auction.currentPrice);
        totalSales.add(auction.currentPrice);
      } else {
        // If token was not sold, return ownership to the seller
        transferToken(auctionId, address(this), auction.seller);
      }
      emit AuctionSettled(auctionId, sold);
  }
  //Save sales information
  function saveSales(address sellerAddress, uint256 price) private {
    if (uniqSellerList.length == 0) {
      uniqSellerList.push(sellerAddress);
    } else {
      bool chkSeller = false;
      for (uint256 i = 0; i < uniqSellerList.length; i++) {
        if (uniqSellerList[i] == sellerAddress) {
          chkSeller = true;
        }
      }
      if (!chkSeller) {
        uniqSellerList.push(sellerAddress);
      }
      SellerSale memory sellerInfo = SellerSale(sellerAddress, price, block.timestamp);
      sellerSales[sellerAddress].push(sellerInfo);
    }
  }


  /**
   * Credit user with given amount in ETH
   * Credits a user with a given amount that he can later withdraw from the contract.
   * Used to refund outbidden buyers and credit sellers / contract owner upon sucessfull sale.
   */
  function creditUser(address creditAddress, uint256 amount) private {
      userPriceList[creditAddress] = userPriceList[creditAddress].add(amount);
      emit UserCredited(creditAddress, amount);
  }

  /**
   *  Withdraws all credit of the caller
   * Transfers all of his credit to the caller and sets the balance to 0
   * Fails if caller has no credit.
   */
  function withdrawCredit() public nonReentrant{
      uint256 creditBalance = userPriceList[msg.sender];
      require(creditBalance > 0, "User has no credits to withdraw");
      userPriceList[msg.sender] = 0;

      (bool success, ) = msg.sender.call{value: creditBalance}("");
      require(success);
  }


  /**
   * Places a bid on the selected auction at the selected price
   * Requires the provided bid price to exceed the current highest bid by at least the minBidSize.
   * Also requires the caller to transfer the exact amount of the chosen bidPrice plus fee, to be held in escrow by the contract
   * until the auction is settled or a higher bid is placed.
   */
  function placeBid(uint256 auctionId, uint256 bidPrice) public openAuction(auctionId) nonExpiredAuction(auctionId) nonReentrant{
      Auction storage auction = auctions[auctionId];
      require(bidPrice >= auction.currentPrice.add(minBidSize/10000), "Bid has to exceed current price by the minBidSize or more");
      require(bidPrice >= auction.currentPrice, "It should be higher than the current bid amount");
      
      uint256 creditAmount;
      // If this is not the first bid, credit the previous highest bidder
      address previousBidder = auction.highestBidder;
      //TODO: buy now test
      if (auction.buyNowPrice <= bidPrice) {
        payout(auctionId, bidPrice);
        auction.status = AuctionStatus.CLOSE;
      } else {
        payout(auctionId, bidPrice);

      }

      //bid list 
      uint256 newBidId = bidList[auctionId].length + 1;
      Bid memory newBid = Bid(newBidId, msg.sender, bidPrice, block.timestamp);
      bidList[auctionId].push(newBid);
      //TODO: fix payable
      
      if(previousBidder != address(0)){
        creditAmount = auction.currentPrice.add(calculateFee(auction.currentPrice));
        creditUser(previousBidder, creditAmount);
      }
    
      auction.highestBidder = msg.sender;
      auction.currentPrice = bidPrice;

      
      emit BidPlaced(auctionId, bidPrice);
  }

  function payout(
        uint256 auctionId,
        uint256 bidPrice
    ) internal {
      require(msg.value == bidPrice.add(calculateFee(bidPrice)), "Transaction value has to equal price + fee");

      // Payment for sales. transfer 
      (bool success, ) = payable(address(this)).call{
        value: msg.value,
          gas: GAS_SIZE
          }("");

        totalMarketVolume.add(bidPrice);
        // if it failed, update their credit balance so they can pull it later
        if (!success) {
          emit BidFailed(auctionId, bidPrice);
        }
  }

  /**
   * Transfer the token(s) belonging to a given auction.
   * Supports both ERC721 and ERC1155 tokens
   */
  function transferToken(uint256 auctionId, address from, address to) private {
      require(to != address(0), "Cannot transfer token to zero address");

      Auction storage auction = auctions[auctionId];
      require(auction.status != AuctionStatus.NONE, "Cannot transfer token of non existent auction");

      TokenType tokenType = auction.tokenType;
      uint256 tokenId = auction.tokenId;
      address contractAddress = auction.contractAddress;

      if(tokenType == TokenType.ERC721){
        IERC721(contractAddress).transferFrom(from, to, tokenId);
      }
      else if(tokenType == TokenType.ERC1155){
        uint256 quantity = auction.quantity;
        require(quantity > 0, "Cannot transfer 0 quantity of ERC1155 tokens");
        IERC1155(contractAddress).safeTransferFrom(from, to, tokenId, quantity, "");
      }
      else{
        revert("Invalid token type for transfer");
      }
  }

  //TODO: test
  //data func auction list 
  function getOpenAuctions(Categories category, Sort sort, string memory keyword, 
  uint256 offset, uint256 limit, FileType fileType) public view returns 
  (Auction[] memory, uint256 newOffset, uint256 totalOpenAuctionsCount) {
        Auction[] memory values = new Auction[] (totalAuctionCount.current());
        
        for (uint256 i = 0; i < totalAuctionCount.current(); i++) {
          //auction open
          if(auctions[i].status == AuctionStatus.OPEN){
            //category
            if (Categories.NONE != category) {
              if(auctions[i].category == category){
                values[i] = auctions[i];
              } 
            } else {
              if (auctions[i].fileType == fileType) {
                values[i] = auctions[i];
              } else {
                values[i] = auctions[i];
              }
            }
          }  
        }
        uint256 openAuctionSize = values.length;
        //search
        Auction[] memory searchValues = new Auction[] (openAuctionSize);
        bytes memory checkString = bytes(keyword);
        if (checkString.length > 0) {
          for (uint256 i = 0; i < openAuctionSize; i++) {
              if (keccak256(abi.encodePacked((values[i].auctionTitle))) == keccak256(abi.encodePacked((keyword)))) {
                searchValues[i] = values[i];
              }
          }
        } else {
          searchValues = values;
        }

        uint256 openAuctionsCount = searchValues.length;

        //sort
        Auction[] memory sortValues = new Auction[] (openAuctionsCount);
        for (uint256 i = 0; i < openAuctionsCount; i++) {
          if (Sort.NEW == sort)  {
            sortValues = sortNew(searchValues, openAuctionsCount);
          } else if (Sort.END == sort)  {
            sortValues = sortEnd(searchValues, openAuctionsCount);
          } else if (Sort.ASC == sort)  {
            sortValues = sortAsc(searchValues, openAuctionsCount);
          } else {
            sortValues = sortDesc(searchValues, openAuctionsCount);
          }
        }

        if(limit == 0) {
            limit = 1;
        }
        
        if (limit > openAuctionsCount - offset) {
            limit = openAuctionsCount - offset;
        }
        Auction[] memory newAuctions = new Auction[] (openAuctionsCount);

        for (uint256 i = 0; i < limit; i++) {
          newAuctions[i] = sortValues[offset+i];
        }

        return (newAuctions, offset + limit, openAuctionsCount);
  }

  //auction data
  function getOpenAuctions(uint256 auctionId) public view returns(Auction memory){
      return auctions[auctionId];
  }
  //bids data
  function getBids(uint256 auctionId) public view returns(Bid[] memory){
      return bidList[auctionId];
  }

  //TMV
  function getTMV() public view returns(uint256){
    return totalMarketVolume;
  }

  //Total sales market
  function getTotalSales() public view returns(uint256) {
      return totalSales;
  }
  // 1day 7day, 1month
  // timestamp
  //TODO: test
  //seller sales list test
  function getSellerSalesList(uint256 timestamp) public view returns(SellerSale[] memory) {
    SellerSale[] memory topSellerList = new SellerSale[](uniqSellerList.length);
    SellerSale memory cuSellerSales;
    for(uint256 i = 0; i < uniqSellerList.length; i++) {
      cuSellerSales.seller = uniqSellerList[i];
      cuSellerSales.price = 0;
      cuSellerSales.timestamp = timestamp;
      for(uint256 j = 0; j < sellerSales[uniqSellerList[i]].length; j++) {
        if (timestamp >= sellerSales[uniqSellerList[i]][j].timestamp) {
          cuSellerSales.price.add(sellerSales[uniqSellerList[i]][j].price);
        }
      }
      topSellerList[i] = cuSellerSales;
    }
    return topSellerList;
  }
  //TODO: test
  //user auction list (no bid)
  function geUserAuctionList(address userAddress) public view returns(Auction[] memory) {
    Auction[] memory myAuctions;
    for(uint256 i = 0; i < totalAuctionCount.current(); i++) {
      if (auctions[i].seller == userAddress) {
        if (auctions[i].status == AuctionStatus.OPEN || auctions[i].status == AuctionStatus.CLOSE ) {
          myAuctions[i] = auctions[i];
        }
      } 
    }
    return myAuctions;
  }
  

  /*  sort  */
  function sortAsc(Auction[] memory arr, uint256 limit) private pure returns (Auction[] memory) {
        //sort
        Auction memory temp;
        for(uint256 i = 0; i < limit; i++) {
            for(uint256 j = i+1; j < limit ;j++) {
                if(arr[i].currentPrice > arr[j].currentPrice) {
                    temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
        return arr;
  }

  function sortDesc(Auction[] memory arr, uint256 limit) private pure returns (Auction[] memory) {
        //sort
        Auction memory temp;
        for(uint256 i = 0; i < limit; i++) {
            for(uint256 j = i+1; j < limit ;j++) {
                if(arr[i].currentPrice < arr[j].currentPrice) {
                    temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
        return arr;
  }

  function sortNew(Auction[] memory arr, uint256 limit) private pure returns (Auction[] memory) {
        //sort
        Auction memory temp;
        for(uint256 i = 0; i < limit; i++) {
            for(uint256 j = i+1; j < limit ;j++) {
                if(arr[i].expiryDate > arr[j].expiryDate) {
                    temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
        return arr;
  }
  function sortEnd(Auction[] memory arr, uint256 limit) private pure returns (Auction[] memory) {
        //sort
        Auction memory temp;
        for(uint256 i = 0; i < limit; i++) {
            for(uint256 j = i+1; j < limit ;j++) {
                if(arr[i].expiryDate < arr[j].expiryDate) {
                    temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
        return arr;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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