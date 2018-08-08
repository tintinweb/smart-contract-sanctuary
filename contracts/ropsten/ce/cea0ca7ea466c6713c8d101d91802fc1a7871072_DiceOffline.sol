library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public{
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public{
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Config is Pausable {
    // 配置信息
    uint public taxRate;     
    uint256 gasForOraclize;
    uint256 public minStake;
    uint256 public maxStake;
    uint256 public maxWin;
    uint256 public normalRoomMin;
    uint256 public normalRoomMax;
    uint256 public tripleRoomMin;
    uint256 public tripleRoomMax;
    uint referrelFund;
    string random_api_key;

    function Config() public{
        setOraGasLimit(400000);         
        setMinStake(0.1 ether);
        setMaxStake(10 ether);
        setMaxWin(10 ether); 
        taxRate = 20;
        setNormalRoomMin(0.1 ether);
        setNormalRoomMax(1 ether);
        setTripleRoomMin(1 ether);
        setTripleRoomMax(10 ether);
        setRandomApiKey("50faa373-68a1-40ce-8da8-4523db62d42a");
        referrelFund = 10;
    }

    function setRandomApiKey(string value) public onlyOwner {        
        random_api_key = value;
    }           

    function setOraGasLimit(uint256 gasLimit) public onlyOwner {
        if(gasLimit == 0){
            return;
        }
        gasForOraclize = gasLimit;
    }         
    

    function setMinStake(uint256 value) public onlyOwner{
        if(value == 0){
            return;
        }
        minStake = value;
    }

    function setMaxStake(uint256 value) public onlyOwner{
        if(value == 0){
            return;
        }
        maxStake = value;
    }

    function setMaxWin(uint256 value) public onlyOwner{
        if(value == 0){
            return;
        }
        maxWin = value;
    }

    function setNormalRoomMax(uint256 value) public onlyOwner{
        if(value == 0){
            return;
        }
        normalRoomMax = value;
    }

    function setNormalRoomMin(uint256 value) public onlyOwner{
        if(value == 0){
            return;
        }
        normalRoomMin = value;
    }

    function setTripleRoomMax(uint256 value) public onlyOwner{
        if(value == 0){
            return;
        }
        tripleRoomMax = value;
    }

    function setTripleRoomMin(uint256 value) public onlyOwner{
        if(value == 0){
            return;
        }
        tripleRoomMin = value;
    }

    function setTaxRate(uint value) public onlyOwner{
        if(value == 0 || value >= 1000){
            return;
        }
        taxRate = value;
    }

    function setReferralFund(uint value) public onlyOwner{
        if(value == 0 || value >= 1000){
            return;
        }
        referrelFund = value;
    }  
}

contract UserManager {
    struct GameRecord{
        uint256 betAmount;
        uint256 winAmount;
        uint playType;
        uint data;
        uint256 time;
    }
    
    struct UserInfo {         
        uint256 playAmount;
        uint playCount;
        uint openRoomCount;
        uint256 winAmount;
        address referral;
        uint lastRecordIndex;
        GameRecord [10] records;
    }
   
    mapping (address => UserInfo) allUsers;
    
    
    function UserManager() public{        
    }    

    function addBet (address player,uint256 value) internal {        
        allUsers[player].playCount++;
        allUsers[player].playAmount += value;
    }

    function addWin (address player,uint256 value) internal {            
        allUsers[player].winAmount += value;
    }
    
    function addOpenRoomCount (address player) internal {
       allUsers[player].openRoomCount ++;
    }

    function subOpenRoomCount (address player) internal {          
        if(allUsers[player].openRoomCount > 0){
            allUsers[player].openRoomCount--;
        }
    }

    function setReferral (address player,address referral) internal { 
        if(referral == 0)
            return;
        if(allUsers[player].referral == 0 && referral != player){
            allUsers[player].referral = referral;
        }
    }    
    
    function addGameRecord(address addr,uint256 betAmount,uint256 winAmount,uint playType,uint data) internal{        
        GameRecord memory record = GameRecord(betAmount,winAmount,playType,data,now);        
        UserInfo storage user = allUsers[addr];
        user.records[user.lastRecordIndex] = record;        
        user.lastRecordIndex = (user.lastRecordIndex + 1) % user.records.length;
    }

    // public query
    function getMyRecordCount(address player) public view returns(uint) {        
        return allUsers[player].records.length;
    }

    function getMyRecord (address player,uint index)  public view 
        returns(uint256 betAmount,uint256 winAmount,uint playType,uint data,uint256 time) {
        betAmount = 0;
        winAmount = 0;
        playType = 0;
        data = 0;
        time = 0;
        UserInfo storage user = allUsers[player];
        if(index >= user.records.length){
            return;
        }

        GameRecord memory record = user.records[index];
        betAmount = record.betAmount;
        winAmount = record.winAmount;
        playType = record.playType;
        data = record.data;
        time = record.time;
        return;
    }

    function getMyPlayedCount(address player) public view returns(uint) {
        return allUsers[player].playCount;
    }    

    function getMyOpenedCount(address player) public view returns(uint) {
        return allUsers[player].openRoomCount;
    } 

    function getMyPlayedAmount(address player) public view returns(uint256) {
        return allUsers[player].playAmount;
    }

    function getMyWinAmount(address player) public view returns(uint256) {
        return allUsers[player].winAmount;
    }

    function fundReferrel(address player,uint256 value) internal {
        if(allUsers[player].referral != 0){
            allUsers[player].referral.transfer(value);
        }
    }
    
}

contract RoomManager {	
	uint constant roomFree = 0;
	uint constant roomPending = 1;
	uint constant roomEnded = 2;

	struct RoomInfo{
		uint roomid;
		address owner;
		uint setCount;	// 0 if not a tripple room
		uint256 balance;
		uint status;
		uint currentSet;
		uint256 initBalance;
		uint roomData;	// owner choose big(1) or small(0)
		address lastPlayer;
		uint256 lastBet;
	}

	RoomInfo[] roomList;

	uint roomindex;
	

	function RoomManager ()  public {		
		roomindex = 1; // 0 is invalid roomid		
	}

	
	function tryOpenRoom(address owner,uint256 value,uint setCount,uint roomData) internal returns(uint){
		RoomInfo memory room;
		room.owner = owner;
		room.initBalance = value;
		room.balance = value;
		room.setCount = setCount;
		room.roomData = roomData;
		room.roomid = roomindex;
		room.status = roomFree;
		roomindex++;
		if(roomindex == 0){
			roomindex = 1;
		}
		roomList.push(room);		
		return room.roomid;
	}

	function tryCloseRoom(address owner,uint roomid,uint taxrate) internal returns(bool ret,bool taxPayed)  {
		// find the room		
		ret = false;
		taxPayed = false;
		bool bFound = false;
		uint index = 0;
		(index,bFound) = getRoom(roomid);			

		if(!bFound){
			return;
		}
		RoomInfo memory room = roomList[index];
		// is the owner?
		if(room.owner != owner){
			return;
		}
		// 能不能解散
		if(room.status == roomPending){
			return;
		}
		ret = true;
		// return 
		// need to pay tax?
		if(room.balance > room.initBalance){
			uint256 tax = SafeMath.div(SafeMath.mul(room.balance,taxrate),1000);			
			room.balance -= tax;
			taxPayed = true;
		}
		roomList[index].owner.transfer(room.balance);
		deleteRoom(index);
		return;
	}

	function tryDismissRoom(uint roomid) internal {
		// find the room		
		bool bFound = false;
		uint index = 0;
		(index,bFound) = getRoom(roomid);			

		if(!bFound){
			return;
		}
		RoomInfo memory room = roomList[index];
		
		if(room.lastPlayer == 0){
			room.owner.transfer(room.balance);
			deleteRoom(index);
			return;
		}
		room.lastPlayer.transfer(room.lastBet);
		room.owner.transfer(SafeMath.sub(room.balance,room.lastBet));
		deleteRoom(index);
	}	

	// just check if can be rolled and update balance,not calculate here
	function tryRollRoom(address user,uint256 value,uint roomid) internal returns(bool)  {
		if(value <= 0){
			return false;
		}

		bool bFound = false;
		uint index = 0;
		(index,bFound) = getRoom(roomid);	
		if(!bFound)	{
			return false;
		}

		RoomInfo storage room = roomList[index];

		if(room.status != roomFree || room.balance == 0){
			return false;
		}

		uint256 betValue = getBetValue(room.initBalance,room.balance,room.setCount);

		// if value less
		if (value < betValue){
			return false;
		}
		if(value > betValue){
			user.transfer(value - betValue);
			value = betValue;
		}
		// add to room balance
		room.balance += value;
		room.lastPlayer = user;
		room.lastBet = value;
		room.status = roomPending;
		return true;
	}

	// do the calculation
	// returns : success,isend,roomowner,player,winer,winamount
	function calculateRoom(uint roomid,uint result,bool isTriple,uint taxrate) internal returns(bool success,
		bool isend,address roomowner, address player,address winer,uint256 winamount,uint256 tax) {
		success = false;
		bool bFound = false;
		uint index = 0;
		tax = 0;
		(index,bFound) = getRoom(roomid);	
		if(!bFound)	{			
			return;
		}

		RoomInfo storage room = roomList[index];
		if(room.status != roomPending || room.balance == 0){			
			return;
		}

		// ok
		success = true;		

		// simple room
		if(room.setCount == 0){
			tax = SafeMath.div(SafeMath.mul(room.balance,taxrate),1000);
			room.balance -= tax; 
			if(room.roomData == result){
				// owner win				
				winer = room.owner;
			} else {
				// player win				
				winer = room.lastPlayer;
			}
			room.status = roomEnded;			
			winer.transfer(room.balance);
			winamount = room.balance - room.initBalance;
			room.balance = 0;
			isend = true;
			roomowner = room.owner;
			player = room.lastPlayer;
			deleteRoom(index);
			return;
		}
		// triple room
		room.currentSet++;
		isend = room.currentSet >= room.setCount || isTriple;
		if(isend){
			tax = SafeMath.div(SafeMath.mul(room.balance,taxrate),1000);
			room.balance -= tax; 
			if(isTriple){	
				// player win
				winer = room.lastPlayer;
				winamount = room.balance - room.lastBet;
			} else {
				// owner win
				winer = room.owner;
				winamount = room.balance - room.initBalance;
			}
			room.status = roomEnded;
			winer.transfer(room.balance);			
			
			room.balance = 0;
			isend = true;
			roomowner = room.owner;
			player = room.lastPlayer;
			deleteRoom(index);
		} else {
			room.status = roomFree;
		}
		return;
	}

	function getBetValue(uint256 initBalance,uint256 curBalance,uint setCount) public pure returns(uint256) {
		// normal
		if(setCount == 0){
			return initBalance;
		}

		// tripple
		return SafeMath.div(curBalance,setCount);
	}	
	
	function getRoom(uint roomid) internal view returns(uint,bool)  {
		for(uint i = 0;i < roomList.length;i++){
			if(roomList[i].roomid == roomid){
				return (i,true);
			}
		}
		return (0,false);
	}	

	function deleteRoomByRoomID (uint roomid)  internal {
		for(uint i = 0;i < roomList.length;i++){
			if(roomList[i].roomid == roomid){
				deleteRoom(i);
				break;
			}
		}
	}	

	function deleteRoom (uint index) internal {
		uint len = roomList.length;
		if(index > len - 1){
			return;
		}
		if(index < len - 1){
			for(uint i = index;i < len - 1;i++){
	            roomList[i] = roomList[i + 1];
    	    }
    	}
        delete roomList[len - 1];
        roomList.length--;
	}

	function getAllBalance() public view returns(uint256) {
		uint256 ret = 0;
		for(uint i = 0;i < roomList.length;i++){
			ret += roomList[i].balance;
		}
		return ret;
	}
	
	function returnAllBalance() internal {
		for(uint i = 0;i < roomList.length;i++){
			if(roomList[i].balance > 0){
				roomList[i].owner.transfer(roomList[i].balance);
				roomList[i].balance = 0;
				roomList[i].status = roomEnded;
			}
		}
	}

	function removeFreeRoom() internal {
		for(uint i = 0;i < roomList.length;i++){
			if(roomList[i].balance ==0 && roomList[i].status == roomEnded){
				deleteRoom(i);
				removeFreeRoom();
				return;
			}
		}
	}

	function getRoomCount() public view returns(uint) {
		return roomList.length;
	}

	function getRoomID(uint index) public view returns(uint)  {
       	if(index > roomList.length){
       		return 0;
       	}
       	return roomList[index].roomid;
    } 

    function getRoomOwner(uint index) public view returns(address)  {
       	if(index > roomList.length){
       		return 0;
       	}
       	return roomList[index].owner;
    } 

    function getRoomSetCount(uint index) public view returns(uint)  {
       	if(index > roomList.length){
       		return 0;
       	}
       	return roomList[index].setCount;
    } 

    function getRoomBalance(uint index) public view returns(uint256)  {
       	if(index > roomList.length){
       		return 0;
       	}
       	return roomList[index].balance;
    } 

    function getRoomStatus(uint index) public view returns(uint)  {
       	if(index > roomList.length){
       		return 0;
       	}
       	return roomList[index].status;
    } 

    function getRoomCurrentSet(uint index) public view returns(uint)  {
       	if(index > roomList.length){
       		return 0;
       	}
       	return roomList[index].currentSet;
    } 

    function getRoomData(uint index) public view returns(uint)  {
       	if(index > roomList.length){
       		return 0;
       	}
       	return roomList[index].roomData;
    }
}

contract DiceOffline is Config,RoomManager,UserManager {
    //using strings for *; 
    // 事件
    event withdraw_failed(string memo);
    event withdraw_succeeded(address toUser,uint256 value,string memo);    
    event bet_failed(address player,uint256 value,uint result,uint roomid,uint errorcode,string memo);
    event bet_succeeded(address player,uint256 value,uint result,uint roomid,bytes32 serialNumber,string memo);
    event evt_calculate(address player,uint num1,uint num2,uint num3,uint256 winAmount,string memo);
    event evt_createRoomFailed(address player,string memo);
    event evt_createRoomSucceeded(address player,uint roomid,string memo);
    event evt_closeRoomFailed(address player,uint roomid,string memo);
    event evt_closeRoomSucceeded(address player,uint roomid,string memo);
    event logNumber(uint256 value,string memo);
    event logString(string value,string memo); 


    // logs

    // 下注信息
    struct BetInfo{
        address player;
        uint result;
        uint256 value;  
        uint roomid;       
    }

    mapping (bytes32 => BetInfo) rollingBet;

    bool isOffline;

    modifier onlyOraclize {      
        _;
    }   
   
    function DiceOffline() public{
        isOffline = true;
    }  
   
    
    // 销毁合约
    function destroy() onlyOwner public{     
        returnAllRoomsBalance();
        selfdestruct(owner);
    }

    // 充值
    function () public payable {        
    }

    // 提现
    function withdraw(uint256 value) public onlyOwner{
        if(getAvailableBalance() < value){
            emit withdraw_failed("withdraw_failed");
            return;
        }
        owner.transfer(value);  
        emit withdraw_succeeded(owner,value,"withdraw");
    }

    // 获取可提现额度
    function getAvailableBalance() internal view returns (uint256){
        return SafeMath.sub(getBalance(),getAllBalance());
    }

    // 返还所有房间余额
    function returnAllRoomsBalance() internal {
        returnAllBalance();
    }

    function rollSystem (uint result,address referral) public payable returns(bool) {
        if(msg.value == 0){
            return;
        }
        BetInfo memory bet = BetInfo(msg.sender,result,msg.value,0);
       
        if(bet.value < minStake){
            bet.player.transfer(bet.value);
            emit bet_failed(bet.player,bet.value,result,0,0,"bet_failed");
            return false;
        }
        if(bet.value > maxStake){
            bet.player.transfer(SafeMath.sub(bet.value,maxStake));
            bet.value = maxStake;
        }

        if(bet.value > getBalance()){
            bet.player.transfer(bet.value);
            return false;
        }

        addBet(msg.sender,bet.value);
        setReferral(msg.sender,referral);        
        // 生成随机数
        bytes32 serialNumber = doOraclize();
        rollingBet[serialNumber] = bet;
        emit bet_succeeded(bet.player,bet.value,result,0,serialNumber,"bet_succeeded");
        if(isOffline){
            callback(serialNumber);
        }
        return true;
    }   

    // 如果setCount为0，表示大小
    function openRoom(uint setCount,uint roomData,address referral) public payable returns(bool) {
        if(setCount > 35){
            emit evt_createRoomFailed(msg.sender,"createRoomFailed");
            msg.sender.transfer(msg.value);
            return false;
        }
        uint256 minValue = normalRoomMin;
        uint256 maxValue = normalRoomMax;
        if(setCount > 0){
            minValue = tripleRoomMin;
            maxValue = tripleRoomMax;
        }

        if(msg.value < minValue || msg.value > maxValue){
            emit evt_createRoomFailed(msg.sender,"createRoomFailed");
            msg.sender.transfer(msg.value);
            return false;
        } 

        uint roomid = tryOpenRoom(msg.sender,msg.value,setCount,roomData);       
        setReferral(msg.sender,referral);
        addOpenRoomCount(msg.sender);

        emit evt_createRoomSucceeded(msg.sender,roomid,"createRoomSucceeded"); 
    }

    function closeRoom(uint roomid) public returns(bool) {        
        bool ret = false;
        bool taxPayed = false;        
        (ret,taxPayed) = tryCloseRoom(msg.sender,roomid,taxRate);
        if(!ret){
            emit evt_closeRoomFailed(msg.sender,roomid,"closeRoomFailed");
            return false;
        }
        
        emit evt_closeRoomSucceeded(msg.sender,roomid,"closeRoomSucceeded");

        if(!taxPayed){
            subOpenRoomCount(msg.sender);
        }
        
        return true;
    }    

    function rollRoom(uint roomid,address referral) public payable returns(bool) {
        bool ret = tryRollRoom(msg.sender,msg.value,roomid);
        if(!ret){
            emit bet_failed(msg.sender,msg.value,0,roomid,0,"rollRoom return failed");
            msg.sender.transfer(msg.value);
            return false;
        }        
        
        BetInfo memory bet = BetInfo(msg.sender,0,msg.value,roomid);
       
        setReferral(msg.sender,referral);
        addBet(msg.sender,bet.value);
        // 生成随机数
        bytes32 serialNumber = doOraclize();
        rollingBet[serialNumber] = bet;
        emit bet_succeeded(msg.sender,msg.value,0,roomid,serialNumber,"rollRoom");
        if(isOffline){
            callback(serialNumber);
        }
        return true;
    }

    function dismissRoom(uint roomid) public onlyOwner {
        tryDismissRoom(roomid);
    }
    

    function doOraclize() internal returns(bytes32) {        
        uint256 random = uint256(keccak256(block.difficulty,now));
        bytes32 rngId = bytes32(random);
        return rngId;
    }

   
    function callback(bytes32 myid) internal {
        uint num1 = uint256(keccak256(block.difficulty,now)) % 6 + 1;
        uint num2 = uint256(keccak256(block.difficulty,now)) % 6 + 1;
        uint num3 = uint256(keccak256(block.difficulty,now)) % 6 + 1;
        doCalculate(num1,num2,num3,myid);        
    }

    function doCalculate(uint num1,uint num2,uint num3,bytes32 myid) internal {
        BetInfo memory bet = rollingBet[myid];   
        if(bet.player == 0){            
            return;
        }
        uint r = 0;
        if(num1 + num2 + num3 > 10){
            r = 1;
        }
        
        if(bet.roomid == 0){    // 普通房间
            // 进行结算
            uint256 winAmount = 0;
            if(bet.result == r){
                uint256 tax = SafeMath.div(SafeMath.mul(bet.value + bet.value,taxRate),1000);                
                winAmount = bet.value - tax;
                addWin(bet.player,winAmount);              
                bet.player.transfer(bet.value + winAmount);
                fundReferrel(bet.player,SafeMath.div(SafeMath.mul(tax,referrelFund),1000));
            }
            addGameRecord(bet.player,bet.value,winAmount,0,bet.result);
            emit evt_calculate(bet.player,num1,num2,num3,winAmount,"evt_calculate");
            delete rollingBet[myid];
            return;
        }
        doCalculateRoom(num1,num2,num3,myid,r);        
    }

    function doCalculateRoom(uint num1,uint num2,uint num3,bytes32 myid,uint result) internal {
        // 多人房间
        BetInfo memory bet = rollingBet[myid];   
        bool isTriple = (num1 == num2 && num1 == num3);
        bool success;
        bool isend;
        address roomowner;
        address player;
        address winer;
        uint256 winamount;
        uint256 tax;
        (success,isend,roomowner,player,winer,winamount,tax) = calculateRoom(bet.roomid,result,isTriple,taxRate);
        if(!success){
            emit logString("calulateRoom failed","doCalculateRoom");
            return;
        }
        if(isend){
            emit evt_calculate(winer,num1,num2,num3,winamount,"evt_calculate");
            fundReferrel(winer,SafeMath.div(SafeMath.mul(tax,referrelFund),1000));
            if(winer == player){
                addGameRecord(bet.player,bet.value,winamount,1,0);
                emit evt_calculate(roomowner,num1,num2,num3,0,"evt_calculate");    
            } else{
                emit evt_calculate(player,num1,num2,num3,0,"evt_calculate");    
            }

        } else{
            addGameRecord(bet.player,bet.value,0,1,0);
            emit evt_calculate(player,num1,num2,num3,0,"evt_calculate");
        }
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
}