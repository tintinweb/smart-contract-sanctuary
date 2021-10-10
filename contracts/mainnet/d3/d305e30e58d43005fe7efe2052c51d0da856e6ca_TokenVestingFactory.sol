// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(year >= 1970, "BP01");
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
        require(newTimestamp >= timestamp, "BP02");
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
        require(newTimestamp >= timestamp, "BP02");
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp, "BP02");
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp, "BP02");
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp, "BP02");
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp, "BP02");
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp, "BP03");
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
        require(newTimestamp <= timestamp, "BP03");
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp, "BP03");
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp, 'BP03');
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp, 'BP03');
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp, 'BP03');
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp, 'BP03');
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp, 'BP03');
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp, 'BP03');
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp, 'BP03');
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp, 'BP03');
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp, 'BP03');
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract MultiSig {

    event setupEvent(address[] signers, uint256 threshold);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event ExecutionFailure(bytes32 txHash);
    event ExecutionSuccess(bytes32 txHash);
    event signerAddEvent(address signer);
    event signerRemoveEvent(address signer);
    event signerChangedEvent(address oldSigner, address newSigner);
    event thresholdEvent(uint256 threshold);
    event eventAlreadySigned(address indexed signed);


    address[] private _signers;

    // Mapping to keep track of all hashes (message or transaction) that have been approved by ANY signers
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

    uint256 internal _threshold;
    uint256 public _nonce;
    bytes32 public _currentHash;

    /**
     * @dev Throws if called by any account other than the this contract address.
     */
    modifier onlyMultiSig() {
        require(msg.sender == address(this), "Only Multisig contract can run this method");
        _;
    }

    constructor () {

    }

    /**
     * @dev setup the multisig contract.
     * @param signers List of signers.
     * @param threshold The minimum required sign for executing a transaction.
     */    
    function setupMultiSig(
        address[] memory signers,
        uint256 threshold
    ) internal {
        require(_threshold == 0, "MS11");
        require(threshold <= signers.length, "MS01");
        require(threshold > 1, "MS02");

        address signer;
        for (uint256 i = 0; i < signers.length; i++) {
            signer = signers[i];
            require(!existSigner(signer), "MS03");
            require(signer != address(0), "MS04");
            require(signer != address(this), "MS05");

            _signers.push(signer);
        }

        _threshold = threshold;
        emit setupEvent(_signers, _threshold);
    }

    /**
     * @dev Allows to execute a Safe transaction confirmed by required number of signers.
     * @param data Data payload of transaction.
     */
    function execTransaction(
        bytes calldata data
    ) external returns (bool success) {
        bytes32 txHash;
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            bytes memory txHashData =
            encodeTransactionData(
            // Transaction info
                data,
                _nonce
            );
            // Increase nonce and execute transaction.
            _nonce++;
            _currentHash = 0x0;
            txHash = keccak256(txHashData);
            checkSignatures(txHash);
        }
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {            
            success = execute(data);
            if (success) emit ExecutionSuccess(txHash);
            else emit ExecutionFailure(txHash);
        }
    }

    
    /**
     * @dev Get the current value of nonce
     */
    function getNonce() external view returns (uint256){
        return _nonce;
    }


    /**
     * @dev Execute a transaction
     * @param data the encoded data of the transaction
     */
    function execute(
        bytes memory data
    ) internal returns (bool success) {
        address to = address (this);
        // We require some gas to emit the events (at least 2500) after the execution
        uint256 gasToCall = gasleft() - 2500;
        assembly {
            success := call(gasToCall, to, 0, add(data, 0x20), mload(data), 0, 0)
        }
    }

    
    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data
     */
    function checkSignatures(bytes32 dataHash) public view {
        uint256 threshold = _threshold;
        // Check that a threshold is set
        require(threshold > 1, "MS02");
        address[] memory alreadySigned = getSignersOfHash(dataHash);

        require(alreadySigned.length >= threshold, "MS06");
    }

    
    /**
     * @dev Return the list of signers for a given hash
     * @param hash Hash of the data
     */
    function getSignersOfHash(
        bytes32 hash
    ) public view returns (address[] memory) {
        uint256 j = 0;
        address[] memory doneSignersTemp = new address[](_signers.length);

        uint256 i;
        address currentSigner;
        for (i = 0; i < _signers.length; i++) {
            currentSigner = _signers[i];
            if (approvedHashes[currentSigner][hash] == 1) {
                doneSignersTemp[j] = currentSigner;
                j++;
            }
        }
        address[] memory doneSigners = new address[](j);
        for (i=0; i < j; i++){
            doneSigners[i] = doneSignersTemp[i];
        }
        return doneSigners;
    }

    /**
     * @dev Marks a hash as approved. This can be used to validate a hash that is used by a signature.
     * @param data Data payload.
     */
    function approveHash(
        bytes calldata data
    ) external {
        require(existSigner(msg.sender), "MS07");

        bytes32 hashToApprove = getTransactionHash(data, _nonce);
        bytes32 hashToCancel = getCancelTransactionHash(_nonce);
        
        if(_currentHash == 0x0) {
            require(hashToApprove != hashToCancel, "MS12");
            _currentHash = hashToApprove;
        }
        else {
            require(_currentHash == hashToApprove || hashToApprove == hashToCancel, "MS13");
        }
        
        approvedHashes[msg.sender][hashToApprove] = 1;
        emit ApproveHash(hashToApprove, msg.sender);
    }


    /**
     * @dev Returns the bytes that are hashed to be signed by owners.
     * @param data Data payload.
     * @param nonce Transaction nonce.
     */    
    function encodeTransactionData(
        bytes calldata data,
        uint256 nonce
    ) public pure returns (bytes memory) {
        bytes32 safeTxHash =
        keccak256(
            abi.encode(
                keccak256(data),
                nonce
            )
        );
        return abi.encodePacked(safeTxHash);
    }

    function encodeCancelTransactionData(
        uint256 nonce
    ) public pure returns (bytes memory) {
        bytes32 safeTxHash =
        keccak256(
            abi.encode(
                keccak256(""),
                nonce
            )
        );
        return abi.encodePacked(safeTxHash);
    }

    /**
     * @dev Returns hash to be signed by owners.
     * @param data Data payload.
     */
    function getTransactionHash(
        bytes calldata data,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(encodeTransactionData(data, nonce));
    }

    function getCancelTransactionHash(
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(encodeCancelTransactionData(nonce));
    }

    
    /**
     * @dev Check if a given address is a signer or not.
     * @param signer signer address.     
     */
    function existSigner(
        address signer
    ) public view returns (bool) {
        for (uint256 i = 0; i < _signers.length; i++) {
            address signerI = _signers[i];
            if (signerI == signer) {
                return true;
            }
        }
        return false;
    }

    
    /**
     * @dev Get the list of all signers.     
     */
    function getSigners() external view returns (address[] memory ) {
        address[] memory ret = new address[](_signers.length) ;
        for (uint256 i = 0; i < _signers.length; i++) {
            ret[i] = _signers[i];
        }
        return ret;
    }

    
    /**
     * @dev Set a new threshold for signing.
     * @param threshold the minimum required signatures for executing a transaction.     
     */
    function setThreshold(
        uint256 threshold
    ) public onlyMultiSig{
        require(threshold <= _signers.length, "MS01");
        require(threshold > 1, "MS02");
        _threshold = threshold;
        emit thresholdEvent(threshold);
    }

    
    /**
     * @dev Get threshold value.
     */
    function getThreshold() external view returns(uint256) {
        return _threshold;
    }

    
    /**
     * @dev Add a new signer and new threshold.
     * @param signer new signer address.   
     * @param threshold new threshold  
     */
    function addSigner(
        address signer,
        uint256 threshold
    ) external onlyMultiSig{
        require(!existSigner(signer), "MS03");
        require(signer != address(0), "MS04");
        require(signer != address(this), "MS05");
        _signers.push(signer);
        emit signerAddEvent(signer);
        setThreshold(threshold);
    }


    /**
     * @dev Remove an old signer
     * @param signer an old signer.     
     * @param threshold new threshold
     */
    function removeSigner(
        address signer,
        uint256 threshold
    ) external onlyMultiSig{
        require(existSigner(signer), "MS07");
        require(_signers.length - 1 > 1, "MS09");
        require(_signers.length - 1 >= threshold, "MS10");
        require(signer != address(0), "MS04");
 
        for (uint256 i = 0; i < _signers.length - 1; i++) {
            if (_signers[i] == signer) {
                _signers[i] = _signers[_signers.length - 1];
                break;
            }
        }
        
        _signers.pop();
        emit signerRemoveEvent(signer);
        setThreshold(threshold);
    }

    
    /**
     * @dev Replace an old signer with a new one
     * @param oldSigner old signer.     
     * @param newSigner new signer
     */
    function changeSigner(
        address oldSigner,
        address newSigner
    ) external onlyMultiSig{
        require(existSigner(oldSigner), "MS07");
        require(!existSigner(newSigner), "MS03");
        require(newSigner != address(0), "MS04");
        require(newSigner != address(this), "MS05");
        
        for (uint256 i = 0; i < _signers.length; i++) {
            if (_signers[i] == oldSigner) {
                _signers[i] = newSigner;
                break;
            }
        }

        emit signerChangedEvent(oldSigner, newSigner);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



import "./MultiSig.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "onlyOwner");
        _;
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Returns the address of the pending owner.
    */
    function pendingOwner() external view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() external {
        require(msg.sender == _pendingOwner, "onlyPendingOwner");
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }
}

