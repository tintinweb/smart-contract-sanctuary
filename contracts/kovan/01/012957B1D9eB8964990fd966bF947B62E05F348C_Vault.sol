pragma solidity ^0.7.5;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
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
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

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
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
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

pragma solidity 0.7.6;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./vaults/StakingData.sol";

contract ITrustVaultFactory is Initializable {
  
  address[] internal _VaultProxies;
  mapping (address => bool) internal _AdminList;
  mapping (address => bool) internal _TrustedSigners;
  mapping(address => bool) internal _VaultStatus;
  address internal _roundDataImplementationAddress;
  address internal _stakeDataImplementationAddress;
  address internal _stakingDataAddress;
  address internal _burnAddress;
  address internal _governanceDistributionAddress;
  address internal _governanceTokenAddress;
  address internal _stakingCalculationAddress;

  function initialize(
      address admin, 
      address trustedSigner, 
      address roundDataImplementationAddress, 
      address stakeDataImplementationAddress, 
      address governanceTokenAddress,
      address stakingCalculationAddress
    ) initializer external {
    require(admin != address(0));
    _AdminList[admin] = true;
    _AdminList[msg.sender] = true;
    _TrustedSigners[trustedSigner] = true;
    _roundDataImplementationAddress = roundDataImplementationAddress;
    _stakeDataImplementationAddress = stakeDataImplementationAddress;
    _governanceTokenAddress = governanceTokenAddress;
    _stakingCalculationAddress = stakingCalculationAddress;
  }

  modifier onlyAdmin() {
    require(_AdminList[msg.sender] == true, "Not Factory Admin");
    _;
  }

  function createVault(
    address contractAddress, 
    bytes memory data
  ) external onlyAdmin {
    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(contractAddress, msg.sender, data );
    require(address(proxy) != address(0));
    _VaultProxies.push(address(proxy));
    _VaultStatus[address(proxy)] = true;
    StakingData stakingDataContract = StakingData(_stakingDataAddress);
    stakingDataContract.addVault(address(proxy));
  }

  function getVaultaddresses() external view returns (address[] memory vaults, bool[] memory status) {

    vaults = _VaultProxies;
    status = new bool[](vaults.length);

    for(uint i = 0; i < vaults.length; i++){
      status[i] = _VaultStatus[vaults[i]];
    }

    return (vaults, status);
  }

  function pauseVault(address vaultAddress) external onlyAdmin {
    _VaultStatus[vaultAddress] = false;
  }

  function unPauseVault(address vaultAddress) external onlyAdmin {
    _VaultStatus[vaultAddress] = true;
  }

  function addAdminAddress(address newAddress) external onlyAdmin {
      require(_AdminList[newAddress] == false, "Already Admin");
      _AdminList[newAddress] = true;
  }

  /**
    * @dev revoke admin
    */
  function revokeAdminAddress(address newAddress) external onlyAdmin {
      require(msg.sender != newAddress);
      _AdminList[newAddress] = false;
  }

  function addTrustedSigner(address newAddress) external onlyAdmin{
      require(_TrustedSigners[newAddress] == false);
      _TrustedSigners[newAddress] = true;
  }

  function isTrustedSignerAddress(address account) external view returns (bool) {
      return _TrustedSigners[account] == true;
  }

  function updateRoundDataImplementationAddress(address newAddress) external onlyAdmin {
      _roundDataImplementationAddress = newAddress;
  }

  function getRoundDataImplementationAddress() external view returns(address){
      return _roundDataImplementationAddress;
  }

  function updateStakeDataImplementationAddress(address newAddress) external onlyAdmin {
      _stakeDataImplementationAddress = newAddress;
  }

  function getStakeDataImplementationAddress() external view returns(address){
      return _stakeDataImplementationAddress;
  }

  function updateStakingDataAddress(address newAddress) external onlyAdmin {
      _stakingDataAddress = newAddress;
  }

  function getStakingDataAddress() external view returns(address){
      return _stakingDataAddress;
  }

  function isStakingDataAddress(address addressToCheck) external view returns (bool) {
      return _stakingDataAddress == addressToCheck;
  }

  function updateBurnAddress(address newAddress) external onlyAdmin {
      _burnAddress = newAddress;
  }

  function getBurnAddress() external view returns(address){
      return _burnAddress;
  }

  function isBurnAddress(address addressToCheck) external view returns (bool) {
      return _burnAddress == addressToCheck;
  }

  function updateGovernanceDistributionAddress(address newAddress) external onlyAdmin {
      _governanceDistributionAddress = newAddress;
  }

  function getGovernanceDistributionAddress() external view returns(address){
      return _governanceDistributionAddress;
  }

  function updateGovernanceTokenAddress(address newAddress) external onlyAdmin {
      _governanceTokenAddress = newAddress;
  }

  function getGovernanceTokenAddress() external view returns(address){
      return _governanceTokenAddress;
  }

  function updateStakingCalculationsAddress(address newAddress) external onlyAdmin {
      _stakingCalculationAddress = newAddress;
  }

  function getStakingCalculationsAddress() external view returns(address){
      return _stakingCalculationAddress;
  }

  /**
    * @dev revoke admin
    */
  function revokeTrustedSigner(address newAddress) external onlyAdmin {
      require(msg.sender != newAddress);
      _TrustedSigners[newAddress] = false;
  }

  function isAdmin() external view returns (bool) {
      return isAddressAdmin(msg.sender);
  }

  function isAddressAdmin(address account) public view returns (bool) {
      return _AdminList[account] == true;
  }

  function isActiveVault(address vaultAddress) external view returns (bool) {
    return _VaultStatus[vaultAddress] == true;
  }   
}

pragma solidity 0.7.6;
pragma abicoder v2;
import "@openzeppelin/contracts/math/SafeMath.sol";

