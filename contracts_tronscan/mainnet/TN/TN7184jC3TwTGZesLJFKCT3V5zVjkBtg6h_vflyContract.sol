//SourceUnit: vflySmartContract.sol

pragma solidity ^0.5.3;
contract vflyContract{
    struct User{
        uint id;
        address referrer;
        uint partnersCount;
        uint vMaxLevel;
        uint fMaxLevel;
        uint vIncome;
        uint fIncome;
        bool isSilver;
        bool isGold;
        uint silverIncome;
        uint goldIncome;
        uint reBirthDone;
        mapping(uint8 => bool) activeVLevels;
        mapping(uint8 => bool) activeFLevels;
        mapping(uint8 => V) vMatrix;
    }
    struct V{
        address currentReferrer;
        address[] referrals;
        bool isactive;
    }
    struct FMATRIX{
        uint myid;
        address myaddress;
        uint referredById;
        address refferedBy;
        uint downcount;
        uint income;
        uint rebirth;
    }
    uint[9] public FlyLastId=[3,3,3,3,3,3,3,3,3];
    uint[9] public JoinUnder=[1,1,1,1,1,1,1,1,1];
    FMATRIX[] public F1;
    FMATRIX[] public F2;
    FMATRIX[] public F3;
    FMATRIX[] public F4;
    FMATRIX[] public F5;
    FMATRIX[] public F6;
    FMATRIX[] public F7;
    FMATRIX[] public F8;
    FMATRIX[] public F9;
    mapping(uint=>address) public F1USERS;
    mapping(uint=>address) public F2USERS;
    mapping(uint=>address) public F3USERS;
    mapping(uint=>address) public F4USERS;
    mapping(uint=>address) public F5USERS;
    mapping(uint=>address) public F6USERS;
    mapping(uint=>address) public F7USERS;
    mapping(uint=>address) public F8USERS;
    mapping(uint=>address) public F9USERS;
    mapping(uint8 => uint) public levelPrice;
    uint silverAmt=uint(0);
    uint goldAmt=uint(0);
    mapping(uint=>uint) public vToF1;
    mapping(uint=>uint) public vToF2;
    mapping(uint=>uint) public vToF3;
    mapping(uint=>uint) public vToF4;
    mapping(uint=>uint) public vToF5;
    mapping(uint=>uint) public vToF6;
    mapping(uint=>uint) public vToF7;
    mapping(uint=>uint) public vToF8;
    mapping(uint=>uint) public vToF9;
    address public owner;
    address[] doner;
    uint[6] private slabper=[68, 10, 5, 4, 3, 2];
    uint8 public constant maxlevel = 9;
    uint public lastUserId = 1;
    mapping(address => User) public users;
    mapping(uint => address) public userIds;
    address payable private controler0;
    address payable private controler1;
    address payable private controler2;
    address[] public silverIds;
    address[] public rebirthIds;
    address[] public goldIds;
    
    constructor(address _owner) public{
        levelPrice[1] = 50 * 1e6;
        uint8 i;
        for(i=2;i<=9;i++){
            levelPrice[i]=levelPrice[i-1]*3;
        }
        owner=_owner;
        User memory user=User({
            id:1,
            referrer: address(0),
            partnersCount: uint(0),
            vMaxLevel: 9,
            fMaxLevel: 9,
            vIncome:uint(0),
            fIncome: uint(0),
            isSilver:false,
            isGold:false,
            silverIncome:uint(0),
            goldIncome:uint(0),
            reBirthDone:uint(0)
        });
        silverAmt=13473 * 1e6;
        goldAmt=3612 * 1e6;
        users[_owner]=user;
        userIds[1] = _owner;
        for (i = 1; i <= 9; i++) {
            users[_owner].activeVLevels[i] = true;
            users[_owner].activeFLevels[i] = true;
            users[_owner].vMatrix[i].currentReferrer = address(0);
            users[_owner].vMatrix[i].isactive = true;
        }
        
        FMATRIX memory tempStructure =FMATRIX({
           myid:1,
           myaddress:_owner,
           referredById:uint(0),
           refferedBy:address(0),
           downcount:3,
           income:uint(0),
           rebirth:uint(0)
        });
        F1.push(tempStructure);
        F2.push(tempStructure);
        F3.push(tempStructure);
        F4.push(tempStructure);
        F5.push(tempStructure);
        F6.push(tempStructure);
        F7.push(tempStructure);
        F8.push(tempStructure);
        F9.push(tempStructure);
        F1USERS[0]=_owner;
        F2USERS[0]=_owner;
        F3USERS[0]=_owner;
        F4USERS[0]=_owner;
        F5USERS[0]=_owner;
        F6USERS[0]=_owner;
        F7USERS[0]=_owner;
        F8USERS[0]=_owner;
        F9USERS[0]=_owner;
        vToF1[1]=0;
        vToF2[1]=0;
        vToF3[1]=0;
        vToF4[1]=0;
        vToF5[1]=0;
        vToF6[1]=0;
        vToF7[1]=0;
        vToF8[1]=0;
        vToF9[1]=0;
    }
    
    function addcoremember(address _coreMemberAddress, address _coreUnder, uint _coreCount) public returns(string memory){
        require(msg.sender==owner,'Invalid Doner');
        require(!isUserExists(_coreMemberAddress), "user exists");
        require(isUserExists(_coreUnder), "referrer not exists");
        uint32 size;
        assembly {
            size := extcodesize(_coreMemberAddress)
        }
        require(size == 0, "Can not be contracted.");
        lastUserId++;
        User memory user = User({
            id: lastUserId,
            referrer: _coreUnder,
            partnersCount: uint(0),
            vMaxLevel: 9,
            fMaxLevel: 9,
            vIncome:uint(0),
            fIncome: uint(0),
            isSilver:false,
            isGold:false,
            silverIncome:uint(0),
            goldIncome:uint(0),
            reBirthDone:uint(0)
        });
        users[_coreMemberAddress] = user;
        users[_coreMemberAddress].referrer = _coreUnder;
        userIds[lastUserId] = _coreMemberAddress;
        for(uint8 i=1;i<=9;i++){
            users[_coreMemberAddress].activeVLevels[i] = true; 
            users[_coreMemberAddress].activeFLevels[i] = true;
            users[_coreMemberAddress].vMatrix[i].currentReferrer = _coreUnder;
            users[_coreUnder].vMatrix[i].referrals.push(_coreMemberAddress);
            users[_coreMemberAddress].vMatrix[i].isactive = true;
        }
        if(_coreCount==1){
            controler0=address(uint160(_coreMemberAddress));
            goldIds.push(_coreMemberAddress);
        }
        if(_coreCount==2) controler1=address(uint160(_coreMemberAddress));
        if(_coreCount==3) controler2=address(uint160(_coreMemberAddress));
        FMATRIX memory tempStructure =FMATRIX({
           myid:_coreCount+1,
           myaddress:_coreMemberAddress,
           referredById:0,
           refferedBy:owner,
           downcount:uint(0),
           income:uint(0),
           rebirth:uint(0)
        });
        F1.push(tempStructure);
        F2.push(tempStructure);
        F3.push(tempStructure);
        F4.push(tempStructure);
        F5.push(tempStructure);
        F6.push(tempStructure);
        F7.push(tempStructure);
        F8.push(tempStructure);
        F9.push(tempStructure);
        F1USERS[_coreCount]=_coreMemberAddress;
        F2USERS[_coreCount]=_coreMemberAddress;
        F3USERS[_coreCount]=_coreMemberAddress;
        F4USERS[_coreCount]=_coreMemberAddress;
        F5USERS[_coreCount]=_coreMemberAddress;
        F6USERS[_coreCount]=_coreMemberAddress;
        F7USERS[_coreCount]=_coreMemberAddress;
        F8USERS[_coreCount]=_coreMemberAddress;
        F9USERS[_coreCount]=_coreMemberAddress;
        vToF1[_coreCount+1]=_coreCount;
        vToF2[_coreCount+1]=_coreCount;
        vToF3[_coreCount+1]=_coreCount;
        vToF4[_coreCount+1]=_coreCount;
        vToF5[_coreCount+1]=_coreCount;
        vToF6[_coreCount+1]=_coreCount;
        vToF7[_coreCount+1]=_coreCount;
        vToF8[_coreCount+1]=_coreCount;
        vToF9[_coreCount+1]=_coreCount;
        return "Done...";
    }
    
    function invited(address refferdby) payable external returns(string memory){
        registration(msg.sender, refferdby);
        return "Registered Successfully";
    }
    function registrationCreate(address newuser, address refferdby) external returns(string memory){
        require(msg.sender==owner,"Invalid Call");
        registration(newuser, refferdby);
        return "Registered Successfully";
    }
    function registration(address newuser, address refferdby) private{
        if(!(msg.sender==owner)) require(msg.value==levelPrice[1]*2,"Invalid Amount.");    
        require(!isUserExists(newuser), "user exists");
        require(isUserExists(refferdby), "referrer not exists");
        uint32 size;
        assembly {
            size := extcodesize(newuser)
        }
        require(size == 0, "no contract");
        lastUserId++;
        User memory user = User({
            id: lastUserId,
            referrer: refferdby,
            partnersCount: uint(0),
            vMaxLevel: 1,
            fMaxLevel: 0,
            vIncome:uint(0),
            fIncome: uint(0),
            isSilver:false,
            isGold:false,
            silverIncome:uint(0),
            goldIncome:uint(0),
            reBirthDone:uint(0)
        });
        users[newuser] = user;
        users[newuser].referrer = refferdby;
        users[newuser].activeVLevels[1] = true; 
        users[newuser].activeFLevels[1] = true;
        userIds[lastUserId] = newuser;
        users[newuser].vMatrix[1].currentReferrer = refferdby;
        users[refferdby].vMatrix[1].referrals.push(newuser);
        users[refferdby].partnersCount++;
        if(users[refferdby].partnersCount==6){
            users[refferdby].isSilver=true;
            silverIds.push(refferdby);
        }
        if(users[refferdby].partnersCount==150){
            users[refferdby].isGold=true;
            goldIds.push(refferdby);
        }
        users[newuser].vMatrix[1].isactive = true;
        distribute(newuser, 1);
        buyNewF(newuser,1, lastUserId);
    }
    
    function buyNewVFlyLevelAdmin(address _userAddress, uint8 level) external returns(string memory){
        require(msg.sender==owner,"Invalid User");
        buyNewVFlyLevelEnt(_userAddress, level);
        return "Level Bought Successfully";
    }
    
    function buyNewVFlyLevel(uint8 level) external payable returns(string memory){
        buyNewVFlyLevelEnt(msg.sender, level);
        return "Level Bought Successfully";
    }
    
    function buyNewVFlyLevelEnt(address _user, uint8 _levels) private{
        require(isUserExists(_user), "User not exists. Register first.");
        require(_levels > 1 && _levels <= maxlevel, "Invalid level");
        require(users[_user].activeVLevels[_levels]==false, "Level already activated");
        require(users[_user].activeVLevels[_levels-1]==true, "Please activate previous level first.");
        if(!(msg.sender==owner)) require(msg.value == levelPrice[_levels], "Invalid Price");
        users[_user].activeVLevels[_levels] = true;
        users[_user].vMatrix[_levels].isactive = true;
        users[_user].vMaxLevel++;
        distribute(_user,_levels);
        
    }
    function distribute(address _newuser, uint8 _level) private{
        address _seniourid=users[_newuser].referrer;
        address payable toPay;
        uint sid=users[_seniourid].id;
        uint8 maxs=0;
        while((sid >= 1) && (maxs<=5)){
            if(users[_seniourid].vMatrix[_level].isactive==true){
                toPay=address(uint160(_seniourid));
                if(!(msg.sender==owner)) toPay.transfer(levelPrice[_level] * slabper[maxs]/100);
                users[_seniourid].vIncome+= levelPrice[_level] * slabper[maxs]/100;
                _seniourid=users[_seniourid].referrer;
                sid=users[_seniourid].id;
                maxs++; 
            }else{
                _seniourid=users[_seniourid].referrer;
                sid=users[_seniourid].id;
            }
        }
        goldAmt+=levelPrice[_level]*8/100;
    }
    
    function buyNewFFlyLevelAdmin(address _user, uint8 level) external returns(string memory){
        require(msg.sender==owner,"Invalid User");
        buyNewF(_user, level, users[_user].id);
        return "Level Bought Successfully";
    }
    
    function buyNewFFlyLevel(uint8 level) external payable returns(string memory){
       buyNewF(msg.sender, level, users[msg.sender].id);
       return "Level Bought Successfully";
    }
    
    function getActiveId(uint _level) private returns(uint, uint, address){
        uint _joinUnder=JoinUnder[_level-1];
        FlyLastId[_level-1]++;
        uint _lastId=FlyLastId[_level-1];
        address _joinUserAddress;
        if(_level==1) _joinUserAddress=F1USERS[_joinUnder];
        if(_level==2) _joinUserAddress=F2USERS[_joinUnder];
        if(_level==3) _joinUserAddress=F3USERS[_joinUnder];
        if(_level==4) _joinUserAddress=F4USERS[_joinUnder];
        if(_level==5) _joinUserAddress=F5USERS[_joinUnder];
        if(_level==6) _joinUserAddress=F6USERS[_joinUnder];
        if(_level==7) _joinUserAddress=F7USERS[_joinUnder];
        if(_level==8) _joinUserAddress=F8USERS[_joinUnder];
        if(_level==9) _joinUserAddress=F9USERS[_joinUnder];
        
        return (_lastId, _joinUnder, _joinUserAddress);
    }
    
    function buyNewF(address _user, uint8 _level, uint _lastUserId) private {
        if(!(msg.sender==owner)){
            if(_level==1){
                require(msg.value==levelPrice[_level]*2,"Invalid Amount");
            }else{
                require(msg.value==levelPrice[_level],"Invalid Amount");
                require(_level > 1 && _level <= maxlevel, "Invalid level");
            }
        }else{
            
        }
        require(isUserExists(_user), "User not exists. Register first.");
        (uint _lastId, uint _joinUnderId, address _joinUserAddress) = getActiveId(_level);
        FMATRIX memory tempStructure =FMATRIX({
           myid:_lastId,
           myaddress:_user,
           referredById:_joinUnderId,
           refferedBy:_joinUserAddress,
           downcount:uint(0),
           income:uint(0),
           rebirth:uint(0)
        });
        if(_level==1){
            F1.push(tempStructure);
            F1USERS[_lastId]=_user;
            vToF1[_lastUserId]=_lastId;
        }
        if(_level==2){
            F2.push(tempStructure);
            F2USERS[_lastId]=_user;
            vToF2[_lastUserId]=_lastId;
        }
        if(_level==3){
            F3.push(tempStructure);
            F3USERS[_lastId]=_user;
            vToF3[_lastUserId]=_lastId;
        }
        if(_level==4){
            F4.push(tempStructure);
            F4USERS[_lastId]=_user;
            vToF4[_lastUserId]=_lastId;
        }
        if(_level==5){
            F5.push(tempStructure);
            F5USERS[_lastId]=_user;
            vToF5[_lastUserId]=_lastId;
        }
        if(_level==6){
            F6.push(tempStructure);
            F6USERS[_lastId]=_user;
            vToF6[_lastUserId]=_lastId;
        }
        if(_level==7){
            F7.push(tempStructure);
            F7USERS[_lastId]=_user;
            vToF7[_lastUserId]=_lastId;
        }
        if(_level==8){
            F8.push(tempStructure);
            F8USERS[_lastId]=_user;
            vToF8[_lastUserId]=_lastId;
        }
        if(_level==9){
            F9.push(tempStructure);
            F9USERS[_lastId]=_user;
            vToF9[_lastUserId]=_lastId;
        }
        //uplineIncrease(_level, _joinUnderId);
        uplineIncrease(_level);
        users[_user].fMaxLevel++;
    }
    function uplineIncrease(uint8 _level) private{
        uint _joinUnderId = JoinUnder[_level-1];
        uint i=1;
        if(_level==1){
            uint refid;
            uint passrefid;
            address refAdd;
            F1[_joinUnderId].downcount++;
            passrefid=_joinUnderId;
            refid=F1[_joinUnderId].referredById;
            refAdd=F1[_joinUnderId].refferedBy;
            while((refid>=0)&&(i<=4)){
               F1[refid].downcount++;
               if(refid==0) break;
               refid=F1[refid].referredById;
               refAdd=F1[refid].refferedBy;
               i++;
            }
            if(F1[passrefid].downcount==3){
               JoinUnder[_level-1]++;
               slabDistribute(passrefid, _level);
            }
        }
        
        if(_level==2){
            uint refid;
            uint passrefid;
            address refAdd;
            F2[_joinUnderId].downcount++;
            passrefid=_joinUnderId;
            refid=F2[_joinUnderId].referredById;
            refAdd=F2[_joinUnderId].refferedBy;
           while((refid>=0)&&(i<=4)){
               F2[refid].downcount++;
               if(refid==0) break;
               refid=F2[refid].referredById;
               refAdd=F2[refid].refferedBy;
               i++;
           }
           if(F2[passrefid].downcount==3){
               JoinUnder[_level-1]++;
               slabDistribute(passrefid, _level);
           }
        }
        
        if(_level==3){
            uint refid;
            uint passrefid;
            address refAdd;
            F3[_joinUnderId].downcount++;
            passrefid=_joinUnderId;
            refid=F3[_joinUnderId].referredById;
            refAdd=F3[_joinUnderId].refferedBy;
           while((refid>=0)&&(i<=4)){
               F3[refid].downcount++;
               if(refid==0) break;
               refid=F3[refid].referredById;
               refAdd=F3[refid].refferedBy;
               i++;
           }
           if(F3[passrefid].downcount==3){
               JoinUnder[_level-1]++;
               slabDistribute(passrefid, _level);
           }
        }
        
        if(_level==4){
            uint refid;
            uint passrefid;
            address refAdd;
            F4[_joinUnderId].downcount++;
            passrefid=_joinUnderId;
            refid=F4[_joinUnderId].referredById;
            refAdd=F4[_joinUnderId].refferedBy;
           while((refid>=0)&&(i<=4)){
               F4[refid].downcount++;
               if(refid==0) break;
               refid=F4[refid].referredById;
               refAdd=F4[refid].refferedBy;
               i++;
           }
           if(F4[passrefid].downcount==3){
               JoinUnder[_level-1]++;
               slabDistribute(passrefid, _level);
           }
        }
        
        if(_level==5){
            uint refid;
            uint passrefid;
            address refAdd;
            F5[_joinUnderId].downcount++;
            passrefid=_joinUnderId;
            refid=F5[_joinUnderId].referredById;
            refAdd=F5[_joinUnderId].refferedBy;
           while((refid>=0)&&(i<=4)){
               F5[refid].downcount++;
               if(refid==0) break;
               refid=F5[refid].referredById;
               refAdd=F5[refid].refferedBy;
               i++;
           }
           if(F5[passrefid].downcount==3){
               JoinUnder[_level-1]++;
               slabDistribute(passrefid, _level);
           }
        }
        
        if(_level==6){
            uint refid;
            uint passrefid;
            address refAdd;
            F6[_joinUnderId].downcount++;
            passrefid=_joinUnderId;
            refid=F6[_joinUnderId].referredById;
            refAdd=F6[_joinUnderId].refferedBy;
           while((refid>=0)&&(i<=4)){
               F6[refid].downcount++;
               if(refid==0) break;
               refid=F6[refid].referredById;
               refAdd=F6[refid].refferedBy;
               i++;
           }
           if(F6[passrefid].downcount==3){
               JoinUnder[_level-1]++;
               slabDistribute(passrefid, _level);
           }
        }
        
        if(_level==7){
            uint refid;
            uint passrefid;
            address refAdd;
            F7[_joinUnderId].downcount++;
            passrefid=_joinUnderId;
            refid=F7[_joinUnderId].referredById;
            refAdd=F7[_joinUnderId].refferedBy;
           while((refid>=0)&&(i<=4)){
               F7[refid].downcount++;
               if(refid==0) break;
               refid=F7[refid].referredById;
               refAdd=F7[refid].refferedBy;
               i++;
           }
           if(F7[passrefid].downcount==3){
               JoinUnder[_level-1]++;
               slabDistribute(passrefid, _level);
           }
        }
        
        if(_level==8){
            uint refid;
            uint passrefid;
            address refAdd;
            F8[_joinUnderId].downcount++;
            passrefid=_joinUnderId;
            refid=F8[_joinUnderId].referredById;
            refAdd=F8[_joinUnderId].refferedBy;
           while((refid>=0)&&(i<=4)){
               F8[refid].downcount++;
               if(refid==0) break;
               refid=F8[refid].referredById;
               refAdd=F8[refid].refferedBy;
               i++;
           }
           if(F8[passrefid].downcount==3){
               JoinUnder[_level-1]++;
               slabDistribute(passrefid, _level);
           }
        }
        
        if(_level==9){
            uint refid;
            uint passrefid;
            address refAdd;
            F9[_joinUnderId].downcount++;
            passrefid=_joinUnderId;
            refid=F9[_joinUnderId].referredById;
            refAdd=F9[_joinUnderId].refferedBy;
           while((refid>=0)&&(i<=4)){
               F9[refid].downcount++;
               if(refid==0) break;
               refid=F9[refid].referredById;
               refAdd=F9[refid].refferedBy;
               i++;
           }
           if(F9[passrefid].downcount==3){
               JoinUnder[_level-1]++;
               slabDistribute(passrefid, _level);
           }
        }
    }
    function slabDistribute(uint passrefid, uint8 _level) private{
        uint _activeId=passrefid;
        uint x=_activeId;
        address payable toPay;
        uint amount;
        if(_level==1){
            amount = levelPrice[_level];
            toPay=address(uint160(F1[_activeId].myaddress));
            if(!(msg.sender==owner)) toPay.transfer(amount);
            F1[_activeId].income+=amount;
            _activeId=F1[_activeId].referredById;
            if(F1[_activeId].downcount==12){
                amount = levelPrice[_level]*2;
                toPay=address(uint160(F1[_activeId].myaddress));
                if(!(msg.sender==owner)) toPay.transfer(amount);
                F1[_activeId].income+=amount;
                _activeId=F1[_activeId].referredById;
                if(F1[_activeId].downcount==39){
                    amount = levelPrice[_level]*4;
                    toPay=address(uint160(F1[_activeId].myaddress));
                    if(!(msg.sender==owner)) toPay.transfer(amount);
                    F1[_activeId].income+=amount;
                    _activeId=F1[_activeId].referredById;
                    if(F1[_activeId].downcount==120){
                        amount = (levelPrice[_level]*8)-(levelPrice[_level]);
                        toPay=address(uint160(F1[_activeId].myaddress));
                        if(!(msg.sender==owner)) toPay.transfer(amount);
                        F1[_activeId].income+=amount;
                        F1[_activeId].rebirth=1;
                        rebirthIds.push(toPay);
                        buyNewF(F1[_activeId].myaddress, _level, x);
                        //autodisbrust();
                    }
                }
            }
            
        }
        
        if(_level==2){
            amount = levelPrice[_level];
            toPay=address(uint160(F2[_activeId].myaddress));
            if(!(msg.sender==owner)) toPay.transfer(amount);
            F2[_activeId].income+=amount;
            _activeId=F2[_activeId].referredById;
            if(F2[_activeId].downcount==12){
                amount = levelPrice[_level]*2;
                toPay=address(uint160(F2[_activeId].myaddress));
                if(!(msg.sender==owner)) toPay.transfer(amount);
                F2[_activeId].income+=amount;
                _activeId=F2[_activeId].referredById;
                if(F2[_activeId].downcount==39){
                    amount = levelPrice[_level]*4;
                    toPay=address(uint160(F2[_activeId].myaddress));
                    if(!(msg.sender==owner)) toPay.transfer(amount);
                    F2[_activeId].income+=amount;
                    _activeId=F2[_activeId].referredById;
                    if(F2[_activeId].downcount==120){
                        amount = (levelPrice[_level]*8)-(levelPrice[_level]);
                        toPay=address(uint160(F2[_activeId].myaddress));
                        if(!(msg.sender==owner)) toPay.transfer(amount);
                        F2[_activeId].income+=amount;
                        F2[_activeId].rebirth=1;
                        buyNewF(F2[_activeId].myaddress, _level, x);
                        //autodisbrust();
                    }
                }
            }
            
        }
        
        if(_level==3){
            amount = levelPrice[_level];
            toPay=address(uint160(F3[_activeId].myaddress));
            if(!(msg.sender==owner)) toPay.transfer(amount);
            F3[_activeId].income+=amount;
            _activeId=F3[_activeId].referredById;
            if(F3[_activeId].downcount==12){
                amount = levelPrice[_level]*2;
                toPay=address(uint160(F3[_activeId].myaddress));
                if(!(msg.sender==owner)) toPay.transfer(amount);
                F3[_activeId].income+=amount;
                _activeId=F3[_activeId].referredById;
                if(F3[_activeId].downcount==39){
                    amount = levelPrice[_level]*4;
                    toPay=address(uint160(F3[_activeId].myaddress));
                    if(!(msg.sender==owner)) toPay.transfer(amount);
                    F3[_activeId].income+=amount;
                    _activeId=F3[_activeId].referredById;
                    if(F3[_activeId].downcount==120){
                        amount = (levelPrice[_level]*8)-(levelPrice[_level]);
                        toPay=address(uint160(F3[_activeId].myaddress));
                        if(!(msg.sender==owner)) toPay.transfer(amount);
                        F3[_activeId].income+=amount;
                        F3[_activeId].rebirth=1;
                        buyNewF(F3[_activeId].myaddress, _level, x);
                        //autodisbrust();
                    }
                }
            }
            
        }
        
        if(_level==4){
            amount = levelPrice[_level];
            toPay=address(uint160(F4[_activeId].myaddress));
            if(!(msg.sender==owner)) toPay.transfer(amount);
            F4[_activeId].income+=amount;
            _activeId=F4[_activeId].referredById;
            if(F4[_activeId].downcount==12){
                amount = levelPrice[_level]*2;
                toPay=address(uint160(F4[_activeId].myaddress));
                if(!(msg.sender==owner)) toPay.transfer(amount);
                F4[_activeId].income+=amount;
                _activeId=F4[_activeId].referredById;
                if(F4[_activeId].downcount==39){
                    amount = levelPrice[_level]*4;
                    toPay=address(uint160(F4[_activeId].myaddress));
                    if(!(msg.sender==owner)) toPay.transfer(amount);
                    F4[_activeId].income+=amount;
                    _activeId=F4[_activeId].referredById;
                    if(F4[_activeId].downcount==120){
                        amount = (levelPrice[_level]*8)-(levelPrice[_level]);
                        toPay=address(uint160(F4[_activeId].myaddress));
                        if(!(msg.sender==owner)) toPay.transfer(amount);
                        F4[_activeId].income+=amount;
                        F4[_activeId].rebirth=1;
                        buyNewF(F4[_activeId].myaddress, _level, x);
                        //autodisbrust();
                    }
                }
            }
            
        }
        
        if(_level==5){
            amount = levelPrice[_level];
            toPay=address(uint160(F5[_activeId].myaddress));
            if(!(msg.sender==owner)) toPay.transfer(amount);
            F5[_activeId].income+=amount;
            _activeId=F5[_activeId].referredById;
            if(F5[_activeId].downcount==12){
                amount = levelPrice[_level]*2;
                toPay=address(uint160(F5[_activeId].myaddress));
                if(!(msg.sender==owner)) toPay.transfer(amount);
                F5[_activeId].income+=amount;
                _activeId=F5[_activeId].referredById;
                if(F5[_activeId].downcount==39){
                    amount = levelPrice[_level]*4;
                    toPay=address(uint160(F5[_activeId].myaddress));
                    if(!(msg.sender==owner)) toPay.transfer(amount);
                    F5[_activeId].income+=amount;
                    _activeId=F5[_activeId].referredById;
                    if(F5[_activeId].downcount==120){
                        amount = (levelPrice[_level]*8)-(levelPrice[_level]);
                        toPay=address(uint160(F5[_activeId].myaddress));
                        if(!(msg.sender==owner)) toPay.transfer(amount);
                        F5[_activeId].income+=amount;
                        F5[_activeId].rebirth=1;
                        buyNewF(F5[_activeId].myaddress, _level, x);
                        //autodisbrust();
                    }
                }
            }
            
        }
        
        if(_level==6){
            amount = levelPrice[_level];
            toPay=address(uint160(F6[_activeId].myaddress));
            if(!(msg.sender==owner)) toPay.transfer(amount);
            F6[_activeId].income+=amount;
            _activeId=F6[_activeId].referredById;
            if(F6[_activeId].downcount==12){
                amount = levelPrice[_level]*2;
                toPay=address(uint160(F6[_activeId].myaddress));
                if(!(msg.sender==owner)) toPay.transfer(amount);
                F6[_activeId].income+=amount;
                _activeId=F6[_activeId].referredById;
                if(F6[_activeId].downcount==39){
                    amount = levelPrice[_level]*4;
                    toPay=address(uint160(F6[_activeId].myaddress));
                    if(!(msg.sender==owner)) toPay.transfer(amount);
                    F6[_activeId].income+=amount;
                    _activeId=F6[_activeId].referredById;
                    if(F6[_activeId].downcount==120){
                        amount = (levelPrice[_level]*8)-(levelPrice[_level]);
                        toPay=address(uint160(F5[_activeId].myaddress));
                        if(!(msg.sender==owner)) toPay.transfer(amount);
                        F6[_activeId].income+=amount;
                        F6[_activeId].rebirth=1;
                        buyNewF(F6[_activeId].myaddress, _level, x);
                        //autodisbrust();
                    }
                }
            }
            
        }
        
        if(_level==7){
            amount = levelPrice[_level];
            toPay=address(uint160(F7[_activeId].myaddress));
            if(!(msg.sender==owner)) toPay.transfer(amount);
            F7[_activeId].income+=amount;
            _activeId=F7[_activeId].referredById;
            if(F7[_activeId].downcount==12){
                amount = levelPrice[_level]*2;
                toPay=address(uint160(F7[_activeId].myaddress));
                if(!(msg.sender==owner)) toPay.transfer(amount);
                F7[_activeId].income+=amount;
                _activeId=F7[_activeId].referredById;
                if(F7[_activeId].downcount==39){
                    amount = levelPrice[_level]*4;
                    toPay=address(uint160(F7[_activeId].myaddress));
                    if(!(msg.sender==owner)) toPay.transfer(amount);
                    F7[_activeId].income+=amount;
                    _activeId=F7[_activeId].referredById;
                    if(F7[_activeId].downcount==120){
                        amount = (levelPrice[_level]*8)-(levelPrice[_level]);
                        toPay=address(uint160(F7[_activeId].myaddress));
                        if(!(msg.sender==owner)) toPay.transfer(amount);
                        F7[_activeId].income+=amount;
                        F7[_activeId].rebirth=1;
                        buyNewF(F7[_activeId].myaddress, _level, x);
                        //autodisbrust();
                    }
                }
            }
            
        }
        
        if(_level==8){
            amount = levelPrice[_level];
            toPay=address(uint160(F8[_activeId].myaddress));
            if(!(msg.sender==owner)) toPay.transfer(amount);
            F8[_activeId].income+=amount;
            _activeId=F8[_activeId].referredById;
            if(F8[_activeId].downcount==12){
                amount = levelPrice[_level]*2;
                toPay=address(uint160(F8[_activeId].myaddress));
                if(!(msg.sender==owner)) toPay.transfer(amount);
                F8[_activeId].income+=amount;
                _activeId=F8[_activeId].referredById;
                if(F8[_activeId].downcount==39){
                    amount = levelPrice[_level]*4;
                    toPay=address(uint160(F8[_activeId].myaddress));
                    if(!(msg.sender==owner)) toPay.transfer(amount);
                    F8[_activeId].income+=amount;
                    _activeId=F8[_activeId].referredById;
                    if(F8[_activeId].downcount==120){
                        amount = (levelPrice[_level]*8)-(levelPrice[_level]);
                        toPay=address(uint160(F8[_activeId].myaddress));
                        if(!(msg.sender==owner)) toPay.transfer(amount);
                        F8[_activeId].income+=amount;
                        F8[_activeId].rebirth=1;
                        buyNewF(F8[_activeId].myaddress, _level, x);
                        //autodisbrust();
                    }
                }
            }
            
        }
        
        if(_level==9){
            amount = levelPrice[_level];
            toPay=address(uint160(F9[_activeId].myaddress));
            if(!(msg.sender==owner)) toPay.transfer(amount);
            F9[_activeId].income+=amount;
            _activeId=F9[_activeId].referredById;
            if(F9[_activeId].downcount==12){
                amount = levelPrice[_level]*2;
                toPay=address(uint160(F9[_activeId].myaddress));
                if(!(msg.sender==owner)) toPay.transfer(amount);
                F9[_activeId].income+=amount;
                _activeId=F9[_activeId].referredById;
                if(F9[_activeId].downcount==39){
                    amount = levelPrice[_level]*4;
                    toPay=address(uint160(F9[_activeId].myaddress));
                    if(!(msg.sender==owner)) toPay.transfer(amount);
                    F9[_activeId].income+=amount;
                    _activeId=F9[_activeId].referredById;
                    if(F9[_activeId].downcount==120){
                        amount = (levelPrice[_level]*8)-(levelPrice[_level]);
                        toPay=address(uint160(F9[_activeId].myaddress));
                        if(!(msg.sender==owner)) toPay.transfer(amount);
                        F9[_activeId].income+=amount;
                        F9[_activeId].rebirth=1;
                        buyNewF(F9[_activeId].myaddress, _level, x);
                        //autodisbrust();
                    }
                }
            }
            
        }
        
    }
    
    
    function autodisbrust() public returns(string memory){
        require(msg.sender==owner);
        address payable toPay;
        uint cbalance=address(this).balance;
        cbalance=cbalance*50/100;
        silverAmt+=cbalance*25/100;
        controler0.transfer(cbalance*7/100);
        controler1.transfer(cbalance*30/100);
        controler2.transfer(cbalance*30/100);
        uint _dircount = doner.length;
        uint toech=(cbalance*8/100)/_dircount;
        for(uint i=0;i<_dircount;i++){
            toPay=address(uint160(doner[i]));
            toPay.transfer(toech);
        }
        return "DONE!!!";
    }
    function distributeGold() public returns(string memory){
        require(msg.sender==owner,"Invalid Account");
        uint x=goldAmt;
        uint gouldCount=goldIds.length;
        if(gouldCount==0) return "NO GOLD MEMBER FOUND";
        uint toech=x/gouldCount;
        address payable toPay;
        uint i;
        for(i=0;i<goldIds.length;i++){
            toPay=address(uint160(goldIds[i]));
            toPay.transfer(toech);
            users[goldIds[i]].goldIncome+=toech;
        }
        goldAmt=0;
        return "Disburstion Done...";
    }
    
    function distributeSilver() public returns(string memory){
        require(msg.sender==owner,"Invalid Account");
        uint x = silverAmt;
        uint silverCount=silverIds.length;
        uint toech=x/silverCount;
        address payable toPay;
        uint rb=rebirthIds.length;
        for(uint i=rb;i<silverCount;i++){
            toPay=address(uint160(silverIds[i]));
            toPay.transfer(toech); 
        }
        silverAmt=0;
        return "Disburstion Done...";
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    function getVMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].vMatrix[level].currentReferrer,
                users[userAddress].vMatrix[level].referrals,
                users[userAddress].vMatrix[level].isactive);
    }
    function addDoner(address _doner) public returns(bool){
        require(msg.sender==owner,"INVALID CALL");
        doner.push(_doner);
        return true;
    }
    function getFMatrix(address _user, uint _level) public view returns(uint, uint, uint, uint){
        if(_level==1){
            uint FID = vToF1[users[_user].id];
            return (F1[FID].myid, F1[FID].downcount, F1[FID].income, F1[FID].rebirth);
        }
        if(_level==2){
            uint FID = vToF2[users[_user].id];
            return (F2[FID].myid, F2[FID].downcount, F2[FID].income, F2[FID].rebirth);
        }
        if(_level==3){
            uint FID = vToF3[users[_user].id];
            return (F3[FID].myid, F3[FID].downcount, F3[FID].income, F3[FID].rebirth);
        }
        if(_level==4){
            uint FID = vToF4[users[_user].id];
            return (F4[FID].myid, F4[FID].downcount, F4[FID].income, F4[FID].rebirth);
        }
        if(_level==5){
            uint FID = vToF5[users[_user].id];
            return (F5[FID].myid, F5[FID].downcount, F5[FID].income, F5[FID].rebirth);
        }
        if(_level==6){
            uint FID = vToF6[users[_user].id];
            return (F6[FID].myid, F6[FID].downcount, F6[FID].income, F6[FID].rebirth);
        }
        if(_level==7){
            uint FID = vToF7[users[_user].id];
            return (F7[FID].myid, F7[FID].downcount, F7[FID].income, F7[FID].rebirth);
        }
        if(_level==8){
            uint FID = vToF8[users[_user].id];
            return (F8[FID].myid, F8[FID].downcount, F8[FID].income, F8[FID].rebirth);
        }
        if(_level==9){
            uint FID = vToF9[users[_user].id];
            return (F9[FID].myid, F9[FID].downcount, F9[FID].income, F9[FID].rebirth);
        }
    }
}