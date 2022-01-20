/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

contract StakingRewards is Ownable {
    IERC20 public token;

    struct UserInfo {
        uint256 userId;
        uint256 amount;
        uint256 rewardEarned;
        uint256 bonusEarned;
        uint256 depositTime;
    }

    uint256 public rewardRate = 100;
    uint256 public bonusRate = 100;

    bool private profibitable;

    mapping(address => UserInfo) public userInfo;

    uint private _totalSupply;

    bool private flagForStaking;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function earnedReward(address account) public view returns (uint) {
        return
            ((userInfo[account].amount * (block.timestamp - userInfo[account].depositTime)) * rewardRate / 1000) + userInfo[account].rewardEarned;
    }
    function earnedBonus(address account) public view returns (uint) {
        return
            ((userInfo[account].amount * (block.timestamp - userInfo[account].depositTime)) * bonusRate / 1000) + userInfo[account].bonusEarned;
    }

    modifier updateBalance(address account) {

        userInfo[account].rewardEarned = earnedReward(account);
        userInfo[account].bonusEarned = earnedBonus(account);
        userInfo[account].depositTime = block.timestamp;

        _;
    }

    function stake(uint _amount) external updateBalance(msg.sender) {
        require(flagForStaking == true, "The service is stopped.");
        _totalSupply += _amount;
        userInfo[msg.sender].amount += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _amount) external updateBalance(msg.sender) {
        require(flagForStaking == true, "The service is stopped.");
        require(userInfo[msg.sender].amount + userInfo[msg.sender].rewardEarned >= _amount, "Not enough balance in staking pool");
        require(_totalSupply >= _amount, "Not enough balance in staking pool");

        if(userInfo[msg.sender].amount + userInfo[msg.sender].rewardEarned >= _amount) {
            _totalSupply -= _amount;
            userInfo[msg.sender].amount -= _amount;
        } else {
            _totalSupply -= userInfo[msg.sender].amount;
            userInfo[msg.sender].rewardEarned -= _amount - userInfo[msg.sender].amount;
            userInfo[msg.sender].amount = 0;
        }
        
        token.transfer(msg.sender, _amount);
    }

    function getCurrentBalance() external view returns (uint) {
        return earnedReward(msg.sender) + userInfo[msg.sender].amount;
    }

    function getCurrentBonus() external view returns (uint) {
        return earnedBonus(msg.sender);
    }

    function withdrawReward(uint _amount) external updateBalance(msg.sender) {
        require(flagForStaking == true, "The service is stopped.");
        require(userInfo[msg.sender].rewardEarned >= _amount, "Not enough amount of reward");

        uint reward = userInfo[msg.sender].rewardEarned - _amount;
        userInfo[msg.sender].rewardEarned -= reward;
        token.transfer(msg.sender, reward);
    }

    function withdrawBonus() external updateBalance(msg.sender) {
        require(flagForStaking == true, "The service is stopped.");
        uint bonus = userInfo[msg.sender].bonusEarned;
        userInfo[msg.sender].bonusEarned = 0;
        token.transfer(msg.sender, bonus);
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }

    function setBonusRate(uint256 _bonusRate) external onlyOwner {
        bonusRate = _bonusRate;
    }

    function setFlagForStaking(bool _flag) external onlyOwner {
        flagForStaking = _flag;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}