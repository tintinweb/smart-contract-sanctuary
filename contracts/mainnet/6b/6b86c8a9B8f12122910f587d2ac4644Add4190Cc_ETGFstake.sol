pragma solidity ^0.5.17;

library SafeMath {
    function add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function sub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); 
        c = a - b; 
    } 
    
    function mul(uint a, uint b) public pure returns (uint c) {
        c = a * b; 
        require(a == 0 || c / a == b); 
    } 
    
    function div(uint a, uint b) public pure returns (uint c) { 
        require(b > 0);
        c = a / b;
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

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ETGFstake is Ownable {
    using SafeMath for uint;
    
    struct StakingInfo {
        uint amount;
        uint depositDate;
        uint rewardPercent;
    }
    
    uint MIN_STAKE_AMOUNT = 30;
    uint REWARD_DIVIDER = 10**8;
    
    ERC20Interface stakingToken;
    uint rewardPercent; //  percent value for per second  -> set 192 if you want 5% per month reward (because it will be divided by 10^8 for getting the small float number)
    string name = "E-stake";
    
    uint ownerTokensAmount;
    address[] internal stakeholders;
    mapping(address => StakingInfo[]) internal stakes;

    //  percent value for per second  
    //  set 192 if you want 5% per month reward (because it will be divided by 10^8 for getting the small float number)
    //  5% per month = 5 / (30 * 24 * 60 * 60) ~ 0.00000192 (192 / 10^8)
    constructor(ERC20Interface _stakingToken, uint _rewardPercent) public {
        stakingToken = _stakingToken;
        rewardPercent = _rewardPercent;
    }
    
    event Staked(address staker, uint amount);
    event Unstaked(address staker, uint amount);
    
    function changeRewardPercent(uint _rewardPercent) public onlyOwner {
        rewardPercent = _rewardPercent;
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
            stakeholders.pop();
        }
    }
    
    function stake(uint256 _amount) public {
        require(_amount >= MIN_STAKE_AMOUNT);
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Stake required!");
        if (stakes[msg.sender].length == 0) {
            addStakeholder(msg.sender);
        }
        stakes[msg.sender].push(StakingInfo(_amount, now, rewardPercent));
        emit Staked(msg.sender, _amount);
    }

    function unstake() public {
        uint withdrawAmount = 0;
        for (uint j = 0; j < stakes[msg.sender].length; j += 1) {
            uint amount = stakes[msg.sender][j].amount;
            withdrawAmount = withdrawAmount.add(amount);
            
            uint rewardAmount = amount.mul((now - stakes[msg.sender][j].depositDate).mul(stakes[msg.sender][j].rewardPercent));
            withdrawAmount = withdrawAmount.add(rewardAmount.div(100));
        }
        
        require(stakingToken.transfer(msg.sender, withdrawAmount), "Not enough tokens in contract!");
        delete stakes[msg.sender];
        removeStakeholder(msg.sender);
        emit Unstaked(msg.sender, withdrawAmount);
    }
    
    function sendTokens(uint _amount) public onlyOwner {
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Stake required!");
        ownerTokensAmount = ownerTokensAmount.add(_amount);
    }
    
    function withdrawTokens(address receiver, uint _amount) public onlyOwner {
        ownerTokensAmount = ownerTokensAmount.sub(_amount);
        require(stakingToken.transfer(receiver, _amount), "Not enough tokens on contract!");
    }
}