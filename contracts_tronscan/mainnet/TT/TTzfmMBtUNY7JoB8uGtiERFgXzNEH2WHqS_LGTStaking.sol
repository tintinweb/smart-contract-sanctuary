//SourceUnit: LGTStaking-1.sol



//SPDX-License-Identifier: MIT

pragma solidity ^0.4.25;

interface ITRC20 {
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


contract LGTStaking is Ownable{
    using SafeMath for uint;
    
    struct StakingInfo {
        uint amount;
        uint depositDate;
        uint rewardAmount;
    }
    
    uint minStakeAmount = 100 * 10**18; // LGT token has 18 decimals
    uint REWARD_DIVIDER = 10**6;
    
    ITRC20 stakingToken;
    uint rewardAmount; 
    
    uint ownerTokensAmount;
    address[] internal stakeholders;
    mapping(address => StakingInfo[]) internal stakes;

      
    //  set 17 if you want 0.0001 per hour reward (because it will be divided by 10^6 for getting the small float number)
    //  0.0001 per hour = 0.001 / 60 ~ 0.0000017 (17 / 10^6)
    constructor(ITRC20 _stakingToken) public {
        stakingToken = _stakingToken;
        rewardAmount = 17;
    }
    
    event Staked(address staker, uint amount);
    event Unstaked(address staker, uint amount);
    
    function changeRewardAmount(uint _rewardAmount) public onlyOwner {
        rewardAmount = _rewardAmount;
    }
    
    function changeMinStakeAmount(uint _minStakeAmount) public onlyOwner {
        minStakeAmount = _minStakeAmount;
    }
    
    function totalStakes() public view returns(uint256) {
        uint _totalStakes = 0;
        for (uint i = 0; i < stakeholders.length; i += 1) {
            for (uint j = 0; j < stakes[stakeholders[i]].length; j += 1)
             _totalStakes = _totalStakes.add(stakes[stakeholders[i]][j].amount);
        }
        return _totalStakes;
    }
    
    function isStakeholder(address _address) public view returns(bool, uint256) {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) 
                return (true, s);
        }
        return (false, 0);
    }

    function addStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if (!_isStakeholder)
            stakeholders.push(_stakeholder);
    }

    function removeStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if (_isStakeholder) {
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            //stakeholders.pop();
        }
    }
    
    function stake(uint256 _amount) public {
        require((_amount >= minStakeAmount) && (_amount % 100 == 0));
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Stake required!");
        if (stakes[msg.sender].length == 0) {
            addStakeholder(msg.sender);
        }
        stakes[msg.sender].push(StakingInfo(_amount, block.timestamp, rewardAmount));
        emit Staked(msg.sender, _amount);
    }

    function unstake() public {
        uint withdrawAmount = 0;
        for (uint j = 0; j < stakes[msg.sender].length; j += 1) {
            uint amount = stakes[msg.sender][j].amount;
            withdrawAmount = withdrawAmount.add(amount);
            
            uint _rewardAmount = amount.mul((block.timestamp - stakes[msg.sender][j].depositDate).mul(stakes[msg.sender][j].rewardAmount));
            _rewardAmount = _rewardAmount.div(REWARD_DIVIDER);
            withdrawAmount = withdrawAmount.add(_rewardAmount.div(100));
        }
        
        require(stakingToken.transfer(msg.sender, withdrawAmount), "Not enough tokens in contract!");
        delete stakes[msg.sender];
        removeStakeholder(msg.sender);
        emit Unstaked(msg.sender, withdrawAmount);
    }
    
    function sendTokens(uint _amount) public onlyOwner {
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Transfering not approved!");
        ownerTokensAmount = ownerTokensAmount.add(_amount);
    }
    
    function withdrawTokens(address receiver, uint _amount) public onlyOwner {
        uint256 _ownerTokenAmount = _amount * 15  / 100 ;
        uint256 netAmount = _amount - _ownerTokenAmount ;
        ownerTokensAmount = ownerTokensAmount.sub(netAmount);
        require(stakingToken.transfer(receiver, netAmount), "Not enough tokens on contract!");
    }
}