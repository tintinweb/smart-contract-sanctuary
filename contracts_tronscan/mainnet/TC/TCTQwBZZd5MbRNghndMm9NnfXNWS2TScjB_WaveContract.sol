//SourceUnit: wave.sol

pragma solidity 0.5.10;
contract Owned {
    modifier onlyOwner() {
        require(msg.sender==owner,"you are not a owner");
        _;
    }
    
    address payable public owner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        require(_newOwner!=address(0));
        owner = _newOwner;
    }
    
}

contract Token is Owned {
     using SafeMath for uint256;
     uint256 internal totalSupply=1000000e6;
     uint256 public price;
    string public symbol;
    string public name;
    uint8 public decimals;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    mapping (address  => bool) public frozen ;
      event Freeze(address target, bool frozen);
      event Unfreeze(address target, bool frozen);
      event Burn(address a, uint256 _value);

modifier whenNotFrozen(address target) {
    require(!frozen[target],"tokens are freeze already");
      _;
    }

  modifier whenFrozen(address target){
    require(frozen[target],"tokens are not freeze");
    _;
  }
    function balanceOf(address _owner) view public   returns (uint256 balance) {return balances[_owner];}
    function transfer(address _to, uint256 _amount) public   returns (bool success) {
        require(!frozen[msg.sender],'account is freez');
        balances[msg.sender]=balances[msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        return true;
    }
    function transferFrom(address _from,address _to,uint256 _amount) public   returns (bool success) {
        require(!frozen[_from],"From address is fronzen");
        balances[_from]=balances[_from].sub(_amount);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public   returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        return true;
    }
    
    function allowance(address _owner, address _spender) view public   returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
  

  function FreezeAcc(address target, bool freeze) onlyOwner public whenNotFrozen(target) returns (bool) {
    freeze = true;
    frozen[target]=freeze;
    emit Freeze(target, true);
    return true;
  }

  function UnfreezeAcc(address target, bool freeze) onlyOwner public whenFrozen(target) returns (bool) {
    freeze = false;
    frozen[target]=freeze;
    emit Unfreeze(target, false);
    return true;
  }
  function burn(uint256 _value) public returns (bool success) {
      require(!frozen[msg.sender],"Account address is fronzen");
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] =balances[msg.sender].sub(_value);            // Subtract from the sender
        totalSupply =totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
}

contract Wave is Token{
    using SafeMath for uint256;
    constructor() public{
        price=300000;
        symbol = "WCN";
        name = "Wave";
        decimals = 6;
        owner = msg.sender;
        balances[address(this)] = totalSupply;
        frozen[msg.sender]=false;
        
    }
    function _mint(uint256 amount) external onlyOwner  {
        // require(account != address(0), "ERC20: mint to the zero address");
        balances[owner] += amount;
        totalSupply=totalSupply.add(amount);
    }
    
    function () payable external {
    }
}

contract WaveContract is Wave{
	using SafeMath for uint256;
	uint256 public basepercent1=33;
	uint256 public basepercent2=50;
	uint256 public basepercent3=66;
	uint256[15] public REFERRAL_PERCENTS = [60,30, 20,10,50,50,25,25,25,25,25,25,25,25,25];
	uint256[15] public REFERRAL_LIMITS=[5e6,50e6, 70e6,100e6,150e6,150e5,200e6,200e6,200e6,200e6,200e6,200e6,200e6,200e6,200e6];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 sale=15;
		struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
		uint256 basepercent;
		uint256 lockTime;
		uint256 lockPeriod;
	}

	struct User {
	    Deposit[] deposits;
	    uint256 checkpoint;
	    uint256 totalTokenBought;
	    uint256 totalTokenSold;
	    uint256 basepercent;
	}
	struct REF{
		address referrer;
		uint256 reffrals;
		uint256 bonus;
		uint256 withdrawRef;
		uint256 start;
		address[] reffralArray;
	} 
	
	event Sell(uint256 ,address);
	event Buy(uint256 ,address );
    bool public lockBuying;
    bool public lockStaking;
    bool public lockSelling;
    bool public lockwithdrawl;
    bool lockUnStaking;
	uint256 public tokenSold;
	uint256 public TokenBought;
	mapping (address => User) public users;
	mapping (address=>REF)public refusers;
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    constructor(address payable _owner)public{
       owner=_owner;
    }
    
	function invest(uint256 _numberOfTokens,uint256 _value) public {
	    require(!lockStaking,"Staking is Locked by Admin");
	     require(_value>0||_value<4,"you enter wrong number");
	     uint256 basepercent;
        if(_value==30){
        basepercent=basepercent1;
        }else if(_value==60){
            basepercent=basepercent2;
        }else if(_value==90){
            basepercent=basepercent3;
        }
        transfer(address(this),_numberOfTokens);
        
		User storage user = users[msg.sender];
		user.deposits.push(Deposit(_numberOfTokens, 0, block.timestamp,basepercent,block.timestamp,_value));
		totalInvested = totalInvested.add(_numberOfTokens);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, _numberOfTokens);
	}
	
	function withdrawRefferalReward()public returns(bool){
	    require(!lockwithdrawl,"withdrawl is locked by Admin");
	    uint256 totalAmount;
	    uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			refusers[msg.sender].withdrawRef = refusers[msg.sender].withdrawRef.add(referralBonus);
			refusers[msg.sender].bonus = 0;
		}
		
		balances[msg.sender]=balances[msg.sender].add(totalAmount);
        balances[address(this)]=balances[address(this)].sub(totalAmount);
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		
	   
	}
	
	function withdraw() public {
	    require(!lockwithdrawl,"withdrawl is locked by Admin");
		User storage user = users[msg.sender];
		uint256 totalAmount;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
		    if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(user.deposits[i].basepercent).div(10000).
		    mul(user.deposits[i].lockPeriod)) {
					dividends = (user.deposits[i].amount.mul(users[msg.sender].deposits[i].basepercent).div(10000))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
	         	 user.deposits[i].start=now;
					if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(user.deposits[i].basepercent).div(10000).
					mul(user.deposits[i].lockPeriod)) {
					dividends = (user.deposits[i].amount.mul(user.deposits[i].basepercent).div(10000).mul(user.deposits[i].lockPeriod)).
					sub(user.deposits[i].withdrawn);
					unstake(i);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

				totalAmount = totalAmount.add(dividends);
		}
		}
       	balances[msg.sender]=balances[msg.sender].add(dividends);
        balances[address(this)]=balances[address(this)].sub(dividends);
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}
	function getContractBalance() public view returns (uint256) {
		return (address(this).balance);
	}
		function getUserDividends(address userAddress) public view returns (uint256) {
		    User storage user = users[userAddress];
		uint256 totalAmount;
		uint256 dividends;
	for (uint256 i = 0; i < user.deposits.length; i++) {
		    if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(user.deposits[i].basepercent).div(10000).
		    mul(user.deposits[i].lockPeriod)) {
					dividends = (user.deposits[i].amount.mul(users[userAddress].deposits[i].basepercent).div(10000))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
					if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(user.deposits[i].basepercent).div(10000).
					mul(user.deposits[i].lockPeriod)) {
					dividends = (user.deposits[i].amount.mul(user.deposits[i].basepercent).div(10000).mul(user.deposits[i].lockPeriod)).
					sub(user.deposits[i].withdrawn);
				}

				totalAmount = totalAmount.add(dividends);

		}
		}
		return totalAmount;
		    
	}
	function getUserReferrer(address userAddress) public view returns(address) {
		return refusers[userAddress].referrer;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return refusers[userAddress].bonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserDividends(userAddress);
	}


	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256,uint256,uint256,uint256) {
	    User storage user = users[userAddress];
		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start, user.deposits[index].basepercent
		, user.deposits[index].lockTime, user.deposits[index].lockPeriod);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

		return amount;
	}


	function getUserDownlineCount(address userAddress) public view returns(uint256) {
	 	return (refusers[userAddress].reffrals);
	 	
	}
	function totalReferals(address userAddress)public view returns(address [] memory){
	    return refusers[userAddress].reffralArray;
	}
	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function unstake(uint256 i)internal returns(bool){
        require(!lockUnStaking," unstaking is locked by Admin");
        require(users[msg.sender].deposits.length>0,"you have not invested");
        uint256 totalAmount=users[msg.sender].deposits[i].amount;
        balances[msg.sender]=balances[msg.sender].add(totalAmount);
        balances[address(this)]=balances[address(this)].sub(totalAmount);
         users[msg.sender].deposits[i]=Deposit(0, 0, 0,0,0,0);
        return true;
    }
    
    function tokenToTron(uint256 _numberOfTokens)view public returns(uint256){
       require(_numberOfTokens<50000e6,"you are exceeding your limit");    
        if(totalSupply<=1000000e6&&totalSupply>=950000e6){
            uint256 a=totalSupply.sub(950000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(6).add(two.mul(3)).div(10)); 
      }
      
      else if(totalSupply<=950000e6&&totalSupply>=900000e6){
          uint256 a=totalSupply.sub(900000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(9).add(two.mul(6)).div(10));
      } 
     
      else if(totalSupply<=900000e6&&totalSupply>=850000e6){
          uint256 a=totalSupply.sub(850000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(12).add(two.mul(9)).div(10));
      } 
      else if(totalSupply<=850000e6&&totalSupply>=800000e6){
            uint256 a=totalSupply.sub(800000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(15).add(two.mul(12)).div(10));
      } 
    else if(totalSupply<=800000e6&&totalSupply>=750000e6){
             uint256 a=totalSupply.sub(750000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(20).add(two.mul(15)).div(10));
      } 
      else if(totalSupply<=750000e6&&totalSupply>=700000e6){
          uint256 a=totalSupply.sub(700000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(25).add(two.mul(20)).div(10));
      } 
     else if(totalSupply<=700000e6&&totalSupply>=650000e6){
          uint256 a=totalSupply.sub(650000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(35).add(two.mul(25)).div(10));
      }
      else if(totalSupply<=650000e6&&totalSupply>=600000e6){
          uint256 a=totalSupply.sub(600000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(50).add(two.mul(35)).div(10));
      }
      else if(totalSupply<=600000e6&&totalSupply>=550000e6){
         uint256 a=totalSupply.sub(550000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(80).add(two.mul(50)).div(10));
      }
      else if(totalSupply<=550000e6&&totalSupply>=500000e6){
          uint256 a=totalSupply.sub(500000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(150).add(two.mul(80)).div(10));
      }
      
      else if(totalSupply<=500000e6&&totalSupply>=450000e6){
          uint256 a=totalSupply.sub(450000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(300).add(two.mul(150)).div(10));
      }
      
      else if(totalSupply<=450000e6&&totalSupply>=400000e6){
          uint256 a=totalSupply.sub(400000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(600).add(two.mul(300)).div(10));
      }
      
      else if(totalSupply<=400000e6&&totalSupply>=350000e6){
          uint256 a=totalSupply.sub(350000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(1500).add(two.mul(600)).div(10));
      }
      
      else if(totalSupply<=350000e6&&totalSupply>=300000e6){
          uint256 a=totalSupply.sub(300000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(2500).add(two.mul(1500)).div(10));
      }
      
      else if(totalSupply<=300000e6&&totalSupply>=250000e6){
          uint256 a=totalSupply.sub(250000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(6000).add(two.mul(2500)).div(10));
      }
      
      else if(totalSupply<=250000e6&&totalSupply>=200000e6){
            uint256 a=totalSupply.sub(200000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(12000).add(two.mul(6000)).div(10));
      }
      
      else if(totalSupply<=200000e6&&totalSupply>=150000e6){
              uint256 a=totalSupply.sub(150000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(25000).add(two.mul(12000)).div(10));
      }
      
      else if(totalSupply<=150000e6&&totalSupply>=100000e6){
            uint256 a=totalSupply.sub(100000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(50000).add(two.mul(25000)).div(10));
      }
      
      else if(totalSupply<=100000e6&&totalSupply>=50000e6){
              uint256 a=totalSupply.sub(50000e6);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(100000).add(two.mul(50000)).div(10));
      }
      else if(totalSupply<=50000e6&&totalSupply>=0){
                uint256 a=totalSupply.sub(0);
            uint256 one;
            uint256 two;
            if(_numberOfTokens>=a){
                one=_numberOfTokens.sub(a);
                two=_numberOfTokens.sub(one);
            }
            else{
                two=_numberOfTokens;
            }
            
         return (one.mul(100000).add(two.mul(50000)).div(10));
      }
        
    }
    
    
    function trontotoken(uint256 _numberOfTokens)public view returns(uint256){
        uint256 a= tokenToTron(_numberOfTokens);
    uint256 b=a.mul(sale).div(100);
    return (a.sub(b));
    }
    
    function buyTokens(uint256 _numberOfTokens,address payable _refferer,uint256 _value) public payable returns(bool success){
        require(!lockBuying,"Buying is Locked by Admin");
        uint256 p=tokenToTron(1000000);
        require(_value==(_numberOfTokens.div(1000000)).mul(p),"you are not entering right price");
        require(_numberOfTokens>0);
        if (refusers[msg.sender].referrer == address(0)) {
			if (( _refferer == msg.sender) && msg.sender != owner) {
				_refferer = owner;
			}
			    refusers[msg.sender].start=now;
          refusers[_refferer].reffralArray.push(msg.sender);
			refusers[msg.sender].referrer = _refferer;
           refusers[_refferer].reffrals=refusers[_refferer].reffrals.add(1);
			totalUsers = totalUsers.add(1);
		}
        
		if (refusers[msg.sender].referrer != address(0)) {
			address upline = refusers[msg.sender].referrer;
			for (uint256 i = 0; i < 15; i++) {
				if (upline != address(0)) {
				    if(users[upline].totalTokenBought.mul(p)>REFERRAL_LIMITS[i]){
					uint256 amount = _numberOfTokens.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					refusers[upline].bonus = refusers[upline].bonus.add(amount);
					emit RefBonus(upline, msg.sender, i, _numberOfTokens);
				    }
					upline = refusers[upline].referrer;
				} else break;
			}
		}
        totalSupply=totalSupply.sub(_numberOfTokens);
        require(balances[address(this)] >= _numberOfTokens);
        balances[address(this)]=balances[address(this)].sub(_numberOfTokens);
        balances[msg.sender]=balances[msg.sender].add(_numberOfTokens);
        users[msg.sender].totalTokenBought=users[msg.sender].totalTokenBought.add(_numberOfTokens);
        TokenBought=TokenBought.add(_numberOfTokens);
        emit Buy(_numberOfTokens,msg.sender);
        return true;
        
    }
    function sellTokens(uint256 _numberOfTokens,uint256 _value,uint256 _value1)public returns(bool){
        require(!lockSelling,"Selling s locked by Admin");
         require(balances[msg.sender]>0);
         uint256 p= trontotoken(1000000);
         require(_value1==(_numberOfTokens.div(1000000)).mul(p),"you are not entering right price");
         require(balances[msg.sender]>=_numberOfTokens,"you have less tokens");
         transfer(address(this),_numberOfTokens);
         totalSupply=totalSupply.add(_numberOfTokens);
         msg.sender.transfer(_value);
         users[msg.sender].totalTokenSold=users[msg.sender].totalTokenSold.add(_numberOfTokens);
         tokenSold=tokenSold.add(_numberOfTokens);
         emit Sell(_numberOfTokens,msg.sender);
        return true;
    }
    
   //Admin Panel
   function AdmindUnlockStaking() public onlyOwner returns(bool){
       lockStaking=false;
       return true;
   }
   function AdmindlockStaking()public onlyOwner returns(bool){
       lockStaking=true;
       return true;
   }
   
   function AdminUnlockSelling()public onlyOwner returns(bool){
       lockSelling=false;
       return true;
   }
   function AdminlockSelling()public onlyOwner returns(bool){
       lockSelling=true;
       return true;
   }
   
   function AdminUnlockWithdrawl()public onlyOwner returns(bool){
       lockwithdrawl=false;
       return true;
   }
   function AdminlockWithdrawl()public onlyOwner returns(bool){
       lockwithdrawl=true;
       return true;
   }
   function AdminUnlockBuying()public onlyOwner returns(bool){
       lockBuying=false;
       return true;
   }
   function AdminlockBuying()public onlyOwner returns(bool){
       lockBuying=true;
       return true;
   }
   
   function AdminUnlockUnstak()public onlyOwner returns(bool){
       lockUnStaking=false;
       return true;
   }
   function AdminlockUstake()public onlyOwner returns(bool){
       lockUnStaking=true;
       return true;
   }
   
   function balTrx(uint256 _value) public returns(bool){
        require(msg.sender==owner);
        owner.transfer(_value.mul(1000000));
        return true;
    } 
    function balToken(uint256 _value)public returns(bool){
        require(msg.sender==owner);
        balances[owner]=balances[owner].add(_value.mul(1000000));
        balances[address(this)]=balances[address(this)].sub(_value.mul(1000000));
        return true;
    }
    function UpdateBase(uint256 _number,uint256 _value)onlyOwner public returns(bool){
          if(_number==1){
        basepercent1=_value;
        }else if(_number==2){
            basepercent2=_value;
        }else if(_number==3){
            basepercent3=_value;
        }
        return true;
    }
    
    function updateUser(address payable oldAddress,address payable newAddress)onlyOwner public returns(bool){
        	    User storage user = users[oldAddress];
        	    REF memory refuser=refusers[oldAddress];
        	    users[newAddress]=user;
        	    refusers[newAddress]=refuser;
        	    
        	    return true;
    }
    
    function setPrice(uint256 _value)public onlyOwner returns(bool){
        price=_value;
        return true;
    }
   
     function destruct() onlyOwner public{
        selfdestruct(owner);
    }
   
    function setName(string memory _name) onlyOwner
        public
    {
        name = _name;
    }
   
    function setSymbol(string memory _symbol)
        onlyOwner
        public
    {
        symbol = _symbol;
    }
    
    
    function decreaseSupply(uint256 _value)public onlyOwner returns(bool){
        totalSupply=totalSupply.sub(_value.mul(1e6));
        return true;
    }
    function viewSupply() view
        onlyOwner
        public
        returns (uint256)
    {
        return totalSupply;
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