/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity 0.5.10; 

// Owner Handler
contract ownerShip    // Auction Contract Owner and OwherShip change
{
    //Global storage declaration
    address public ownerWallet;
    address public signer;
    address public newOwner;
    //Event defined for ownership transfered
    event OwnershipTransferredEv(address indexed previousOwner, address indexed newOwner);

    //Sets owner only on first run
    constructor() public 
    {
        //Set contract owner
        ownerWallet = msg.sender;
        signer = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner 
    {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferredEv(ownerWallet, newOwner);
        ownerWallet = newOwner;
        newOwner = address(0);
    }

    //This will restrict function only for owner where attached
    modifier onlyOwner() 
    {
        require(msg.sender == ownerWallet);
        _;
    }

    function changeSigner(address _signer) public onlyOwner returns(bool){
        signer = _signer;
        return true;
    }

    //This will restrict function only for owner where attached
    modifier onlySigner() 
    {
        require(msg.sender == signer);
        _;
    }

}

 interface tokenInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
 }


contract FOX_BUSD is ownerShip {

    uint public defaultRefID = 1;   //this ref ID will be used if user joins without any ref ID
    uint maxDownLimit = 2;
    uint levelLifeTime = 8640000000000;  // = 100 days;
    uint public lastIDCount = 0;
    address public defaultWallet;
    address public token;
    bool public goLive;

    struct userInfo {
        bool joined;
        uint id;
        uint origRef;
        uint smLevel;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }


    mapping (address => userInfo) public userInfos;
    mapping (uint => address) public userAddressByID;

    //user => level => recycleCount
    mapping (address => mapping(uint => uint)) public recCount; 

    // level =>
    mapping(uint => uint) public currentSMIndex;
    // user => level => 
    mapping(address => mapping(uint =>  uint)) public currentPaidCount;

    uint[10] public SMPoolPrice;
    uint[3] public priceOffirstLevel;
    
    uint[12] public priceOfLevel;


    struct autoPool
    {
        uint userID;
        uint SMPoolParent;
    }
    // level => autoPoolRecords
    mapping(uint => autoPool[]) public SMPool;  // users lavel records under auto pool scheme

    // address => level => userIndex
    mapping(address => mapping(uint => uint[])) public SMPoolParentIndex; //to find index of user inside auto pool
    
    // level => sublevel => nextIndexToFill
    mapping(uint => uint) public nextMemberFillIndex;  // which auto pool index is in top of queue to fill in 

    // level => sublevel => nextBoxToFill    
    mapping(uint => uint) public nextMemberFillBox;   // 3 downline to each, so which downline need to fill in






    struct autoPool_
    {
        uint userID;
        uint autoPoolParent;
    }
    mapping(uint => autoPool_[]) public autoPoolLevel;  // users lavel records under auto pool scheme
    mapping(address => mapping(uint => uint[])) private autoPoolIndex; //to find index of user inside auto pool
    uint[11] public nextMemberFillIndex_;  // which auto pool index is in top of queue to fill in 
    uint[11] public nextMemberFillBox_;   // 3 downline to each, so which downline need to fill in


    event RegLevelEV( address UserAddress,address ReferalAddress, uint UserId, uint RefferID, uint Time,uint PlaceId);
    event LevelByEV(uint UserID,uint Level,uint Amount, uint Time);
    event PayForLevelEV(uint Amount, uint FromId, uint ToID, uint Level, uint Ttime, uint Type);
    event PlacingEV(uint UserId, uint PlaceId, uint Amount, uint Position, uint Ttime);

    constructor(address _token) public {
        token = _token;
        priceOfLevel[1] = 12 * ( 10 ** 18) ;
        priceOfLevel[2] = 20 * ( 10 ** 18) ;
        priceOfLevel[3] = 40 * ( 10 ** 18) ;
        priceOfLevel[4] = 80 * ( 10 ** 18) ;
        priceOfLevel[5] = 160 * ( 10 ** 18) ;
        priceOfLevel[6] = 320 * ( 10 ** 18) ;
        priceOfLevel[7] = 640 * ( 10 ** 18) ;
        priceOfLevel[8] = 1280 * ( 10 ** 18) ;
        priceOfLevel[9] = 2560 * ( 10 ** 18) ;
        priceOfLevel[10] = 5120 * ( 10 ** 18) ;
        priceOfLevel[11] = 10240 * ( 10 ** 18) ;

        priceOffirstLevel[1] = 10 * ( 10 ** 18) ;
        priceOffirstLevel[2] = 2 * ( 10 ** 18) ;

        SMPoolPrice[1] = 500  * ( 10 ** 18) ;
        SMPoolPrice[2] = 1000 * ( 10 ** 18) ;
        SMPoolPrice[3] = 2000 * ( 10 ** 18) ;
        SMPoolPrice[4] = 4000 * ( 10 ** 18) ;
        SMPoolPrice[5] = 20000 * ( 10 ** 18) ;
        SMPoolPrice[6] = 40000 * ( 10 ** 18) ;
        SMPoolPrice[7] = 100000 * ( 10 ** 18) ;
        SMPoolPrice[8] = 500000 * ( 10 ** 18) ;
        SMPoolPrice[9] = 1000000 * ( 10 ** 18) ;


        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: 1,
            origRef:1,
            smLevel:0,
            referral: new address[](0)
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[1] = ownerWallet;

        for(uint i = 1; i <= 11; i++) {
            userInfos[ownerWallet].levelExpired[i] = 99999999999;
        }
        
        for(uint i = 0; i <= 8; i++) 
        {
            autoPool memory temp;
            temp.userID = 1;
            SMPool[i].push(temp);
            currentPaidCount[ownerWallet][i]++;
            SMPoolParentIndex[ownerWallet][i].push(0);
        }    
        


        autoPool_ memory tmp;
        for (uint i = 0 ; i < 11; i++)
        {
           tmp.userID = 1;  
           autoPoolLevel[i].push(tmp);
         
           autoPoolIndex[ownerWallet][i].push(0);
        }        
    }

    function () external payable {

    }

    function regUserForOld(address _user, uint _parentID) public onlySigner returns(bool){
        regUserI(_user,_parentID, false);
        return true;
    }   

    function regUser(uint _parentID) public returns(bool){
        require(goLive,"setup not complete");
        regUserI(msg.sender,_parentID, true);
        return true;
    }   

    function goLive_() public onlyOwner returns(bool)
    {
        goLive = true;
        return true;
    }
    
    function regUserI(address msgsender, uint _parentID,bool _new) internal returns(bool){
        uint originalReferrer;
        require(!userInfos[msgsender].joined, 'User exist');
        require(_parentID > 0 && _parentID <= lastIDCount, 'Incorrect referrer Id');
        if(_new)  require(tokenInterface(token).transferFrom(msg.sender,address(this), priceOfLevel[1]), "token transfer fail" );
        if(!(_parentID > 0 && _parentID <= lastIDCount)) _parentID = defaultRefID;
        originalReferrer = _parentID;

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            origRef: originalReferrer,
            smLevel:0,
            referral: new address[](0)
        });

        userInfos[msgsender] = UserInfo;
        userAddressByID[lastIDCount] = msgsender;

        userInfos[msgsender].levelExpired[1] = now + levelLifeTime;

        userInfos[userAddressByID[_parentID]].referral.push(msgsender);

        payNow(priceOffirstLevel[1]/2, userAddressByID[originalReferrer], 1,lastIDCount , 4, false, _new);
        
        if(_new) 
        {
            tokenInterface(token).transfer(address(uint160(defaultWallet)),priceOffirstLevel[2]);
        }

        updateNPayAutoPool(1,msgsender, _new);
        emit RegLevelEV(msgsender,userAddressByID[originalReferrer],lastIDCount, originalReferrer, now, 0);
        return true;
    }

    function buyLevelForOld(address _user, uint _level) public onlySigner returns(bool){
        buyLevelI(_user, _level, false);
        return true;
    }

    function buyLevel(uint _level) public payable returns(bool){
        buyLevelI(msg.sender, _level, true);
        return true;
    }

    function buyLevelI(address msgsender, uint _level, bool _new) internal returns(bool){
        require(userInfos[msgsender].joined, 'User not exist'); 
        require(_level > 1 && _level <= 11, 'Incorrect level');
        require(userInfos[msgsender].levelExpired[_level] == 0 && userInfos[msgsender].levelExpired[_level-1] > 0, "buy previous level"  );
        if(_new)   require(tokenInterface(token).transferFrom(msg.sender,address(this), priceOfLevel[_level]), "token transfer fail" );
        userInfos[msgsender].levelExpired[_level] = now + levelLifeTime;

        address originalReferrer = userAddressByID[userInfos[msgsender].origRef];

        for(uint i=1;i<_level;i++)
        {
            originalReferrer = userAddressByID[userInfos[originalReferrer].origRef];
        }

        payNow(priceOfLevel[_level]/5, originalReferrer, _level, userInfos[msgsender].id, 3, false, _new);


        updateNPayAutoPool(_level,msgsender, _new);

        emit LevelByEV(userInfos[msgsender].id,_level,priceOfLevel[_level], now);
        return true;
    }

    function updateNPayAutoPool(uint _level,address _user, bool _new) internal returns (bool)
    {
        uint a = _level -1;
        uint len = uint(autoPoolLevel[a].length);
        autoPool_ memory temp;
        temp.userID = userInfos[_user].id;
        uint idx = nextMemberFillIndex_[a];
        temp.autoPoolParent = idx;       
        autoPoolLevel[a].push(temp);        

        address usr = userAddressByID[autoPoolLevel[a][idx].userID]; 
        uint place;       
        if(nextMemberFillBox_[a] == 0)
        {
            place = 1;
            nextMemberFillBox_[a] = 1;
            if(usr == address(0)) usr = userAddressByID[1];

            if(_level > 1) payNow(priceOfLevel[_level]*4/5, usr, _level, userInfos[_user].id, 2, false, _new);
            else payNow(priceOfLevel[_level]/2, usr, _level, userInfos[_user].id, 2, false, _new);            
        }   
        else
        {
            place = 2;
            nextMemberFillIndex_[a]++;
            nextMemberFillBox_[a] = 0;
            uint z = recCount[usr][_level]; 
            if(z < 3 || userInfos[usr].levelExpired[_level+1] > 0 || _level == 11) 
            {
                updateNPayAutoPool(_level, usr, _new );   // for recycle 
                recCount[usr][_level]++;     
            }
            else
            {
                if(_level > 1) payNow(priceOfLevel[_level]*4/5, ownerWallet, _level, userInfos[_user].id, 2, false, _new);
                else payNow(priceOfLevel[_level]/2, ownerWallet, _level, userInfos[_user].id, 2, false, _new);                 
            }
        }
        autoPoolIndex[_user][_level - 1].push(len);

        emit PlacingEV(userInfos[_user].id,autoPoolLevel[a][idx].userID , priceOfLevel[_level], place, now);
        return true;
    }

    function buySmartMatrixForOld(address _user, uint _level) public onlySigner returns (bool){
        buySmartMatrixI(_user, _level, false);
        return true;
    }

    function buySmartMatrix(uint _level) public payable returns (bool){
        buySmartMatrixI(msg.sender, _level, true);
        return true;
    }

    function buySmartMatrixI(address msgsender, uint _level, bool _new) internal returns (bool)
    {
        require(userInfos[msgsender].joined, "please register first");
        require(_level >0 && _level < 10, "Invalid Level");
        require(userInfos[msgsender].smLevel == _level - 1, "pls buy previous sm level");
        if(_new)   require(tokenInterface(token).transferFrom(msg.sender, address(this), SMPoolPrice[_level]), "token transfer fail" );

        userInfos[msgsender].smLevel++;

        address payable _user = address(uint160(msgsender));
        uint a = _level -1;

        uint idx = nextMemberFillIndex[a];
        uint ibx =  nextMemberFillBox[a];
        autoPool memory temp;

        temp.userID = userInfos[_user].id;
        temp.SMPoolParent = idx;       
        SMPool[a].push(temp);        
        SMPoolParentIndex[_user][a].push(SMPool[a].length);
        uint pos = ibx;

        if(ibx <= 1)
        {
            ibx++;
        }   
        else
        {
            idx++;
            ibx = 0;
            nextMemberFillIndex[a] = idx;
        }
        nextMemberFillBox[a] = ibx;
        SMPart(temp.userID, pos , _level,temp.SMPoolParent,SMPool[a].length, a, msg.value);

        require(payForSM(_user, a,temp.SMPoolParent, pos, _level, _new ), "payout call fail");

        return true;
    }

    event lavelBy_SM_Ev(uint timeNow,uint userId, uint position , uint level, uint SMPoolParent, uint amount);
 
    function SMPart(uint _id,uint ibx,uint _level,uint Parent,uint len,uint a, uint amount) internal
    {
        len = 0;
        Parent = userInfos[userAddressByID[SMPool[a][Parent].userID]].id;
        emit lavelBy_SM_Ev(now,_id, ibx,_level, Parent, amount);
    }


    event paidSMEv(address _user,uint userID,address paidTo,uint paidToID,uint amount, uint place );
    event directPaidEv(address _user, uint level);        
    function payForSM(address _user,uint a, uint _parent, uint pos, uint _level, bool _new) internal returns(bool)
    {
        uint cp;
        address payable usr = address(uint160(userAddressByID[SMPool[a][_parent].userID]));
        if(pos == 0 )
        {
            cp = currentPaidCount[usr][a];
            currentPaidCount[usr][a]++;
            payNow(SMPoolPrice[_level], usr, _level, userInfos[_user].id, 1, true, _new);
        }
        else
        {
            usr = address(uint160(userAddressByID[SMPool[a][currentSMIndex[a]].userID]));
            cp = currentPaidCount[usr][a];
            if(cp < 17)
            {  
                currentPaidCount[usr][a]++; 
                payNow(SMPoolPrice[_level], usr, _level, userInfos[_user].id, 1, true, _new);
            }
            else if(cp == 17)
            {
                currentPaidCount[usr][a]++;
                usr = address(uint160(userAddressByID[userInfos[usr].origRef]));
                emit directPaidEv(usr, _level);
                payNow(SMPoolPrice[_level], usr, _level, userInfos[_user].id, 5, true, _new);
            }
            else if(cp == 18)
            {
                currentPaidCount[usr][a] = 0; 
                currentSMIndex[a]++;                                
                buySmartMatrix_(usr, _level, _new);
            }
        } 
        emit paidSMEv(_user, userInfos[_user].id, usr, userInfos[usr].id, SMPoolPrice[_level],cp );    
        return true;
    }

    function buySmartMatrix_(address msgsender, uint _level, bool _new) internal returns (bool)
    {
        uint a = _level -1;

        uint idx = nextMemberFillIndex[a];
        uint ibx =  nextMemberFillBox[a];
        autoPool memory temp;

        temp.userID = userInfos[msgsender].id;
        temp.SMPoolParent = idx;       
        SMPool[a].push(temp);        
        SMPoolParentIndex[msgsender][a].push(SMPool[a].length);
        uint pos = ibx;

        if(ibx <= 1)
        {
            ibx++;
        }   
        else
        {
            idx++;
            ibx = 0;
        }
        nextMemberFillIndex[a] = idx;
        nextMemberFillBox[a] = ibx;
        SMPart(temp.userID, pos , _level,temp.SMPoolParent,SMPool[a].length, a,SMPoolPrice[_level] );

        require(payForSM(msgsender, a,temp.SMPoolParent, pos, _level , _new), "payout call fail");

        return true;
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return userInfos[_user].referral;
    }

    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return userInfos[_user].levelExpired[_level];
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

        
    function changeDefaultRefID(uint newDefaultRefID) onlyOwner public returns(string memory){

        defaultRefID = newDefaultRefID;
        return("Default Ref ID updated successfully");
    }

    function defaultWalet(address _defaultWallet) public onlyOwner returns(bool)
    {
        defaultWallet = _defaultWallet;
        return true;
    }

    function payNow(uint amount, address user,uint _level, uint fromID,uint Type, bool sm, bool _new) internal returns(bool){
        if(!_new) return true;
        if(!sm) 
        {
            if(userInfos[user].levelExpired[_level] == 0) user = defaultWallet;
        }
        else
        {
            if(userInfos[user].smLevel < _level) user = defaultWallet;
        }
        tokenInterface(token).transfer(address(uint160(user)),amount);
        emit PayForLevelEV(amount,fromID, userInfos[user].id, _level, now, Type);
        return true;
    }

    function setTokenAddress(address _token) public onlyOwner returns(bool)
    {
        token = _token;
        return true;
    }

}