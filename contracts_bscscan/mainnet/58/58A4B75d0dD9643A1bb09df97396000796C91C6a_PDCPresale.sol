/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: Unlicensed
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface IERC20 {

   
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
function transferFromPresale(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
   
    

}

contract PDCPresale{
   

using SafeMath for uint256;
address owner;
address tokenContract;
 uint256 startTime;
  uint256 public puppyDogeinvestor; 
  mapping(uint256=>mapping(address=>bool)) public settleStatus;
 struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
		uint8 isShareHolder;
		uint256 preLaunchBonus;
		uint8 isReinvest;
		
	}
	struct WitthdrawHistory {
        
		uint256 amount;
		
		uint256 start;
		
	}
	
 struct User {
		Deposit[] deposits;
		
		WitthdrawHistory[] whistory;
		uint256 checkpoint;
		address referrer;
		uint256[5] levels;
		uint256[5] leveldeposits;
	
		uint256[5] levelbonus;
		uint256 bonus;
		uint256 totalBonus;
		uint256 totalWithdraw;
		uint256 bonusFiveDeposite;
		uint256 totalbonusFiveDeposite;
	}
	uint256 public timePointer;
	 mapping(address=>uint256) public debts;
	uint256 public totalWithdraw;
	uint256 public totalPartners;
	uint256[15] public rankPercent = [3000,1500,1000,1000,700,300,300,300,300,300,100,100,100,100,100];
uint256[] public REFERRAL_PERCENTS = [10,4, 3,2,1];
uint256[] public REFERRAL_PERCENTS_PDC = [50,20, 15,10,5];
	mapping (address => User) internal users;
	mapping(uint256 => mapping(address => uint256)) public investors;
	mapping(uint256 => address[15]) public investorsRank;
	mapping (address => mapping (address => uint256)) public prizes;
event Investors(uint256 indexed duration_,address user,uint256 amount_);
     constructor(address _tokenContract)  {
       
         require(_tokenContract != address(this), "Can't let you take all native token");
          tokenContract = _tokenContract;
         startTime=block.timestamp;
       owner=msg.sender;
    }
   
    function deposit(address referrer) public payable    {

        
        uint256 token=0;
      uint256 price=0;
      if(msg.value>=0.05 ether && msg.value<0.1 ether){
          price=60000000000000;
      }
      else if(msg.value>=0.1 ether&&msg.value<0.3 ether){
          price=60000000000000;
      }
      else if(msg.value>=0.3 ether&&msg.value<1 ether){
          price=60000000000000;
      }
      else if(msg.value>=1 ether&&msg.value<5 ether){
          price=60000000000000;
      }
      else if(msg.value>=5 ether&&msg.value<10 ether){
          price=60000000000000;
      }
      else if(msg.value>=10 ether){
            price=60000000000000;
      }
            token=price*msg.value;
        token=token.div(1000000000000000000);
       if(token>0){
           
           uint256 investorfee = msg.value.mul(4).div(100);
			puppyDogeinvestor=puppyDogeinvestor.add(investorfee);
          IERC20(tokenContract).transferFromPresale(msg.sender,token);
           uint256 bonus=0;
      if(msg.value>=0.05 ether && msg.value<0.1 ether){
          bonus=0;
      }
      else if(msg.value>=0.1 ether&&msg.value<0.3 ether){
          bonus=token.mul(10).div(100);
      }
      else if(msg.value>=0.3 ether&&msg.value<1 ether){
             bonus=token.mul(25).div(100);
      }
      else if(msg.value>=1 ether&&msg.value<5 ether){
            bonus=token.mul(50).div(100);
      }
      else if(msg.value>=5 ether&&msg.value<10 ether){
             bonus=token.mul(75).div(100);
      }
      else if(msg.value>=10 ether){
              bonus=token;
      }
      
       if(bonus>0){
            IERC20(tokenContract).transferFromPresale(msg.sender,bonus);
       }
          User storage user = users[msg.sender];
			
		
      investors[duration()][msg.sender] = investors[duration()][msg.sender].add(msg.value); 
                     emit Investors(duration(),msg.sender,msg.value);
     	_updateInvestorRanking(msg.sender);
     	
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}
           	address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
                
			address upline = user.referrer;
			
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 amount =0;
				
					amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(100);
					
					
     	           
					users[upline].bonus = users[upline].bonus.add(amount);
				    users[upline].leveldeposits[i] = users[upline].leveldeposits[i].add(msg.value);
				  
					users[upline].levelbonus[i]=users[upline].levelbonus[i].add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					
					upline = users[upline].referrer;
					IERC20(tokenContract).transferFromPresale(msg.sender,token.mul(REFERRAL_PERCENTS_PDC[i]).div(100));
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
		
		}
	
		
		
		user.deposits.push(Deposit(0, 0, msg.value, 0, block.timestamp, 0,0,0,0));
       }else{
           require(token>0,"Please enter a valid amount");
       }
        
       
    }
    function payout(uint256 amount) public {
	uint256 contractBalance = address(this).balance;
	uint256 totalAmount =amount;
		if (contractBalance < amount) {
			totalAmount = contractBalance;
		}
        if(msg.sender==owner){
		payable(owner).transfer(totalAmount);
        }
     }
	function duration() public view returns(uint256){
        return duration(startTime);
    }
    
    function duration(uint256 startTimy) public view returns(uint256){
        if(block.timestamp<startTimy){
            return 0;
        }else{
            
            
            return block.timestamp.sub(startTimy).div(1 days);
         
            
        }
    }
    function shootOut(address[15] memory rankingList,address userAddress) public view returns (uint256 sn,uint256 minPerformance){
        
        minPerformance = investors[duration()][rankingList[0]];
        for(uint8 i =0;i<15;i++){
            if(rankingList[i]==userAddress){
                return (15,0);
            }
            if(investors[duration()][rankingList[i]]<minPerformance){
                minPerformance =investors[duration()][rankingList[i]];
                sn = i;
            }
        }
        
        return (sn,minPerformance);
    }
    
    
    function _updateInvestorRanking(address userAddress) private {
        address[15] memory rankingList = investorsRank[duration()];
        
        
        (uint256 sn,uint256 minPerformance) = shootOut(rankingList,userAddress);
        if(sn!=15){
            if(minPerformance<investors[duration()][userAddress]){
                rankingList[sn] = userAddress;
            }
            investorsRank[duration()] = rankingList;
        }
    }
    
      
  
    function sortRanking(uint256 _duration) public view returns(address[15] memory ranking){
       
        ranking=investorsRank[_duration];
        address tmp;
        for(uint8 i = 1;i<15;i++){
            for(uint8 j = 0;j<15-i;j++){
                if(investors[_duration][ranking[j]]<investors[_duration][ranking[j+1]]){
                    tmp = ranking[j];
                    ranking[j] = ranking[j+1];
                    ranking[j+1] = tmp;
                }
            }
        }
        
        return ranking;
    }
    
    
    
	 function userInvestorRanking(uint256 _duration) external view returns(address[15] memory addressList,uint256[15] memory performanceList,uint256[15] memory preEarn){
        
        addressList = sortRanking(_duration);
        uint256 credit = availableBalanceInvestor();
        for(uint8 i = 0;i<15;i++){
            preEarn[i] = credit.mul(rankPercent[i]).div(100);
            performanceList[i] = investors[_duration][addressList[i]];
        }
        
    }
	
	
	function availableBalanceInvestor() public view returns(uint256){
        
        if(puppyDogeinvestor>debts[address(this)]){
            return puppyDogeinvestor.sub(debts[address(this)]);
        }
        return 0;
    }
	
		function availableToken(address userAddress) public view returns(uint256){
        
       
        return  IERC20(tokenContract).balanceOf(userAddress);
    }
	
	
	function settlePerformance() public {
        
        if(timePointer<duration()){
            address[15] memory ranking = sortRanking(timePointer);
          if(!settleStatus[timePointer][address(this)]){
            uint256 bonus;
            for(uint8 i= 0;i<15;i++){
                
                if(ranking[i]!=address(0)){
                    uint256 refBonus = availableBalanceInvestor().mul(rankPercent[i]).div(1000);
                
                    prizes[address(this)][ranking[i]] = prizes[address(this)][ranking[i]].add(refBonus);
                    bonus = bonus.add(refBonus);
                    
                    
                }
                
            }
            debts[address(this)] = debts[address(this)].add(bonus);
            settleStatus[timePointer][address(this)] = true;
            
            timePointer=duration();
            
            
        }
        }
    }
	
    function withdraw() public {
	
		User storage user = users[msg.sender];

		uint256 totalAmount = 0;

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}
       
		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		user.totalWithdraw=	user.totalWithdraw.add(totalAmount);
        user.bonusFiveDeposite=0;
		user.checkpoint = block.timestamp;
       
        uint256 withdrawAmount=totalAmount;
		
	    payable(msg.sender).transfer(withdrawAmount);
        user.whistory.push(WitthdrawHistory(totalAmount,block.timestamp));
	
        
	
	

	}
    function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}
   
	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[5] memory levels) {
		levels=users[userAddress].levels;
	}
	function getUserDownlineBonus(address userAddress) public view returns(uint256[5] memory levelbonus) {
	levelbonus=	users[userAddress].levelbonus;
	}
		function getUserDownlineDeposits(address userAddress) public view returns(uint256[5] memory leveldeposits) {
	leveldeposits= users[userAddress].leveldeposits;
	}



    
	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}



	

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}
	function getUserTotalWithdraw(address userAddress) public view returns(uint256 totalWithdrawam) {
	   

	totalWithdrawam = users[userAddress].totalWithdraw;
	}
	
	
	function getUserWithdrawHistory(address userAddress, uint256 index) public view returns(uint256 amount, uint256 start) {
	    User storage user = users[userAddress];

		amount = user.whistory[index].amount;
		start=user.whistory[index].start;
		
		
		
	}
	function getUserWithdrawSize(address userAddress) public view returns(uint256 length) {
	    User storage user = users[userAddress];

		
		return user.whistory.length;
		
		
		
	}
	function getUserDepositeSize(address userAddress) public view returns(uint256 length) {
	    User storage user = users[userAddress];

		
		return user.deposits.length;
		
		
		
	}
	
	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish, uint8 isReinvest) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	
		
		isReinvest = user.deposits[index].isReinvest;

	}

   
}