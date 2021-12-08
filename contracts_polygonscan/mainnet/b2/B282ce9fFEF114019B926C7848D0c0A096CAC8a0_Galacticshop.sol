// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.7.0;

import "./GalToken.sol";

contract Galacticshop {
    address payable admin;
    GalToken public tokenContract;
    uint256 public deGal = 100 * 10 ** 18; // GAL
    uint256 public deSpent;
    uint256 public deCS;
    uint256 public galStaked;
    uint256 public spy = 100000000000000000; // 0.1 (10%)
    uint256 public lockPeriod = 7 * 24 * 60; // 7 days
    
    mapping(address => uint256) public balanceOf;
    
    struct StakerStruct {
        uint256 stake;
        uint256 deadline;
    }
    
    mapping(address => StakerStruct) public stakingOf;

    event Sell(address _buyer, uint256 _amount);
    event Buy(address _seller, uint256 _amount);
    event Spend(address _user, uint256 _amount);
    event Stake(address _user, uint256 _amount);
    event Unstake(address _user, uint256 _amount);
    event Distribute(uint256[] _rewards);

    constructor(GalToken _tokenContract) public {
        admin = msg.sender;
        tokenContract = _tokenContract;
    }
	
	function setStakingPercentageYield(uint256 _spy) public {
	    require(msg.sender == admin);
	    spy = _spy;
	}
	
	function setStakeLockingPeriod(uint256 _lockPeriod) public {
	    require(msg.sender == admin);
	    lockPeriod = _lockPeriod;
	}

    function spendDarkEnergy(uint256 _numberOfUnits) public {
        require(balanceOf[msg.sender] >= _numberOfUnits);
        
        balanceOf[msg.sender] -= _numberOfUnits;
        deCS -= _numberOfUnits;
        deSpent += _numberOfUnits;

        emit Spend(msg.sender, _numberOfUnits);
    }

    function sellDarkEnergy(uint256 _numberOfUnits) public {
        uint256 cost = toGal(_numberOfUnits, deGal);
        require(balanceOf[msg.sender] >= _numberOfUnits);
        require(tokenContract.balanceOf(address(this)) >= cost);
        require(tokenContract.transfer(msg.sender, cost));
        
        balanceOf[msg.sender] -= _numberOfUnits;
        deCS -= _numberOfUnits;

        emit Buy(msg.sender, _numberOfUnits);
    }

    function buyDarkEnergy(uint256 _numberOfUnits) public {
        uint256 cost = toGal(_numberOfUnits, deGal);
        require(tokenContract.balanceOf(msg.sender) >= cost);
        require(tokenContract.allowance(msg.sender, address(this)) >= cost);
        require(tokenContract.transferFrom(msg.sender, address(this), cost));
        
        balanceOf[msg.sender] += _numberOfUnits;
        deCS += _numberOfUnits;

        emit Sell(msg.sender, _numberOfUnits);
    }
    
    function distributeRankingAndStakingRewards(address[] memory _to, uint256[] memory _points) public {
        require(msg.sender == admin);
        uint256 totalPoints;
        uint256[] memory rewards = new uint256[](_points.length);
        
        uint256 stakingRewards = deSpent * spy / 10 ** 18;
        uint256 rankingRewards = deSpent - stakingRewards;
        
        for(uint256 i=0; i<_points.length; i++) {
            totalPoints += _points[i];
        }
        
        if(galStaked > 0) {
           	for(uint256 i=0; i<_points.length; i++) {
           	    uint256 stakingReward = stakingRewards*stakingOf[_to[i]].stake/galStaked;
	            rewards[i] += stakingReward;
	            balanceOf[_to[i]] += stakingReward;
	            deCS += stakingRewards;
	        }
        } else {
            rankingRewards += stakingRewards;
        }
        
        if(totalPoints > 0) {
	        for(uint256 i=0; i<_points.length; i++) {
	            uint256 rankingReward = rankingRewards*_points[i]/totalPoints;
	            rewards[i] += rankingReward;
	            balanceOf[_to[i]] += rankingReward;
	            deCS += rankingRewards;
	        }
	        
	        deSpent = 0;
        }
        
        emit Distribute(rewards);
    }
    
    function distributeReferralRewards(address[] memory _to, uint256[] memory _rewards) public {
        require(msg.sender == admin);
        uint256 totalRewards;
        
        for(uint256 i=0; i<_rewards.length; i++) {
            balanceOf[_to[i]] += _rewards[i];
            deCS += _rewards[i];
            totalRewards += _rewards[i];
        }
        
        deSpent -= totalRewards;
    }

	function stakeGal(uint256 _numberOfUnits) public {
	    require(tokenContract.balanceOf(msg.sender) >= _numberOfUnits);
        require(tokenContract.allowance(msg.sender, address(this)) >= _numberOfUnits);
        require(tokenContract.transferFrom(msg.sender, address(this), _numberOfUnits));
        
        stakingOf[msg.sender].stake += _numberOfUnits;
        stakingOf[msg.sender].deadline = now + (lockPeriod * 1 minutes);
        galStaked += _numberOfUnits;

        emit Stake(msg.sender, _numberOfUnits);
	}
	
	function unstakeGal(uint256 _numberOfUnits) public {
	    require(stakingOf[msg.sender].stake >= _numberOfUnits);
	    require(stakingOf[msg.sender].deadline <= now);
        require(tokenContract.balanceOf(address(this)) >= _numberOfUnits);
        require(tokenContract.transfer(msg.sender, _numberOfUnits));
        
        stakingOf[msg.sender].stake -= _numberOfUnits;
        galStaked -= _numberOfUnits;

        emit Unstake(msg.sender, _numberOfUnits);
	}

    function endMarket() public {
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));
        selfdestruct(admin);
    }

	function toGal(uint256 units, uint256 price) internal pure returns (uint256 z) {
        require(units == 0 || (z = units * price) / price == units);
        return z / 10 ** 18;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.7.0;

contract GalToken {
    string  public name = "Galactic Empires";
    string  public symbol = "GAL";
    string  public standard = "Gal Token v1.0";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * (uint256(10) ** decimals);
    

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

         emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
    
}