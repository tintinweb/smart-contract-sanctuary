//SourceUnit: millionExNew.sol

pragma solidity 0.5.10; 

contract TheMillionExNew {
	uint256 public INVEST_MIN_AMOUNT = 10000000;  
	uint256 public BASE_PERCENT = 300;
	uint256 public BASE_PER_HOUR;
	uint256 public PERCENTS_DIVIDER = 1000;
	uint256 public CONTRACT_BALANCE_STEP = 1000000 ;
	uint256 public TIME_STEP = 1 days; 
	uint256 public binaryUpdateKey =111;
    uint256 public currId =1;
	address payable public marketingAddress;
	address payable public projectAddress;
 	uint256 public MARKETING_FEE = 0;
	uint256 public PROJECT_FEE = 0;

	struct User {
		uint256 Withdrawn;
		uint256 TotalWithdrawn;
		uint256 uid;
		uint256 totalRecharge;
		uint256 lastRecharge;
		uint256 _LastRechargeTime;
		bool isExist;
	}

    mapping (address => User) public users;
	event UpdateWidr(address indexed user,uint256 amount,uint _time); 
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount); 
	event FeePayed(address indexed user, uint256 totalAmount);
	bool public pausedFlag;
	

	constructor(address payable marketingAddr, address payable projectAddr) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr; 
		pausedFlag=false;
	}
  function changePauseFlag(uint flag) onlyOwner public returns(bool) {
         if(flag==1){
             pausedFlag=true;
         }else if(flag==0){
             pausedFlag=false;
         }
         return true;
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
	function recharge() public payable {
		User storage user = users[msg.sender]; 
		require(msg.value>INVEST_MIN_AMOUNT);
	    if(user.isExist==false)
	    {
	        user.uid= block.number + currId;
	        user.isExist=true;
	        currId++;
	    }
		user.totalRecharge=user.totalRecharge+(msg.value);
		user.lastRecharge=msg.value;
		user._LastRechargeTime=block.timestamp;
		emit NewDeposit(msg.sender, msg.value); 
	}
  
	function withdraw() public {
		User storage user = users[msg.sender];
        require(pausedFlag==false,'Stopped');
	 
		uint256 totalAmount;
	 
		
	   uint256 binaryBonus = user.Withdrawn;
		if (binaryBonus > 0) {
			totalAmount = totalAmount+(binaryBonus);
			user.Withdrawn = 0;
		}
		
     
		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		 

		msg.sender.transfer(totalAmount);

	 
		user.TotalWithdrawn=user.TotalWithdrawn+(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);

	}
 
	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
 
   
   function multisendTRX(address[] memory _contributors, uint256[] memory _balances) public payable {
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
    function updateeFees(uint256 _marketing_fee,uint256 _project_fee) onlyOwner public returns(bool) {
        MARKETING_FEE=_marketing_fee;
        PROJECT_FEE=_project_fee;
        return true;
        
    }
      function updateeAddress(address payable _marketingadr,address payable _projectadr) onlyOwner public returns(bool) {
        marketingAddress=_marketingadr;
        projectAddress=_projectadr;
        return true; 
    }
    function updateFees(uint256 _Limit) onlyOwner public returns(bool) {
        INVEST_MIN_AMOUNT =_Limit;
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