/**
 *Submitted for verification at BscScan.com on 2021-10-12
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
        _name = "CryptoGuard";
        _symbol = "CG";
        _decimals = 18;
        _limitSupply = 180000000e18;
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


contract CryptoGuard is Token {

    uint private startTime = 1633716000; //Fri, 8 Oct 2021 :00:00 UTC
    
    address payable private ADMIN;
    address payable private PRJ_1;
    address payable private ADV_1;
    address payable private ADV_2;

    uint256 public totalUsers; 
    uint256 public totalStaked;
    uint256 public totalBNBStaked; 
    uint256 public totalTokenStaked;
    uint256 public sentToken;
    uint256 public totalRefBonus;
    uint public sentAirdrop;

    uint256 public ownerManualAirdrop;
    uint256 public ownerManualAirdropCheckpoint = startTime;

    uint256 private MIN_INVEST = 1e16; //0.01BNB
    uint private constant ADV_FEE           = 40;
    uint private constant LIMIT_AIRDROP     = 100000 ether;
    uint private constant MANUAL_AIRDROP    = 50000 ether;    
    uint private constant USER_AIRDROP      = 100 ether;
    uint private constant MATIC_DAILYPROFIT = 20;
    uint private constant TOKEN_DAILYPROFIT = 40;
    uint private constant PERCENT_DIVIDER   = 1000;
    uint private constant PRICE_DIVIDER     = 1 ether;
    uint private constant TIME_STEP         = 1 days;
    uint private constant TIME_TO_UNSTAKE   = 7 days;
    uint private constant NEXT_AIRDROP      = 7 days;
    uint private constant BON_AIRDROP       = 5;
    uint private constant SELL_LIMIT        = 40000 ether; 
    uint256 constant public PERCENT_STEP = 3; 

    uint256 private REF_BONUS_PLAN1 = 1000;
    uint256 private REF_PDAY_PLAN1 = 20;
    uint256 private REF_DAYS_PLAN1 = 50 days;
    
    uint256 private REF_BONUS_PLAN2 = 500;
    uint256 private REF_PDAY_PLAN2 = 20;
    uint256 private REF_DAYS_PLAN2 = 25 days;
    
    uint256 private REF_BONUS_PLAN3 = 240;
    uint256 private REF_PDAY_PLAN3 = 20;
    uint256 private REF_DAYS_PLAN3 = 12 days;
    

    uint256 private REF_TOKEN_BONUS = 500;
    uint256 private TOKEN_EACH_PLAN = 30000;
    uint256 private TOKEN_PDAY_PLAN1 = 300;
    uint256 private TOKEN_PDAY_PLAN2 = 1000;
    uint256 private TOKEN_PDAY_PLAN3 = 2500;
    

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    struct Stake {
        uint checkpoint;
        uint totalStaked; 
        uint lastStakeTime;
        uint unClaimedTokens;        
    }


    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		uint256 checkpointHold;
		address referrer;
		uint256[3] levels;
        uint lastAirdrop;
        uint countAirdrop;
        uint bonAirdrop;
        Stake sM;
        Stake sT;  
		uint256 bonus;
		uint256 totalBonus;
		uint256 totalPlanWithdrawn;
		uint256 totalHoldWithdrawn;
        uint totaReferralBonus;
	}

	mapping (address => User) internal users;
    mapping(uint => uint) private sold; 

    event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event TokenOperation(address indexed account, string txType, uint tokenAmount, uint trxAmount);

    modifier onlyOwner {
        require(msg.sender == ADMIN, "Only owner can call this function");
        _;
    } 

    constructor() public{

        ADMIN=msg.sender;
        PRJ_1=address(0x00000000000000);
        ADV_1=address(0x00000000000000);
        ADV_2=address(0x00000000000000);

        plans.push(Plan(100, 20));
        plans.push(Plan(30, 50));
        plans.push(Plan(12, 100));
        plans.push(Plan(50, 40));
        plans.push(Plan(15, 100));
        plans.push(Plan(6, 200));

    }

	function invest(address referrer, uint8 plan) public payable {
		require(block.timestamp > startTime, "Contract not start yet");	
		require(plan < 6, "Invalid plan");
		
		User storage user = users[msg.sender];
	
		uint investAmount;
		
		if (plan < 3) {
		    investAmount = msg.value;
		} else {
		    require(msg.value == 0, "Amount must be 0");
		    investAmount = getUserDividends(msg.sender);
		    user.checkpoint = block.timestamp;
		}		
		
		require(investAmount >= MIN_INVEST);

		uint256 fee = investAmount.mul(ADV_FEE).div(PERCENT_DIVIDER);
		ADV_1.transfer(fee);
		ADV_2.transfer(fee);
		PRJ_1.transfer(fee);
		
		if (user.referrer == address(0) && msg.sender != ADMIN) {
			if (users[referrer].deposits.length == 0) {
				referrer = ADMIN;
			}
			user.referrer = referrer;
			
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
				if (upline == address(0)) {
				    upline = ADMIN;
				}
				
				uint amount = investAmount.mul(REF_BONUS_PLAN1).div(PERCENT_DIVIDER);
				
				users[upline].bonus = users[upline].bonus.add(amount);
				users[upline].totalBonus = users[upline].totalBonus.add(amount);
				emit RefBonus(upline, msg.sender, 1, amount);
				upline = users[upline].referrer;
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			user.checkpointHold = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, investAmount);
		user.deposits.push(Deposit(plan, percent, investAmount, profit, block.timestamp, finish));

		totalStaked = totalStaked.add(investAmount);
		emit NewDeposit(msg.sender, plan, percent, investAmount, profit, block.timestamp, finish);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);
		require(totalAmount > 0, "User has no dividends");
		
		user.checkpoint = block.timestamp;
		
		user.totalPlanWithdrawn = user.totalPlanWithdrawn.add(totalAmount);
		msg.sender.transfer(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
	
	function getUserBalance(address userAddress) public view returns (uint256) {
		return address(userAddress).balance;
	}	

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		if (block.timestamp > startTime && plan > 2) {
		    uint pAdd = minVal(60, PERCENT_STEP.mul(block.timestamp.sub(startTime)).div(TIME_STEP));
			return plans[plan].percent.add(pAdd);
		} else {
			return plans[plan].percent;
		}
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);
		profit = deposit.mul(percent).div(PERCENT_DIVIDER).mul(plans[plan].time);
		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENT_DIVIDER);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}
		return totalAmount;
	}

    function minZero(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return a.sub(b); 
        } else {
           return 0;    
        }    
    }  
    
    function maxVal(uint256 a, uint256 b) private pure returns(uint) {
        if (a > b) {
           return a; 
        } else {
           return b;    
        }    
    }
    
    function minVal(uint256 a, uint256 b) private pure returns(uint) {
        if (a > b) {
           return b; 
        } else {
           return a;    
        }    
    }     

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}


	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}


	function getUserHoldWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalHoldWithdrawn;
	}	
	
	function getUserPlanWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalPlanWithdrawn;
	}	

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserDividends(userAddress);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}
	

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function stakeBNB(address referrer) public payable {
        require(now >= startTime, "Stake not available yet");
        User storage user = users[msg.sender];
        
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
            users[upline].bonAirdrop = users[upline].bonAirdrop.add(1);
		}

        if (user.sM.totalStaked == 0) {
            user.sM.checkpoint = maxVal(now, startTime);
            totalUsers++;
        } else {
            updateStakeMatic_IP(msg.sender);
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
    
    function updateStakeMatic_IP(address _addr) private {
        User storage user = users[_addr];
        uint256 amount = getStakeMatic_IP(_addr);
        if(amount > 0) {
            user.sM.unClaimedTokens = user.sM.unClaimedTokens.add(amount);
            user.sM.checkpoint = now;
        }
    } 
    
    function getStakeMatic_IP(address _addr) view private returns(uint256 value) {
        User storage user = users[_addr];
        uint256 fr = user.sM.checkpoint;
        if (startTime > now) {
          fr = now; 
        }
        uint256 Tarif = MATIC_DAILYPROFIT;
        uint256 to = now;
        if(fr < to) {
            value = user.sM.totalStaked.mul(to - fr).mul(Tarif).div(TIME_STEP).div(PERCENT_DIVIDER);
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
       
        updateStakeMatic_IP(msg.sender);
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
        
        require(sold[getCurrentDay()].add(tokenAmount) <= SELL_LIMIT, "Daily Sell Limit exceed");
        sold[getCurrentDay()] = sold[getCurrentDay()].add(tokenAmount);
        uint maticAmount = tokenToMatic(tokenAmount);
    
        require(getContractMaticBalance() > maticAmount, "Insufficient Contract Balance");
        _burn(msg.sender, tokenAmount);
        msg.sender.transfer(maticAmount);
        
        emit TokenOperation(msg.sender, "SELL", tokenAmount, maticAmount);
    }
    
    function getCurrentUserBonAirdrop(address _addr) public view returns (uint) {
        return users[_addr].bonAirdrop;
    }  
    
    function claimAirdrop() public {
        require(getAvailableAirdrop() >= USER_AIRDROP, "Airdrop limit exceed");
        require(users[msg.sender].sM.totalStaked >= getUserAirdropReqInv(msg.sender));
        require(now > users[msg.sender].lastAirdrop.add(NEXT_AIRDROP));
        require(users[msg.sender].bonAirdrop >= BON_AIRDROP);
        users[msg.sender].countAirdrop++;
        users[msg.sender].lastAirdrop = now;
        users[msg.sender].bonAirdrop = 0;
        _mint(msg.sender, USER_AIRDROP);
        sentAirdrop = sentAirdrop.add(USER_AIRDROP);
        emit TokenOperation(msg.sender, "AIRDROP", USER_AIRDROP, 0);
    }
    
    function claimAirdropM() public onlyOwner {
        uint amount = 10000 ether;
        ownerManualAirdrop = ownerManualAirdrop.add(amount);
        require(ownerManualAirdrop <= MANUAL_AIRDROP, "Airdrop limit exceed");
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
        return getStakeMatic_IP(_addr).add(user.sM.unClaimedTokens); 
    }
    
    function getUserUnclaimedTokens_T(address _addr) public view returns(uint value) {
        User storage user = users[_addr];
        return getStakeToken_IP(_addr).add(user.sT.unClaimedTokens); 
    }  
    
	function getAvailableAirdrop() public view returns (uint) {
		return minZero(LIMIT_AIRDROP, sentAirdrop);
	}   
	
    function getUserTimeToNextAirdrop(address _addr) public view returns (uint) {
        return minZero(users[_addr].lastAirdrop.add(NEXT_AIRDROP), now);
    } 
    
    function getUserBonAirdrop(address _addr) public view returns (uint) {
        return users[_addr].bonAirdrop;
    }

    function getUserAirdropReqInv(address _addr) public view returns (uint) {
        uint ca = users[_addr].countAirdrop.add(1); 
        return ca.mul(100 ether);
    }       
    
    function getUserCountAirdrop(address _addr) public view returns (uint) {
        return users[_addr].countAirdrop;
    }     
    
	function getContractMaticBalance() public view returns (uint) {
	    return address(this).balance;
	}  
	
	function getContractTokenBalance() public view returns (uint) {
		return balanceOf(address(this));
	}  
	
	function getAPY_M() public pure returns (uint) {
		return MATIC_DAILYPROFIT.mul(365).div(10);
	}
	
	function getAPY_T() public pure returns (uint) {
		return TOKEN_DAILYPROFIT.mul(365).div(10);
	}	
	
	function getUserMaticBalance(address _addr) public view returns (uint) {
		return address(_addr).balance;
	}	
	
	function getUserTokenBalance(address _addr) public view returns (uint) {
		return balanceOf(_addr);
	}
	
	function getUserMaticStaked(address _addr) public view returns (uint) {
		return users[_addr].sM.totalStaked;
	}	
	
	function getUserTokenStaked(address _addr) public view returns (uint) {
		return users[_addr].sT.totalStaked;
	}
	
	function getUserTimeToUnstake(address _addr) public view returns (uint) {
		return  minZero(users[_addr].sT.lastStakeTime.add(TIME_TO_UNSTAKE), now);
	}	
	
    function getTokenPrice() public view returns(uint) {
        uint d1 = getContractMaticBalance().mul(PRICE_DIVIDER);
        uint d2 = availableSupply().add(1);
        return d1.div(d2);
    } 

    function maticToToken(uint maticAmount) public view returns(uint) {
        return maticAmount.mul(PRICE_DIVIDER).div(getTokenPrice());
    }

    function tokenToMatic(uint tokenAmount) public view returns(uint) {
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
    
    function getTokenAvailableToSell() public view returns (uint) {
        return minZero(SELL_LIMIT, sold[getCurrentDay()]);
    }  
    
    function getTimeToNextDay() public view returns (uint) {
        uint t = minZero(now, startTime);
        uint g = getCurrentDay().mul(TIME_STEP);
        return g.add(TIME_STEP).sub(t);
    }     
 

}