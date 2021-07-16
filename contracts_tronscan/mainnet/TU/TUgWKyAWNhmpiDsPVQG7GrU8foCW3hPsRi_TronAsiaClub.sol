//SourceUnit: tronAsiaClub.sol

/*
www.TronAsiaClub.io
*/
pragma solidity ^0.5.0;

contract TronAsiaClub{
	
	address payable public owner;
	struct SponserW {
		uint256 lastWithdraw;
		uint256 totalReceive;
		uint256 lastTimeWithdraw;
	}
	struct LevelW {
		uint256 lastWithdraw;
		uint256 totalReceive;
		uint256 totalWithdraw;
		uint256 lastTimeWithdraw;
	}
	struct ClubW {
		uint256 lastWithdraw;
		uint256 totalReceive;
		uint256 totalWithdraw;
		uint256 lastTimeWithdraw;
	}
	struct LevelMemberBonus {
		uint256[] level;
		uint[] memlev;
    }
    struct UserSuccessor {
		uint64[] successorId;
		uint8[] position;
    }
	struct User {
		bool exists;
		address payable addr;
		address payable upline;
		uint64 refCode;
		uint64 parentCode;
		uint position;
		uint8 totalReference;
		uint8 totalNetwork;
		uint256 totalRevenue;
		uint256 referenceInvestment;
		uint256 networkInvestment;
		uint8 lastActiveLevel;
	}
	
	
	struct UserActive {
		bool activeStatus;
		uint256 activateTime;
		uint alpha;
		uint beeta;
		uint gaama;
		uint256 alphaTime;
		uint256 beetaTime;
		uint256 gaamaTime;
		uint256 alphaW;
		uint256 beetaW;
		uint256 gaamaW;
	}
	
	uint64 public count;
	uint64 private totalAlphaM;
	uint64 private totalBeetaM;
	uint64 private totalGaamaM;
	
	uint private totalAlphaReq = 5;
	uint private totalBeetaReq = 15;
	uint private totalGaamaReq = 25;
	
	uint256 private totalAlphaR;//total receive
	uint256 private totalBeetaR;
	uint256 private totalGaamaR;
	
	uint256 private totalSponserR;
	uint256 private totalLevelR;
	
	uint64 public latestReferrerCode;
	uint64 private constant REFERRER_CODE = 555; 
	uint8 private constant MATRIXWIDTH = 3;
	
	uint private ALPHASHARE = 0;
	uint256 private clubLastDistribute; 
	
	uint private constant clubLastDistributeHour = 6;
	uint private constant ALPHALASTBONUS = 5000*1e6;
	uint private constant BEETALASTBONUS = 10000*1e6;
	uint private constant GAAMALASTBONUS = 25000*1e6; 
	
	
	
	mapping(uint256 => User) public users;
	mapping(address =>  address[]) public ancestors;
	mapping(uint256 =>  UserSuccessor) private successor;
	mapping(address => uint64) public listUsers;
	mapping(address => SponserW) private sponserW;
	mapping(address => LevelW) private levelW;
	mapping(address => ClubW) private clubW;
	mapping(address => UserActive) private userActive;
	
	
	mapping(address => LevelMemberBonus) private levelBonus;
	
	uint256[] private bonusLevel;
	address[] private clubAlpha;
	address[] private clubBeeta;
	address[] private clubGaama;
	

	constructor(address payable _owner) public {
		owner = _owner;
		_init();
		count++;
	}
	function _init() private {	
		latestReferrerCode = REFERRER_CODE;
		listUsers[owner] = latestReferrerCode;
		User memory user = User({
			exists: true,
			addr : owner,
			upline: address(0),
			refCode : 0,
			parentCode : 0,
			position : 0,
			totalReference: 0,
			totalNetwork: 0,
			totalRevenue: 0,
			referenceInvestment : 0,
			networkInvestment : 0,
			lastActiveLevel : 0
		});
		
		users[latestReferrerCode] = user;
		userActive[owner].activeStatus = true;
		userActive[owner].activateTime = now;
		clubLastDistribute = block.timestamp;
		for(uint k=0; k < 15; k++){
			levelBonus[msg.sender].memlev.push(0);
		    levelBonus[msg.sender].level.push(0);
		}
		bonusLevel.push(25*1e6);
        bonusLevel.push(25*1e6);
        bonusLevel.push(20*1e6);
        bonusLevel.push(15*1e6);
		bonusLevel.push(10*1e6);
        bonusLevel.push(5*1e6);
		bonusLevel.push(5*1e6);
        bonusLevel.push(5*1e6);
		bonusLevel.push(5*1e6);
        bonusLevel.push(5*1e6);
		bonusLevel.push(5*1e6);
		bonusLevel.push(5*1e6);
		bonusLevel.push(5*1e6);
		bonusLevel.push(5*1e6);
		bonusLevel.push(10*1e6);
    }
	function register(address payable _upline) public payable {
		address payable upline = _upline;
		uint64 refCode = listUsers[upline];
		require(refCode > 0, "No Upline");
		
		uint64 addrCode = listUsers[msg.sender];
		require(addrCode == 0,"Address exists");
		(uint64 parentCode,uint8 position) = bestPosition(refCode);
		
		latestReferrerCode += 1;
		successor[parentCode].successorId.push(latestReferrerCode);
		successor[parentCode].position.push(position);
		
		require(msg.value == 600 trx, "Sure To Deposit 600 TRX,");
		User memory user = User({
            exists: true,
			addr : msg.sender,
			upline: upline,
			refCode : refCode,
			parentCode : parentCode,
			position : position,
			totalReference: 0,
			totalNetwork: 0,
			totalRevenue: 0,
			referenceInvestment : 0,
			networkInvestment : 0,
			lastActiveLevel : 0
		});
		 
		
		
		users[latestReferrerCode] = user;
		userActive[msg.sender].activeStatus = true;
		userActive[msg.sender].activateTime = now;
		listUsers[msg.sender] = latestReferrerCode;
		_hanldeSystem(msg.sender, _upline);
		_setReferalIncome(msg.sender,msg.value);
		
		address[] memory _ancestors = ancestors[msg.sender];
   		if(_ancestors.length > 0){
   			for(uint index = 0; index < _ancestors.length; index++){
				address _anc = _ancestors[index];
				users[listUsers[_anc]].totalNetwork += 1;
				users[listUsers[_anc]].networkInvestment += msg.value;
			}
		}
		for(uint k=0; k < 15; k++){
			levelBonus[msg.sender].memlev.push(0);
		    levelBonus[msg.sender].level.push(0);
		}
		for(uint i=0; i < 15; i++){
			if(users[parentCode].addr == address(0))break;
			_setLevelMember(i+1 , users[parentCode].addr);
			parentCode = users[parentCode].parentCode;
		}
		_setLevelIncome(msg.sender);
		_setClub(upline);
		
		count++;
		uint256 diff = now - clubLastDistribute;
		uint dayss = diff/60/60/clubLastDistributeHour;
		if(dayss > 0){
		    distributeClubIncome();
		    clubLastDistribute = block.timestamp;
		    ALPHASHARE = 50*1e6;
		}
		else{
		    ALPHASHARE += 50*1e6;
		}
		emit Register(upline,msg.sender, msg.value);
	}
	
	
	function bestPosition(uint64 refCode) private returns(uint64,uint8) {
	    uint64[] memory bpm = new uint64[](count);
	    uint8 l = 0;
		bpm[l] = refCode;
		for(uint8 i = 0; i < bpm.length; i++){
			refCode = bpm[i];
			uint8 len = uint8(successor[refCode].successorId.length);
			if(len < MATRIXWIDTH){
				return (refCode,len);
			}
			for(uint8 k = 0; k < len; k++){
				l++;
				bpm[l] = uint64(successor[refCode].successorId[k]);
			}
		}
	}
	
	function _hanldeSystem(address  _add, address _upline) private {       
		ancestors[_add] = ancestors[_upline];
        ancestors[_add].push(_upline);
        users[listUsers[_upline]].totalReference += 1;
		users[listUsers[_upline]].referenceInvestment +=  msg.value;
    }
	function _setReferalIncome(address _add,uint256 value) private {		
		
		address payable upline = users[listUsers[_add]].upline;
		
		for(uint8 i=0; i < 1; i++){
			if(upline == address(0)){break;}
			if(userActive[upline].activeStatus){
				uint bp = 50;
				uint256 bonus = bp * value / 100 ;
				sponserW[upline].totalReceive += bonus;
				totalSponserR += bonus;
				users[listUsers[upline]].totalRevenue += bonus;
				upline.transfer(bonus);
			}
			upline = users[listUsers[upline]].upline;
		}
	}
	function _setLevelIncome(address _add) private {		
		uint64 parentC = users[listUsers[_add]].parentCode;
		address payable teamAddr = users[parentC].addr;
		for(uint8 i=0; i < 15; i++){
			if(teamAddr == address(0)){break;}
			if(userActive[teamAddr].activeStatus){
				uint256 bonuses = bonusLevel[i];
				levelW[teamAddr].totalReceive += bonuses;
				totalLevelR += bonuses;
				users[listUsers[teamAddr]].totalRevenue += bonuses;
				if(users[listUsers[teamAddr]].lastActiveLevel < (i+1)){
					users[listUsers[teamAddr]].lastActiveLevel = (i+1);
				}
				_setLevelBonus(i+1 ,bonuses ,teamAddr);
			}
			parentC = users[listUsers[teamAddr]].parentCode;
			teamAddr = users[parentC].addr;
		}
	}
	function distributeClubIncome() private {
		//require(msg.sender == owner,"only Owner Can Distribute Club Income");
		if(clubAlpha.length > 0){
			uint aLs = ALPHASHARE/clubAlpha.length;
			for(uint i = 0; i < clubAlpha.length; i++){
				address payable addr = users[listUsers[clubAlpha[i]]].addr;
				if(userActive[addr].alphaW < ALPHALASTBONUS){
					clubW[addr].totalReceive += aLs; 
					userActive[addr].alphaW += aLs;
					totalAlphaR += aLs;
					users[listUsers[addr]].totalRevenue += aLs;
					//addr.transfer(aLs);
				}
				else{
					userActive[addr].alpha = 2;
				}
				
			}
		}
		if(clubBeeta.length > 0){
			uint bLs = ALPHASHARE/clubBeeta.length;
			for(uint i = 0; i < clubBeeta.length; i++){
				address payable addr = users[listUsers[clubBeeta[i]]].addr;
				if(userActive[addr].beetaW < BEETALASTBONUS){
					clubW[addr].totalReceive += bLs; 
					userActive[addr].beetaW += bLs;
					totalBeetaR += bLs;
					users[listUsers[addr]].totalRevenue += bLs;
					//addr.transfer(bLs);
				}
				else{
					userActive[addr].beeta = 2;
				}
			}
		}
		if(clubGaama.length > 0){
			uint gLs = ALPHASHARE/clubGaama.length;
			for(uint i = 0; i < clubGaama.length; i++){
				address payable addr = users[listUsers[clubGaama[i]]].addr;
				if(userActive[addr].gaamaW < GAAMALASTBONUS){
					clubW[addr].totalReceive += gLs;
					userActive[addr].gaamaW += gLs;
					totalGaamaR += gLs;
					users[listUsers[addr]].totalRevenue += gLs;
					//addr.transfer(gLs);
				}
				else{
					userActive[addr].gaama = 2;
				}
			}
		}
	}
	function _setClub(address upline) private {		
		uint8 totalRef = users[listUsers[upline]].totalReference;
		if(totalRef > 0){
			uint256 activateTimes = userActive[upline].activateTime;
			uint256 diff = now - activateTimes;
			uint dayaa = diff/60/60/24;
			uint alpha = userActive[upline].alpha;
			uint beeta = userActive[upline].beeta;
			uint gaama = userActive[upline].gaama;
			if(alpha == 0 && totalRef == totalAlphaReq){
				if(dayaa <= 259200){
					userActive[upline].alpha = 1;
					userActive[upline].alphaTime = now;
					totalAlphaM += 1;
					clubAlpha.push(upline);
				
				}
			}
			alpha = userActive[upline].alpha;
			if(alpha == 1 && beeta == 0 && totalRef == totalAlphaReq+totalBeetaReq){
				if(dayaa <= 864000){
					userActive[upline].beeta = 1;
					userActive[upline].beetaTime = now;
					totalBeetaM += 1;
					clubBeeta.push(upline);
				}
			}
			beeta = userActive[upline].beeta;
			if(beeta == 1 && gaama == 0 && totalRef == totalAlphaReq+totalBeetaReq+totalGaamaReq){
				userActive[upline].gaama = 1;
				userActive[upline].gaamaTime = now;
				totalGaamaM += 1;
				clubGaama.push(upline);
			}
		}
	}
	
	function _getMemberBonus(address _addr) public view returns(uint256,uint256,uint256,uint256,uint256,uint256){
		return(
		    userActive[_addr].alphaW,
		    userActive[_addr].beetaW,
		    userActive[_addr].gaamaW,
		    clubW[_addr].totalReceive,
		    sponserW[_addr].totalReceive,
		    levelW[_addr].totalReceive
	    );
	}
	function _getMemberLevelBal(address _addr) public view returns(uint256){
		return( levelW[_addr].totalReceive-levelW[_addr].totalWithdraw);
	}
	function _getMemberClubBal(address _addr) public view returns(uint256){
		return( clubW[_addr].totalReceive-clubW[_addr].totalWithdraw);
	}
	function _getMemberClub(address _addr) public  view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256){
		return(
		    uint256(userActive[_addr].activateTime),
		    uint256(userActive[_addr].alphaTime),
		    uint256(userActive[_addr].beetaTime),
		    uint256(userActive[_addr].gaamaTime),
		    uint256(userActive[_addr].alpha),
		    uint256(userActive[_addr].beeta),
		    uint256(userActive[_addr].gaama)
		);
	}
	function systemReport() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,
	uint256,uint256){
		return(
			count,
			totalAlphaM,
			totalBeetaM,
			totalGaamaM,
			totalAlphaR,
			totalBeetaR,
			totalGaamaR,
			totalSponserR,
			totalLevelR
		);
	}
	function _getMemberNetworkInfo(address _addr) public view returns(uint256,uint256,uint256,uint256,uint256,uint256){
		uint64 uID = listUsers[_addr];
		uint8 totalRef = users[uID].totalReference;
		uint8 totalNet = users[uID].totalNetwork;
		uint256 totalReven = users[uID].totalRevenue;
		uint256 referenceInvest = users[uID].referenceInvestment;
		uint256 networkInvest = users[uID].networkInvestment;
		uint8 lastActive = users[uID].lastActiveLevel;
		return(totalRef,totalNet,totalReven,referenceInvest,networkInvest,lastActive);
	}
	function _getMemberLevelInfo(address _addr) public view returns(uint[] memory, uint[] memory){
		uint cnt = levelBonus[_addr].level.length;
		uint[] memory amount = new uint[](cnt);
        uint[] memory member = new uint[](cnt);
        for (uint i = 0; i < cnt; i++) {
            amount[i] = uint(levelBonus[_addr].level[i]);
            member[i] = uint(levelBonus[_addr].memlev[i]);
        }
		return (amount,member);
	}
	
	
   	
	/*function getUIDByAddress(address _addr) private view returns (uint256) {
        return listUsers[_addr];
    }*/
	
	function _setLevelBonus(uint8 lev, uint256 bonus,address upline) private{
		levelBonus[upline].level[lev-1] += bonus;
	}
   	function _setLevelMember(uint lev, address upline) private{
		levelBonus[upline].memlev[lev-1] += 1;		
	}
	
   	
	function withdraw() public payable{
        require(msg.sender == owner,"only Owner Can Withdraw Fund");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Withdraw(owner, cBalance);
    }
	
	function withdrawLevel() public {
        uint64 uID = listUsers[msg.sender];
		require(uID > 0,"Member Not Registered !!");
		require(users[uID].totalReference >= 5,"Member Have Not 5 Direct For withdrawal !!");
		uint256 balance = levelW[msg.sender].totalReceive-levelW[msg.sender].totalWithdraw;
		require(balance > 100 trx, "Make Sure Your Wallet Balance Gretter Than 100 TRX !!");
		
		levelW[msg.sender].lastWithdraw = balance;
		levelW[msg.sender].totalWithdraw += balance;
		levelW[msg.sender].lastTimeWithdraw = now;
		msg.sender.transfer(balance);
		emit Withdraw(msg.sender, balance);
    }
	
	function withdrawClub() public {
        uint64 uID = listUsers[msg.sender];
		require(uID > 0,"Member Not Registered !!");
		uint256 balance = clubW[msg.sender].totalReceive - clubW[msg.sender].totalWithdraw;
		require(balance > 100 trx, "Make Sure Your Wallet Balance Gretter Than 100 TRX !!");
		
		clubW[msg.sender].lastWithdraw = balance;
		clubW[msg.sender].totalWithdraw += balance;
		clubW[msg.sender].lastTimeWithdraw = now;
		msg.sender.transfer(balance);
		emit Withdraw(msg.sender, balance);
    }

    event Register(
    	address upline,
    	address newMember,
    	uint256 value
    );

    event Withdraw(
    	address add,
    	uint256 value
    );
}