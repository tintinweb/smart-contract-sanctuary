//SourceUnit: Finxer_Contract.sol

pragma solidity 0.5.9;
    
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

interface fsg
{
    function registrationExt(address referrerAddress, uint _id) external payable returns(bool);
    function callX_(address _user) external returns(bool);
}



contract FINEXER is owned
{
    uint32 public levelLifeTime = 15552000;  // =180 days;
    uint32 public lastIDCount;
    address payable public fsgAddress;

    uint public maxDownLimit = 999999999999;
    uint public defaultRefID = 1;

    struct userInfo {
        bool joined;
        uint id;
        uint referrerID;
        uint originalReferrer;
        uint directCount;
        uint regDate;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }

    mapping (address => userInfo) public userInfos;
    mapping (uint => address payable) public userAddressByID;

    mapping(uint => uint) public priceOfLevel;
    mapping(uint => uint) public directPayoutDist;
    mapping(uint => uint[6]) public autoPoolDist;
    mapping(uint => uint) public levelDist;

    struct autoPool
    {
        uint userID;
        uint poolParent;
    }

    mapping(uint => autoPool[]) public autoPoolLevel;  // users lavel records under auto pool scheme
    mapping(address => mapping(uint => uint)) public autoPoolIndex; //to find index of user inside auto pool

    uint[10] public nextMemberFillIndex;  // which auto pool index is in top of queue to fill in 
    uint[10] public nextMemberFillBox;   // x downline to each, so which downline need to fill in

    uint public regLevelEventCount;
    uint public levelBuyEventCount;
    uint public payoutEventCount;
    uint public autoPoolEventCount;
    uint public directPayEventCount;

    event regLevelEv(uint eventIndex, address indexed _userWallet, uint indexed _userID, uint indexed _referrerID, uint _time, address _refererWallet, uint _originalReferrer, uint timeStamp);
    event levelBuyEv(uint eventIndex, address indexed _user, uint _level, uint _amount, uint _time, uint userId);
    event updateAutoPoolEv(uint eventIndex, uint timeNow,uint autoPoolLevelIndex,uint userIndexInAutoPool, address user, uint userId,uint parent, uint parentMainId, uint position);

    // Payout events type definition
    // 0 = direct pay 50%
    // 1 = auto pool level 
    // 2 = level income paid
    //uint public autoPoolIndex;


    event payoutEv(uint eventIndex, uint _type, address paidAgainst, address paidTo, uint againstID, uint toID, uint amount,uint level, uint timeNow );

    constructor(address payable ownerAddress, address payable ID1address) public {

        owner = ownerAddress;
        signer = ownerAddress;
        emit OwnershipTransferred(address(0), owner);
        address payable ownerWallet = ID1address;

        priceOfLevel[1] = 200000000; // trx
        priceOfLevel[2] = 1500000000; // trx
        priceOfLevel[3] = 20000000000; // trx

        uint i;

        levelDist[1] = 10000000; // = 10%
        levelDist[2] = 5000000; // = 5%
        levelDist[3] = 3000000; // = 3%
        levelDist[4] = 2000000; // = 2%
        for(i=5; i < 15;i++)
        {
            levelDist[i] = 1000000; // = 1%
        }


        directPayoutDist[1] = 50000000; // = 50%
        for(i=2; i<=15;i++)
        {
            directPayoutDist[i] = 20000000; // 20%
        }

        autoPoolDist[1][1] = 5000000; // = trx
        autoPoolDist[1][2] = 6000000; // = trx
        autoPoolDist[1][3] = 7000000; // = trx
        autoPoolDist[1][4] = 8000000; // = trx
        autoPoolDist[1][5] = 14000000; // = trx

        autoPoolDist[2][1] = 100000000; // = trx
        autoPoolDist[2][2] = 150000000; // = trx
        autoPoolDist[2][3] = 200000000; // = trx
        autoPoolDist[2][4] = 250000000; // = trx
        autoPoolDist[2][5] = 500000000; // = trx

        autoPoolDist[3][1] = 1000000000; // = trx
        autoPoolDist[3][2] = 1500000000; // = trx
        autoPoolDist[3][3] = 2000000000; // = trx
        autoPoolDist[3][4] = 2500000000; // = trx
        autoPoolDist[3][5] = 9000000000; // = trx

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: 1,
            originalReferrer: 1,
            directCount: 0,
            regDate: 0,
            referral: new address[](0)
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;

        regLevelEventCount++;
        emit regLevelEv(regLevelEventCount, ownerWallet, 1, 1,now,ownerWallet, 1, now);
        uint lvlBuyEvCont = levelBuyEventCount;
        for(i = 1; i <= 15; i++) {
            userInfos[ownerWallet].levelExpired[i] = 99999999999;
            lvlBuyEvCont++;
            emit levelBuyEv(lvlBuyEvCont,ownerWallet, i, 0, now, 1);
        }
        levelBuyEventCount = lvlBuyEvCont;

        autoPool memory temp;
        for (i = 0 ; i < 4; i++)
        {
           temp.userID = lastIDCount;  
           autoPoolLevel[i].push(temp);
         
           autoPoolIndex[ownerWallet][i] = 0;
        } 

    }

    function () payable external {
        revert();
    }

    function setFsgAddress(address payable _fsgAddress) public onlyOwner returns(bool)
    {
        fsgAddress = _fsgAddress;
        return true;
    }

    function regUser(uint _referrerID) public payable returns(bool)
    {
        require(msg.value == priceOfLevel[1],"Invalid Amount");
        require(regUserI(_referrerID, msg.sender), "registration failed");
        return true;
    }

    function regUserI(uint _referrerID, address payable msgSender) internal returns(bool) 
    {
        //this saves gas while using this multiple times
        uint originalReferrer = _referrerID;

        //checking all conditions
        require(!userInfos[msgSender].joined, 'User exist');
        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;
        if(userInfos[userAddressByID[_referrerID]].referral.length >= maxDownLimit) _referrerID = userInfos[findFreeReferrer(userAddressByID[_referrerID])].id;

        //update variables
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: _referrerID,
            originalReferrer : originalReferrer,
            directCount : 0,
            regDate: now,
            referral: new address[](0)
        });

        userInfos[msgSender] = UserInfo;
        userAddressByID[lastIDCount] = msgSender;

        userInfos[msgSender].levelExpired[1] = now + levelLifeTime;

        userInfos[userAddressByID[_referrerID]].referral.push(msgSender);
        userInfos[userAddressByID[originalReferrer]].directCount++;

        require(payForLevel(1, msgSender),"pay for level fail");
        regLevelEventCount++;
        emit regLevelEv(regLevelEventCount, msgSender, lastIDCount, _referrerID, now,userAddressByID[_referrerID], originalReferrer, now );
        levelBuyEventCount++;
        emit levelBuyEv(levelBuyEventCount,msgSender, 1, priceOfLevel[1] , now, userInfos[msgSender].id);

        updateNPayAutoPool(1,msgSender);
        return true;
    }


    function buyLevel(uint _level ) public payable returns(bool)
    {
        require(buyLevelI(_level, msg.sender), "registration failed");
        require(msg.value == priceOfLevel[_level],"Invalid Amount");
        return true;
    }


    function buyLevelI(uint _level, address payable _user) internal returns(bool){
        
        //this saves gas while using this multiple times
        address payable msgSender = _user;   
        
        
        //checking conditions
        require(userInfos[msgSender].joined, 'User not exist'); 
        require(_level >= 1 && _level <= 15, 'Incorrect level');   
        
        //updating variables
        if(_level == 1) {
            userInfos[msgSender].levelExpired[1] += levelLifeTime;
        }
        else {
            for(uint l =_level - 1; l > 0; l--) require(userInfos[msgSender].levelExpired[l] >= now, 'Buy the previous level');

            if(userInfos[msgSender].levelExpired[_level] == 0) userInfos[msgSender].levelExpired[_level] = now + levelLifeTime;
            else userInfos[msgSender].levelExpired[_level] += levelLifeTime;
        }
        require(payForLevel(_level, msgSender),"pay for level fail");
        levelBuyEventCount++;
        emit levelBuyEv(levelBuyEventCount,msgSender, _level, priceOfLevel[_level] , now, userInfos[msgSender].id);
        updateNPayAutoPool(_level,msgSender);
        return true;
    }


    function findFreeReferrer(address _user) public view returns(address) {
        if(userInfos[_user].referral.length < maxDownLimit) return _user;

        address[] memory referrals = new address[](126);
        referrals[0] = userInfos[_user].referral[0];
        referrals[1] = userInfos[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(userInfos[referrals[i]].referral.length == maxDownLimit) {
                if(i < 62) {
                    referrals[(i+1)*2] = userInfos[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = userInfos[referrals[i]].referral[1];
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

    function payForLevel(uint _level, address payable _user) internal returns (bool)
    {
        address payable dp = userAddressByID[userInfos[_user].originalReferrer];
        uint amt = priceOfLevel[_level];       
        dp.transfer(amt *  directPayoutDist[_level] / 100000000);
        directPayEventCount++;
        emit payoutEv(directPayEventCount, 0, _user,dp , userInfos[_user].id, userInfos[dp].id, amt,_level, now );
        if(_level > 1 ) return true;
        uint i;
        uint pE = payoutEventCount;
        address payable parent =  userAddressByID[userInfos[_user].referrerID];
        for(i=1;i<15;i++)
        {
            parent =  userAddressByID[userInfos[parent].referrerID];
            parent.transfer(amt * levelDist[i] / 100000000);
            pE++;
            split(pE,2,_user,parent , userInfos[_user].id, userInfos[parent].id, amt * levelDist[i] / 100000000 ,_level);
        }
        payoutEventCount = pE;
        return true;
    }

    function split(uint pE,uint _a, address _user,address parent ,uint _id,uint id_,uint amt, uint _level) internal returns(bool)
    {
        emit payoutEv(pE, _a, _user,parent , _id, id_, amt,_level, now);
        return true;
    }

    function updateNPayAutoPool(uint _level,address _user) internal returns (bool)
    {
        autoPool memory temp;
        temp.userID = userInfos[_user].id;
        temp.poolParent = nextMemberFillIndex[_level-1];       
        autoPoolLevel[_level-1].push(temp);        
        uint idx = nextMemberFillIndex[_level-1];

        address payable usr = userAddressByID[autoPoolLevel[_level-1][idx].userID];
        if(usr == address(0)) usr = userAddressByID[defaultRefID];
        for(uint i=0;i<5;i++)
        {
            uint amount = autoPoolDist[_level][i+1];
            if(_level < 5 || userInfos[usr].directCount >= 4)
            {
                usr.transfer(amount);
                autoPoolEventCount++;
                split(autoPoolEventCount,1,_user,usr , userInfos[_user].id, userInfos[usr].id, amount,_level);
            }
            else
            {
                owner.transfer(amount);
            }
            idx = autoPoolLevel[_level-1][idx].poolParent; 
            usr = userAddressByID[autoPoolLevel[_level-1][idx].userID];
            if(usr == address(0)) usr = userAddressByID[defaultRefID];
        }
        idx = nextMemberFillIndex[_level-1];
        if(nextMemberFillBox[_level-1] < 3)
        {
            nextMemberFillBox[_level-1]++;
        }   
        else
        {
            nextMemberFillIndex[_level-1]++;
            nextMemberFillBox[_level-1] = 0;
        }
        autoPoolIndex[_user][_level - 1] = uint32(autoPoolLevel[_level-1].length);
        autoPoolEventCount++;
        split2(autoPoolEventCount,_level, autoPoolLevel[_level-1].length, _user, userInfos[_user].id, idx, autoPoolLevel[_level-1][idx].userID,nextMemberFillBox[_level-1] );
        return true;
    }

    function split2(uint _autoPoolEventCount,uint _level,uint len,address _user,uint _id,uint pid, uint pidMain,uint _fb) internal returns(bool)
    {
        if (_fb == 0 ) _fb = 4;
        emit updateAutoPoolEv(_autoPoolEventCount,now, _level, len, _user, _id,pid,pidMain, _fb);
        return true;
    }


    function viewUserReferral(address _user) public view returns(address[] memory) {
        return userInfos[_user].referral;
    }

    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return userInfos[_user].levelExpired[_level];
    }

    function joinForsage() public payable returns (bool)
    {
        require(msg.value == 150000000, "invalid amount paid" );
        require(userInfos[msg.sender].joined, "User not registered");
        fsg(fsgAddress).registrationExt.value(msg.value)(userAddressByID[userInfos[msg.sender].originalReferrer],userInfos[msg.sender].id);
        return true;
    }
/*
    function joinForsagePart() public returns (bool)
    {
        require(userInfos[msg.sender].joined, "User not registered");
        fsg(fsgAddress).callX_(msg.sender);
        return true;
    }
*/

}