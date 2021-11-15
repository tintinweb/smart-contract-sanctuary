// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./IMetaStarNFT.sol";
import "./IERC20Mintable.sol";

import "./RandomName.sol";

contract MetaStarAuction is Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event Claimed(address indexed account, uint256 userShare);
    event Received(address indexed account, uint256 amount);
    event EnterBid(address indexed account, uint256 amount);

    event BidCreated(uint256 period, address id, uint256 ts, uint256 amount);
    event BidLinked(uint256 period, address prev, address next);
    event BidRemoved(uint256 period, address id);
    event NewHead(uint256 period, address id);

    event LevelUp(address indexed account, uint256 tokenId, uint256 level);

    uint256 public START;
    mapping(uint256 => uint256) totalProvided;

    mapping(uint256 => mapping(address => uint256)) public provided;

    mapping(uint256 => mapping(address => bool)) public hasClaimed;

    mapping(uint256 => address) heads;

    struct Bid {
        address id;
        address next;
        uint256 ts;
        uint256 amount;
    }

    mapping(uint256 => mapping(address => Bid)) public bids;
    mapping(uint256 => uint256) public averagePrices;

    IERC20 public immutable META;
    IERC20Mintable public immutable POINT;
    IMetaStarNFT public STAR;

    uint256[] nftPriceFirst = [1500, 2000, 2500, 3000];
    uint256[] nftMaxOfferCountFirst = [100, 150, 100, 50];
    // FIXME: only for test
    // uint256[] nftMaxOfferCountFirst = [10, 15, 10, 5];
    uint256[] nftPrice = [700, 1200, 1700, 2200];
    uint256[] nftMaxOfferCount = [30, 45, 30, 15];

    uint256[] levelCostPoints = [1000, 2000, 5000, 8000];
    uint256[] levelRewardPoints = [200, 400, 1000, 2000];

    uint256 DURATION = 1 weeks;
    uint256 BID_DURATION = 24 hours;

    uint256 private _nonce;

    // FIXME:only for test
    // uint256 DURATION = 3 minutes;
    // uint256 BID_DURATION = 1 minutes;

    constructor(
        IERC20 _META,
        IERC20Mintable _POINT,
        IMetaStarNFT _STAR
    ) public {
        START = block.timestamp;

        META = IERC20(_META);
        POINT = IERC20Mintable(_POINT);
        STAR = IMetaStarNFT(_STAR);
    }

    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    function enterBid(uint256 _amount) external nonReentrant whenNotPaused {
        uint256 _period = getCurrPeriod();
        uint256 _start = getStart(_period);
        uint256 _end = getEnd(_start);

        require(
            _period != 2 && _period != 3 && _period != 4,
            "The offering has not started yet"
        );
        require(_start <= block.timestamp, "The offering has not started yet");
        require(block.timestamp <= _end, "The offering has already ended");

        address account = _msgSender();

        if (_period > 4) {
            setAveragePrice(_period.sub(1));
        }

        uint256[] memory prices = getPrices(_period);
        require(_amount >= prices[0], "Less than minimum bid");

        uint256 _provided = provided[_period][account];

        totalProvided[_period] = totalProvided[_period].add(_amount);
        provided[_period][account] = provided[_period][account].add(_amount);

        if (_provided > 0) {
            _remove(_period, account);
        }

        _orderInsert(_period, account, _amount);

        META.transferFrom(account, address(this), _amount);

        emit EnterBid(account, _amount);
    }

    function getPrices(uint256 _period) public view returns (uint256[] memory) {
        uint256[] memory price = nftPriceFirst;
        if (_period > 1) {
            uint256 prevPeriod = _period == 3 ? 1 : _period.sub(1);
            price = nftPrice;
            uint256 averagePrice = averagePrices[prevPeriod];

            for (uint256 i = 0; i < price.length; i++) {
                price[i] = averagePrice.div(2).add(price[i].mul(1e18));
            }
        } else {
            for (uint256 i = 0; i < price.length; i++) {
                price[i] = price[i].mul(1e18);
            }
        }

        return price;
    }

    function getAveragePrice(uint256 _period) public view returns (uint256) {
        uint256 _start = getStart(_period);
        uint256 _end = getEnd(_start);
        require(block.timestamp > _end, "Do not end.");
        return averagePrices[_period];
    }

    function setAveragePrice(uint256 _period) public {
        if (averagePrices[_period] > 0) {
            return;
        }
        uint256[] memory offerCounts = _period == 1
            ? nftMaxOfferCountFirst
            : nftMaxOfferCount;
        uint256[] memory prices = getPrices(_period);
        Bid memory currObject = bids[_period][heads[_period]];
        uint256 winCount = 1;
        uint256 totalOfferCount = 0;
        for (uint256 i = 0; i < offerCounts.length; i++) {
            totalOfferCount = totalOfferCount.add(offerCounts[i]);
        }
        offerCounts[0] = offerCounts[0].sub(1);

        while (currObject.next != address(0)) {
            currObject = bids[_period][currObject.next];
            uint256 index = prices.length.sub(1);

            for (uint256 i = 0; i < prices.length; i++) {
                if (currObject.amount < prices[i]) {
                    index = i.sub(1);
                    break;
                }
            }
            for (uint256 i = 0; i <= index; i++) {
                if (offerCounts[i] > 0) {
                    offerCounts[i] = offerCounts[i].sub(1);
                    winCount = winCount.add(1);
                    break;
                }
            }

            if (winCount >= totalOfferCount) {
                break;
            }
        }
        offerCounts = _period == 1 ? nftMaxOfferCountFirst : nftMaxOfferCount;
        uint256 _averagePrice = 0;
        uint256 totalMaxOffer = offerCounts[0];
        uint256 tmpTotalMaxOffer = 0;
        for (uint256 i = 1; i < offerCounts.length; i++) {
            if (winCount >= totalMaxOffer.add(offerCounts[i])) {
                totalMaxOffer = totalMaxOffer.add(offerCounts[i]);
            } else {
                break;
            }
        }
        for (uint256 i = 0; i < offerCounts.length; i++) {
            tmpTotalMaxOffer = tmpTotalMaxOffer.add(offerCounts[i]);
            if (winCount <= tmpTotalMaxOffer) {
                break;
            }
            _averagePrice = _averagePrice.add(
                prices[i].mul(offerCounts[i]).div(totalMaxOffer)
            );
        }
        averagePrices[_period] = _averagePrice;
        if (_period == 1) {
            averagePrices[4] = _averagePrice;
        }
    }

    function isWinner(uint256 _period, address user)
        public
        view
        returns (bool)
    {
        uint256[] memory offerCount = _period == 1
            ? nftMaxOfferCountFirst
            : nftMaxOfferCount;
        uint256[] memory tmpOfferCount = offerCount;
        uint256[] memory price = getPrices(_period);
        Bid memory currObject = bids[_period][heads[_period]];
        if (currObject.amount >= price[0]) {
            if (currObject.id == user) {
                return true;
            }
        } else {
            return false;
        }
        offerCount[0] = offerCount[0].sub(1);
        bool win = false;
        uint256 winCount = 1;
        uint256 totalOfferCount = 0;
        for (uint256 i = 0; i < offerCount.length; i++) {
            totalOfferCount = totalOfferCount.add(tmpOfferCount[i]);
        }
        while (currObject.next != address(0)) {
            currObject = bids[_period][currObject.next];
            uint256 index = price.length.sub(1);
            for (uint256 i = 0; i < price.length; i++) {
                if (currObject.amount < price[i]) {
                    index = i.sub(1);
                    break;
                }
            }
            for (uint256 i = 0; i <= index; i++) {
                if (offerCount[i] > 0) {
                    offerCount[i] = offerCount[i].sub(1);
                    winCount = winCount.add(1);
                    if (currObject.id == user) {
                        win = true;
                    }
                    break;
                }
            }
            if (win) {
                break;
            }
            if (winCount >= totalOfferCount) {
                break;
            }
        }

        return win;
    }

    function claim(uint256 _period) external nonReentrant {
        uint256 _start = getStart(_period);
        uint256 _end = getEnd(_start);
        address account = _msgSender();

        require(block.timestamp > _end, "Do not end.");
        require(provided[_period][account] > 0, "No provided.");

        uint256 userShare = provided[_period][account];
        provided[_period][account] = 0;

        setAveragePrice(_period);

        if (isWinner(_period, account)) {
            string memory randomName = RandomName.getRandomName(_nonce++);
            STAR.mint(account, randomName);
            uint256 _averagePrice = getAveragePrice(_period);

            uint256 diff = userShare.sub(_averagePrice);
            if (diff > 0) {
                META.transfer(account, diff);
            }
        } else {
            META.transfer(account, userShare);
        }
        emit Claimed(account, userShare);
    }

    function withdrawProvidedETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawMETA() external onlyOwner {
        META.safeTransfer(owner(), META.balanceOf(address(this)));
    }

    /**
     * @dev Given an Object, denoted by `_id`, returns the id of the Object that points to it, or 0 if `_id` refers to the Head.
     */
    function findPrevId(uint256 _period, address _id)
        public
        view
        virtual
        returns (address)
    {
        if (_id == heads[_period]) return address(0);
        Bid memory prevObject = bids[_period][heads[_period]];
        while (prevObject.next != _id) {
            prevObject = bids[_period][prevObject.next];
        }
        return prevObject.id;
    }

    /**
     * @dev Returns the id for the Tail.
     */
    function findTailId(uint256 _period) public view virtual returns (address) {
        Bid memory oldTailObject = bids[_period][heads[_period]];
        while (oldTailObject.next != address(0)) {
            oldTailObject = bids[_period][oldTailObject.next];
        }
        return oldTailObject.id;
    }

    /**
     * @dev Insert a new Object as the new Head with `_data` in the data field.
     */
    function _addHead(
        uint256 _period,
        address _user,
        uint256 _amount
    ) internal {
        address objectId = _createObject(_period, _user, _amount);
        _link(_period, objectId, heads[_period]);
        _setHead(_period, objectId);
    }

    /**
     * @dev Insert a new Object as the new Tail with `_data` in the data field.
     */
    function _addTail(
        uint256 _period,
        address _user,
        uint256 _amount
    ) internal {
        if (heads[_period] == address(0)) {
            _addHead(_period, _user, _amount);
        } else {
            address oldTailId = findTailId(_period);
            address newTailId = _createObject(_period, _user, _amount);
            _link(_period, oldTailId, newTailId);
        }
    }

    /**
     * @dev Remove the Object denoted by `_id` from the List.
     */
    function _remove(uint256 _period, address _id) internal {
        Bid memory removeObject = bids[_period][_id];
        if (heads[_period] == _id) {
            _setHead(_period, removeObject.next);
        } else {
            address prevObjectId = findPrevId(_period, _id);
            _link(_period, prevObjectId, removeObject.next);
        }
        delete bids[_period][removeObject.id];
        emit BidRemoved(_period, _id);
    }

    /**
     * @dev Insert a new Object after the Object denoted by `_id` with `_data` in the data field.
     */
    function _insertAfter(
        uint256 _period,
        address _prevId,
        address _user,
        uint256 _amount
    ) internal {
        Bid memory prevObject = bids[_period][_prevId];
        address newObjectId = _createObject(_period, _user, _amount);
        _link(_period, newObjectId, prevObject.next);
        _link(_period, prevObject.id, newObjectId);
    }

    /**
     * @dev Insert a new Object before the Object denoted by `_id` with `_data` in the data field.
     */
    function _insertBefore(
        uint256 _period,
        address _nextId,
        address _user,
        uint256 _amount
    ) internal {
        if (_nextId == heads[_period]) {
            _addHead(_period, _user, _amount);
        } else {
            address prevId = findPrevId(_period, _nextId);
            _insertAfter(_period, prevId, _user, _amount);
        }
    }

    function _orderInsert(
        uint256 _period,
        address _user,
        uint256 _amount
    ) internal returns (bool) {
        if (heads[_period] == address(0)) {
            _addHead(_period, _user, _amount);
        } else {
            Bid memory currObject = bids[_period][heads[_period]];
            if (_amount > currObject.amount) {
                _insertBefore(_period, currObject.id, _user, _amount);
                return true;
            }
            while (currObject.next != address(0)) {
                currObject = bids[_period][currObject.next];
                if (_amount > currObject.amount) {
                    _insertBefore(_period, currObject.id, _user, _amount);
                    return true;
                }
            }
            if (currObject.next == address(0)) {
                _insertAfter(_period, currObject.id, _user, _amount);
            }
        }
    }

    /**
     * @dev Internal function to update the Head pointer.
     */
    function _setHead(uint256 _period, address _id) internal {
        heads[_period] = _id;
        emit NewHead(_period, _id);
    }

    /**
     * @dev Internal function to create an unlinked Object.
     */
    function _createObject(
        uint256 _period,
        address _user,
        uint256 _amount
    ) internal returns (address) {
        address newId = _user;
        Bid memory bid = Bid(newId, address(0), block.timestamp, _amount);
        bids[_period][bid.id] = bid;
        emit BidCreated(_period, bid.id, bid.ts, bid.amount);
        return bid.id;
    }

    /**
     * @dev Internal function to link an Object to another.
     */
    function _link(
        uint256 _period,
        address _prevId,
        address _nextId
    ) internal {
        bids[_period][_prevId].next = _nextId;
        emit BidLinked(_period, _prevId, _nextId);
    }

    function getTotalBids(uint256 _period) public view returns (uint256) {
        if (heads[_period] == address(0)) {
            return 0;
        }
        Bid memory currObject = bids[_period][heads[_period]];
        uint256 total = 1;
        while (currObject.next != address(0)) {
            currObject = bids[_period][currObject.next];
            total++;
        }

        return total;
    }

    function getCurrPeriod() public view returns (uint256) {
        return (block.timestamp.sub(START)).div(DURATION).add(1);
    }

    function getStart(uint256 _period) public view returns (uint256) {
        return DURATION.mul(_period.sub(1)).add(START);
    }

    function getEnd(uint256 _start) public view returns (uint256) {
        return _start.add(BID_DURATION);
    }

    function isStarted(uint256 _period) public view returns (bool) {
        return block.timestamp >= getStart(_period);
    }

    function isEnded(uint256 _period) public view returns (bool) {
        return block.timestamp >= getEnd(getStart(_period));
    }

    function levelUp(uint256 tokenId) public nonReentrant {
        require(
            STAR.ownerOf(tokenId) == msg.sender,
            "You don't own this token."
        );
        address account = _msgSender();

        (, uint256 level, ) = STAR.getStar(tokenId);
        STAR.levelUp(tokenId);

        uint256 amount = levelCostPoints[level] * 1e18;

        POINT.transferFrom(account, address(this), amount);
        emit LevelUp(account, tokenId, level.add(1));
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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMetaStarNFT is IERC721 {
    function mint(address to, string memory name) external;

    function getStar(uint256 tokenId)
        external
        view
        returns (
            string memory,
            uint256,
            uint256
        );

    function levelUp(uint256 tokenId) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IERC20Mintable {
    function addMinter(address account) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function isMinter(address account) external view returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function renounceMinter() external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/math/SafeMath.sol";

library RandomName {
    using SafeMath for uint256;

    function getRandomName(uint256 _nonce) public view returns (string memory) {
        string[26] memory letter = [
            "A",
            "B",
            "C",
            "D",
            "E",
            "F",
            "G",
            "H",
            "I",
            "G",
            "K",
            "L",
            "M",
            "N",
            "O",
            "P",
            "Q",
            "R",
            "S",
            "T",
            "U",
            "V",
            "W",
            "X",
            "Y",
            "Z"
        ];
        string[10] memory str;
        _nonce++;

        str[0] = letter[getRandomNumber(_nonce, 26)];
        _nonce++;

        str[1] = letter[getRandomNumber(_nonce, 26)];
        for (uint256 i = 2; i < 7; i++) {
            _nonce++;

            str[i] = uint2str(getRandomNumber(_nonce, 10));
        }

        return strConcat(str);
    }

    function getRandomNumber(uint256 _nonce, uint8 count)
        internal
        view
        returns (uint256)
    {
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, _nonce))
        ) % count;
        return randomNumber;
    }

    function strConcat(string[10] memory str)
        internal
        pure
        returns (string memory)
    {
        uint256 k = 0;
        uint256 len = 0;
        for (uint256 i = 0; i < str.length; i++) {
            bytes memory _b = bytes(str[i]);
            len = len.add(_b.length);
        }
        string memory ret = new string(len);
        bytes memory bret = bytes(ret);

        for (uint256 i = 0; i < str.length; i++) {
            bytes memory _b2 = bytes(str[i]);
            for (uint256 j = 0; j < _b2.length; j++) bret[k++] = _b2[j];
        }
        return string(ret);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

