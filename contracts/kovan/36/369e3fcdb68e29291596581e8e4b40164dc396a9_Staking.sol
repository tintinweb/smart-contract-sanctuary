/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

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
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}
contract Context {
    constructor () public { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

contract Ownable {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == owner)
            _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) owner = newOwner;
    }
}


contract Staking is Ownable{
    using SafeMath for uint;
    
    struct StakingInfo {
        uint amount;
        uint depositDate;
    }
    
 
    IERC20 stakingTokenEON;
    IERC20 stakingTokenMNT;
    uint rewardAmount; 
    
    uint ownerTokensAmount;
    address[] internal stakeholdersEON;
    mapping(address => StakingInfo[]) internal stakesEON;
    address[] internal stakeholdersMNT;
    mapping(address => StakingInfo[]) internal stakesMNT;
      
    
    constructor(IERC20 _stakingTokenEON, IERC20 _stakingTokenMNT) public {
        stakingTokenEON = _stakingTokenEON;
        stakingTokenMNT = _stakingTokenMNT;
    }
    
    event StakedEON(address staker, uint amount);
    event UnstakedEON(address staker, uint amount);
     
    event StakedMNT(address staker, uint amount);
    event UnstakedMNT(address staker, uint amount);
    
  
    function totalStakesEON() public view returns(uint256) {
        uint _totalStakes = 0;
        for (uint i = 0; i < stakeholdersEON.length; i += 1) {
            for (uint j = 0; j < stakesEON[stakeholdersEON[i]].length; j += 1)
             _totalStakes = _totalStakes.add(stakesEON[stakeholdersEON[i]][j].amount);
        }
        return _totalStakes;
    }
    
     function totalStakesMNT() public view returns(uint256) {
        uint _totalStakes = 0;
        for (uint i = 0; i < stakeholdersMNT.length; i += 1) {
            for (uint j = 0; j < stakesMNT[stakeholdersMNT[i]].length; j += 1)
             _totalStakes = _totalStakes.add(stakesMNT[stakeholdersMNT[i]][j].amount);
        }
        return _totalStakes;
    }
    
    function isStakeholderEON(address _address) public view returns(bool, uint256) {
        for (uint256 s = 0; s < stakeholdersEON.length; s += 1) {
            if (_address == stakeholdersEON[s]) 
                return (true, s);
        }
        return (false, 0);
    }
     function isStakeholderMNT(address _address) public view returns(bool, uint256) {
        for (uint256 s = 0; s < stakeholdersMNT.length; s += 1) {
            if (_address == stakeholdersMNT[s]) 
                return (true, s);
        }
        return (false, 0);
    }


    function addStakeholderEON(address _stakeholder) internal {
        (bool _isStakeholderEON, ) = isStakeholderEON(_stakeholder);
        if (!_isStakeholderEON)
            stakeholdersEON.push(_stakeholder);
    }
    
     function addStakeholderMNT(address _stakeholder) internal {
        (bool _isStakeholderMNT, ) = isStakeholderMNT(_stakeholder);
        if (!_isStakeholderMNT)
            stakeholdersMNT.push(_stakeholder);
    }

    function removeStakeholderEON(address _stakeholder) internal {
        (bool _isStakeholderEON, uint256 s) = isStakeholderEON(_stakeholder);
        if (_isStakeholderEON) {
            stakeholdersEON[s] = stakeholdersEON[stakeholdersEON.length - 1];
            stakeholdersEON.pop();
        }
    }
    
     function removeStakeholderMNT(address _stakeholder) internal {
        (bool _isStakeholderMNT, uint256 s) = isStakeholderMNT(_stakeholder);
        if (_isStakeholderMNT) {
            stakeholdersMNT[s] = stakeholdersMNT[stakeholdersMNT.length - 1];
            stakeholdersMNT.pop();
        }
    }
    
    function stakeEON(uint256 _amount) public {
        require(_amount >= 0, "INSUFFIECIENT STAKE");
        require(stakingTokenEON.transferFrom(msg.sender, address(this), _amount), "Stake required!");
        if (stakesEON[msg.sender].length == 0) {
            addStakeholderEON(msg.sender);
        }
        stakesEON[msg.sender].push(StakingInfo(_amount, block.timestamp));
        emit StakedEON(msg.sender, _amount);
    }
    
     function stakeMNT(uint256 _amount) public {
        require(_amount >= 0, "INSUFFIECIENT STAKE");
        require(stakingTokenMNT.transferFrom(msg.sender, address(this), _amount), "Stake required!");
        if (stakesMNT[msg.sender].length == 0) {
            addStakeholderMNT(msg.sender);
        }
        stakesMNT[msg.sender].push(StakingInfo(_amount, block.timestamp));
        emit StakedMNT(msg.sender, _amount);
    }

    function unstakeEON() public
    {
        uint withdrawAmount = 0;
        for (uint j = 0; j < stakesEON[msg.sender].length; j += 1) 
        {
            uint amount = stakesEON[msg.sender][j].amount;
            withdrawAmount = withdrawAmount.add(amount);
            if(block.timestamp - stakesEON[msg.sender][j].depositDate >= 5259486)
            {
                uint256 RewardForTwoMonths = amount + ((amount * 1 / 100) * 60);
                require(stakingTokenEON.transfer(msg.sender, RewardForTwoMonths), "Not enough tokens in contract!");
                require(stakingTokenMNT.transfer(msg.sender, RewardForTwoMonths), "Not enough tokens in contract!");
                delete stakesEON[msg.sender];
                removeStakeholderEON(msg.sender);
                emit UnstakedEON(msg.sender, RewardForTwoMonths);
            }
             else if(block.timestamp - stakesEON[msg.sender][j].depositDate >= 15778458)
            {
                uint256 RewardForSixMonths = amount + ((amount * 25 / 1000) * 180);
                uint256 RewardForSixMonthsMNT = amount * 3 / 100;
                require(stakingTokenEON.transfer(msg.sender, RewardForSixMonths), "Not enough tokens in contract!");
                require(stakingTokenMNT.transfer(msg.sender, RewardForSixMonthsMNT), "Not enough tokens in contract!");
                delete stakesEON[msg.sender];
                removeStakeholderEON(msg.sender);
                emit UnstakedEON(msg.sender, RewardForSixMonths);
            }
              else if(block.timestamp - stakesEON[msg.sender][j].depositDate >= 31556926)
            {
                uint256 RewardForOneYear = amount + ((amount * 6 / 100) * 365);
                uint256 RewardForOneYearMNT = amount * 7 / 100 ;
                require(stakingTokenEON.transfer(msg.sender, RewardForOneYear), "Not enough tokens in contract!");
                require(stakingTokenMNT.transfer(msg.sender, RewardForOneYearMNT), "Not enough tokens in contract!");
                delete stakesEON[msg.sender];
                removeStakeholderEON(msg.sender);
                emit UnstakedEON(msg.sender, RewardForOneYear);
            }
              else if(block.timestamp - stakesEON[msg.sender][j].depositDate >= 63113852)
            {
                uint256 RewardForTwoYears = amount + ((amount * 13 / 100) * 730);
                uint256 RewardForTwoYearsMNT = amount * 15 / 100;
                require(stakingTokenEON.transfer(msg.sender, RewardForTwoYears), "Not enough tokens in contract!");
                require(stakingTokenMNT.transfer(msg.sender, RewardForTwoYearsMNT), "Not enough tokens in contract!");
                delete stakesEON[msg.sender];
                removeStakeholderEON(msg.sender);
                emit UnstakedEON(msg.sender, RewardForTwoYears);
            }
        }
    }
    
     function unstakeMNT() public
    {
        uint withdrawAmount = 0;
        for (uint j = 0; j < stakesMNT[msg.sender].length; j += 1) 
        {
            uint amount = stakesMNT[msg.sender][j].amount;
            withdrawAmount = withdrawAmount.add(amount);
            if(block.timestamp - stakesMNT[msg.sender][j].depositDate >= 5259486)
            {
                uint256 RewardForTwoMonths = amount + ((amount * 2 / 100) * 60);
                require(stakingTokenMNT.transfer(msg.sender, RewardForTwoMonths), "Not enough tokens in contract!");
                delete stakesMNT[msg.sender];
                removeStakeholderMNT(msg.sender);
                emit UnstakedMNT(msg.sender, RewardForTwoMonths);
            }
             else if(block.timestamp - stakesMNT[msg.sender][j].depositDate >= 15778458)
            {
                uint256 RewardForSixMonths = amount + ((amount * 6 / 1000) * 180);
                require(stakingTokenMNT.transfer(msg.sender, RewardForSixMonths), "Not enough tokens in contract!");
                delete stakesMNT[msg.sender];
                removeStakeholderMNT(msg.sender);
                emit UnstakedMNT(msg.sender, RewardForSixMonths);
            }
              else if(block.timestamp - stakesMNT[msg.sender][j].depositDate >= 31556926)
            {
                uint256 RewardForOneYear = amount + ((amount * 14 / 100) * 365);
                require(stakingTokenMNT.transfer(msg.sender, RewardForOneYear), "Not enough tokens in contract!");
                delete stakesMNT[msg.sender];
                removeStakeholderMNT(msg.sender);
                emit UnstakedMNT(msg.sender, RewardForOneYear);
            }
              else if(block.timestamp - stakesMNT[msg.sender][j].depositDate >= 63113852)
            {
                uint256 RewardForTwoYears = amount + ((amount * 30 / 100) * 730);
                require(stakingTokenMNT.transfer(msg.sender, RewardForTwoYears), "Not enough tokens in contract!");
                delete stakesMNT[msg.sender];
                removeStakeholderMNT(msg.sender);
                emit UnstakedMNT(msg.sender, RewardForTwoYears);
            }
        }
    }
    
    function sendTokensEON(uint _amount) public onlyOwner {
        require(stakingTokenEON.transferFrom(msg.sender, address(this), _amount), "Transfering not approved!");
        ownerTokensAmount = ownerTokensAmount.add(_amount);
    }
   
    function sendTokensMNT(uint _amount) public onlyOwner {
        require(stakingTokenMNT.transferFrom(msg.sender, address(this), _amount), "Transfering not approved!");
        ownerTokensAmount = ownerTokensAmount.add(_amount);
    }
   
}