contract TokenVestingFactory is Ownable, MultiSig {


    event TokenVestingCreated(address tokenVesting);

    // enum VestingType { SeedInvestors, StrategicInvestors, Advisors, Team, All }

    struct BeneficiaryIndex {
        address tokenVesting;
        uint256 vestingType;
        bool isExist;
        // uint256 index;
    }

    mapping(address => BeneficiaryIndex) private _beneficiaryIndex;
    address[] private _beneficiaries;
    address private _tokenAddr;
    uint256 private _decimal;

    constructor (address tokenAddr, uint256 decimal, address[] memory owners, uint256 threshold) {
        require(tokenAddr != address(0), "TokenVestingFactory: token address must not be zero");

        _tokenAddr = tokenAddr;
        _decimal = decimal;
        setupMultiSig(owners, threshold);
    }

    function create(address beneficiary, uint256 start, uint256 cliff, uint256 initialShare, uint256 periodicShare, bool revocable, uint256 vestingType) onlyOwner external {
        require(!_beneficiaryIndex[beneficiary].isExist, "TokenVestingFactory: benficiery exists");
        require(vestingType != 0, "TokenVestingFactory: vestingType 0 is reserved");

        address tokenVesting = address(new TokenVesting(_tokenAddr, beneficiary, start, cliff, initialShare, periodicShare, _decimal, revocable));

        _beneficiaries.push(beneficiary);
        _beneficiaryIndex[beneficiary].tokenVesting = tokenVesting;
        _beneficiaryIndex[beneficiary].vestingType = vestingType;
        _beneficiaryIndex[beneficiary].isExist = true;

        emit TokenVestingCreated(tokenVesting);
    }

    function initialize(address tokenVesting, address from, uint256 amount) external onlyOwner {
        TokenVesting(tokenVesting).initialize(from, amount);
    }

    function update(address tokenVesting, uint256 start, uint256 cliff, uint256 initialShare, uint256 periodicShare, bool revocable) external onlyOwner {
        TokenVesting(tokenVesting).update(start, cliff, initialShare, periodicShare, revocable);
    }


    function getBeneficiaries(uint256 vestingType) external view returns (address[] memory) {
        uint256 j = 0;
        address[] memory beneficiaries = new address[](_beneficiaries.length);

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            address beneficiary = _beneficiaries[i];
            if (_beneficiaryIndex[beneficiary].vestingType == vestingType || vestingType == 0) {
                beneficiaries[j] = beneficiary;
                j++;
            }
        }
        return beneficiaries;
    }

    function getVestingType(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary].isExist, "TokenVestingFactory: benficiery does not exist");
        return _beneficiaryIndex[beneficiary].vestingType;
    }

    function getTokenVesting(address beneficiary) external view returns (address) {
        require(_beneficiaryIndex[beneficiary].isExist, "TokenVestingFactory: benficiery does not exist");
        return _beneficiaryIndex[beneficiary].tokenVesting;
    }

    function getTokenAddress() external view returns (address) {
        return _tokenAddr;
    }

    function getDecimal() external view returns (uint256) {
        return _decimal;
    }

    function revoke(address tokenVesting) external onlyMultiSig{
        TokenVesting(tokenVesting).revoke(owner());
    }

}

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {    
    using SafeERC20 for IERC20;

    event TokenVestingUpdated(uint256 start, uint256 cliff, uint256 initialShare, uint256 periodicShare, bool revocable);
    event TokensReleased(address beneficiary, uint256 amount);
    event TokenVestingRevoked(address refundAddress, uint256 amount);
    event TokenVestingInitialized(address from, uint256 amount);

    enum Status {NotInitialized, Initialized, Revoked}

    // beneficiary of tokens after they are released
    address private _beneficiary;

    uint256 private _cliff;
    uint256 private _start;
    address private _tokenAddr;
    uint256 private _initialShare;
    uint256 private _periodicShare;
    uint256 private _decimal;
    uint256 private _released;

    bool private _revocable;
    Status private _status;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion. By then all
     * of the balance will have vested.
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param cliff duration in seconds of the cliff in which tokens will begin to vest
     * @param start the time (as Unix time) at which point vesting starts
     * @param revocable whether the vesting is revocable or not
     */
    constructor(
        address tokenAddr,
        address beneficiary,
        uint256 start,
        uint256 cliff,
        uint256 initialShare,
        uint256 periodicShare,
        uint256 decimal,
        bool revocable
    )

    {
        require(beneficiary != address(0), "TokenVesting: beneficiary address must not be zero");

        _tokenAddr = tokenAddr;
        _beneficiary = beneficiary;
        _revocable = revocable;
        _cliff = start + cliff;
        _start = start;
        _initialShare = initialShare;
        _periodicShare = periodicShare;
        _decimal = decimal;
        _status = Status.NotInitialized;

    }

    /**
    * @return TokenVesting details.
    */
    function getDetails() external view returns (address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256) {
        uint256 _total = IERC20(_tokenAddr).balanceOf(address(this)) + _released;
        uint256 _vested = _vestedAmount();
        uint256 _releasable = _vestedAmount() - _released;
        return (_beneficiary, _initialShare, _periodicShare, _start, _cliff, _total, _vested, _released, _releasable, _revocable, uint256(_status));
    }


    /**
     * @return the initial share of the beneficiary.
     */
    function getInitialShare() external view returns (uint256) {
        return _initialShare;
    }


    /**
     * @return the periodic share of the beneficiary.
     */
    function getPeriodicShare() external view returns (uint256) {
        return _periodicShare;
    }


    /**
     * @return the beneficiary of the tokens.
     */
    function getBeneficiary() external view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the start time of the token vesting.
     */
    function getStart() external view returns (uint256) {
        return _start;
    }

    /**
     * @return the cliff time of the token vesting.
     */
    function getCliff() external view returns (uint256) {
        return _cliff;
    }

    /**
     * @return the total amount of the token.
     */
    function getTotal() external view returns (uint256) {
        return IERC20(_tokenAddr).balanceOf(address(this)) + _released;
    }

    /**
     * @return the amount of the vested token.
     */
    function getVested() external view returns (uint256) {
        return _vestedAmount();
    }

    /**
     * @return the amount of the token released.
     */
    function getReleased() external view returns (uint256) {
        return _released;
    }

    /**
     * @return the amount that has already vested but hasn't been released yet.
     */
    function getReleasable() public view returns (uint256) {
        return _vestedAmount() - _released;
    }

    /**
     * @return true if the vesting is revocable.
     */
    function isRevocable() external view returns (bool) {
        return _revocable;
    }

    /**
     * @return true if the token is revoked.
     */
    function isRevoked() external view returns (bool) {
        if (_status == Status.Revoked) {
            return true;
        } else {
            return false;
        }
    }

    /**
    * @return status.
    */
    function getStatus() external view returns (uint256) {
        return uint256(_status);
    }

    /**
     * @notice change status to initialized.
     */
    function initialize(address from, uint256 amount) public onlyOwner {

        require(_status == Status.NotInitialized, "TokenVesting: status must be NotInitialized");

        _status = Status.Initialized;

        emit TokenVestingInitialized(address(from), amount);

        IERC20(_tokenAddr).safeTransferFrom(from, address(this), amount);

    }

    /**
    * @notice update token vesting contract.
    */
    function update(
        uint256 start,
        uint256 cliff,
        uint256 initialShare,
        uint256 periodicShare,
        bool revocable

    ) external onlyOwner {

        require(_status == Status.NotInitialized, "TokenVesting: status must be NotInitialized");

        _start = start;
        _cliff = start + cliff;
        _initialShare = initialShare;
        _periodicShare = periodicShare;
        _revocable = revocable;

        emit TokenVestingUpdated(_start, _cliff, _initialShare, _periodicShare, _revocable);

    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() external {
        require(_status != Status.NotInitialized, "TokenVesting: status is NotInitialized");
        uint256 unreleased = getReleasable();

        require(unreleased > 0, "TokenVesting: releasable amount is zero");

        _released = _released + unreleased;

        emit TokensReleased(address(_beneficiary), unreleased);

        IERC20(_tokenAddr).safeTransfer(_beneficiary, unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     */
    function revoke(address refundAddress) external onlyOwner {
        require(_revocable, "TokenVesting: contract is not revocable");
        require(_status != Status.Revoked, "TokenVesting: status is Revoked");

        uint256 balance = IERC20(_tokenAddr).balanceOf(address(this));

        uint256 unreleased = getReleasable();
        uint256 refund = balance - unreleased;

        _status = Status.Revoked;

        emit TokenVestingRevoked(address(refundAddress), refund);
        
        IERC20(_tokenAddr).safeTransfer(refundAddress, refund);

    }


    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount() private view returns (uint256) {
        uint256 currentBalance = IERC20(_tokenAddr).balanceOf(address(this));
        uint256 totalBalance = currentBalance + _released;
        uint256 initialRelease = (totalBalance * _initialShare) / ((10 ** _decimal) * 100) ;

        if (block.timestamp < _start)
            return 0;

        if (_status == Status.Revoked)
            return totalBalance;

        if (block.timestamp < _cliff)
            return initialRelease;

        uint256 monthlyRelease = (totalBalance * _periodicShare) / ((10 ** _decimal) * 100);
        uint256 _months = BokkyPooBahsDateTimeLibrary.diffMonths(_cliff, block.timestamp);

        if (initialRelease + (monthlyRelease * (_months + 1)) >= totalBalance) {
            return totalBalance;
        } else {
            return initialRelease + (monthlyRelease * (_months + 1));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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