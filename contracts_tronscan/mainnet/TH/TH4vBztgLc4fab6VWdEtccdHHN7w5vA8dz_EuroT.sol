//SourceUnit: eurot.sol

pragma solidity ^0.5.0;

contract TRC20Token {


  string public name;

  string public symbol;

  uint8 public decimals;

  uint256 public totalSupply;

  function balanceOf(address _owner) public view returns (uint256 balance);

  function transfer(address _to, uint256 _value) public returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  function approve(address _spender, uint256 _value) public returns (bool success);

  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract EuroT{
	
	address payable public owner;
	address payable public tokenAddress;
	TRC20Token eurotron;
	
	struct Plan {
		uint planId;
		uint amount;
        uint dailyInterest;
        uint term; //0 means unlimited
		uint targetLevel;
    }
    struct User {
		bool exists;
		address payable upline;
		uint totalReference;
		bool booster;
		bool dlevelach;
		bool activeStatus;
		mapping(uint8 => Investment) mplans;
		mapping(uint8 => Income) income;
	}
	struct Investment {
        uint planId;
        uint investmentDate;
        uint investment;        
		uint maxOut;
    }
    struct Income {
		uint lastTimeDividend;
		uint lastWithdraw;
		uint totalReceive;
		uint totalTokenAirDrop;
	}
	uint public count = 1;
	uint public adminFee = 1;
	uint public tRate = 115;
	uint public trxRateDivider = 10;
	bool public wTRX = false;
	uint private dlevelper = 5;
	

	
	mapping(address => User) public users;
	
	mapping(uint => address) public listUsers;
	mapping(uint8 => uint) private bonusPercent;
	
	Plan[] private investmentPlans_;
	constructor(address payable _owner, address payable _tokenAddress) public {
		owner = _owner;
		eurotron = TRC20Token(_tokenAddress);
		tokenAddress = _tokenAddress;
		
		
		User memory user = User({
			exists: true,
			upline: address(0),
			totalReference: 0,
			booster : false,
			dlevelach : false,
			activeStatus : true
		});
		users[owner] = user;
		
		listUsers[count] = owner;
		_init();
	}
	function _init() private {
        investmentPlans_.push(Plan(1,400,5,600,1));//id,amount,per,term,level
		investmentPlans_.push(Plan(2,2400,7,428,3));
		investmentPlans_.push(Plan(3,4800,1,300,5));
		investmentPlans_.push(Plan(4,10000,12,250,6));
		investmentPlans_.push(Plan(5,20000,14,214,7));
		investmentPlans_.push(Plan(6,30000,16,187,8));
		investmentPlans_.push(Plan(7,50000,18,166,9));
		investmentPlans_.push(Plan(8,80000,20,150,10));
		bonusPercent[1] = 10;
        bonusPercent[2] = 2;
        bonusPercent[3] = 1;
        bonusPercent[4] = 2;
        bonusPercent[5] = 2;
        bonusPercent[6] = 2;
        bonusPercent[7] = 2;
        bonusPercent[8] = 2;
        bonusPercent[9] = 2;
        bonusPercent[10] = 2;
        
    }
	function() external payable {
        if(msg.data.length == 0) {
            return register(owner);
        }
    }
    function register(address payable _upline) public payable {
		address payable upline = _upline;
		require(users[_upline].exists, "No Upline");
		require(!users[msg.sender].exists,"Address exists");
		require(msg.value >= 400 trx, "Greater than or equal min deposit value");
		require(msg.value % 10000000 == 0, "Amount should be in multiple of 10 TRX");
		User memory user = User({
			exists: true,
			upline: upline,
			totalReference: 0,
			booster : false,
			dlevelach : false,
			activeStatus : false
		});
		count++;
		users[msg.sender] = user;
		listUsers[count] = msg.sender;
		users[_upline].totalReference += 1;
		users[msg.sender].income[1].lastTimeDividend = now;
		_setUserPlan(msg.sender,msg.value);
		_setReferalIncome(msg.sender,msg.value);
		_setBooster(_upline);		
        
		emit Register(upline,msg.sender, msg.value);
	}
	function _setUserPlan(address _add,uint _value) private {
		uint _planId = _getPlanByValue(_value/1e6);
		
		if(_planId+1 > 1 && !users[_add].dlevelach){
		    users[_add].dlevelach = true;
		}
		users[_add].activeStatus = true;
		users[_add].mplans[1].planId = _planId;
		users[_add].mplans[1].investmentDate = block.timestamp;
		users[_add].mplans[1].investment = _value;
		users[_add].mplans[1].maxOut = 0;
		
	}
	function _setReferalIncome(address _add,uint value) private {		
		address payable upline = users[_add].upline;
		
		for(uint8 i=0; i < 10; i++){
			if(upline == address(0))return;
			
			
			uint _planId = users[upline].mplans[1].planId;
			uint targetLevel = investmentPlans_[_planId].targetLevel;
			if(i+1 <= targetLevel && users[upline].activeStatus && _chkIncome(upline)){
				uint bp = bonusPercent[i+1];
				if(!users[upline].dlevelach){
					bp = dlevelper;
				}
				uint bonus = bp * value / 100 ;
				users[upline].income[1].totalReceive += bonus;
				upline.transfer(bonus);
				emit ReferalIncome(msg.sender,upline, bonus,i+1);
			}
			upline = users[upline].upline;
		}
	}
	function _setBooster(address _add) private  {
		if(!users[_add].booster){
			if(users[_add].mplans[1].planId > 0){
				uint timeToInvest = now - users[_add].mplans[1].investmentDate;
				if(timeToInvest <= 172800 && users[_add].totalReference > 1){
					users[_add].booster = true;
				}
			}
		}
    }
	function _chkIncome(address _add) private view returns(bool){
		uint totalInvestment = users[_add].mplans[1].investment;
		uint totalReceive = users[_add].income[1].totalReceive;
		uint totalDividends = users[_add].income[1].lastWithdraw*(tRate/trxRateDivider);
		if(totalInvestment*300/100 > totalReceive+totalDividends){
		    return true;
		}
		return false;
	}
	
	function _getPlanByValue(uint _value) private view returns (uint){
		uint totalPlan = (investmentPlans_.length) - 1;
		for (uint i = totalPlan; i >= 0 && _value > 0; i--) {
            Plan storage plan = investmentPlans_[i];
            if(plan.amount <= _value){return i;}
        }
		return 0;
	}
	
    function  changeFee (uint _newAdminFee) public {
		require(msg.sender == owner,"only Owner Can Change Fee");
		adminFee = _newAdminFee;
		return;
	}
	
	function  changeRate (uint _newRate) public {
		require(msg.sender == owner,"only Owner Can Change Rate");
		tRate = _newRate;
		return;
	}
	function  changeTrxRateDivider (uint _newRate) public {
		require(msg.sender == owner,"only Owner Can Change Rate");
		trxRateDivider = _newRate;
		return;
	}
	function  change_OCwTRX () public {
		require(msg.sender == owner,"only Owner Can Change");
		wTRX = !wTRX;
		return;
	}
	function withdraw(uint valuet) public {
		if (msg.sender == owner){
			uint contractBalance = address(this).balance/1e6;
			require(contractBalance >= valuet,"No Value");
			owner.transfer(valuet*1e6);
			emit Withdraw(msg.sender, valuet*1e6);
		} 
	}
	function getUserBusinessInfo() external view returns(uint,uint,uint,uint,uint,uint,uint,uint){
		uint lastTimeDividend = users[msg.sender].income[1].lastTimeDividend;
		uint lastWithdraw = users[msg.sender].income[1].lastWithdraw;
		uint totalReceive = users[msg.sender].income[1].totalReceive;
		uint totalTokenAirDrop = users[msg.sender].income[1].totalTokenAirDrop;
		uint planId = users[msg.sender].mplans[1].planId;
        uint investmentDate = users[msg.sender].mplans[1].investmentDate;
        uint investment = users[msg.sender].mplans[1].investment;        
		uint maxOut = users[msg.sender].mplans[1].maxOut;
		return (lastTimeDividend,lastWithdraw,totalReceive,totalTokenAirDrop,planId,investmentDate,investment,maxOut);
	}
	function roiWallet(uint8 w,uint systemtime) public view returns(uint,uint){
		uint systemtime = now;
		require(users[msg.sender].mplans[1].investment > 0,"Member Not Active");
		uint diff = systemtime - users[msg.sender].income[1].lastTimeDividend;
		uint dayss = diff/60/60/24;
		uint balance = 0;
		uint planId = users[msg.sender].mplans[1].planId;
        uint term = investmentPlans_[planId].term;
		uint maxOut = users[msg.sender].mplans[1].maxOut;
		if(dayss > 0 && maxOut < term){
            uint profit = investmentPlans_[planId].dailyInterest;
			uint m = tRate/trxRateDivider;
			if(w == 1){
				m = 1;
			}		    
			uint bonus =  ((users[msg.sender].mplans[1].investment * profit/1000)/(m));
			if(users[msg.sender].booster){
				bonus *= 2;
			}
			balance = bonus*dayss;
		}
		return (balance,dayss);
	}
	

	function  roiWithdraw(uint systemtime) public {
		//require(users[msg.sender].investment > 0,"Member Not Active");
		uint systemtime = now;
		(uint bal,uint dayss) = roiWallet(0,systemtime);
		require(bal > 0,"Withdrawal Balance In-sufficent");
		
		uint tokenBalance = eurotron.balanceOf(address(this));
		require(tokenBalance > 0,"Balance In-sufficent");
		
		uint rdiv = bal;
		uint tax = rdiv * adminFee/100;
		rdiv = rdiv - tax;
		require(rdiv < tokenBalance,"EUROTron In-sufficent On Contract");
		
		users[msg.sender].income[1].totalTokenAirDrop += bal;
		users[msg.sender].income[1].lastWithdraw = bal;
		users[msg.sender].income[1].lastTimeDividend = systemtime;
		users[msg.sender].mplans[1].maxOut += dayss;
		eurotron.transfer(msg.sender,rdiv);
		emit WithdrawToken(msg.sender, rdiv);		
	}
	function  roiWithdrawTRX(uint systemtime) public {
		require(wTRX,"TRX Withdrawal Close !!");
		uint systemtime = now;
		(uint bal,uint dayss) = roiWallet(1,systemtime);
		require(bal > 0,"Withdrawal Balance In-sufficent");
		
		uint trxBalance = address(this).balance;
		require(trxBalance > 0,"Balance In-sufficent");
		
		uint rdiv = bal;
		uint tax = rdiv * adminFee/100;
		rdiv = rdiv - tax;
		require(rdiv < trxBalance,"TRX In-sufficent On Contract");
		uint m = tRate/trxRateDivider;
		users[msg.sender].income[1].totalTokenAirDrop += bal/m;
		users[msg.sender].income[1].lastWithdraw = bal/m;
		users[msg.sender].income[1].lastTimeDividend = systemtime;
		users[msg.sender].mplans[1].maxOut += dayss;
		msg.sender.transfer(rdiv);	
		
		emit WithdrawTrx(msg.sender, rdiv);
	}
	event Withdraw(
    	address add,
    	uint value
    );
	event WithdrawToken(
    	address add,
    	uint value
    );
	event WithdrawTrx(
    	address add,
    	uint256 value
    );
	event Register(
    	address upline,
    	address newMember,
    	uint value
    );
	event ReferalIncome(
    	address newMember,
    	address upline,
    	uint bonus,
		uint8 level
    );
}