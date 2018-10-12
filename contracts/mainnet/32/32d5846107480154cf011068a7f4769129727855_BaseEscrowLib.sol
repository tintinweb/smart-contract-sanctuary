pragma solidity ^0.4.15;

library DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint private constant DAY_IN_SECONDS = 86400;
        uint private constant YEAR_IN_SECONDS = 31536000;
        uint private constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint private constant HOUR_IN_SECONDS = 3600;
        uint private constant MINUTE_IN_SECONDS = 60;

        uint16 private constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) public constant returns (bool) {
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

        function leapYearsBefore(uint year) public constant  returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public constant  returns (uint8) {
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

        function parseTimestamp(uint timestamp) internal constant returns (_DateTime dt) {
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

        function getYear(uint timestamp) public constant returns (uint16) {
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

        function getMonth(uint timestamp) public constant returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) public constant returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) public constant returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) public constant returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) public constant returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) public constant returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) public constant returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public constant returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public constant returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public constant returns (uint timestamp) {
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

		// -1 t1 < t2
		// 0  t1 == t2
		// 1  t1 > t2
		function compareDatesWithoutTime(uint t1, uint t2) public constant returns (int res)
		{
			_DateTime memory dt1 = parseTimestamp(t1);
			_DateTime memory dt2 = parseTimestamp(t2);

			res = compareInts(dt1.year, dt2.year);
			if (res == 0)
			{
				res = compareInts(dt1.month, dt2.month);
				if (res == 0)
				{
					res = compareInts(dt1.day, dt2.day);
				}
			}
		}


		//  t2 -> MoveIn or MoveOut day in GMT, will be counted as beginning of a day
		//  t1 -> Current System DateTime
		// -1 t1 before t2
		//--------------------------------
		// 0  t1 same day as t2
		// 1  t1 after t2
		function compareDateTimesForContract(uint t1, uint t2) public constant returns (int res)
		{
		    uint endOfDay = t2 + (60 * 60 * 24);
		    res = 0;
		    
		    if (t2 <= t1 && t1 <= endOfDay)
		    {
		        res = 0;
		    }
		    else if (t2 > t1)
		    {
		        res = -1;
		    }
		    else if (t1 > endOfDay)
		    {
		        res = 1;
		    }
		}	


		// -1 n1 < n2
		// 0  n1 == n2
		// 1  n1 > n2
		function compareInts(int n1, int n2) internal constant returns (int res)
		{
			if (n1 == n2)
			{
				res = 0;
			}
			else if (n1 < n2)
			{
				res = -1;
			}
			else if (n1 > n2)
			{
				res = 1;
			}
		}
}



// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


