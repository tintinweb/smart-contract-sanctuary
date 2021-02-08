/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

pragma solidity 0.5.0;

contract TDTC{
	
	address payable public owner=0xc00fF977DE164aF8e02EA622C242b3AdE3595076;
	struct SponserW {
		uint256 lastWithdraw;
		uint256 totalReceive;
		uint256 lastTimeWithdraw;
	}
	struct LevelW {
		uint256 lastWithdraw;
		uint256 totalReceive;
		uint256 lastTimeWithdraw;
	}
	struct ClubW {
		uint256 lastWithdraw;
		uint256 totalReceive;
		uint256 lastTimeWithdraw;
	}
	struct LevelBonus {
		uint256 bonus;
		uint256 memlev;	
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
	
	
	uint64 private totalAlphaM;
	uint64 private totalBeetaM;
	uint64 private totalGaamaM;
	
	uint private totalAlphaReq = 5;
	uint private totalBeetaReq = 15;
	uint private totalGaamaReq = 25;
	uint256 private totalAlphaR;
	uint256 private totalBeetaR;
	uint256 private totalGaamaR;
	uint256 private totalSponserR;
	uint256 private totalLevelR;
	
	uint64 public latestReferrerCode;
	uint64 private constant REFERRER_CODE = 555; //default
	
	
	
	mapping(uint256 => User) public users;
	mapping(address =>  address[]) public ancestors;
	mapping(address => uint64) public listUsers;
	mapping(address => SponserW) private sponserW;
	mapping(address => LevelW) private levelW;
	mapping(address => ClubW) private clubW;
	mapping(address => UserActive) public userActive;
	
	mapping(address => LevelBonus[]) public levelBonus;
	
	uint256[] private bonusLevel;

	constructor() public {
		owner = msg.sender;
		_init();
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
		bonusLevel.push(25);
        bonusLevel.push(25);
        bonusLevel.push(20);
        bonusLevel.push(15);
		bonusLevel.push(15);
        bonusLevel.push(5);
		bonusLevel.push(5);
        bonusLevel.push(5);
		bonusLevel.push(5);
        bonusLevel.push(5);
		bonusLevel.push(5);
		bonusLevel.push(5);
		bonusLevel.push(5);
		bonusLevel.push(5);
		bonusLevel.push(5);
    }
    
	function register(address payable _upline) public payable {
		address payable upline = _upline;
		uint64 refCode = listUsers[upline];
		require(refCode > 0, "No Upline");
		
		uint64 addrCode = listUsers[msg.sender];
		require(addrCode == 0,"Address exists");
		uint position = latestReferrerCode%3;
		uint64 parentCode = (latestReferrerCode/3)+370;
		require(msg.value == 600 ether, "Sure To Deposit 600 Ether,");
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
		latestReferrerCode += 1; 
		users[latestReferrerCode] = user;
		userActive[msg.sender].activeStatus = true;
		userActive[msg.sender].activateTime = now;
		listUsers[msg.sender] = latestReferrerCode;
		_hanldeSystem(msg.sender, _upline);
		_setReferalIncome(msg.sender,msg.value);
		_setLevelIncome(msg.sender);
		_setClub(upline);
		emit Register(upline,msg.sender, msg.value);
	}
	
	
	
	function _hanldeSystem(address  _add, address _upline) private {       
		ancestors[_add] = ancestors[_upline];
        ancestors[_add].push(_upline);
        users[listUsers[_upline]].totalReference += 1;
    }
	function _setReferalIncome(address _add,uint256 value) private {		
		users[listUsers[_add]].referenceInvestment +=  value;
		address payable upline = users[listUsers[_add]].upline;
		
		for(uint8 i=0; i < 1; i++){
			if(upline == address(0)){break;}
			if(userActive[upline].activeStatus){
				uint bp = 50;
				uint256 bonus = bp * value / 100 ;
				sponserW[upline].totalReceive += bonus;
				upline.transfer(bonus);
			}
			upline = users[listUsers[upline]].upline;
		}
	}
	function _setLevelIncome(address _add) private {		
		uint256 parent = users[listUsers[_add]].parentCode;
		address payable teamAddr = users[parent].addr;
		for(uint8 i=0; i < 15; i++){
			if(teamAddr == address(0)){break;}
			if(userActive[teamAddr].activeStatus){
				uint256 bonus = bonusLevel[i] ;
				levelBonus[teamAddr][i].bonus += bonus;
				levelBonus[teamAddr][i].memlev += 1;
				levelW[teamAddr].totalReceive += bonus;
				if(users[listUsers[teamAddr]].lastActiveLevel < i+1){
					users[listUsers[teamAddr]].lastActiveLevel = i+1;
				}
			}
			parent = users[listUsers[teamAddr]].parentCode;
			teamAddr = users[parent].addr;
		}
	}

	function _setClub(address upline) private {		
		uint8 totalRef = users[listUsers[upline]].totalReference;
		uint256 activateTimes = userActive[upline].activateTime;
		uint256 diff = now - activateTimes;
		uint dayaa = diff/60/60/24;
		uint alpha = userActive[upline].alpha;
		uint beeta = userActive[upline].beeta;
		uint gaama = userActive[upline].gaama;
		if(alpha == 0 && totalRef == totalAlphaReq){
			if(dayaa <= 259200){
				userActive[upline].alpha = 1;
				totalAlphaM += 1;
			}
		}
		alpha = userActive[upline].alpha;
		if(alpha == 1 && beeta == 0 && totalRef == totalAlphaReq+totalBeetaReq){
			if(dayaa <= 864000){
				userActive[upline].beeta = 1;
				totalBeetaM += 1;
			}
		}
		beeta = userActive[upline].beeta;
		if(beeta == 1 && gaama == 0 && totalRef == totalAlphaReq+totalBeetaReq+totalGaamaReq){
			userActive[upline].gaama = 1;
			totalGaamaM += 1;
		}
	}
   
   	
	function withdraw() public payable{
        require(msg.sender == owner,"only Owner Can Withdraw Fund");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Withdraw(owner, cBalance);
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