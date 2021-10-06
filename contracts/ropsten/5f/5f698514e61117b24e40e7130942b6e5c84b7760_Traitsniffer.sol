/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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


contract Traitsniffer is Ownable {
    uint256 public trialPrice = 15000000000000000;
    uint256 constant private DAY_IN_UNIX = 86400;
    uint256 private trialTimestamp = 3600;
    bool public trialIsActive = false;
    bool public saleIsActive = false;

    mapping (address => bool) private whitelisted;
    mapping (address => uint256) private userToTimeRegistered;
    mapping (address => uint256) private trialToTime;

    address[] private registeredAddresses;
    Subscription[] private subscriptionPlans;

    struct Subscription {
        uint _price;
        uint _days;
    }

    constructor() {
        subscriptionPlans.push(Subscription(250000000000000000,7));
        subscriptionPlans.push(Subscription(400000000000000000,14));
        subscriptionPlans.push(Subscription(600000000000000000,30));
    }

    function register(uint _id) public payable {
        require(msg.value == getPrice(_id), "Incorrect ETH value");
        require(saleIsActive, "Sale not active");
        require(subscriptionPlans[_id]._days > 0, "ID does not exist");
        require(userToTimeRegistered[msg.sender] == 0, "Already registered");
        require(whitelisted[msg.sender] == false, "Already whitelisted");

        registeredAddresses.push(msg.sender);
        userToTimeRegistered[msg.sender] = block.timestamp + (DAY_IN_UNIX * subscriptionPlans[_id]._days);
    }

    function updateSubscription(uint _id) public payable{
        require(msg.value == getPrice(_id), "Incorrect ETH value");
        require(subscriptionPlans[_id]._days > 0, "ID does not exist.");

        uint256 expireTime = userToTimeRegistered[msg.sender];
        uint256 timestamp = block.timestamp;
        require(saleIsActive || expireTime > timestamp, "Max users reached");
        require(expireTime > 1, "User must register first");

        if (expireTime < timestamp) {
            // Previous subscription has expired
            userToTimeRegistered[msg.sender] = timestamp + (DAY_IN_UNIX * subscriptionPlans[_id]._days);
        } else {
            // Still has an active subscription but wants to add time
            userToTimeRegistered[msg.sender] = expireTime + (DAY_IN_UNIX * subscriptionPlans[_id]._days);
        }
    }

    function buyTrial() public payable {
        require(trialIsActive, "Trial buying closed");
        require(msg.value == trialPrice, "Incorrect ETH value");

        trialToTime[msg.sender] = block.timestamp + trialTimestamp;
    }

    function migrateExistingUsers(address[] memory _addresses, uint256[] memory _timestamps) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            registeredAddresses.push(_addresses[i]);
            userToTimeRegistered[_addresses[i]] = _timestamps[i];
        }
    }

    function flipTrialState() external onlyOwner {
        trialIsActive = !trialIsActive;
    }

    function flipSaleState() external onlyOwner {
            saleIsActive = !saleIsActive;
    }

    function isTrial(address _address) external view returns (bool) {
        return trialToTime[_address] > block.timestamp;
    }

    function hasAccess(address _address) external view returns (bool) {
        return userToTimeRegistered[_address] > block.timestamp ||
                whitelisted[_address] == true ||
                trialToTime[_address] > block.timestamp;
    }

    function getTimestamp(address _address) external view returns (uint256) {
        if (whitelisted[_address] == true) {
            return 1;
        } else if (trialToTime[_address] > block.timestamp){
            return trialToTime[_address];
        } else {
            return userToTimeRegistered[_address];
        }
    }

    function getActiveSubCount() public view returns(uint) {
        uint activeSubCount;
        uint256 timestamp = block.timestamp;
        for(uint i = 0; i < registeredAddresses.length; i++) {
            if (userToTimeRegistered[registeredAddresses[i]] > timestamp) {
                activeSubCount++;
            }
        }
        return activeSubCount;
    }

    function getAllSubscribers() external view returns (address[] memory) {
        uint count = getActiveSubCount();
        address [] memory activeUsers = new address[](count);
        uint x;
        uint256 timestamp = block.timestamp;

        for(uint i = 0; i < registeredAddresses.length; i++) {
            address current = registeredAddresses[i];
            if (userToTimeRegistered[current] > timestamp) {
                activeUsers[x++] = current;
            }
        }
        return activeUsers;
    }

    function getWhitelisted() external view returns(address[] memory) {
        uint whitelistedCount;
        for(uint i = 0; i < registeredAddresses.length; i++) {
            if (whitelisted[registeredAddresses[i]] == true) {
                whitelistedCount++;
            }
        }
        uint count = whitelistedCount;
        address[] memory whitelistedUsers = new address[](count);

        uint x;
        for (uint i = 0; i < registeredAddresses.length; i++) {
            address current = registeredAddresses[i];
            if (whitelisted[current] == true) {
                whitelistedUsers[x] = current;
                x++;
            }
        }
        return whitelistedUsers;
    }

    function getPrice(uint _id) public view returns(uint256) {
        return subscriptionPlans[_id]._price;
    }

    function setPrice(uint _planId, uint256 _price) public onlyOwner {
        subscriptionPlans[_planId]._price = _price;
    }

    function setTrialPeriod(uint256 _time) external onlyOwner {
        trialTimestamp = _time;
    }

    function setTrialPrice(uint256 _price) external onlyOwner {
        trialPrice = _price;
    }

    function giveTrial(address _address, uint256 _timestamp) external onlyOwner {
        trialToTime[_address] = _timestamp;
    }

    function setTimestampForAddress(address _address, uint256 _timestamp) external onlyOwner {
        if (userToTimeRegistered[_address] == 0) {
            registeredAddresses.push(_address);
        }
        userToTimeRegistered[_address] = _timestamp;
    }

    function whitelistAddress(address _address) external onlyOwner {
        require(whitelisted[_address] == false, "Already whitelisted");
        if (userToTimeRegistered[_address] == 0) {
            registeredAddresses.push(_address);
        }
        whitelisted[_address] = true;
    }

    function removeAddressFromWhitelist(address _address) external onlyOwner {
        require(whitelisted[_address] == true, "Not whitelisted");
        delete whitelisted[_address];
    }

    function isRegistered(address _address) public view returns (bool) {
        for(uint i = 0; i < registeredAddresses.length; i++) {
            if (registeredAddresses[i] == _address ) {
                return true;
            }
        }
        return false;
    }

    function isWhitelisted(address _address) external view returns (bool) {
        return whitelisted[_address];
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}