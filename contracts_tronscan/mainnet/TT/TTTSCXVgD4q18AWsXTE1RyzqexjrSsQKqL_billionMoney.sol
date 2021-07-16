//SourceUnit: Billion-Money_Tron.sol

pragma solidity 0.5.9; /*
___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_



 ██████╗ ██╗██╗     ██╗     ██╗ ██████╗ ███╗   ██╗    ███╗   ███╗ ██████╗ ███╗   ██╗███████╗██╗   ██╗
 ██╔══██╗██║██║     ██║     ██║██╔═══██╗████╗  ██║    ████╗ ████║██╔═══██╗████╗  ██║██╔════╝╚██╗ ██╔╝
 ██████╔╝██║██║     ██║     ██║██║   ██║██╔██╗ ██║    ██╔████╔██║██║   ██║██╔██╗ ██║█████╗   ╚████╔╝ 
 ██╔══██╗██║██║     ██║     ██║██║   ██║██║╚██╗██║    ██║╚██╔╝██║██║   ██║██║╚██╗██║██╔══╝    ╚██╔╝  
 ██████╔╝██║███████╗███████╗██║╚██████╔╝██║ ╚████║    ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║███████╗   ██║   
 ╚═════╝ ╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝    ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   
                                                                                            


-------------------------------------------------------------------
 Copyright (c) 2020 onwards Billion Money Inc. ( https://billionmoney.live )
-------------------------------------------------------------------
 */



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
//------------------         Token interface        -------------------//
//*******************************************************************//

 interface tokenInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
 }




//*******************************************************************//
//------------------        MAIN contract         -------------------//
//*******************************************************************//

