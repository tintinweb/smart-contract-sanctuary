//SourceUnit: troncmc.sol

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
	
	struct Plan {
		uint256 planId;
		uint256 amount;
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
    }
	struct User {
		bool exists;
		address payable upline;
		uint256 planId;
        uint256 investment;
		uint maxOut;
		uint256 lastTimeDividend;
		bool activeStatus;
		uint256 lastLevelWithdraw;
		uint256 totalLevelReceive;
		uint256 totalTokenAirDrop1;
		uint256 lastRoiWithdraw;
		uint256 totalRoiReceive;
		uint256 totalTokenAirDrop2;
	}
	
	
	
	uint256 public count = 1;
	uint public cmcRate = 5;
	uint public trxRate = 35;
	uint public minWithdra = 100;
	
	uint256 private totalSysInvestment = 0;
	uint256 private totalSysRoi = 0;
	uint256 private totalSysLBonus = 0;
	uint256 public BUSINESS_TIME;
	
	mapping(address => User) public users;
	mapping(uint256 => address) public listUsers;
	
	uint256[] private bonusPercent;
	Plan[] private investmentPlans_;

	constructor(address payable _owner, address payable _tokenAddress) public {
		owner = _owner;
		CMC = CMC20Token(_tokenAddress);
		tokenAddress = _tokenAddress;
		User memory user = User({
			exists: true,
			upline: address(0),
			planId : 0,
			investment : 0,
			maxOut : 0,
			lastTimeDividend : 0,
			activeStatus : true,
			lastLevelWithdraw : 0,
    		totalLevelReceive : 0,
    		totalTokenAirDrop1 : 0,
    		lastRoiWithdraw : 0,
    		totalRoiReceive : 0,
    		totalTokenAirDrop2 : 0
		});
		users[_owner] = user;
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
		//CMC.transferFrom(msg.sender,owner,amount);
		emit Register(upline,msg.sender, deposit);	
	}
	
	function _addMember(address payable _upline,uint256 deposit) internal {
		address payable upline = _upline;
		User memory user = User({
				exists: true,
				upline: upline,
				planId : 0,
				investment : 0,
				maxOut : 0,
				lastTimeDividend : 0,
				activeStatus : true,
				lastLevelWithdraw : 0,
        		totalLevelReceive : 0,
        		totalTokenAirDrop1 : 0,
        		lastRoiWithdraw : 0,
        		totalRoiReceive : 0,
        		totalTokenAirDrop2 : 0
		});
		count++;
		users[msg.sender] = user;
		listUsers[count] = msg.sender;
		
		_setUserPlan(msg.sender,deposit);
		_setReferalIncome(msg.sender,deposit);
		
		IntersetDividends(now);
	}
	
	function _setReferalIncome(address _add,uint256 value) private {		
		address payable upline = users[_add].upline;
		
		for(uint8 i=0; i < 5; i++){
			if(upline == address(0))break;
			
			if(users[upline].activeStatus){
				uint bp = bonusPercent[i];
				uint256 bonus = ((bp * value / 100)/(cmcRate))*10;
				users[upline].totalLevelReceive += bonus;
				totalSysLBonus += bonus;
			}
			upline = users[upline].upline;
		}
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
		users[_add].activeStatus = true;
		
		users[_add].planId = _planId;
		users[_add].investment = _value;
		users[_add].lastTimeDividend = now;
		
		totalSysInvestment += _value;
	}
   	
	function IntersetDividends(uint256 systime) internal returns(bool){
		//require(msg.sender == owner,"only Owner Can Distribute Dividends");
		bool setDiv = false;
		for(uint i = 0; i < count; i++){
			address _add = listUsers[i+1];
			bool packexist = false;
			for(uint j = 0; j < 1; j++){
				
				uint256 diff = systime - users[_add].lastTimeDividend;
				uint256 dayss = diff/60/60/24;
				Plan storage plan = investmentPlans_[users[_add].planId];
				uint term = plan.term;
				if(term > users[_add].maxOut ){
					packexist = true;
					if(dayss > 0 ){
						uint256 bonus =  ((users[_add].investment * plan.dailyInterest/100)/(cmcRate))*10;
						
						users[_add].totalRoiReceive += bonus;
						totalSysRoi += bonus;
						users[_add].lastTimeDividend = systime;
						users[_add].maxOut += 1;
						setDiv = true;
					}
				}
			}
			if(!packexist){
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
			bool packexist = false;
			for(uint j = 0; j < 1; j++){
				
				uint256 diff = systime - users[_add].lastTimeDividend;
				uint256 dayss = diff/60/60/24;
				Plan storage plan = investmentPlans_[users[_add].planId];
				uint term = plan.term;
				if(term > users[_add].maxOut ){
					packexist = true;
					if(dayss > 0 ){
						uint256 bonus =  ((users[_add].investment * plan.dailyInterest/100)/(cmcRate))*10;
						
						users[_add].totalRoiReceive += bonus;
						totalSysRoi += bonus;
						users[_add].lastTimeDividend = systime;
						users[_add].maxOut += 1;
						setDiv = true;
					}
				}
			}
			if(!packexist){
				users[_add].activeStatus = false;
			}
		}
		return setDiv;
	}
	
	function  roiWithdrawERT() public {
		require(users[msg.sender].activeStatus,"Member Not Active");
		
		uint256 tokenBalance = CMC.balanceOf(address(this));
		require(tokenBalance > 0,"Balance In-sufficent");
		uint256 bal = users[msg.sender].totalRoiReceive - users[msg.sender].totalTokenAirDrop2;
		require (bal > 0, "You do not have CMC bonus");
		uint256 rdiv = bal;
		require(rdiv >= (minWithdra*1e6),"Min. Balance Required For Withdrawal CMC");
		
		
		
		
		users[msg.sender].lastRoiWithdraw = bal;
		users[msg.sender].totalTokenAirDrop2 += users[msg.sender].lastRoiWithdraw;
		CMC.transfer(msg.sender,rdiv/1e6);
		emit WithdrawToken(msg.sender, rdiv/1e6);
		
	}
	function  levelWithdrawERT() public {
		require(users[msg.sender].activeStatus,"Member Not Active");
		
		uint256 tokenBalance = CMC.balanceOf(address(this));
		require(tokenBalance > 0,"Balance In-sufficent");
		
		uint256 bal = users[msg.sender].totalLevelReceive - users[msg.sender].totalTokenAirDrop1;
		require (bal > 0, "You do not have CMC bonus");
		uint256 rdiv = bal;
		require(rdiv >= (minWithdra*1e6),"Min. Balance Required For Withdrawal CMC");
		
		
		
		
		users[msg.sender].lastLevelWithdraw = bal;
		users[msg.sender].totalTokenAirDrop1 += users[msg.sender].lastLevelWithdraw;
		CMC.transfer(msg.sender,rdiv/1e6 );
		emit WithdrawToken(msg.sender, rdiv/1e6);
		
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