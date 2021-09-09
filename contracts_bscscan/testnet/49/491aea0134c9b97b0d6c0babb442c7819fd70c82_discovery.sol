/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

pragma solidity 0.5.16;

//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {

    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
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



//*******************************************************************//
//------------------         TOKEN interface        -------------------//
//*******************************************************************//

 interface busdInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
 }




//*******************************************************************//
//------------------        MAIN contract         -------------------//
//*******************************************************************//

contract discovery is owned {

    // Replace below address with main TOKEN token
    address public tokenTokenAddress;
    uint public maxDownLimit = 2;
    uint public levelLifeTime = 1555200000000;  //
    uint public lastIDCount = 0;
    uint public defaultRefID = 1;   //this ref ID will be used if user joins without any ref ID

    struct userInfo {
        bool joined;
        uint id;
        uint origRefID;
        uint referrerID;
        address[] parent;
        mapping(uint => uint) levelExpired;
    }

    mapping(uint => uint) public priceOfLevel;
    mapping(uint => uint) public distForLevel;
    mapping(uint => uint) public autoPoolDist;

    struct autoPool
    {
        uint userID;
        uint autoPoolParent;
    }
    mapping(uint => autoPool[]) public autoPoolLevel;  // users lavel records under auto pool scheme
    mapping(address => mapping(uint => uint)) public autoPoolIndex; //to find index of user inside auto pool
    uint[10] public nextMemberFillIndex;  // which auto pool index is in top of queue to fill in 
    uint[10] public nextMemberFillBox;   // 3 downline to each, so which downline need to fill in

    uint[10][10] public autoPoolSubDist;

    

    mapping (address => userInfo) public userInfos;
    mapping (uint => address payable) public userAddressByID;

    event regLevelEv(address indexed _userWallet, uint indexed _userID, uint indexed _referrerID, uint _time, address _refererWallet, uint _originalReferrer);
    event levelBuyEv(address indexed _user, uint _level, uint _amount, uint _time);
    event paidForLevelEv(address indexed _user, address indexed _parent, uint _level, uint _amount, uint _time);
    event lostForLevelEv(address indexed _user, address indexed _parent, uint _level, uint _amount, uint _time);

    event updateAutoPoolEv(uint timeNow,uint autoPoolLevelIndex,uint userIndexInAutoPool, address user);
    event autoPoolPayEv(uint timeNow,address paidTo,uint paidForLevel, uint paidAmount, address paidAgainst);

    
    constructor(address payable ownerAddress, address payable ID1address) public {
        owner = ownerAddress;

        emit OwnershipTransferred(address(0), owner);
        address payable ownerWallet = ID1address;
        priceOfLevel[1] = 20 * ( 10 ** 18 );   

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            origRefID: 1,
            referrerID: 1,
            parent: new address[](0)
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;

        for(uint i = 1; i <= 1; i++) {
            userInfos[ownerWallet].levelExpired[i] = 99999999999;
            emit paidForLevelEv(address(0), ownerWallet, i, distForLevel[i], now);
        }

        autoPool memory temp;
        for (uint i = 0 ; i < 6; i++)
        {
           temp.userID = lastIDCount;  
           autoPoolLevel[i].push(temp);        
           autoPoolIndex[ownerWallet][i] = 0;
        } 

        emit regLevelEv(ownerWallet, 1, 0, now, address(this), 0);

    }

    function () payable external {
        revert();
    }

    function regUser(uint _referrerID) public returns(bool) 
    {
        //this saves gas while using this multiple times
        address msgSender = msg.sender; 
        uint originalReferrer = _referrerID;

        //checking all conditions
        require(!userInfos[msgSender].joined, 'User exist');
        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;

        if(userInfos[userAddressByID[_referrerID]].parent.length >= maxDownLimit) _referrerID = userInfos[findFreeReferrer(userAddressByID[_referrerID])].id;

        require( busdInterface(tokenTokenAddress).transferFrom(msgSender, address(this), priceOfLevel[1]),"token transfer failed");


        
        //update variables
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            origRefID: originalReferrer,
            referrerID: _referrerID,
            parent: new address[](0)
        });

        userInfos[msgSender] = UserInfo;
        userAddressByID[lastIDCount] = msg.sender;

        userInfos[msgSender].levelExpired[1] = now + levelLifeTime;

        userInfos[userAddressByID[_referrerID]].parent.push(msgSender);

        require(payForLevel( msgSender),"pay for level fail");
        emit regLevelEv(msgSender, lastIDCount, _referrerID, now,userAddressByID[_referrerID], originalReferrer);
        emit levelBuyEv(msgSender, 1, priceOfLevel[1], now);
        require(updateNPayAutoPool(1,msgSender),"auto pool update fail");
        return true;
    }

    function payForLevel(address _user) internal returns (bool){
        payOut(userAddressByID[userInfos[_user].origRefID], 25 * ( 10 ** 17));
        address ref =userAddressByID[userInfos[_user].referrerID];
        uint amt =  5 * ( 10 ** 17);
        for(uint i=0;i<20;i++)
        {
            if(i > 9) amt = 25 * ( 10 ** 16);
            payOut(ref, amt);
            ref =userAddressByID[userInfos[ref].referrerID];
        }
        return true;

    }

    function findFreeReferrer(address _user) public view returns(address) {
        if(userInfos[_user].parent.length < maxDownLimit) return _user;

        address[] memory parents = new address[](126);
        parents[0] = userInfos[_user].parent[0];
        parents[1] = userInfos[_user].parent[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(userInfos[parents[i]].parent.length == maxDownLimit) {
                if(i < 62) {
                    parents[(i+1)*2] = userInfos[parents[i]].parent[0];
                    parents[(i+1)*2+1] = userInfos[parents[i]].parent[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = parents[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }



    event payOutEv(uint timeNow,address caller,uint totalAmount);
    function payOut(address _user, uint _amount) internal returns(bool)
    {
        require(busdInterface(tokenTokenAddress).transfer(owner, _amount / 10),"token transfer failed");
        require(busdInterface(tokenTokenAddress).transfer(_user, _amount * 9 / 10),"token transfer failed");
        emit payOutEv(now, _user, _amount);
        
    }



    function updateNPayAutoPool(uint _level,address _user) internal returns (bool)
    {
        uint a = _level -1;
        uint len = autoPoolLevel[a].length;
        autoPool memory temp;
        temp.userID = userInfos[_user].id;
        temp.autoPoolParent = nextMemberFillIndex[a];       
        autoPoolLevel[a].push(temp);        

        address ref;
        if(_level < 4)
        {
            ref = userAddressByID[autoPoolLevel[_level-1][temp.autoPoolParent].userID];
            payOut(ref, 5 ** (_level+1) );
        }
        else
        {
            ref = userAddressByID[autoPoolLevel[_level-1][temp.autoPoolParent].userID];
            payOut(ref, 10 ** (_level+1) );
        }

        uint box = nextMemberFillBox[a];

        if(nextMemberFillBox[a] <= 8)
        {
            nextMemberFillBox[a]++;
        }   
        else
        {
            nextMemberFillIndex[a]++;
            nextMemberFillBox[a] = 0;
        }
        autoPoolIndex[_user][_level - 1] = len;
        emit updateAutoPoolEv(now, _level, len, _user);

        if(_level < 4 && box == 9) updateNPayAutoPool(_level + 1,ref);

        return true;
    }


    function viewUserparent(address _user) public view returns(address[] memory) {
        return userInfos[_user].parent;
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
    
    function changeTOKENaddress(address newTOKENaddress) onlyOwner public returns(string memory){
        tokenTokenAddress = newTOKENaddress;
        return("TOKEN address updated successfully");
    }
    
    function changeDefaultRefID(uint newDefaultRefID) onlyOwner public returns(string memory){
        defaultRefID = newDefaultRefID;
        return("Default Ref ID updated successfully");
    }





}