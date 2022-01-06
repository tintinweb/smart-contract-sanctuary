/**
 *Submitted for verification at BscScan.com on 2022-01-05
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)  external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract XGold is owned
{
    IERC20 private _busd;
    uint public maxDownLimit = 2;

    uint public lastIDCount;
    uint public defaultRefID = 1;
    bool goLive; 

    uint[16] public levelPrice;
    uint public directPercent = 40000000; 

    address holderContract;

    struct userInfo {
        bool joined;
        uint id;
        uint origRef;
        uint levelBought;
        address[] referral;

        mapping(uint8 => bool) activeXGoldLevels;
    }

    struct goldInfo {
        uint currentParent;
        uint position;
        address[] childs;
        uint reinvestNumber;

        bool blocked;
    }

    struct ReferralPosition {
        address userAddress;
        uint8 position;
    }

    mapping (address => userInfo) public userInfos;
    mapping (address => mapping(uint => uint)) public userReInvestNumbers;
    mapping (address => mapping(uint8 => uint8)) public userFourthLevelCounts; // uint is level
    mapping (uint => address ) public userAddressByID;

    mapping (address => mapping(uint => goldInfo)) public activeGoldInfos;
    mapping (address => mapping(uint => goldInfo[])) public archivedGoldInfos;

    mapping(address => bool) public regPermitted;
    mapping(address => uint) public levelPermitted;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event DirectPaidEv(uint indexed from,uint indexed to, uint amount, uint level, uint timeNow);
    event Payout(uint indexed sender, uint indexed receiverId, uint indexed fromId, uint8 matrix, uint level, uint amount, uint missedAmount);
    event Reinvest(uint indexed sender, uint indexed userId, uint indexed currentReferrerId, uint callerId, uint8 level, uint reInvestCount);
    event FreezeAmount(uint indexed userId, uint indexed referrerId, uint8 level, uint amount);

    event NewUserPlace(uint indexed sender, uint indexed userId, uint indexed referrerId, uint8 matrix, uint8 level, uint8 place, uint reInvestCount, uint originalReferrer);

    event Upgrade(address indexed sender, uint indexed userId, uint indexed referrerId, uint8 matrix, uint level);

    constructor(address _owner, address busdAddress) public {
        owner = _owner;
        _busd = IERC20(busdAddress);
        goLive == true;
        levelPrice[1] = 100e18;
        levelPrice[2] = 200e18;
        levelPrice[3] = 400e18;
        levelPrice[4] = 800e18;
        levelPrice[5] = 1600e18;
        levelPrice[6] = 3200e18;
        levelPrice[7] = 6400e18;
        levelPrice[8] = 12800e18;
        levelPrice[9] = 25000e18;
        levelPrice[10]= 50000e18;
        levelPrice[11]= 100000e18;
        levelPrice[12]= 200000e18;
        levelPrice[13]= 400000e18;
        levelPrice[14]= 800000e18;
        levelPrice[15]= 1500000e18;

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
            userFourthLevelCounts[owner][uint8(i)] = 0;
        }

    }

    function ()  external payable {
        
    }

    // function addCount(uint8 level)  public {
    //     userFourthLevelCounts[owner][level]++;
    // }

    function regUser(uint _referrerID) public payable returns(bool)
    {
        //require(goLive, "wait shifting not finished");
        uint prc = levelPrice[1];
        //uint balance = _busd.balanceOf(msg.sender);
        require(_busd.allowance(msg.sender, address(this)) >= prc, "Allow Contract to spend BUSD");
        _busd.transferFrom(msg.sender, address(this), prc);
        regUser_(msg.sender, _referrerID, true, prc);
        return true;
    }

    function regUser_(address msgsender, uint _referrerID, bool pay, uint prc) internal returns(bool)
    {
        require(!userInfos[msgsender].joined, "already joined");
        if(! (_referrerID > 0 && _referrerID <= lastIDCount) ) _referrerID = 1;
        
        address origRef = userAddressByID[_referrerID];
        (uint _parentID,bool treeComplete  ) = findFreeParentInDown(_referrerID, 1);
        require(!treeComplete, "No free place");

        lastIDCount++;
        userInfo memory UserInfo;
        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            origRef:_referrerID,            
            levelBought:1,
            referral: new address[](0)
        });
        userInfos[msgsender] = UserInfo;
        userAddressByID[lastIDCount] = msgsender;
        userInfos[origRef].referral.push(msgsender);
        userReInvestNumbers[msgsender][1] = 0;

        userInfos[msgsender].referral.push(userAddressByID[_referrerID]); // i think some mistake here       

        goldInfo memory temp;
        temp.currentParent = _parentID;
        temp.position = activeGoldInfos[userAddressByID[_parentID]][1].childs.length + 1;
        activeGoldInfos[msgsender][1] = temp;
        activeGoldInfos[userAddressByID[_parentID]][1].childs.push(msgsender);
        userFourthLevelCounts[msgsender][1] = 0;

        emit Registration(msg.sender, userAddressByID[_referrerID], lastIDCount, _referrerID);
        
        placeUsers(msgsender, 1);
        
        //direct payout
        //if(pay) address(uint160(origRef)).transfer(prc * 4/10);
        if(pay) _busd.transfer(origRef, prc * 4/10);

        emit DirectPaidEv(userInfos[msgsender].id,userInfos[origRef].id,prc*4/10, 1,now);

        uint userPosition;
        uint user4thParent;
        (userPosition, user4thParent) = getPosition(msgsender, 1);
        
        if(userFourthLevelCounts[userAddressByID[user4thParent]][1] == 16)
        {
            payForLevel(msgsender, 1, true, pay);   // true means recycling pay to all except 25%
        }
        else
        {
            payForLevel(msgsender, 1, false, pay);   // false means no recycling pay to all
        }
        
        if(userFourthLevelCounts[userAddressByID[user4thParent]][1] == 16)
        {
            recyclePosition(user4thParent,1, pay );
        }
 
        return true;
    }

    function placeUsers(address msgsender, uint8 _level) private {
        (uint8 uplineCount, ReferralPosition memory fi, ReferralPosition memory s, ReferralPosition memory t, ReferralPosition memory f) = getUserPlacePositions(msgsender, _level);
        emitNewUserPlaceEvent(_level,uplineCount, msgsender, fi, s, t, f);
        if(uplineCount == 4) {
            userFourthLevelCounts[f.userAddress][_level]++;
        }
    }
    
    function emitNewUserPlaceEvent(uint8 _level, uint8 uplineCount, address msgsender, ReferralPosition memory first, ReferralPosition memory second, ReferralPosition memory third, ReferralPosition memory fourth) private {
        if(uplineCount == 1) {
            emit NewUserPlace(userInfos[msg.sender].id, userInfos[msgsender].id, userInfos[first.userAddress].id, 1, _level, first.position, userReInvestNumbers[first.userAddress][_level], userInfos[msgsender].origRef);
        }
        else if(uplineCount == 2) {
           emit NewUserPlace(userInfos[msg.sender].id, userInfos[msgsender].id, userInfos[first.userAddress].id, 1, _level, first.position, userReInvestNumbers[first.userAddress][_level], userInfos[msgsender].origRef);
           emit NewUserPlace(userInfos[msg.sender].id, userInfos[msgsender].id, userInfos[second.userAddress].id, 1, _level, second.position, userReInvestNumbers[second.userAddress][_level], userInfos[msgsender].origRef);
        }
        else if(uplineCount == 3) {
            emit NewUserPlace(userInfos[msg.sender].id, userInfos[msgsender].id, userInfos[first.userAddress].id, 1, _level, first.position, userReInvestNumbers[first.userAddress][_level], userInfos[msgsender].origRef);
            emit NewUserPlace(userInfos[msg.sender].id, userInfos[msgsender].id, userInfos[second.userAddress].id, 1, _level, second.position, userReInvestNumbers[second.userAddress][_level], userInfos[msgsender].origRef);
            emit NewUserPlace(userInfos[msg.sender].id, userInfos[msgsender].id, userInfos[third.userAddress].id, 1, _level, third.position, userReInvestNumbers[third.userAddress][_level], userInfos[msgsender].origRef);
        }
        else {
            emit NewUserPlace(userInfos[msg.sender].id, userInfos[msgsender].id, userInfos[first.userAddress].id, 1, _level, first.position, userReInvestNumbers[first.userAddress][_level], userInfos[msgsender].origRef);
            emit NewUserPlace(userInfos[msg.sender].id, userInfos[msgsender].id, userInfos[second.userAddress].id, 1, _level, second.position, userReInvestNumbers[second.userAddress][_level], userInfos[msgsender].origRef);
            emit NewUserPlace(userInfos[msg.sender].id, userInfos[msgsender].id, userInfos[third.userAddress].id, 1, _level, third.position, userReInvestNumbers[third.userAddress][_level], userInfos[msgsender].origRef);
            emit NewUserPlace(userInfos[msg.sender].id, userInfos[msgsender].id, userInfos[fourth.userAddress].id, 1, _level, fourth.position, userReInvestNumbers[fourth.userAddress][_level], userInfos[msgsender].origRef);
        }
    }

    function getPosition(address _user, uint _level) public view returns(uint recyclePosition_, uint recycleID)
    {
        uint positionForSecondUprLvl = 1;
        uint a;
        uint b;
        uint c;
        uint d;
        bool id1Found;
        a = activeGoldInfos[_user][_level].position;

        uint parent_ = activeGoldInfos[_user][_level].currentParent;
        b = activeGoldInfos[userAddressByID[parent_]][_level].position;
        //position = b + 2;
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

    function getUserPlacePositions(address _user, uint8 _level) private returns(uint8 uplineCount, ReferralPosition memory first, ReferralPosition memory second, ReferralPosition memory third, ReferralPosition memory fourth)
    {
        bool id1Found;
        
        uint parent_ = activeGoldInfos[_user][_level].currentParent;
        
        first = ReferralPosition ({
            userAddress: userAddressByID[activeGoldInfos[_user][_level].currentParent],
            position: uint8(activeGoldInfos[_user][_level].position)
        });
        
        
        second = ReferralPosition ({
            userAddress: address(0),
            position: 0
        });
        third = ReferralPosition ({
            userAddress: address(0),
            position: 0
        });
        
        fourth = ReferralPosition ({
            userAddress: address(0),
            position: 0
        });

        uplineCount = 1;
        
        if(parent_ == 1) {
            id1Found = true;
        } 

        if(!id1Found)
        {
            (parent_, second.userAddress, second.position) = setSecondRefPosition(parent_, first.userAddress, _level, uint8(first.position));
            
            uplineCount++;
            if(parent_ == 1 ) id1Found = true;
        }

        if(!id1Found)
        {
            (parent_, third.userAddress, third.position) = setThirdRefPosition(_user, parent_, second.userAddress, _level, uint8(second.position));
            
            uplineCount++;

            if(parent_ == 1 ) id1Found = true;
        }
        
        if(!id1Found) {
            parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent;
            fourth.userAddress = userAddressByID[parent_];

            fourth.position = setTopRefPosition(fourth.userAddress, third.userAddress, _user, _level, third.position, 8, 16, 4);
            uplineCount++;
        } 

        return (uplineCount, first, second, third, fourth);

    }

    function setTopRefPosition(address topRef, address downRef, address userAddress, uint level, 
        uint8 position, uint8 leftTreeAmount, uint8 rightTreeAmount, uint8 treeLevel) internal returns(uint8) {
        if (activeGoldInfos[topRef][level].childs[0] == downRef) {
            position = position + leftTreeAmount;
            return position;
        } else if (activeGoldInfos[topRef][level].childs[1] == downRef) {
            position = position + rightTreeAmount;
            return position;
        }
    }
    
    function setSecondRefPosition(uint parent_, address refPosFirstAddress, uint _level, uint8 position) internal returns(uint, address, uint8) {
            parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent;
            address userAddress = userAddressByID[parent_];
            uint8 len = uint8(activeGoldInfos[userAddress][_level].childs.length);
            if ((len == 2) &&
                (activeGoldInfos[userAddress][_level].childs[0] == refPosFirstAddress) &&
                (activeGoldInfos[userAddress][_level].childs[1] == refPosFirstAddress)) {
                if (activeGoldInfos[refPosFirstAddress][_level].childs.length == 1) {
                    position = 5;
                } else {
                    position = 6;
                }
            } else if (activeGoldInfos[userAddress][_level].childs[0] == refPosFirstAddress) {
                if (activeGoldInfos[refPosFirstAddress][_level].childs.length == 1) {
                    position = 3;
                } else {
                    position = 4;
                }
            } else if (activeGoldInfos[userAddress][_level].childs[1] == refPosFirstAddress) {
                if (activeGoldInfos[refPosFirstAddress][_level].childs.length == 1) {
                    position = 5;
                } else {
                    position = 6;
                }
            }
            return (parent_,userAddress, position);
    }
    
    function setThirdRefPosition(address msgsender, uint parent_, address refPosSecondAddress, uint _level, uint8 position) internal returns(uint, address, uint8) {
            parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent;

            address userAddress = userAddressByID[parent_];
            position = setTopRefPosition(userAddress, refPosSecondAddress, msgsender, _level, position, 4, 8, 3);
            return (parent_,userAddress, position);
    }

    function getCorrectGold(address childss,uint _level,  uint parenT ) internal view returns (goldInfo memory tmps)
    {

        uint len = archivedGoldInfos[childss][_level].length;
        if(activeGoldInfos[childss][_level].currentParent == parenT) return activeGoldInfos[childss][_level];
        if(len > 0 )
        {
            for(uint j=len-1; j>=0; j--)
            {
                tmps = archivedGoldInfos[childss][_level][j];
                if(tmps.currentParent == parenT)
                {
                    break;                    
                }
                if(j==0) 
                {
                    tmps = activeGoldInfos[childss][_level];
                    break;
                }
            }
        } 
        else
        {
            tmps = activeGoldInfos[childss][_level];
        }       
        return tmps;
    }

    
    function findFreeParentInDown(uint  refID_ , uint _level) public view returns(uint parentID, bool noFreeReferrer)
    {
        address _user = userAddressByID[refID_];
        if(activeGoldInfos[_user][_level].childs.length < maxDownLimit) return (refID_, false);

        address[14] memory childss;
        uint[14] memory parenT;

        childss[0] = activeGoldInfos[_user][_level].childs[0];
        parenT[0] = refID_;
        childss[1] = activeGoldInfos[_user][_level].childs[1];
        parenT[1] = refID_;

        address freeReferrer;
        noFreeReferrer = true;

        goldInfo memory temp;

        for(uint i = 0; i < 14; i++)
        {
            temp = getCorrectGold(childss[i],_level, parenT[i] );

            if(temp.childs.length == maxDownLimit) {
                if(i < 6) {
                    childss[(i+1)*2] = temp.childs[0];
                    parenT[(i+1)*2] = userInfos[childss[i]].id;
                    childss[((i+1)*2)+1] = temp.childs[1];
                    parenT[((i+1)*2)+1] = parenT[(i+1)*2];
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
        require(goLive, "shift not finished");
        uint prc = levelPrice[_level];
        require(_busd.allowance(msg.sender, address(this)) >= prc, "Allow Contract to spend BUSD");
        _busd.transferFrom(msg.sender, address(this), prc);

        buyLevel_(msg.sender,_level, true, prc);
        address _referrerAdd = findEligibleRef(userAddressByID[userInfos[msg.sender].origRef], _level);
        
        return true;
    }

    function buyLevel_(address msgsender, uint _level, bool pay, uint prc) internal returns(bool)
    {
        require(userInfos[msgsender].joined, "already joined");       
        
        require(userInfos[msgsender].levelBought + 1 == _level, "please buy previous level first");

        uint _referrerID = userInfos[msgsender].origRef;
        while(userInfos[userAddressByID[_referrerID]].levelBought < _level)
        {
            _referrerID = userInfos[userAddressByID[_referrerID]].origRef;
        }
        bool treeComplete;
        (_referrerID,treeComplete) = findFreeParentInDown(_referrerID, _level); // from here _referrerID is _parentID
        require(!treeComplete, "no free place");

        userInfos[msgsender].levelBought = _level; 
        userReInvestNumbers[msgsender][_level] = 0;

        goldInfo memory temp;
        temp.currentParent = _referrerID;
        temp.position = activeGoldInfos[userAddressByID[_referrerID]][_level].childs.length + 1;
        activeGoldInfos[msgsender][_level] = temp;
        activeGoldInfos[userAddressByID[_referrerID]][_level].childs.push(msgsender);
        userFourthLevelCounts[msgsender][uint8(_level)] = 0;
        
        emit Upgrade(msg.sender, userInfos[msg.sender].id, _referrerID, 1, _level);
        
        placeUsers(msgsender, uint8(_level));
        //direct payout
        address origRef = userAddressByID[userInfos[msgsender].origRef];
        if(_level > 1 ) origRef = findEligibleRef(origRef, _level);
        if(pay) _busd.transfer(origRef, prc * 4/10);
        emit DirectPaidEv(userInfos[msgsender].id,userInfos[origRef].id,prc*4/10, _level,now);

        uint userPosition;
        uint user4thParent;
        (userPosition, user4thParent) = getPosition(msgsender, _level);

        if(userFourthLevelCounts[userAddressByID[user4thParent]][uint8(_level)] == 16) 
        {
            payForLevel(msgsender, _level, true, pay);   // true means recycling pay to all except 25%
        }
        else
        {
            payForLevel(msgsender, _level, false, pay);   // false means no recycling pay to all
        }
        
        if(userFourthLevelCounts[userAddressByID[user4thParent]][uint8(_level)] == 16)
        {           
            recyclePosition(user4thParent, _level, pay);
        }
        
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

    function getAddressById(uint id) public view returns(address addr) {
        return userAddressByID[id];
    }

    event debugEv(address _user, bool treeComplete,uint user4thParent,uint _level,uint userPosition);
    function recyclePosition(uint _userID, uint _level, bool pay)  internal returns(bool)
    {
        uint prc = levelPrice[_level];
        address msgSender = userAddressByID[_userID];

        archivedGoldInfos[msgSender][_level].push(activeGoldInfos[msgSender][_level]); 

        if(_userID == 1 ) 
        {
            goldInfo memory temp;
            temp.currentParent = 1;
            temp.position = 0;
            activeGoldInfos[msgSender][_level] = temp;
            
            userFourthLevelCounts[msgSender][uint8(_level)] = 0;
            userReInvestNumbers[owner][_level]++;
            emit Reinvest(userInfos[msg.sender].id, userInfos[owner].id, 0, userInfos[msg.sender].id, uint8(_level), activeGoldInfos[owner][_level].reinvestNumber);
            
            return true;
        }

        if(pay) require( ext(holderContract).getFund(prc), "fetching amount fail");
        
            // to find eligible referrer
            uint _parentID =   getValidRef(msgSender, _level); // user will join under his eligible referrer


            (_parentID,) = findFreeParentInDown(_parentID, _level);

            goldInfo memory temp;
            temp.currentParent = _parentID;
            temp.position = activeGoldInfos[userAddressByID[_parentID]][_level].childs.length + 1;
            activeGoldInfos[msgSender][_level] = temp;
            activeGoldInfos[userAddressByID[_parentID]][_level].childs.push(msgSender);
            userFourthLevelCounts[msgSender][uint8(_level)] = 0;
            activeGoldInfos[msgSender][_level].reinvestNumber++;

            //direct payout
            address origRef = userAddressByID[userInfos[msgSender].origRef];
            if(_level > 1 ) origRef = findEligibleRef(origRef, _level);
            if(pay) _busd.transfer(origRef, prc * 4/10);
            emit DirectPaidEv(userInfos[msgSender].id,userInfos[origRef].id,prc*4/10, _level,now);
            
        uint userPosition;
        
        placeUsers(msgSender, uint8(_level));

        (userPosition, prc) = getPosition(msgSender, _level); //  from here prc = user4thParent

        if(userFourthLevelCounts[userAddressByID[prc]][uint8(_level)] == 16) 
        {
            payForLevel(msgSender, _level, true, pay);   // false means recycling pay to all except 25%
        }
        else
        {
            payForLevel(msgSender, _level, false, pay);   // true means no recycling pay to all        
        }

        uint originalRef = getValidRef(msgSender, _level);
        userReInvestNumbers[owner][_level]++;
        invokeReinvestEvent(originalRef, msgSender, _level);

        if(userFourthLevelCounts[userAddressByID[prc]][uint8(_level)] == 16)
        {           
            recyclePosition(prc, _level, pay);
        }
        return true;
    }
    
    function invokeReinvestEvent(uint originalRef, address msgsender, uint _level) private {
        emit Reinvest(userInfos[msg.sender].id, userInfos[msgsender].id, userInfos[userAddressByID[originalRef]].id, userInfos[msg.sender].id, uint8(_level), activeGoldInfos[msgsender][_level].reinvestNumber);
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


    function payForLevel(address _user, uint _level, bool recycle, bool pay) internal returns(bool)
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
                if(pay) _busd.transfer(parent_, price_ * percentPayout[i-1] / 100);
                emit Payout(userInfos[_user].id, userInfos[parent_].id, userInfos[_user].id, 1, _level, price_ * percentPayout[i-1] / 100, 0);
            }
            else if(recycle == false && userFourthLevelCounts[parent_][uint8(_level)] < 13)
            {
                if(pay) _busd.transfer(parent_, price_ * percentPayout[i-1] / 100);
                emit Payout(userInfos[_user].id, userInfos[parent_].id, userInfos[_user].id, 1, _level, price_ * percentPayout[i-1] / 100, 0);
            }
            else
            {
                if(userInfos[parent_].id == 1) {
                    if(pay) _busd.transfer(parent_, price_ * percentPayout[i-1] / 100);
                    emit Payout(userInfos[_user].id, userInfos[parent_].id, userInfos[_user].id, 1, _level, price_ * percentPayout[i-1] / 100, 0);
                } else {
                    if(pay) _busd.transfer(holderContract, price_ * percentPayout[i-1] / 100);
                    emit Payout(userInfos[_user].id, userInfos[parent_].id, userInfos[_user].id, 1, _level, price_ * percentPayout[i-1] / 100, 0);
                }
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

    function viewChilds(address _user, uint _level, bool _archived, uint _archivedIndex) public view returns(address[2] memory _child)
    {
        uint len;
        if(!_archived)
        {
            len = activeGoldInfos[_user][_level].childs.length;
            if(len > 0) _child[0] = activeGoldInfos[_user][_level].childs[0];
            if(len > 1) _child[1] = activeGoldInfos[_user][_level].childs[1];
        }
        else
        {
            len = archivedGoldInfos[_user][_level][_archivedIndex].childs.length;
            if(len > 0) _child[0] = archivedGoldInfos[_user][_level][_archivedIndex].childs[0];
            if(len > 1) _child[1] = archivedGoldInfos[_user][_level][_archivedIndex].childs[1];            
        }
        return (_child);
    }

    function upgradeContract() public onlyOwner returns(bool)
    {
        address(uint160(owner)).transfer(address(this).balance);
        _busd.transfer(owner, _busd.balanceOf(address(this)));
        return true;
    }

    //************************************************************//
    //****************** TO UPDATE DATA FROM OLD *****************//
    //************************************************************//

    function goLive_() public onlyOwner returns(bool)
    {
        goLive = !goLive;
        return true;
    }

    function shiftUser(address _user, uint _referrerID) public  returns(bool)
    {
        require(!goLive, "shifting finished");
        uint prc = levelPrice[1];
        regUser_(_user, _referrerID, false, prc);
        return true;
    }

    function shiftLevel(address _user, uint _level) public onlyOwner returns(bool)
    {
        require(!goLive, "shift finished");
        uint prc = levelPrice[_level];
        buyLevel_(_user,_level, false, prc);
        return true;
    }


    //this function will stop working after going live.. so no one can allow new users to upgrade their levels after going live.
    function allowBuyOld(address[] memory _user, uint[] memory _level) public  onlyOwner returns(bool)
    {
        require(!goLive, "shift finished");
        uint256 arrayLength = _user.length;
        require(arrayLength <= 150, 'Too many wallets');
        for(uint8 i=0; i < arrayLength; i++){
            levelPermitted[_user[i]] = _level[i];
        }
        
        return true;
    }

    function activateLevel(uint _level) public returns(bool)
    {
        require(goLive, "shift is not finished");
        uint permitted = levelPermitted[msg.sender];
        require( permitted <= _level && permitted > 0, "Not Permitted");
        uint prc = levelPrice[_level];
        buyLevel_(msg.sender,_level, false, prc);
        return true;
    }



}