contract billionMoney is owned {

    // Replace below address with main Token token
    address public tokenAddress;
    uint public maxDownLimit = 2;
    uint public levelLifeTime = 10368000;  // =120 days;
    uint public lastIDCount = 0;
    
    bool public dataUpdated;

    uint public defaultRefID = 1;   //this ref ID will be used if user joins without any ref ID


    struct userInfo {
        bool joined;
        uint id;
        uint referrerID;
        uint originalReferrer;
        uint directCount;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }

    mapping(uint => uint) public priceOfLevel;
    mapping(uint => uint) public distForLevel;
    mapping(uint => uint) public autoPoolDist;
    mapping(uint => uint) public uniLevelDistPart;
    uint256 public totalDivCollection;
    uint[11] public globalDivDistPart;
    uint public systemDistPart;
    
    uint public oneMonthDuration = 2592000; // = 30 days
    uint public thisMonthEnd;
    struct divPoolRecord
    {
        uint totalDividendCollection;
        uint totalEligibleCount;
    }
    divPoolRecord[] public globalDivRecords_;
    mapping ( address => uint) public eligibleUser; // if val > 0 then user is eligible from this globalDivRecords_;
    mapping ( address => bool) public divOnHold; 
    struct autoPool
    {
        uint userID;
        uint autoPoolIndex_;
    }
    mapping(uint => autoPool[]) public autoPoolLevel;  // users lavel records under auto pool scheme
    mapping(address => mapping(uint => uint)) public autoPoolIndex; //to find index of user inside auto pool
    uint[10] public nextMemberFillIndex;  // which auto pool index is in top of queue to fill in 
    uint[10] public nextMemberFillBox;   // 3 downline to each, so which downline need to fill in

    uint[10][10] public autoPoolSubDist;

    

    mapping (address => userInfo) public userInfos;
    mapping (uint => address payable) public userAddressByID;
    mapping(address => address payable) public newUserAddress;

    mapping(address => uint256) public totalGainInMainNetwork; //Main lavel income system income will go here with owner mapping
    mapping(address => uint256) public totalGainInUniLevel; 
    mapping(address => uint256) public totalGainInAutoPool;
    mapping(address => uint256) public netTotalUserWithdrawable;  //Dividend is not included in it
    mapping(address => uint256) public totalDirect;  //Dividend is not included in it


    event regLevelEv(address indexed _userWallet, uint indexed _userID, uint indexed _referrerID, uint _time, address _refererWallet, uint _originalReferrer);
    event levelBuyEv(address indexed _user, uint _level, uint _amount, uint _time);
    event paidForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);
    event lostForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);
    event payDividendEv(uint timeNow,uint payAmount,address paitTo);
    event updateAutoPoolEv(uint timeNow,uint autoPoolLevelIndex,uint userIndexInAutoPool, address user);
    event autoPoolPayEv(uint timeNow,address paidTo,uint paidForLevel, uint paidAmount, address paidAgainst);
    event paidForUniLevelEv(uint timeNow,address PaitTo,uint Amount);
    
    constructor(address payable ownerAddress, address payable ID1address) public {
        owner = ownerAddress;
        signer = ownerAddress;
        emit OwnershipTransferred(address(0), owner);
        address payable ownerWallet = ID1address;

        globalDivDistPart[1] = 1000000;
        globalDivDistPart[2] = 1000000;
        globalDivDistPart[3] = 2000000;
        globalDivDistPart[4] = 6000000;
        globalDivDistPart[5] = 27500000;
        globalDivDistPart[6] = 120000000;
        globalDivDistPart[7] = 135000000;
        globalDivDistPart[8] = 225000000;
        globalDivDistPart[9] = 360000000;
        globalDivDistPart[10] = 690000000;


        systemDistPart = 1000000;

        priceOfLevel[1] = 25000000;
        priceOfLevel[2] = 25000000;
        priceOfLevel[3] = 50000000;
        priceOfLevel[4] = 140000000;
        priceOfLevel[5] = 600000000;
        priceOfLevel[6] = 2500000000;
        priceOfLevel[7] = 3000000000;
        priceOfLevel[8] = 5000000000;
        priceOfLevel[9] = 8000000000;
        priceOfLevel[10] = 15000000000;

        distForLevel[1] = 10000000;
        distForLevel[2] = 15000000;
        distForLevel[3] = 30000000;
        distForLevel[4] = 90000000;
        distForLevel[5] = 412500000;
        distForLevel[6] = 1800000000;
        distForLevel[7] = 2025000000;
        distForLevel[8] = 3375000000;
        distForLevel[9] = 5400000000;
        distForLevel[10] = 10350000000;

        autoPoolDist[1] = 4000000;
        autoPoolDist[2] = 5000000;
        autoPoolDist[3] = 10000000;
        autoPoolDist[4] = 20000000;
        autoPoolDist[5] = 50000000;
        autoPoolDist[6] = 100000000;
        autoPoolDist[7] = 300000000;
        autoPoolDist[8] = 500000000;
        autoPoolDist[9] = 800000000;
        autoPoolDist[10]= 1200000000;        

        uniLevelDistPart[1] = 1000000;
        uniLevelDistPart[2] = 800000;
        uniLevelDistPart[3] = 600000;
        uniLevelDistPart[4] = 400000;

        for (uint i = 5 ; i < 11; i++)
        {
           uniLevelDistPart[i] =  200000;
        } 

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: 0,
            originalReferrer: 1,
            directCount: 0,
            referral: new address[](0)
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;

        for(uint i = 1; i <= 10; i++) {
            userInfos[ownerWallet].levelExpired[i] = 99999999999;
            emit paidForLevelEv(address(0), ownerWallet, i, distForLevel[i], now);
        }

        autoPool memory temp;
        for (uint i = 11 ; i < 21; i++)
        {
           uniLevelDistPart[i] =  100000;
           uint a = i-11;
           temp.userID = lastIDCount;  
           autoPoolLevel[a].push(temp);
         
           autoPoolIndex[ownerWallet][a] = 0;
           uint distPart = autoPoolDist[a+1];
           autoPoolSubDist[a][0] = distPart * 1250 / 10000;
           autoPoolSubDist[a][1] = distPart * 1250 / 10000;
           autoPoolSubDist[a][2] = distPart * 1000 / 10000;
           autoPoolSubDist[a][3] = distPart * 750 / 10000;
           autoPoolSubDist[a][4] = distPart * 750 / 10000;
           autoPoolSubDist[a][5] = distPart * 750 / 10000;
           autoPoolSubDist[a][6] = distPart * 750 / 10000;
           autoPoolSubDist[a][7] = distPart * 1000 / 10000;
           autoPoolSubDist[a][8] = distPart * 1250 / 10000;                                                                             
           autoPoolSubDist[a][9] = distPart * 1250 / 10000;
        } 

        startNextMonth();
        eligibleUser[ownerWallet] = 1;
        emit regLevelEv(ownerWallet, 1, 0, now, address(this), 0);

    }

    function () payable external {
        regUser(defaultRefID);
    }

    function dataUpdateDone() public onlyOwner returns(bool)
    {
        require(!dataUpdated, "can not do once set to true ");
        dataUpdated = true;
        return true;
    }

    function resetGainOld(uint fromId, uint toId) public onlyOwner returns(bool)
    {
        require(!dataUpdated, "can not do once set to true ");
        require (fromId <= toId && toId <= lastIDCount, "Invalid Id");
        uint i;
        uint j;
        uint divLen = globalDivRecords_.length;
        for(j=0;j<divLen;j++)
        {
            globalDivRecords_[j].totalDividendCollection = 0;
        }
        for(i=fromId;i<= toId; i++)
        {
            address usr = userAddressByID[i];
            netTotalUserWithdrawable[usr] = 0;
            totalGainInAutoPool[usr] = 0;
            totalGainInMainNetwork[usr] = 0;
            totalGainInUniLevel[usr] = 0;
            totalDirect[usr] = 0;
        }
        return true;
    }

    function regUserOld(uint _originalReferrer, address payable _user,uint _referrerID ) public returns(bool)
    {
        require(!dataUpdated, "update is already finished");
        require(regUserI(_originalReferrer, _user, _referrerID), "registration failed");
        return true;
    }

    function regUser(uint _referrerID) public returns(bool)
    {
        require(dataUpdated, "update is already finished");
        require(regUserI(_referrerID, msg.sender, 0), "registration failed");
        return true;
    }

    function regUserI(uint _referrerID, address payable msgSender, uint _refOrig) internal returns(bool) 
    {
        //this saves gas while using this multiple times
        uint originalReferrer = _referrerID;

        //checking all conditions
        require(!userInfos[msgSender].joined, 'User exist');
        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;
        if(userInfos[userAddressByID[_referrerID]].referral.length >= maxDownLimit) _referrerID = userInfos[findFreeReferrer(userAddressByID[_referrerID])].id;
        if(_refOrig != 0) _referrerID = _refOrig;


        if(dataUpdated) require( tokenInterface(tokenAddress).transferFrom(msgSender, address(this), priceOfLevel[1]),"token transfer failed");

        //update variables
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: _referrerID,
            originalReferrer : originalReferrer,
            directCount : 0,
            referral: new address[](0)
        });

        userInfos[msgSender] = UserInfo;
        userAddressByID[lastIDCount] = msgSender;

        userInfos[msgSender].levelExpired[1] = now + levelLifeTime;

        userInfos[userAddressByID[_referrerID]].referral.push(msgSender);
        userInfos[userAddressByID[originalReferrer]].directCount++;

        if(thisMonthEnd < now) startNextMonth();

        uint lastDivPoolIndex = globalDivRecords_.length;
        globalDivRecords_[lastDivPoolIndex - 1].totalDividendCollection += globalDivDistPart[1];
        totalDivCollection += globalDivDistPart[1];
        totalDirect[userAddressByID[originalReferrer]] += globalDivDistPart[1] * 4;
        netTotalUserWithdrawable[userAddressByID[originalReferrer]] += globalDivDistPart[1] * 4;

        totalGainInMainNetwork[userAddressByID[1]] += systemDistPart;
        netTotalUserWithdrawable[userAddressByID[1]] += systemDistPart;

        address usr = userAddressByID[originalReferrer];
        if(eligibleUser[usr] == 0)
        {
            if(userInfos[usr].directCount > 9)
            {
                eligibleUser[usr] = lastDivPoolIndex;
                globalDivRecords_[lastDivPoolIndex - 1 ].totalEligibleCount++;
            }
        }

        require(payForLevel(1, msgSender),"pay for level fail");
        emit regLevelEv(msgSender, lastIDCount, _referrerID, now,userAddressByID[_referrerID], originalReferrer );
        emit levelBuyEv(msgSender, 1, priceOfLevel[1] , now);
        require(updateNPayAutoPool(1,msgSender),"auto pool update fail");
        return true;
    }

    function viewCurrentMonthDividend() public view returns(uint256 amount, uint256 indexCount)
    {
        uint256 length = globalDivRecords_.length;
        return (globalDivRecords_[length-1].totalDividendCollection,length);
    }



    function buyLevelOld(uint _level, address payable _user) public returns(bool)
    {
        require(!dataUpdated, "update is already finished");
        require(buyLevelI(_level, _user), "registration failed");
        return true;
    }

    function buyLevel(uint _level ) public returns(bool)
    {
        require(dataUpdated, "update is already finished");
        require(buyLevelI(_level, msg.sender), "registration failed");
        return true;
    }


    function buyLevelI(uint _level, address _user) internal returns(bool){
        
        //this saves gas while using this multiple times
        address msgSender = _user;   
        
        
        //checking conditions
        require(userInfos[msgSender].joined, 'User not exist'); 
        require(_level >= 1 && _level <= 10, 'Incorrect level');
        
        //transfer tokens
        if(dataUpdated) require( tokenInterface(tokenAddress).transferFrom(msgSender, address(this), priceOfLevel[_level]),"token transfer failed");
        
        
        //updating variables
        if(_level == 1) {
            userInfos[msgSender].levelExpired[1] += levelLifeTime;
        }
        else {
            for(uint l =_level - 1; l > 0; l--) require(userInfos[msgSender].levelExpired[l] >= now, 'Buy the previous level');

            if(userInfos[msgSender].levelExpired[_level] == 0) userInfos[msgSender].levelExpired[_level] = now + levelLifeTime;
            else userInfos[msgSender].levelExpired[_level] += levelLifeTime;
        }

        globalDivRecords_[globalDivRecords_.length - 1].totalDividendCollection += globalDivDistPart[_level] ;
        totalDivCollection += globalDivDistPart[_level];
        address reff = userAddressByID[userInfos[msgSender].originalReferrer];
        totalDirect[reff] += globalDivDistPart[_level] * 4;
        netTotalUserWithdrawable[reff] += globalDivDistPart[_level] * 4;            
        if(_level == 1)
        {
            totalGainInMainNetwork[userAddressByID[1]] += systemDistPart;
            netTotalUserWithdrawable[userAddressByID[1]] += systemDistPart;           
        }
        require(payForLevel(_level, msgSender),"pay for level fail");
        emit levelBuyEv(msgSender, _level, priceOfLevel[_level] , now);
        require(updateNPayAutoPool(_level,msgSender),"auto pool update fail");
        return true;
    }
    

    function payForLevel(uint _level, address _user) internal returns (bool){
        address referer;
        address referer1;
        address referer2;
        address referer3;
        address referer4;
        
        

        if(_level == 1 || _level == 6) {
            referer = userAddressByID[userInfos[_user].referrerID];
            payForUniLevel(userInfos[_user].referrerID);
        }
        else if(_level == 2 || _level == 7) {
            referer1 = userAddressByID[userInfos[_user].referrerID];
            referer = userAddressByID[userInfos[referer1].referrerID];
        }
        else if(_level == 3 || _level == 8) {
            referer1 = userAddressByID[userInfos[_user].referrerID];
            referer2 = userAddressByID[userInfos[referer1].referrerID];
            referer = userAddressByID[userInfos[referer2].referrerID];
        }
        else if(_level == 4 || _level == 9) {
            referer1 = userAddressByID[userInfos[_user].referrerID];
            referer2 = userAddressByID[userInfos[referer1].referrerID];
            referer3 = userAddressByID[userInfos[referer2].referrerID];
            referer = userAddressByID[userInfos[referer3].referrerID];
        }
        else if(_level == 5 || _level == 10) {
            referer1 = userAddressByID[userInfos[_user].referrerID];
            referer2 = userAddressByID[userInfos[referer1].referrerID];
            referer3 = userAddressByID[userInfos[referer2].referrerID];
            referer4 = userAddressByID[userInfos[referer3].referrerID];
            referer = userAddressByID[userInfos[referer4].referrerID];
        }


        if(!userInfos[referer].joined) referer = userAddressByID[defaultRefID];

       
        if(userInfos[referer].levelExpired[_level] >= now) {
            totalGainInMainNetwork[referer] += distForLevel[_level];
            netTotalUserWithdrawable[referer] += distForLevel[_level];
            emit paidForLevelEv(referer, _user, _level, distForLevel[_level], now);

        }
        else{

            emit lostForLevelEv(referer, _user, _level, distForLevel[_level] , now);
            payForLevel(_level, referer);

        }
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

    function payForUniLevel(uint _referrerID) internal returns(bool)
    {
        uint256 endID = 21;
        for (uint i = 0 ; i < endID; i++)
        {
            address usr = userAddressByID[_referrerID];
            _referrerID = userInfos[usr].referrerID;
            if(usr == address(0)) usr = userAddressByID[defaultRefID];
            uint Amount = uniLevelDistPart[i + 1 ];
            totalGainInUniLevel[usr] += Amount;
            netTotalUserWithdrawable[usr] += Amount;
            emit paidForUniLevelEv(now,usr, Amount);
        }
        return true;
    }

    event withdrawMyGainEv(uint timeNow,address caller,uint totalAmount);
    function withdrawMyDividendNAll() public returns(uint)
    {
        address payable caller = msg.sender;
        require(userInfos[caller].joined, 'User not exist');
        uint from = eligibleUser[caller];
        uint totalAmount;
        if(from > 0 && !divOnHold[caller])
        {
            from --;
            uint lastDivPoolIndex = globalDivRecords_.length;
            if( lastDivPoolIndex > 1 )
            {

                for(uint i=from;i< lastDivPoolIndex - 1; i++)
                {
                    totalAmount +=  ( globalDivRecords_[i].totalDividendCollection * 10000000000 /  globalDivRecords_[i].totalEligibleCount ) / 10000000000;
                    eligibleUser[caller] = i+2;
                }
            }
        }

        if(totalAmount > 0)
        {
            totalDivCollection -= totalAmount;
            emit payDividendEv(now, totalAmount, caller);
        }
        totalAmount = totalAmount + netTotalUserWithdrawable[caller];
        netTotalUserWithdrawable[caller] = 0;
        totalGainInAutoPool[caller] = 0;
        totalGainInMainNetwork[caller] = 0;
        totalGainInUniLevel[caller] = 0;
        if(dataUpdated) require(tokenInterface(tokenAddress).transfer(msg.sender, totalAmount),"token transfer failed");
        emit withdrawMyGainEv(now, caller, totalAmount);
        
    }


    function viewMyDividendPotential(address user) public view returns(uint256 totalDivPotential, uint256 lastUnPaidIndex)
    {
        uint from = eligibleUser[user];
        uint totalAmount;
        if(from > 0)
        {
            from --;
            uint lastDivPoolIndex = globalDivRecords_.length;
            if( lastDivPoolIndex > 1 )
            {

                for(uint i=from;i< lastDivPoolIndex;i++)
                {
                    totalAmount +=  ( globalDivRecords_[i].totalDividendCollection * 10000000000 /  globalDivRecords_[i].totalEligibleCount ) / 10000000000;
                }
            }
        }
        return(totalAmount, eligibleUser[user]);
    }


    function viewMyDividendConfirm(address user) public view returns(uint256 totalDivPotential, uint256 lastUnPaidIndex)
    {
        uint from = eligibleUser[user];
        uint totalAmount;
        if(from > 0)
        {
            from --;
            uint lastDivPoolIndex = globalDivRecords_.length;
            if( lastDivPoolIndex > 1 )
            {

                for(uint i=from;i< lastDivPoolIndex -1 ;i++)
                {
                    totalAmount +=  ( globalDivRecords_[i].totalDividendCollection * 10000000000 /  globalDivRecords_[i].totalEligibleCount ) / 10000000000;
                }
            }
        }
        return(totalAmount, eligibleUser[user]);
    }

    function viewMyDividendPotentialByIndex(address user,uint _divIndex ) public view returns(uint256)
    {
        uint from = eligibleUser[user];
        if( from <= _divIndex+1 && from != 0 &&  _divIndex  < globalDivRecords_.length)
        {
            return (globalDivRecords_[_divIndex].totalDividendCollection * 10000000000 /  globalDivRecords_[_divIndex].totalEligibleCount ) / 10000000000;
        }
        return 0;
    }

    function viewTimestampSinceJoined(address usr) public view returns(uint256[10] memory timeSinceJoined )
    {
        if(userInfos[usr].joined)
        {
            for(uint256 i=0;i<10;i++)
            {
                uint256 t = userInfos[usr].levelExpired[i+1];
                if(t>now)
                {
                    timeSinceJoined[i] = (t-now);
                }
            }
        }
        return timeSinceJoined;
    }

    
    
    function divPoolAllLevel() public view returns (uint256[10] memory divPoolArray)
    {
        for(uint256 i=0;i<10;i++)
        {
            divPoolArray[i] = globalDivRecords_[i].totalDividendCollection;
        }
        return divPoolArray;
    }
    

    function startNextMonth() public returns(bool)
    {
        require(thisMonthEnd < now,"month end not reached");
        thisMonthEnd = now + oneMonthDuration;
        divPoolRecord memory temp;
        temp.totalEligibleCount = 1;
        globalDivRecords_.push(temp);
        uint lastDivPoolIndex = globalDivRecords_.length -1;
        if (lastDivPoolIndex > 0)
        {
            globalDivRecords_[lastDivPoolIndex].totalEligibleCount = globalDivRecords_[lastDivPoolIndex -1].totalEligibleCount;
        }
        return (true);
    }

    function updateNPayAutoPool(uint _level,address _user) internal returns (bool)
    {
        uint a = _level -1;
        uint len = autoPoolLevel[a].length;
        autoPool memory temp;
        temp.userID = userInfos[_user].id;
        temp.autoPoolIndex_ = nextMemberFillIndex[a];       
        autoPoolLevel[a].push(temp);        
        uint idx = nextMemberFillIndex[a];

        address payable usr = userAddressByID[autoPoolLevel[a][idx].userID];
        if(usr == address(0)) usr = userAddressByID[defaultRefID];
        for(uint i=0;i<10;i++)
        {
            uint amount = autoPoolSubDist[a][i];
            totalGainInAutoPool[usr] += amount;
            netTotalUserWithdrawable[usr] += amount;
            emit autoPoolPayEv(now, usr,a+1, amount, _user);
            idx = autoPoolLevel[a][idx].autoPoolIndex_; 
            usr = userAddressByID[autoPoolLevel[a][idx].userID];
            if(usr == address(0)) usr = userAddressByID[defaultRefID];
        }

        if(nextMemberFillBox[a] == 0)
        {
            nextMemberFillBox[a] = 1;
        }   
        else if (nextMemberFillBox[a] == 1)
        {
            nextMemberFillBox[a] = 2;
        }
        else
        {
            nextMemberFillIndex[a]++;
            nextMemberFillBox[a] = 0;
        }
        autoPoolIndex[_user][_level - 1] = len;
        emit updateAutoPoolEv(now, _level, len, _user);
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
    
    
    /*======================================
    =            ADMIN FUNCTIONS           =
    ======================================*/
    
    function changeTokenaddress(address newTokenaddress) onlyOwner public returns(string memory){
        //if owner makes this 0x0 address, then it will halt all the operation of the contract. This also serves as security feature.
        //so owner can halt it in any problematic situation. Owner can then input correct address to make it all come back to normal.
        tokenAddress = newTokenaddress;
        return("Token address updated successfully");
    }
    
    function changeDefaultRefID(uint newDefaultRefID) onlyOwner public returns(string memory){
        //this ref ID will be assigned to user who joins without any referral ID.
        defaultRefID = newDefaultRefID;
        return("Default Ref ID updated successfully");
    }

    function ownerChangeAddress(uint _id, address _oldUserAddress, address payable _newUserAddress ) onlyOwner public returns(bool)
    {
        require(userInfos[_oldUserAddress].id == _id, "id not matching with address");
        newUserAddress[_oldUserAddress] = _newUserAddress;
        return true;
    }

    
    function acceptChangeAddress() public returns(bool)
    {
        address payable nAddress = newUserAddress[msg.sender];
        uint uid = userInfos[msg.sender].id;
        require( uid > 0 && nAddress != address(0), "please contact admin");
        newUserAddress[msg.sender] = address(0);
        eligibleUser[nAddress] = eligibleUser[msg.sender];
        eligibleUser[msg.sender] = 0;

        userInfos[nAddress] = userInfos[msg.sender];
        userInfos[msg.sender].id = 0;
        userInfos[msg.sender].joined = false;
        userInfos[msg.sender].referrerID = 0;
        userInfos[msg.sender].originalReferrer = 0;
        delete userInfos[msg.sender].referral;

        for(uint i=0;i<10;i++)
        {
            autoPoolIndex[nAddress][i]=autoPoolIndex[msg.sender][i];
            autoPoolIndex[msg.sender][i] = 0;
        }

        for(uint i=0;i<10;i++)
        {
            autoPoolIndex[nAddress][i]=autoPoolIndex[msg.sender][i];
            autoPoolIndex[msg.sender][i] = 0;
            userInfos[msg.sender].levelExpired[i] = 0;
        }
        userAddressByID[userInfos[nAddress].id] = nAddress;
        totalGainInMainNetwork[nAddress] = totalGainInMainNetwork[msg.sender] ;
        totalGainInMainNetwork[msg.sender] = 0;
        totalGainInUniLevel[nAddress] = totalGainInUniLevel[msg.sender]; 
        totalGainInUniLevel[msg.sender] = 0;
        totalGainInAutoPool[nAddress] = totalGainInAutoPool[msg.sender] ;
        totalGainInAutoPool[msg.sender] = 0;
        netTotalUserWithdrawable[nAddress] = netTotalUserWithdrawable[msg.sender] ;
        netTotalUserWithdrawable[msg.sender] = 0;
        return true;
    }

    function reCheckEligibility(address[] memory user, bool[] memory _divOnHold) public onlySigner returns(bool)
    {
        require(user.length == _divOnHold.length, "array count mismatch");
        uint i;
        for (i=0; i<_divOnHold.length; i++)
        {
            divOnHold[user[i]] = _divOnHold[i];
        }
        return true;
    }

}