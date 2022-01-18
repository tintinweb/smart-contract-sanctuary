/**
 *Submitted for verification at FtmScan.com on 2022-01-18
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;


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
    constructor() {
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Reward.sol


pragma solidity ^0.8.4;



contract FantomFrensReward is Ownable, Pausable {

    uint public rewardCount = 0;
    address MANAGER;

    uint[] public rewards;

    mapping(uint => Reward) public rewardList;

    //Track Rewards Collected total
    // Reward ID => reward count
    mapping(uint => uint) public collections;

    // address => rewardId ID => bool
    mapping(address => mapping(uint => bool)) public hasCollected;
    
    struct Reward {
        uint rewardId;
        string title;
        uint256 initiationTimestamp;
        uint256 completionTimestamp;
        uint256 creationTime;
        uint pool;
    }

    // Events
    event RewardSubmitted(
        uint rewardId,
        string title,
        uint256 initiationTimestamp,
        uint256 completionTimestamp,
        uint256 creationTime,
        uint pool
    );

    
    event RewardDeleted(
        uint rewardId
    );

    event RewardCollected(
        uint rewardId,
        address collector,
        uint256 amount
    );

    function setManager(address _address) external onlyOwner{
        MANAGER = _address;
    }
    
    function collectReward(uint rewardId, uint amount, address to) external whenNotPaused {
        require(msg.sender == MANAGER || msg.sender == owner(), "Only the manager or Owner can execute rewards");
        require(to != address(0), "Proposal sender cannot be the zero address");
        require(rewardList[rewardId].initiationTimestamp >= block.timestamp, "Rewards has not started yet");
        require(rewardList[rewardId].completionTimestamp < block.timestamp, "Rewards has already ended");
        require(hasCollected[to][rewardId] == false, "You have already collected this reward");

        collections[rewardId] += amount;
        hasCollected[to][rewardId] = true;

        payable(to).transfer(amount);
        
        emit RewardCollected(
            rewardId,
            to,
            amount
        );

    }


    function submitReward(
        string calldata title,
        uint256 initiationTimestamp,
        uint256 completionTimestamp,
        uint256 creationTime,
        uint pool
    ) external onlyOwner whenNotPaused {
        require(msg.sender != address(0), "Proposal sender cannot be the zero address");

        uint rewardId = rewardCount++;

        rewardList[rewardId] = Reward(
            rewardId,
            title,
            initiationTimestamp,
            completionTimestamp,
            creationTime,
            pool
        );

        rewards.push(rewardId);

        emit RewardSubmitted(
            rewardId,
            title,
            initiationTimestamp,
            completionTimestamp,
            creationTime,
            pool
        );
    }

    function deleteReward(uint rewardId) external onlyOwner {
        require(!paused(), "Contract is paused");
        delete rewardList[rewardId];

        for (uint i = rewardId; i<rewards.length-1; i++){
            rewards[i] = rewards[i+1];
        }
        rewards.pop();

        emit RewardDeleted(rewardId);
    }

    function getReward(uint rewardId) external view returns (Reward memory) {
        return rewardList[rewardId];
    }

    function geRewardIds() external view returns (uint[] memory) {
        return rewards;
    }

   

    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

    function withdraw(uint amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function withdrawAll() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

}