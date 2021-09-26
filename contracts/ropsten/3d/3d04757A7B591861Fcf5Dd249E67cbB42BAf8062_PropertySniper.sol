/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
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

contract PropertySniper is Ownable {
    // Structs for gas optimization
    struct Subscription {
        uint256 price;
        uint256 time;
    }

    struct User {
        uint256 end_of_subscription;
    }

    uint256 constant private DAY_SECONDS = 86400;
    uint private currentPrice = 100;
    address payable public treasury;
    uint maxNumberOfUsers = 25;
    uint whitelistCount;

    mapping(address => User) private users;
    mapping(address => bool) private whitelisted;
    mapping(uint => Subscription) private subscriptionOptions;
    address[] currentlySubscribedAddresses;
    bool activeSale = true;
    

    constructor() {
        subscriptionOptions[0] = Subscription(200000000000000000, 14 * DAY_SECONDS);
        subscriptionOptions[1] = Subscription(350000000000000000, 30 * DAY_SECONDS);
        subscriptionOptions[2] = Subscription(850000000000000000, 90 * DAY_SECONDS);
        subscriptionOptions[3] = Subscription(2650000000000000000, 365 * DAY_SECONDS);
    }

    function setTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setBasePrice(uint256 _index, uint256 _price) external onlyOwner {
        subscriptionOptions[_index].price = _price;
    }

    function getSubscriptionLength(uint256 _index) external view returns(uint256) {
        return subscriptionOptions[_index].time;
    }

    function setSubscriptionLength(uint256 _index, uint256 _timeInDays) external onlyOwner {
        subscriptionOptions[_index].time = _timeInDays * DAY_SECONDS;
    }

    function subscribe(address payable _referrer, uint256 _subscriptionIndex) external payable {
        require(treasury != address(0), "Treasury not set yet.");
        require(subscriptionOptions[_subscriptionIndex].price * currentPrice / 100 == msg.value, "Incorrect Ether value.");
        require(whitelistCount < maxNumberOfUsers, "Maximum number of subscribers reached.");
        require(activeSale, "Sale is not active. Check Discord or Twitter for updates.");
        require(updateAndReturnNumberOfSubscribers() < maxNumberOfUsers, "Max number of users reached.");
        
        User storage user = users[msg.sender];

        if (user.end_of_subscription == 0) {
            users[msg.sender] = User(block.timestamp + subscriptionOptions[_subscriptionIndex].time);
            whitelistCount++;
        } else if (getTimeUntilSubscriptionExpired(msg.sender) <= 0) {
            user.end_of_subscription = block.timestamp + subscriptionOptions[_subscriptionIndex].time;
            whitelistCount++;
        } else {
            user.end_of_subscription += subscriptionOptions[_subscriptionIndex].time;
        }

        // Whitelist the user
        currentlySubscribedAddresses.push(msg.sender);

        // Never hold Ether in the contract. Directly transfer 5% to the referrer, 95% to the treasury wallet.
        if (_referrer == address(0)) {
            treasury.transfer(msg.value);
        } else {
            _referrer.transfer(msg.value * 5 / 100);
            treasury.transfer(msg.value * 95 / 100);
        }
    }

    function getAllSubscriptionPlans() external view returns(Subscription[] memory) {
        Subscription[] memory subscriptionArray = new Subscription[](4);
        for(uint i = 0; i < 4; i++) {
            subscriptionArray[i] = subscriptionOptions[i];
        }
        return subscriptionArray;
    }

    function discount(uint _amountAsAPercent) external onlyOwner {
        currentPrice = 100 - _amountAsAPercent;
    }
    
    function getCurrentPrice() internal view returns(uint) {
        return currentPrice;
    }
    
    function getSubscriptionPlanPrice(uint _index) external view returns(uint256) {
        return subscriptionOptions[_index].price * currentPrice / 100;
    }

    function setMaxNumberOfUsers(uint _numberOfUsers) external onlyOwner {
        maxNumberOfUsers = _numberOfUsers;
    }
    
    function getMaxNumberOfUsers() external view returns(uint) {
        return maxNumberOfUsers;
    }
    
    function addUserToWhitelist(address _address, uint subscriptionLengthInSeconds) external onlyOwner {
        // Add or overwrite key value pair
        if (block.timestamp <= users[_address].end_of_subscription) {
            users[_address].end_of_subscription += subscriptionLengthInSeconds;
        } else if (users[_address].end_of_subscription != 0){
            users[_address].end_of_subscription = block.timestamp + subscriptionLengthInSeconds;
        } else {
            users[_address] = User(block.timestamp + subscriptionLengthInSeconds);
        }
        currentlySubscribedAddresses.push(_address);
    }
    
    function getTimeUntilSubscriptionExpired(address _address) public view returns(int256) {
        return int256(users[_address].end_of_subscription) - int256(block.timestamp);
    }
    
    function updateAndReturnNumberOfSubscribers() public returns(uint) {
        uint index = 0;
        while (index < currentlySubscribedAddresses.length) {
            while (index < currentlySubscribedAddresses.length && getTimeUntilSubscriptionExpired(currentlySubscribedAddresses[index]) <= 0) {
                efficientRemove(index);
            }
            index++;
        }
        return currentlySubscribedAddresses.length;
    }
    
    function efficientRemove(uint _index) internal {
        require(_index < currentlySubscribedAddresses.length);
        currentlySubscribedAddresses[_index] = currentlySubscribedAddresses[currentlySubscribedAddresses.length - 1];
        currentlySubscribedAddresses.pop();
        whitelistCount--;
    }
    
    function getWhitelistedAddresses() external view returns(address[] memory) {
        return currentlySubscribedAddresses;
    }
    
    function removeAddressFromWhitelist(address _address) external onlyOwner {
        for (uint i = 0; i < currentlySubscribedAddresses.length; i++) {
            if (currentlySubscribedAddresses[i] == _address) {
                efficientRemove(i);
                users[_address].end_of_subscription = 0;
                whitelistCount--;
            }
        }
    }
    
    function getActiveSale() external view returns(bool) {
        return activeSale;
    }
    
    function setActiveSale(bool _activeSale) external onlyOwner {
        activeSale = _activeSale;
    }

    function getNumberOfWhitelistedUsers() external view returns(uint) {
        return whitelistCount;
    }
}