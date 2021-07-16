//SourceUnit: tronator_ver2.sol

pragma solidity ^0.5.9;

contract Tronator  {
    event newRT3Event(address indexed _user, uint _userId, uint indexed _upline, uint indexed _directUpline, address _directUplineAddress);
    event newFT3Event(address indexed _user, uint _userId, uint indexed _upline, uint indexed _directUpline, address _directUplineAddress);
    event payToDirectUplineEvent(address indexed _user, uint _userId, uint indexed _directUpline, address indexed _directUplineAddress, uint value, uint _level, bool result);
    event payToT3UplineEvent(address indexed _user, uint _userId, uint indexed _upline, address indexed _uplineAddress, uint value, uint _level, bool result);
    event payToT4UplineEvent(address indexed _user, uint _userId, uint indexed _upline, address indexed _uplineAddress, uint _directUplineId, uint value, uint _level, bool result);
    event T4LostMoneyEvent(address indexed _user, uint _userId, uint indexed _upline, address indexed _uplineAddress, uint value, uint _level);
    
    event newT4Event(address indexed _user, uint _userId, uint indexed _upline, uint indexed _directUpline);
    event newLevelT4Event(address indexed _user, uint _level);
    
    bool public initSt = true;
    uint public START_TIME = 1604257200; // 11/01/2020 @ 7:00pm (UTC)
    mapping (uint => uint) public LEVEL_PRICE;
    uint public LEVELS_COUNT = 30;
    uint public REF_T3_LIMIT = 3;
    uint public REF_T4_LIMIT = 2;
    uint public REG_FEE = 100 trx;
    
    
    struct UserStructT3 {
        uint id;
        address userAddress;
        uint uplineId;
        uint directUplineId;
        uint[] referrals;
        bool realUser;
        mapping (uint => bool) levels;
        mapping (uint => uint) incomeForLevel;
        uint totalIncome;
        uint directUplineIncome;
        mapping (uint => uint) incomeFromLevel;
    }

    mapping (uint => UserStructT3) public t3Users;
    mapping (address => uint) public t3RealUserList;

    mapping (address => uint[]) public t3FUserList;    
    mapping (uint => uint[]) public t3UsersInLine;

    uint public currUserID = 0;    
    uint public t3CurrLine = 0;
    uint public t3CurrUserInLine = 0;

    struct UserStructT4 {
        uint id;
        address userAddress;
        uint uplineId;
        uint uplineDeth;
        uint directUplineId;
        uint depth;
        mapping (uint => uint[]) referrals;
        mapping (uint => bool) levels;
        mapping (uint => uint) incomeForLevel;
        uint totalIncome;
        mapping (uint => uint) incomeFromLevel;
    }  
    
    mapping (uint => UserStructT4) public t4Users;
    
    
    address id1Address = 0x5966B93806588E507e6D0fEDA5B173458B7153f7;
    address d1 = 0x35A9325b4603e8Cf28d3B65a9b21e9eB7B05a790;
    address d2 = 0xd4E8Ee1893A184312f144a33AD87D74963C77574;
    
    modifier startTimeCome() {
        require(now >= START_TIME, 'The time has not come yet');
        _;
    }    
    
    constructor() public {


        LEVEL_PRICE[1] = 20 trx;
        LEVEL_PRICE[2] = 30 trx;
        LEVEL_PRICE[3] = 50 trx;
        LEVEL_PRICE[4] = 90 trx;
        LEVEL_PRICE[5] = 160 trx;
        LEVEL_PRICE[6] = 300 trx;
        LEVEL_PRICE[7] = 500 trx;
        LEVEL_PRICE[8] = 800 trx;
        LEVEL_PRICE[9] = 1400 trx;
        LEVEL_PRICE[10] = 2500 trx;
        LEVEL_PRICE[11] = 4000 trx;
        LEVEL_PRICE[12] = 7000 trx;
        LEVEL_PRICE[13] = 12000 trx;
        LEVEL_PRICE[14] = 20000 trx;
        LEVEL_PRICE[15] = 30000 trx;
        LEVEL_PRICE[16] = 50000 trx;
        LEVEL_PRICE[17] = 70000 trx;
        LEVEL_PRICE[18] = 100000 trx;
        LEVEL_PRICE[19] = 150000 trx;
        LEVEL_PRICE[20] = 200000 trx;
        LEVEL_PRICE[21] = 300000 trx;
        LEVEL_PRICE[22] = 500000 trx;
        LEVEL_PRICE[23] = 800000 trx;
        LEVEL_PRICE[24] = 1400000 trx;
        LEVEL_PRICE[25] = 2500000 trx;
        LEVEL_PRICE[26] = 4000000 trx;
        LEVEL_PRICE[27] = 7000000 trx;
        LEVEL_PRICE[28] = 10000000 trx;
        LEVEL_PRICE[29] = 15000000 trx;
        LEVEL_PRICE[30] = 25000000 trx;
        
        UserStructT3 memory userStructT3;
        currUserID++;        
        
        userStructT3 = UserStructT3({
            id : currUserID,
            userAddress: id1Address,
            uplineId : 0,
            directUplineId: 1,
            referrals : new uint[](0),
            realUser:true,
            totalIncome:0,
            directUplineIncome:0
        });
        t3RealUserList[id1Address] = userStructT3.id;
        t3Users[userStructT3.id] = userStructT3;
        
        for(uint i =1;i<=LEVELS_COUNT;i++){
            t3Users[userStructT3.id].levels[i] = true;
        }
        
        t3UsersInLine[0].push(1);
        
        emit newRT3Event(id1Address, userStructT3.id, 0, 1, t3Users[userStructT3.uplineId].userAddress);
        
        
        UserStructT4 memory userStructT4;
        
        userStructT4 = UserStructT4({
            id : currUserID,
            userAddress: id1Address,
            uplineId : 0,
            uplineDeth:0,
            directUplineId: 1,
            depth:0,
            totalIncome:0
        });
        
        t4Users[userStructT4.id] = userStructT4;
        t4Users[userStructT4.id].referrals[userStructT4.depth] = new uint[](0);
        
        for(uint i =1;i<=LEVELS_COUNT;i++){
            t4Users[userStructT4.id].levels[i] = true;
        }        
        
        emit newT4Event(id1Address, userStructT4.id, 0, 1);
  
    }
    
    function registration(uint _directUplineId) public payable startTimeCome(){
        require(msg.value==REG_FEE, 'Incorrect Value send');
        require(t3RealUserList[msg.sender]==0, 'User exist');
        require((_directUplineId > 0 && _directUplineId <= currUserID ), 'Incorrect Direct Upline ID');
        require(t3RealUserList[t3Users[_directUplineId].userAddress]==_directUplineId, ' Direct Upline мust be a real user');
        
        currUserID++;
        
        uint t4UplineId = t4PlaceSearch(_directUplineId);
        if(t4UplineId==0){
            t4Users[_directUplineId].depth += 1;
            t4UplineId = _directUplineId;
        }
        
        UserStructT4 memory userStructT4;
        
        userStructT4 = UserStructT4({
            id : currUserID,
            userAddress: msg.sender,
            uplineId : t4UplineId,
            uplineDeth:t4Users[t4UplineId].depth,
            directUplineId: _directUplineId,
            depth:0,
            totalIncome:0
        });
        
        t4Users[userStructT4.id] = userStructT4;
        t4Users[userStructT4.id].levels[1] = true;
        t4Users[userStructT4.id].referrals[userStructT4.depth] = new uint[](0);
        
        t4Users[t4UplineId].referrals[t4Users[t4UplineId].depth].push(userStructT4.id);
        
        _payForLevelT4(userStructT4.id,1);
        emit newT4Event(userStructT4.userAddress, userStructT4.id, userStructT4.uplineId, userStructT4.directUplineId);
           
          
        uint t3UplineId = _t3PlaceSearch();
    
        UserStructT3 memory userStructT3;
        
         userStructT3 = UserStructT3({
            id : currUserID,
            userAddress: msg.sender,
            uplineId : t3UplineId,
            directUplineId: _directUplineId,
            referrals : new uint[](0),
            realUser:true,
            totalIncome:0,
            directUplineIncome:0
        });
        
        t3RealUserList[msg.sender] = userStructT3.id;
        t3Users[userStructT3.id] = userStructT3;
        t3Users[userStructT3.id].levels[1] = true;
        t3Users[userStructT3.uplineId].referrals.push(userStructT3.id);

        t3UsersInLine[t3CurrLine+1].push(userStructT3.id);
        
        emit newRT3Event(msg.sender, userStructT3.id, userStructT3.uplineId, userStructT3.directUplineId, t3Users[userStructT3.directUplineId].userAddress);

        _payForLevelT3(userStructT3.id,LEVEL_PRICE[1],1);
        
        for(uint i =1;i<=3;i++){
            UserStructT3 memory fUserStructT3;
            currUserID++;
            
             fUserStructT3 = UserStructT3({
                id : currUserID,
                userAddress: msg.sender,
                uplineId : userStructT3.id,
                directUplineId: _directUplineId,
                referrals : new uint[](0),
                realUser:false,
                totalIncome:0,
                directUplineIncome:0
            });
            
            t3FUserList[msg.sender].push(fUserStructT3.id);
            t3Users[fUserStructT3.id] = fUserStructT3;
            t3Users[fUserStructT3.id].levels[1] = true;
            t3Users[fUserStructT3.uplineId].referrals.push(fUserStructT3.id);
            t3UsersInLine[t3CurrLine+2].push(fUserStructT3.id);
            
            emit newFT3Event(msg.sender, fUserStructT3.id, userStructT3.uplineId, userStructT3.directUplineId, t3Users[userStructT3.directUplineId].userAddress);
            
            _payForLevelT3(fUserStructT3.id,LEVEL_PRICE[1],1);
        }
        
    }
    
    function buyT4Level() public payable{
        uint userId = t3RealUserList[msg.sender];
        require(userId>0, 'You are not registred');
        
        uint level = 0;
        for(uint i =2;i<=LEVELS_COUNT;i++){
            if(LEVEL_PRICE[i]==msg.value){
                level = i;
                break;
            }
        }   
        require(level!=0, 'Incorrect Value send');
        
        require(t4Users[userId].levels[level]==false, 'You already have this level');
        require(t4Users[userId].levels[level-1]==true, 'You must buy the previous level');
        
        t4Users[userId].levels[level] = true;
        
        _payForLevelT4(userId,level);
        emit newLevelT4Event(t4Users[userId].userAddress, level);
        
    }
    
    function _payForLevelT3(uint _userId, uint _value, uint _level) internal {
        if( (_userId-1)%4==0){

            bool result;
            result = address(uint160(t3Users[t3Users[_userId].directUplineId].userAddress)).send(_value);
            emit payToDirectUplineEvent(t3Users[_userId].userAddress, _userId, t3Users[_userId].directUplineId, t3Users[t3Users[_userId].directUplineId].userAddress, _value, _level, result);
            t3Users[t3Users[_userId].directUplineId].directUplineIncome += _value;

        } else {

            if(_level+1>LEVELS_COUNT){

                bool result;
                result = address(uint160(t3Users[t3Users[_userId].uplineId].userAddress)).send(_value);
                t3Users[t3Users[_userId].uplineId].incomeForLevel[_level+1] += _value;
                emit payToT3UplineEvent(t3Users[_userId].userAddress, _userId, t3Users[_userId].uplineId, t3Users[t3Users[_userId].uplineId].userAddress, _value, (_level+1), result);
                    
                t3Users[t3Users[_userId].uplineId].totalIncome += _value;
                t3Users[t3Users[_userId].uplineId].incomeFromLevel[_level] += _value; 

            }else{

                if(t3Users[t3Users[_userId].uplineId].levels[_level+1]){

                    bool result;
                    result = address(uint160(t3Users[t3Users[_userId].uplineId].userAddress)).send(_value);
                    t3Users[t3Users[_userId].uplineId].incomeForLevel[_level+1] += _value;
                    emit payToT3UplineEvent(t3Users[_userId].userAddress, _userId, t3Users[_userId].uplineId, t3Users[t3Users[_userId].uplineId].userAddress, _value, (_level+1), result);
                    
                    t3Users[t3Users[_userId].uplineId].totalIncome += _value;
                    t3Users[t3Users[_userId].uplineId].incomeFromLevel[_level] += _value;   

                }else{

                    if(t3Users[t3Users[_userId].uplineId].incomeForLevel[_level+1] + _value >= LEVEL_PRICE[_level+1]){

                        uint rest = t3Users[t3Users[_userId].uplineId].incomeForLevel[_level+1] + _value - LEVEL_PRICE[_level+1];
                        bool result;
                        result = address(uint160(t3Users[t3Users[_userId].uplineId].userAddress)).send(rest);  
                        t3Users[t3Users[_userId].uplineId].incomeForLevel[_level+1] += _value;
                        t3Users[t3Users[_userId].uplineId].levels[_level+1] = true;
                        emit payToT3UplineEvent(t3Users[_userId].userAddress, _userId, t3Users[_userId].uplineId, t3Users[t3Users[_userId].uplineId].userAddress, rest, (_level+1), result);
                        
                        t3Users[t3Users[_userId].uplineId].totalIncome += rest;
                        t3Users[t3Users[_userId].uplineId].incomeFromLevel[_level] += rest;                         
                        
                        _payForLevelT3(t3Users[_userId].uplineId, _value-rest,  _level+1); 
                    } else{
                        t3Users[t3Users[_userId].uplineId].incomeForLevel[_level+1] += _value;
                        _payForLevelT3(t3Users[_userId].uplineId, _value,  _level+1);
                    }
                }
            }
        }
    }   
    
    function _payForLevelT4(uint _userId, uint _level) internal {
        uint l1UplineId = t4Users[_userId].uplineId;
        uint value = LEVEL_PRICE[_level];
        
        if(l1UplineId>1){
            l1UplineId = t4Users[l1UplineId].uplineId;    
        }
        
        if(t4Users[l1UplineId].levels[_level]){
            bool result;
            if(l1UplineId>1 && l1UplineId<=62){
                result = address(uint160(t4Users[l1UplineId].userAddress)).send(value/10*9);    
                t4Users[l1UplineId].totalIncome += value/10*9;
                emit payToT4UplineEvent(t4Users[_userId].userAddress, _userId, t4Users[l1UplineId].id, t4Users[l1UplineId].userAddress, t4Users[_userId].directUplineId, value/10*9, _level, result);
                
                result = address(uint160(d1)).send(value/20); 
                result = address(uint160(d2)).send(value/20); 
            }else{
                result = address(uint160(t4Users[l1UplineId].userAddress)).send(value);    
                t4Users[l1UplineId].totalIncome += value;
                emit payToT4UplineEvent(t4Users[_userId].userAddress, _userId, t4Users[l1UplineId].id, t4Users[l1UplineId].userAddress, t4Users[_userId].directUplineId, value, _level, result);
            }

        }else{
           emit T4LostMoneyEvent(t4Users[_userId].userAddress, _userId, t4Users[l1UplineId].id, t4Users[l1UplineId].userAddress, value, _level);
           _payForLevelT4(l1UplineId, _level);
        }
    }
    
    function _t3PlaceSearch() internal returns (uint){
        if(t3UsersPerLine(t3CurrLine+1)<=t3UsersInLine[t3CurrLine+1].length){
            t3CurrLine++;
            t3CurrUserInLine = 0;
            return _t3PlaceSearch();
        } else{
            if(t3Users[t3UsersInLine[t3CurrLine][t3CurrUserInLine]].referrals.length>=REF_T3_LIMIT){
                t3CurrUserInLine++;
                return _t3PlaceSearch();
            } else{
                return t3UsersInLine[t3CurrLine][t3CurrUserInLine];
            }
        }
    }  
    
    function t4PlaceSearch(uint _directUplineId) public view returns (uint){
        uint uplineId = 0;
        
        if(t4Users[_directUplineId].referrals[t4Users[_directUplineId].depth].length<REF_T4_LIMIT){
            uplineId= _directUplineId;
        } else{
            uint ref = t4Users[_directUplineId].referrals[t4Users[_directUplineId].depth][0];
            if(t4Users[ref].referrals[0].length<REF_T4_LIMIT){
                uplineId = ref;
            } else{
                ref = t4Users[_directUplineId].referrals[t4Users[_directUplineId].depth][1];
                if(t4Users[ref].referrals[0].length<REF_T4_LIMIT){
                    uplineId = ref;
                }
            }
        }
        return uplineId;
    }    
    
    function t3UsersPerLine(uint _line) public pure returns (uint) {
        return 3**_line;
    }    
    
    function t3getUserLevelInfo(uint _id, uint _level) public view returns (bool, uint, uint) {
        return (t3Users[_id].levels[_level], t3Users[_id].incomeForLevel[_level], t3Users[_id].incomeFromLevel[_level]);
    }   

    function t3getUserLevelsIncomes(uint _id) public view returns(bool [] memory, uint [] memory, uint [] memory){
        bool [] memory exists = new bool[](LEVELS_COUNT);
        uint [] memory incomesFromLevel = new uint[](LEVELS_COUNT);
        uint [] memory incomesForLevel = new uint[](LEVELS_COUNT);
        for(uint i=0; i<LEVELS_COUNT; i++){
            exists[i] = t3Users[_id].levels[i+1];
            incomesFromLevel[i] = t3Users[_id].incomeFromLevel[i+1];
            incomesForLevel[i] = t3Users[_id].incomeForLevel[i+1];
        }
        return (exists, incomesFromLevel, incomesForLevel);
    } 
    
    function t4getUserLevelInfo(uint _id, uint _level) public view returns (bool) {
        return (t4Users[_id].levels[_level]);
    }   

    function t4GetUserLevels(uint _id) public view returns(bool [] memory){
        bool [] memory exists = new bool[](LEVELS_COUNT);
        for(uint i=0; i<LEVELS_COUNT; i++){
            exists[i] = t4Users[_id].levels[i+1];
        }
        return exists;
    }  
    
    function viewT4Referrals(uint _userId, uint _depth) public view returns(uint[] memory) {
        return t4Users[_userId].referrals[_depth];
    }

    function viewT4ReferralsLevels(uint _userId, uint _level) public view returns(uint[] memory, uint [] memory) {
        uint [] memory ref = new uint[](2);
        uint [] memory directId = new uint[](2);
        if(t4Users[_userId].referrals[0].length>0){
            if(!t4Users[t4Users[_userId].referrals[0][0]].levels[_level]){
                ref[0] = 0;
            } else {
                ref[0] = t4Users[_userId].referrals[0][0];
                directId[0] = t4Users[ref[0]].directUplineId;
            }
        }
        if(t4Users[_userId].referrals[0].length>1){
            if(!t4Users[t4Users[_userId].referrals[0][1]].levels[_level]){
                ref[1] = 0;
            } else {
                ref[1] = t4Users[_userId].referrals[0][1];
                directId[1] = t4Users[ref[1]].directUplineId;
            }
        }
        return (ref, directId);
    }

    function viewT3Referrals(uint _userId) public view returns(uint [] memory){
        return t3Users[_userId].referrals;
    }

    function viewT4AllReferrals(uint _userId) public view returns(uint [] memory, uint [] memory, uint [] memory){
        uint depth = t4Users[_userId].depth;

        uint [] memory usersId = new uint[](t4Users[_userId].depth*2+2);
        uint [] memory levels = new uint[](t4Users[_userId].depth*2+2);
        uint [] memory directId = new uint[](t4Users[_userId].depth*2+2);

        
        
        for(uint i=0; i<=t4Users[_userId].depth; i++){
            if(t4Users[_userId].referrals[i].length>0){
                usersId[i*2] = t4Users[_userId].referrals[i][0];
            }
            
            if(t4Users[_userId].referrals[i].length>1){
                usersId[i*2+1] = t4Users[_userId].referrals[i][1];
            }

            for(uint level=30; level>0; level--){
                if(levels[i*2]==0){
                    bool exist = t4getUserLevelInfo(usersId[i*2], level);
                    if(exist){
                        levels[i*2] = level;
                    }
                }

                if(levels[i*2+1]==0){
                    bool exist = t4getUserLevelInfo(usersId[i*2+1], level);
                    if(exist){
                        levels[i*2+1] = level;
                    }
                }
            }

            directId[i*2] = t4Users[usersId[i*2]].directUplineId;
            directId[i*2+1] = t4Users[usersId[i*2+1]].directUplineId;
        }

        return (usersId, levels, directId);
    }  
    
    function closeInitSt() public  {
        initSt = false;
    }
    

    function initReg(uint _start, uint _stop) public {
        require(initSt == true);
        
        address[16] memory leaders;
        
        leaders[0] = 0xfb83A8E968dEBCC789F113C4BB07d9153158d549;
        leaders[1] = 0xa2dF479f56d78b6B797cEDeEE54155b38F2985C2;
        leaders[2] = 0x84Cb5483b60F5811623a158281DB9e2C8C78Db9C;
        leaders[3] = 0xbdf359352ABC87216CE480315EB0D8217DcaCbbb;
        leaders[4] = 0xa5833A43A23bCcEc0bdb61EC40C8fB6B0BFb7BBb;
        leaders[5] = 0x793302E36C46ae62750971fB01e68Aeb905190f7;
        leaders[6] = 0x66Ac072a82318448365c410d6DBE559629c777De;
        leaders[7] = 0xE2f5DE6B4036b30462D9eC83f4823Bb9bfc5F721;
        leaders[8] = 0x5aEb5eF52Ca2Db3AB4D447734f260142B79abcB0;
        leaders[9] = 0xB5860F88D48618C4Fc07e47e74Ba6757DF063dBf;
        leaders[10] = 0x3e91d339ffadC4a8b824F1c14Fe12E33f20b7087;
        leaders[11] = 0x2bb17a46039787DA92C19799F74b5614551bF594;
        leaders[12] = 0x92E8FA06823C4B6b105934DfCD285ea00b37fEA3;
        leaders[13] = 0xACa4a63CF740bbcf7500054e34F92204987c6352;
        leaders[14] = 0x1456a315Fe13f0A010079ff5e5f468829a6E70b4;
        leaders[15] = 0x89ad0C2492B0659E767ffd8f27759BC57c6E2453;
        
        for(uint i = _start;i<=_stop;i++){
            uint _directUplineId = 1;
            currUserID++;
            
            uint t4UplineId = t4PlaceSearch(_directUplineId);
            if(t4UplineId==0){
                t4Users[_directUplineId].depth += 1;
                t4UplineId = _directUplineId;
            }
            
            UserStructT4 memory userStructT4;
            
            userStructT4 = UserStructT4({
                id : currUserID,
                userAddress: leaders[i],
                uplineId : t4UplineId,
                uplineDeth:t4Users[t4UplineId].depth,
                directUplineId: _directUplineId,
                depth:0,
                totalIncome:0
            });
            
            t4Users[userStructT4.id] = userStructT4;
            for(uint j =1;j<=LEVELS_COUNT;j++){
                t4Users[userStructT4.id].levels[j] = true;
            }
            
            t4Users[userStructT4.id].referrals[userStructT4.depth] = new uint[](0);
            
            t4Users[t4UplineId].referrals[t4Users[t4UplineId].depth].push(userStructT4.id);
            
            _payForLevelT4(userStructT4.id,1);
            emit newT4Event(userStructT4.userAddress, userStructT4.id, userStructT4.uplineId, userStructT4.directUplineId);
               
            uint t3UplineId = _t3PlaceSearch();
        
            UserStructT3 memory userStructT3;
            
             userStructT3 = UserStructT3({
                id : currUserID,
                userAddress: leaders[i],
                uplineId : t3UplineId,
                directUplineId: _directUplineId,
                referrals : new uint[](0),
                realUser:true,
                totalIncome:0,
                directUplineIncome:0
            });
            
            t3RealUserList[leaders[i]] = userStructT3.id;
            t3Users[userStructT3.id] = userStructT3;
            t3Users[userStructT3.id].levels[1] = true;
            t3Users[userStructT3.uplineId].referrals.push(userStructT3.id);
            t3UsersInLine[t3CurrLine+1].push(userStructT3.id);
            
            emit newRT3Event(leaders[i], userStructT3.id, userStructT3.uplineId, userStructT3.directUplineId, t3Users[userStructT3.directUplineId].userAddress);
            _payForLevelT3(userStructT3.id,LEVEL_PRICE[1],1); 
            
            for(uint j =1;j<=3;j++){
                UserStructT3 memory fUserStructT3;
                currUserID++;
                
                 fUserStructT3 = UserStructT3({
                    id : currUserID,
                    userAddress: leaders[i],
                    uplineId : userStructT3.id,
                    directUplineId: _directUplineId,
                    referrals : new uint[](0),
                    realUser:false,
                    totalIncome:0,
                    directUplineIncome:0
                });
                
                t3FUserList[leaders[i]].push(fUserStructT3.id);
                t3Users[fUserStructT3.id] = fUserStructT3;
                t3Users[fUserStructT3.id].levels[1] = true;
                t3Users[fUserStructT3.uplineId].referrals.push(fUserStructT3.id);
                t3UsersInLine[t3CurrLine+2].push(fUserStructT3.id);
                
                emit newFT3Event(leaders[i], fUserStructT3.id, userStructT3.uplineId, userStructT3.directUplineId, t3Users[userStructT3.directUplineId].userAddress);
                
                _payForLevelT3(fUserStructT3.id,LEVEL_PRICE[1],1);
            }
        }
    }        
        
    
    
}