// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./INFTToken.sol";

contract NFTAuction is Ownable{
    using SafeMath for uint256;

    INFTToken public token;
    uint256 public bidIncrementPercentage;
    
    struct Auction {
        address owner;
        // The minimum price accepted in an auction
        uint256 minNFTPrice;
        uint256 escrowAmount;
        uint256 start;
        uint256 end;
        bool canceled;
        address winnerAddress;
    }

    struct Bidder{
        address bidderAddr;
        uint256 amount;
    }

    // mapping of token ID to Auction Structure
    mapping (uint256 => Auction) public auction;

    // mapping of token ID to bidder address to bidder's fund
    // mapping (uint256 => mapping (address => uint256)) public fundsByBidder;
    mapping (uint256 => Bidder[]) public auctionBidder;

    event LogAuction(address creator, uint256 tokenID, uint256 startTime, uint256 endTime, bool status);
    event LogBid(uint256 tokenID, address bidder, uint256 amount);
    event LogWithdrawal(uint tokenID, address withdrawalAccount, uint256 amount);
    event LogAuctionWinner(uint tokenID, address winnerAddress);
    event LogCanceled(uint256 tokenID);   // modifier onlyOwner {

    constructor (address _token, uint256 _bidIncrementPercentage) {
        require(_token != address(0), "owner is zero address");
        // require(_minNFTPrice > 0);
        require(_bidIncrementPercentage > 0, "Bid increament should be more then 0%");
        token = INFTToken(_token);
        bidIncrementPercentage = _bidIncrementPercentage; // for 5% => 500
    }

    function createAuction(uint256 _minNFTPrice, uint256 _start, uint256 _end) public onlyOwner returns(uint256 tokenID){

        // mint NFT 
        uint256 _tokenId = token.mint();
     
        // Create NFT bid by contract owner
        auction[_tokenId] = Auction({
            owner: msg.sender,
            minNFTPrice: _minNFTPrice,
            escrowAmount: 0,
            start: _start,
            end: _end,
            canceled: false,
            winnerAddress: address(0)
        });

        emit LogAuction(msg.sender, _tokenId, _start, _end, false);
        return _tokenId;
    }

    function transferNFTToCharity(uint _tokenId, address charityAddress) public onlyOwner{
        cancelAuction(_tokenId);
        //Transfer NFT charity address 
        token.safeTransferFrom(address(this), charityAddress, _tokenId);
    }

    function highestBidAmountInAuction(uint256 _tokenId) internal view returns(address bidderAddr, uint256 amount){
        Bidder[] memory bidder = auctionBidder[_tokenId];
        uint256 _maxAmount;
        for(uint256 i = 0; i < bidder.length; i++){
            if(_maxAmount < bidder[i].amount){
                _maxAmount = bidder[i].amount;
                bidderAddr = bidder[i].bidderAddr;
            }
        } 
        return (bidderAddr, _maxAmount);
    }

     function findUserBidInAuction(uint256 _tokenID, address _bidderAddr) internal view returns(bool isBid, uint index, uint256 amount){
        Bidder[] memory bidder = auctionBidder[_tokenID];
        for(uint256 i = 0; i < bidder.length; i++){
            if(_bidderAddr == bidder[i].bidderAddr){
                return(true, i, bidder[i].amount);
            }
        } 
        return (false, 0, 0);
    }

    function placeBid(uint256 _tokenID) public payable{
        Auction memory _auction = auction[_tokenID];
        
        require(block.timestamp >= _auction.start, "Auction not started yet");
        require(block.timestamp <= _auction.end, 'Auction expired');
        require(msg.sender != _auction.owner, "Owner cannot place bid");
        require(msg.value >= _auction.minNFTPrice, 'Must send at least minimum NFT price');
        (, uint256 amount) = highestBidAmountInAuction(_tokenID);
        require(
            msg.value >= amount + ((amount * bidIncrementPercentage) / 10000),
            'Must send more than last bid by minBidIncrementPercentage amount'
        );

        (bool isBid, uint index, uint256 _amount) = findUserBidInAuction(_tokenID, msg.sender);
        if(isBid){
            payable(msg.sender).transfer(_amount);
            auctionBidder[_tokenID][index].amount = msg.value;
        } else{
            Bidder memory bidder;
            bidder.amount = msg.value;
            bidder.bidderAddr = payable(msg.sender);
            auctionBidder[_tokenID].push(bidder);
        }

        auction[_tokenID].escrowAmount = auction[_tokenID].escrowAmount.add(msg.value);

        emit LogBid(_tokenID, msg.sender, msg.value);
    }

    function cancelAuction(uint _tokenID) public onlyOwner returns (bool success) {
        Auction memory _auction = auction[_tokenID];
        require(_auction.end > block.timestamp, "Auction already completed");
        require(_auction.canceled == false, "Auction already canceled");

        auction[_tokenID].canceled = true;
        emit LogCanceled(_tokenID);
        return true;
    }

    function claim(uint256 _tokenID) public payable {
        Auction memory _auction = auction[_tokenID];
        require(_auction.end < block.timestamp, "Auction still under progress");
        (bool isBid, , uint256 amount) = findUserBidInAuction(_tokenID, msg.sender);
        require(isBid, "You are not a bidder");
        if(_auction.canceled){
            require(_auction.escrowAmount >= amount, "Aunction amount is less");
            payable(msg.sender).transfer(amount);
            emit LogWithdrawal(_tokenID, msg.sender, amount);
        } else {
            (address bidderAddr, uint256 _amount) = highestBidAmountInAuction(_tokenID);
            if(bidderAddr == msg.sender ){
                payable(_auction.owner).transfer(_amount);
                // Transfer NFT to contract
                token.safeTransferFrom(address(this), msg.sender, _tokenID);
                auction[_tokenID].winnerAddress = msg.sender;
                emit LogAuctionWinner(_tokenID, msg.sender);
            } else {
                require(_auction.escrowAmount >= amount, "Aunction amount is less");
                payable(msg.sender).transfer(amount);
                emit LogWithdrawal(_tokenID, msg.sender, amount);
            }
        }
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

interface INFTToken {
    function mint() external returns(uint256 tokenID);
    function balanceOf(address owner) external returns(uint256 balance);
    function safeTransferFrom(address sender, address receiver, uint256 tokenID) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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