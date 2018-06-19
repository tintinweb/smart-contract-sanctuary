pragma solidity 0.4.23;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title SafeMath32
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath32 {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ether Habits
 * @dev Implements the logic behind Ether Habits
 */
contract Habits {
    
    using SafeMath for uint256;
    using SafeMath32 for uint32;

    // owner is only set on contract initialization, this cannot be changed
    address internal owner;
    mapping (address => bool) internal adminPermission;
    
    uint256 constant REGISTRATION_FEE = 0.005 ether;  // deposit for a single day
    uint32 constant NUM_REGISTER_DAYS = 10;  // default number of days for registration
    uint32 constant NINETY_DAYS = 90 days;
    uint32 constant WITHDRAW_BUFFER = 129600;  // time before user can withdraw deposit
    uint32 constant MAY_FIRST_2018 = 1525132800;
    uint32 constant DAY = 86400;

    enum UserEntryStatus {
        NULL,
        REGISTERED,
        COMPLETED,
        WITHDRAWN
    }

    struct DailyContestStatus {
        uint256 numRegistered;
        uint256 numCompleted;
        bool operationFeeWithdrawn;
    }

    mapping (address => uint32[]) internal userToDates;
    mapping (uint32 => address[]) internal dateToUsers;
    mapping (address => mapping (uint32 => UserEntryStatus)) internal userDateToStatus;
    mapping (uint32 => DailyContestStatus) internal dateToContestStatus;

    event LogWithdraw(address user, uint256 amount);
    event LogOperationFeeWithdraw(address user, uint256 amount);

    /**
     * @dev Sets the contract creator as the owner. Owner can&#39;t be changed in the future
     */
    function Habits() public {
        owner = msg.sender;
        adminPermission[owner] = true;
    }

    /**
     * @dev Registers a user for NUM_REGISTER_DAYS days
     * @notice Changes state
     * @param _expectedStartDate (unix time: uint32) Start date the user had in mind when submitting the transaction
     */
    function register(uint32 _expectedStartDate) external payable {
        // throw if sent ether doesn&#39;t match the total registration fee
        require(REGISTRATION_FEE.mul(NUM_REGISTER_DAYS) == msg.value);

        // can&#39;t register more than 100 days in advance
        require(_expectedStartDate <= getDate(uint32(now)).add(NINETY_DAYS));

        uint32 startDate = getStartDate();
        // throw if actual start day doesn&#39;t match the user&#39;s expectation
        // may happen if a transaction takes a while to get mined
        require(startDate == _expectedStartDate);

        for (uint32 i = 0; i < NUM_REGISTER_DAYS; i++) {
            uint32 date = startDate.add(i.mul(DAY));

            // double check that user already hasn&#39;t been registered
            require(userDateToStatus[msg.sender][date] == UserEntryStatus.NULL);

            userDateToStatus[msg.sender][date] = UserEntryStatus.REGISTERED;
            userToDates[msg.sender].push(date);
            dateToUsers[date].push(msg.sender);
            dateToContestStatus[date].numRegistered += 1;
        }
    }

    /**
     * @dev Checks-in a user for a given day
     * @notice Changes state
     */
    function checkIn() external {
        uint32 nowDate = getDate(uint32(now));

        // throw if user entry status isn&#39;t registered
        require(userDateToStatus[msg.sender][nowDate] == UserEntryStatus.REGISTERED);
        userDateToStatus[msg.sender][nowDate] = UserEntryStatus.COMPLETED;
        dateToContestStatus[nowDate].numCompleted += 1;
    }

    /**
     * @dev Allow users to withdraw deposit and bonus for checked-in dates
     * @notice Changes state
     * @param _dates Array of dates user wishes to withdraw for, this is
     * calculated beforehand and verified in this method to reduce gas costs
     */
    function withdraw(uint32[] _dates) external {
        uint256 withdrawAmount = 0;
        uint256 datesLength = _dates.length;
        uint32 now32 = uint32(now);
        for (uint256 i = 0; i < datesLength; i++) {
            uint32 date = _dates[i];
            // if it hasn&#39;t been more than 1.5 days since the entry, skip
            if (now32 <= date.add(WITHDRAW_BUFFER)) {
                continue;
            }
            // if the entry status is anything other than COMPLETED, skip
            if (userDateToStatus[msg.sender][date] != UserEntryStatus.COMPLETED) {
                continue;
            }

            // set status to WITHDRAWN to prevent re-entry
            userDateToStatus[msg.sender][date] = UserEntryStatus.WITHDRAWN;
            withdrawAmount = withdrawAmount.add(REGISTRATION_FEE).add(calculateBonus(date));
        }

        if (withdrawAmount > 0) {
           msg.sender.transfer(withdrawAmount);
        }
        LogWithdraw(msg.sender, withdrawAmount);
    }

    /**
     * @dev Calculate current withdrawable amount for a user
     * @notice Doesn&#39;t change state
     * @return Amount of withdrawable Wei
     */
    function calculateWithdrawableAmount() external view returns (uint256) {
        uint32[] memory dates = userToDates[msg.sender];
        uint256 datesLength = dates.length;
        uint256 withdrawAmount = 0;
        uint32 now32 = uint32(now);
        for (uint256 i = 0; i < datesLength; i++) {
            uint32 date = dates[i];
            // if it hasn&#39;t been more than 1.5 days since the entry, skip
            if (now32 <= date.add(WITHDRAW_BUFFER)) {
                continue;
            }
            // if the entry status is anything other than COMPLETED, skip
            if (userDateToStatus[msg.sender][date] != UserEntryStatus.COMPLETED) {
                continue;
            }
            withdrawAmount = withdrawAmount.add(REGISTRATION_FEE).add(calculateBonus(date));
        }

        return withdrawAmount;
    }

    /**
     * @dev Calculate dates that a user can withdraw his/her deposit
     * array may contain zeros so those need to be filtered out by the client
     * @notice Doesn&#39;t change state
     * @return Array of dates (unix time: uint32)
     */
    function getWithdrawableDates() external view returns(uint32[]) {
        uint32[] memory dates = userToDates[msg.sender];
        uint256 datesLength = dates.length;
        // We can&#39;t initialize a mutable array in memory, so creating an array
        // with length set as the number of regsitered days
        uint32[] memory withdrawableDates = new uint32[](datesLength);
        uint256 index = 0;
        uint32 now32 = uint32(now);

        for (uint256 i = 0; i < datesLength; i++) {
            uint32 date = dates[i];
            // if it hasn&#39;t been more than 1.5 days since the entry, skip
            if (now32 <= date.add(WITHDRAW_BUFFER)) {
                continue;
            }
            // if the entry status is anything other than COMPLETED, skip
            if (userDateToStatus[msg.sender][date] != UserEntryStatus.COMPLETED) {
                continue;
            }
            withdrawableDates[index] = date;
            index += 1;
        }

        // this array may contain zeroes at the end of the array
        return withdrawableDates;
    }

    /**
     * @dev Return registered days and statuses for a user
     * @notice Doesn&#39;t change state
     * @return Tupple of two arrays (dates registered, statuses)
     */
    function getUserEntryStatuses() external view returns (uint32[], uint32[]) {
        uint32[] memory dates = userToDates[msg.sender];
        uint256 datesLength = dates.length;
        uint32[] memory statuses = new uint32[](datesLength);

        for (uint256 i = 0; i < datesLength; i++) {
            statuses[i] = uint32(userDateToStatus[msg.sender][dates[i]]);
        }
        return (dates, statuses);
    }

    /**
     * @dev Withdraw operation fees for a list of dates
     * @notice Changes state, owner only
     * @param _dates Array of dates to withdraw operation fee
     */
    function withdrawOperationFees(uint32[] _dates) external {
        // throw if sender isn&#39;t contract owner
        require(msg.sender == owner);

        uint256 withdrawAmount = 0;
        uint256 datesLength = _dates.length;
        uint32 now32 = uint32(now);

        for (uint256 i = 0; i < datesLength; i++) {
            uint32 date = _dates[i];
            // if it hasn&#39;t been more than 1.5 days since the entry, skip
            if (now32 <= date.add(WITHDRAW_BUFFER)) {
                continue;
            }
            // if already withdrawn for given date, skip
            if (dateToContestStatus[date].operationFeeWithdrawn) {
                continue;
            }
            // set operationFeeWithdrawn to true to prevent re-entry
            dateToContestStatus[date].operationFeeWithdrawn = true;
            withdrawAmount = withdrawAmount.add(calculateOperationFee(date));
        }

        if (withdrawAmount > 0) {
            msg.sender.transfer(withdrawAmount);
        }
        LogOperationFeeWithdraw(msg.sender, withdrawAmount);
    }

    /**
     * @dev Get total withdrawable operation fee amount and dates, owner only
     * array may contain zeros so those need to be filtered out by the client
     * @notice Doesn&#39;t change state
     * @return Tuple(Array of dates (unix time: uint32), amount)
     */
    function getWithdrawableOperationFeeDatesAndAmount() external view returns (uint32[], uint256) {
        // throw if sender isn&#39;t contract owner
        if (msg.sender != owner) {
            return (new uint32[](0), 0);
        }

        uint32 cutoffTime = uint32(now).sub(WITHDRAW_BUFFER);
        uint32 maxLength = cutoffTime.sub(MAY_FIRST_2018).div(DAY).add(1);
        uint32[] memory withdrawableDates = new uint32[](maxLength);
        uint256 index = 0;
        uint256 withdrawAmount = 0;
        uint32 date = MAY_FIRST_2018;

        while(date < cutoffTime) {
            if (!dateToContestStatus[date].operationFeeWithdrawn) {
                uint256 amount = calculateOperationFee(date);
                if (amount > 0) {
                    withdrawableDates[index] = date;
                    withdrawAmount = withdrawAmount.add(amount);
                    index += 1;
                }
            }
            date = date.add(DAY);
        } 
        return (withdrawableDates, withdrawAmount);
    }

    /**
     * @dev Get contest status, only return complete and bonus numbers if it&#39;s been past the withdraw buffer
     * Return -1 for complete and bonus numbers if still before withdraw buffer
     * @notice Doesn&#39;t change state
     * @param _date Date to get DailyContestStatus for
     * @return Tuple(numRegistered, numCompleted, bonus)
     */
    function getContestStatusForDate(uint32 _date) external view returns (int256, int256, int256) {
        DailyContestStatus memory dailyContestStatus = dateToContestStatus[_date];
        int256 numRegistered = int256(dailyContestStatus.numRegistered);
        int256 numCompleted = int256(dailyContestStatus.numCompleted);
        int256 bonus = int256(calculateBonus(_date));

        if (uint32(now) <= _date.add(WITHDRAW_BUFFER)) {
            numCompleted = -1;
            bonus = -1;
        }
        return (numRegistered, numCompleted, bonus);
    }

    /**
     * @dev Get next valid start date.
     * Tomorrow or the next non-registered date is the next start date
     * @notice Doesn&#39;t change state
     * @return Next start date (unix time: uint32)
     */
    function getStartDate() public view returns (uint32) {
        uint32 startDate = getNextDate(uint32(now));
        uint32 lastRegisterDate = getLastRegisterDate();
        if (startDate <= lastRegisterDate) {
            startDate = getNextDate(lastRegisterDate);
        }
        return startDate;
    }

    /**
     * @dev Get the next UTC midnight date
     * @notice Doesn&#39;t change state
     * @param _timestamp (unix time: uint32)
     * @return Next date (unix time: uint32)
     */
    function getNextDate(uint32 _timestamp) internal pure returns (uint32) {
        return getDate(_timestamp.add(DAY));
    }

    /**
     * @dev Get the date floor (UTC midnight) for a given timestamp
     * @notice Doesn&#39;t change state
     * @param _timestamp (unix time: uint32)
     * @return UTC midnight date (unix time: uint32)
     */
    function getDate(uint32 _timestamp) internal pure returns (uint32) {
        return _timestamp.sub(_timestamp % DAY);
    }

    /**
     * @dev Get the last registered date for a user
     * @notice Doesn&#39;t change state
     * @return Last registered date (unix time: uint32), 0 if user has never registered
     */
    function getLastRegisterDate() internal view returns (uint32) {
        uint32[] memory dates = userToDates[msg.sender];
        uint256 pastRegisterCount = dates.length;

        if(pastRegisterCount == 0) {
            return 0;
        }
        return dates[pastRegisterCount.sub(1)];
    }

    /**
     * @dev Calculate the bonus for a given day
     * @notice Doesn&#39;t change state
     * @param _date Date to calculate the bonus for (unix time: uint32)
     * @return Bonus amount (unit256)
     */ 
    function calculateBonus(uint32 _date) internal view returns (uint256) {
        DailyContestStatus memory status = dateToContestStatus[_date];
        if (status.numCompleted == 0) {
            return 0;
        }
        uint256 numFailed = status.numRegistered.sub(status.numCompleted);
        // Split 90% of the forfeited deposits between completed users
        return numFailed.mul(REGISTRATION_FEE).mul(9).div(
            status.numCompleted.mul(10)
        );
    }

    /**
     * @dev Calculate the operation fee for a given day
     * @notice Doesn&#39;t change state
     * @param _date Date to calculate the operation fee for (unix time: uint32)
     * @return Operation fee amount (unit256)
     */ 
    function calculateOperationFee(uint32 _date) internal view returns (uint256) {
        DailyContestStatus memory status = dateToContestStatus[_date];
        // if no one has completed, take all as operation fee
        if (status.numCompleted == 0) {
            return status.numRegistered.mul(REGISTRATION_FEE);
        }
        uint256 numFailed = status.numRegistered.sub(status.numCompleted);
        // 10% of forefeited deposits 
        return numFailed.mul(REGISTRATION_FEE).div(10);
    }

    /********************
     * Admin only methods
     ********************/

    /**
     * @dev Adding an admin, owner only
     * @notice Changes state
     * @param _newAdmin Address of new admin
     */ 
    function addAdmin(address _newAdmin) external {
        require(msg.sender == owner);
        adminPermission[_newAdmin] = true;
    }

    /**
     * @dev Return all registered dates for a user, admin only
     * @notice Doesn&#39;t change state
     * @param _user User to get dates for
     * @return All dates(uint32[]) the user registered for
     */ 
    function getDatesForUser(address _user) external view returns (uint32[]) {
        if (!adminPermission[msg.sender]) {
           return new uint32[](0); 
        }
        return userToDates[_user];
    }

    /**
     * @dev Return all registered users for a date, admin only
     * @notice Doesn&#39;t change state
     * @param _date Date to get users for
     * @return All users(address[]) registered on a given date
     */ 
    function getUsersForDate(uint32 _date) external view returns (address[]) {
        if (!adminPermission[msg.sender]) {
           return new address[](0); 
        }
        return dateToUsers[_date];
    }

    /**
     * @dev Return entry status for a user and date, admin only
     * @notice Doesn&#39;t change state
     * @param _user User to get EntryStatus for
     * @param _date (unix time: uint32) Date to get EntryStatus for
     * @return UserEntryStatus
     */ 
    function getEntryStatus(address _user, uint32 _date)
    external view returns (UserEntryStatus) {
        if (!adminPermission[msg.sender]) {
            return UserEntryStatus.NULL;
        }
        return userDateToStatus[_user][_date];
    }

    /**
     * @dev Get daily contest status, admin only
     * @notice Doesn&#39;t change state
     * @param _date Date to get DailyContestStatus for
     * @return Tuple(uint256, uint256, bool)
     */
    function getContestStatusForDateAdmin(uint32 _date)
    external view returns (uint256, uint256, bool) {
        if (!adminPermission[msg.sender]) {
            return (0, 0, false);
        }
        DailyContestStatus memory dailyContestStatus = dateToContestStatus[_date];
        return (
            dailyContestStatus.numRegistered,
            dailyContestStatus.numCompleted,
            dailyContestStatus.operationFeeWithdrawn
        );
    }
}