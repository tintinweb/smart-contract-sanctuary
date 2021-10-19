// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract EnvoyStaking is Ownable {
    event NewStake(address indexed user, uint256 totalStaked, uint256 totalDays, bool isEmbargo);
    event StakeFinished(address indexed user, uint256 totalRewards);
    event LockingIncreased(address indexed user, uint256 total);
    event LockingReleased(address indexed user, uint256 total);
    IERC20 token;
    uint256 dailyBonusRate = 10003271876792519; //1,0003271876792519
    
    uint256 public totalStakes;
    uint256 public totalActiveStakes;
    uint256 public totalStaked;
    uint256 public totalStakeClaimed;
    uint256 public totalRewardsClaimed;
    
    struct Stake {
        bool exists;
        uint256 createdOn;
        uint256 initialAmount;
        uint256 totalDays;
        bool claimed;
        bool isEmbargo;
    }
    
    mapping(address => Stake) stakes;
    mapping(address => uint256) public lockings;

    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function increaseLocking(address _beneficiary, uint256 _total) public onlyOwner {
        require(IERC20(token).transferFrom(msg.sender, address(this), _total), "Couldn't take the tokens");
        
        lockings[_beneficiary] += _total;
        
        emit LockingIncreased(_beneficiary, _total);
    }
    
    function releaseFromLocking(address _beneficiary, uint256 _total) public onlyOwner {
        require(lockings[_beneficiary] >= _total, "Not enough locked tokens");
        
        lockings[_beneficiary] -= _total;

        require(IERC20(token).transfer(_beneficiary, _total), "Couldn't send the tokens");
        
        emit LockingReleased(_beneficiary, _total);
    }

    function createEmbargo(address _account, uint256 _totalStake, uint256 _totalDays) public onlyOwner {
        _addStake(_account, _totalStake, _totalDays, true);
    }
    
    function createStake(uint256 _totalStake, uint256 _totalDays) public {
        _addStake(msg.sender, _totalStake, _totalDays, false);
    }
    
    function _addStake(address _beneficiary, uint256 _totalStake, uint256 _totalDays, bool _isEmbargo) internal {
        require(!stakes[_beneficiary].exists, "Stake already created");
        require(_totalDays > 29, "The minimum is 30 days");

        require(IERC20(token).transferFrom(msg.sender, address(this), _totalStake), "Couldn't take the tokens");
        
        Stake memory stake = Stake({exists:true,
                                    createdOn: block.timestamp, 
                                    initialAmount:_totalStake, 
                                    totalDays:_totalDays, 
                                    claimed:false,
                                    isEmbargo:_isEmbargo
        });
        
        stakes[_beneficiary] = stake;
                                    
        totalActiveStakes++;
        totalStakes++;
        totalStaked += _totalStake;
        
        emit NewStake(_beneficiary, _totalStake, _totalDays, _isEmbargo);
    }
    
    function finishStake() public {
        require(!stakes[msg.sender].isEmbargo, "This is an embargo");

        _finishStake(msg.sender);
    }
    
    function finishEmbargo(address _account) public onlyOwner {
        require(stakes[_account].isEmbargo, "Not an embargo");

        _finishStake(_account);
    }
    
    function _finishStake(address _account) internal {
        require(stakes[_account].exists, "Invalid stake");
        require(!stakes[_account].claimed, "Already claimed");

        Stake storage stake = stakes[_account];
        
        uint256 finishesOn = _calculateFinishTimestamp(stake.createdOn, stake.totalDays);
        require(block.timestamp > finishesOn, "Can't be finished yet");
        
        stake.claimed = true;
        
        uint256 totalRewards = calculateRewards(_account, block.timestamp);

        totalActiveStakes -= 1;
        totalStakeClaimed += stake.initialAmount;
        totalRewardsClaimed += totalRewards;
        
        require(token.transfer(msg.sender, totalRewards), "Couldn't transfer the tokens");
        
        emit StakeFinished(msg.sender, totalRewards);
    }
    
    function _truncateTotal(uint256 _total) internal pure returns(uint256) {
        return _total / 1e18 * 1e18;
    }
    
    function calculateRewards(address _account, uint256 _date) public view returns (uint256) {
        require(stakes[_account].exists, "Invalid stake");

        uint256 daysSoFar = (_date - stakes[_account].createdOn) / 1 days;
        if (daysSoFar > stakes[_account].totalDays) {
            daysSoFar = stakes[_account].totalDays;
        }
        
        uint256 totalRewards = stakes[_account].initialAmount;
        
        for (uint256 i = 0; i < daysSoFar; i++) {
            totalRewards = totalRewards * dailyBonusRate / 1e16;
        }
        
        return _truncateTotal(totalRewards);
    }
    
    function calculateFinishTimestamp(address _account) public view returns (uint256) {
        return _calculateFinishTimestamp(stakes[_account].createdOn, stakes[_account].totalDays);
    }
    
    function _calculateFinishTimestamp(uint256 _timestamp, uint256 _totalDays) internal pure returns (uint256) {
        return _timestamp + _totalDays * 1 days;
    }
    
    function _extract(uint256 amount, address _sendTo) public onlyOwner {
        require(token.transfer(_sendTo, amount));
    }
    
    function getStake(address _account) external view returns (bool _exists, uint256 _createdOn, uint256 _initialAmount, uint256 _totalDays, bool _claimed, bool _isEmbargo, uint256 _finishesOn, uint256 _rewardsSoFar, uint256 _totalRewards) {
        Stake memory stake = stakes[_account];
        if (!stake.exists) {
            return (false, 0, 0, 0, false, false, 0, 0, 0);
        }
        uint256 finishesOn = calculateFinishTimestamp(_account);
        uint256 rewardsSoFar = calculateRewards(_account, block.timestamp);
        uint256 totalRewards = calculateRewards(_account, stake.createdOn + stake.totalDays * 1 days);
        return (stake.exists, stake.createdOn, stake.initialAmount, stake.totalDays, stake.claimed, stake.isEmbargo, finishesOn, rewardsSoFar, totalRewards);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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