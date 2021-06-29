// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Auction is Ownable {
    using SafeMath for uint256;
    address payable public serviceWallet;
    uint256 public lotId;

    /**
     * Current auction state. used in requires to revert transaction depending on its state
     */
    enum State {
        Default, //is equal to 0 and assigned to auction automatically after its creation
        Running, //is equal to 1 and assigned to auction after first bed
        Finalized //is equal to 2 and assigned to auction in finalize methods in order to show that auction is totally finalized
    }

    /**
    * Bids struct used to be assigned in array of bids and then output to get all necessary info about bed
    */
    struct Bids {
        address bidder; //the one who placed a bet
        uint256 bidTime; //time of the placed bet
        uint256 amount; //amount of the placed bet
    }

    uint256 timeBeforeAuctionStarts; //time before auction starts (amount of seconds. example: 600 s -> 10 m)
    uint256 beginPrice; //price value (wei)
    uint256 auctionStep; //step value (wei)
    uint256 minTimer; //minimal time (amount of seconds)
    uint256 bidTime; //bid time (amount of seconds)
    address lotAddress; //lot address (address)
    uint256 lotAmount; //amount of tokens to sale (wei)
    State auctionState; //current state
    uint256 highestPrice; //store highest price
    address highestBidder; //store highest bidder address
    mapping(address => uint256) public bids; //save current amount of bet of the user
    Bids[] public bidsHistory; //history of the all bets of the auction

    event EditAuction(uint256 indexed _lotId, uint256 _beginPrice, uint256 _auctionStep, uint256 _minTimer, uint256 _bidTime);
    event PlaceBid(uint256 indexed _lotId, address indexed _user, address indexed _prevHihgestBidder, address _lotAddress, uint256 _amount, uint256 _time);
    event FinalizeAuction(uint256 indexed _lotId, address _winner, uint256 _prize, uint256 _price, address _serviceWallet, uint256 _lotAmount);

    constructor(
        uint256 _lotId,
        uint256 _timeBeforeAuctionStarts,
        uint256 _beginPrice,
        uint256 _auctionStep,
        uint256 _minTimer,
        uint256 _bidTimer,
        address _lotAddress,
        uint256 _lotAmount,
        address payable _serviceWallet) {
        lotId = _lotId;
        timeBeforeAuctionStarts = _timeBeforeAuctionStarts.add(block.timestamp);
        beginPrice = _beginPrice;
        auctionStep = _auctionStep;
        minTimer = _minTimer.add(_timeBeforeAuctionStarts.add(block.timestamp)); //add to minimal time bid time in order to start auction only after time before auction starts runs out
        bidTime = _bidTimer;
        lotAddress = _lotAddress;
        lotAmount = _lotAmount;
        serviceWallet = _serviceWallet;
        transferOwnership(serviceWallet);
    }

    /**
    * Change auction parameters only if it has not been started
    */
    function editAuction(
        uint256 _beginPrice, //begin price (wei)
        uint256 _auctionStep,// auction step (wei)
        uint256 _minTimer, //minimal auction time (amount of seconds)
        uint256 _bidTime, //bid time (amount of seconds)
        address payable _serviceWallet //service wallet (address)
    ) onlyOwner public returns(bool) {
        require(timeBeforeAuctionStarts > block.timestamp, "Auction has been started. You cannot change its parameters anymore");
        beginPrice = _beginPrice;
        auctionStep = _auctionStep;
        minTimer = _minTimer.add(timeBeforeAuctionStarts);
        bidTime = _bidTime;
        if (_serviceWallet != serviceWallet) {
            serviceWallet = _serviceWallet;
            transferOwnership(serviceWallet);
        }
        emit EditAuction(lotId, _beginPrice, _auctionStep, _minTimer, _bidTime);

        return true;
    }

    /**
    * place bet function to register highest price, highest bidder, revert unsupported bets, save user's bets and so on.
    * place necessary price to transfer it to the auction address (wei)
    */
    function placeBid() payable public returns(bool) {
        require(block.timestamp <= minTimer, "Auction already finalized");
        require(block.timestamp >= timeBeforeAuctionStarts, "Auction is not started yet");
        require(msg.value > 0, "You cannot place bid with zero value");
        require(highestBidder != msg.sender, "You cannot outbid yourself");
        uint256 currentBid = bids[msg.sender].add(msg.value);
        require(beginPrice <= currentBid, "Bid price is lower then lot price");
        require(currentBid >= highestPrice.add(auctionStep), "Bid price is lower then highest price");
        bids[msg.sender] = currentBid;
        highestPrice = currentBid;
        address prevHighestBidder = highestBidder;
        highestBidder = msg.sender;
        uint256 previousBetToServiceWalletAmount = address(this).balance.sub(highestPrice);
        if (previousBetToServiceWalletAmount > 0) {
            serviceWallet.transfer(previousBetToServiceWalletAmount);
        }
        minTimer = minTimer.add(bidTime);
        auctionState = State.Running;
        bidsHistory.push(Bids({
            bidder: msg.sender,
            bidTime: block.timestamp,
            amount: address(this).balance
        }));
        emit PlaceBid(lotId, msg.sender, prevHighestBidder, lotAddress, msg.value, block.timestamp);

        return true;
    }

    /**
    * finalize auction function to withdraw reward and transfer price to the auction owner and all previous bets to service wallet
    * revert if state is equal to 2 (Finalized) so can be user ones
    */
    function finalizeAuction() public returns(bool) {
        require(auctionState != State.Finalized, "Auction is totally finalized");
        require(block.timestamp > minTimer, "Auction is not finalized yet");
        require(msg.sender == highestBidder || (msg.sender == owner() &&
        block.timestamp > minTimer.add(48 hours)), "You are not winner or not owner of the auction");

        auctionState = State.Finalized;

        serviceWallet.transfer(highestPrice);
        if (msg.sender != serviceWallet) {
            require(IERC20(lotAddress).transfer(highestBidder, lotAmount), "Lot is not transfered to the winner");
        } else {
            require(IERC20(lotAddress).transfer(serviceWallet, lotAmount), "Lot is not transfered to the owner");
        }
        emit FinalizeAuction(lotId, msg.sender, lotAmount, highestPrice, serviceWallet, lotAmount);

        return true;
    }

    /**
    * Owner can get lot back if nobody placed a bid
    */
    function getLotBack() onlyOwner public returns (bool) {
        require(block.timestamp > minTimer && highestPrice == 0, "You cannot get lot back");
        require(IERC20(lotAddress).transfer(msg.sender, lotAmount), "Lot is not transfered to the owner");
        auctionState = State.Finalized;
        emit FinalizeAuction(lotId, address(0), lotAmount, 0, serviceWallet, 0);

        return true;
    }

    function mainAuctionDetails() public view returns(State, uint256, address, uint256, uint256, Bids[] memory, uint256, uint256, uint256) {
        return (auctionState, highestPrice, highestBidder, minTimer, bidTime, bidsHistory, beginPrice, auctionStep, timeBeforeAuctionStarts);
    }

    function retrieveTokens(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != lotAddress || auctionState == State.Finalized, "You can't retrieve the basic token until auction finalized");

        uint256 amount = IERC20(_tokenAddress).balanceOf(address(this));
        require(amount > 0, "Zero tokens balance");

        require(
            IERC20(_tokenAddress).transfer(owner(), amount),
            "Transfer failed"
        );
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
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "byzantium",
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