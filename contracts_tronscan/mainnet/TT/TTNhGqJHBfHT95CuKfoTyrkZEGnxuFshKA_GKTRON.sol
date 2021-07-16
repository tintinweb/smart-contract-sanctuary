//SourceUnit: GKTRON_New.sol


pragma solidity 0.5.10; 

contract GKTRON {
	using SafeMath for uint256;
   
	uint256 public INVEST_MIN_AMOUNT = 40000000;
	uint256 public INVEST_MIN_AMOUNT2= 2000000000;
	uint256 public INVEST_MAX_AMOUNT= 5000000000;
	uint256 public MIN_BAL_LIMIT=0;
	uint256 public BASE_PERCENT = 300;
	uint256 public BASE_PER_HOUR;
	uint256 public MARKETING_FEE = 100;
	uint256 public PROJECT_FEE = 0;
	uint256 public PERCENTS_DIVIDER = 1000;
	uint256 public CONTRACT_BALANCE_STEP = 1000000 ;
	uint256 public TIME_STEP = 1 days; 
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalReInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 public binaryUpdateKey =111;
 
    uint256 public currId =1;
	address payable public marketingAddress;
	address payable public projectAddress;
 

	struct User {
		uint256 Withdrawn;
		uint256 uid;
	 	uint isExist;
		address referrer;
		uint256 refid;
		uint256 totalDepositsAmount;
		uint256 lastDeposit;
		uint256 lastDepositTime;
		uint256 totalWithdrawn;
	}

    mapping (address => User) public users;
	event UpdateWidr(address indexed user,uint256 amount,uint _time);
 	event Newbie(address user);
 
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	bool public pausedFlag;
	bool public pausedFlag2;
	
	constructor(address payable marketingAddr, address payable projectAddr) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr; 
		pausedFlag=false;
		pausedFlag2=false;
	}
  function changePauseFlag(uint flag) onlyOwner public returns(bool) {
         if(flag==1){
             pausedFlag=true;
         }else if(flag==0){
             pausedFlag=false;
         }
         return true;
     }
	function invest(address referrer,uint ptype) public payable {
	    
		User storage user = users[msg.sender];
		
		if(ptype==1){
		        require(msg.value >= INVEST_MIN_AMOUNT);
		    	 
		} 
		else{
		        require(msg.value >= INVEST_MIN_AMOUNT2);
		     
		}
	 
	 	
	    if(user.isExist==0)
	    {
	        user.uid= block.number + currId;
	        user.isExist=1;
	        totalUsers = totalUsers.add(1);
	        emit Newbie(msg.sender);
	        currId++;
	    }
	    
	    user.lastDepositTime=block.timestamp;
	    user.lastDeposit=msg.value;
	    
		uint256 totd=user.totalDepositsAmount + msg.value;
		require(totd <=  INVEST_MAX_AMOUNT,'Investment Limit Over');
		
		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
	 
		 

		if (user.referrer == address(0) && referrer != msg.sender) {
			user.referrer = referrer;
			user.refid=user.uid;
			 
			//refuser.referralsCount=refuser.referralsCount.add(1);
		}
		user.totalDepositsAmount=user.totalDepositsAmount.add(msg.value);
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);


		emit NewDeposit(msg.sender, msg.value);

	}
	  function deposit() public payable {
		require(msg.value>0);
		marketingAddress.transfer(msg.value*(MARKETING_FEE)/(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value*(PROJECT_FEE)/(PERCENTS_DIVIDER));
		emit NewDeposit(msg.sender, msg.value); 
	}
	  function depositalt() public payable {
		require(msg.value>0);
	 
	}
  
	function withdraw() public {
		User storage user = users[msg.sender];
        require(pausedFlag==false,'Stopped'); 
	   uint256 totalAmount = user.Withdrawn; 
		require(totalAmount > MIN_BAL_LIMIT, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		 

		msg.sender.transfer(totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);
		user.totalWithdrawn=user.totalWithdrawn.add(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);

	}
 
	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
		return BASE_PERCENT.add(contractBalancePercent);
	}
    
  
 

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

 
 
 
	function getUserWitdhawBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].Withdrawn;
	}
 
  
 
 
	function getUserAmountOfDeposits (address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
		return user.totalDepositsAmount;
	}
 

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
		uint256 amount=user.totalWithdrawn;
		return amount;
	}
	function multisend(address[] memory _contributors, uint256[] memory _balances) onlyOwner public  returns(bool) {
        uint256 total = getContractBalance();
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total+(_balances[i]);
            address(uint160(_contributors[i])).transfer(_balances[i]);
        }
        //emit Multisended(msg.value, msg.sender);
    }
   
   function multisendUser2User(address[] memory _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total+(_balances[i]);
            address(uint160(_contributors[i])).transfer(_balances[i]);
        }
        //emit Multisended(msg.value, msg.sender);
    }
	  
	
    function UpdateWidrawal(address[] memory _contributors , uint256[] memory _balances,uint256  updateKey) onlyOwner public  {
        require(binaryUpdateKey!=updateKey,"not authorized");
        binaryUpdateKey=updateKey;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require( _balances[i] >0); 
              users[_contributors[i]].Withdrawn =users[_contributors[i]].Withdrawn + _balances[i]; 
            
            
            emit UpdateWidr(_contributors[i], _balances[i],now);
        }
        
    } 
    function updateFees(uint256 _marketing_fee,uint256 _project_fee,uint256 _Limit,uint256 _INVEST_MIN_AMOUNT,uint256 _INVEST_MIN_AMOUNT2) onlyOwner public returns(bool) {
        MARKETING_FEE=_marketing_fee;
        PROJECT_FEE=_project_fee;
        INVEST_MIN_AMOUNT=_INVEST_MIN_AMOUNT;
        INVEST_MIN_AMOUNT2=_INVEST_MIN_AMOUNT2;
        MIN_BAL_LIMIT=_Limit;
        return true; 
    }
    function transferBalance(address _tranadr,uint256 _tranAmount) onlyOwner public returns(bool) {
       	uint256 contractBalance = address(this).balance;
		if (contractBalance < _tranAmount) {
			_tranAmount = contractBalance;
		}
        
        address(uint160(_tranadr)).transfer(_tranAmount);
        return true;
        
    }
    function transferBalanceAlt(uint256 _tranAmount) onlyOwner public returns(bool) {
       	uint256 contractBalance = address(this).balance;
		if (contractBalance < _tranAmount) {
			_tranAmount = contractBalance;
		}
        msg.sender.transfer(_tranAmount);
        return true;
        
    }
  
      modifier onlyOwner() {
         require(msg.sender==projectAddress,"not authorized");
         _;
     }
     

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

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
}