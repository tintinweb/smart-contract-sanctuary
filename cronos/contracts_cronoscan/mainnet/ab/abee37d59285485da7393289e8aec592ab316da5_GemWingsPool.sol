/**
 *Submitted for verification at cronoscan.com on 2022-06-06
*/

//
/**
GemWingsPool 
*/
pragma solidity 0.8.12;

// SPDX-License-Identifier: MIT
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {_setOwner(_msgSender());}
    function owner() public view virtual returns (address) {return _owner;}
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0),"Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}



contract GemWingsPool is Ownable {
    constructor() {
        stakeholders.push();
        apyRateForDaysLocked[0] = 50;
        apyRateForDaysLocked[7] = 150;
        apyRateForDaysLocked[30] = 300;
    }
    address public constant GemWings_TOKEN = 0x2c4E88a10f5C9814366b72322eC3886F40f1Ff2B;
    address public devWallet = 0x48Df8357a323b299C1Ff728f5C7b1d8a28f52e37;
    
    mapping(uint256 => uint256) public apyRateForDaysLocked;
    
    struct Stake {
        address user;
        uint256 amount;
        uint256 stakedDays;
        uint256 since;
        uint256 dueDate;
        uint256 baseRate;
        uint256 claimableReward;
        uint256 personalStakeIndex;
    }
    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }
    struct StakingSummary {
        uint256 total_amount;
        Stake[] stakes;
    }
    Stakeholder[] internal stakeholders;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) public totalStakedTokensForThisAddress;

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 stakedDays,
        uint256 index,
        uint256 timestamp,
        uint256 dueDate,
        uint256 baseRate
    );

    function _addStakeholder(address staker) internal returns (uint256) {
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex;
    }

    function _calculateDueDate(uint256 _days) internal view returns (uint256) {return block.timestamp + (_days * 1 days);}
    
    function _stake(uint256 _amount, uint256 _days) internal {
        require(_amount > 0, "Cannot stake nothing");
        uint256 stakingRateTotal = apyRateForDaysLocked[_days];
        uint256 dueDate = _calculateDueDate(_days);
        uint256 index = stakes[msg.sender];
        uint256 _personalStakeIndex;
        uint256 timestamp = block.timestamp;
        if (index == 0) {
            index = _addStakeholder(msg.sender);
            _personalStakeIndex = 0;
        } else {_personalStakeIndex = stakeholders[stakes[msg.sender]].address_stakes.length;}
        stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, _days, timestamp, dueDate, stakingRateTotal, 0, _personalStakeIndex));
        totalStakedTokensForThisAddress[msg.sender] += _amount;
        emit Staked(msg.sender, _amount, _days, index, timestamp, dueDate, stakingRateTotal);
    }
    function calculateStakeReward(Stake memory _current_stake) internal view returns (uint256) {
        return (((block.timestamp - _current_stake.since) * _current_stake.amount) * _current_stake.baseRate) / (365 days * 100);
    }

    function _withdrawStake(uint256 amount, uint256 index) internal returns (uint256, uint256){
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        if(amount > 0){
        require(current_stake.dueDate < block.timestamp,"Stake can not be claimed yet");
        require(current_stake.amount >= amount,"Cannot withdraw more than you have staked");
        totalStakedTokensForThisAddress[msg.sender] -= amount;
        }

        uint256 reward = calculateStakeReward(current_stake);

        current_stake.amount = current_stake.amount - amount;
        if (current_stake.amount == 0) {
            delete stakeholders[user_index].address_stakes[index];
        } else {
            stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
            stakeholders[user_index].address_stakes[index].since = block.timestamp;
        }
        return (amount, reward);
    }

    function hasStake(address _staker) public view returns (StakingSummary memory){
        uint256 totalStakeAmount = 0;
        StakingSummary memory summary = StakingSummary(0,stakeholders[stakes[_staker]].address_stakes);
        
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].claimableReward = availableReward;
            totalStakeAmount += summary.stakes[s].amount;
        }
        summary.total_amount = totalStakeAmount;
        return summary;
    }

    function howManyTokenHasThisAddressStaked(address account) external view returns (uint256) {
        return totalStakedTokensForThisAddress[account];
    }

    function setApy(uint256 _days, uint256 _apy) external onlyOwner {
        apyRateForDaysLocked[_days] = _apy; 
    }
    
    function stake(uint256 _amount, uint256 _days) public {
        require(IERC20(GemWings_TOKEN).balanceOf(msg.sender) >= _amount,"Cannot stake more than you own");
        _stake(_amount, _days);
        IERC20(GemWings_TOKEN).transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawStake(uint256 amount, uint256 stake_index) public {
        uint256 stakingAmount;
        uint256 rewardForStaking;
        (stakingAmount, rewardForStaking) = _withdrawStake(amount, stake_index);
        uint256 totalWithdrawalAmount = stakingAmount + rewardForStaking;
        IERC20(GemWings_TOKEN).transfer(msg.sender, totalWithdrawalAmount);
    }


    function stakeAllFromTokenContract(address staker, uint256 _days) external {
        require(msg.sender == GemWings_TOKEN, "Only the tokencontract can use this");
        uint256 amount = IERC20(GemWings_TOKEN).balanceOf(staker);
        require(amount > 0);
        IERC20(GemWings_TOKEN).transferFrom(staker, address(this), amount);
        _stakeFromContract(staker, amount, _days);
    }

    function stakeFromTokenContract(address staker, uint256 _amount, uint256 _days) external {
        require(msg.sender == GemWings_TOKEN, "Only the tokencontract can use this");
        IERC20(GemWings_TOKEN).transferFrom(staker, address(this), _amount);
        _stakeFromContract(staker, _amount, _days);
    }

    function unstakeAllFromTokenContract(address staker) external {
        require(msg.sender == GemWings_TOKEN, "Only the tokencontract can use this");

        uint256 user_index = stakes[staker];
        uint256 totalWithdrawalAmount;
       
        for (uint i=0; i<stakeholders[user_index].address_stakes.length; i++) {
            Stake memory current_stake = stakeholders[user_index].address_stakes[i];
            uint256 stakeAmountOfCurrentStake = current_stake.amount;
            uint256 stakingAmount;
            uint256 rewardForStaking;
            (stakingAmount, rewardForStaking) = _withdrawStakeFromContract(staker,stakeAmountOfCurrentStake, i);
            totalWithdrawalAmount += stakingAmount + rewardForStaking;   
        }
        IERC20(GemWings_TOKEN).transfer(staker, totalWithdrawalAmount);
    }

    function claimFromTokenContract(address staker) external {
        require(msg.sender == GemWings_TOKEN, "Only the tokencontract can use this");
        uint256 user_index = stakes[staker];
        uint256 totalWithdrawalAmount;
       
        for (uint i=0; i<stakeholders[user_index].address_stakes.length; i++) {
        uint256 stakingAmount;
        uint256 rewardForStaking;
        (stakingAmount, rewardForStaking) = _withdrawStakeFromContract(staker,0, i);
        totalWithdrawalAmount += stakingAmount + rewardForStaking;
        }
        IERC20(GemWings_TOKEN).transfer(staker, totalWithdrawalAmount);
    }

    function unstakeFromTokenContract(address staker, uint amount, uint256 stake_index) external {
        require(msg.sender == GemWings_TOKEN, "Only the tokencontract can use this");
        require(amount > 0);
        uint256 stakingAmount;
        uint256 rewardForStaking;
        (stakingAmount, rewardForStaking) = _withdrawStakeFromContract(staker, amount, stake_index);
        uint256 totalWithdrawalAmount = stakingAmount + rewardForStaking;
        IERC20(GemWings_TOKEN).transfer(staker, totalWithdrawalAmount);
    }

    function _withdrawStakeFromContract(address staker, uint256 amount, uint256 index) internal returns (uint256, uint256){
        uint256 user_index = stakes[staker];
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        if(amount > 0){
        require(current_stake.dueDate < block.timestamp,"Stake can not be claimed yet");
        require(current_stake.amount >= amount,"Cannot withdraw more than you have staked");
        totalStakedTokensForThisAddress[staker] -= amount;
        }
        uint256 reward = calculateStakeReward(current_stake);
        current_stake.amount = current_stake.amount - amount;
        if (current_stake.amount == 0) {delete stakeholders[user_index].address_stakes[index];} 
        else {
            stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
            stakeholders[user_index].address_stakes[index].since = block.timestamp;
        }
        return (amount, reward);
    }

    function _stakeFromContract(address staker, uint256 _amount, uint256 _days) internal {
        require(_amount > 0, "Cannot stake nothing");
        uint256 stakingRateTotal = apyRateForDaysLocked[_days];
        uint256 dueDate = _calculateDueDate(_days);
        uint256 index = stakes[staker];
        uint256 _personalStakeIndex;
        uint256 timestamp = block.timestamp;
        if (index == 0) {
            index = _addStakeholder(staker);
            _personalStakeIndex = 0;
        } else {_personalStakeIndex = stakeholders[stakes[staker]].address_stakes.length;}
        stakeholders[index].address_stakes.push(Stake(staker, _amount, _days, timestamp, dueDate, stakingRateTotal, 0, _personalStakeIndex));
        totalStakedTokensForThisAddress[staker] += _amount;
        emit Staked(staker, _amount, _days, index, timestamp, dueDate, stakingRateTotal);
    }

    function rescueCRO() external onlyOwner{
        (bool tmpSuccess,) = payable(devWallet).call{value: address(this).balance, gas: 40000}("");
        tmpSuccess = false;
    }

    function rescueCROWithTransfer() external onlyOwner{
        payable(devWallet).transfer(address(this).balance);
    }
    
}