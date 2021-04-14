// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./derived/OwnableClone.sol";
import "./ISaleable.sol";

contract DutchAuctions is OwnableClone {
    
    struct Listing {
        address tokenAddress;
        uint256 offeringId;
        uint256 startPrice;
        uint256 startTime;
        uint256 endPrice;
        uint256 endTime;
    }

    mapping(uint256 => Listing) public listingsById;
    uint256 internal nextListingId;
    string public name;

    event ListingPurchased( uint256 indexed listingId );
    event ListingAdded(uint256 indexed listingId, address tokenAddress, uint256 offeringId, uint256 startPrice, uint256 startTime, uint256 endPrice, uint256 endTime);
    event ListingUpdated(uint256 indexed listingsById, uint256 startPrice, uint256 startTime, uint256 endPrice, uint256 endTime);
    event ListingRemoved(uint256 indexed listingId);

 	constructor(string memory _name, address _owner) {
        _init(_name, _owner);
    }

    function _init(string memory _name, address _owner) internal {
        name = _name;
        nextListingId = 0;
        transferOwnership(_owner);
    }

    function init(string memory _name, address _owner) public {
        require(owner() == address(0), "already initialized");
        OwnableClone.init(msg.sender);
        _init(_name, _owner);
    }


    function calculateCurrentPrice(uint256 listingId) public view returns (uint256) {
        Listing memory listing = listingsById[listingId];
        uint256 delta = listing.startPrice - listing.endPrice;
 
        uint256 premium = SafeMath.div( SafeMath.mul(delta, listing.endTime - block.timestamp), listing.endTime - listing.startTime );
        return listing.endPrice + premium;
    }

    function bid(uint256 listingId, address _recipient, address payable _changeAddress) public payable {
        Listing memory listing = listingsById[listingId];

        require(listingsById[listingId].tokenAddress != address(0), "No such listing");
        
        uint256 currentPrice = calculateCurrentPrice(listingId);
		require(msg.value >= currentPrice);
        ISaleable(listing.tokenAddress).processSale(listing.offeringId, _recipient);

        if(currentPrice < msg.value) {
            _changeAddress.transfer(msg.value - currentPrice);
        }

        emit ListingPurchased(listingId);
	}

    function addListing(address tokenAddress, uint256 offeringId, uint256 startPrice, uint256 startTime, uint256 endPrice, uint256 endTime) public onlyOwner {
        require (startTime > block.timestamp, "Auction must start in the future");
        require (startTime < endTime, "Auction end must be later than start");
        require (startPrice > endPrice, "Auction must start with a higher price than it ends with");

        uint256 idx = nextListingId++;
        listingsById[idx].tokenAddress = tokenAddress;
        listingsById[idx].offeringId = offeringId;
        listingsById[idx].startPrice = startPrice;
        listingsById[idx].startTime = startTime;
        listingsById[idx].endPrice = endPrice;
        listingsById[idx].endTime = endTime;

        emit ListingAdded(idx, tokenAddress, offeringId, startPrice, startTime, endPrice, endTime);
    }

    function updateListing(uint256 listingId, uint256 startPrice, uint256 startTime, uint256 endPrice, uint256 endTime ) public onlyOwner {
        require(listingsById[listingId].tokenAddress != address(0), "No such listing");
 
        require (listingsById[listingId].startTime > block.timestamp, "Auction has already started");
        require (startTime > block.timestamp, "Auction must start in the future");
        require (startTime > endTime, "Auction end must be later than start");
        require (startPrice > endPrice, "Auction must start with a higher price than it ends with");

        listingsById[listingId].startPrice = startPrice;
        listingsById[listingId].startTime = startTime;
        listingsById[listingId].endPrice = endPrice;
        listingsById[listingId].endTime = endTime;

        emit ListingUpdated(listingId, startPrice, startTime, endPrice, endTime);
    }

    function removeListing(uint256 listingId) public onlyOwner {
        delete(listingsById[listingId]);
        
        emit ListingRemoved(listingId);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ISaleable.sol";

interface ISaleable {
    function processSale( uint256 offeringId, address buyer ) external;
    function getSellersFor( uint256 offeringId ) external view returns ( address [] memory sellers);
 
    event SaleProcessed(address indexed seller, uint256 indexed offeringId, address buyer);
    event SellerAdded(address indexed seller, uint256 indexed offeringId);
    event SellerRemoved(address indexed seller, uint256 indexed offeringId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
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
abstract contract OwnableClone is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function init ( address initialOwner ) internal {
        require(_owner == address(0), "Contract is already initialized");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        init(msgSender);
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
        require(owner() == _msgSender(), "OwnableClone: caller is not the owner");
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}