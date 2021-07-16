//SourceUnit: tronplusv2.sol

pragma solidity ^0.5.0;
contract TRC20 {


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


contract TronPlusV2 {
	
	address payable public owner;
	address public dev;
    address payable tokenAddress;
	struct User {
		bool exists;
		uint256 uplineId;
		address addr;
		mapping (uint256 => address) partnerAddress;
		uint256 partners;
		uint256 totalRevenue;
	}

	struct Income {
		bool isReceiveBonus;
		uint256 dayOfWithdraw;
		uint256 lastDeposit;
		uint256 cycle;
		uint256 lastTimeWithdraw;
		uint256 lastTimeDeposit;
        uint256 currentIncome;
		uint256 profitSystem;
		uint256 profitReference;
        uint256 totalReceive;
        uint256 maxOut;
		uint256 totalDeposit;
		uint256 totalTokenAirDrop;
	}



    uint256 public totalOldUser = 0;
	uint256 public count = 1;
	uint256 public daysOfPool = 0;
	uint256 public timeOfPool;
	uint256 public poolInDay =0;
    uint256 public tokenAirdrop = 0;
    uint256 public totalAllTime = 0;
    uint256 public tokenBonusOldUser = 0;
    uint256 public tokenBonusRoundOne = 0;
    uint256 public tokenBonusRoundTwo = 0;
    uint256 public tokenBonusLeader = 0;
    bool public disableSync = false;
	mapping(uint256 => User) public users;
	mapping(uint256 => Income) public incomes;
	mapping(address => uint256) public userId;
	mapping (uint256 => mapping (uint8 => uint256)) public systems;
	mapping (uint8 => uint256) public maching_bonus;
	mapping (uint8 => uint256) public bonusPercent;
	mapping (address => mapping (uint8 => bool)) public rankBonus;
	mapping (uint256 =>  mapping (uint8 => uint256)) public revenues;
	mapping (uint8 => uint256) public rankToMaxDeposit;
	
	
	TronPlus oldContract;
	TRC20 tokenTRP;
	constructor(address payable _owner, address _oldContract, address payable _tokenAddress) public {
        owner = _owner;
        dev = msg.sender;
        oldContract = TronPlus(_oldContract);
        tokenTRP = TRC20(_tokenAddress);
        tokenAddress =_tokenAddress;
        users[1].exists = true;
       	users[1].addr = _owner;
        userId[_owner] = 1;
        timeOfPool = now;
        bonusPercent[1] = 3;
        bonusPercent[2] = 2;
        bonusPercent[3] = 1;
        maching_bonus[1] = 20;
        maching_bonus[2] = 10;
        maching_bonus[3] = 10;
        maching_bonus[4] = 10;
        maching_bonus[5] = 10;
        maching_bonus[6] = 5;
        maching_bonus[7] = 5;
        maching_bonus[8] = 5;
        maching_bonus[9] = 5;
        maching_bonus[10] = 5;
        maching_bonus[11] = 3;
        maching_bonus[12] = 3;
        maching_bonus[13] = 3;
        maching_bonus[14] = 3;
        maching_bonus[15] = 3;
        maching_bonus[16] = 2;
        maching_bonus[17] = 2;
        maching_bonus[18] = 2;
        rankToMaxDeposit[0] = 100000 trx;
        rankToMaxDeposit[1] = 1000000 trx;
        rankToMaxDeposit[2] = 800000 trx;
        rankToMaxDeposit[3] = 500000 trx;
        rankToMaxDeposit[4] = 300000 trx;
        rankToMaxDeposit[5] = 200000 trx;
	}

	function syncMemberFromTronPlus(uint256 _to) public {
		require(msg.sender == dev);
		require (!disableSync);
		
		for(uint256 i= count+1; i <= _to; i++){
			address _add = oldContract.listUsers(i);
			(
 				bool exists,
 				address payable upline,
 				uint256 total,
 				uint256 totalReference,
 				uint256 totalRevenue
 			) = oldContract.users(_add);

 			users[i].exists = exists;
 			users[i].addr = _add;
 			users[i].uplineId = userId[upline];
 			userId[_add] = i;
		}
		
		count = _to;

	}

	function disableSyncData() public {
		require(msg.sender == dev);
		require (!disableSync);
		totalOldUser = count;
		disableSync = true;
	}
	

	function register(address payable _upline) public payable {
		address payable upline = _upline;
		require(users[userId[upline]].exists, "No Upline");
		require(!users[userId[msg.sender]].exists,"Address exists");
		require(msg.value >= 5000 trx && msg.value <=100000 trx, "Greater than or equal min deposit value");
		require(msg.value % 100000000 == 0, "Amount should be in multiple of 100 TRX");
		count++;
		users[count].uplineId = userId[upline];
		users[count].exists = true;
		users[count].addr = msg.sender;
		users[userId[upline]].partners += 1;
		users[userId[upline]].partnerAddress[users[userId[upline]].partners] = msg.sender;
		userId[msg.sender] = count;
		_setIncome(count, msg.value);
		_hanldeMathchingSystem(count, msg.value);
		_bonusTokenOld(count, msg.value);
		owner.transfer(msg.value / 20);
		totalAllTime += msg.value;
		if(now > timeOfPool + 1 days){
			timeOfPool += getQuotient(now - timeOfPool, 1 days) * 1 days;
			poolInDay = msg.value;
		} else {
			poolInDay += msg.value;
		}
		emit Register(upline,msg.sender, msg.value);
	}

	function redeposit() public payable {
        require(users[userId[msg.sender]].exists,"Register first");
		require(msg.value % 100000000 == 0, "Amount should be in multiple of 100 TRX");
		require(msg.value >= incomes[userId[msg.sender]].lastDeposit, "Greater than or equal last deposit");
		require(msg.value <=rankToMaxDeposit[getRank(msg.sender)], "Check your level");
		require(!incomes[userId[msg.sender]].isReceiveBonus, "Only reivest when receive max out");
		_setIncome(userId[msg.sender], msg.value);
		if(incomes[userId[msg.sender]].cycle == 1){
			uint256 uplineId = users[userId[msg.sender]].uplineId;
			users[uplineId].partners += 1;
			users[uplineId].partnerAddress[users[uplineId].partners] = msg.sender;
		}
		_hanldeMathchingSystem(userId[msg.sender], msg.value);
		_bonusTokenOld(userId[msg.sender], msg.value);
		owner.transfer(msg.value / 20);
		totalAllTime += msg.value;
		if(now > timeOfPool + 1 days){
			timeOfPool += getQuotient(now - timeOfPool, 1 days) * 1 days;
			poolInDay = msg.value;
		} else {
			poolInDay += msg.value;
		}
		emit ReDeposit(msg.sender, msg.value);

	}

	function withdraw() public payable {
		uint256 _userId  = userId[msg.sender];
		(uint256 _profitPending , uint256 dayOfWithdraw) = getProfitPending(_userId);
		uint256 profit = incomes[_userId].profitSystem + incomes[_userId].profitReference + _profitPending;
		uint256 value = _getValue(_userId, profit);
		msg.sender.transfer(value * 95 / 100);
		tokenAddress.transfer(value * 5 / 100);
		incomes[_userId].dayOfWithdraw += dayOfWithdraw;
		incomes[_userId].profitSystem = 0;
		incomes[_userId].profitReference = 0;
		incomes[_userId].currentIncome += value;
		incomes[_userId].totalReceive += value;
		incomes[_userId].lastTimeWithdraw += dayOfWithdraw * 1 days;
		_hanldeAncestorProfit(_userId, _profitPending);
		emit Withdraw(msg.sender, value);
	}

	function  withdrawTRP() public {
		require (incomes[userId[msg.sender]].totalTokenAirDrop > 0, "You do not have TRP bonus");
		tokenTRP.transfer(msg.sender, incomes[userId[msg.sender]].totalTokenAirDrop);
		emit WithdrawToken(msg.sender, incomes[userId[msg.sender]].totalTokenAirDrop);
		incomes[userId[msg.sender]].totalTokenAirDrop = 0;
	}
	
	function chagneAddress(address _newAddress) public {
		require (users[userId[msg.sender]].exists, "Register first");
		require (!users[userId[_newAddress]].exists, "Address have been exists");
		userId[_newAddress] = userId[msg.sender];
		userId[msg.sender] = 0;
		emit ChangeAddress(msg.sender, _newAddress);
	}
		
	function _hanldeAncestorProfit(uint256 _userId, uint256 _value) private {
		uint8 level = 1;
   		uint256 uplineId = users[_userId].uplineId;
   		while(level <= 18 && uplineId != 0){
   			if(users[uplineId].partners >= level && incomes[uplineId].isReceiveBonus){
   				incomes[uplineId].profitSystem += _value * maching_bonus[level] / 100;
   			}
   			level++;
			uplineId = users[uplineId].uplineId;
   		}
	}

	function _setIncome(uint256 _userId,uint256 value) private {
		incomes[_userId].isReceiveBonus = true;
		incomes[_userId].dayOfWithdraw = 0;
		incomes[_userId].lastDeposit = value;
		incomes[_userId].cycle += 1;
		incomes[_userId].lastTimeWithdraw = now;
		incomes[_userId].lastTimeDeposit = now;
		incomes[_userId].currentIncome = 0;
		incomes[_userId].profitSystem = 0;
		incomes[_userId].profitReference = 0;
		incomes[_userId].totalDeposit += value;
		incomes[_userId].maxOut = value * 3;
		uint256 uplineId = users[_userId].uplineId;
		for(uint8 i=1; i <=3; i++){
			uint256 bonus = bonusPercent[i] * msg.value / 100 ;
			incomes[uplineId].profitReference += _getValue(uplineId,bonus);
			uplineId = users[uplineId].uplineId;
		}
	}

	function _getValue(uint256 _userId, uint256 _value) private returns (uint256){
		if(!incomes[_userId].isReceiveBonus){
			return 0;
		}
		uint256 result = _value;
		if(incomes[_userId].currentIncome + result < incomes[_userId].maxOut){
			return result;
		} else {
			result = incomes[_userId].maxOut - incomes[_userId].currentIncome;
			incomes[_userId].isReceiveBonus = false;
			return result;
		}
	}


    function getProfitPending(uint256 _userId) public view returns(uint256, uint256){
    	if(!incomes[_userId].isReceiveBonus || incomes[_userId].dayOfWithdraw >= 300){
    		return (0,0);
    	}
    	uint256 timeToInvest = now - incomes[_userId].lastTimeWithdraw;
    	uint256 dayOfReceive = getQuotient(timeToInvest, 1 days);
    	
    	if(incomes[_userId].dayOfWithdraw + dayOfReceive >= 300){
    		dayOfReceive = 300 - incomes[_userId].dayOfWithdraw;
    	}

    	uint256 _profitPending = dayOfReceive * getPercent(_userId) * incomes[_userId].lastDeposit / 10000;
    	return (_profitPending, dayOfReceive);

    }

    function  getMatchingSystem(uint256 _userId) public  view returns(uint256[] memory)  {
    	uint256[] memory result;
    	result = new uint256[](18);
    	for(uint8 i =1; i <=18; i++){
    		result[i-1] = systems[_userId][i];
    	}
    	return result;
    }

    function getRevenuesSystem(uint256 _userId) public  view returns(uint256[] memory)  {
    	uint256[] memory result;
    	result = new uint256[](18);
    	for(uint8 i =1; i <=18; i++){
    		result[i-1] = revenues[_userId][i];
    	}
    	return result;
    }
    

    function getListPartner(uint256 _userId) public view returns(address[] memory) {
    	address[] memory result;
    	result = new address[](users[_userId].partners);
    	for(uint256 i =1; i <= users[_userId].partners; i++){
    		result[i-1] = (users[_userId].partnerAddress[i]);
    	}
    	return result;
    }
    
    
   	function _hanldeMathchingSystem(uint256 _userId, uint256 _value) private {
   		uint8 level = 1;
   		uint256 uplineId = users[_userId].uplineId;
   		while(level <= 18 && uplineId != 0){
   			if(incomes[_userId].cycle == 1){
   				systems[uplineId][level] += 1;
   			}
   			users[uplineId].totalRevenue += _value;
   			revenues[uplineId][level] += _value;
   			level++;
   			uplineId = users[uplineId].uplineId;
   		}
   	}
    
    function  _bonusToken(uint256 _userId, uint256 _value) private {
        if(tokenBonusRoundOne == 80000000 trx && tokenBonusRoundTwo == 60000000 trx ){
            return;
        }
        uint256 bonus;
        
		    if(tokenBonusRoundOne < 80000000 trx){
		        if(tokenBonusRoundOne + _value / 2 >= 80000000 trx){
		            bonus = 80000000 trx - tokenBonusRoundOne + (tokenBonusRoundOne + _value /2 - 80000000 trx) * 2 / 3;
		            tokenBonusRoundTwo = (tokenBonusRoundOne + _value /2 - 80000000 trx) * 2 / 3;
		            tokenBonusRoundOne = 80000000 trx;
		        } else {
		           bonus = _value / 2;
		           tokenBonusRoundOne += _value / 2;
		        }
		    } else {
		         if(tokenBonusRoundTwo < 60000000 trx){
    		        if(tokenBonusRoundTwo + _value / 3 >= 60000000 trx){
    		            bonus = 60000000 trx - tokenBonusRoundTwo;
    		            tokenBonusRoundTwo = 60000000 trx;
    		        } else {
    		           bonus = _value /3;
    		           tokenBonusRoundOne += _value / 3;
    		        }
    		    }
		    }
		    incomes[_userId].totalTokenAirDrop +=  bonus;
		    tokenAirdrop += bonus;
		    return;

    }
   	
   	function  _bonusTokenOld(uint256 _userId, uint256 _value) private {
        if(incomes[_userId].cycle == 1 && _userId <= totalOldUser){
            	(	
	 			    uint256 totalReceive,
					uint256 maxOut
				) = getData(users[_userId].addr);
            if(totalReceive < maxOut * 2 / 9){
                 if(tokenBonusOldUser <= 90000000 trx){
		             incomes[_userId].totalTokenAirDrop +=  _value;
		         	 tokenAirdrop += _value;
		         	 tokenBonusOldUser += _value;
		        }
            } else {
                _bonusToken(_userId, _value);
            }
 		} else {
 		    _bonusToken(_userId, _value);
 		}
    }
    
	function getQuotient(uint256 a, uint256 b) private pure returns (uint256){
        return (a - (a % b))/b;
    }
    
    function getData(address _add) public view returns(uint256, uint256) {
        address member = _add;
         (	bool isReceiveBonus,
					uint256 dayOfWithdraw,
					uint256 lastDeposit,
					uint256 cycle,
					uint256 totalReceive,
					uint256 lastTimeWithdraw,
					uint256 lastTimeDeposit,
					uint256 profitBonusTop,
					uint256 profitSystem,
					uint256 profitReference,
					uint256 maxOut,
					uint256 totalTokenAirDrop
				) = oldContract.incomes(member);
		
		return(totalReceive, maxOut);
    }

    function getPercent(uint256 _userId) public view returns(uint256) {
    	if(incomes[_userId].cycle > 2){
    		return 70;
    	}
        if(_userId > totalOldUser){
            return 80;
        }
 		if(incomes[_userId].cycle == 1){
	 		(	
	 		    uint256 totalReceive,
				uint256 maxOut
			) = getData(users[_userId].addr);
	 		uint256 percent = _getProfitPercent(totalReceive, maxOut);
	 		return percent;
 		}

 		return 80;
    }

    function  transferOutTRP(address payable _add) public {
    	require (msg.sender == dev);
    	if(tokenTRP.balanceOf(address(this)) > 0 ){
    		uint256 total = tokenTRP.balanceOf(address(this));
    		tokenTRP.transfer(_add,total);
    	}
    }
    

    function  getBonusRank() public {
    	if(tokenBonusLeader >= 20000000 trx){
    		return;
    	}
    	uint8 rank = getRank(msg.sender);
    	if(rank == 1 && !rankBonus[msg.sender][1]){
    		tokenTRP.transfer(msg.sender,3000000 trx);
    		rankBonus[msg.sender][1] = true;
    		tokenBonusLeader += 3000000 trx;
    	}
    	if(rank == 2 && !rankBonus[msg.sender][2]){
    		tokenTRP.transfer(msg.sender,1000000 trx);
    		rankBonus[msg.sender][2] = true;
    		tokenBonusLeader += 1000000 trx;
    	}
    	if(rank == 3 && !rankBonus[msg.sender][3]){
    		tokenTRP.transfer(msg.sender,500000 trx);
    		rankBonus[msg.sender][3] = true;
    		tokenBonusLeader += 500000 trx;
    	}
    	if(rank == 4 && !rankBonus[msg.sender][4]){
    		tokenTRP.transfer(msg.sender,300000 trx);
    		rankBonus[msg.sender][4] = true;
    		tokenBonusLeader += 300000 trx;
    	}
    	if(rank == 5 && !rankBonus[msg.sender][5]){
    		tokenTRP.transfer(msg.sender,100000 trx);
    		rankBonus[msg.sender][5] = true;
    		tokenBonusLeader += 100000 trx;
    	}
    	emit Bonus(msg.sender, rank);

    }

    function isBonusRank(address _add,uint8 rank) public view returns(bool) {
     	if(rank == 0){
     		return false;
     	}

     	return rankBonus[_add][rank];
    }
    
    
    function getRank(address _add) public view returns(uint8) {
    	uint256 totalRevenue = users[userId[_add]].totalRevenue;
    	uint256 totalDeposit = incomes[userId[_add]].totalDeposit;
    	if(totalRevenue >= 50000000 trx && totalDeposit >= 500000 trx){
    		return 1;
    	}

    	if(totalRevenue >= 30000000 trx && totalDeposit >= 300000 trx){
    		return 2;
    	}

    	if(totalRevenue >= 10000000 trx && totalDeposit >= 200000 trx){
    		return 3;
    	}

    	if(totalRevenue >= 3000000 trx && totalDeposit >= 100000 trx){
    		return 4;
    	}

    	if(totalRevenue >= 1000000 trx && totalDeposit >= 50000 trx){
    		return 5;
    	}

    	return 0;

    }
    
    
    function _getProfitPercent (uint256 _totalReceive, uint256 _maxOut) private pure returns(uint256)  {
    	uint256 _totalDeposit = _maxOut * 10 / 36;
    	if(_totalReceive >= _totalDeposit / 2 && _totalReceive < _totalDeposit){
    		return 85;
    	} 

    	if(_totalReceive < _totalDeposit / 2){
    		return 90;
    	}

    	if(_totalReceive > _totalDeposit){
    		return 70;
    	}

    	return 80;
    }
    

    event Register(
    	address upline,
    	address newMember,
    	uint256 value
    );

    event MaxOutPaid(
    	address add
    );

    event ReDeposit(
    	address add,
    	uint256 value
    );

    event Withdraw(
    	address add,
    	uint256 value
    );

     event WithdrawToken(
    	address add,
    	uint256 value
    );

     event ChangeAddress(
     	address oldAddr,
     	address newAddr
     );

     event Bonus(
     	address victim,
     	uint8 rank
     );
     
     
}



contract TronPlus {
	struct User {
		bool exists;
		address payable upline;
		uint256 total;
		uint256 totalReference;
		uint256 totalRevenue;
	}
	struct Income {
		bool isReceiveBonus;
		uint256 dayOfWithdraw;
		uint256 lastDeposit;
		uint256 cycle;
		uint256 totalReceive;
		uint256 lastTimeWithdraw;
		uint256 lastTimeDeposit;
		uint256 profitBonusTop;
		uint256 profitSystem;
		uint256 profitReference;
		uint256 maxOut;
		uint256 totalTokenAirDrop;
	}

	mapping(address => User) public users;
	mapping(address => Income) public incomes;
	mapping(uint256 => address) public listUsers;
}