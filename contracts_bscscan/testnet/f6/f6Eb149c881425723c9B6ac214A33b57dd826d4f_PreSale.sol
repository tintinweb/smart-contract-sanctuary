// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface Token {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function approve(address _to, uint256 _value) external returns (bool);
}

contract PreSale is Ownable {
	
	using SafeMath for uint256;

	using Strings for *;

	using Arrays for uint256[];

	enum ProductLaunchState {
		None,
		Launch
	}

	struct Buyer {

		uint weight;  // PreSale amount
		uint lasttime; // PreSale time
		uint pretime; // Prev presale time
		uint amount;  // PreSale price
		bool attend; // if true, the guys are join presale

	}

	struct Stock {

		uint boxId; // Blind box Id
		uint price; // Blind box price
		uint number; // Blind box number

	}


	// Pre sale total price
	uint256 public totalPreSalePrice;

	// Blind box product list 
	mapping(uint => Stock) public stock;

	Stock[] public stocks;


	mapping(uint => mapping(address=> Buyer)) public Player;

	address payable[] public PlayerAddress;

	// Blind box pre sale consume billboard
	mapping(address => uint) public Billboard;

	// Product launch time
	uint public releaseTime;

	// Pre sale time
	uint public preSaleTime;

	// product number
	uint public productNum=0;

	// presale number
	uint public presaleNum=0;

	// Product launch state
	ProductLaunchState public state; 

	// administrators
	address public maker;

	address public BlindBoxContract;
  
  	Token private BUSDToken;

	event addProduct(address indexed from, uint num);
	event offRackBlindBox(address indexed from);
	event buyBlindBox(address indexed from,uint boxId, uint num);
	event Refund(address indexed from, uint boxId);
	event extractionBlindBox(address indexed from, uint boxId);
	event setContract(address sender,address to);
	event LaunchGame(uint total, ProductLaunchState state);

	constructor(Token usdt_, uint presaletime, uint time) {
		 maker = msg.sender;
		 BUSDToken =  usdt_;
		 releaseTime = time;
		 preSaleTime = presaletime;
	}
	// Set Token 
	function setToken(Token usdt) public virtual returns(bool) {
		BUSDToken = usdt;
	}

	// Add PreSale product
	function AddProduct(uint[] calldata _boxId,uint[] calldata _price, uint[] calldata _number) public returns (bool) {
		require(address(maker) == address(msg.sender), "Only maker can Add Product");
		require(_boxId.length == _price.length && _price.length == _number.length, "Data parameter length error");

		for(uint256 i=0;i< _price.length; i=i.add(1)) {
			uint boxId = _boxId[i];
			Stock memory productInfo = Stock(boxId, _price[i], _number[i]);
			stocks.push(Stock(_boxId[i], _price[i], _number[i]));
			stock[boxId] = productInfo;
			productNum = productNum.add(1);
		}

		emit addProduct(msg.sender, _price.length);
	}
	// blind box off rack
	function OffRackBlindBox(uint boxId_) public returns (bool) {
		require(address(maker) == address(msg.sender), "Only maker can off rack blind box");
		Stock memory stockss = stock[boxId_];
		require(stockss.boxId > 0, "The specified blind box ID does not exist");
		delete stock[boxId_];
		delete stocks[boxId_];
		productNum = productNum.sub(1);
		emit offRackBlindBox(msg.sender);
	}

	// Buy pre sale blind box
	function BuyBlindBox(uint boxId_, uint num_) public payable virtual returns (bool) {
		require(preSaleTime <= block.timestamp, "The pre-sale time has not arrived yet");
		require(stock[boxId_].number > 0, "The specified blind box ID does not exists");
		require(num_ > 0, "Purchase quantity must be greater than 0");
		require(stock[boxId_].number >= num_, "The specified blind box is out of stock");

		// calculate price
		uint price = stock[boxId_].price.mul(1e18).mul(num_);

		BUSDToken.approve(address(this), price);

		require(BUSDToken.transferFrom(msg.sender, address(this), price), "transferFrom call fail");

		// update total presale price 
		totalPreSalePrice = totalPreSalePrice.add(price);
		if(!Player[boxId_][msg.sender].attend){
			PlayerAddress.push(payable(msg.sender));
		}
		// update Player info
		Buyer storage buyer = Player[boxId_][msg.sender];
					buyer.weight = buyer.weight.add(num_);
					buyer.pretime = buyer.lasttime;
					buyer.lasttime = block.timestamp;
					buyer.amount = buyer.amount.add(price);
					buyer.attend = true;

		presaleNum = presaleNum.add(num_);
		for(uint i=0; i < stocks.length;i=i.add(1)) {
			if(stocks[i].boxId == boxId_){
				stocks[i].number.sub(num_);
			}
		}
		stock[boxId_].number.sub(num_);
		// Update Billboard
		Billboard[msg.sender].add(price);
		emit buyBlindBox(msg.sender, boxId_, num_);
	}

	// Return advance collection
	function refund(uint boxId_) public virtual returns (bool) {
		require(Player[boxId_][msg.sender].attend, "Not participating in pre-sale or refunded");
		require(block.timestamp >= releaseTime, "It's not time for the product to go online");
		require(state == ProductLaunchState.None, "The product is online and cannot be returned");

		Buyer storage buyer = Player[boxId_][msg.sender];
		require(buyer.attend, "sender Not a pre-sale address");
		require(BUSDToken.transfer(msg.sender, buyer.amount));

		BUSDToken.transfer(msg.sender, buyer.amount);
		buyer.attend = false;
		presaleNum = presaleNum.sub(1);

		for(uint i=0; i < stocks.length;i=i.add(1)) {
			if(stocks[i].boxId == boxId_){
				stocks[i].number.add(buyer.weight);
			}
		}
		stock[boxId_].number.add(buyer.weight);
		Billboard[msg.sender].sub(buyer.amount);
		emit Refund(msg.sender, boxId_);
	}

	// Blind box lottery
	function ExtractionBlindBox(address sender, uint boxId_) public virtual returns(bool) {
		require(address(msg.sender) == address(BlindBoxContract), "Only BlindBoxContract can ExtractionBlindBox");
		require(state == ProductLaunchState.Launch, "Product not online");
		Buyer storage buyer = Player[boxId_][sender];
		require(buyer.attend, "sender Not a pre-sale address");
		require(buyer.weight > 0, "sender No pre-sale quota");

		buyer.weight = buyer.weight.sub(1);
		if(buyer.weight == 0) {
			buyer.attend = false;
		}
		emit extractionBlindBox(sender, boxId_);
	}

	// Game product Launch withdrawal of funds
	function LaunchWithdrawal() public virtual returns(bool) {
		require(address(msg.sender)== address(maker), "Only maker can LaunchWithdrawal");
		state = ProductLaunchState.Launch;
		require(BUSDToken.transfer(msg.sender, totalPreSalePrice));
		emit LaunchGame(totalPreSalePrice, state);
	}
	function isContract(address addr) public virtual returns (bool) {
	    uint size;
	    assembly { size := extcodesize(addr) }
	    return size > 0;
  	}
	// Product launch
	function SetBlindBoxContract(address BoxContract_) public virtual returns (bool) {
		require(address(msg.sender) == address(maker), "Only maker can SetBlindBoxContract");
		require(BoxContract_ != address(0), "BoxContract can't be zero");
		require(isContract(BoxContract_), "This address is not a contract address");
		BlindBoxContract = BoxContract_;
		emit setContract(msg.sender, BlindBoxContract);
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
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