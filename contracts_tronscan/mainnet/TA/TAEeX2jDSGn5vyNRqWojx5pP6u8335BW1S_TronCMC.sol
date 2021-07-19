//SourceUnit: troncmc.sol


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
contract TronCMC{
	
	address payable public owner;
	address payable public tokenAddress;
	CMC20Token CMC;
	
	struct User {
		uint256 id;
		uint256 uid;
        uint256 investment;
		uint256 lastTimeDividend;
		uint256 totalLevelReceive;
		uint256 totalRoiWithdra;
		uint256 activetime;
	}
	
	
	
	uint256 public count = 1;
	uint public cmcRate = 5;
	uint public trxRate = 35;
	uint public minWithdra = 100;
	
	mapping(address => User) public users;
	mapping(address => uint256) public listUsers;
	mapping(uint256 => address) public addrsUsers;
	uint256[] private bonusPercent;

	constructor(address payable _owner, address payable _tokenAddress) public {
		owner = _owner;
		CMC = CMC20Token(_tokenAddress);
		tokenAddress = _tokenAddress;
		User memory user = User({
			id: 1,
			uid: 0,
			investment : 0,
			lastTimeDividend : now,
    		totalLevelReceive : 0,
			totalRoiWithdra : 0,
    		activetime : now
		});
		users[owner] = user;
		listUsers[owner] = count;
		addrsUsers[count] = owner;
		_init();
	}
	function _init() private {
		bonusPercent.push(10);
        bonusPercent.push(5);
        bonusPercent.push(5);
        bonusPercent.push(5);
		bonusPercent.push(5);
    }
	function register(address payable _upline) public payable {
		require(listUsers[msg.sender] == 0,"Member already registered");
		uint256 deposit = msg.value/trxRate;
		address payable upline = _upline;
		_addMember(upline,deposit);
		
		emit Register(upline,msg.sender, deposit);
	}
	
	function registerCMC(address payable _upline,uint256 amount) public payable {
		require(listUsers[msg.sender] == 0,"Member already registered");
		uint256 deposit = amount*1e6;
		address payable upline = _upline;
		_addMember(upline,deposit);	
		//CMC.transferFrom(msg.sender,owner,amount);
		emit Register(upline,msg.sender, deposit);	
	}
	
	function _addMember(address payable _upline,uint256 deposit) internal {
		address payable upline = _upline;
		count++;
		User memory user = User({
				id: count,
				uid: listUsers[upline],
				investment : 0,
				lastTimeDividend : now,
				totalLevelReceive : 0,
				totalRoiWithdra : 0,
				activetime : now
		});
		
		users[msg.sender] = user;
		listUsers[msg.sender] = count;
		addrsUsers[count] = msg.sender;
		users[msg.sender].investment = deposit;
		_setReferalIncome(msg.sender,deposit);
	}
	
	function _setReferalIncome(address _add,uint256 value) private {		
		uint256 uid = users[_add].uid;
		
		for(uint256 i=0; i < 5; i++){
			if(uid == 0)break;
			uint bp = bonusPercent[i];
			uint256 bonus = ((bp * value / 100)/(cmcRate))*10;
			
			users[addrsUsers[uid]].totalLevelReceive += bonus;
			uid = users[addrsUsers[uid]].uid;
		}
	}
	
	
   	function roi_wallet(uint256 systemtime) public view returns(uint256){
		require(users[msg.sender].investment > 0,"Member Not Active");
		uint256 diff = systemtime - users[msg.sender].lastTimeDividend;
		uint256 dayss = diff/60/60/24;
		uint256 balance = 0;
		if(dayss > 0 ){
			uint256 bonus =  ((users[msg.sender].investment * 1/100)/(cmcRate))*10;
			balance = bonus*dayss-users[msg.sender].totalRoiWithdra;
		}
		return balance;
	}
	
	function  roiWithdrawERT() public {
		//require(users[msg.sender].investment > 0,"Member Not Active");
		uint256 bal = roi_wallet(now);
		require(bal/1e6 > 0,"Get Today Roi");
		
		uint256 tokenBalance = CMC.balanceOf(address(this));
		require(tokenBalance > 0,"Balance In-sufficent");
		
		uint256 rdiv = bal/1e6;
		require(rdiv >= (minWithdra),"Min. Balance Required For Withdrawal CMC");
		require(rdiv < tokenBalance,"CMC In-sufficent On Contract");
		
		users[msg.sender].totalRoiWithdra += bal;
		CMC.transfer(msg.sender,rdiv);
		emit WithdrawToken(msg.sender, rdiv);
		
	}
	function  levelWithdrawERT() public {
		//require(users[msg.sender].investment > 0,"Member Not Active");
		
		uint256 tokenBalance = CMC.balanceOf(address(this));
		require(tokenBalance > 0,"Balance In-sufficent");
		
		uint256 bal = users[msg.sender].totalLevelReceive;
		require (bal/1e6 > 0, "You do not have CMC bonus");
		uint256 rdiv = bal;
		require(rdiv >= (minWithdra*1e6),"Min. Balance Required For Withdrawal CMC");
		require(rdiv/1e6 < tokenBalance,"CMC In-sufficent On Contract");
		
		users[msg.sender].totalLevelReceive = 0;
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