library BaseEscrowLib
{
    struct EscrowContractState { 
		uint _CurrentDate;
		uint _CreatedDate;
		int _RentPerDay;
		uint _MoveInDate;
		uint _MoveOutDate;				
		int _TotalAmount;					
		int _SecDeposit;
		int _State;	
		uint _ActualMoveInDate;
		uint _ActualMoveOutDate;
		address _landlord;
		address _tenant;
		bool _TenantConfirmedMoveIn;		
		bool _MisrepSignaled;			
		string _DoorLockData;
		address _ContractAddress;		
		ERC20Interface _tokenApi;
		int _landlBal;
		int _tenantBal;
		int _Id;
		int _CancelPolicy;
		uint _Balance;
		string _Guid;
    }

    //Define public constants
	//Pre-Move In
	int internal constant ContractStateActive = 1;
	int internal constant ContractStateCancelledByTenant = 2;
	int internal constant ContractStateCancelledByLandlord = 3;

	//Move-In
	int internal constant ContractStateTerminatedMisrep = 4;

	//Living
	int internal constant ContractStateEarlyTerminatedByTenant = 5;
	int internal constant ContractStateEarlyTerminatedByTenantSecDep = 6;
	int internal constant ContractStateEarlyTerminatedByLandlord = 7;		

	//Move-Out
	int internal constant ContractStateTerminatedOK = 8;	
	int internal constant ContractStateTerminatedSecDep = 9;
	
	//Stages
	int internal constant ContractStagePreMoveIn = 0;
	int internal constant ContractStageLiving = 1;
	int internal constant ContractStageTermination = 2;

	//Action
	int internal constant ActionKeyTerminate = 0;
	int internal constant ActionKeyMoveIn = 1;	
	int internal constant ActionKeyTerminateMisrep = 2;	
	int internal constant ActionKeyPropOk = 3;
	int internal constant ActionKeyClaimDeposit = 4;

	//Log
	int internal constant LogMessageInfo = 0;
	int internal constant LogMessageWarning = 1;
	int internal constant LogMessageError = 2;

	event logEvent(int stage, int atype, uint timestamp, string guid, string text);


	//DEBUG or TESTNET
	//bool private constant EnableSimulatedCurrentDate = true;

	//RELEASE
	bool private constant EnableSimulatedCurrentDate = false;


	//LogEvent wrapper
	function ContractLogEvent(int stage, int atype, uint timestamp, string guid, string text) public
	{
		logEvent(stage, atype, timestamp, guid, text);
	}

	//Constant function wrappers
	function GetContractStateActive() public constant returns (int)
	{
		return ContractStateActive;
	}

	function GetContractStateCancelledByTenant() public constant returns (int)
	{
		return ContractStateCancelledByTenant;
	}

	function GetContractStateCancelledByLandlord() public constant returns (int)
	{
		return ContractStateCancelledByLandlord;
	}
	
	function GetContractStateTerminatedMisrep() public constant returns (int)
	{
		return ContractStateTerminatedMisrep;
	}

	function GetContractStateEarlyTerminatedByTenant() public constant returns (int)
	{
		return ContractStateEarlyTerminatedByTenant;
	}

	function GetContractStateEarlyTerminatedByTenantSecDep() public constant returns (int)
	{
		return ContractStateEarlyTerminatedByTenantSecDep;
	}

	function GetContractStateEarlyTerminatedByLandlord() public constant returns (int)
	{
		return ContractStateEarlyTerminatedByLandlord;		
	}

	function GetContractStateTerminatedOK() public constant returns (int)
	{
		return ContractStateTerminatedOK;	
	}

	function GetContractStateTerminatedSecDep() public constant returns (int)
	{
		return ContractStateTerminatedSecDep;
	}
	
	function GetContractStagePreMoveIn() public constant returns (int)
	{
		return ContractStagePreMoveIn;
	}

	function GetContractStageLiving() public constant returns (int)
	{
		return ContractStageLiving;
	}

	function GetContractStageTermination() public constant returns (int)
	{
		return ContractStageTermination;
	}
	
	function GetLogMessageInfo() public constant returns (int)
	{
		return LogMessageInfo;
	}

	function GetLogMessageWarning() public constant returns (int)
	{
		return LogMessageWarning;
	}

	function GetLogMessageError() public constant returns (int)
	{
		return LogMessageError;
	}


	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	function initialize(EscrowContractState storage self) {

		//Check parameters
		//all dates must be in the future

		require(self._CurrentDate < self._MoveInDate);
		require(self._MoveInDate < self._MoveOutDate);
							
		int nPotentialBillableDays = (int)(self._MoveOutDate - self._MoveInDate) / (60 * 60 * 24);
		int nPotentialBillableAmount = nPotentialBillableDays * (self._RentPerDay);
		
		//Limit 2 months stay
		require (nPotentialBillableDays <= 60); 

		self._TotalAmount = nPotentialBillableAmount + self._SecDeposit;
				
		//Sec Deposit should not be more than 30 perecent
		require (self._SecDeposit / nPotentialBillableAmount * 100 <= 30);
				

		self._TenantConfirmedMoveIn = false;
		self._MisrepSignaled = false;
		self._State = GetContractStateActive();
		self._ActualMoveInDate = 0;
		self._ActualMoveOutDate = 0;
		self._landlBal = 0;
		self._tenantBal = 0;
	}


	function TerminateContract(EscrowContractState storage self, int tenantBal, int landlBal, int state) public
	{
		int stage = GetCurrentStage(self);
		uint nCurrentDate = GetCurrentDate(self);
		int nActualBalance = int(GetContractBalance(self));

		if (nActualBalance == 0)
		{
		    //If it was unfunded, just change state
		    self._State = state;   
		}
		else if (self._State == ContractStateActive && state != ContractStateActive)
		{
			//Check if some balances are negative
			if (landlBal < 0)
			{
				tenantBal += landlBal;
				landlBal = 0;
			}

			if (tenantBal < 0) {
				landlBal += tenantBal;
				tenantBal = 0;
			}

			//Check if balances exceed total amount
			if ((landlBal + tenantBal) > nActualBalance)
			{
				var nOverrun = (landlBal + tenantBal) - self._TotalAmount;
				landlBal -= (nOverrun / 2);
				tenantBal -= (nOverrun / 2);
			}

			self._State = state;

			string memory strState = "";

			if (state == ContractStateTerminatedOK)
			{
				strState = " State is: OK";
			}
			else if (state == ContractStateEarlyTerminatedByTenant)
			{
				strState = " State is: Early terminated by tenant";
			}
			else if (state == ContractStateEarlyTerminatedByTenantSecDep)
			{
				strState = " State is: Early terminated by tenant, Security Deposit claimed";
			}
			else if (state == ContractStateEarlyTerminatedByLandlord)
			{
				strState = " State is: Early terminated by landlord";
			}
			else if (state == ContractStateCancelledByTenant)
			{
				strState = " State is: Cancelled by tenant";
			}
			else if (state == ContractStateCancelledByLandlord)
			{
				strState = " State is: Cancelled by landlord";
			}
			else if (state == ContractStateTerminatedSecDep)
			{
				strState = " State is: Security Deposit claimed";
			}
		
			
			
			bytes32 b1;
			bytes32 b2;
			b1 = uintToBytes(uint(landlBal));
			b2 = uintToBytes(uint(tenantBal));

                        /*
		    string memory s1;
		    string memory s2;	
		    s1 = bytes32ToString(b1);
		    s2 = bytes32ToString(b2);
                        */
			
			string memory strMessage = strConcat(
			    "Contract is termintaing. Landlord balance is _$b_", 
			    bytes32ToString(b1), 
			    "_$e_, Tenant balance is _$b_", 
			    bytes32ToString(b2));

            
			string memory strMessage2 = strConcat(
				strMessage,
				"_$e_.",
				strState
			);

            string memory sGuid;
            sGuid = self._Guid;
			
            logEvent(stage, LogMessageInfo, nCurrentDate, sGuid, strMessage2);
            
			//Send tokens
			self._landlBal = landlBal;
			self._tenantBal = tenantBal;
		}	
	}

	function GetCurrentStage(EscrowContractState storage self) public constant returns (int stage)
	{
		uint nCurrentDate = GetCurrentDate(self);
		uint nActualBalance = GetContractBalance(self);
        
        stage = ContractStagePreMoveIn;
        
		if (self._State == ContractStateActive && uint(self._TotalAmount) > nActualBalance)
		{
			//Contract unfunded
			stage = ContractStagePreMoveIn;
		}		
		else if (DateTime.compareDateTimesForContract(nCurrentDate, self._MoveInDate) < 0)
		{
			stage = ContractStagePreMoveIn;
		}
		else if (DateTime.compareDateTimesForContract(nCurrentDate, self._MoveInDate) >= 0 && 
		         DateTime.compareDateTimesForContract(nCurrentDate, self._MoveOutDate) < 0 && 
		         self._TenantConfirmedMoveIn)
		{
			stage = ContractStageLiving;
		}
		else if (DateTime.compareDateTimesForContract(nCurrentDate, self._MoveOutDate) >= 0)
		{
			stage = ContractStageTermination;
		}	
	}



	///Helper functions
	function SimulateCurrentDate(EscrowContractState storage self, uint n) public
	{
		if (EnableSimulatedCurrentDate)
		{
			self._CurrentDate = n;
			//int stage = GetCurrentStage(self);
			//logEvent(stage, LogMessageInfo, self._CurrentDate, "SimulateCurrentDate was called.");	
		}
	}
	
	
	
	function GetCurrentDate(EscrowContractState storage self) public constant returns (uint nCurrentDate)
	{
		if (EnableSimulatedCurrentDate)
		{
			nCurrentDate = self._CurrentDate;
		}
		else
		{
			nCurrentDate = now;
		}	
	}

	function GetContractBalance(EscrowContractState storage self) public returns (uint res)
	{
	    res = self._Balance;
	}


	function splitBalanceAccordingToRatings(int balance, int tenantScore, int landlScore) public constant returns (int tenantBal, int landlBal)
	{
		if (tenantScore == landlScore) {
			//Just split in two 
			tenantBal = balance / 2;
			landlBal = balance / 2;
		}
		else if (tenantScore == 0)
		{
			tenantBal = 0;
			landlBal = balance;			
		}
		else if (landlScore == 0) {
			tenantBal = balance;
			landlBal = 0;
		}
		else if (tenantScore > landlScore) {			
			landlBal = ((landlScore * balance / 2) / tenantScore);
			tenantBal = balance - landlBal;			
		}
		else if (tenantScore < landlScore) {			
			tenantBal = ((tenantScore * balance / 2) / landlScore);
			landlBal = balance - tenantBal;			
		}		
	}

	function formatDate(uint dt) public constant returns (string strDate)
	{
		bytes32 b1;
		bytes32 b2;
		bytes32 b3;
		b1 = uintToBytes(uint(DateTime.getMonth(dt)));
		b2 = uintToBytes(uint(DateTime.getDay(dt)));
		b3 = uintToBytes(uint(DateTime.getYear(dt)));
		string memory s1;
		string memory s2;	
		string memory s3;
		s1 = bytes32ToString(b1);
		s2 = bytes32ToString(b2);
		s3 = bytes32ToString(b3);
		
		string memory strDate1 = strConcat(s1, "/", s2, "/");
		strDate = strConcat(strDate1, s3);			
	}
	

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal constant returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
    
    function strConcat(string _a, string _b, string _c, string _d) internal constant returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }
    
    function strConcat(string _a, string _b, string _c) internal constant returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }
    
    function strConcat(string _a, string _b) internal constant returns (string) {
        return strConcat(_a, _b, "", "", "");
    } 
    
    function bytes32ToString(bytes32 x) internal constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function bytes32ArrayToString(bytes32[] data) internal constant returns (string) {
        bytes memory bytesString = new bytes(data.length * 32);
        uint urlLength;
        for (uint i=0; i<data.length; i++) {
            for (uint j=0; j<32; j++) {
                byte char = byte(bytes32(uint(data[i]) * 2 ** (8 * j)));
                if (char != 0) {
                    bytesString[urlLength] = char;
                    urlLength += 1;
                }
            }
        }
        bytes memory bytesStringTrimmed = new bytes(urlLength);
        for (i=0; i<urlLength; i++) {
            bytesStringTrimmed[i] = bytesString[i];
        }
        return string(bytesStringTrimmed);
    }  
    
    
    function uintToBytes(uint v) internal constant returns (bytes32 ret) {
        if (v == 0) {
            ret = &#39;0&#39;;
        }
        else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    /// @dev Converts a numeric string to it&#39;s unsigned integer representation.
    /// @param v The string to be converted.
    function bytesToUInt(bytes32 v) internal constant returns (uint ret) {
        if (v == 0x0) {
            throw;
        }

        uint digit;

        for (uint i = 0; i < 32; i++) {
            digit = uint((uint(v) / (2 ** (8 * (31 - i)))) & 0xff);
            if (digit == 0) {
                break;
            }
            else if (digit < 48 || digit > 57) {
                throw;
            }
            ret *= 10;
            ret += (digit - 48);
        }
        return ret;
    }    


}