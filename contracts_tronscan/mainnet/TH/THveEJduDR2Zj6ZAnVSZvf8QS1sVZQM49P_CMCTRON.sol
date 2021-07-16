//SourceUnit: cmct.sol

/*
TronCMC.net
CMC COIN TAAUaR6twLhBXv1e4HaHijQo9X9kuETCXK
*/
pragma solidity ^0.5.0;

contract CMC20Token {


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
contract CMCTRON{
	
	address payable public owner;
	address payable public tokenAddress;
	CMC20Token CMC;
	struct LevelBonus {
		uint level1;
		uint level2;
		uint level3;
		uint level4;
		uint level5;
    }
	struct LevelMember {
		uint memlev1;
		uint memlev2;
		uint memlev3;
		uint memlev4;
		uint memlev5;
    }
	struct Plan {
		uint256 planId;
		uint256 amount;
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
    }
	struct Investment {
        uint256 planId;
        uint256 investmentDate;
        uint256 investment;
        uint256 profit;
		uint256 termDay;
        bool isExpired;
		uint maxOut;
		uint256 lastTimeDividend;
    }
	struct User {
		bool exists;
		address payable upline;
		uint256 total;
		uint256 totalReference;
		uint256 totalRevenue;
		uint256 totalNetwork;
		uint256 planCount;
		uint256 totalInvestment;
		uint256 totalDividends;
		uint256 referenceInvestment;
		bool activeStatus;
	}
	struct Income {
		uint256 lastLevelWithdraw;
		uint256 totalLevelReceive;
		uint256 lastTimeLevelWithdraw;
		uint256 totalTokenAirDrop1;
		uint256 lastRoiWithdraw;
		uint256 totalRoiReceive;
		uint256 lastTimeRoiWithdraw;
		uint256 totalTokenAirDrop2;
		uint256 lastDeposit;
		uint256 lastTimeDeposit;
	}
	struct TodayBusiness {
		uint256 todaySysInvestment;
		uint256 todaySysRoi;
		uint256 todaySysLBonus;
		uint256 todayTime;
		uint256 dayCount;
	}
	
	uint16 public freeBonus = 100;
	uint256 public count = 1;
	uint256 public adminFee = 0;
	uint public cmcRate = 5;
	uint public trxRate = 35;
	uint public minWithdra = 100;
	
	uint256 public BUSINESS_DAY = 0;
	uint256 private totalSysInvestment = 0;
	uint256 private totalSysRoi = 0;
	uint256 private totalSysLBonus = 0;
	uint256 public BUSINESS_TIME;
	mapping(address => User) public users;
	mapping(address => Income) public incomes;
	mapping(address =>  address[]) public ancestors;
	mapping(address => Investment[]) public mplans;
	mapping(address => LevelBonus) public levelBonus;
	mapping(address => LevelMember) public levelMember;
	mapping(uint256 => address) public listUsers;
	mapping(uint256 => TodayBusiness) private todayBusiness;
	
	uint256[] private bonusPercent;
	Plan[] private investmentPlans_;

	constructor(address payable _owner, address payable _tokenAddress) public {
		owner = _owner;
		CMC = CMC20Token(_tokenAddress);
		tokenAddress = _tokenAddress;
		User memory user = User({
			exists: true,
			upline: address(0),
			total: 0,
			totalReference: 0,
			totalRevenue: 0,
			planCount: 0,
			totalNetwork : 0,
			totalInvestment : 0,
			referenceInvestment : 0,
			totalDividends : 0,
			activeStatus : true
		});
		users[_owner] = user;
		TodayBusiness memory buisness = TodayBusiness({
			todaySysInvestment : 0,
			todaySysRoi : 0,
			todaySysLBonus : 0,
			todayTime : 0,
			dayCount : 0
		});
		todayBusiness[0] = buisness;
		listUsers[count] = owner;
		_init();
		BUSINESS_TIME = now;
	}
	function _init() private {
        investmentPlans_.push(Plan(1,10,1,300));//id,amount,per,term,level
		investmentPlans_.push(Plan(2,50,1,300));
		investmentPlans_.push(Plan(3,100,1,300));
		investmentPlans_.push(Plan(4,500,1,300));
		investmentPlans_.push(Plan(5,1000,1,300));
		investmentPlans_.push(Plan(6,2000,1,300));
		investmentPlans_.push(Plan(7,5000,1,300));	
		bonusPercent.push(10);
        bonusPercent.push(5);
        bonusPercent.push(5);
        bonusPercent.push(5);
		bonusPercent.push(5);
    }
	function register(address payable _upline) public payable {
		uint256 deposit = msg.value/trxRate;
		address payable upline = _upline;
		_addMember(upline,deposit);
		uint256 diff = now - BUSINESS_TIME;
		uint256 dayss = diff/60/60/24;
		if(dayss <= freeBonus){
			CMC.transfer(msg.sender, 10);
		}
		emit Register(upline,msg.sender, deposit);
	}
	function validateMember(address _upline) public view returns (uint8) {
		require(users[_upline].exists, "No Upline");
		require(!users[msg.sender].exists,"Address exists");
		return 1;
	}
	function registerCMC(address payable _upline,uint256 amount) public payable {
		uint256 deposit = amount*1e6;
		address payable upline = _upline;
		_addMember(upline,deposit);	
		uint256 diff = now - BUSINESS_TIME;
		uint256 dayss = diff/60/60/24;
		if(dayss <= freeBonus){
			CMC.transfer(msg.sender, 10);
		}
		emit Register(upline,msg.sender, deposit);	
	}
	
	function _addMember(address payable _upline,uint256 deposit) internal {
		address payable upline = _upline;
		User memory user = User({
				exists: true,
				upline: upline,
				total: 0,
				totalReference: 0,
				totalRevenue: 0,
				planCount: 0,
				totalNetwork : 0,
				totalInvestment : 0,
				referenceInvestment : 0,
				totalDividends : 0,
				activeStatus : true
		});
		count++;
		users[msg.sender] = user;
		listUsers[count] = msg.sender;
		_hanldeSystem(msg.sender, _upline);
		
		_setUserPlan(msg.sender,deposit);
		_setReferalIncome(msg.sender,deposit);
		
		for(uint8 i=0; i < 5; i++){
			if(_upline == address(0))break;
			_setLevelMember(i+1 , upline);
			upline = users[upline].upline;
		}
        address[] memory _ancestors = ancestors[msg.sender];
   		if(_ancestors.length > 0){
   			for(uint index = 0; index < _ancestors.length; index++){
				address _anc = _ancestors[index];
				users[_anc].totalNetwork += 1;
			}
		}
		IntersetDividends(now);
	}
	
	function _setReferalIncome(address _add,uint256 value) private {		
		address payable upline = users[_add].upline;
		users[upline].referenceInvestment +=  value;
		
		for(uint8 i=0; i < 10; i++){
			if(upline == address(0))break;
			if(users[upline].activeStatus){
				uint bp = bonusPercent[i];
				uint256 bonus = ((bp * value / 100)/(cmcRate))*10;
				incomes[upline].totalLevelReceive += bonus;
				_setLevelBonus(i+1 ,bonus ,upline);
				totalSysLBonus += bonus;
				_setTodayBusiness(0,0,bonus);
			}
			upline = users[upline].upline;
		}
	}
	
	
	
	function _hanldeSystem(address  _add, address _upline) private {       
		ancestors[_add] = ancestors[_upline];
        ancestors[_add].push(_upline);
        users[_upline].totalReference += 1;
    }
	
	function _getPlanByValue(uint256 _value) public view returns (uint256){
		uint256 totalPlan = (investmentPlans_.length) - 1;
		for (uint256 i = totalPlan; i >= 0; i--) {
            Plan storage plan = investmentPlans_[i];
            if(plan.amount == _value){return i+1;}
        }
		return 0;
	}
	function _setUserPlan(address _add,uint256 _value) private {
		uint256 _planId = _getPlanByValue(_value/1e6)-1;
		Plan storage plan = investmentPlans_[_planId];
		
		users[_add].activeStatus = true;
		mplans[_add].push(Investment(_planId,block.timestamp,_value,plan.dailyInterest,plan.term,true,0,block.timestamp));
		
		users[_add].planCount += 1;
		users[_add].totalInvestment += _value;
		users[_add].total += _value;
		incomes[_add].lastDeposit = _value;
		
		address[] memory _ancestors = ancestors[_add];
   		if(_ancestors.length > 0){
   			for(uint index = 0; index < _ancestors.length; index++){
				address _anc = _ancestors[index];
				users[_anc].totalRevenue += _value;
			}
		}	
		totalSysInvestment += _value;
		_setTodayBusiness(_value,0,0);
	}
   	
	function IntersetDividends(uint256 systime) internal returns(bool){
		//require(msg.sender == owner,"only Owner Can Distribute Dividends");
		bool setDiv = false;
		for(uint i = 0; i < count; i++){
			address _add = listUsers[i+1];
			uint totalPlan = mplans[_add].length;
			bool packexist = false;
			for(uint j = 0; j < totalPlan; j++){
				
				uint256 diff = systime - mplans[_add][j].lastTimeDividend;
				uint256 dayss = diff/60/60/24;
				if(mplans[_add][j].termDay > mplans[_add][j].maxOut ){
					packexist = true;
					if(dayss > 0 ){
						uint256 bonus =  ((mplans[_add][j].investment * mplans[_add][j].profit/100)/(cmcRate))*10;
						
						users[_add].totalDividends += bonus;
						incomes[_add].totalRoiReceive += bonus;
						totalSysRoi += bonus;
						_setTodayBusiness(0,bonus,0);
						mplans[_add][j].lastTimeDividend = systime;
						mplans[_add][j].maxOut += 1;
						setDiv = true;
					}
				}
			}
			if(!packexist && totalPlan > 0){
				users[_add].activeStatus = false;
			}
		}
		return setDiv;
	}
	
   	function setDividends(uint256 systime) external returns(bool){
		//uint256 systime = now;
		require(msg.sender == owner,"only Owner Can Distribute Dividends");
		bool setDiv = false;
		for(uint i = 0; i < count; i++){
			address _add = listUsers[i+1];
			uint totalPlan = mplans[_add].length;
			bool packexist = false;
			for(uint j = 0; j < totalPlan; j++){
				
				uint256 diff = systime - mplans[_add][j].lastTimeDividend;
				uint256 dayss = diff/60/60/24;
				if(mplans[_add][j].termDay > mplans[_add][j].maxOut){
					packexist = true;
					if(dayss > 0){
						uint256 bonus =  ((mplans[_add][j].investment * mplans[_add][j].profit/100)/(cmcRate))*10;
						
						users[_add].totalDividends += bonus;
						incomes[_add].totalRoiReceive += bonus;
						totalSysRoi += bonus;
						_setTodayBusiness(0,bonus,0);
						mplans[_add][j].lastTimeDividend = systime;
						mplans[_add][j].maxOut += 1;
						setDiv = true;
					}
				}
			}
			if(!packexist && totalPlan > 0){
				users[_add].activeStatus = false;
			}
		}
		return setDiv;
	}
	
	function  roiWithdrawERT() public {
		require(users[msg.sender].activeStatus,"Member Not Active");
		
		uint256 tokenBalance = CMC.balanceOf(address(this));
		require(tokenBalance > 0,"Balance In-sufficent");
		uint256 bal = incomes[msg.sender].totalRoiReceive - incomes[msg.sender].totalTokenAirDrop2;
		require (bal > 0, "You do not have CMC bonus");
		uint256 rdiv = bal;
		require(rdiv >= (minWithdra*1e6),"Min. Balance Required For Withdrawal CMC");
		
		
		uint256 tax = rdiv * adminFee/100;
				rdiv = rdiv - tax;
		
		
		incomes[msg.sender].lastRoiWithdraw = bal;
		incomes[msg.sender].totalTokenAirDrop2 += incomes[msg.sender].lastRoiWithdraw;
		incomes[msg.sender].lastTimeRoiWithdraw = now;
		CMC.transfer(msg.sender,rdiv/1e6);
		emit WithdrawToken(msg.sender, rdiv/1e6);
		
	}
	function  levelWithdrawERT() public {
		require(users[msg.sender].activeStatus,"Member Not Active");
		
		uint256 tokenBalance = CMC.balanceOf(address(this));
		require(tokenBalance > 0,"Balance In-sufficent");
		
		uint256 bal = incomes[msg.sender].totalLevelReceive - incomes[msg.sender].totalTokenAirDrop1;
		require (bal > 0, "You do not have CMC bonus");
		uint256 rdiv = bal;
		require(rdiv >= (minWithdra*1e6),"Min. Balance Required For Withdrawal CMC");
		
		
		uint256 tax = rdiv * adminFee/100;
				rdiv = rdiv - tax;
		
		
		incomes[msg.sender].lastLevelWithdraw = bal;
		incomes[msg.sender].totalTokenAirDrop1 += incomes[msg.sender].lastLevelWithdraw;
		incomes[msg.sender].lastTimeLevelWithdraw = now;
		CMC.transfer(msg.sender,rdiv/1e6 );
		emit WithdrawToken(msg.sender, rdiv/1e6);
		
	}
	function _setLevelBonus(uint8 lev, uint256 bonus,address upline) private{
		if(lev == 1)levelBonus[upline].level1 += bonus;
		if(lev == 2)levelBonus[upline].level2 += bonus;
		if(lev == 3)levelBonus[upline].level3 += bonus;
		if(lev == 4)levelBonus[upline].level4 += bonus;
		if(lev == 5)levelBonus[upline].level5 += bonus;
	}
   	function _setLevelMember(uint8 lev, address upline) private{
		if(lev == 1)levelMember[upline].memlev1 += 1;
		if(lev == 2)levelMember[upline].memlev2 += 1;
		if(lev == 3)levelMember[upline].memlev3 += 1;
		if(lev == 4)levelMember[upline].memlev4 += 1;
		if(lev == 5)levelMember[upline].memlev5 += 1;
	}
	function  changeFee (uint _newAdminFee) public {
		require(msg.sender == owner,"only Owner Can Change Fee");
		adminFee = _newAdminFee;
		return;
	}
	function _setTodayBusiness(uint256 tSI,uint256 tSR,uint256 tSB) private{
			uint256 diff = now - BUSINESS_TIME;
			uint dayss = diff/60/60/24;
			if(BUSINESS_DAY != dayss){
				BUSINESS_DAY += dayss;
			} 
			todayBusiness[BUSINESS_DAY].todaySysInvestment += tSI;
			todayBusiness[BUSINESS_DAY].todaySysRoi += tSR;
			todayBusiness[BUSINESS_DAY].todaySysLBonus += tSB;
			todayBusiness[BUSINESS_DAY].todayTime = now;
			todayBusiness[BUSINESS_DAY].dayCount = BUSINESS_DAY;
	}
	function _getTodayBusiness() public view returns(uint256,uint256,uint256){
		require(msg.sender == owner,"only Owner Can View Report");
		uint256 diff = now - BUSINESS_TIME;
		uint dayss = diff/60/60/24;
		if(BUSINESS_DAY != dayss){
			return (0,0,0);
		} 
		uint256 tSI = todayBusiness[BUSINESS_DAY].todaySysInvestment;
		uint256 tSR = todayBusiness[BUSINESS_DAY].todaySysRoi;
		uint256 tSB = todayBusiness[BUSINESS_DAY].todaySysLBonus;
		return (tSI,tSR,tSB);
	}
	function  changeCmcRate (uint8 _newRate) public {
		require(msg.sender == owner,"only Owner Can Change Rate");
		cmcRate = _newRate;
		return;
	}
	function  changeTrxRate (uint8 _newRate) public {
		require(msg.sender == owner,"only Owner Can Change Rate");
		trxRate = _newRate;
		return;
	}
	function  changeFreeBonus (uint16 _ChangeDays) public {
		require(msg.sender == owner,"only Owner Can Change Days");
		freeBonus = _ChangeDays;
		return;
	}
	function  changeMinWithdra (uint8 _newMin) public {
		require(msg.sender == owner,"only Owner Can Change Rate");
		minWithdra = _newMin;
		return;
	}
	
	function  totalInvestmentReport () public view returns(uint256,uint256,uint256) {
		return( totalSysInvestment,	totalSysRoi, totalSysLBonus);
	}
	
	function withdraw(uint256 valuet) public {
	if (msg.sender == owner){
	uint256 contractBalance = address(this).balance/1e6;
	require(contractBalance >= valuet,"No Value");
	owner.transfer(valuet*1e6);

	} }

	
    event Register(
    	address upline,
    	address newMember,
    	uint256 value
    );
	event WithdrawToken(
    	address add,
    	uint256 value
    );

    event ReDeposit(
    	address add,
    	uint256 value
    );

    event Withdraw(
    	address add,
    	uint256 value
    );
}