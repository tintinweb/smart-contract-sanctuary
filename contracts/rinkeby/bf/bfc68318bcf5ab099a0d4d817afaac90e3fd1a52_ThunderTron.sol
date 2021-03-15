/**
 *Submitted for verification at Etherscan.io on 2021-03-15
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

contract ThunderTron is owned
{

    uint public maxDownLimit = 4;

    uint public lastIDCount;
    uint public defaultRefID = 1; 

    uint[13] public levelPrice;
    uint public directPayout = 50000000;
    uint[4] public clubPayout;

    mapping(uint => uint[4]) public clubFund;
    mapping(uint => uint[4]) public clubEligibleCount;
    mapping(address => mapping( uint => uint)) public eligible;
    mapping(address => mapping( uint => bool)) public paid;

    uint public dayEnd;
    uint public lastDayIndex;

    struct userInfo {
        bool joined;
        uint id;
        uint origRef;
        uint levelBought;
        uint directCount;
        address[] referral;
    }

    struct RecycleInfo {
        uint currentParent;
        uint position;
        address[] childs;
    }
    mapping (address => userInfo) public userInfos;
    mapping (uint => address ) public userAddressByID;
    mapping(address => mapping(uint => bool)) public firstComplete;

    mapping (address => mapping(uint => RecycleInfo)) public activeRecycleInfos;
    mapping (address => mapping(uint => RecycleInfo[])) public archivedRecycleInfos;

    event directPaidEv(uint from,uint to, uint amount, uint level, uint timeNow);
    event payForLevelEv(uint _userID,uint parentID,uint amount,uint fromDown, uint timeNow);
    event regLevelEv(uint _userID,uint _referrerID,uint timeNow,address _user,address _referrer);
    event levelBuyEv(uint amount, uint toID, uint level, uint timeNow);
    event treeEv(uint _userID, uint _userPosition,uint amount, uint placing,uint timeNow,uint _parent, uint _level );

    constructor() public {
        owner = msg.sender;
            
        levelPrice[1] = 250000000;

        for(uint i=2; i<13; i++)
        {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        clubPayout[1] = 10000000;
        clubPayout[2] = 15000000;
        clubPayout[3] = 25000000;

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            origRef:lastIDCount,            
            levelBought:12,
            directCount:100,
            referral: new address[](0)
        });
        userInfos[owner] = UserInfo;
        userAddressByID[lastIDCount] = owner;

        RecycleInfo memory temp;
        temp.currentParent = 1;
        temp.position = 0;
        for(uint i=1;i<=12;i++)
        {
            activeRecycleInfos[owner][i] = temp;
        }
    }

    function ()  external payable {
        
    }

    function regUser(uint _referrerID) public payable returns(bool)
    {
        require(!userInfos[msg.sender].joined, "already joined");
        require(msg.value == levelPrice[1] + 100000000, "Invalid price paid");
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
            directCount:0,
            referral: new address[](0)
        });
        userInfos[msg.sender] = UserInfo;
        userAddressByID[lastIDCount] = msg.sender;
        userInfos[origRef].referral.push(msg.sender);

        if(dayEnd < now) 
        {
            lastDayIndex++;
            clubEligibleCount[lastDayIndex][1] = 1;
            clubEligibleCount[lastDayIndex][2] = 1;
            clubEligibleCount[lastDayIndex][3] = 1;
            dayEnd = now + 1 days;
        }

        userInfos[origRef].directCount++;
        uint cnt = userInfos[origRef].directCount;
        if(cnt == 10 ) eligible[origRef][lastDayIndex] = 1;
        else if(cnt == 25 ) eligible[origRef][lastDayIndex] = 2;
        else if(cnt == 50 ) eligible[origRef][lastDayIndex] = 3;

        userInfos[msg.sender].referral.push(userAddressByID[_referrerID]);       

        RecycleInfo memory temp;
        temp.currentParent = _parentID;
        uint position = activeRecycleInfos[userAddressByID[_parentID]][1].childs.length + 1;
        temp.position = position;
        activeRecycleInfos[msg.sender][1] = temp;
        activeRecycleInfos[userAddressByID[_parentID]][1].childs.push(msg.sender);

        //direct payout
        address(uint160(origRef)).transfer(directPayout);
        emit directPaidEv(userInfos[msg.sender].id,userInfos[origRef].id,directPayout, 1,now);



        clubFund[lastDayIndex][1] += clubPayout[1];
        clubFund[lastDayIndex][2] += clubPayout[2];
        clubFund[lastDayIndex][3] += clubPayout[3];

        processPosition(origRef, position,1);

        emit regLevelEv(lastIDCount,_referrerID,now, msg.sender,userAddressByID[_referrerID]);
        return true;
    }

    event boughtLevelEv(uint id, uint level, uint position);
    event paidForLevelEv(uint id, uint amount, uint level, uint position);

    function processPosition(address _ref, uint position, uint _level) internal returns(bool)
    {
        //address usr = userAddressByID[_ref];
        if(!firstComplete[_ref][_level])
        {
            if(position == 2 ) 
            {
                if(_level <= 11 )
                {
                    buyLevel(_ref,_level +1);
                    emit boughtLevelEv(userInfos[_ref].id, _level+1, position);
                }
                else
                {
                    address(uint160(_ref)).transfer(levelPrice[_level]);
                    emit paidForLevelEv(userInfos[_ref].id, levelPrice[_level], _level, position);
                }
                
            }
            else if(position == 3) 
            {
                address(uint160(_ref)).transfer(levelPrice[_level]);
                emit paidForLevelEv(userInfos[_ref].id, levelPrice[_level], _level, position);
            }
            else if(position == 4)
            {
                recyclePosition(userInfos[_ref].id, _level);
                firstComplete[_ref][_level] = true;
            } 
        }
        else
        {
            if(position == 3) 
            {
                address(uint160(_ref)).transfer(levelPrice[1]);
                emit paidForLevelEv(userInfos[_ref].id, levelPrice[1], _level, position);
            }
            else
            {
                recyclePosition(userInfos[_ref].id, _level);
            } 
        }

        return true;
    }


    function findFreeParentInDown(uint  refID_ , uint _level) public view returns(uint parentID, bool noFreeReferrer)
    {
        address _user = userAddressByID[refID_];
        if(activeRecycleInfos[_user][_level].childs.length < maxDownLimit) return (refID_, false);
        else return (0, true);
    }

    function buyLevel(address msgsender, uint _level) internal returns(bool)
    {
        require(userInfos[msgsender].joined, "already joined");

        uint _referrerID = userInfos[msgsender].origRef;
        while(userInfos[userAddressByID[_referrerID]].levelBought < _level)
        {
            _referrerID = userInfos[userAddressByID[_referrerID]].origRef;
        }

        (uint _parentID,) = findFreeParentInDown(_referrerID, _level);

        userInfos[msgsender].levelBought = _level; 

        RecycleInfo memory temp;
        temp.currentParent = _parentID;
        uint position = activeRecycleInfos[userAddressByID[_parentID]][_level].childs.length + 1;
        temp.position = position;
        activeRecycleInfos[msgsender][_level] = temp;
        activeRecycleInfos[userAddressByID[_parentID]][_level].childs.push(msgsender);
        
        processPosition(userAddressByID[_referrerID], position,_level);

        emit levelBuyEv(levelPrice[_level], userInfos[msgsender].id,_level, now);
        return true;
    }

    function recyclePosition(uint _userID, uint _level)  internal returns(bool)
    {

        address msgSender = userAddressByID[_userID];

        if(_userID == 1 ) 
        {
            RecycleInfo memory temp;
            temp.currentParent = 1;
            temp.position = 0;
            activeRecycleInfos[msgSender][_level] = temp;
            return true;
        }

        // to find eligible referrer
        uint origRef =   getValidRef(msgSender, _level); // user will join under his eligible referrer

        
        (uint _parentID,) = findFreeParentInDown(origRef, _level);


        archivedRecycleInfos[msgSender][_level].push(activeRecycleInfos[msgSender][_level]); 

        RecycleInfo memory temp;
        temp.currentParent = _parentID;
        uint position = activeRecycleInfos[userAddressByID[_parentID]][_level].childs.length + 1;
        temp.position = position;
        activeRecycleInfos[msgSender][_level] = temp;
        activeRecycleInfos[userAddressByID[_parentID]][_level].childs.push(msgSender);
        
        processPosition(userAddressByID[origRef], position,_level);

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
    
    event getClubIncomeEv(address _user, uint amount);
    function getClubIncome(uint clubIndex) public returns(bool)
    {
        require(clubIndex < lastDayIndex, "Invalid index" );
        require(eligible[msg.sender][clubIndex] > 0 , "not eligible" );
        require(!paid[msg.sender][clubIndex], "already paid");
        paid[msg.sender][clubIndex] = true;
        uint idx = eligible[msg.sender][clubIndex];
        uint amt = clubFund[clubIndex][idx];
        amt =  amt / clubEligibleCount[clubIndex][idx];
        msg.sender.transfer(amt);
        emit getClubIncomeEv(msg.sender, amt);
    }

}