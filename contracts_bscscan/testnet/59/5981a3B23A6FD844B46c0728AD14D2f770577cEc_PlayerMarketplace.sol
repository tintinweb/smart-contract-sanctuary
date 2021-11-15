pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlayerMarketplace is Ownable {
    using SafeMath for uint256;

    bytes32 public MarketplaceStatus;

    struct Auction {
        uint256 price;
        IERC20 paymentToken;
        IERC721 nft;
        uint256 startBlock;
        uint256 endBlock;
        uint256 hoursToExpire;
        bool buyOutOnly;
        bytes32 status; // Active, Inactive, Pending
        uint256 tokenID;
        uint256 minimumBidAmount;
        address createdBy;
        address highestBidder;
        uint256 highestBidAmount;
        uint256 biddingFeePaid;
    }

    struct Fees {
        uint256 listingFeePercentage;
        uint256 listingDailyFeePercentage;
        uint256 biddingFeePercentage;
        uint256 auctionCreatorBiddingFeePercentage;
    }

    Fees public fees;

    address[] public acceptablePaymentTokens;
    address[] public acceptableNFTs;

    Auction[] public auctions;

    address public feeAddress;
    uint256 public maximumListingDuration = 10 days;
    uint256 public minimumListingDuration = 1 days;

    event NFTAdded(address indexed nftAddress);
    event TokenAdded(address indexed tokenAddress);
    event BidReceived(address indexed bidder, uint256 indexed auctionID, uint256 bidAmount);
    event BuyOut(address indexed buyer, uint256 indexed auctionID, uint256 amount);
    event AuctionCancelled(uint256 indexed auctionID);
    event AuctionFinalized(address indexed buyer, uint256 indexed auctionID, uint256 time);
    event CreateAuction(address indexed _creator, address indexed _paymentToken, uint256 _price, address indexed _nft, uint256 _endBlock, uint256 id, bool buyOutOnly, uint256 minimumBidAmount);

    constructor(address fee, uint256 _listingfeePercentage, uint256 _biddingFeePercentage, uint256 _listingDailyFeePercentage, uint256 _auctionCreatorBiddingFeePercentage) public {
        MarketplaceStatus = "Active";
        feeAddress = fee;
        fees = Fees(
            {
                listingDailyFeePercentage : _listingDailyFeePercentage,
                listingFeePercentage : _listingfeePercentage,
                biddingFeePercentage : _biddingFeePercentage,
                auctionCreatorBiddingFeePercentage : _auctionCreatorBiddingFeePercentage
            }
        );
    }

    function createAuction(address paymentTokenAddress, uint256 _price, address nftAddress, uint256 _durationBlocks, uint256 tokenID, bool _buyOutOnly, uint256 _minimumBidAmount) external {
        require(MarketplaceStatus == "Active", "createAuction: Marketplace is not active");
        require(_durationBlocks <= maximumListingDuration, "createAuction: Cannot create auctions for longer than maximum listing time.");
        require(_durationBlocks >= minimumListingDuration, "createAuction: Cannot create auctions for shorter than minimum listing time.");
        require(isAcceptablePaymentToken(paymentTokenAddress) == true, "createAuction: Payment token is not acceptable.");
        require(isAcceptableNFT(nftAddress) == true, "createAuction: NFT is not acceptable.");
        IERC721 pNft = IERC721(nftAddress);
        require(pNft.balanceOf(msg.sender) >= 1, "createAuction: User does not own the nft they are trying to list.");
        require(pNft.ownerOf(tokenID) == msg.sender, "createAuction: User does not own the given nft with id");
        IERC20 pToken = IERC20(paymentTokenAddress);
        uint256 _id = auctions.length;
        uint256 _feeAmount = getListingFee(_price, _durationBlocks);
        require(pToken.balanceOf(msg.sender) >= _feeAmount, "createAuction: User does not have enough balance to pay the listing fee.");
        pToken.transferFrom(msg.sender, feeAddress, _feeAmount);
        pNft.transferFrom(msg.sender, address(this), tokenID);
        uint256 _startBlock = block.timestamp;
        uint256 _endblock =  _startBlock + _durationBlocks;
        auctions.push(Auction({
            startBlock : _startBlock,
            createdBy : msg.sender,
            status : "Active",
            paymentToken : pToken,
            nft : pNft,
            hoursToExpire : _durationBlocks.div(1 hours),
            price : _price,
            tokenID : tokenID,
            buyOutOnly : _buyOutOnly,
            highestBidAmount : 0,
            minimumBidAmount : _minimumBidAmount,
            highestBidder : address(0),
            endBlock : _endblock,
            biddingFeePaid : 0
        }));
        emit CreateAuction(msg.sender, paymentTokenAddress, _price, nftAddress, _endblock, _id, _buyOutOnly, _minimumBidAmount);
    }

    function bid(uint256 auctionID, uint256 amount) external {
        require(MarketplaceStatus == "Active", "bid: Marketplace is not active");
        Auction storage auction = auctions[auctionID];
        require(auction.status == "Active", "bid: Requested auction is not active");
        require(auction.endBlock >= block.timestamp, "bid: Listing has expired.");
        require(auction.createdBy != msg.sender, "bid: Auction creator cannot bid on their own listing");
        require(auction.buyOutOnly == false, "bid: Requested listing is only for buy-outs.");
        require(auction.highestBidAmount < amount, "bid: There is already a higher bid on this listing.");
        require(auction.minimumBidAmount <= amount, "bid: Given bid amount is below the minimum amount specified by lister");
        uint256 biddingFee = getBiddingFee(amount);
        require(auction.paymentToken.balanceOf(msg.sender) >= amount.add(biddingFee), "bid: Bidder does not have enough tokens to bid on this listing.");
        uint256 previousHighestBidAmount = auction.highestBidAmount;
        address previousHighestBidder = auction.highestBidder;
        if(previousHighestBidder != address(0)) // If there is a bidder, return their tokens before receiving the new bid
        {
            auction.paymentToken.transfer(previousHighestBidder, previousHighestBidAmount);
        }
        uint256 creatorBiddingReturn = biddingFee.mul(fees.auctionCreatorBiddingFeePercentage).div(10000);
        auction.paymentToken.transferFrom(msg.sender, feeAddress, biddingFee.sub(creatorBiddingReturn));
        auction.paymentToken.transferFrom(msg.sender, auction.createdBy, creatorBiddingReturn);
        auction.paymentToken.transferFrom(msg.sender, address(this), amount);
        auctions[auctionID].highestBidAmount = amount;
        auctions[auctionID].highestBidder = msg.sender;
        auctions[auctionID].biddingFeePaid = biddingFee;
        emit BidReceived(msg.sender, auctionID, amount);
    }

    function buyOut(uint256 auctionID) external {
        require(MarketplaceStatus == "Active", "buyOut: Marketplace is not active");
        Auction storage auction = auctions[auctionID];
        require(auction.endBlock >= block.timestamp, "buyOut: Listing has expired.");
        require(auction.status == "Active", "buyOut: Listing is not active.");
        require(auction.paymentToken.balanceOf(msg.sender) >= auction.price, "buyOut: Buyer does not have enough tokens to buy this item.");
        auction.paymentToken.transferFrom(msg.sender, auction.createdBy, auction.price);
        auction.nft.safeTransferFrom(address(this), msg.sender, auction.tokenID);
        auctions[auctionID].status = "Bought Out";
        emit BuyOut(msg.sender, auctionID, auction.price);
    }

    function finalizeAuction(uint256 auctionID) external {
        require(MarketplaceStatus == "Active", "finalizeAuction: Marketplace is not active.");
        Auction storage auction = auctions[auctionID];
        require(auction.createdBy == msg.sender || auction.highestBidder == msg.sender, "finalizeAuction: Not authorized.");
        require(auction.endBlock < block.timestamp, "finalizeAuction: Listing did not expire yet.");
        if(auction.highestBidder != address(0))
        {
            auction.nft.safeTransferFrom(address(this), auction.highestBidder, auction.tokenID);
            auction.paymentToken.transfer(auction.createdBy, auction.highestBidAmount);
        }
        else
        {
            auction.nft.safeTransferFrom(address(this), auction.createdBy, auction.tokenID);
        }
        auctions[auctionID].status = "Finished";
        emit AuctionFinalized(msg.sender, auctionID, block.timestamp);
    }

    function cancelAuction(uint256 auctionID) external {
        require(MarketplaceStatus == "Active", "cancelAuction: Marketplace is not active.");
        Auction storage auction = auctions[auctionID];
        require(auction.createdBy == msg.sender, "cancelAuction: Not authorized.");
        require(auction.endBlock >= block.timestamp, "cancelAuction: Listing has already expired.");
        require(auction.status == "Active", "cancelAuction: Listing is not active.");
        if(auction.highestBidder != address(0))
        {
            auction.paymentToken.transfer(auction.highestBidder, auction.highestBidAmount);
            auction.paymentToken.transferFrom(auction.createdBy, auction.highestBidder, auction.biddingFeePaid);
        }
        auction.nft.safeTransferFrom(address(this), auction.createdBy, auction.tokenID);
        auctions[auctionID].status = "Cancelled";
        emit AuctionCancelled(auctionID);
    }

    function setListingFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(fees.listingFeePercentage != _feePercentage, "setListingFeePercentage: Already set.");
        fees.listingFeePercentage = _feePercentage;
    }
    
    function setListingDailyFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(fees.listingDailyFeePercentage != _feePercentage, "setListingDailyFeePercentage: Already set.");
        fees.listingDailyFeePercentage = _feePercentage;
    }

    function setBiddingFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(fees.biddingFeePercentage != _feePercentage, "setBiddingFeePercentage: Already set.");
        fees.biddingFeePercentage = _feePercentage;
    }
    function setAuctionCreatorBiddingFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(fees.auctionCreatorBiddingFeePercentage != _feePercentage, "setAuctionCreatorBiddingFeePercentage: Already set.");
        fees.auctionCreatorBiddingFeePercentage = _feePercentage;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "setFeeAddress: Not good");
        require(feeAddress != _feeAddress, "setFeeAddress: Already set.");
        feeAddress = _feeAddress;
    }

    function getAuctionsLength() external view returns(uint256){
        return auctions.length;
    }
    
    function getAcceptableNFTsLength() external view returns(uint256){
        return acceptableNFTs.length;
    }

    function getAcceptablePaymentTokensLength() external view returns(uint256){
        return acceptablePaymentTokens.length;
    }
    
    function setAcceptablePaymentToken(address addr) external onlyOwner {
        require(addr != address(0), "setAcceptablePaymentToken: Not good");
        require(isAcceptablePaymentToken(addr) == false, "setAcceptablePaymentToken: Already added to the acceptable token list.");
        acceptablePaymentTokens.push(addr);
        emit TokenAdded(addr);
    }

    function isAcceptablePaymentToken(address addr) public view returns(bool){
        for (uint256 i = 0; i < acceptablePaymentTokens.length; i++)
        {
            if(acceptablePaymentTokens[i] == addr)
            {
                return true;
            }
        }
        return false;
    }

    function setMaximumListingDuration(uint256 duration) external onlyOwner {
        require(maximumListingDuration != duration, "setMaximumListingDuration: Duration already set.");
        maximumListingDuration = duration;
    }

    function setMinimumListingDuration(uint256 duration) external onlyOwner {
        require(minimumListingDuration != duration, "setMinimumListingDuration: Duration already set.");
        minimumListingDuration = duration;
    }

    function setAcceptableNFT(address addr) external onlyOwner {
        require(addr != address(0), "setAcceptablePaymentToken: Not good");
        require(isAcceptableNFT(addr) == false, "setAcceptablePaymentToken: Already added to the acceptable token list.");
        acceptableNFTs.push(addr);
        emit NFTAdded(addr);
    }

    function getListingFee(uint256 price, uint256 durationBlocks) public view returns(uint256) {
        return price.mul(fees.listingFeePercentage.add(fees.listingDailyFeePercentage.mul(durationBlocks).div(1 days))).div(10000);
    }

    function getBiddingFee(uint256 price) public view returns(uint256) {
        return price.mul(fees.biddingFeePercentage).div(10000);
    }

    function isAcceptableNFT(address addr) public view returns(bool){
        for (uint256 i = 0; i < acceptableNFTs.length; i++)
        {
            if(acceptableNFTs[i] == addr)
            {
                return true;
            }
        }
        return false;
    }
    
    function activateMarketplace() external onlyOwner {
        require(MarketplaceStatus != "Active", "activateMarketplace: Already active");
        MarketplaceStatus = "Active";
    }
    
    function deactivateMarketplace() external onlyOwner {
        require(MarketplaceStatus != "Inactive", "deactivateMarketplace: Already deactivated");
        MarketplaceStatus = "Inactive";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

