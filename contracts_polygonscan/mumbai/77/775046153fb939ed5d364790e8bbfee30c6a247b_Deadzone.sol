/**
 *Submitted for verification at polygonscan.com on 2021-12-17
*/

// File: contracts/IBits.sol



pragma solidity ^0.8.0;

interface IBits {
    // Mint and burn functionality, only to be called by the contracts (factory AND gameplay)
    // factory will BURN when healing a sentry (from infected to not)
    // Gameplay will MINT when paying out
    function mint(address reciever, uint amount) external;
    function burn(address from, uint amount) external;

    // Essentially a renaming of balanceOf
    function getBitsBalance(address _address) external view returns (uint);
}
// File: contracts/IStructs.sol



pragma solidity ^0.8.0;

interface IStructs {
    struct Sentry {
        uint16 id; 
        // 0=Human, 1=cyborg, 2=alien
        uint8 species;
        uint dna; 
        uint8 attack;
        uint8 defense; 
        uint8 luck;
        bool infected;

    }


    struct GameplayStats {
      uint16 sentryId;
      bool isDeployed;
      uint8 riskCode;
      uint cooldownTimestamp;
      uint16 daysSurvived;
      uint16 longestStreak;
      uint deploymentTimestamp;
      uint16 successfulAttacks;
      uint16 successfulDefends;
    }


    struct DeploymentParty {
        uint id;
        uint16[] listOfIds;
        address leaderAddress;
        bool isDeployed;
    }
}
// File: contracts/ISentryFactory.sol



pragma solidity ^0.8.0;


interface ISentryFactory is IStructs  {
    // Interface used by gameplay contract
    // Need to get traits for gameplay RNG
    // Need owner to return $BITS upond evac
    
    // get owner address of a sentry
    function ownerOf(uint16 tokenId) external view returns (address);

    // retrieve sentry traits for gameplay
    function getSentryTraits(uint16 tokenId) external view returns (Sentry memory);
    // get number of sentries byy owner
    // ensures an address actually owns a token
    function balanceOf(address owner) external view returns (uint);


    // Infect sentry
    // Called by gameplay
    function infectSentry(uint16 tokenId) external;
}
// File: contracts/IDeploymentParty.sol



pragma solidity ^0.8.0;


interface IDeploymentParty is IStructs {
    function evacuation(uint16 sentryId, uint partyId, bool attack) external;
    function deployParty(uint partyId) external;
    function getListOfDeployedParties() external view returns(DeploymentParty[] memory);
    function getSentryPartyId(uint16 sentryId) external view returns(uint);
    function randomPartyMemberFromId(uint16 sentryId) external returns (uint16);

    function checkAndTransferPartyOwnership(uint16 sentryId, address checkAddress, address to) external;
    function setNewSentryParty(uint16 sentryId) external;

    function leavePartyAfterAttack(uint16 sentryId) external;
}
// File: contracts/DateTime.sol


pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------

// Credit given above
// renamed for simplicity