library ITrustVaultLib {
    using SafeMath for uint;

    struct RewardTokenRoundData{
        address tokenAddress;
        uint amount;
        uint commissionAmount;
        uint tokenPerBlock; 
        uint totalSupply;
        bool ignoreUnstakes;
    }

    struct RewardTokenRound{
        mapping(address => RewardTokenRoundData) roundData;
        uint startBlock;
        uint endBlock;
    }

    struct AccountStaking {
        uint32 startRound;
        uint endDate;
        uint total;
        Staking[] stakes;
    }

    struct Staking {
        uint startTime;
        uint startBlock;
        uint amount;
        uint total;
    }

    struct UnStaking {
        address account; 
        uint amount;
        uint startDateTime;   
        uint startBlock;     
        uint endBlock;    
    }

    struct ClaimedReward {
        uint amount;
        uint lastClaimedRound;
    }

    function divider(uint numerator, uint denominator, uint precision) internal pure returns(uint) {        
        return numerator*(uint(10)**uint(precision))/denominator;
    }

    function getUnstakingsForBlockRange(
        UnStaking[] memory unStakes, 
        uint startBlock, 
        uint endBlock) internal pure returns (uint){
         // If we have bad data, no supply data or it starts after the block we are looking for then we can return zero
        if(endBlock < startBlock 
            || unStakes.length == 0 
            || unStakes[0].startBlock > endBlock)
        {         
            return 0;
        }

        uint lastIndex = unStakes.length - 1;
        uint diff = 0;
        uint stakeEnd;
        uint stakeStart;

        uint total;
        diff = 0;
        stakeEnd = 0; 
        stakeStart = 0;
        //last index should now be in our range so loop through until all block numbers are covered
      
        while(lastIndex >= 0) {  

            if( (unStakes[lastIndex].endBlock != 0 && unStakes[lastIndex].endBlock < startBlock)
                || unStakes[lastIndex].startBlock > endBlock) {
                if(lastIndex == 0){
                    break;
                } 
                lastIndex = lastIndex.sub(1);
                continue;
            }
            
            stakeEnd = unStakes[lastIndex].endBlock == 0 
                ? endBlock : unStakes[lastIndex].endBlock;

            stakeEnd = (stakeEnd >= endBlock ? endBlock : stakeEnd);

            stakeStart = unStakes[lastIndex].startBlock < startBlock 
                ? startBlock : unStakes[lastIndex].startBlock;
            
            diff = (stakeEnd == stakeStart ? 1 : stakeEnd.sub(stakeStart));

            total = total.add(unStakes[lastIndex].amount.mul(diff));

            if(lastIndex == 0){
                break;
            } 

            lastIndex = lastIndex.sub(1); 
        }
 
        return total;
    }

function getHoldingsForBlockRange(
        Staking[] memory stakes,
        uint startBlock, 
        uint endBlock) internal pure returns (uint){
        
        // If we have bad data, no supply data or it starts after the block we are looking for then we can return zero
        if(endBlock < startBlock 
            || stakes.length == 0 
            || stakes[0].startBlock > endBlock){
            return 0;
        }
        uint lastIndex = stakes.length - 1;
    
        uint diff;
        // If the last total supply is before the start we are looking for we can take the last value
        if(stakes[lastIndex].startBlock <= startBlock){
            diff =  endBlock.sub(startBlock) == 0 ? 1 : endBlock.sub(startBlock);
            return stakes[lastIndex].total.mul(diff);
        }
 
        // working our way back we need to get the first index that falls into our range
        // This could be large so need to think of a better way to get here
        while(lastIndex > 0 && stakes[lastIndex].startBlock > endBlock){
            lastIndex = lastIndex.sub(1);
        }
 
        uint total;
        diff = 0;
        //last index should now be in our range so loop through until all block numbers are covered
        while(stakes[lastIndex].startBlock >= startBlock ) {  
            diff = 1;
            if(stakes[lastIndex].startBlock <= startBlock){
                diff = endBlock.sub(startBlock) == 0 ? 1 : endBlock.sub(startBlock);
                total = total.add(stakes[lastIndex].total.mul(diff));
                break;
            }
 
            diff = endBlock.sub(stakes[lastIndex].startBlock) == 0 
                            ? 1 
                            : endBlock.sub(stakes[lastIndex].startBlock);
            total = total.add(stakes[lastIndex].total.mul(diff));
            endBlock = stakes[lastIndex].startBlock;
 
            if(lastIndex == 0){
                break;
            } 
 
            lastIndex = lastIndex.sub(1); 
        }
 
        // If the last total supply is before the start we are looking for we can take the last value
        if(stakes[lastIndex].startBlock <= startBlock && startBlock <= endBlock){
            diff =  endBlock.sub(startBlock) == 0 ? 1 : endBlock.sub(startBlock);
            total = total.add(stakes[lastIndex].total.mul(diff));

        }
 
        return total;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

contract iTrustGovernanceToken is ERC20CappedUpgradeable, OwnableUpgradeable, PausableUpgradeable {

    using SafeMathUpgradeable for uint;

    address internal _treasuryAddress;
    uint internal _yearOneSupply;
    uint internal _yearTwoSupply;
    uint internal _yearThreeSupply;
    uint internal _yearFourSupply;
    uint internal _yearFiveSupply;
    
    function initialize(
        address payable treasuryAddress, 
        uint cap_,
        uint yearOneSupply, 
        uint yearTwoSupply, 
        uint yearThreeSupply, 
        uint yearFourSupply, 
        uint yearFiveSupply) initializer public {

        require(yearOneSupply.add(yearTwoSupply).add(yearThreeSupply).add(yearFourSupply).add(yearFiveSupply) == cap_);

        __ERC20_init("iTrust Governance Token", "$ITG");
        __ERC20Capped_init(cap_);
        __Ownable_init();
        __Pausable_init();

        _treasuryAddress = treasuryAddress;
        _yearOneSupply = yearOneSupply;
        _yearTwoSupply = yearTwoSupply;
        _yearThreeSupply = yearThreeSupply;
        _yearFourSupply = yearFourSupply;
        _yearFiveSupply = yearFiveSupply;

        
    }

    function mintYearOne() external onlyOwner {
        require(totalSupply() == 0);
        _mint(_treasuryAddress, _yearOneSupply);
    }

    function mintYearTwo() external onlyOwner {
        require(totalSupply() == _yearOneSupply);
        _mint(_treasuryAddress, _yearTwoSupply);
    }

    function mintYearThree() external onlyOwner {
        require(totalSupply() == _yearOneSupply.add(_yearTwoSupply));
        _mint(_treasuryAddress, _yearThreeSupply);
    }

    function mintYearFour() external onlyOwner {
        require(totalSupply() == _yearOneSupply.add(_yearTwoSupply).add(_yearThreeSupply));
        _mint(_treasuryAddress, _yearFourSupply);
    }

    function mintYearFive() external onlyOwner {
        require(totalSupply() == _yearOneSupply.add(_yearTwoSupply).add(_yearThreeSupply).add(_yearFourSupply));
        _mint(_treasuryAddress, _yearFiveSupply);
    }
}

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import { ITrustVaultLib as VaultLib } from "./../libraries/ItrustVaultLib.sol"; 

abstract contract BaseContract is Initializable, ContextUpgradeable
{
    uint8 internal constant FALSE = 0;
    uint8 internal constant TRUE = 1;

    uint8 internal _locked;
    address internal _iTrustFactoryAddress;

    mapping (address => uint32) internal _CurrentRoundNumbers;
    mapping (address => uint) internal _TotalUnstakedWnxm;
    mapping (address => uint[]) internal _TotalSupplyKeys;
    mapping (address => uint[]) internal _TotalUnstakingKeys;
    mapping (address => uint[]) internal _TotalSupplyForDayKeys;
   
    mapping (address => address[]) public totalRewardTokenAddresses;
    mapping (address => address[]) internal _UnstakingAddresses;
    mapping (address => address[]) internal _AccountStakesAddresses;

    mapping (address => VaultLib.UnStaking[]) internal _UnstakingRequests;
    mapping (address => mapping (address => uint32)) internal _RewardStartingRounds;
    mapping (address => mapping (address => VaultLib.AccountStaking)) internal _AccountStakes;
    mapping (address => mapping (address => VaultLib.UnStaking[])) internal _AccountUnstakings;

    mapping (address => mapping (address => uint8)) internal _RewardTokens;
    mapping (address => mapping (address => uint)) internal _AccountUnstakingTotals;
    mapping (address => mapping (address => uint)) internal _AccountUnstakedTotals;
    mapping (address => mapping (uint => uint)) internal _TotalSupplyHistory;
    mapping (address => mapping (address => mapping (address => VaultLib.ClaimedReward))) internal _AccountRewards;
    mapping (address => mapping (uint => VaultLib.RewardTokenRound)) internal _Rounds;

    mapping (address => mapping (uint => uint)) internal _TotalSupplyForDayHistory;
    


    mapping (address => mapping (uint => VaultLib.UnStaking)) internal _TotalUnstakingHistory;
    
    function _nonReentrant() internal view {
        require(_locked == FALSE);  
    }

}

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./../iTrustVaultFactory.sol";
import "./../tokens/iTrustGovernanceToken.sol";
import "./Vault.sol";
import {
    BokkyPooBahsDateTimeLibrary as DateTimeLib
} from "./../3rdParty/BokkyPooBahsDateTimeLibrary.sol";

contract GovernanceDistribution is Initializable, ContextUpgradeable
{
    using SafeMathUpgradeable for uint;

    uint8 internal constant FALSE = 0;
    uint8 internal constant TRUE = 1;

    uint8 internal _locked;
    uint internal _tokenPerHour;
    address internal _iTrustFactoryAddress;
    uint[] internal _totalSupplyKeys;
    mapping (uint => uint) internal _totalSupplyHistory;
    mapping (address => uint[]) internal _totalStakedKeys;
    mapping (address => mapping (uint => uint)) internal _totalStakedHistory;
    mapping (address => uint) internal _lastClaimedTimes;
    mapping(address => mapping(string => bool)) _UsedNonces;

    function initialize(
        address iTrustFactoryAddress,
        uint tokenPerDay
    ) 
        initializer 
        external 
    {
        _iTrustFactoryAddress = iTrustFactoryAddress;
        _tokenPerHour = tokenPerDay.div(24);
    }

    /**
     * Public functions
     */

     function totalStaked(address account) external view returns(uint) {
         _onlyAdmin();

         if(_totalStakedKeys[account].length == 0){
             return 0;
         }

        return _totalStakedHistory[account][_totalStakedKeys[account][_totalStakedKeys[account].length.sub(1)]];
    }

    function totalSupply() external view returns(uint) {
         _onlyAdmin();

         if(_totalSupplyKeys.length == 0){
             return 0;
         }

        return _totalSupplyHistory[_totalSupplyKeys[_totalSupplyKeys.length.sub(1)]];
    }

    function calculateRewards() external view returns(uint amount, uint claimedUntil) {
        (amount, claimedUntil) = _calculateRewards(_msgSender());
        return(amount, claimedUntil);
    }

    function calculateRewardsForAccount(address account) external view returns(uint amount, uint claimedUntil) {
        _isTrustedSigner(_msgSender());
        (amount, claimedUntil) = _calculateRewards(account);
        return(amount, claimedUntil);
    }

    function removeStake(address account, uint value) external {
        _validateStakingDataAddress();
        require(_totalStakedKeys[account].length != 0);
        uint currentTime = _getStartOfHourTimeStamp(block.timestamp);
        uint lastStakedIndex = _totalStakedKeys[account][_totalStakedKeys[account].length.sub(1)];
        if(lastStakedIndex > currentTime){
            if(_totalStakedKeys[account].length == 1 || _totalStakedKeys[account][_totalStakedKeys[account].length.sub(2)] != currentTime){
                _totalStakedKeys[account][_totalStakedKeys[account].length.sub(1)] = currentTime;
                _totalStakedHistory[account][currentTime] = _totalStakedKeys[account].length == 1 ? 0 : _totalStakedHistory[account][_totalStakedKeys[account][_totalStakedKeys[account].length.sub(2)]];
                _totalStakedKeys[account].push(lastStakedIndex);
            }
            _totalStakedHistory[account][lastStakedIndex] = _totalStakedHistory[account][lastStakedIndex].sub(value);
            lastStakedIndex = _totalStakedKeys[account][_totalStakedKeys[account].length.sub(2)];
        }
        require(value <= _totalStakedHistory[account][lastStakedIndex]);
        uint newValue = _totalStakedHistory[account][lastStakedIndex].sub(value);
        if(lastStakedIndex != currentTime){
            _totalStakedKeys[account].push(currentTime);
        }
        _totalStakedHistory[account][currentTime] = newValue;
        require(_totalSupplyKeys.length != 0);
        uint lastSupplyIndex = _totalSupplyKeys[_totalSupplyKeys.length.sub(1)];
        if(lastSupplyIndex > currentTime){
            if(_totalSupplyKeys.length == 1 || _totalSupplyKeys[_totalSupplyKeys.length.sub(2)] != currentTime){
                _totalSupplyKeys[_totalSupplyKeys.length.sub(1)] = currentTime;
                _totalSupplyHistory[currentTime] = _totalSupplyKeys.length == 1 ? 0 : _totalSupplyHistory[_totalSupplyKeys[_totalSupplyKeys.length.sub(2)]];
                _totalSupplyKeys.push(lastSupplyIndex);
            }
            
            _totalSupplyHistory[lastSupplyIndex] = _totalSupplyHistory[lastSupplyIndex].sub(value);
            lastSupplyIndex = _totalSupplyKeys[_totalSupplyKeys.length.sub(2)];
        }
        if(lastSupplyIndex != currentTime){
            _totalSupplyKeys.push(currentTime);
        }
        _totalSupplyHistory[currentTime] = _totalSupplyHistory[lastSupplyIndex].sub(value);
    }

    function addStake(address account, uint value) external {
        _validateStakingDataAddress();
        uint currentTime = _getStartOfNextHourTimeStamp(block.timestamp);

        if(_totalStakedKeys[account].length == 0){
            _totalStakedKeys[account].push(currentTime);
            _totalStakedHistory[account][currentTime] = value;
        } else {
            uint lastStakedIndex = _totalStakedKeys[account].length.sub(1);
            uint lastTimestamp = _totalStakedKeys[account][lastStakedIndex];

            if(lastTimestamp != currentTime){
                _totalStakedKeys[account].push(currentTime);
            }

            _totalStakedHistory[account][currentTime] = _totalStakedHistory[account][lastTimestamp].add(value);
        }

        if(_totalSupplyKeys.length == 0){
            _totalSupplyKeys.push(currentTime);
            _totalSupplyHistory[currentTime] = value;
        } else {
            uint lastSupplyIndex = _totalSupplyKeys.length.sub(1);
            uint lastSupplyTimestamp = _totalSupplyKeys[lastSupplyIndex];

            if(lastSupplyTimestamp != currentTime){
                _totalSupplyKeys.push(currentTime);
            }

            _totalSupplyHistory[currentTime] = _totalSupplyHistory[lastSupplyTimestamp].add(value);
        }
    }

    function withdrawTokens(uint amount, uint claimedUntil, string memory nonce, bytes memory sig) external {
        _nonReentrant();
        require(amount != 0);
        require(claimedUntil != 0);
        require(!_UsedNonces[_msgSender()][nonce]);
        _locked = TRUE;
        bytes32 abiBytes = keccak256(abi.encodePacked(_msgSender(), amount, claimedUntil, nonce, address(this)));
        bytes32 message = _prefixed(abiBytes);

        address signer = _recoverSigner(message, sig);
        _isTrustedSigner(signer);

        _lastClaimedTimes[_msgSender()] = claimedUntil;
        _UsedNonces[_msgSender()][nonce] = true;

        _getiTrustGovernanceToken().transfer(_msgSender(), amount);
        _locked = FALSE;
    }

    /**
     * Internal functions
     */

    function _calculateRewards(address account) internal view returns(uint, uint) {

        if(_totalStakedKeys[account].length == 0 || _totalSupplyKeys.length == 0){
            return (0, 0);
        }

        uint currentTime = _getStartOfHourTimeStamp(block.timestamp);
        uint claimedUntil = _getStartOfHourTimeStamp(block.timestamp);
        uint lastClaimedTimestamp = _lastClaimedTimes[account];

        // if 0 they have never staked go back to the first stake
        if(lastClaimedTimestamp == 0){
            lastClaimedTimestamp = _totalStakedKeys[account][0];
        }

        uint totalRewards = 0;
        uint stakedStartingIndex = _totalStakedKeys[account].length.sub(1);
        uint supplyStartingIndex = _totalSupplyKeys.length.sub(1);
        uint hourReward = 0;

        while(currentTime > lastClaimedTimestamp) {
            (hourReward, stakedStartingIndex, supplyStartingIndex) = _getTotalRewardHour(account, currentTime, stakedStartingIndex, supplyStartingIndex);
            totalRewards = totalRewards.add(hourReward);
            currentTime = DateTimeLib.subHours(currentTime, 1);
        }

        return (totalRewards, claimedUntil);
    }

    function _getTotalRewardHour(address account, uint hourTimestamp, uint stakedStartingIndex, uint supplyStartingIndex) internal view returns(uint, uint, uint) {

        (uint totalStakedForHour, uint returnedStakedStartingIndex) =  _getTotalStakedForHour(account, hourTimestamp, stakedStartingIndex);
        (uint totalSupplyForHour, uint returnedSupplyStartingIndex) =  _getTotalSupplyForHour(hourTimestamp, supplyStartingIndex);
        uint reward = 0;
        
        if(totalSupplyForHour > 0 && totalStakedForHour > 0){
            uint govTokenPerTokenPerHour = _divider(_tokenPerHour, totalSupplyForHour, 18); // _tokenPerHour.div(totalSupplyForHour);
            reward = reward.add(totalStakedForHour.mul(govTokenPerTokenPerHour).div(1e18)); 
        }

        return (reward, returnedStakedStartingIndex, returnedSupplyStartingIndex);
    }

    function _getTotalStakedForHour(address account, uint hourTimestamp, uint startingIndex) internal view returns(uint, uint) {

        while(startingIndex != 0 && hourTimestamp <= _totalStakedKeys[account][startingIndex]) {
            startingIndex = startingIndex.sub(1);
        }

        // We never got far enough back before hitting 0, meaning we staked after the hour we are looking up
        if(hourTimestamp < _totalStakedKeys[account][startingIndex]){
            return (0, startingIndex);
        }

        return (_totalStakedHistory[account][_totalStakedKeys[account][startingIndex]], startingIndex);
    }

    function _getTotalSupplyForHour(uint hourTimestamp, uint startingIndex) internal view returns(uint, uint) {

        

        while(startingIndex != 0 && hourTimestamp <= _totalSupplyKeys[startingIndex]) {
            startingIndex = startingIndex.sub(1);
        }

        // We never got far enough back before hitting 0, meaning we staked after the hour we are looking up
        if(hourTimestamp < _totalSupplyKeys[startingIndex]){
            return (0, startingIndex);
        }

        return (_totalSupplyHistory[_totalSupplyKeys[startingIndex]], startingIndex);
    }

    function _getStartOfHourTimeStamp(uint nowDateTime) internal pure returns (uint) {
        (uint year, uint month, uint day, uint hour, ,) = DateTimeLib.timestampToDateTime(nowDateTime);
        return DateTimeLib.timestampFromDateTime(year, month, day, hour, 0, 0);
    }

    function _getStartOfNextHourTimeStamp(uint nowDateTime) internal pure returns (uint) {
        (uint year, uint month, uint day, uint hour, ,) = DateTimeLib.timestampToDateTime(nowDateTime);
        return DateTimeLib.timestampFromDateTime(year, month, day, hour.add(1), 0, 0);
    }

    function _getITrustVaultFactory() internal view returns(ITrustVaultFactory) {
        return ITrustVaultFactory(_iTrustFactoryAddress);
    }

    function _governanceTokenAddress() internal view returns(address) {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        return vaultFactory.getGovernanceTokenAddress();
    }

    function _getiTrustGovernanceToken() internal view returns(iTrustGovernanceToken) {
        return iTrustGovernanceToken(_governanceTokenAddress());
    }

    function _divider(uint numerator, uint denominator, uint precision) internal pure returns(uint) {        
        return numerator*(uint(10)**uint(precision))/denominator;
    }

    /**
     * Validate functions
     */

     function _nonReentrant() internal view {
        require(_locked == FALSE);  
    }

    function _onlyAdmin() internal view {
        require(
            _getITrustVaultFactory().isAddressAdmin(_msgSender()),
            "Not admin"
        );
    }

    function _isTrustedSigner(address signer) internal view {
        require(
            _getITrustVaultFactory().isTrustedSignerAddress(signer),
            "Not trusted signer"
        );
    }

    function _validateStakingDataAddress() internal view {
        _validateStakingDataAddress(_msgSender());
    }

    function _validateStakingDataAddress(address contractAddress) internal view {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        require(vaultFactory.isStakingDataAddress(contractAddress));
    }

    function _splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function _recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = _splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function _prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./../iTrustVaultFactory.sol";
import "./BaseContract.sol";
import "./StakingDataController/StakeData.sol";

import { ITrustVaultLib as VaultLib } from "./../libraries/ItrustVaultLib.sol"; 

contract StakingCalculation
{
    using SafeMath for uint;

    // function getRoundDataForAccount(
    //     VaultLib.Staking[] memory stakes,
    //     VaultLib.UnStaking[] memory unstakes,
    //     uint startBlock, 
    //     uint endBlock) external pure 
    //     returns (uint totalHoldings, uint[] memory stakeBlocks, uint[] memory stakeAmounts, uint[] memory unstakeStartBlocks, uint[] memory unstakeEndBlocks, uint[] memory unstakeAmounts)
    // {
        
    //     totalHoldings = VaultLib.getHoldingsForBlockRange(stakes, startBlock, endBlock);

    //     (stakeBlocks, stakeAmounts) = VaultLib.getRoundDataStakesForAccount(stakes, startBlock, endBlock);

    //     (unstakeStartBlocks, unstakeEndBlocks, unstakeAmounts) = VaultLib.getRoundDataUnstakesForAccount(unstakes, startBlock, endBlock);

    //     return (totalHoldings, stakeBlocks, stakeAmounts, unstakeStartBlocks, unstakeEndBlocks, unstakeAmounts);
    // }

    function getUnstakingsForBlockRange(
        VaultLib.UnStaking[] memory unStakes, 
        uint startBlock, 
        uint endBlock) external pure returns (uint){
        return VaultLib.getUnstakingsForBlockRange(
                        unStakes, 
                        startBlock, 
                        endBlock
                    );
    }

    function getHoldingsForBlockRange(
        VaultLib.Staking[] memory stakes,
        uint startBlock, 
        uint endBlock) external pure returns (uint){
        
        return VaultLib.getHoldingsForBlockRange(
                    stakes, 
                    startBlock, 
                    endBlock);
    }

}

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./../iTrustVaultFactory.sol";
import "./BaseContract.sol";
import "./StakingDataController/StakeData.sol";
import "./StakingCalculation.sol";
import "./StakingDataController/RoundData.sol";

contract StakingData is BaseContract
{
    using SafeMathUpgradeable for uint;

    function initialize(
        address iTrustFactoryAddress
    ) 
        initializer 
        external 
    {
        _iTrustFactoryAddress = iTrustFactoryAddress;
        _locked = FALSE;
    }

    /**
     * Public functions
     */

     function _getTotalSupplyForBlockRange(address vaultAddress, uint endBlock, uint startBlock) internal returns(uint) {

        (bool success, bytes memory result) = 
            _stakeDataImplementationAddress()
                .delegatecall(
                    abi.encodeWithSelector(
                        StakeData.getTotalSupplyForBlockRange.selector,                       
                        vaultAddress, 
                        endBlock,
                        startBlock
                    )
                );
        require(success);
        return abi.decode(result, (uint256));
    }

    function _getTotalUnstakingsForBlockRange(address vaultAddress, uint endBlock, uint startBlock) internal returns(uint) {

        (bool success, bytes memory result) = 
            _stakeDataImplementationAddress()
                .delegatecall(
                    abi.encodeWithSelector(
                         StakeData.getTotalUnstakingsForBlockRange.selector,
                        vaultAddress, 
                        endBlock,
                        startBlock
                    )
                );
        require(success);
        return abi.decode(result, (uint256));
    }

    

     function addVault(address vaultAddress) external  {
        _validateFactory();
        _CurrentRoundNumbers[vaultAddress] = 1;
        _Rounds[vaultAddress][_CurrentRoundNumbers[vaultAddress]].startBlock = block.number;
        _updateTotalSupplyForBlock(0);
    }

    function endRound(address[] calldata tokens, uint[] calldata tokenAmounts,  bool[] calldata ignoreUnstakes, uint commission) external returns(bool) {
        _validateVault();

        address vaultAddress = _vaultAddress();
 
        uint startBlock = _Rounds[vaultAddress][_CurrentRoundNumbers[vaultAddress]].startBlock;
        (bool result, ) = _roundDataImplementationAddress()
            .delegatecall(
                abi.encodeWithSelector(
                RoundData.endRound.selector,
                vaultAddress, 
                tokens, 
                tokenAmounts, 
                ignoreUnstakes, 
                _getTotalSupplyForBlockRange(
                    vaultAddress, 
                    block.number, 
                    startBlock
                ),
                _getTotalUnstakingsForBlockRange(
                        vaultAddress, 
                        block.number, 
                        startBlock
                    ), 
                commission)
            );
      
        require(result);
        return true;
    }

    function getCurrentRoundData() external view returns(uint, uint, uint) {
        _validateVault();
        return _getRoundDataForAddress(_vaultAddress(), _CurrentRoundNumbers[_vaultAddress()]);
    }

    function getRoundData(uint roundNumberIn) external view returns(uint, uint, uint) {
        _validateVault();
        return _getRoundDataForAddress(_vaultAddress(), roundNumberIn);
    }

    function getRoundRewards(uint roundNumber) external  view 
    returns(
        address[] memory rewardTokens,
        uint[] memory rewardAmounts,
        uint[] memory commisionAmounts,
        uint[] memory tokenPerBlock, 
        uint[] memory totalSupply
    ) {
        _validateVault();
        return _getRoundRewardsForAddress(_vaultAddress(), roundNumber);
    }

    function startUnstake(address account, uint256 value) external returns(bool) {
        _validateVault();
        (bool result, ) = _stakeDataImplementationAddress()
            .delegatecall(abi.encodeWithSelector(StakeData.startUnstakeForAddress.selector, _vaultAddress(), account, value));
        return result;
    }

    function getAccountStakes(address account) external view 
    returns(
        uint stakingTotal,
        uint unStakingTotal,
        uint[] memory unStakingAmounts,
        uint[] memory unStakingStarts            
    ) {
        _validateVault();
        return _getAccountStakesForAddress(_vaultAddress(), account);
    }

    function getAccountStakingTotal(address account) external view returns (uint) {
        _validateVault();
        return _AccountStakes[_vaultAddress()][account].total.sub(_AccountUnstakingTotals[_vaultAddress()][account]);
    }

    function getAllAcountUnstakes() external view returns (address[] memory accounts, uint[] memory startTimes, uint[] memory values) {
        _validateVault();
        return _getAllAcountUnstakesForAddress(_vaultAddress());
    }

    function getAccountUnstakedTotal(address account) external view  returns (uint) {
        _validateVault();
        return _AccountUnstakedTotals[_vaultAddress()][account];
    }

    function authoriseUnstakes(address[] memory account, uint[] memory timestamp) external returns(bool) {
        _validateVault();
        require(account.length <= 10);        
        for(uint8 i = 0; i < account.length; i++) {
            _authoriseUnstake(_vaultAddress(), account[i], timestamp[i]);
        }        
        return true;
    }

    function withdrawUnstakedToken(address account, uint amount) external returns(bool)  {
        _validateVault();
        _nonReentrant();
        _locked = TRUE;

        address vaultAddress = _vaultAddress();
        require(_AccountUnstakedTotals[vaultAddress][account] > 0);
        require(amount <= _AccountUnstakedTotals[vaultAddress][account]);
        _AccountUnstakedTotals[vaultAddress][account] = _AccountUnstakedTotals[vaultAddress][account].sub(amount);
        _TotalUnstakedWnxm[vaultAddress] = _TotalUnstakedWnxm[vaultAddress].sub(amount);

        _locked = FALSE;
        return true;
    }

    function createStake(uint amount, address account) external returns(bool) {
        _validateVault();
        (bool result, ) = _stakeDataImplementationAddress()
            .delegatecall(abi.encodeWithSelector(StakeData.createStake.selector,_vaultAddress(),amount,account));
        return result;
    }

    function removeStake(uint amount, address account) external returns(bool) {
        _validateVault();
        (bool result, ) = _stakeDataImplementationAddress()
            .delegatecall(abi.encodeWithSelector(StakeData.removeStake.selector, _vaultAddress(), amount, account));
        return result;
    }

    function calculateRewards(address account) external view returns (address[] memory rewardTokens, uint[] memory rewards) {
        _validateVault();
        return _calculateRewards(account);
    }

    function withdrawRewards(address account, address[] memory rewardTokens, uint[] memory rewards) external returns(bool) {
        _validateVault();
        _nonReentrant();
        _locked = TRUE;
        _withdrawRewards(_vaultAddress(), rewardTokens, rewards, account);
        _locked = FALSE;
        return true;
    }

    function updateTotalSupplyForDayAndBlock(uint totalSupply) external returns(bool) {
        _validateVault();
        _updateTotalSupplyForBlock(totalSupply);
        return true;
    }

    function getTotalSupplyForAccountBlock(address vaultAddress, uint date) external view returns(uint) {
        _validateBurnContract();
        return _getTotalSupplyForAccountBlock(vaultAddress, date);
    }

    function getHoldingsForIndexAndBlockForVault(address vaultAddress, uint index, uint blockNumber) external view returns(address indexAddress, uint addressHoldings) {
        _validateBurnContract();
        return _getHoldingsForIndexAndBlock(vaultAddress, index, blockNumber);
    }

    function getNumberOfStakingAddressesForVault(address vaultAddress) external view returns(uint) {
        _validateBurnContract();
        return _AccountStakesAddresses[vaultAddress].length;
    }

    /**
     * Internal functions
     */

     function _getHoldingsForIndexAndBlock(address vaultAddress, uint index, uint blockNumber) internal view returns(address indexAddress, uint addressHoldings) {
        require(_AccountStakesAddresses[vaultAddress].length - 1 >= index);
        indexAddress = _AccountStakesAddresses[vaultAddress][index];
        bytes memory data = abi.encodeWithSelector(StakingCalculation.getHoldingsForBlockRange.selector, _AccountStakes[vaultAddress][indexAddress].stakes, blockNumber, blockNumber);        
        (, bytes memory resultData) = _stakingCalculationsAddress().staticcall(data);
        addressHoldings = abi.decode(resultData, (uint256));
        return(indexAddress, addressHoldings);
    }

     function _getTotalSupplyForAccountBlock(address vaultAddress, uint blockNumber) internal view returns(uint) {
        uint index =  _getIndexForBlock(vaultAddress, blockNumber, 0);
        return _TotalSupplyHistory[vaultAddress][_TotalSupplyKeys[vaultAddress][index]];
    }

     function _authoriseUnstake(address vaultAddress, address account, uint timestamp) internal {
        (bool result, ) = _stakeDataImplementationAddress()
            .delegatecall(abi.encodeWithSelector(StakeData.authoriseUnstake.selector, vaultAddress, account, timestamp));            
        require(result);
    }

    function _updateTotalSupplyForBlock(uint totalSupply) public returns(bool) {
        if(_TotalSupplyHistory[_vaultAddress()][block.number] == 0){  // Assumes there will never be 0, could use the array itself to check will look at this again
            _TotalSupplyKeys[_vaultAddress()].push(block.number);
        }

        _TotalSupplyHistory[_vaultAddress()][block.number] = totalSupply;
        return true;
    }


    function _getRoundDataForAddress(address vaultAddress, uint roundNumberIn) internal view returns(uint roundNumber, uint startBlock, uint endBlock) {
        roundNumber = roundNumberIn;
        startBlock = _Rounds[vaultAddress][roundNumber].startBlock;
        endBlock = _Rounds[vaultAddress][roundNumber].endBlock;
        return( 
            roundNumber,
            startBlock,
            endBlock
        );
    }

    function _getRoundRewardsForAddress(address vaultAddress, uint roundNumber) internal view 
    returns(
        address[] memory rewardTokens,
        uint[] memory rewardAmounts,
        uint[] memory commissionAmounts,
        uint[] memory tokenPerBlock,        
        uint[] memory totalSupply
    ) {
        rewardTokens = new address[](totalRewardTokenAddresses[vaultAddress].length);
        rewardAmounts = new uint[](totalRewardTokenAddresses[vaultAddress].length);
        commissionAmounts = new uint[](totalRewardTokenAddresses[vaultAddress].length);
        tokenPerBlock = new uint[](totalRewardTokenAddresses[vaultAddress].length);
        totalSupply  = new uint[](totalRewardTokenAddresses[vaultAddress].length);
        for(uint i = 0; i < totalRewardTokenAddresses[vaultAddress].length; i++){
            rewardTokens[i] = totalRewardTokenAddresses[vaultAddress][i];
            rewardAmounts[i] = _Rounds[vaultAddress][roundNumber].roundData[totalRewardTokenAddresses[vaultAddress][i]].amount;
            commissionAmounts[i] = _Rounds[vaultAddress][roundNumber].roundData[totalRewardTokenAddresses[vaultAddress][i]].commissionAmount;
            tokenPerBlock[i] = _Rounds[vaultAddress][roundNumber].roundData[totalRewardTokenAddresses[vaultAddress][i]].tokenPerBlock;
            totalSupply[i] = _Rounds[vaultAddress][roundNumber].roundData[totalRewardTokenAddresses[vaultAddress][i]].totalSupply;
        }
        return( 
            rewardTokens,
            rewardAmounts,
            commissionAmounts,
            tokenPerBlock,
            totalSupply
        );
    }

    function _getIndexForBlock(address vaultAddress, uint startBlock, uint startIndex) internal view returns(uint) {
        uint i = startIndex == 0 ? _TotalSupplyKeys[vaultAddress].length.sub(1) : startIndex;
        uint blockForIndex = _TotalSupplyKeys[vaultAddress][i];
        
        if(_TotalSupplyKeys[vaultAddress][0] > startBlock){
            return 0;
        }

        if(blockForIndex < startBlock){
            return i;
        }

        while(blockForIndex > startBlock){
            i = i.sub(1);
            blockForIndex = _TotalSupplyKeys[vaultAddress][i];
        }

        return i;
    }

    function _getAccountStakesForAddress(address vaultAddress, address account) internal view 
    returns(
        uint stakingTotal,
        uint unStakingTotal,
        uint[] memory unStakingAmounts,
        uint[] memory unStakingStarts            
    ) {
        unStakingAmounts = new uint[](_AccountUnstakings[vaultAddress][account].length);
        unStakingStarts = new uint[](_AccountUnstakings[vaultAddress][account].length);
        for(uint i = 0; i < _AccountUnstakings[vaultAddress][account].length; i++){
            if(_AccountUnstakings[vaultAddress][account][i].endBlock == 0){
                unStakingAmounts[i] = _AccountUnstakings[vaultAddress][account][i].amount;
                unStakingStarts[i] = _AccountUnstakings[vaultAddress][account][i].startDateTime;
            }
        }
        return( 
            _AccountStakes[vaultAddress][account].total.sub(_AccountUnstakingTotals[vaultAddress][account]),
            _AccountUnstakingTotals[vaultAddress][account],
            unStakingAmounts,
            unStakingStarts
        );
    }

    function _getAllAcountUnstakesForAddress(address vaultAddress) internal view returns (address[] memory accounts, uint[] memory startTimes, uint[] memory values) {
        accounts = new address[](_UnstakingRequests[vaultAddress].length);
        startTimes = new uint[](_UnstakingRequests[vaultAddress].length);
        values = new uint[](_UnstakingRequests[vaultAddress].length);
        for(uint i = 0; i < _UnstakingRequests[vaultAddress].length; i++) {
            if(_UnstakingRequests[vaultAddress][i].endBlock == 0 ) {
                accounts[i] = _UnstakingRequests[vaultAddress][i].account;
                startTimes[i] = _UnstakingRequests[vaultAddress][i].startDateTime;
                values[i] = _UnstakingRequests[vaultAddress][i].amount;
            }
        }        
        return(accounts, startTimes, values);
    }

    function getUnstakedWxnmTotal() external view returns(uint total) {
        _validateVault();
        total = _TotalUnstakedWnxm[_vaultAddress()];
    }

    function _calculateRewards(address account) internal view  returns (address[] memory rewardTokens, uint[] memory rewards) {
        rewardTokens = totalRewardTokenAddresses[_vaultAddress()];
        rewards = new uint[](rewardTokens.length);

        for(uint x = 0; x < totalRewardTokenAddresses[_vaultAddress()].length; x++){            
            (rewards[x]) = _calculateReward(_vaultAddress(), account, rewardTokens[x]);            
            rewards[x] = rewards[x].div(1 ether);
        }

        return (rewardTokens, rewards);
    }

     function _calculateReward(address vaultAddress, address account, address rewardTokenAddress) internal view returns (uint reward){
        VaultLib.ClaimedReward memory claimedReward = _AccountRewards[vaultAddress][account][rewardTokenAddress];

        if(_RewardStartingRounds[vaultAddress][rewardTokenAddress] == 0){            
            return(0);
        }

        uint futureRoundNumber = _CurrentRoundNumbers[vaultAddress] - 1;// one off as the current hasnt closed
        address calcContract = _stakingCalculationsAddress();
        while(claimedReward.lastClaimedRound < futureRoundNumber 
                && _RewardStartingRounds[vaultAddress][rewardTokenAddress] <= futureRoundNumber
                && futureRoundNumber != 0 )
        {

            if(_Rounds[vaultAddress][futureRoundNumber].roundData[rewardTokenAddress].amount == 0){
                futureRoundNumber--;
                continue;
            }

            (, bytes memory resultData) = calcContract.staticcall(abi.encodeWithSignature(
                "getHoldingsForBlockRange((uint256,uint256,uint256,uint256)[],uint256,uint256)", 
                _AccountStakes[vaultAddress][account].stakes, 
                _Rounds[vaultAddress][futureRoundNumber].startBlock, 
                _Rounds[vaultAddress][futureRoundNumber].endBlock
            ));
            uint holdingsForRound = abi.decode(resultData, (uint256));

            if (!(_Rounds[vaultAddress][futureRoundNumber].roundData[rewardTokenAddress].ignoreUnstakes)) {
                (, bytes memory unstakedResultData) = calcContract.staticcall(abi.encodeWithSignature(
                    "getUnstakingsForBlockRange((address,uint256,uint256,uint256,uint256)[],uint256,uint256)", 
                    _AccountUnstakings[vaultAddress][account], 
                    _Rounds[vaultAddress][futureRoundNumber].startBlock, 
                    _Rounds[vaultAddress][futureRoundNumber].endBlock
                ));
                holdingsForRound = holdingsForRound.sub(abi.decode(unstakedResultData, (uint256)));
            }
           
            holdingsForRound = VaultLib.divider(
                     holdingsForRound, 
                     _Rounds[vaultAddress][futureRoundNumber].roundData[rewardTokenAddress].totalSupply, 
                     18)
                     .mul(_Rounds[vaultAddress][futureRoundNumber].roundData[rewardTokenAddress].amount);
            reward = reward.add(holdingsForRound);
            futureRoundNumber--;
        }

        return (reward);
    }

    function _withdrawRewards(address vaultAddress, address[] memory rewardTokens, uint[] memory rewards, address account) internal {
          
        for (uint x = 0; x < rewardTokens.length; x++){
            _AccountRewards[vaultAddress][account][rewardTokens[x]].amount = _AccountRewards[vaultAddress][account][rewardTokens[x]].amount + rewards[x];
            _AccountRewards[vaultAddress][account][rewardTokens[x]].lastClaimedRound = _CurrentRoundNumbers[vaultAddress] - 1;
        }

    }

    function _vaultAddress() internal view returns(address) {
        return _msgSender();
    }

    function _roundDataImplementationAddress() internal view returns(address) {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        return vaultFactory.getRoundDataImplementationAddress();
    }

    function _stakeDataImplementationAddress() internal view returns(address) {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        return vaultFactory.getStakeDataImplementationAddress();
    }

    function _stakingCalculationsAddress() internal view returns(address) {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        return address(vaultFactory.getStakingCalculationsAddress());
    }

    /**
     * Validate functions
     */

    function _validateVault() internal view {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        require(vaultFactory.isActiveVault(_vaultAddress()));
    }

    function _validateBurnContract() internal view {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        require(vaultFactory.isBurnAddress(_msgSender()));
    }

    function _validateFactory() internal view {
        require(_msgSender() == _iTrustFactoryAddress);
    }

}

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./../BaseContract.sol";

contract RoundData is BaseContract
{
    using SafeMathUpgradeable for uint;
    
    function endRound(
        address vaultAddress, 
        address[] memory tokens, 
        uint[] memory tokenAmounts, 
        bool[] memory ignoreUnstakes,        
        uint totalSupplyForBlockRange, 
        uint totalUnstakings,
        uint commissionValue) 
        external 
    {
        require( _Rounds[vaultAddress][_CurrentRoundNumbers[vaultAddress]].startBlock < block.number);       
        uint32 roundNumber = _CurrentRoundNumbers[vaultAddress];
        uint rewardAmount;
        uint commissionAmount;
        uint tokensPerBlock; //Amoun

        for (uint i=0; i < tokens.length; i++) {    
              
            rewardAmount = tokenAmounts[i].sub(tokenAmounts[i].mul(commissionValue).div(10000));
            commissionAmount = tokenAmounts[i].mul(commissionValue).div(10000);
            tokensPerBlock = VaultLib.divider(rewardAmount, _getAdjustedTotalSupply(totalSupplyForBlockRange, totalUnstakings, ignoreUnstakes[i]), 18);
            VaultLib.RewardTokenRoundData memory tokenData = VaultLib.RewardTokenRoundData(
                {
                    tokenAddress: tokens[i],
                    amount: rewardAmount,
                    commissionAmount: commissionAmount,
                    tokenPerBlock: tokensPerBlock,//.div(1e18),
                    totalSupply: _getAdjustedTotalSupply(totalSupplyForBlockRange, totalUnstakings, ignoreUnstakes[i]),  
                    ignoreUnstakes: ignoreUnstakes[i]
                }
            );

            _Rounds[vaultAddress][roundNumber].roundData[tokens[i]] = tokenData;            
           
            if(_RewardTokens[vaultAddress][tokens[i]] != TRUE){
                _RewardStartingRounds[vaultAddress][tokens[i]] = roundNumber;
                totalRewardTokenAddresses[vaultAddress].push(tokens[i]);
                _RewardTokens[vaultAddress][tokens[i]] = TRUE;
            }
        }

        //do this last
         _Rounds[vaultAddress][_CurrentRoundNumbers[vaultAddress]].endBlock = block.number;
        _CurrentRoundNumbers[vaultAddress]++;
        _Rounds[vaultAddress][_CurrentRoundNumbers[vaultAddress]].startBlock = block.number;
        
    }

    function _getAdjustedTotalSupply(uint totalSupply, uint totalUnstaking, bool ignoreUnstaking) internal pure returns(uint) {
        if(ignoreUnstaking) {
            return totalSupply;
        }
        return (totalUnstaking > totalSupply ? 0 : totalSupply.sub(totalUnstaking));
    }

}

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./../BaseContract.sol";
import "./../GovernanceDistribution.sol";

contract StakeData is BaseContract
{    
    using SafeMathUpgradeable for uint;

    function startUnstakeForAddress(address vaultAddress, address account, uint256 value) external  {
        require( 
            ( _AccountStakes[vaultAddress][account].total.sub(_AccountUnstakingTotals[vaultAddress][account]) ) 
            >= value);

        _AccountUnstakingTotals[vaultAddress][account] =_AccountUnstakingTotals[vaultAddress][account].add(value);
        VaultLib.UnStaking memory unstaking = VaultLib.UnStaking(account, value, block.timestamp, block.number, 0 );
        _AccountUnstakings[vaultAddress][account].push(unstaking);
        _UnstakingRequests[vaultAddress].push(unstaking);
        _UnstakingAddresses[vaultAddress].push(account);
        _TotalUnstakingKeys[vaultAddress].push(block.number);
        _TotalUnstakingHistory[vaultAddress][block.number]  = unstaking;
    }

    function authoriseUnstake(address vaultAddress, address account, uint timestamp) external {
        uint amount = 0;        
        for(uint i = 0; i < _AccountUnstakings[vaultAddress][account].length; i++){
            if(_AccountUnstakings[vaultAddress][account][i].startDateTime == timestamp) {
                amount = _AccountUnstakings[vaultAddress][account][i].amount;
                _AccountUnstakedTotals[vaultAddress][account] = _AccountUnstakedTotals[vaultAddress][account] + amount;
                _AccountUnstakings[vaultAddress][account][i].endBlock = block.number;
                _AccountUnstakingTotals[vaultAddress][account] = _AccountUnstakingTotals[vaultAddress][account] - amount;
                _TotalUnstakedWnxm[vaultAddress] = _TotalUnstakedWnxm[vaultAddress].add(amount);
                break;
            }
        }

        for(uint i = 0; i < _UnstakingRequests[vaultAddress].length; i++){
            if(_UnstakingRequests[vaultAddress][i].startDateTime == timestamp &&
                _UnstakingRequests[vaultAddress][i].amount == amount &&
                _UnstakingRequests[vaultAddress][i].endBlock == 0 &&
                _UnstakingAddresses[vaultAddress][i] == account) 
            {
                    delete _UnstakingAddresses[vaultAddress][i];
                    _UnstakingRequests[vaultAddress][i].endBlock = block.number;
                    _TotalUnstakingHistory[vaultAddress]
                        [_UnstakingRequests[vaultAddress][i].startBlock].endBlock = block.number;
            }
        }
        
        _AccountStakes[vaultAddress][account].total = _AccountStakes[vaultAddress][account].total.sub(amount);
        _AccountStakes[vaultAddress][account].stakes.push(VaultLib.Staking(block.timestamp, block.number, amount, _AccountStakes[vaultAddress][account].total));
        _governanceDistributionContract().removeStake(account, amount);
        
    }

    function createStake(address vaultAddress, uint amount, address account) external {

        if( _AccountStakes[vaultAddress][account].startRound == 0) {
            _AccountStakes[vaultAddress][account].startRound = _CurrentRoundNumbers[vaultAddress];
            _AccountStakesAddresses[vaultAddress].push(account);
        }

        _AccountStakes[vaultAddress][account].total = _AccountStakes[vaultAddress][account].total.add(amount);
        // block number is being used to record the block at which staking started for governance token distribution
        _AccountStakes[vaultAddress][account].stakes.push(
            VaultLib.Staking(block.timestamp, block.number, amount, _AccountStakes[vaultAddress][account].total)
        );
        _governanceDistributionContract().addStake(account, amount);
    }

    function removeStake(address vaultAddress, uint amount, address account) external {

        if( _AccountStakes[vaultAddress][account].startRound == 0) {
            _AccountStakes[vaultAddress][account].startRound = _CurrentRoundNumbers[vaultAddress];
             _AccountStakesAddresses[vaultAddress].push(account);
        }

        require(_AccountStakes[vaultAddress][account].total >= amount);

        _AccountStakes[vaultAddress][account].total = _AccountStakes[vaultAddress][account].total.sub(amount);
        // block number is being used to record the block at which staking started for governance token distribution
        _AccountStakes[vaultAddress][account].stakes.push(
            VaultLib.Staking(block.timestamp, block.number, amount, _AccountStakes[vaultAddress][account].total)
        );
        _governanceDistributionContract().removeStake(account, amount);
    }

    function _governanceDistributionAddress() internal view returns(address) {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        return vaultFactory.getGovernanceDistributionAddress();
    }

    function _governanceDistributionContract() internal view returns(GovernanceDistribution) {
        return GovernanceDistribution(_governanceDistributionAddress());
    }

    function getTotalUnstakingsForBlockRange(address vaultAddress, uint endBlock, uint startBlock) external view returns(uint) {
         // If we have bad data, no supply data or it starts after the block we are looking for then we can return zero
        if(endBlock < startBlock 
            || _TotalUnstakingKeys[vaultAddress].length == 0 
            || _TotalUnstakingKeys[vaultAddress][0] > endBlock){
            return 0;
        }

        uint lastIndex = _TotalUnstakingKeys[vaultAddress].length - 1;
        uint total;
        uint diff;
        uint stakeEnd;
        uint stakeStart;
        if(_TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].endBlock < startBlock
            && lastIndex == 0) {
            return 0;
        }
        
        //last index should now be in our range so loop through until all block numbers are covered
        while( lastIndex >= 0 ) {

            if( _TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].endBlock < startBlock &&
                _TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].endBlock != 0 )
            {
                if (lastIndex == 0) {
                    break;
                }
                lastIndex = lastIndex.sub(1);
                continue;
            }

            stakeEnd = _TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].endBlock == 0 
                ? endBlock : _TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].endBlock;

            stakeEnd = (stakeEnd >= endBlock ? endBlock : stakeEnd);

            stakeStart = _TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].startBlock < startBlock 
                ? startBlock : _TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].startBlock;
            
            diff = (stakeEnd == stakeStart ? 1 : stakeEnd.sub(stakeStart));
           
            total = total.add(_TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].amount.mul(diff));
           

            if(lastIndex == 0){
                break;
            } 

            lastIndex = lastIndex.sub(1); 
        }

        return total;
    }

    function getTotalSupplyForBlockRange(address vaultAddress, uint endBlock, uint startBlock) external view returns(uint) {

        // If we have bad data, no supply data or it starts after the block we are looking for then we can return zero
        if(endBlock < startBlock 
            || _TotalSupplyKeys[vaultAddress].length == 0 
            || _TotalSupplyKeys[vaultAddress][0] > endBlock){
            return 0;
        }
        uint lastIndex = _TotalSupplyKeys[vaultAddress].length - 1;
        
        // If the last total supply is before the start we are looking for we can take the last value
        if(_TotalSupplyKeys[vaultAddress][lastIndex] <= startBlock){
            return _TotalSupplyHistory[vaultAddress][_TotalSupplyKeys[vaultAddress][lastIndex]].mul(endBlock.sub(startBlock));
        }

        // working our way back we need to get the first index that falls into our range
        // This could be large so need to think of a better way to get here
        while(lastIndex > 0 && _TotalSupplyKeys[vaultAddress][lastIndex] > endBlock){
            if(lastIndex == 0){
                break;
            } 
            lastIndex = lastIndex.sub(1);
        }

        uint total;
        uint diff;
        //last index should now be in our range so loop through until all block numbers are covered
       
        while(_TotalSupplyKeys[vaultAddress][lastIndex] >= startBlock) {  
            diff = 0;
            if(_TotalSupplyKeys[vaultAddress][lastIndex] <= startBlock){
                diff = endBlock.sub(startBlock) == 0 ? 1 : endBlock.sub(startBlock);
                total = total.add(_TotalSupplyHistory[vaultAddress][_TotalSupplyKeys[vaultAddress][lastIndex]].mul(diff));
                break;
            }
            
            diff = endBlock.sub(_TotalSupplyKeys[vaultAddress][lastIndex]) == 0 ? 1 : endBlock.sub(_TotalSupplyKeys[vaultAddress][lastIndex]);
            total = total.add(_TotalSupplyHistory[vaultAddress][_TotalSupplyKeys[vaultAddress][lastIndex]].mul(diff));
            endBlock = _TotalSupplyKeys[vaultAddress][lastIndex];

            if(lastIndex == 0){
                break;
            } 

            lastIndex = lastIndex.sub(1); 
        }

        // If the last total supply is before the start we are looking for we can take the last value
        if(_TotalSupplyKeys[vaultAddress][lastIndex] <= startBlock && startBlock < endBlock){
            total = total.add(_TotalSupplyHistory[vaultAddress][_TotalSupplyKeys[vaultAddress][lastIndex]].mul(endBlock.sub(startBlock)));
        }
 
        return total;
    }

}

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./StakingData.sol";
import "./../iTrustVaultFactory.sol";
import { ITrustVaultLib as VaultLib } from "./../libraries/ItrustVaultLib.sol"; 
contract Vault is  
    ERC20Upgradeable 
{
    using SafeMathUpgradeable for uint;

    uint8 internal constant FALSE = 0;
    uint8 internal constant TRUE = 1;
    uint8 internal _Locked;

    uint internal _RewardCommission;
    uint internal _AdminFee;    
    address internal _NXMAddress;
    address internal _WNXMAddress;
    address payable internal _VaultWalletAddress;
    address payable internal _TreasuryAddress;
    address internal _StakingDataAddress;
    address internal _BurnDataAddress;
    address internal _iTrustFactoryAddress;
    mapping (address => uint256) internal _ReentrantCheck;
    mapping(address => mapping(string => bool)) internal _UsedNonces;

    event Stake(address indexed account, address indexed tokenAddress, uint amount, uint balance, uint totalStaked);
    event UnstakedRequest(address indexed  account, uint amount, uint balance, uint totalStaked);
    event UnstakedApproved(address indexed  account, uint amount, uint balance, uint totalStaked);
    event TransferITV(
        address indexed  fromAccount, 
        address indexed toAccount, 
        uint amount, 
        uint fromBalance, 
        uint fromTotalStaked,
        uint toBalance, 
        uint toTotalStaked);
    
    function initialize(
        address nxmAddress,
        address wnxmAddress,
        address vaultWalletAddress,
        address stakingDataAddress,
        address burnDataAddress,
        string memory tokenName,
        string memory tokenSymbol,
        uint adminFee,
        uint commission,
        address treasuryAddress
    ) 
        initializer 
        external 
    {
        __ERC20_init(tokenName, tokenSymbol); 
        _Locked = FALSE;
        _NXMAddress = nxmAddress;
        _WNXMAddress = wnxmAddress;
        _VaultWalletAddress = payable(vaultWalletAddress);
        _StakingDataAddress = stakingDataAddress;
        _BurnDataAddress = burnDataAddress;
        _AdminFee = adminFee;
        _iTrustFactoryAddress = _msgSender();
        _RewardCommission = commission;
        _TreasuryAddress = payable(treasuryAddress);
    }

    /**
     * Public functions
     */

    function getAdminFee() external view returns (uint) {
        return _AdminFee;
    }

    function SetAdminFee(uint newFee) external {
        _onlyAdmin();
        _AdminFee = newFee;
    }

    function setCommission(uint newCommission) external {
        _onlyAdmin();
        _RewardCommission = newCommission;
    }

    function setTreasury(address newTreasury) external {
        _onlyAdmin();
        _TreasuryAddress = payable(newTreasury);
    }

    function depositNXM(uint256 value) external  {
        _valueCheck(value);
        _nonReentrant();
        _Locked = TRUE;
        IERC20Upgradeable nxmToken = IERC20Upgradeable(_NXMAddress);        

        _mint(
            _msgSender(),
            value
        );
        
        require(_getStakingDataContract().createStake(value, _msgSender()));
        require(nxmToken.transferFrom(_msgSender(), _VaultWalletAddress, value));        
        emit Stake(
            _msgSender(), 
            _NXMAddress, 
            value,
            balanceOf(_msgSender()),
            _getStakingDataContract().getAccountStakingTotal(_msgSender()));

        _Locked = FALSE;
    }

    function _depositRewardToken(address token, uint amount) internal {        
        require(token != address(0));   
        uint commission = 0;
        uint remain = amount;
        if (_RewardCommission != 0) {
            commission = amount.mul(_RewardCommission).div(10000);
            remain = amount.sub(commission);            
        }       

        IERC20Upgradeable tokenContract = IERC20Upgradeable(token);
        if (commission != 0) {
            require(tokenContract.transferFrom(msg.sender, _TreasuryAddress, commission));  
        }
        require(tokenContract.transferFrom(msg.sender, address(this), remain));  
    }

    function endRound(address[] calldata tokens, uint[] calldata tokenAmounts, bool[] calldata ignoreUnstakes) external {
        _onlyAdmin();
        require(tokens.length == tokenAmounts.length);
        
        require(_getStakingDataContract().endRound(tokens, tokenAmounts, ignoreUnstakes, _RewardCommission));
        for(uint i = 0; i < tokens.length; i++) {
            _depositRewardToken(tokens[i], tokenAmounts[i]);
        }
    }

    function getCurrentRoundData() external view returns(uint roundNumber, uint startBlock, uint endBlock) {
        _onlyAdmin();
       
        return _getStakingDataContract().getCurrentRoundData();
    }

    function getRoundData(uint roundNumberIn) external view returns(uint roundNumber, uint startBlock, uint endBlock) {
        _onlyAdmin();
        
        return _getStakingDataContract().getRoundData(roundNumberIn);
    }

    function getRoundRewards(uint roundNumber) external view 
    returns(
        address[] memory rewardTokens,
        uint[] memory rewardAmounts ,
        uint[] memory commissionAmounts,
        uint[] memory tokenPerDay,
        uint[] memory totalSupply              
    ) {
        _onlyAdmin();
        
        return _getStakingDataContract().getRoundRewards(roundNumber);
    }

    function depositWNXM(uint256 value) external {
        _valueCheck(value);
        _nonReentrant();
        _Locked = TRUE;
        IERC20Upgradeable wnxmToken = IERC20Upgradeable(_WNXMAddress);
        
        _mint(
            _msgSender(),
            value
        );

        require(_getStakingDataContract().createStake(value, _msgSender()));
        require(wnxmToken.transferFrom(_msgSender(), _VaultWalletAddress, value));        
        emit Stake(
            _msgSender(), 
            _WNXMAddress, 
            value,
            balanceOf(_msgSender()),
            _getStakingDataContract().getAccountStakingTotal(_msgSender()));
        _Locked = FALSE;
    }

    function startUnstake(uint256 value) external payable  {
        _nonReentrant();
        _Locked = TRUE;
        uint adminFee = _AdminFee;
        if(adminFee != 0) {
            require(msg.value == _AdminFee);
        }
        
        require(_getStakingDataContract().startUnstake(_msgSender(), value));
        if(adminFee != 0) {
            (bool sent, ) = _VaultWalletAddress.call{value: adminFee}("");
            require(sent);
        }
        emit UnstakedRequest(
            _msgSender(), 
            value,
            balanceOf(_msgSender()),
            _getStakingDataContract().getAccountStakingTotal(_msgSender()));

        _Locked = FALSE;
    }

    function getAccountStakes() external  view 
    returns(
        uint stakingTotal,
        uint unStakingTotal,
        uint[] memory unStakingAmounts,
        uint[] memory unStakingStarts            
    ) {       
        return _getStakingDataContract().getAccountStakes(_msgSender());
    }

    function getAllAcountUnstakes() external view returns (address[] memory accounts, uint[] memory startTimes, uint[] memory values) {
        _onlyAdmin();
        return _getStakingDataContract().getAllAcountUnstakes();
    }

    function getAccountUnstakedTotal() external view  returns (uint) {
        return _getStakingDataContract().getAccountUnstakedTotal(_msgSender());
    }

    function getUnstakedwNXMTotal() external view returns (uint) {
        return _getStakingDataContract().getUnstakedWxnmTotal();
    }


    function authoriseUnstakes(address[] memory account, uint[] memory timestamp, uint[] memory amounts) external {
        _onlyAdmin();        
        require(_getStakingDataContract().authoriseUnstakes(account, timestamp));  
        //for each unstake burn
        for(uint i = 0; i < account.length; i++) {
            _burn(account[i], amounts[i]); 
            emit UnstakedApproved(
                account[i], 
                amounts[i],
                balanceOf(account[i]),
                _getStakingDataContract().getAccountStakingTotal(account[i]));
        }             
    }

    function withdrawUnstakedwNXM(uint amount) external {
        _nonReentrant();
        _Locked = TRUE;
        IERC20Upgradeable wnxm = IERC20Upgradeable(_WNXMAddress);
       
        uint balance = wnxm.balanceOf(address(this));
        
        require(amount <= balance);
        require(_getStakingDataContract().withdrawUnstakedToken(_msgSender(), amount));

        require(wnxm.transfer(msg.sender, amount));
       
      //  emit ClaimUnstaked(msg.sender, amount);
        _Locked = FALSE;
    }

    function isAdmin() external view returns (bool) {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        return vaultFactory.isAddressAdmin(_msgSender());
    }
    function calculateRewards() external view returns (address[] memory rewardTokens, uint[] memory rewards) {        
        return _getStakingDataContract().calculateRewards(_msgSender());
    }

    function calculateRewardsForAccount(address account) external view returns (address[] memory rewardTokens, uint[] memory rewards) {
        _isTrustedSigner(_msgSender());
       
        return _getStakingDataContract().calculateRewards(account);
    }

    function withdrawRewards(address[] memory tokens, uint[] memory rewards, string memory nonce, bytes memory sig) external returns (bool) {
        require(!_UsedNonces[_msgSender()][nonce]);
        _nonReentrant();
        _Locked = TRUE;
        bool toClaim = false;
        for(uint x = 0; x < tokens.length; x++){
            if(rewards[x] != 0) {
                toClaim = true;
            }
        }
        require(toClaim == true);
        bytes32 abiBytes = keccak256(abi.encodePacked(_msgSender(), tokens, rewards, nonce, address(this)));
        bytes32 message = VaultLib.prefixed(abiBytes);

        address signer = VaultLib.recoverSigner(message, sig);
        _isTrustedSigner(signer);

       
        require(_getStakingDataContract().withdrawRewards(_msgSender(), tokens, rewards));
        _UsedNonces[_msgSender()][nonce] = true;

        for(uint x = 0; x < tokens.length; x++){
            if(rewards[x] != 0) {
                IERC20Upgradeable token = IERC20Upgradeable(tokens[x]); 
                require(token.balanceOf(address(this)) >= rewards[x]);
                require(token.transfer(_msgSender() ,rewards[x]));
            }
        }
        _Locked = FALSE;
        return true;
    }

    function burnTokensForAccount(address account, uint tokensToBurn) external returns(bool) {
        _nonReentrant();
        _validBurnSender();
        require(tokensToBurn > 0);
        _Locked = TRUE;
         _burn(account, tokensToBurn);
        require(_getStakingDataContract().removeStake(tokensToBurn, account));
        _Locked = FALSE;
        return true;
    }

    /**
     * @dev See {IERC20Upgradeable-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) { 
        _transfer(_msgSender(), recipient, amount);
                
        return true;
    }

    /**
     * @dev See {IERC20Upgradeable-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);   
        _approve(sender, _msgSender(), allowance(_msgSender(), sender).sub(amount));     
        return true;    
    }

    /**
     * @dev required to be allow for receiving ETH claim payouts
     */
    receive() external payable {}

    /**
     * Private functions
     */

     /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal override {
        super._mint(account, amount);
        _updateTotalSupplyForBlock();
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        _updateTotalSupplyForBlock();
    }

    function _getStakingDataContract() internal view returns (StakingData){
        return StakingData(_StakingDataAddress);
    }
    function _updateTotalSupplyForBlock() internal {
        require(_getStakingDataContract().updateTotalSupplyForDayAndBlock(totalSupply()));
    }


     /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {

        require(_getStakingDataContract().removeStake(amount, sender));
        require(_getStakingDataContract().createStake(amount, recipient));
        
        super._transfer(sender, recipient, amount);
        emit TransferITV(
            sender,
            recipient,
            amount,            
            balanceOf(sender),
            _getStakingDataContract().getAccountStakingTotal(sender),
            balanceOf(recipient),
            _getStakingDataContract().getAccountStakingTotal(recipient));            
        _updateTotalSupplyForBlock();
    }

     /**
     * Private validation functions
     */

    function _valueCheck(uint value) internal pure {
        require(value != 0, "!");
    }

    function _onlyAdmin() internal view {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        require(
            vaultFactory.isAddressAdmin(_msgSender()),
            "NTA"
        );
    }

    function _validBurnSender() internal view {
        require(
            _BurnDataAddress == _msgSender(),
            "NTB"
        );
    }

    function _isTrustedSigner(address signer) internal view {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        require(
            vaultFactory.isTrustedSignerAddress(signer),
            "NTS"
        );
    }


    function _nonReentrant() internal view {
        require(_Locked == FALSE);
    }  
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20CappedUpgradeable is Initializable, ERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    function __ERC20Capped_init(uint256 cap_) internal initializer {
        __Context_init_unchained();
        __ERC20Capped_init_unchained(cap_);
    }

    function __ERC20Capped_init_unchained(uint256 cap_) internal initializer {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 * 
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 * 
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal virtual view returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     * 
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 * 
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 * 
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 * 
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 * 
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     * 
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     * 
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     * 
     * Emits an {AdminChanged} event.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeTo(newImplementation);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal override virtual {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 * 
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     * 
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success,) = _logic.delegatecall(_data);
            require(success);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal override view returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     * 
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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

