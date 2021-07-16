//SourceUnit: canonshot.sol

 pragma solidity 0.5.10;

contract CanonShot {
    address payable ownerWallet;
    address payable ownerWallet2;
    uint public startTime = 9999999999;
    uint public levelTwoTime = 9999999999;
    uint public currUserID = 0;
    uint public currApplyUserID = 0;
    uint public productX = 1000000*1e6;

    // uint public pool1currUserID = 0;
    uint public poolActiveID = 0;
    uint public poolFinishID = 0;
    // uint public pool2currUserID = 0;
    // uint public pool2activeUserID = 1;
      
     
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

    // struct PoolUserStruct {
    //     bool isExist;
    //     uint id;
    //     uint payment_received; 
    //     uint256 time1;
    //     uint256 time2;
    //     uint256 time3;
    //     uint256 time4;
    //     uint256 time5;
    //     uint256 time6;
    // }
    
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

    
    uint REGESTRATION_FESS = 500*1e6;
    ////////////////////////////////
    uint tank1_price =   6000*1e6;
    uint tank2_price =  10000*1e6;
    uint tank3_price =  12000*1e6;
    uint tank4_price =  15000*1e6;
    uint tank5_price =  20000*1e6;
    uint tank6_price =  50000*1e6;
    uint tank7_price = 100000*1e6;
   
    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event getRefBal(address indexed _user,uint level,uint amount ,address sender);
    event getProRefBal(address indexed _user,uint level,uint amount,address sender);
    event regPoolEntry(address indexed _user, uint256 _timeindex, uint _time);
    event getPoolPayment(address indexed _receiver, uint product , uint amount ,uint purchaseid,address sender);
    event productPayClear(address indexed _user, uint product,uint purchaseid,address sender);
        
    constructor() public {
        ownerWallet = address(0x4108dce7a29b49d2c8e9c10fe67d06a8fe19bb30b8);
        ownerWallet2 = address(0x41cf285988acedf0da8bae0292d2fe78287dd1b195);

        LEVEL_PRICE[1] = 250*1e6;
        LEVEL_PRICE[2] = 150*1e6;
        LEVEL_PRICE[3] =  50*1e6;
        LEVEL_PRICE[4] =  20*1e6;
        LEVEL_PRICE[5] =   5*1e6;
        
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
    function enter() public payable{
        require(now >= startTime,"Sale Not Started!");
        require(getHour(now) == 0 || getHour(now) == 12, "Not Exact Hour");
        require((getMinute(now) >= 0 && getMinute(now) < 5) || (getMinute(now) >= 15 && getMinute(now) < 20) || (getMinute(now) >= 30 && getMinute(now) < 35), "Not Exact Minute");

        uint defaultPrice = 20000*1e6;
        if(now >= levelTwoTime){
            defaultPrice = 100000*1e6;
        }
        if(msg.value == defaultPrice){
            applyPool();
        }
        else{
            revert("Invalid Amount!");
        }       
    }
    function applyPool() internal {
        uint userId = users[msg.sender].id;
        uint nowInning = 0;

        uint dateStr = getDate(now);
        if(getMinute(now) >= 0 && getMinute(now) < 5){
            nowInning = 1;
        }
        else if(getMinute(now) >= 15 && getMinute(now) < 20){
            nowInning = 2;
        }
        else if(getMinute(now) >= 30 && getMinute(now) < 35){
            nowInning = 3;
        }

        bool selected = false;
        if(poolSelected[msg.sender].isExist){
            selected = true;
        }

        bool applied = false;
        if(poolApplies[msg.sender].isExist){
            applied = true; 
        }

        require(applied == false, "You already applied for this timeindex");
        require(selected == false, "You are already selected for this timeindex");
        //////////////////////////////////////////////
        ApplyStruct memory applyStruct;
        currApplyUserID++;
        
        applyStruct = ApplyStruct({
            isExist:true,
            isSelected:false,
            id:currApplyUserID,
            userId:userId,
            inning:nowInning,
            standardTime:dateStr
        });

        poolApplies[msg.sender] = applyStruct;
        poolApplyUserList[currApplyUserID] = msg.sender;
        ///////////////////////////////////////////////
  
        emit regPoolEntry(msg.sender, dateStr, now);
    }
    //발사신청 끝//

    //발사선정 시작//
    function select() public payable {
        require(ownerWallet == msg.sender, "You don't have permission to select.");

        uint256 poolProductX = 0;
        while(poolProductX < productX){
            uint cannon1 = 0;
            uint cannon2 = 0;
            uint cannon3 = 0;
            uint cannon4 = 0;
            uint cannon5 = 0;
            uint cannoncount = 1;//poolActiveID;
            while(cannoncount <= 20){
                uint applyId = random(currApplyUserID);
                uint tankType = 0;
                uint priceX = 0;
                if(poolApplies[poolApplyUserList[applyId]].isExist == true){
                    if(poolApplies[poolApplyUserList[applyId]].isSelected == false){
                        poolApplies[poolApplyUserList[applyId]].isSelected = true;
                        if(cannon1 < 2){
                            tankType = 1;
                            priceX = tank1_price;
                            cannon1++;
                        }
                        else if(cannon2 < 5){
                            tankType = 2;
                            priceX = tank2_price;
                            cannon2++;
                        }
                        else if(cannon3 < 5){
                            tankType = 3;
                            priceX = tank3_price;
                            cannon3++;
                        }
                        else if(cannon4 < 5){
                            tankType = 4;
                            priceX = tank4_price;
                            cannon4++;
                        }
                        else if(cannon5 < 3){
                            tankType = 5;
                            priceX = tank5_price;
                            cannon5++;
                        }
                        SelectedStruct memory selectedStruct;
                        selectedStruct = SelectedStruct ({
                            isExist:true,
                            id:poolActiveID+cannoncount,
                            userId:poolApplies[poolApplyUserList[applyId]].userId,
                            applyId:applyId,
                            paymentReceived:0,
                            paymentRemaining:priceX*105/100,
                            tankType:tankType,
                            standardTime:poolApplies[poolApplyUserList[applyId]].standardTime,
                            inning:poolApplies[poolApplyUserList[applyId]].inning
                        });
                        poolSelectedUserList[poolActiveID+cannoncount] = poolApplyUserList[applyId];
                        poolSelected[poolApplyUserList[applyId]] = selectedStruct;
                        cannoncount++;
                    }
                }
                poolProductX = poolProductX + priceX;
            }
            poolActiveID = poolActiveID + 20;
        }
        productX = poolProductX * 110 / 100;
        clear();        
    }

    function clear() internal  {
        uint feeAmount = 0;
        for(uint p = 1 ; p <= currApplyUserID ; p++){
            bool sent = false;
            address tempAddress = poolApplyUserList[p];
            uint returnAmount = 20000*1e6;
            if(poolApplies[tempAddress].isSelected == true){
                uint tanktype = poolSelected[tempAddress].tankType;
                if(tanktype == 1){
                    returnAmount = returnAmount - 6000*1e6;
                    feeAmount = feeAmount + 6000 * 1e6;
                }
                else if(tanktype == 2){
                    returnAmount = returnAmount - 10000*1e6;
                    feeAmount = feeAmount + 10000 * 1e6;
                }
                else if(tanktype == 3){
                    returnAmount = returnAmount - 12000*1e6;
                    feeAmount = feeAmount + 12000 * 1e6;
                }
                else if(tanktype == 4){
                    returnAmount = returnAmount - 15000*1e6;
                    feeAmount = feeAmount + 15000 * 1e6;
                }
                else if(tanktype == 5){
                    returnAmount = returnAmount - 20000*1e6;
                    feeAmount = feeAmount + 20000 * 1e6;
                }   
                // distributeProductRefferal(tanktype, tempAddress);
            }
            sent = address(uint160(tempAddress)).send(returnAmount);
            if(sent){
                delete poolApplies[tempAddress];
            }
        }

        for(uint p = currApplyUserID ; p >= 1 ; p--){
            delete poolApplyUserList[p];
        }

        if(feeAmount > 0){
            bool sent = false;
            feeAmount = feeAmount * 2 / 100;
            uint feeAmount2 = feeAmount * 215 / 200;
            sent = address(uint160(ownerWallet2)).send(feeAmount2);
            sent = address(uint160(ownerWallet)).send(feeAmount);
        }
        currApplyUserID = 0;
    }

    function calculateProduct() public payable {
        require(ownerWallet == msg.sender, "You don't have permission to select.");

        uint minute = getMinute(now);
        uint hour = getHour(now);

        uint inning = 0;
        uint standardTime = 0;
        if(hour == 23){
            inning = 1;
            standardTime = getDate(now + 180 - 32400);
        }
        else if(hour == 0 && minute < 15){
            inning = 2;
            standardTime = getDate(now + 180 - 32400);
        }
        else if(hour == 0 && minute < 30){
            inning = 3;
            standardTime = getDate(now + 180 - 32400);
        }
        else if(hour == 8){
            inning = 1;
            standardTime = getDate(now + 180 - 32400);
        }
        else if(hour == 9 && minute < 15){
            inning = 2;
            standardTime = getDate(now + 180 - 32400);
        }
        else if(hour == 9 && minute < 30){
            inning = 3;
            standardTime = getDate(now + 180 - 32400);
        }
        if(inning > 0 && standardTime > 0){
            for(uint p = poolFinishID ; p < poolActiveID ; p++){
                if(poolSelected[poolSelectedUserList[p]].standardTime == standardTime && poolSelected[poolSelectedUserList[p]].inning == inning && poolSelected[poolSelectedUserList[p]].paymentRemaining > 0){
                    uint remain = poolSelected[poolSelectedUserList[p]].paymentRemaining;
                    address getter = poolSelectedUserList[p];

                    bool sent = false;
                    sent = address(uint160(getter)).send(remain);
                    if(sent){
                        poolSelected[poolSelectedUserList[p]].paymentRemaining = 0;
                        poolFinishID++;
                        distributeProductRefferal(poolSelected[poolSelectedUserList[p]].tankType, getter);
                    }
                }
            }
        }
    }

    function random(uint productCount) private view returns (uint8) {
       return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%productCount);
    }

    mapping(uint => uint256) public P_LEVEL_PRICE;
    /////////////////
    uint256 public productRefAmount = 0;
    ///////////////
     
    function distributeProductRefferal(uint product, address _selecter) internal{
        
        if(product==1){
            productRefAmount = 300 * 1e6;
        }
        else if(product==2){
            productRefAmount = 500 * 1e6;
        }
        else if(product==3){
            productRefAmount = 600 * 1e6;
        }
        else if(product==4){
            productRefAmount = 750 * 1e6;
        }
        else if(product==5){
            productRefAmount = 1000 * 1e6;
        }
        else{
            productRefAmount = 0;
        }
        P_LEVEL_PRICE[1] =  productRefAmount * 5/100;
        P_LEVEL_PRICE[2] =  productRefAmount * 3/100;
        P_LEVEL_PRICE[3] =  productRefAmount * 2/100;
        P_LEVEL_PRICE[4] =  productRefAmount * 1/100;
        P_LEVEL_PRICE[5] =  productRefAmount * 1/100;
        P_LEVEL_PRICE[6] =  productRefAmount * 1/100;
        P_LEVEL_PRICE[7] =  productRefAmount * 1/100;
        P_LEVEL_PRICE[8] =  productRefAmount * 1/100;
        P_LEVEL_PRICE[9] =  productRefAmount * 1/100;
        P_LEVEL_PRICE[10] = productRefAmount * 1/100;
        
        productReferral(1, _selecter);
    }
    
    
    function productReferral(uint _level, address _user) internal {
        address referer;
        referer = userList[users[_user].referrerID];
    
        bool sent = false;
        uint level_price_local=P_LEVEL_PRICE[_level];
        sent = address(uint160(referer)).send(level_price_local);
        if (sent) {
            emit getProRefBal(referer, _level, level_price_local,msg.sender);
            if(_level < 10 && users[referer].referrerID >= 1){
                productReferral(_level+1,referer);
            }
        }
     }
     ////////////////////////////////////////////
    
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
        return (uint(getYear(timestamp))*1e8) + (uint(getMonth(timestamp))*1e6) + (uint(getDay(timestamp))*1e4) + (uint(getHour(timestamp))*1e2);// + getMinute(timestamp);
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