library DateTime {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        uint year;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        uint year;
        uint month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Deadzone.sol


pragma solidity ^0.8.0;







contract Deadzone is Ownable, IStructs {
    using DateTime for uint;

///*EVENTS*
    event StatsUpdated(uint16 sentryId);
    event Deployment(uint16 sentryId, uint timestamp);
// *VARS*
    uint randNonce = 1;
    //0=city 1=forrest 2=caves
    uint8 public currentEnvironment;
    uint public totalDeployedSentries;
    uint16 maxYield = 10000;
    uint16 dailyBitRate = 500;


    //array of stats needed for iteration upon battle call
    GameplayStats[] public allStats;

// *CONTRACT_REFERNCES*
    ISentryFactory public factory;
    IDeploymentParty public party;
    IBits public bits;

///*MAPPINGS*
    mapping(uint16 => GameplayStats) public idToStats;
    mapping(address => bool) public controllers;

    // these maps are set up so that the currentEnvironment will match with the species respective stats
    mapping(uint8 => uint8[]) public battleMultipliers;
    mapping(uint8 => uint8[]) public luckMultipliers;

    // 0 = cyborg/city, 1=human/forrest, 2=alien/caves
    constructor() {
        currentEnvironment = 0;
        totalDeployedSentries = 0;
        battleMultipliers[0] = [120,80,100]; 
        luckMultipliers[0] =   [80,120,100]; 

        battleMultipliers[1] = [100,120,80]; 
        luckMultipliers[1] =   [100,80,120]; 

        battleMultipliers[2] = [80,100,120]; 
        luckMultipliers[2] =   [120,100,80]; 
    }



///*MODIFIER*
    modifier onlyController() {
        require(controllers[msg.sender], "You cannot access this functionality!");
        _;
    }
    modifier onlyTokenOwner(uint16 sentryId) {
        require(factory.ownerOf(sentryId) == msg.sender, "You do not own this sentry!");
        _;
    }
    modifier validInfectedSentry(uint16 sentryId) {
        require(factory.getSentryTraits(sentryId).infected, "This Sentry is not infected!");
        require(idToStats[sentryId].cooldownTimestamp < block.timestamp, "Sentry cooldown has not ended!");
        _;
    }

///*FUNCTIONS*
    // risky biz
    function soloDeploy(uint16 sentryId, uint8 riskCode) external onlyTokenOwner(sentryId) {
        require(party.getSentryPartyId(sentryId) == 0, "You cannot solo deploy while in a party!");
        require(!factory.getSentryTraits(sentryId).infected, "Infected Sentries cannot deploy!");
        deployOrEvacHandler(sentryId, riskCode, true);

        emit Deployment(sentryId, block.timestamp);
    }
    function soloEvac(uint16 sentryId) external onlyTokenOwner(sentryId) {
        require(idToStats[sentryId].isDeployed, "This Sentry is not currently deployed!");
        deployOrEvacHandler(sentryId, 0, false);

        uint daysSurvived =  idToStats[sentryId].deploymentTimestamp.diffDays(block.timestamp);
        uint payout = daysSurvived*dailyBitRate;

        if(rng(100) < factory.getSentryTraits(sentryId).luck && !deadzoneActive()) {
            payout = payout/2;
        }
        bits.mint(msg.sender, payout);
    }

    function attack(uint16 sentryId) external onlyTokenOwner(sentryId) validInfectedSentry(sentryId) {
        require(deadzoneActive(), "The deadzone is not active. You cannot attack until it activates.");
        GameplayStats[] memory allDeployed = getDeployedSentries();
        GameplayStats memory target = allStats[rng(allDeployed.length)];
        if(party.getSentryPartyId(target.sentryId) != 0) {
            // get target from deployment party
            target = idToStats[party.randomPartyMemberFromId(target.sentryId)];
        }
        bool successfulAttack = battle(sentryId, target.sentryId);
        if(successfulAttack) {
        // zombie is rewarded, sentry is penalized
            party.leavePartyAfterAttack(target.sentryId);
            if(target.riskCode == 2) {
                factory.infectSentry(target.sentryId);
            }
            uint16 daysSurvived = uint16(target.deploymentTimestamp.diffDays(block.timestamp));
            deployOrEvacHandler(sentryId, 0, false);
            idToStats[sentryId].successfulAttacks++;
            allStats[getStatsIndex(sentryId)].successfulAttacks++;


        } else {
            //infected loses
            allStats[getStatsIndex(sentryId)].deploymentTimestamp = block.timestamp;
            idToStats[sentryId].deploymentTimestamp = block.timestamp;
            if(idToStats[sentryId].riskCode == 2) {
                idToStats[sentryId].cooldownTimestamp = block.timestamp.addDays(3);
                allStats[getStatsIndex(sentryId)].cooldownTimestamp = block.timestamp.addDays(3);
            } else {
                idToStats[sentryId].cooldownTimestamp = block.timestamp.addDays(1);
                allStats[getStatsIndex(sentryId)].cooldownTimestamp = block.timestamp.addDays(1);
            }
            target.successfulDefends++;
        }
    }

///*HELPERS*
    function getStatsIndex(uint16 sentryId) private view returns(uint) {
        for(uint i = 0; i< allStats.length; i++) {
            if(allStats[i].sentryId == sentryId) {
                return i;
            }
        }
    }

    function deployOrEvacHandler(uint16 sentryId,uint8 riskCode ,bool deploy) private {
        if(riskCode == 0) {
            riskCode= idToStats[sentryId].riskCode;
        }
        uint index = getStatsIndex(sentryId);
        if(deploy) {
            idToStats[sentryId].isDeployed = true;
            idToStats[sentryId].riskCode = riskCode;
            allStats[index].isDeployed = true;
            allStats[index].riskCode = riskCode;
        } else {
            uint16 daysSurvived = uint16(idToStats[sentryId].deploymentTimestamp.diffDays(block.timestamp));
            if(daysSurvived > idToStats[sentryId].longestStreak) {
                idToStats[sentryId].longestStreak = daysSurvived;
            }
            idToStats[sentryId].daysSurvived +=daysSurvived;
            idToStats[sentryId].isDeployed = false;
            allStats[index].isDeployed = false;
        }
            idToStats[sentryId].deploymentTimestamp = block.timestamp;
    }

    function determinePayout(uint16 daysPayable) private view returns (uint) {
        uint amt=  daysPayable * dailyBitRate;
        if(amt > maxYield) {
            return maxYield;
        }
        return amt;
    }

    function getDeployedSentries() private view returns(GameplayStats[] memory) {
        GameplayStats[] memory deployed;
        for(uint i = 0; i< allStats.length; i++) {
            if(allStats[i].isDeployed) {
                deployed[i] = allStats[i];
            }
        }
        return deployed;
    }

    function battle(uint16 attackerId, uint16 defenderId) private returns(bool) {
        // bool return refers to if the ATTACKER won
        Sentry memory attacker = factory.getSentryTraits(attackerId);
        Sentry memory defender = factory.getSentryTraits(defenderId);
        uint8 attackStat = (attacker.attack*battleMultipliers[attacker.species][currentEnvironment])/100;
        uint8 defendStat = (defender.defense*battleMultipliers[defender.species][currentEnvironment])/100;
        return rng(100) < (attackStat / (attackStat+defendStat))*100;
    }
    function rng(uint max) private returns (uint) {
        // Eventual replacement will be chainlink vrf
           randNonce++; 
            return uint(keccak256(abi.encodePacked(block.timestamp,
                                          msg.sender,
                                          randNonce))) %
                                          max;
    }
    function deadzoneActive() public view returns(bool) {
        return block.timestamp.getDayOfWeek() < 6;
    }

///*PUBLIC*

///*INTERFACE*
    function getStatsFromId(uint16 id) public view returns(GameplayStats memory) {
        return idToStats[id];
    }

    // This interface is to be used by the deployment party contract
    function deploy(uint16 sentryId) public onlyController {
        require(!factory.getSentryTraits(sentryId).infected, "Infected Sentries cannot deploy!");
        deployOrEvacHandler(sentryId, 0, true);
    }
    // This interface is to be used by the deployment party contract
    function evac(uint16 sentryId) public onlyController {
        deployOrEvacHandler(sentryId, 0, false);
    }

    // will be called when a sentry is created;
    function createGameplayStats(uint16 sentryId) public onlyController {
        GameplayStats memory stats = GameplayStats(sentryId, false, 0, block.timestamp,0,0,block.timestamp, 0,0);
        idToStats[sentryId] = stats;
        allStats.push(stats);
    }

    // This is strictly going to be used for immediate-dpeloy parties
    // Ownership is checked in deploymentparty contract
    // WIll be used internally AND as interface
    function sentryListDeploy(uint16[] memory sentryId) external onlyController {
        for(uint i = 0; i < sentryId.length; i++) {
            require(!factory.getSentryTraits(sentryId[i]).infected, "Infected Sentries cannot be deployed!");
            if(!idToStats[sentryId[i]].isDeployed) {
                sentryStatUpdateOnDeploy(sentryId[i]);
            }
            totalDeployedSentries++;
        }
    }
    function sentryStatUpdateOnDeploy(uint16 sentryId) internal {
        idToStats[sentryId].isDeployed = true;
        idToStats[sentryId].deploymentTimestamp = block.timestamp;
    }
    function editRiskCode(uint16 sentryId ,uint8 newCode) external onlyTokenOwner(sentryId) {
        idToStats[sentryId].riskCode = newCode;
        emit StatsUpdated(sentryId);
    }

///*OWNER*
    //Contract Setters
    function setFactory(address _address) public onlyOwner {
        factory = ISentryFactory(_address);
    }
    function setBits(address _address) public onlyOwner {
        bits = IBits(_address);
    }
    function setParty(address _address) public onlyOwner {
        party = IDeploymentParty(_address);
    }
    function addController(address _address) public onlyOwner {
        controllers[_address] = true;
    }
    function removeController(address _address) public onlyOwner {
        controllers[_address] = false;
    }
    function setCurrentEnvironment(uint8 code) public onlyOwner {
        currentEnvironment = code;
    }
    function setMaxYield(uint16 newMax) public onlyOwner {
        maxYield = newMax;
    }
    function setDaily(uint16 newDaily) public onlyOwner {
        dailyBitRate = newDaily;
    }
    function setNonce(uint nonce) public onlyOwner {
        randNonce = nonce;
    }
    function setBattleMultiplier(uint8 ind,uint8[] memory newSet) public onlyOwner {
        battleMultipliers[ind] = newSet;
    }
    function setLuckMultiplier(uint8 ind,uint8[] memory newSet) public onlyOwner {
        luckMultipliers[ind] = newSet;
    }
}