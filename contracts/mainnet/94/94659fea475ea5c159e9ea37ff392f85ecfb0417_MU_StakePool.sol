/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

/**
    BETA POOL :
    Pool Details - 10%, 7 days (1 Week)
    Early Maturity - 1/2 Week ,3.5 Days, 20% Of Pool Rewards
**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable  {
    address payable public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = payable(msg.sender);
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface Token {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);

}


contract MU_StakePool is Ownable{
    
    using SafeMath for uint;

    struct User {
        uint256 poolBal;
        uint40 pool_deposit_time;
        uint256 total_deposits;
        uint256 pool_payouts;
        uint256 rewardEarned;
        uint256 rewardUnWithdrawed;
        uint256 earlyRewardUnWithdrawed;
        uint256 afterEarlyRewardUnWithdrawed;
    }
    
    address public tokenAddr;
    uint256 public Pool = 100000;
    uint256 public PoolBalance;
    uint256 public tokenDecimal = 18;

    uint256 public poolNumber = 1;
    uint256 public poolRewardPercent = 10;
    uint256 public poolDurationMonths = 1;
   

    mapping(address => User) public users;

    event TokenTransfer(address beneficiary, uint amount);
    event PoolTransfer(address beneficiary, uint amount);
    event RewardClaimed(address beneficiary, uint amount);
    
    mapping (address => uint256) public balances;


    constructor(address _tokenAddr) {
        tokenAddr = _tokenAddr;
    }
    
    /* Recieve Accidental ETH Transfers */
    receive() payable external {
        _owner.transfer(msg.value);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
    }


    /* Stake Token Function */
    function PoolStake(uint256  _amount) public returns (bool) {
        require(_amount <= Token(tokenAddr).balanceOf(msg.sender),"Token Balance of user is less");
        require(Token(tokenAddr).transferFrom(msg.sender,address(this), _amount),"BEP20: Amount Transfer Failed Check id Amount is Approved");
        PoolBalance += _amount;
        require(PoolBalance <= Pool * (10**tokenDecimal),"Pool is Full, Enter Amount Equal to Pool Holding or remaining pool balance");
        require(users[msg.sender].poolBal == 0,"Already Staked");
        users[msg.sender].poolBal = _amount;
        users[msg.sender].total_deposits += _amount;
        users[msg.sender].pool_deposit_time = uint40(block.timestamp);
        users[msg.sender].rewardUnWithdrawed = (_amount*10)/100; // 10% Total Reward After 1 Week Stake
        users[msg.sender].earlyRewardUnWithdrawed = (((_amount*10)/100)*20)/100; // 20% of Reward After 3.5 Days Stake - Early Maturity
        users[msg.sender].afterEarlyRewardUnWithdrawed = (((_amount*10)/100)*80)/100; // 80% of Reward After 1 week Stake Early Withdrawal - Full Maturity
        emit PoolTransfer(msg.sender, _amount);
        return true;
    }
    
    /* Claims Principal Token and Rewards Collected */
    function claimPool() public returns(bool){
        require(users[msg.sender].poolBal > 0,"There is no deposit for this address in Pool");
        require(block.timestamp > users[msg.sender].pool_deposit_time + 5040 minutes, "Minimum 3.5 Days to be completed - 1/2 Week");
        
        if(block.timestamp > users[msg.sender].pool_deposit_time + 5040 minutes && block.timestamp < users[msg.sender].pool_deposit_time + 7 days){
            
            require(Token(tokenAddr).transfer(msg.sender, users[msg.sender].earlyRewardUnWithdrawed),"Cannot Transfer Reward Funds");
            users[msg.sender].rewardEarned += (users[msg.sender].earlyRewardUnWithdrawed);
            users[msg.sender].rewardUnWithdrawed = users[msg.sender].rewardUnWithdrawed - users[msg.sender].earlyRewardUnWithdrawed;
            users[msg.sender].earlyRewardUnWithdrawed = 0;
            emit RewardClaimed(msg.sender, users[msg.sender].earlyRewardUnWithdrawed);
            return true;

        }else{
            require(block.timestamp > users[msg.sender].pool_deposit_time + 7 days, "Minimum 7 Days to be completed  - 1 Week");
            uint256 amount = users[msg.sender].poolBal;
            require(Token(tokenAddr).transfer(msg.sender, amount),"Cannot Transfer Principal Funds");
            require(Token(tokenAddr).transfer(msg.sender, users[msg.sender].earlyRewardUnWithdrawed + users[msg.sender].afterEarlyRewardUnWithdrawed),"Cannot Transfer Reward Funds");
            
            uint256 totalReward= (users[msg.sender].earlyRewardUnWithdrawed + users[msg.sender].afterEarlyRewardUnWithdrawed);
            users[msg.sender].rewardEarned += totalReward;
            
            users[msg.sender].rewardUnWithdrawed = users[msg.sender].rewardUnWithdrawed - (users[msg.sender].earlyRewardUnWithdrawed + users[msg.sender].afterEarlyRewardUnWithdrawed);
            users[msg.sender].earlyRewardUnWithdrawed = 0;
            users[msg.sender].afterEarlyRewardUnWithdrawed = 0;
            users[msg.sender].poolBal = 0;
            users[msg.sender].pool_deposit_time = 0;
            users[msg.sender].pool_payouts += amount;
            
            emit TokenTransfer(msg.sender, amount);
            emit RewardClaimed(msg.sender, totalReward);
            return true;
        
            
        }

            
    }

    
    /* Check Token Balance inside Contract */
    function tokenBalance() public view returns (uint256){
        return Token(tokenAddr).balanceOf(address(this));
    }

    /* Check ETH Balance inside Contract */
    function ethBalance() public view returns (uint256){
        return address(this).balance;
    }

    /* Calculate Remaining Staking Claim time of Users */
    function stakeTimeRemaining(address _userAdd) public view returns (uint256){
        if(users[_userAdd].pool_deposit_time > 0){
            uint256 stakeTime = users[_userAdd].pool_deposit_time + 7 days;
            if(stakeTime > block.timestamp){
                return (stakeTime - block.timestamp);
            }else{
                return 0;
            }
        }else{
            return 0;
        }
    }
    
    /* Calculate Early Remaining Staking Claim time of Users */
    function earlyStakeTimeRemaining(address _userAdd) public view returns (uint256){
        if(users[_userAdd].pool_deposit_time > 0){
            uint256 stakeTime = users[_userAdd].pool_deposit_time + 5040 minutes;
            if(stakeTime > block.timestamp){
                return (stakeTime - block.timestamp);
            }else{
                return 0;
            }
        }else{
            return 0;
        }
    }

    /* Admin function to update the Pool Total Stake Capacity */
    function updatePoolCapacity(uint256 PoolAmount) public onlyOwner() returns(bool){
        Pool = PoolAmount;
        return true;
    }
    
    
    /* Maturity Date */
    function maturityDate(address userAdd) public view returns(uint256){
        return (users[userAdd].pool_deposit_time + 7 days);
    }
    
    /* Early Maturity Date */
    function earlyMaturityDate(address userAdd) public view returns(uint256){
        return (users[userAdd].pool_deposit_time + 5040 minutes);
    }
    

}