// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
//pragma experimental ABIEncoderV2;

import "./SMinter.sol";

contract SStaking is IStakingRewards2, Configurable {
    using SafeMath for uint;
    using TransferHelper for address;
    
    address public minter;
    address public token;
    
    uint override public totalSupply;
    mapping(address => uint) override public balanceOf;
    
    mapping(address => uint) override public stakeTimeOf;
    mapping(address => uint) override public spendTimeOf;

	function initialize(address governor, address _minter) public initializer {
	    super.initialize(governor);
	    
	    minter = _minter;
	    token  = Minter(_minter).token();
	}
    
    function stake(uint256 amount) virtual override external {
        uint oldBalance = balanceOf[msg.sender];
        uint newBalance = oldBalance.add(amount);
        stakeTimeOf[msg.sender] = now.sub(stakeAgeOf(msg.sender).mul(oldBalance).div(newBalance));
        spendTimeOf[msg.sender] = now.sub(spendAgeOf(msg.sender).mul(oldBalance).div(newBalance));

        token.safeTransferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender] = newBalance;
        totalSupply = totalSupply.add(amount);
        emit Staked(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) virtual override public {
        totalSupply = totalSupply.sub(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
    
    function exit() virtual override external {
        withdraw(balanceOf[msg.sender]);
        getReward();
    }

	function totalMinted() virtual override public view returns (uint) {
	    return IERC20(token).totalSupply().sub(IERC20(token).balanceOf(minter));
	}
	
	function weightOfGauge(address gauge) virtual override public view returns (uint) {
	    return SMinter(minter).quotas(gauge).mul(1 ether).div(IERC20(token).balanceOf(minter));
	}
	
	function stakingPerLPT(address gauge) virtual override external view returns (uint) {
	    return totalMinted().mul(weightOfGauge(gauge)).div(LiquidityGauge(gauge).totalSupply());
	}
	
	function stakeAgeOf(address account) virtual override public view returns (uint) {
	    return now.sub(stakeTimeOf[account]);
	}
	
	function factorOf(address account) virtual override external view returns (uint) {
	    uint age = stakeAgeOf(account);
	    if(age <= 5 days)
	        return age.mul(0.5 ether).div( 5 days).add(1.0 ether);
	    else if(age <= 30 days)
	        return age.sub( 5 days).mul(0.5 ether).div(25 days).add(1.5 ether);
        else if(age <= 80 days)
            return age.sub(30 days).mul(0.5 ether).div(50 days).add(2.0 ether);
        else
            return 2.5 ether;
	}

	function spendAgeOf(address account) virtual override public view returns (uint) {
	    return now.sub(spendTimeOf[account]);
	}
	
	function coinAgeOf(address account) virtual override public view returns (uint) {
	    return balanceOf[account].mul(spendAgeOf(account));
	}
	
    function spendCoinAge(address account, uint coinAge) virtual override external returns (uint) {
        require(SMinter(minter).quotas(msg.sender) > 0, 'No quota');
        if(coinAge > coinAgeOf(account))
            coinAge = coinAgeOf(account);
        spendTimeOf[account] = now.sub(coinAgeOf(account).sub(coinAge).div(balanceOf[account]));
        emit SpentCoinAge(msg.sender, account, coinAge);
        return coinAge;
    }

    function lastTimeRewardApplicable() virtual override external view returns (uint256) {}     // todo
    function rewardPerToken() virtual override external view returns (uint256) {}               // todo        
    function rewards(address account) virtual override external view returns (uint256) {}       // todo
    function earned(address account) virtual override external view returns (uint256) {}        // todo
    function getRewardForDuration() virtual override external view returns (uint256) {}         // todo
    function getReward() virtual override public {}                                             // todo
}