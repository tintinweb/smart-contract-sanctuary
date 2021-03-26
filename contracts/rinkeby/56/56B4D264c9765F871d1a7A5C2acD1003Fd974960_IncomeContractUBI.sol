// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./IntercoinTrait.sol";

contract IncomeContract is OwnableUpgradeable, ReentrancyGuardUpgradeable, IntercoinTrait {
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    struct Restrict {
        uint256 amount;
        uint256 startTime;
        uint256 untilTime;
        bool gradual;
    }
    
    struct RestrictParam {
        uint256 amount;
        uint256 untilTime;
        bool gradual;
    }
    
    
    modifier recipientExists(address recipient) {
        require(recipients[recipient].exists == true, 'There are no such recipient');
        _;
    }
    
    modifier canManage(address recipient) {
        require(recipients[recipient].managers.contains(_msgSender()) == true, 'Can not manage such recipient');
        _;
    }
   
    struct Recipient {
        address addr;
        uint256 amountMax;
        uint256 amountPayed;
        uint256 amountAllowedByManager;
        Restrict[] restrictions;
        
        EnumerableSetUpgradeable.AddressSet managers;
        
        bool exists;
    }
    
    mapping(address => Recipient) recipients;
    address tokenAddr;
    
    function __IncomeContract_init(
        address token // can be address(0) = 0x0000000000000000000000000000000000000000   mean   ETH
    ) 
        public 
        initializer 
    {
        __Ownable_init();
        __ReentrancyGuard_init();
        
        tokenAddr = token;
    }
    
    receive() external payable {
        // payable fallback to receive and store ETH
    }
   
    ///////////////////////////////////////////////////
    //////////// owner section ////////////////////////
    /**
     * @param recipient recipient
     */
    function addRecipient(
        address recipient
    ) 
        public 
        onlyOwner 
    {
        if (recipients[recipient].exists == false) {
            recipients[recipient].exists = true;
            recipients[recipient].addr = recipient;
            recipients[recipient].amountMax = 0;
            recipients[recipient].amountPayed = 0;
            recipients[recipient].amountAllowedByManager = 0;
            
            
           // recipients[recipient].gradual = false;

        }
        
    }
    
    /**
     * Setup restrictions by owner
     * @param recipient recipient
     * @param restrictions restrictions
     * param amount amount
     * param untilTime untilTime in unixtimestamp
     * param gradual gradual
     */
    function setLockup(
        address recipient,
        RestrictParam[] memory restrictions
    ) 
        public 
        onlyOwner 
        recipientExists(recipient)
    {

        for (uint256 i = 0; i < restrictions.length; i++ ) {
            // add to amountMax
            recipients[recipient].amountMax = recipients[recipient].amountMax.add(restrictions[i].amount);
            
            // adding restriction
            require(restrictions[i].untilTime > block.timestamp, 'untilTime must be more than current time');
            recipients[recipient].restrictions.push(Restrict({
                amount: restrictions[i].amount,
                startTime: block.timestamp,
                untilTime: restrictions[i].untilTime,
                gradual: restrictions[i].gradual
            }));
            
        }
    }
    
    /** allow manager pay some funds to recipients
     * @param recipient recipient's address
     * @param manager manager's address
     */
    function addManager(
        address recipient, 
        address manager
    ) 
        public 
        onlyOwner 
    {
        recipients[recipient].managers.add(manager);
    }
    
    /** disallow manager pay some funds to recipients
     * @param recipient recipient's address
     * @param manager manager's address
     */
    function removeManager(
        address recipient, 
        address manager
    ) 
        public 
        onlyOwner 
    {
        recipients[recipient].managers.remove(manager);
    }
    
    ///////////////////////////////////////////////////
    //////////// managers section /////////////////////
    
    /**
     * @param recipient recipient's address
     * @param amount amount to pay 
     */
    function pay(
        address recipient, 
        uint256 amount
    ) 
        public 
        recipientExists(recipient)
        canManage(recipient)
    {
        
        (uint256 maximum, uint256 payed, uint256 locked, uint256 allowedByManager, ) = _viewLockup(recipient);
        
        uint256 availableUnlocked = maximum.sub(payed).sub(locked);
        
        require (amount > 0, 'Amount can not be a zero');

        require (amount <= availableUnlocked, 'Amount exceeds available unlocked balance');
        require (amount <= availableUnlocked.sub(allowedByManager), 'Amount exceeds available allowed balance by manager');
        
        recipients[recipient].amountAllowedByManager = recipients[recipient].amountAllowedByManager.add(amount);
        
    }
    
    ///////////////////////////////////////////////////
    //////////// recipients section ///////////////////

    function claim(
    ) 
        public 
        recipientExists(_msgSender())
        nonReentrant()
    {
        (,,, uint256 allowedByManager, ) = _viewLockup(_msgSender());
        // 40 20 0 10 => 40 30 0 0
        require (allowedByManager > 0, 'There are no avaialbe amount to claim');

        recipients[_msgSender()].amountAllowedByManager = 0;
        recipients[_msgSender()].amountPayed = recipients[_msgSender()].amountPayed.add(allowedByManager);
        bool success = _claim(_msgSender(), allowedByManager);

        require(success == true, 'There are no enough funds at contract');
        
    }
    
    
    
    /**
     * View restrictions setup by owner
     * @param recipient recipient
     * @return maximum maximum
     * @return payed payed
     * @return locked locked
     * @return allowedByManager allowedByManager
     * 
     */
    function viewLockup(
        address recipient
    ) 
        public 
        view
        returns (
            uint256 maximum,
            uint256 payed,
            uint256 locked,
            uint256 allowedByManager
        )
    {
        require(recipients[recipient].exists == true, 'There are no such recipient');
        (maximum, payed, locked,allowedByManager,) = _viewLockup(recipient);
    }
    
    
    /**
     * @param recipient recipient's address
     */
    function _claim(
        address recipient, 
        uint256 amount
    ) 
        internal 
        returns(
            bool success
        ) 
    {
        uint256 balance;
        if (tokenAddr == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20Upgradeable(tokenAddr).balanceOf(address(this));
        }
        if (balance < amount) {
            success = false;
        } else {
            if (tokenAddr == address(0)) {
                address payable addr = payable(recipient);
                success = addr.send(amount);
            } else {
                success = IERC20Upgradeable(tokenAddr).transfer(recipient, amount);
            }
        }
    }
    
    function _calcLock(
        Restrict[] memory restrictions
    ) 
        internal 
        view 
        returns(uint256 locked) 
    {
        locked = 0;
        uint256 fundsPerSecond;
        for (uint256 i = 0; i < restrictions.length; i++ ) {
            if (restrictions[i].untilTime > block.timestamp) {
                if (restrictions[i].gradual == true) {
                    fundsPerSecond = restrictions[i].amount.div(restrictions[i].untilTime.sub(restrictions[i].startTime));
                    locked = locked.add(
                        fundsPerSecond.mul(restrictions[i].untilTime.sub(block.timestamp))
                    );
                    
                } else {
                    locked = locked.add(restrictions[i].amount);
                
                }
            }
        }
    
    }
    
    /**
     * @param recipient recipient's address
     */
    function _viewLockup(
        address recipient
    ) 
        internal 
        view
        returns (
            uint256 maximum,
            uint256 payed,
            uint256 locked,
            uint256 allowedByManager,
            Restrict[] memory restrictions
        )
    {
        
        maximum = recipients[recipient].amountMax;
        payed = recipients[recipient].amountPayed;
        locked = _calcLock(recipients[recipient].restrictions);
        allowedByManager = recipients[recipient].amountAllowedByManager;
        restrictions = recipients[recipient].restrictions;
        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./lib/DateTime.sol";

import "./interfaces/IUBI.sol";
import "./interfaces/ICommunity.sol";

import "./IncomeContract.sol";

contract IncomeContractUBI is IUBI, IncomeContract {
    
    ICommunity private communityAddress;
    string private communityRole;
    string private communityUBIRole;
    
    uint256 constant sampleSize = 10;
    uint256 constant multiplier = 1e6;
    
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using DateTime for uint256;
    
    uint256 private startDateIndex;
    
    
    uint256 private tagsIndex = 1;
    mapping (bytes32 => uint256) internal _tags;
    mapping (uint256 => bytes32) internal _tagsIndices;
    
    
    struct RatioStruct {
        int256 count;
        int256 total;
        int256 average;
        //int256 median;
        //int256 variance;
        int256 prevRatio;
        bool alreadyInit;
    }
    
    mapping(bytes32 => RatioStruct) ratiosData;
    
    //      tagname            dayTs       price
    mapping(bytes32 => mapping(uint256 => uint256)) avgPrices;
        
    //      dayTs       ubi
    mapping(uint256 => uint256) UBIValues;
    
    struct UBIStruct {
        uint256 lastIndex;
        uint256 payed;
        uint256 total;
        uint256 prevUBI;
        bool exists;
    }
    mapping(address => UBIStruct) users;
    
    modifier canRecord() {
        bool s = _canRecord(communityRole);
        
        require(s == true, "Sender has not in accessible List");
        _;
    }
    modifier canObtainUBI() {
        bool s = _canRecord(communityUBIRole);
        
        require(s == true, "Sender has not in accessible List");
        _;
    }
   
    /**
     * @param token  token address of eth
     * @param community address of community contract
     * @param roleName role of contracts who can send stats of prices and ratios
     * @param ubiRoleName role of EOA which can obtain ubi
     */
    function __IncomeContractUBI_init(
        address token, // can be address(0) = 0x0000000000000000000000000000000000000000   mean   ETH
        ICommunity community,
        string memory roleName,
        string memory ubiRoleName
    )  
        public 
        initializer 
    {
        __IncomeContract_init(token);

        communityAddress = community;
        communityRole = roleName;
        communityUBIRole = ubiRoleName;
        
        startDateIndex = getCurrentDateIndex();
    }
    
    function getRatioMultiplier() public pure returns(uint256) {
        return multiplier;
    }
    // calling by voting
    function setRatio(
        bytes32 tag, 
        uint256 ratio
    ) 
        canRecord() 
        external 
        override 
    {
        createTag(tag);
        _record(tag,int256(ratio));
        
        uint256 dateIndex = getCurrentDateIndex();
        
        setUBI(dateIndex);
        
    }
    
    function setRatio(
        bytes32[] calldata tags, 
        uint256[] calldata ratios
    ) 
        canRecord() 
        external 
        override 
    {
        uint256 dateIndex = getCurrentDateIndex();
        for (uint256 i=0; i<tags.length; i++) {
            createTag(tags[i]);
            _record(tags[i],int256(ratios[i]));
        }
        setUBI(dateIndex);
    }
    
    // calling by Prices
    function setAvgPrice(
        bytes32 tag, 
        uint256 price
    ) 
        canRecord() 
        external 
        override 
    {
        uint256 dateIndex = getCurrentDateIndex();
        createTag(tag);
        avgPrices[tag][dateIndex] = price;
        
        setUBI(dateIndex);
        
    }
    function setAvgPrice(
        bytes32[] calldata tags, 
        uint256[] calldata prices
    ) 
        canRecord() 
        external 
        override 
    {
        uint256 dateIndex = getCurrentDateIndex();
        for (uint256 i=0; i<tags.length; i++) {
            createTag(tags[i]);
            avgPrices[tags[i]][dateIndex] = prices[i];
        }
        setUBI(dateIndex);
    }

    function checkUBI(
    ) 
        public 
        view
        override 
        returns(uint256 ubi) 
    {
        uint256 lastIndex = users[msg.sender].lastIndex;
        uint256 payed = users[msg.sender].payed;
        uint256 total = users[msg.sender].total;
        uint256 prevUBI = users[msg.sender].prevUBI;
        
        if (users[msg.sender].exists == false) {
            lastIndex = startDateIndex;
        }
       
        uint256 untilIndex = getCurrentDateIndex(); //.add(DAY_IN_SECONDS);
        for (uint256 i=lastIndex; i<untilIndex; i=i+DateTime.DAY_IN_SECONDS) {
            if (UBIValues[i] == 0) {
            } else {
               prevUBI = UBIValues[i];
            }
            total = total.add(prevUBI);
            lastIndex = i.add(DateTime.DAY_IN_SECONDS);
            
        }
        ubi =  (total.sub(payed)).div(multiplier);

    }
    
    function claimUBI(
    ) 
        public 
        override 
        canObtainUBI()
    {
        _actualizeUBI();
        uint256 toPay = users[msg.sender].total.sub(users[msg.sender].payed);
        require(toPay.div(multiplier) > 0, 'Amount exceeds balance available to claim');
        users[msg.sender].payed = users[msg.sender].payed.add(toPay);
        bool success = _claim(msg.sender, toPay.div(multiplier));
        require(success == true, 'There are no enough funds at contract');
        
    }
    
    function _actualizeUBI(
    ) 
        internal 
        
        returns(uint256 ubi) 
    {
        if (users[msg.sender].exists == false) {
            users[msg.sender].lastIndex = startDateIndex;
            users[msg.sender].payed = 0;
            users[msg.sender].total = 0;
            users[msg.sender].prevUBI = 0;
            users[msg.sender].exists = true;
        }
        
        uint256 untilIndex = getCurrentDateIndex(); //.add(DAY_IN_SECONDS);
        for (uint256 i=users[msg.sender].lastIndex; i<untilIndex; i=i+DateTime.DAY_IN_SECONDS) {
            if (UBIValues[i] == 0) {
            } else {
                users[msg.sender].prevUBI = UBIValues[i];
            }
            users[msg.sender].total = users[msg.sender].total.add(users[msg.sender].prevUBI);
            users[msg.sender].lastIndex = i.add(DateTime.DAY_IN_SECONDS);
            
        }
        ubi =  (users[msg.sender].total.sub(users[msg.sender].payed)).div(multiplier);

    }
    
    function _canRecord(string memory roleName) private view returns(bool s){
        s = false;
        string[] memory roles = ICommunity(communityAddress).getRoles(msg.sender);
        for (uint256 i=0; i< roles.length; i++) {
            
            if (keccak256(abi.encodePacked(roleName)) == keccak256(abi.encodePacked(roles[i]))) {
                s = true;
            }
        }
    }
    
    function setUBI(
        uint256 dateIndex
    ) 
        private
    {
        // UBI = SUM over all tags of ( avgPrice[day] * avgFractionFromVote )
        
        uint256 ubi;
        for (uint256 i=0; i< tagsIndex; i++) {
            ubi = ubi.add(
                multiplier.mul(
                    uint256(ratiosData[_tagsIndices[i]].average).mul(avgPrices[_tagsIndices[i]][dateIndex]).div(multiplier)
                ).div(multiplier)
            );
            
        }
        UBIValues[dateIndex] = ubi;
    }
    
    function getCurrentDateIndex(
    ) 
        internal 
        view 
        returns(uint256 dateIndex) 
    {
        uint256 y = (block.timestamp).getYear();
        uint256 m = (block.timestamp).getMonth();
        uint256 d = (block.timestamp).getDay();
        dateIndex = (uint256(y)).toTimestamp(uint256(m),uint256(d));
    }
    
    function _record(
        bytes32 tagBytes32, 
        int256 ratio
    ) 
        private 
    {
        ratio = ratio.mul(int256(multiplier));
        
        ratiosData[tagBytes32].total = ratiosData[tagBytes32].total.add(ratio);
        
        if (ratiosData[tagBytes32].alreadyInit == false) {
            ratiosData[tagBytes32].alreadyInit = true;
            ratiosData[tagBytes32].count = 1;
            ratiosData[tagBytes32].average = ratio;
            ratiosData[tagBytes32].prevRatio = ratio;
        } else {
            ratiosData[tagBytes32].count = ratiosData[tagBytes32].count.add(1);
            //int256 oldAverage = ratiosData[tagBytes32].average;
            
            // https://stackoverflow.com/questions/10930732/c-efficiently-calculating-a-running-median/15150143#15150143
            // for each sample
            // average += ( sample - average ) * 0.1f; // rough running average.
            // median += _copysign( average * 0.01, sample - median );
            // but "0.1f" replace to "sampleSize"
            ratiosData[tagBytes32].average = ratiosData[tagBytes32].average.add(
                (
                    (
                        (int256(ratio)).sub(ratiosData[tagBytes32].average)
                    ).div(int256(sampleSize))
                )
            );
            
            ratiosData[tagBytes32].prevRatio = ratio;
            
            
        }
        
    }
    
    function createTag(bytes32 tag) private {
        if (_tags[tag] == 0) {
            _tags[tag] = tagsIndex;
            _tagsIndices[tagsIndex] = tag;
            tagsIndex = tagsIndex.add(1);
        }
       
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IIntercoin.sol";
import "./interfaces/IIntercoinTrait.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract IntercoinTrait is Initializable, IIntercoinTrait {
    
    address private intercoinAddr;
    bool private isSetup;

    /**
     * setup intercoin contract's address. happens once while initialization through factory
     * @param addr address of intercoin contract
     */
    function setIntercoinAddress(address addr) public override returns(bool) {
        require (addr != address(0), 'Address can not be empty');
        require (isSetup == false, 'Already setup');
        intercoinAddr = addr;
        isSetup = true;
        
        return true;
    }
    
    /**
     * got stored intercoin address
     */
    function getIntercoinAddress() public override view returns (address) {
        return intercoinAddr;
    }
    
    /**
     * @param addr address of contract that need to be checked at intercoin contract
     */
    function checkInstance(address addr) internal view returns(bool) {
        require (intercoinAddr != address(0), 'Intercoin address need to be setup before');
        return IIntercoin(intercoinAddr).checkInstance(addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ICommunity {
    function memberCount(string calldata role) external view returns(uint256);
    function getRoles(address member)external view returns(string[] memory);
    function getMember(string calldata role) external view returns(address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IIntercoin {
    
    function registerInstance(address addr) external returns(bool);
    function checkInstance(address addr) external view returns(bool);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIntercoinTrait {
    
    function setIntercoinAddress(address addr) external returns(bool);
    function getIntercoinAddress() external view returns (address);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IUBI {
    function setRatio(bytes32 tag, uint256 ratio) external;
    function setRatio(bytes32[] calldata tags, uint256[] calldata ratios) external;
    function setAvgPrice(bytes32 tag, uint256 price) external;
    function setAvgPrice(bytes32[] calldata tags, uint256[] calldata prices) external;
    
    function checkUBI() external view returns(uint256);
    function claimUBI() external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

library DateTime {
       
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint256 year;
                uint256 month;
                uint256 day;
                uint256 hour;
                uint256 minute;
                uint256 second;
                uint256 weekday;
        }

        uint256 constant DAY_IN_SECONDS = 86400;
        uint256 constant YEAR_IN_SECONDS = 31536000;
        uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint256 constant HOUR_IN_SECONDS = 3600;
        uint256 constant MINUTE_IN_SECONDS = 60;

        uint256 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint256 year) internal pure returns (bool) {
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

        function leapYearsBefore(uint256 year) internal pure returns (uint256) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint256 month, uint256 year) internal pure returns (uint256) {
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

        function parseTimestamp(uint256 timestamp) internal pure returns (_DateTime memory dt) {
                uint256 secondsAccountedFor = 0;
                uint256 buf;
                uint256 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint256 secondsInMonth;
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

        function getYear(uint256 timestamp) internal pure returns (uint256) {
                uint256 secondsAccountedFor = 0;
                uint256 year;
                uint256 numLeapYears;

                // Year
                year = uint256(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint256(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint256 timestamp) internal pure returns (uint256) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint256 timestamp) internal pure returns (uint256) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint256 timestamp) internal pure returns (uint256) {
                return uint256((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint256 timestamp) internal pure returns (uint256) {
                return uint256((timestamp / 60) % 60);
        }

        function getSecond(uint256 timestamp) internal pure returns (uint256) {
                return uint256(timestamp % 60);
        }

        function getWeekday(uint256 timestamp) internal pure returns (uint256) {
                return uint256((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint256 year, uint256 month, uint256 day, uint256 hour) internal pure returns (uint256 timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute) internal pure returns (uint256 timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) internal pure returns (uint256 timestamp) {
                uint256 i;

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
                uint256[12] memory monthDayCounts;
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMathUpgradeable {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}