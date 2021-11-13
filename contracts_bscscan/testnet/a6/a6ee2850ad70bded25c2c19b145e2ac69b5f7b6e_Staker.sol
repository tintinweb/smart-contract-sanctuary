/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

// SPDX-License-Identifier: No-License
pragma solidity ^0.8;

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

contract Staker is Ownable {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    
    //rewards
    uint public rewardRate;    
    uint public rewardPerTokenStored;
    uint public lastUpdateBlock;

    //user rewards mapping
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;        
    mapping(address => uint) private _balances;
    uint private _totalStaked;
    
    
    constructor(address _tokenAddress, uint _rewardrate){
        stakingToken = IERC20(_tokenAddress);
        rewardsToken = IERC20(_tokenAddress);
        rewardRate = _rewardrate * 1e9;
    }
    
    
    function rewardPerToken() public view returns(uint){
        if(_totalStaked == 0){
            return 0;
        }
        return rewardPerTokenStored + (rewardRate * (block.number - lastUpdateBlock) * 1e9 / _totalStaked);
    }
    
    function earned(address account) public view returns(uint){
        return (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e9) + rewards[account];
    }
    
    modifier updateReward(address account){
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = block.number;
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }
    
    function deposit(uint _amount) external updateReward(msg.sender){
         require(_amount > 0, "Cannot withdraw 0");
        _totalStaked += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }
    
    function withdraw(uint _amount) external updateReward(msg.sender){
        require(_amount > 0, "Cannot withdraw 0");
        _totalStaked -= _amount;
        _balances[msg.sender] -= _amount;   
        stakingToken.transfer(msg.sender, _amount);
    }
    
    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
    }
    
    function setRewardRate(uint _rewardrate) public onlyOwner{
        rewardRate = _rewardrate * 1e9;
    }

    function getTotalStaked() external view returns(uint){
        return _totalStaked;
    }

    function getUserStaked(address _account) external view returns(uint){
        return _balances[_account];
    }
    
}

interface IERC20 {
    
    function totalSupply() external view returns (uint);
    
    function balanceOf(address account) external view returns (uint);
    
    function transfer(address recipient, uint amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint);
    
    function approve(address spender, uint amount) external returns (bool);
    
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}