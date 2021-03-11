/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity 0.5.10;

 
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

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


interface ext
{
    function getFund(uint amount) external returns(bool);
}

contract TronXContract is owned
{

    uint public maxDownLimit = 2;

    uint public lastIDCount;
    uint public defaultRefID = 1; 

    uint[16] public levelPrice;
    uint public directPercent = 40000000; 

    address holderContract;

    struct userInfo {
        bool joined;
        uint id;
        uint origRef;
        uint levelBought;
        address[] referral;
    }

    struct goldInfo {
        uint currentParent;
        uint position;
        address[] childs;
    }
    mapping (address => userInfo) public userInfos;
    mapping (uint => address ) public userAddressByID;

    mapping (address => mapping(uint => goldInfo)) public activeGoldInfos;
    mapping (address => mapping(uint => goldInfo[])) public archivedGoldInfos;

    event directPaidEv(uint from,uint to, uint amount, uint level, uint timeNow);
    event payForLevelEv(uint _userID,uint parentID,uint amount,uint fromDown, uint timeNow);
    event regLevelEv(uint _userID,uint _referrerID,uint timeNow,address _user,address _referrer);
    event levelBuyEv(uint amount, uint toID, uint level, uint timeNow);
    event treeEv(uint _userID, uint _userPosition,uint amount, uint placing,uint timeNow,uint _parent, uint _level );

    constructor() public {
        owner = msg.sender;


        levelPrice[1] = 200000000;
        levelPrice[2] = 400000000;
        levelPrice[3] = 800000000;
        levelPrice[4] = 1600000000;
        levelPrice[5] = 3200000000;
        levelPrice[6] = 6400000000;
        levelPrice[7] = 12800000000;
        levelPrice[8] = 25000000000;
        levelPrice[9] = 50000000000;
        levelPrice[10]= 100000000000;
        levelPrice[11]= 200000000000;
        levelPrice[12]= 400000000000;
        levelPrice[13]= 800000000000;
        levelPrice[14]= 1500000000000;
        levelPrice[15]= 2000000000000;

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            origRef:lastIDCount,            
            levelBought:15,
            referral: new address[](0)
        });
        userInfos[owner] = UserInfo;
        userAddressByID[lastIDCount] = owner;

        goldInfo memory temp;
        temp.currentParent = 1;
        temp.position = 0;
        for(uint i=1;i<=15;i++)
        {
            activeGoldInfos[owner][i] = temp;
        }
    }

    function ()  external payable {
        
    }

    function regUser(uint _referrerID) public payable returns(bool)
    {
        require(!userInfos[msg.sender].joined, "already joined");
        require(msg.value == levelPrice[1], "Invalid price paid");
        if(! (_referrerID > 0 && _referrerID <= lastIDCount) ) _referrerID = 1;
        address origRef = userAddressByID[_referrerID];
        (uint _parentID,  ) = findFreeParentInDown(_referrerID, 1);

        lastIDCount++;
        userInfo memory UserInfo;
        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            origRef:_referrerID,            
            levelBought:1,
            referral: new address[](0)
        });
        userInfos[msg.sender] = UserInfo;
        userAddressByID[lastIDCount] = msg.sender;
        userInfos[origRef].referral.push(msg.sender);

        userInfos[msg.sender].referral.push(userAddressByID[_referrerID]);       

        goldInfo memory temp;
        temp.currentParent = _parentID;
        temp.position = activeGoldInfos[userAddressByID[_parentID]][1].childs.length + 1;
        activeGoldInfos[msg.sender][1] = temp;
        activeGoldInfos[userAddressByID[_parentID]][1].childs.push(msg.sender);

        //direct payout
        address(uint160(origRef)).transfer(msg.value * 4/10);
        emit directPaidEv(userInfos[msg.sender].id,userInfos[origRef].id,msg.value*4/10, 1,now);
        
        (uint userPosition, uint user4thParent) = getPosition(msg.sender, 1);
        (,bool treeComplete) = findFreeParentInDown(user4thParent, 1);
        if(userPosition > 26 && userPosition < 31 ) 
        {
            payForLevel(msg.sender, 1, true);   // true means recycling pay to all except 25%
        }
        else
        {
            payForLevel(msg.sender, 1, false);   // false means no recycling pay to all
        }
        
        if(treeComplete)
        {
            recyclePosition(user4thParent,1 );
        }
        emit regLevelEv(lastIDCount,_referrerID,now, msg.sender,userAddressByID[_referrerID]);
        emit treeEv(lastIDCount,userPosition,msg.value,temp.position, now,  temp.currentParent, 1 );
        return true;
    }

    function getPosition(address _user, uint _level) public view returns(uint recyclePosition_, uint recycleID)
    {
        uint a;
        uint b;
        uint c;
        uint d;
        bool id1Found;
        a = activeGoldInfos[_user][_level].position;

        uint parent_ = activeGoldInfos[_user][_level].currentParent;
        b = activeGoldInfos[userAddressByID[parent_]][_level].position;
        if(parent_ == 1 ) id1Found = true;

        if(!id1Found)
        {
            parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent;
            c = activeGoldInfos[userAddressByID[parent_]][_level].position;
            if(parent_ == 1 ) id1Found = true;
        }

        if(!id1Found)
        {
            parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent;
            d = activeGoldInfos[userAddressByID[parent_]][_level].position;
            if(parent_ == 1 ) id1Found = true;
        }
        
        if(!id1Found) parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent;
        
        if (a == 2 && b == 2 && c == 2 && d == 2 ) return (30, parent_);
        if (a == 1 && b == 2 && c == 2 && d == 2 ) return (29, parent_);
        if (a == 2 && b == 1 && c == 2 && d == 2 ) return (28, parent_);
        if (a == 1 && b == 1 && c == 2 && d == 2 ) return (27, parent_);
        else return (1,parent_);

    }


    function findFreeParentInDown(uint  refID_ , uint _level) public view returns(uint parentID, bool noFreeReferrer)
    {
        address _user = userAddressByID[refID_];
        if(activeGoldInfos[_user][_level].childs.length < maxDownLimit) return (refID_, false);

        address[] memory childss = new address[](14);
        uint[] memory parenT = new uint[](6);
        uint parnt = refID_;
        parenT[0] = refID_;
        childss[0] = activeGoldInfos[_user][_level].childs[0];
        childss[1] = activeGoldInfos[_user][_level].childs[1];

        address freeReferrer;
        noFreeReferrer = true;

        goldInfo memory temp;

        for(uint i = 0; i < 14; i++)
        {
            temp = activeGoldInfos[childss[i]][_level];

            uint len = archivedGoldInfos[childss[i]][_level].length;
            if(len > 0 && i < 6)
            {
                for(uint j=len-1; j>=0; j--)
                {
                    if(i>1) parnt = parenT[(i-(i%2))/2];
                    if(archivedGoldInfos[childss[i]][_level][j].currentParent == parnt)
                    {
                        temp = archivedGoldInfos[childss[i]][_level][j];
                        break;
                    }
                }
            }

            if(temp.childs.length == maxDownLimit) {
                if(i < 6) {
                    childss[(i+1)*2] = temp.childs[0];
                    childss[((i+1)*2)+1] = temp.childs[1];
                    parenT[i] = temp.currentParent;
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = childss[i];
                break;
            } 
        } 
        if(noFreeReferrer) return (0, noFreeReferrer);      
        return (userInfos[freeReferrer].id, noFreeReferrer);
    }

    function buyLevel(uint _level) public payable returns(bool)
    {
        require(userInfos[msg.sender].joined, "already joined");
        require(msg.value == levelPrice[_level], "Invalid price paid");
        require(userInfos[msg.sender].levelBought + 1 == _level, "please buy previous level first");

        uint _referrerID = userInfos[msg.sender].origRef;
        while(userInfos[userAddressByID[_referrerID]].levelBought < _level)
        {
            _referrerID = userInfos[userAddressByID[_referrerID]].origRef;
        }

        (uint _parentID,) = findFreeParentInDown(_referrerID, _level);

        userInfos[msg.sender].levelBought = _level; 

        goldInfo memory temp;
        temp.currentParent = _parentID;
        temp.position = activeGoldInfos[userAddressByID[_parentID]][_level].childs.length + 1;
        activeGoldInfos[msg.sender][_level] = temp;
        activeGoldInfos[userAddressByID[_parentID]][_level].childs.push(msg.sender);

        //direct payout
        address origRef = userAddressByID[userInfos[msg.sender].origRef];
        if(_level > 1 ) origRef = findEligibleRef(origRef, _level);
        address(uint160(origRef)).transfer(msg.value * 4/10);
        emit directPaidEv(userInfos[msg.sender].id,userInfos[origRef].id,msg.value*4/10, _level,now);
        
        (uint userPosition, uint user4thParent) = getPosition(msg.sender, _level);
        (,bool treeComplete) = findFreeParentInDown(user4thParent, _level);
        if(userPosition > 26 && userPosition < 31 ) 
        {
            payForLevel(msg.sender, _level, true);   // true means recycling pay to all except 25%
        }
        else
        {
            payForLevel(msg.sender, _level, false);   // false means no recycling pay to all
        }
        
        if(treeComplete)
        {
            recyclePosition(user4thParent, _level);
        }
        emit levelBuyEv(msg.value, userInfos[msg.sender].id,_level, now);
        emit treeEv(userInfos[msg.sender].id,userPosition,msg.value,temp.position,now,0, _level );
        return true;
    }

    function findEligibleRef(address _origRef, uint _level) public view returns (address)
    {
        while (userInfos[_origRef].levelBought < _level)
        {
            _origRef = userAddressByID[userInfos[_origRef].origRef];
        }
        return _origRef;
    }


    event debugEv(address _user, bool treeComplete,uint user4thParent,uint _level,uint userPosition);
    function recyclePosition(uint _userID, uint _level)  internal returns(bool)
    {

        uint prc = levelPrice[_level];
        require( ext(holderContract).getFund(prc), "fetching amount fail");
        address msgSender = userAddressByID[_userID];

        if(_userID == 1 ) 
        {
            goldInfo memory temp;
            temp.currentParent = 1;
            temp.position = 0;
            activeGoldInfos[msgSender][_level] = temp;
            return true;
        }

        // to find eligible referrer
        uint _parentID =   getValidRef(msgSender, _level); // user will join under his eligible referrer

        
        (_parentID,) = findFreeParentInDown(_parentID, _level);


        archivedGoldInfos[msgSender][_level].push(activeGoldInfos[msgSender][_level]); 

        goldInfo memory temp;
        temp.currentParent = _parentID;
        temp.position = activeGoldInfos[userAddressByID[_parentID]][_level].childs.length + 1;
        activeGoldInfos[msgSender][_level] = temp;
        activeGoldInfos[userAddressByID[_parentID]][_level].childs.push(msgSender);

        //direct payout
        address origRef = userAddressByID[userInfos[msgSender].origRef];
        if(_level > 1 ) origRef = findEligibleRef(origRef, _level);
        address(uint160(origRef)).transfer(prc * 4/10);
        emit directPaidEv(userInfos[msgSender].id,userInfos[origRef].id,prc*4/10, _level,now);
        
        (uint userPosition, uint user4thParent) = getPosition(msgSender, _level);
        (,bool treeComplete) = findFreeParentInDown(user4thParent, _level);
        if(userPosition > 26 && userPosition < 31 ) 
        {
            payForLevel(msgSender, _level, true);   // false means recycling pay to all except 25%
        }
        else
        {
            payForLevel(msgSender, _level, false);   // true means no recycling pay to all        
        }
        
        emit debugEv(msgSender, treeComplete, user4thParent, _level, userPosition);

        if(treeComplete)
        {
            recyclePosition(user4thParent, _level);
        }
        return true;
    }

    function getValidRef(address _user, uint _level) public view returns(uint)
    {
        uint refID = userInfos[_user].origRef;
        uint lvlBgt = userInfos[userAddressByID[refID]].levelBought;

        while(lvlBgt < _level)
        {
            refID = userInfos[userAddressByID[refID]].origRef;
            lvlBgt = userInfos[userAddressByID[refID]].levelBought;
        }
        return refID;
    }


    function payForLevel(address _user, uint _level, bool recycle) internal returns(bool)
    {
        uint[4] memory percentPayout;
        percentPayout[0] = 5;
        percentPayout[1] = 10;
        percentPayout[2] = 20;
        percentPayout[3] = 25;

        address parent_ = userAddressByID[activeGoldInfos[_user][_level].currentParent];
        uint price_ = levelPrice[_level];
        for(uint i = 1;i<=4; i++)
        {
            if(i<4)
            {
                address(uint160(parent_)).transfer(price_ * percentPayout[i-1] / 100);
                emit payForLevelEv(userInfos[_user].id,userInfos[parent_].id,price_ * percentPayout[i-1] / 100, i,now);
            }
            else if(recycle == false)
            {
                address(uint160(parent_)).transfer(price_ * percentPayout[i-1] / 100);
                emit payForLevelEv(userInfos[_user].id,userInfos[parent_].id,price_ * percentPayout[i-1] / 100, i,now);                
            }
            else
            {
                address(uint160(holderContract)).transfer(price_ * percentPayout[i-1] / 100);
                emit payForLevelEv(userInfos[_user].id,0,price_ * percentPayout[i-1] / 100, i,now);                
            }
            parent_ = userAddressByID[activeGoldInfos[parent_][_level].currentParent];
        }
        return true;
    }

    function setContract(address _contract) public onlyOwner returns(bool)
    {
        holderContract = _contract;
        return true;
    }


}