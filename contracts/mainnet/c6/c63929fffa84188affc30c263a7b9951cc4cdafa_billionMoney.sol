/**
 *Submitted for verification at Etherscan.io on 2020-04-27
*/

/**
 *Submitted for verification at Etherscan.io on 2020-03-27
*/

pragma solidity 0.5.16; /*


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
    
contract owned {
    address  public owner;
    address  internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {

    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address  _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

interface interfaceOldBMContract
{
    function lastIDCount() external view returns(uint);
    function userInfos(address user) external view returns(bool, uint, uint);
    function viewUserLevelExpired(address _user, uint _level) external view returns(uint);
    function totalDivCollection() external view returns(uint);
    function thisMonthEnd() external view returns(uint);
    function nextMemberFillIndex(uint) external view returns(uint);
    function nextMemberFillBox(uint) external view returns(uint); 
    function autoPoolLevel(uint _lvl, uint _index) external view returns (uint, uint); 
    function userAddressByID(uint) external view returns(address);
}



//*******************************************************************//
//------------------         PAX interface        -------------------//
//*******************************************************************//

 interface paxInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
 }




//*******************************************************************//
//------------------        MAIN contract         -------------------//
//*******************************************************************//
// This is billionMoney Version 2 , which works after the last id of old contract
contract billionMoney is owned {

    // Replace below address with main PAX token
    // All address here below taken from old contract
    address public paxTokenAddress;
    address public oldBMContractAddress;
    address public specialAddress1;
    address public specialAddress2;
    uint public maxDownLimit = 2;
    uint public levelLifeTime = 15552000;  // =180 days;
    uint public lastIDCount;
    uint public defaultRefID = 1;   //this ref ID will be used if user joins without any ref ID 
    struct userInfo {
        bool joined;
        uint id;
        uint parentID;
        uint referrerID;
        address[] dReferred;
        mapping(uint => uint) levelExpired;
    }
    mapping(uint => uint) public priceOfLevel; // Main network level price chart 
    mapping(uint => uint) public distForLevel; // distribution price chart for main network
    mapping(uint => uint) public autoPoolDist; // price chart for auto pool level
    mapping(uint => uint) public uniLevelDistPart; // price chart for uniLevel distribution
    uint256 public totalDivCollection;
    uint public globalDivDistPart = 0.6 ether;
    uint public systemDistPart = 1 ether;   
    uint public oneMonthDuration = 2592000; // = 30 days
    uint public thisMonthEnd;
    struct divPoolRecord
    {
        uint totalDividendCollection;
        uint totalEligibleCount;
    }
    divPoolRecord[] public divPoolRecords;
    mapping ( address => uint) public eligibleUser; // if val > 0 then user is eligible from this divPoolRecords;
    mapping(uint => mapping ( address => bool)) public dividendReceived; // dividend index => user => true/false

    struct autoPool
    {
        uint userID;
        uint autoPoolParent;
    }
    mapping(uint => autoPool[]) public autoPoolLevel;  // users lavel records under auto pool scheme
    uint lastlDCount; // To track total id/synced from last contract, so that in this contract id will start form next
    mapping(address => mapping(uint => uint)) public autoPoolIndex; //to find index of user inside auto pool
    uint[10] public nextMemberFillIndex;  // which auto pool index is in top of queue to fill in 
    uint[10] public nextMemberFillBox;   // 3 downline to each, so which downline need to fill in
    uint[10][10] public autoPoolSubDist;
    bool stopSwap;
    mapping (address => userInfo)  userInfos;  // to see value two seperate 'view' functions created where userInfo can be checked by Id and by address both
    mapping (uint => address )  userAddressByID; // this keeps user address with respect to id , will return id of given address
    mapping(address => uint256) public totalGainInMainNetwork; //This is the withdrawable amount of user which he gains through main network, after each withdraw it becomes 0
    mapping(address => uint256) public totalGainInUniLevel; // This is the withdrawable amount of user which he gains from unilevel network, after each withdraw it becomes 0
    mapping(address => uint256) public totalGainInAutoPool; // This is the withdrawable amount of user from auto pool level after each withdraw it becomes 0 
    mapping(address => uint256) public netTotalUserWithdrawable;  //Dividend is not included in it dividend is seperate pool which eligible user can withdraw after each next month
    event regLevelEv(address indexed _userWallet, uint indexed _userID, uint indexed _referrerID, uint _time, address _refererWallet, uint _originalReferrer);
    event levelBuyEv(address indexed _user, uint _level, uint _amount, uint _time);
    event paidForLevelEv(address indexed _user, address indexed _referredID, uint _level, uint _amount, uint _time);
    event lostForLevelEv(address indexed _user, address indexed _referredID, uint _level, uint _amount, uint _time);
    event payDividendEv(uint timeNow,uint payAmount,address paitTo);
    event updateAutoPoolEv(uint timeNow,uint autoPoolLevelIndex,uint userIndexInAutoPool, address user);
    event autoPoolPayEv(uint timeNow,address paidTo,uint paidForLevel, uint paidAmount, address paidAgainst);
    event paidForUniLevelEv(uint timeNow,address PaitTo,uint Amount);
    uint[10] autoPoolCount;  // This variable is only useful for fetching auto pool records from old contract, once all records fetched it has no use
    
    constructor(address  ownerAddress) public {
        owner = ownerAddress;

        emit OwnershipTransferred(address(0), owner);

        priceOfLevel[1] = 20 ether;
        priceOfLevel[2] = 20 ether;
        priceOfLevel[3] = 40 ether;
        priceOfLevel[4] = 140 ether;
        priceOfLevel[5] = 600 ether;
        priceOfLevel[6] = 5000 ether;
        priceOfLevel[7] = 5500 ether;
        priceOfLevel[8] = 10000 ether;
        priceOfLevel[9] = 20000 ether;
        priceOfLevel[10] = 40000 ether;

        distForLevel[1] = 10 ether;
        distForLevel[2] = 15 ether;
        distForLevel[3] = 30 ether;
        distForLevel[4] = 120 ether;
        distForLevel[5] = 500 ether;
        distForLevel[6] = 4700 ether;
        distForLevel[7] = 5000 ether;
        distForLevel[8] = 9000 ether;
        distForLevel[9] = 18000 ether;
        distForLevel[10] = 35000 ether;

        autoPoolDist[1] = 4 ether;
        autoPoolDist[2] = 5 ether;
        autoPoolDist[3] = 10 ether;
        autoPoolDist[4] = 20 ether;
        autoPoolDist[5] = 100 ether;
        autoPoolDist[6] = 300 ether;
        autoPoolDist[7] = 500 ether;
        autoPoolDist[8] = 1000 ether;
        autoPoolDist[9] = 2000 ether;
        autoPoolDist[10] = 5000 ether;        

        uniLevelDistPart[1] = 1 ether;
        uniLevelDistPart[2] = 0.6 ether;
        uniLevelDistPart[3] = 0.4 ether;

        for (uint i = 4 ; i < 11; i++)
        {
           uniLevelDistPart[i] =  0.2 ether;
        } 

        autoPool memory temp;
        for (uint i = 11 ; i < 21; i++)
        {
           uniLevelDistPart[i] =  0.1 ether;
           uint a = i-11;
           autoPoolLevel[a].push(temp);
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

    }

    function ()  external {
        revert();
    }

    // use findFreeReferrer function to get _parentID 
    function regUser(uint _referrerID, uint _parentID) public returns(bool) 
    {
        //this saves gas while using this multiple times
        address  msgSender = msg.sender; 
        if(!stopSwap) stopSwap = true;
        //checking all conditions
        require(!userInfos[msgSender].joined, 'User exist');
        
        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;
        uint fct = 1;
        require(userInfos[userAddressByID[_parentID]].joined, 'freeReferrer not exist');

        //transferring PAX tokens from smart user to smart contract for level 1
        if(!(msgSender==specialAddress1 || msgSender == specialAddress2)){
            require( paxInterface(paxTokenAddress).transferFrom(msgSender, address(this), priceOfLevel[1]),"token transfer failed");
        }
        else
        {
            fct = 0;
        }
        
        //update variables
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: _referrerID,
            parentID: _parentID,
            dReferred: new address[](0)
        });

        userInfos[msgSender] = UserInfo;
        userAddressByID[lastIDCount] = msgSender;

        userInfos[msgSender].levelExpired[1] = now + levelLifeTime;

        userInfos[userAddressByID[_referrerID]].dReferred.push(msgSender);

        totalGainInMainNetwork[owner] += systemDistPart * fct;
        netTotalUserWithdrawable[owner] += systemDistPart * fct;

        if(thisMonthEnd < now) startNextMonth();

        uint lastDivPoolIndex = divPoolRecords.length -1 ;
        divPoolRecords[lastDivPoolIndex].totalDividendCollection += globalDivDistPart * fct;
        totalDivCollection += globalDivDistPart * fct;

        address usr = userAddressByID[_referrerID];
        if(eligibleUser[usr] == 0)
        {
            if(userInfos[usr].dReferred.length == 10 )
            {
                eligibleUser[usr] = lastDivPoolIndex + 1;
                divPoolRecords[lastDivPoolIndex].totalEligibleCount++;
            }
        }

        require(payForLevel(1, msgSender,fct),"pay for level fail");
        emit regLevelEv(msgSender, lastIDCount, _parentID, now,userAddressByID[_referrerID], _referrerID );
        emit levelBuyEv(msgSender, 1, priceOfLevel[1] * fct, now);
        require(updateNPayAutoPool(1,msgSender,fct),"auto pool update fail");
        return true;
    }

    function viewCurrentMonthDividend() public view returns(uint256 amount, uint256 indexCount)
    {
        uint256 length = divPoolRecords.length;
        return (divPoolRecords[length-1].totalDividendCollection,length);
    }

    function buyLevel(uint _level) public returns(bool){
        
        //this saves gas while using this multiple times
        address msgSender = msg.sender;   
        
        
        //checking conditions
        require(userInfos[msgSender].joined, 'User not exist'); 
        uint fct=1;
        require(_level >= 1 && _level <= 10, 'Incorrect level');
        
        //transfer tokens
        if(!(msgSender==specialAddress1 || msgSender == specialAddress2)){
            require( paxInterface(paxTokenAddress).transferFrom(msgSender, address(this), priceOfLevel[_level]),"token transfer failed");
        }
        else
        {
            fct = 0;
        }
        
        
        //updating variables
        if(_level == 1) {
            userInfos[msgSender].levelExpired[1] += levelLifeTime;
        }
        else {
            for(uint l =_level - 1; l > 0; l--) require(userInfos[msgSender].levelExpired[l] >= now, 'Buy the previous level');

            if(userInfos[msgSender].levelExpired[_level] == 0) userInfos[msgSender].levelExpired[_level] = now + levelLifeTime;
            else userInfos[msgSender].levelExpired[_level] += levelLifeTime;
        }

        require(payForLevel(_level, msgSender,fct),"pay for level fail");
        emit levelBuyEv(msgSender, _level, priceOfLevel[_level] * fct, now);
        require(updateNPayAutoPool(_level,msgSender,fct),"auto pool update fail");
        return true;
    }
    

    function payForLevel(uint _level, address _user,uint fct) internal returns (bool){
        address referer;
        address referer1;
        address referer2;
        address referer3;
        address referer4;

        if(_level == 1 || _level == 6) {
            referer = userAddressByID[userInfos[_user].referrerID];
            payForUniLevel(userInfos[_user].referrerID,fct);
            totalGainInMainNetwork[owner] += systemDistPart * fct;
            netTotalUserWithdrawable[owner] += systemDistPart * fct;
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
            totalGainInMainNetwork[referer] += distForLevel[_level] * fct;
            netTotalUserWithdrawable[referer] += distForLevel[_level] * fct;
            emit paidForLevelEv(referer, msg.sender, _level, distForLevel[_level] * fct, now);

        }
        else{

            emit lostForLevelEv(referer, msg.sender, _level, distForLevel[_level] * fct, now);
            payForLevel(_level, referer,fct);

        }
        return true;

    }

    function findFreeReferrerByAddress(address _user) public view returns(uint) {
        if(userInfos[_user].dReferred.length < maxDownLimit) return userInfos[_user].id;

        address[] memory downLine = new address[](126);
        downLine[0] = userInfos[_user].dReferred[0];
        downLine[1] = userInfos[_user].dReferred[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(userInfos[downLine[i]].dReferred.length == maxDownLimit) {
                if(i < 62) {
                    downLine[(i+1)*2] = userInfos[downLine[i]].dReferred[0];
                    downLine[(i+1)*2+1] = userInfos[downLine[i]].dReferred[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = downLine[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return userInfos[freeReferrer].id;
    }

    function findFreeReferrerByID(uint _userID) public view returns(uint) {
        return findFreeReferrerByAddress(userAddressByID[_userID]);
    }




    function payForUniLevel(uint _referrerID, uint fct) internal returns(bool)
    {
        uint256 endID = 21;
        for (uint i = 0 ; i < endID; i++)
        {
            address usr = userAddressByID[_referrerID];
            _referrerID = userInfos[usr].referrerID;
            if(usr == address(0)) usr = userAddressByID[defaultRefID];
            uint Amount = uniLevelDistPart[i + 1 ]  * fct;
            totalGainInUniLevel[usr] += Amount;
            netTotalUserWithdrawable[usr] += Amount;
            emit paidForUniLevelEv(now,usr, Amount);
        }
        return true;
    }

    event withdrawMyGainEv(uint timeNow,address caller,uint totalAmount);
    function withdrawMyDividendNAll() public returns(uint)
    {
        address  caller = msg.sender;
        require(userInfos[caller].joined, 'User not exist');
        uint from = eligibleUser[caller];
        uint totalAmount;
        if(from > 0)
        {
            from --;
            uint lastDivPoolIndex = divPoolRecords.length;
            if( lastDivPoolIndex > 1 )
            {
                lastDivPoolIndex = lastDivPoolIndex -2;

                for(uint i=0;i<150;i++)
                {
                    if(lastDivPoolIndex < i) break;
                    uint curIndex = lastDivPoolIndex - i;
                    if( curIndex >= from && !dividendReceived[curIndex][caller] )
                    {
                        totalAmount +=  ( divPoolRecords[curIndex].totalDividendCollection * 10000000000 /  divPoolRecords[curIndex].totalEligibleCount ) / 10000000000;
                        dividendReceived[curIndex][caller] = true;
                    }

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
        require(paxInterface(paxTokenAddress).transfer(msg.sender, totalAmount),"token transfer failed");
        emit withdrawMyGainEv(now, caller, totalAmount);
        
    }

    function viewMyDividendPotential(address user) public view returns(uint256 totalDivPotential, uint256 lastUnPaidIndex)
    {
        if (eligibleUser[user] > 0 )
        {
            uint256 i;
            uint256 lastIndex = divPoolRecords.length -1;
            for(i=1;i<50;i++)
            {
                lastUnPaidIndex = lastIndex - i;
                if(dividendReceived[lastUnPaidIndex][user] == true) break;
                totalDivPotential = totalDivPotential + ( divPoolRecords[lastUnPaidIndex].totalDividendCollection * 10000000000 /  divPoolRecords[lastUnPaidIndex].totalEligibleCount);               
            }
            return (totalDivPotential, lastUnPaidIndex + 1);
        }
        return (0,0);
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
            divPoolArray[i] = divPoolRecords[i].totalDividendCollection;
        }
        return divPoolArray;
    }
    

    function startNextMonth() public returns(bool)
    {
        require(thisMonthEnd < now,"month end not reached");
        thisMonthEnd = now + oneMonthDuration;
        divPoolRecord memory temp;
        temp.totalEligibleCount = 1;
        divPoolRecords.push(temp);
        uint lastDivPoolIndex = divPoolRecords.length -1;
        if (lastDivPoolIndex > 0)
        {
            divPoolRecords[lastDivPoolIndex].totalEligibleCount = divPoolRecords[lastDivPoolIndex -1].totalEligibleCount;
            lastlDCount++;
        }
        return (true);
    }

    function updateNPayAutoPool(uint _level,address _user, uint fct) internal returns (bool)
    {
        uint a = _level -1;
        uint len = autoPoolLevel[a].length;
        autoPool memory temp;
        temp.userID = userInfos[_user].id;
        temp.autoPoolParent = nextMemberFillIndex[a];       
        autoPoolLevel[a].push(temp);        
        uint idx = nextMemberFillIndex[a];

        address  usr = userAddressByID[autoPoolLevel[a][idx].userID];
        if(usr == address(0)) usr = userAddressByID[defaultRefID];
        for(uint i=0;i<10;i++)
        {
            uint amount = autoPoolSubDist[a][i]  * fct;
            totalGainInAutoPool[usr] += amount;
            netTotalUserWithdrawable[usr] += amount;
            emit autoPoolPayEv(now, usr,a+1, amount, _user);
            idx = autoPoolLevel[a][idx].autoPoolParent; 
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


    function viewUserdReferred(address _user) public view returns(address[] memory) {
        return userInfos[_user].dReferred;
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
    
    function changePAXaddress(address newPAXaddress) onlyOwner public returns(string memory){
        //if owner makes this 0x0 address, then it will halt all the operation of the contract. This also serves as security feature.
        //so owner can halt it in any problematic situation. Owner can then input correct address to make it all come back to normal.
        paxTokenAddress = newPAXaddress;
        return("PAX address updated successfully");
    }



    
    function changeDefaultRefID(uint newDefaultRefID) onlyOwner public returns(string memory){
        //this ref ID will be assigned to user who joins without any referredIDs ID.
        defaultRefID = newDefaultRefID;
        return("Default Ref ID updated successfully");
    }

    function userInfoS(address usr) public view returns(bool joined, uint id, uint parent, uint referrer, address[10] memory direct,uint[10] memory levelExpired)
    {
        joined = userInfos[usr].joined;
        id = userInfos[usr].id;
        parent = userInfos[usr].parentID;
        referrer = userInfos[usr].referrerID;
        uint len = userInfos[usr].dReferred.length;
        for (uint i=0;i<len;i++)
        {
            direct[i] = userInfos[usr].dReferred[i];
        }
        for (uint i=1;i<=10;i++)
        {
            levelExpired[i-1] = userInfos[usr].levelExpired[i];
        }  
        return (joined, id, parent, referrer, direct, levelExpired) ;     
    }

    function getUserAddressById(uint id) public view returns(address)
    {
        if(id>0 && id <= lastIDCount)
        {
            return userAddressByID[id];
        }
        return address(0);
    }



    //*********************************************************************************************/
    //*********************All below functions are only for swaping purpose ********************** /
    //******** these functions will not work twice updating for any record even by admin **********/
    //******** this is a trust of public and responsibility of admin to make sure all *************/
    //******** updated records are perfectly matching with old contract which *********************/
    //****************** any user can verify by comparing it with old records**********************/

    //***** All these functions written in a way that once sysncing complete can not be caalled again *********/


    // this is only to set first id will work only once
    function setFirstID() public returns (string memory)
    {
        address msgSender = msg.sender;
        require(!userInfos[msgSender].joined, "can't create first id twice");
        require(lastlDCount == 0 , "can't create first id twice"); 
        ( uint _id,uint _parentID ) = viewUserInfos(msg.sender);
        userInfo memory UserInfo;
        UserInfo.joined = true;
        UserInfo.id = _id;
        UserInfo.parentID = _parentID;
        userInfos[msgSender] = UserInfo;
        userAddressByID[_id] = msgSender;
        for(uint i = 1; i <= 10; i++) {
            userInfos[msgSender].levelExpired[i] = 99999999999;
        }
        autoPool memory temp;
        for (uint i = 0 ; i < 10; i++)
        {
           temp.userID = _id;  
           autoPoolLevel[i].push(temp);
           autoPoolIndex[msgSender][i] = _id;
        } 
        eligibleUser[msgSender] = 1;
        lastIDCount ++;
    }

    function viewUserInfos(address userAddress) public view returns(uint _id, uint _parentID)
    {
        ( ,_id,_parentID) = interfaceOldBMContract(oldBMContractAddress).userInfos(userAddress);
        return (_id,_parentID);
    }

    function setGlobalVariables() public onlyOwner returns(bool)
    {
        require(thisMonthEnd==0, "can't be called twice");
        totalDivCollection = interfaceOldBMContract(oldBMContractAddress).totalDivCollection();
        thisMonthEnd = interfaceOldBMContract(oldBMContractAddress).thisMonthEnd();
        for(uint i =0; i < 10; i++)
        {
            nextMemberFillIndex[i] = interfaceOldBMContract(oldBMContractAddress).nextMemberFillIndex(i);
            nextMemberFillBox[i] = interfaceOldBMContract(oldBMContractAddress).nextMemberFillBox(i);
        }
        return true;
    }

    function setEligibleUsers(address[] memory _users,uint divIndex) public onlyOwner returns(bool)
    {
        require(divPoolRecords[divIndex].totalEligibleCount == 0 , "can't run twice" );
        require(!stopSwap , "can't run now was for swaping only");
        uint len = _users.length;
        for (uint i=0;i<len;i++)
        {
            eligibleUser[_users[i]] = divIndex + 1;
        }
        divPoolRecords[divIndex].totalEligibleCount = ( divIndex * divPoolRecords[divIndex].totalEligibleCount ) + len;
        return true;
    }

    function setDividendPoolData(uint _totalDividendCollection, uint _totalDividendCollection2 ) public onlyOwner returns(bool)
    {
        require(totalDivCollection == 0, "can't run twice");
        divPoolRecord memory temp;
        temp.totalDividendCollection = _totalDividendCollection;
        divPoolRecords.push(temp);
        divPoolRecord memory temp2;
        temp2.totalDividendCollection = _totalDividendCollection2;
        divPoolRecords.push(temp);        
        return (true);
    }

    function setLastIDCount(uint _lastIDCountOfOldContract) public onlyOwner returns(bool)
    {
        require(lastIDCount == 1, "can't run twice");
        lastIDCount = _lastIDCountOfOldContract;
        return true;
    }

    function setUserInfos( uint _id,uint _parentID ) public onlyOwner returns(bool)
    {
            require(_id >= 1 && _id <= lastIDCount, "can't run twice for same id or non-existing in old");
            address _user = interfaceOldBMContract(oldBMContractAddress).userAddressByID(_id);
            require(!stopSwap , "can't run now was for swaping only");
            userInfo memory UserInfo;
            UserInfo.joined = true;
            UserInfo.id = _id;
            UserInfo.parentID = _parentID;
            userInfos[_user] =UserInfo;
            userAddressByID[_id] = _user;
            uint _levelExpired;
            for(uint i = 1; i <= 10; i++) {
                _levelExpired = interfaceOldBMContract(oldBMContractAddress).viewUserLevelExpired(_user, i);
                userInfos[_user].levelExpired[i] = _levelExpired;
            }
        return true;
    }

    function setAutoPool(uint level, uint recordCount) public onlyOwner returns(bool)
    {
        require(level <= 10 && level > 0, "invalid level");
        require(!stopSwap , "can't run now was for swaping only");
        uint a = level -1;
        uint tmp = autoPoolCount[a];
        autoPool memory temp;
        for (uint i = autoPoolCount[a]; i<tmp + recordCount; i++)
        {
            (uint _id,uint _parentID) = interfaceOldBMContract(oldBMContractAddress).autoPoolLevel(tmp,i);
            if(_id > 1 )
            {
                temp.userID = _id;
                temp.autoPoolParent = _parentID;
                autoPoolLevel[a].push(temp);
                autoPoolIndex[userAddressByID[_id]][a] = autoPoolLevel[a].length -1;
            }
        }
        autoPoolCount[a] = tmp + recordCount; 
        return true;
    }

    function setReferrerNDirect(uint _id, uint _referrer, address[] memory direct) public onlyOwner returns(bool)
    {
        address usr = userAddressByID[_id];
        require(!stopSwap , "can't run now was for swaping only");
        userInfos[usr].referrerID = _referrer;
        uint len = direct.length;
        for (uint i=0;i<len;i++)
        {
            userInfos[usr].dReferred.push(direct[i]);
        }
        return true;
    }

    function updateAddresses(address _paxTokenAddress,address _oldBMContractAddress,address _specialAddress1,address _specialAddress2 ) public onlyOwner returns (bool)
    {
        require(!stopSwap , "can't run now was for swaping only");
        paxTokenAddress = _paxTokenAddress;
        oldBMContractAddress = _oldBMContractAddress;
        specialAddress1 = _specialAddress1;
        specialAddress2 = _specialAddress2;
        return true;
    }

}