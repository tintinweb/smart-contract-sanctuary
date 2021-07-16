//SourceUnit: canonshot2.sol

 pragma solidity 0.5.10;

contract CanonShot {
    address payable ownerWallet;
    address payable ownerWallet2;
    
    uint public startTime = 9999999999;
    uint public levelTwoTime = 9999999999;
    uint public currUserID = 0;
    uint public currApplyUserID = 0;
    uint public productX = 1000000*1e2;

    // uint public pool1currUserID = 0;
    uint public poolActiveID = 0;
    uint public poolFinishID = 0;  
     
    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;
    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;
    uint16 constant ORIGIN_YEAR = 1970;


    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint referredUserCount;
        string refCode;
        mapping(uint => uint) levelExpired;
    }

    struct ApplyStruct {
        bool isExist;
        bool isSelected;
        uint id;
        uint userId;
        uint inning;
        uint256 standardTime;        
    }
    
    struct SelectedStruct {
        bool isExist;
        uint id;
        uint userId;
        uint applyId;
        uint paymentReceived;
        uint paymentRemaining;
        uint tankType;
        uint inning;
        uint256 standardTime;
    }

    
    mapping (address => UserStruct) public users;   //주소 -> userStruct 매칭
    mapping (uint => address) public userList;      //userid -> 주소 매칭
     
    mapping (address => ApplyStruct) public poolApplies;    //주소 -> 구매신청 매칭
    mapping (uint => address) public poolApplyUserList;     //번호 -> 신청주소 매칭

    mapping (address => SelectedStruct) public poolSelected;    //주소 -> 선정된 매칭
    mapping (uint => address) public poolSelectedUserList;

    // mapping (address => PoolUserStruct) public pool1users;
    // mapping (uint => address) public pool1userList;
    
    // mapping (address => PoolUserStruct) public pool2users;
    // mapping (uint => address) public pool2userList;
    
    mapping(uint => uint) public LEVEL_PRICE;

    
    uint REGESTRATION_FESS = 500*1e2;
    ////////////////////////////////
    uint tank1_price =   6000*1e2;
    uint tank2_price =  10000*1e2;
    uint tank3_price =  12000*1e2;
    uint tank4_price =  15000*1e2;
    uint tank5_price =  20000*1e2;
    uint tank6_price =  50000*1e2;
    uint tank7_price = 100000*1e2;
   
    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event getRefBal(address indexed _user,uint level,uint amount ,address sender);
    event getProRefBal(address indexed _user,uint level,uint amount,address sender);
    event regPoolEntry(address indexed _user, uint256 _timeindex, uint _time);
    event getPoolPayment(address indexed _receiver, uint product , uint amount ,uint purchaseid,address sender);
    event productPayClear(address indexed _user, uint product,uint purchaseid,address sender);
        
    constructor() public {
        ownerWallet = address(0x4108dce7a29b49d2c8e9c10fe67d06a8fe19bb30b8);
        ownerWallet2 = address(0x41cf285988acedf0da8bae0292d2fe78287dd1b195);

        LEVEL_PRICE[1] = 250*1e2;
        LEVEL_PRICE[2] = 150*1e2;
        LEVEL_PRICE[3] =  50*1e2;
        LEVEL_PRICE[4] =  20*1e2;
        LEVEL_PRICE[5] =   5*1e2;
        
        UserStruct memory userStruct;
        currUserID++;

        string memory refCode = "K07K25H0";
        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            referredUserCount:0,
            refCode:refCode
        });
        
        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;
    }

    //회원등록 시작//
    function adminRegUser(string memory _referrerCode, string memory _myRefCode, address _regAddress) public payable {
        require(ownerWallet == msg.sender, "You don't have permission to select.");
        uint referID = 0;
        for(uint p = 1 ; p <= currUserID ; p++){
            if(keccak256(bytes(users[userList[p]].refCode)) == keccak256(bytes(_referrerCode))){
                referID = p;
            }
        }
        if(referID == 0){
            referID = 1;
        }
        require(!users[_regAddress].isExist,     "User Exists");
        require(referID <= currUserID,          "Incorrect referral ID");
        
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: referID,
            referredUserCount:0,
            refCode:_myRefCode
        });
    
        users[_regAddress] = userStruct;
        userList[currUserID]=_regAddress;
       
        users[userList[users[_regAddress].referrerID]].referredUserCount = users[userList[users[_regAddress].referrerID]].referredUserCount + 1;
        
    }
    function regUser(string memory _referrerCode, string memory _myRefCode) public payable {
        uint referID = 0;
        for(uint p = 1 ; p <= currUserID ; p++){
            if(keccak256(bytes(users[userList[p]].refCode)) == keccak256(bytes(_referrerCode))){
                referID = p;
            }
        }
        if(referID == 0){
            referID = 1;
        }
        require(!users[msg.sender].isExist,     "User Exists");
        require(referID <= currUserID,          "Incorrect referral ID");
        require(msg.value == REGESTRATION_FESS, "Incorrect Value");
       
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: referID,
            referredUserCount:0,
            refCode:_myRefCode
        });
    
        users[msg.sender] = userStruct;
        userList[currUserID]=msg.sender;
       
        users[userList[users[msg.sender].referrerID]].referredUserCount = users[userList[users[msg.sender].referrerID]].referredUserCount + 1;
        
        payReferral(1, msg.sender);
        emit regLevelEvent(msg.sender, userList[referID], now);
    }

    function payReferral(uint _level, address _user) internal {
        address referer;
        referer = userList[users[_user].referrerID];
        
        bool sent = false;
        uint level_price_temp = 0;
        
        level_price_temp = LEVEL_PRICE[_level];
        
        sent = address(uint160(referer)).send(level_price_temp);
        if (sent) {
            emit getRefBal(referer, _level, level_price_temp, msg.sender);
            if(_level < 5 && users[referer].referrerID >= 1){
                payReferral(_level + 1,referer);
            }
            else{
                sendBalance();
            }   
        }
    }
    //회원등록 끝//

    //구매신청 시작//
    function shoot() public payable{
        uint dateStr = getDate(now);
        emit regPoolEntry(msg.sender, dateStr, now);
    }

    function random(uint productCount) public view returns (uint8) {
       return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%productCount);
    }

    mapping(uint => uint256) public P_LEVEL_PRICE;
    /////////////////
    uint256 public productRefAmount = 0;
    ///////////////
     
    // DATETIME METHODS //
    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 4 != 0) {
                return false;
        }
        if (year % 100 != 0) {
                return true;
        }
        if (year % 400 != 0) {
                return false;
        }
        return true;
    }

    function leapYearsBefore(uint year) public pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        }
        else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        }
        else if (isLeapYear(year)) {
            return 29;
        }
        else {
            return 28;
        }
    }

    function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
        uint secondsAccountedFor = 0;
        uint buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint secondsInMonth;
        for (i = 1; i <= 12; i++) {
                secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                if (secondsInMonth + secondsAccountedFor > timestamp) {
                        dt.month = i;
                        break;
                }
                secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                        dt.day = i;
                        break;
                }
                secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        dt.weekday = getWeekday(timestamp);
    }

    function getDate(uint timestamp) public pure returns (uint) {
        return (uint(getYear(timestamp))*1e8) + (uint(getMonth(timestamp))*1e2) + (uint(getDay(timestamp))*1e4) + (uint(getHour(timestamp))*1e2);// + getMinute(timestamp);
    }

    function getYear(uint timestamp) public pure returns (uint16) {
        uint secondsAccountedFor = 0;
        uint16 year;
        uint numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
                if (isLeapYear(uint16(year - 1))) {
                        secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                }
                else {
                        secondsAccountedFor -= YEAR_IN_SECONDS;
                }
                year -= 1;
        }
        return year;
    }

    function getMonth(uint timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
                if (isLeapYear(i)) {
                        timestamp += LEAP_YEAR_IN_SECONDS;
                }
                else {
                        timestamp += YEAR_IN_SECONDS;
                }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
                monthDayCounts[1] = 29;
        }
        else {
                monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
                timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);

        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);

        // Second
        timestamp += second;

        return timestamp;
    }
    

    // SEND TO WALLET //
    function getEthBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function sendBalance() private{
        if (!address(uint160(ownerWallet)).send(getEthBalance())){
             
        }
    }
    function sendBalance2() public payable {
        require(msg.sender == ownerWallet, "You do not have permission");

        if (!address(uint160(ownerWallet)).send(getEthBalance())){
             
        }
    }
    function sendBalance3() public payable {
        require(msg.sender == ownerWallet, "You do not have permission");
        if (!address(uint160(ownerWallet2)).send(getEthBalance())){

        }
    }
    function sendBalanceTo(address payable _to, uint _amount) public payable {
        require(msg.sender == ownerWallet, "You do not have permission");

        if (!address(uint160(_to)).send(_amount)){
             
        }
    }
    function setStart(uint datetime) public {
        require(msg.sender == ownerWallet, "You do not have permission");
        startTime = datetime;
    }
    function setLeveltwoStart(uint datetime) public {
        require(msg.sender == ownerWallet, "You do not have permission");
        levelTwoTime = datetime;
    }
    function setProductX(uint prodX) public {
        require(msg.sender == ownerWallet, "You do not have permission");
        productX = prodX;
    }
}