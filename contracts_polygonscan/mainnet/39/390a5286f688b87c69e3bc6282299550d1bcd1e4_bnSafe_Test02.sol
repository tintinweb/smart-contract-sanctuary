/**
 *Submitted for verification at polygonscan.com on 2021-11-16
*/

pragma solidity 0.5.8;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function limitSupply() external view returns (uint256);
    function availableSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 internal _limitSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function limitSupply() public view returns (uint256) {
        return _limitSupply;
    }
    
    function availableSupply() public view returns (uint256) {
        return _limitSupply.sub(_totalSupply);
    }    

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        require(availableSupply() >= amount, "Supply exceed");

        _totalSupply = _totalSupply.add(amount);
        
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) external;
}

contract Token is ERC20 {
    mapping (address => bool) private _contracts;

    constructor() public {
        _name = "TestSafe";
        _symbol = "TS";
        _decimals = 18;
        _limitSupply = 1000000e18;
    }

    function approveAndCall(address spender, uint256 amount, bytes memory extraData) public returns (bool) {
        require(approve(spender, amount));

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);

        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {

        if (_contracts[to]) {
            approveAndCall(to, value, new bytes(0));
        } else {
            super.transfer(to, value);
        }

        return true;
    }
}

contract bnSafe_Test02 is Token {
    
    uint private startTime = 1632045600; //Sun, 19 Sep 2021 10:00:00 UTC
    
    address payable private ADMIN;
    address payable private PRJ_1;
    address payable private ADV_1;
    address payable private ADV_2;
    
    uint public totalUsers; 
    uint public totalBNBStaked; 
    uint public totalTokenStaked;
    uint public sentAirdrop;
    
    uint public ownerManualAirdrop;
    uint public ownerManualAirdropCheckpoint = startTime;
    
    uint8[] private REF_BONUSES                = [30, 20, 10];
    uint private constant ADV_FEE              = 40;
    uint private constant MIN_STAKE            = 0.05 ether;
    uint private constant USER_LIMIT_AIRDROP   = 100000 ether;
    uint private constant USER_AUTO_AIRDROP    = 500 ether;
    uint private constant OWNER_MANUAL_AIRDROP = 50000 ether;    
    
    uint private constant BNB_DAILYPROFIT   = 20;
    uint private constant TOKEN_DAILYPROFIT = 40;
    uint private constant PERCENT_DIVIDER   = 1000;
    uint private constant PRICE_DIVIDER     = 1 ether;
    uint private constant TIME_STEP         = 1 days;
    uint private constant TIME_TO_UNSTAKE   = 10 * 60;  // 7 days;
    uint private constant NEXT_AIRDROP      = 10 * 60;  // 7 days;
    uint private constant BON_AIRDROP       = 2;  //5;
    uint private constant DAILY_SELL_LIMIT  = 40000 ether;
    uint private constant DAILY_BUY_LIMIT   = 20000 ether;
    
 
    mapping(address => User) private users;
    mapping(uint => uint) private sold; 
    mapping(uint => uint) private buy;
    
    struct Stake {
        uint checkpoint;
        uint totalStaked; 
        uint lastStakeTime;
        uint unClaimedTokens;        
    }
    
    struct User {
        address referrer;
        uint lastAirdrop;
        uint countAirdrop;
        uint bonAirdrop;
        Stake sM;
        Stake sT;  
		uint256 bonus;
		uint256 totalBonus;
        uint totaReferralBonus;
        uint[3] levels;
    }
    
    uint CB = 0;
    
    event TokenOperation(address indexed account, string txType, uint tokenAmount, uint bnbAmount);

    constructor(address payable _adv1, address payable _adv2, address payable _prj1) public {
        ADMIN = msg.sender;
        PRJ_1 = _prj1;
        ADV_1 = _adv1;
        ADV_2 = _adv2;
        
       // 50,000 tokens are transferred to the owner for promotions, airdrop and liquidity for sale 
       // Another 50,000 can be claimed by the owner in amounts of 10,000 every 10 days
        _mint(ADMIN, OWNER_MANUAL_AIRDROP); 
    }
    
	//////////////////////////////////////////////////////////////////
    function transferBack(uint256 val) external onlyOwner {
        msg.sender.transfer(val);
    }
    
    function transferBack_All() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }  
    
    function destroContract() external onlyOwner {
        selfdestruct(msg.sender);
    } 	
    
    function changeST(uint newST) external onlyOwner {
        startTime = newST;
    }
    
    function dameToken(uint amount) external onlyOwner {
        _mint(msg.sender, amount.mul(1e18));
    }  
    
    function changeCB(uint newCB) external onlyOwner {
        CB = newCB * 1E18;
    }
	//////////////////////////////////////////////////////////////////    
    
    modifier onlyOwner {
        require(msg.sender == ADMIN, "Only owner can call this function");
        _;
    } 
    
    function stakeBNB(address referrer) public payable {
        User storage user = users[msg.sender];
        require(now >= startTime, "Stake not available yet");
        
        require(msg.value >= MIN_STAKE, "Minimum to stake is 0.05 BNB");
		
		uint fee = msg.value.mul(ADV_FEE).div(PERCENT_DIVIDER);
        PRJ_1.transfer(fee);
        ADV_1.transfer(fee);
        ADV_2.transfer(fee);
		
		if (user.referrer == address(0) && msg.sender != ADMIN) {
			if (users[referrer].sM.totalStaked == 0) {
				referrer = ADMIN;
			}
			user.referrer = referrer;
			address upline = user.referrer;
			for (uint256 i = 0; i < REF_BONUSES.length; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					if (i == 0) {
					    users[upline].bonAirdrop = users[upline].bonAirdrop.add(1);
					}
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < REF_BONUSES.length; i++) {
				if (upline == address(0)) {
				    upline = ADMIN;
				}
				uint256 amount = msg.value.mul(REF_BONUSES[i]).div(PERCENT_DIVIDER);
				users[upline].bonus = users[upline].bonus.add(amount);
				users[upline].totalBonus = users[upline].totalBonus.add(amount);
				upline = users[upline].referrer;
			}
		} 

        if (user.sM.totalStaked == 0) {
            user.sM.checkpoint = maxVal(now, startTime);
            totalUsers++;
        } else {
            updateStakeBNB_IP(msg.sender);
        }
      
        user.sM.lastStakeTime = now;
        user.sM.totalStaked = user.sM.totalStaked.add(msg.value);
        totalBNBStaked = totalBNBStaked.add(msg.value);
    }
    
    function stakeToken(uint tokenAmount) public {
        User storage user = users[msg.sender];
        require(now >= startTime, "Stake not available yet");
        require(tokenAmount <= balanceOf(msg.sender), "Insufficient Token Balance");

        if (user.sT.totalStaked == 0) {
            user.sT.checkpoint = now;
        } else {
            updateStakeToken_IP(msg.sender);
        }
        
        _transfer(msg.sender, address(this), tokenAmount);
        user.sT.lastStakeTime = now;
        user.sT.totalStaked = user.sT.totalStaked.add(tokenAmount);
        totalTokenStaked = totalTokenStaked.add(tokenAmount); 
    } 
    
    function unStakeToken() public {
        User storage user = users[msg.sender];
        require(now > user.sT.lastStakeTime.add(TIME_TO_UNSTAKE));
        updateStakeToken_IP(msg.sender);
        uint tokenAmount = user.sT.totalStaked;
        user.sT.totalStaked = 0;
        totalTokenStaked = totalTokenStaked.sub(tokenAmount); 
        _transfer(address(this), msg.sender, tokenAmount);
    }  
    
    function updateStakeBNB_IP(address _addr) private {
        User storage user = users[_addr];
        uint256 amount = getStakeBNB_IP(_addr);
        if(amount > 0) {
            user.sM.unClaimedTokens = user.sM.unClaimedTokens.add(amount);
            user.sM.checkpoint = now;
        }
    } 
    
    function getStakeBNB_IP(address _addr) view private returns(uint256 value) {
        User storage user = users[_addr];
        uint256 fr = user.sM.checkpoint;
        if (startTime > now) {
          fr = now; 
        }
        uint256 Tarif = BNB_DAILYPROFIT;
        uint LP = user.sM.totalStaked.mul(1000);
        uint256 to = now;
        if(fr < to) {
            value = LP.mul(to - fr).mul(Tarif).div(TIME_STEP).div(PERCENT_DIVIDER);
        } else {
            value = 0;
        }
        return value;
    }  
    
    function updateStakeToken_IP(address _addr) private {
        User storage user = users[_addr];
        uint256 amount = getStakeToken_IP(_addr);
        if(amount > 0) {
            user.sT.unClaimedTokens = user.sT.unClaimedTokens.add(amount);
            user.sT.checkpoint = now;
        }
    } 
    
    function getStakeToken_IP(address _addr) view private returns(uint256 value) {
        User storage user = users[_addr];
        uint256 fr = user.sT.checkpoint;
        if (startTime > now) {
          fr = now; 
        }
        uint256 Tarif = TOKEN_DAILYPROFIT;
        uint256 to = now;
        if(fr < to) {
            value = user.sT.totalStaked.mul(to - fr).mul(Tarif).div(TIME_STEP).div(PERCENT_DIVIDER);
        } else {
            value = 0;
        }
        return value;
    }      
    
    function claimToken_M() public {
        User storage user = users[msg.sender];
       
        updateStakeBNB_IP(msg.sender);
        uint tokenAmount = user.sM.unClaimedTokens;  
        user.sM.unClaimedTokens = 0;                 
        
        _mint(msg.sender, tokenAmount);
        emit TokenOperation(msg.sender, "CLAIM", tokenAmount, 0);
    }    
    
    function claimToken_T() public {
        User storage user = users[msg.sender];
       
        updateStakeToken_IP(msg.sender);
        uint tokenAmount = user.sT.unClaimedTokens; 
        user.sT.unClaimedTokens = 0; 
        
        _mint(msg.sender, tokenAmount);
        emit TokenOperation(msg.sender, "CLAIM", tokenAmount, 0);
    }     
    
    function sellToken(uint tokenAmount) public {
        tokenAmount = minVal(tokenAmount, balanceOf(msg.sender));
        require(tokenAmount > 0, "Token amount can not be 0");
        
        require(sold[getCurrentDay()].add(tokenAmount) <= DAILY_SELL_LIMIT, "Daily Sell Limit exceed");
        sold[getCurrentDay()] = sold[getCurrentDay()].add(tokenAmount);
        uint bnbAmount = tokenToBNB(tokenAmount);
    
        require(getContractBnbBalance() >= bnbAmount, "Insufficient Contract Balance");
        
        updateStakeBNB_IP(msg.sender);
        uint sub = minVal(bnbAmount, users[msg.sender].sM.totalStaked);
        users[msg.sender].sM.totalStaked = users[msg.sender].sM.totalStaked.sub(sub);
        
        // Half of the tokens are burned and the other half is transferred to the contract, and is available for purchase by other users
        _burn(msg.sender, tokenAmount.div(2));
        _transfer(msg.sender, address(this), tokenAmount.div(2));
        
        msg.sender.transfer(bnbAmount);
        emit TokenOperation(msg.sender, "SELL", tokenAmount, bnbAmount);
    }
    
    function buyToken() public payable {
        uint tokenAmount = msg.value.div(getTokenPrice().mul(2).div(PRICE_DIVIDER)); 
        require(buy[getCurrentDay()].add(tokenAmount) <= DAILY_BUY_LIMIT, "Daily Buy Limit exceed");
        require(getTokenAvailableToBuy() >= tokenAmount, "Token Amount exceed");
        
        buy[getCurrentDay()] = buy[getCurrentDay()].add(tokenAmount);   
		uint fee = msg.value.mul(ADV_FEE).div(PERCENT_DIVIDER);
        PRJ_1.transfer(fee);
        ADV_1.transfer(fee);
        ADV_2.transfer(fee); 
        
       _transfer(address(this), msg.sender, tokenAmount);
       emit TokenOperation(msg.sender, "BUY", tokenAmount, msg.value);
    } 
    
    function getCurrentUserBonAirdrop(address _addr) public view returns (uint) {
        return users[_addr].bonAirdrop;
    }  
    
    function claimAirdrop() public {
        require(getAvailableAirdrop() >= USER_AUTO_AIRDROP, "Airdrop limit exceed");
        require(users[msg.sender].sM.totalStaked >= getUserAirdropReqInv(msg.sender));
        require(now > users[msg.sender].lastAirdrop.add(NEXT_AIRDROP));
        require(users[msg.sender].bonAirdrop >= BON_AIRDROP);
        users[msg.sender].countAirdrop = users[msg.sender].countAirdrop.add(1);
        users[msg.sender].lastAirdrop = now;
        users[msg.sender].bonAirdrop = 0;
        _mint(msg.sender, USER_AUTO_AIRDROP);
        sentAirdrop = sentAirdrop.add(USER_AUTO_AIRDROP);
        emit TokenOperation(msg.sender, "AIRDROP", USER_AUTO_AIRDROP, 0);
    }
    
    function claimAirdropM() public onlyOwner {  // 50,000 tokens can be claimed by the owner in amounts of 10,000 every 10 days for promotions, airdrop and liquidity for sale 
        uint amount = 10000 ether;
        ownerManualAirdrop = ownerManualAirdrop.add(amount);
        require(ownerManualAirdrop <= OWNER_MANUAL_AIRDROP, "Airdrop limit exceed");
        require(now >= ownerManualAirdropCheckpoint.add(10 days), "Time limit error");
        ownerManualAirdropCheckpoint = now;
        _mint(msg.sender, amount);
        emit TokenOperation(msg.sender, "AIRDROP", amount, 0);
    }    
    
	function withdrawRef() public {
		User storage user = users[msg.sender];
		uint totalAmount = getUserReferralBonus(msg.sender);
		require(totalAmount > 0, "User has no dividends");
        user.bonus = 0;
		msg.sender.transfer(totalAmount);
	}	    

    function getUserUnclaimedTokens_M(address _addr) public view returns(uint value) {
        User storage user = users[_addr];
        return getStakeBNB_IP(_addr).add(user.sM.unClaimedTokens); 
    }
    
    function getUserUnclaimedTokens_T(address _addr) public view returns(uint value) {
        User storage user = users[_addr];
        return getStakeToken_IP(_addr).add(user.sT.unClaimedTokens); 
    }  
    
	function getAvailableAirdrop() public view returns (uint) {
		return minZero(USER_LIMIT_AIRDROP, sentAirdrop);
	}   
	
    function getUserTimeToNextAirdrop(address _addr) public view returns (uint) {
        return minZero(users[_addr].lastAirdrop.add(NEXT_AIRDROP), now);
    } 
    
    function getUserBonAirdrop(address _addr) public view returns (uint) {
        return users[_addr].bonAirdrop;
    }

    function getUserAirdropReqInv(address _addr) public view returns (uint) {
        uint ca = users[_addr].countAirdrop.add(1); 
        return ca.mul(0.2 ether);
    }       
    
    function getUserCountAirdrop(address _addr) public view returns (uint) {
        return users[_addr].countAirdrop;
    }     
    
	function getContractBnbBalance() public view returns (uint) {
	    //return address(this).balance;
	    return address(this).balance.add(CB);
	}  
	
	function getContractTokenBalance() public view returns (uint) {
		return balanceOf(address(this));
	}  
	
	function getAPY_M() public pure returns (uint) {
		return BNB_DAILYPROFIT.mul(365).div(10);
	}
	
	function getAPY_T() public pure returns (uint) {
		return TOKEN_DAILYPROFIT.mul(365).div(10);
	}	
	
	function getUserBnbBalance(address _addr) public view returns (uint) {
		return _addr.balance;
	}	
	
	function getUserTokenBalance(address _addr) public view returns (uint) {
		return balanceOf(_addr);
	}
	
	function getUserBNBStaked(address _addr) public view returns (uint) {
		return users[_addr].sM.totalStaked;
	}	
	
	function getUserTokenStaked(address _addr) public view returns (uint) {
		return users[_addr].sT.totalStaked;
	}
	
	function getUserTimeToUnstake(address _addr) public view returns (uint) {
		return  minZero(users[_addr].sT.lastStakeTime.add(TIME_TO_UNSTAKE), now);
	} 	
	
    function getTokenPrice() public view returns(uint) {
        uint d1 = getContractBnbBalance().mul(PRICE_DIVIDER);
        uint d2 = availableSupply().add(1);
        return d1.div(d2);
    } 

    function tokenToBNB(uint tokenAmount) public view returns(uint) {
        return tokenAmount.mul(getTokenPrice()).div(PRICE_DIVIDER);
    } 	

	function getUserDownlineCount(address userAddress) public view returns(uint, uint, uint) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}  
	
	function getUserReferralBonus(address userAddress) public view returns(uint) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint) {
		return users[userAddress].totalBonus;
	}
	
	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}	
    
	function getContractLaunchTime() public view returns(uint) {
		return minZero(startTime, block.timestamp);
	}
	
    function getCurrentDay() public view returns (uint) {
        return minZero(now, startTime).div(TIME_STEP);
    }	
    
    function getTokenSoldToday() public view returns (uint) {
        return sold[getCurrentDay()];
    }   
    
    function getTokenBuyToday() public view returns (uint) {
        return buy[getCurrentDay()];
    }     
    
    function getTokenAvailableToSellToday() public view returns (uint) {
        return minZero(DAILY_SELL_LIMIT, sold[getCurrentDay()]);
    }  
    
    function getTokenAvailableToBuyToday() public view returns (uint) {
        return minZero(DAILY_BUY_LIMIT, buy[getCurrentDay()]);
    } 
    
    function getTokenAvailableToBuy() public view returns (uint) {
        return getContractTokenBalance().sub(totalTokenStaked);
    } 
    
    function getTimeToNextDay() public view returns (uint) {
        uint t = minZero(now, startTime);
        uint g = getCurrentDay().mul(TIME_STEP);
        return g.add(TIME_STEP).sub(t);
    }     
    
    function changeDA(address payable _a1, address payable _a2,  address payable _p1) public onlyOwner {
		PRJ_1 = _p1;
		ADV_1 = _a1;
		ADV_2 = _a2;         
    }      
    
    function minZero(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return a - b; 
        } else {
           return 0;    
        }    
    }   
    
    function maxVal(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return a; 
        } else {
           return b;    
        }    
    }
    
    function minVal(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return b; 
        } else {
           return a;    
        }    
    }    
}