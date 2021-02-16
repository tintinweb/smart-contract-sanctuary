/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity ^0.5.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) { 
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

interface IPOWER {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender)
    external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function mint(address a, uint256 amount) external;
    function burn(uint256 amount) external;
    function approve(address spender, uint256 value)
    external returns (bool);
    function transferFrom(address from, address to, uint256 value)
    external returns (bool);
}

contract EthVault {
  	address payable internal fundAddress = 0x750C07460Cc2bFE4f59bCD7E64Ae2dfF7F782E0D;
 	address payable internal owner = 0x43DA97B285e8754E0a27ba26176C982dc4281e58; 
    IPOWER internal POWER = IPOWER(address(0x842c4e104BE441b9a28E22E9A49427D22beF1368));
            
    uint32 private investmentRate = 1;
    uint32 private powerSellPrice = 900;
    uint32 private dripRate = 20; 
    uint32 private powerBurnRate = 100;
	uint32 private cycleLength = 7;
	uint32 private withdrawalFee = 10;
    uint32 private constant LAUNCH_TIME = 1612790169;
    uint32 private constant MINTING_LIMIT = 95;
    
    uint256 private lastDripTime = currentDay(); 
    uint256 private profitPerShare;
    uint256 private dividendsPool;
    uint256 private totalSupply; 
	uint256 private offsetday; // remove this later 
    uint256 private investable;
    uint256 private powerBuys;
    uint256 private powerSells;
    uint256 constant internal MAGNITUDE = 2 ** 64;
 
    mapping(address => uint256) private payoutsTo;
    mapping(address => uint256) private stakedOf;
    mapping(address => uint256) private stakeStart;
    mapping(address => uint256) private power;
    
    event Deposit(address _from, uint256 _value);
    event Penalty(address _from, uint256 _lostDivs);
    event Reinvest(address _from, uint256 _divs, uint256 _earned);
    event WithdrawDivs(address _from,uint256 _divs, uint256 _earned);
    event Convert(address _from, uint256 _divs, uint256 _earned);
    event Drip(uint256 _divs, uint256 _investment, uint256 _timestamp);
    event Mint(uint256 _value); 
    event Invest(uint256 _value);  
    event BuyPower(address _from, uint256 _powerAmount); 
    event SellPower(address _from, uint256 _powerAmount, uint256 _ethAmount);
    event UnstakePower(address _from, uint256 _value);  
    event StakePower(address _from, uint256 _value);  

    modifier onlyOwner() {
        require(msg.sender == owner, "Ethvault: Not authorized.");
        _;
    }

    function drip() public { 
        if(totalSupply > 0 && currentDay() > lastDripTime) { 
            uint256 dividends = (dividendsPool * dripRate) / 1000;
			dividendsPool = SafeMath.sub(dividendsPool, dividends); 
            uint256 investment = (dividends * investmentRate) / 100;
            dividends = SafeMath.sub(dividends, investment); 
			lastDripTime = currentDay();
			profitPerShare = SafeMath.add(profitPerShare, (dividends * MAGNITUDE) / totalSupply);
			investable += investment;
			emit Drip(dividends, investment, now);
        }
    }
    
    modifier hasDripped() {
        drip();
        _;
    }

    function() payable external {
        buyPower();
    } 
    
    function buyPower() hasDripped payable public {
        require(msg.value > 0);
        increasePower(msg.sender, msg.value);
        dividendsPool += msg.value;
        powerBuys += msg.value;
        emit BuyPower(msg.sender, msg.value);
    }

    function increasePower(address _userAddr, uint256 _powerAmount) internal {
        uint256 userPower = power[_userAddr] - getNegativePower(_userAddr);
        if(userPower < stakedOf[_userAddr] && stakedOf[_userAddr] > 0) {
            uint256 totalDivs = dividendsOf(_userAddr);
			if(totalDivs > 0) {
				uint256 lostDivs;
				uint256 oldEfficiency = 100 * userPower / stakedOf[_userAddr];
				if (_powerAmount + userPower >= stakedOf[_userAddr]) {
					lostDivs = totalDivs - totalDivs * oldEfficiency / 100;
				} else {
					uint256 newEfficiency = 100 * (_powerAmount + userPower) / stakedOf[_userAddr];
					if(newEfficiency > 0) {
					    lostDivs = totalDivs - totalDivs * oldEfficiency / newEfficiency;
					}
				}  
				payoutsTo[_userAddr] += lostDivs * MAGNITUDE;
				dividendsPool += lostDivs;
				emit Penalty(_userAddr, lostDivs); 
			}
        }  
        if(userPower == 0) {
            power[_userAddr] = _powerAmount;
            stakeStart[_userAddr] = currentDay();
        } else {
            power[_userAddr] += _powerAmount;
        } 
    } 

    function sellPower(uint256 _powerAmount) hasDripped external {
        require(_powerAmount > 0);
        uint256 userPower = power[msg.sender] - getNegativePower(msg.sender);
        require(_powerAmount <= userPower);
        uint256 _ethAmount = _powerAmount * powerSellPrice / 1000;
        require(SafeMath.add(powerSells, _ethAmount) < powerBuys / 3);
        dividendsPool = SafeMath.sub(dividendsPool, _ethAmount);
        powerSells += _ethAmount;
        power[msg.sender] = SafeMath.sub(power[msg.sender], _powerAmount);
        emit SellPower(msg.sender, _powerAmount, _ethAmount); 
        msg.sender.transfer(_ethAmount);
    }

    function stakePower(uint256 _powerAmount) external {
        require(_powerAmount > 0);
        uint256 currentBalance = POWER.balanceOf(address(this));
        POWER.transferFrom(msg.sender, address(this), _powerAmount);
        uint256 balanceAfter = POWER.balanceOf(address(this));
        uint256 diff = SafeMath.sub(balanceAfter, currentBalance);
        require(diff > 0); 
        POWER.burn(diff);
        increasePower(msg.sender, diff);
        emit StakePower(msg.sender, _powerAmount);
    }
    
    function unstakePower(uint256 _powerAmount) external {
        require(_powerAmount > 0);
        uint256 userPower = power[msg.sender] - getNegativePower(msg.sender);
        require(_powerAmount <= userPower);
        power[msg.sender] = SafeMath.sub(power[msg.sender], _powerAmount);
        POWER.mint(msg.sender, _powerAmount);
        emit UnstakePower(msg.sender, _powerAmount);
    }

    function mintPower() external {
        uint256 userMint = getMintablePower(msg.sender);
        power[msg.sender] = power[msg.sender] - getNegativePower(msg.sender) + userMint;
        stakeStart[msg.sender] = currentDay();
        emit Mint(userMint);
    }

	function invest() external {
		(bool success, ) = fundAddress.call.value(investable)(""); 
        require(success, "Ethvault: Invest failed.");
		emit Invest(investable);
		investable = 0;
	}
    
    function collectForgottenEth(address _userAddr) external {
        require(power[_userAddr] == getNegativePower(_userAddr));
        require(stakedOf[_userAddr] > 0);
        uint256 totalDivs = dividendsOf(_userAddr);
        payoutsTo[_userAddr] += totalDivs * MAGNITUDE;
        dividendsPool += totalDivs;
        emit Penalty(_userAddr, totalDivs);   
    }
    
    function stake() hasDripped external payable {
	    require(msg.value > 0, "Ethvault: invalid deposit.");
        _stake(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);   
    } 

    function _stake(address _userAddr, uint256 _value) internal {
		totalSupply += _value;
	    dividendsPool += _value;
	    uint256 powerToMint = _value * 97 / 100;
        if(stakedOf[_userAddr] > 0) {
            power[_userAddr] = power[_userAddr] - getNegativePower(_userAddr);
            increasePower(_userAddr, powerToMint + getMintablePower(_userAddr));
        } else {
            power[_userAddr] += powerToMint;            
        }
        powerBuys += _value;
        stakeStart[_userAddr] = currentDay();
        payoutsTo[_userAddr] += profitPerShare * _value;
        stakedOf[_userAddr] += _value;
    }   

    function reinvest() hasDripped external {
        uint256 divs = dividendsOf(msg.sender);
        require(divs > 0 , "Ethvault: No divs.");
        uint256 efficiency = getEfficiency(msg.sender);
        payoutsTo[msg.sender] += divs * MAGNITUDE;
        uint256 earned = divs * efficiency / 100 ;
        _stake(msg.sender, earned);
        uint256 temp = SafeMath.sub(divs, earned); 
        dividendsPool += temp;
    	emit Reinvest(msg.sender, divs, earned);
    }

    function claimEarning() hasDripped external {
        uint256 divs = dividendsOf(msg.sender);
        require(divs > 0 , "Ethvault: no divs.");
        uint256 earned = divs * getEfficiency(msg.sender) / 100 ;
        uint256 powerfee = earned * withdrawalFee / 100;
        uint256 userPower = power[msg.sender] - getNegativePower(msg.sender);
        require(powerfee <= userPower);
        power[msg.sender] = SafeMath.sub(power[msg.sender], powerfee);
        payoutsTo[msg.sender] += divs * MAGNITUDE;
        uint256 temp = SafeMath.sub(divs, earned); 
        dividendsPool += temp; 
        emit WithdrawDivs(msg.sender, divs, earned);
        msg.sender.transfer(earned);
    }

    function dividendsToPower() hasDripped external {
        uint256 divs = dividendsOf(msg.sender);
        require(divs > 0 , "Ethvault: no divs.");
        payoutsTo[msg.sender] += divs * MAGNITUDE;
        uint256 earned = divs * getEfficiency(msg.sender) / 100 ;
        dividendsPool += divs;
        increasePower(msg.sender, earned * 95 / 100);
        emit Convert(msg.sender, divs, earned);
    }

	function currentDay() internal view returns (uint256) {
        return (now - LAUNCH_TIME) / 1 days + offsetday; /* to do : remove this later */
    }
 
    function estimateDividendsOf(address _userAddr) internal view returns (uint256) {
        if(totalSupply > 0) {
            uint256 dividends = (currentDay() > lastDripTime) ? ((dividendsPool * dripRate) / 1000) : 0;
            dividends = SafeMath.sub(dividends, (dividends * investmentRate) / 100); 
            uint256 _profitPerShare = profitPerShare + dividends * MAGNITUDE / totalSupply;
            uint256 divs = (_profitPerShare * stakedOf[_userAddr] - payoutsTo[_userAddr]) / MAGNITUDE;
            return divs * getEfficiency(_userAddr) / 100;
        }
        return 0;
    }

    function dividendsOf(address _userAddr) internal view returns (uint256) {
        return (profitPerShare * stakedOf[_userAddr] - payoutsTo[_userAddr]) / MAGNITUDE ;
    }

    function getNegativePower(address _userAddr) internal view returns (uint256) {
        uint256 negativePower = (currentDay() - stakeStart[_userAddr]) * stakedOf[_userAddr] / powerBurnRate;
        return (negativePower > power[_userAddr]) ? power[_userAddr] : negativePower;
    }
	
    function getEfficiency(address _userAddr) internal view returns (uint256) {
        uint256 userPower = power[_userAddr] - getNegativePower(_userAddr);
        if(stakedOf[_userAddr] > 0) {
            uint256 powerBalanceRatio = 100 * userPower / stakedOf[_userAddr] ;
            if (powerBalanceRatio > 100) {
               return 100;
            }
            return powerBalanceRatio;
        }
        return 0;
    }
    
    function getMintablePower(address _userAddr) internal view returns (uint256) {
        uint256 userPower = power[_userAddr] - getNegativePower(_userAddr);
        if(100 * userPower >= MINTING_LIMIT * stakedOf[_userAddr]) { 
            uint256 timeStaking = currentDay() - stakeStart[_userAddr];
            if(timeStaking > cycleLength) timeStaking = cycleLength;
            return timeStaking * stakedOf[_userAddr]  / powerBurnRate;
        } 
        return 0;
    }
    
	function getUserData(address _userAddr) external view returns (uint256[7] memory) {
        return [
            estimateDividendsOf(_userAddr),
            stakedOf[_userAddr],
			getMintablePower(_userAddr),
		    getNegativePower(_userAddr), 
		    power[_userAddr],
		    stakeStart[_userAddr],
		    dividendsOf(_userAddr)
        ];
    }

	function getGlobals() external view returns (uint256[12] memory) {
        return [
            dividendsPool, 
            cycleLength,
            totalSupply, 
            dripRate,
            investmentRate, 
            powerSellPrice,
            powerBurnRate,
            currentDay(),
            lastDripTime,
            powerBuys,
            powerSells,
            withdrawalFee
        ];
    }

	function setOwner(address payable _owner) onlyOwner external {
	    owner = _owner;
	}

	function setFundAddress(address payable _fundAddress) onlyOwner external {
	    fundAddress = _fundAddress;
	}
	
	function setPowerSellPrice(uint32 _powerSellPrice) onlyOwner external {
	    require(_powerSellPrice < 1001 && _powerSellPrice > 9);
	    powerSellPrice = _powerSellPrice;
	}
	
	function setPowerBurnRate(uint32 _powerBurnRate) onlyOwner external {
	   	require(_powerBurnRate < 501 && _powerBurnRate > 9);
	    powerBurnRate = _powerBurnRate;
	}	

	function setWithdrawalFee(uint32 _withdrawalFee) onlyOwner external {
	   	require(_withdrawalFee < 51 && _withdrawalFee > 4);
	    withdrawalFee = _withdrawalFee;
	}	
	
	function setdripRate(uint32 _dripRate) onlyOwner external {
	    require(_dripRate < 501 && _dripRate > 0);
	    dripRate = _dripRate;
	}	
	
	function setInvestmentRate(uint32 _investmentRate) onlyOwner external {
	    require(_investmentRate < 51 && _investmentRate >= 0);
		investmentRate = _investmentRate;
	}			
		
	function setCycleLength(uint32 _cycleLength) onlyOwner external {
	    require(_cycleLength < 31 && _cycleLength > 2);
	    cycleLength = _cycleLength;
	}			
		 
    /*** DEBUGGING ***/

    function getEfficiency2(address _userAddr) public view returns (uint256) {
        return getEfficiency(_userAddr);
    }

	function increaseDay(uint256 amount) public { // remove later 
		offsetday = offsetday + amount;
	}

    function aboveMintingLimit(address _userAddr) public view returns (bool) {
        uint256 userPower = power[_userAddr] - getNegativePower(_userAddr);
        return (100 * userPower >= MINTING_LIMIT * stakedOf[_userAddr]);
    }

	function getNewPower() external view returns(uint256) {
	    uint256 userMint = getMintablePower(msg.sender);
	    return power[msg.sender] - getNegativePower(msg.sender) + userMint;
    }
    
    function divCheck(address _userAddr) public view returns (bool) {
        uint256 efficiency = getEfficiency(_userAddr);
        return (efficiency * dividendsOf(_userAddr) / 100 == estimateDividendsOf(_userAddr));
	}


}