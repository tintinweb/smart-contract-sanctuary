pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IAgERC721.sol";
import './base/BaseAuction.sol';
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title fixed auction
/// @author yzbbanban
/// @notice buy token
/// @dev 
contract FixedAuction is BaseAuction, Pausable, ReentrancyGuard{
    event Auction(uint256 indexed _auctionId, address _token, 
                    uint256 _tokenId, address _seller, 
                    uint256 _openingBid, uint256 _fixedPrice,uint32 _auctionStatus);
    event ReAuction(uint256 indexed _auctionId,
                    uint256 _openingBid, uint256 _fixedPrice,uint32 _auctionStatus);
    event LastParam(uint256 _limitTime, uint256 _extendTime, uint256 _reverseTime);
    event Bid(uint256 indexed _auctionId, address _bidder,
                uint256 _bidPrice, uint256 _bidCount,uint256 _startTime, uint256 _expirationTime,uint32 _auctionStatus);
    event Selling(uint256 indexed _auctionId, address _bidder, uint256 _bidPrice, uint32 _auctionStatus, uint256 _bidCount);
    event Reverse(uint256 indexed _auctionId, address _bidder, uint256 _bidPrice, uint32 _auctionStatus, uint256 _bidCount);
    event Fixed(uint256 indexed _auctionId, address _bidder, uint256 _bidPrice, uint32 _auctionStatus, uint256 _bidCount);
    event Cancel(uint256 indexed _auctionId, address _seller,uint256 _bidPrice, uint32 _auctionStatus, uint256 _bidCount);

    using Counters for Counters.Counter;
    Counters.Counter private _auctionIds;
    using SafeMath for uint256;

    mapping(uint256 => BidInfo) public bidInfos;
    uint256 public limitTime = 1 days;
    uint256 public extendTime = 15 minutes;
    uint256 public reverseTime = 5 days;
    
    constructor(IAgERC721 _artGee, address _platform) public{
        artGee = _artGee;
        platform = _platform;
    }

    struct BidInfo{
        address token;
        uint256 tokenId;
        address seller;
        address bidder;//change
        uint256 openingBid;
        uint256 fixedPrice;
        uint256 bidPrice;//change
        uint256 bidCount;//change
        uint256 startTime;
        uint32 auctionStatus;// 0 init; 1 bid; 2 bidder reverse;3 seller finish; 4 bidder finish 5 seller cancel
        uint256 expirationTime;//change
    }

    function setReverseTime(uint256 _limitTime,uint256 _extendTime, uint256 _reverseTime) public onlyOwner(){
        emit LastParam(limitTime, extendTime, reverseTime);
        if(_limitTime != 0){
            limitTime = _limitTime;
        }
        if(_extendTime != 0){
            extendTime = _extendTime;
        }
        if(_reverseTime != 0){
            reverseTime = _reverseTime;
        }
    }

    function auction(address _token, uint256 _tokenId, 
                    uint256 _openingBid,
                    uint256 _fixedPrice) public nonReentrant whenNotPaused{
        require(_openingBid < _fixedPrice,"Opening bid price must lower than fixedPrice");
        _auctionIds.increment();
        uint256 auctionId = _auctionIds.current();
        BidInfo storage bidInfo = bidInfos[auctionId];
        bidInfo.token = _token;
        bidInfo.tokenId = _tokenId;
        bidInfo.seller = msg.sender;
        bidInfo.openingBid = _openingBid;
        bidInfo.fixedPrice = _fixedPrice;
         _initAuction(bidInfo);
        //add tokenId
        IERC721 ierc721 = IERC721(_token);
        ierc721.safeTransferFrom(msg.sender, address(this), _tokenId);
        // add my auction
        _addMyAuction(msg.sender,auctionId);
        artList.push(auctionId);
        emit Auction(auctionId,_token, _tokenId, msg.sender, _openingBid,_fixedPrice, 0);
    }

    function reAuction(uint256 _auctionId, uint256 _openingBid, 
                    uint256 _fixedPrice) public nonReentrant whenNotPaused{
        require(_openingBid < _fixedPrice,"Opening bid price must lower than fixedPrice");
        BidInfo storage bidInfo = bidInfos[_auctionId];
        require(bidInfo.token != address(0),"Bid not exist");
        uint32 nowStatus = bidInfo.auctionStatus;
        require(nowStatus != 5,"Seller has been canceled");
        require(nowStatus != 3 || nowStatus != 4,"Auction success");
        //must wait for auction over
        require(bidInfo.seller == msg.sender,"Not auction id seller");
        //bidder has already reverse
        if(nowStatus == 1){
            require(block.timestamp > bidInfo.expirationTime, "Auction not over");
            //sende coin to bidder
            transferMain(bidInfo.bidder, bidInfo.bidPrice);
            //remove bidder's auctionId
            _removeMyAuction(bidInfo.bidder, _auctionId);
        }
        bidInfo.seller = msg.sender;
        bidInfo.openingBid = _openingBid;
        bidInfo.fixedPrice = _fixedPrice;
        _initAuction(bidInfo);
        emit ReAuction(_auctionId, _openingBid, _fixedPrice, 0);
    }

    function bid(uint256 _auctionId) payable public nonReentrant whenNotPaused{
        BidInfo storage bidInfo = bidInfos[_auctionId];
        require(bidInfo.token != address(0),"Bid not exist");
        require(block.timestamp >= bidInfo.startTime,"Auction not start");
        //now time > expiration time then auction over
        require(bidInfo.auctionStatus == 0 || bidInfo.auctionStatus == 1, "Not on auction");
        require(msg.sender != bidInfo.seller, "Seller can not bid");
        require(msg.sender != bidInfo.bidder, "Bidder can not repeat bid");
        uint256 t = block.timestamp;
        uint256 nowBidPrice = msg.value;
        //transfer to last bidder
        if(bidInfo.bidCount != 0){
            require(block.timestamp <= bidInfo.expirationTime, "Auction over");
            transferMain(bidInfo.bidder, bidInfo.bidPrice);
            require(nowBidPrice > bidInfo.bidPrice, "Value error");
            // expiration time - (startTime + 1day) => update expiration
            if(bidInfo.expirationTime.sub(block.timestamp) <= extendTime){
                bidInfo.expirationTime = block.timestamp.add(extendTime);
            }
        }else{
            require(nowBidPrice >= bidInfo.openingBid, "Value error");
            bidInfo.startTime = t;
            //1 day later
            bidInfo.expirationTime = t.add(limitTime);
        }
        require(msg.value < bidInfo.fixedPrice, "Over fixed price");
        //update price
        bidInfo.bidPrice = nowBidPrice;
        
        // add bidder auction id and remove seller auction id
        if(bidInfo.bidder != address(0)){
            _removeMyAuction(bidInfo.bidder, _auctionId);
        }
        _addMyAuction(msg.sender,_auctionId);
        //reset bidder
        bidInfo.bidder = msg.sender;
        //add bid count
        bidInfo.auctionStatus = 1;
        bidInfo.bidCount = bidInfo.bidCount.add(1);
        emit Bid(_auctionId, msg.sender, nowBidPrice, bidInfo.bidCount,t,bidInfo.expirationTime, 1);
    }

    function getCurrentPrice(uint256 _auctionId) view public returns(uint256 _nowBidPrice){
        BidInfo memory bidInfo = bidInfos[_auctionId];
        return bidInfo.bidPrice;
    }
    
    //seller cancel
    function cancel(uint256 _auctionId) public nonReentrant whenNotPaused{
        BidInfo storage bidInfo = bidInfos[_auctionId];
        require(bidInfo.token != address(0),"Bid not exist");
        require(bidInfo.seller == msg.sender,"Not auction id seller");
        uint32 nowStatus = bidInfo.auctionStatus;
        require(nowStatus == 0 || nowStatus == 1 || nowStatus == 2, "Auction cancel or success");
        uint256 refund = 0;
        if(nowStatus == 1){
            // must end
            require(bidInfo.expirationTime < block.timestamp, "On auction");
            refund = bidInfo.bidPrice;
            //has bid send coin to bidder
            transferMain(bidInfo.bidder, bidInfo.bidPrice);
            //remove seller list
            _removeMyAuction(bidInfo.seller, _auctionId);
            //remove bidder list
            _removeMyAuction(bidInfo.bidder, _auctionId);
        }
        IERC721 ierc721 = IERC721(bidInfo.token);
        ierc721.safeTransferFrom(address(this),msg.sender, bidInfo.tokenId);
        bidInfo.auctionStatus = 5;
        emit Cancel(_auctionId, bidInfo.seller, refund, 5, bidInfo.bidCount);
    }

    //seller executor
    function sellingSettlementPrice(uint256 _auctionId) public nonReentrant whenNotPaused{
        BidInfo storage bidInfo = bidInfos[_auctionId];
        require(bidInfo.token != address(0),"Bid not exist");
        require(msg.sender == bidInfo.seller, "Not seller");
        require(bidInfo.auctionStatus == 1, "Not on bid");
        bidInfo.auctionStatus = 3;
        uint256 amount = _share(_auctionId,bidInfo,bidInfo.bidPrice);
        emit Selling(_auctionId,bidInfo.bidder,amount,3,bidInfo.bidCount);
    }

    //bidder execute
    function bidderReverse(uint256 _auctionId) public nonReentrant whenNotPaused{
        BidInfo storage bidInfo = bidInfos[_auctionId];
        require(bidInfo.token != address(0),"Bid not exist");
        require(msg.sender == bidInfo.bidder, "Not bidder");
        // if bidder wanner his coin, current time must over than `reverseTime`
        require(bidInfo.auctionStatus == 1, "Reverse must on bid");
        require(bidInfo.expirationTime.add(reverseTime) <= block.timestamp, "Not over reverse time");
        //coin send to bidder
        transferMain(msg.sender, bidInfo.bidPrice);
        bidInfo.auctionStatus = 2;
        _removeMyAuction(bidInfo.bidder, _auctionId);
        emit Reverse(_auctionId, bidInfo.bidder, bidInfo.bidPrice,2,bidInfo.bidCount);
    }

    //auction success bidder execute
    function fixedWithdraw(uint256 _auctionId) payable public nonReentrant whenNotPaused{
        BidInfo storage bidInfo = bidInfos[_auctionId];
        require(bidInfo.token != address(0),"Bid not exist");
        require(bidInfo.auctionStatus == 1 || bidInfo.auctionStatus == 0, "Withdraw not on bid or on sell");
        if(bidInfo.bidCount != 0){
            require(bidInfo.expirationTime >= block.timestamp, "Not on auction");
        }
        if(bidInfo.auctionStatus == 1){
            //send to last bidder
            transferMain(bidInfo.bidder, bidInfo.bidPrice);
        }
        require(bidInfo.fixedPrice == msg.value,"Not fixed price");
        bidInfo.auctionStatus = 4;
        bidInfo.bidPrice = bidInfo.fixedPrice;
        uint256 amount = _share(_auctionId,bidInfo,bidInfo.fixedPrice);
        // to seller
        bidInfo.bidder = msg.sender;
        emit Fixed(_auctionId,bidInfo.bidder,amount,4,bidInfo.bidCount);
    }

    function setPaused() public onlyOwner(){
        super._pause();
    }

    function setUnpaused() public onlyOwner(){
        super._unpause();
    }

    function _share(uint256 _auctionId, BidInfo storage bidInfo, uint256 _price) internal returns(uint256 _amount){
        uint256 amount = _price;
        //721 transfer current bidder , get bidder price
        IERC721 ierc721 = IERC721(bidInfo.token);
        ierc721.safeTransferFrom(address(this), msg.sender, bidInfo.tokenId);
        //fee to platform
        uint256 _fee = amount.mul(feePercent).div(basePercent);
        uint256 _artistFee = 0; 
        transferMain(platform,_fee);
        //artist share in the benefit 
        if(address(artGee) == bidInfo.token){
            (uint256 artId,,)=artGee.tokenArts(bidInfo.tokenId);
            (,,,address creator,
                address[] memory assistants,
                uint256[] memory benefits,)=artGee.getSourceDigitalArt(artId);
            bool isNotFirst = isNotFirstAuction[bidInfo.token][bidInfo.tokenId];
            //first time 20% to artist,other time 10% 
            _artistFee = amount.mul(isNotFirst ? artPercent[1]:artPercent[0]).div(basePercent);
            if(assistants.length == 0){
                //send to creator
                transferMain(creator,_artistFee);
            }else{
                //send to creator and other assistant
                for (uint256 index = 0; index < benefits.length; index++) {
                    if(index==0){
                        // to creator
                        transferMain(creator,_artistFee.mul(benefits[index]).div(basePercent));
                    }else{
                        // to assistants
                        transferMain(assistants[index-1],_artistFee.mul(benefits[index]).div(basePercent));
                    }
                }
            }
            isNotFirstAuction[bidInfo.token][bidInfo.tokenId] = true;
        }
        transferMain(bidInfo.seller, amount.sub(_fee).sub(_artistFee));
        _removeMyAuction(bidInfo.seller, _auctionId);
        //remove bidder list
        _removeMyAuction(bidInfo.bidder, _auctionId);
        return amount.sub(_fee).sub(_artistFee);
    }

    function _initAuction(BidInfo storage bidInfo) internal {
        bidInfo.bidPrice = 0;
        bidInfo.bidder = address(0);        
        bidInfo.bidCount = 0;
        bidInfo.startTime = 0;
        bidInfo.expirationTime = 0;
        bidInfo.auctionStatus = 0; 
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
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

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAgERC721 is IERC721{

    function tokenArts(uint256 _tokenId) view external returns(
        uint256 artId,
        uint256 edition,
        uint256 totalEdition
    );

    function getSourceDigitalArt(uint256 _artId) view external returns(
                uint256 id,
                uint256 totalEdition,
                uint256 currentEdition,
                address creator,
                address[] memory assistants,
                uint256[] memory benefits,
                string memory uri
    );
}

pragma solidity ^0.6.2;

import "../interfaces/IAgERC721.sol";
import "../owner/Operator.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract BaseAuction is Operator{
    using SafeMath for uint256;
    IAgERC721 public artGee;
    uint256 public feePercent = 100; //10%
    uint256[] public artPercent = [200,100]; //first 20%; other time 10%
    uint256 public basePercent = 1000;
    address public platform;
    mapping(address => mapping(uint256 => bool)) public isNotFirstAuction;
    //my bids 
    mapping(address => uint256[]) public myBidInfos;
    //my => auction id => index
    mapping(address => mapping(uint256 => uint256)) myBidInfoIndex;

    uint256[] public artList;

    function getMyArtList(address _owner) view public returns(uint256[] memory){
        return myBidInfos[_owner];
    }
    
    function getArtList() view public returns(uint256[] memory _artList){
        return artList;
    }

    function setArtgee(IAgERC721 _artGee,address _platform) public onlyOwner(){
        artGee = _artGee;
        platform = _platform;
    }
    function setArtPercent(uint256 _feePercent,uint256[2] memory _artPercents) public onlyOwner(){
        if(_feePercent!=0){
            feePercent = _feePercent;
        }
        artPercent[0] = _artPercents[0];
        artPercent[1] = _artPercents[1];
    }

    function _addMyAuction(address _owner,uint256 _auctionId) internal{
        myBidInfoIndex[_owner][_auctionId] = myBidInfos[_owner].length;
        myBidInfos[_owner].push(_auctionId);
    }

    function _removeMyAuction(address _owner, uint256 _auctionId) internal{
        uint256 lastIndex = myBidInfos[_owner].length.sub(1);
        uint256 currentIndex = myBidInfoIndex[_owner][_auctionId];
        if(lastIndex != currentIndex){
            uint256 lastAuctionId = myBidInfos[_owner][lastIndex];
            myBidInfos[_owner][currentIndex] = lastAuctionId;
            myBidInfoIndex[_owner][lastAuctionId] = currentIndex;
        }
        myBidInfos[_owner].pop();
    }

    function transferMain(address _address, uint256 _value) internal{
        (bool res, ) = address(uint160(_address)).call{value:_value}("");
        require(res,"TRANSFER ETH ERROR");
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive () external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.2;

import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() internal {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(
            _operator == msg.sender,
            'operator: caller is not the operator'
        );
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(
            newOperator_ != address(0),
            'operator: zero address given for new operator'
        );
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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