/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// File: contracts/lib/SafeMath.sol

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted to use pragma ^0.4.24 and satisfy our linter rules

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// File: contracts/RegisterAndCall.sol

pragma solidity ^0.4.24;

contract RegisterAndCall {

    /**
    * @dev This allows users to verify their BrightId account and interact with a contract in one transaction.
    *      Implementers of this function should check that msg.sender is the BrightIdRegister contract expected.
    * @param _usersSenderAddress The address from which the transaction was created
    * @param _usersUniqueId The unique address assigned to the registered BrightId user
    * @param _data Optional data that can be used to determine what operations to execute in the recipient contract
    */
    function receiveRegistration(address _usersSenderAddress, address _usersUniqueId, bytes _data) external;

}

// File: contracts/lib/ArrayUtils.sol

pragma solidity ^0.4.24;

library ArrayUtils {

    address constant public UNVERIFIABLE_ADDRESS = address(-1);

    // Note that due to operating on a memory array, the array length can not be shortened
    // after an element is deleted so the element is set to an unverifiable address instead
    function deleteItem(address[] memory self, address item) internal returns (bool) {
        uint256 length = self.length;
        for (uint256 i = 0; i < length; i++) {
            if (self[i] == item) {
                uint256 newLength = self.length - 1;
                if (i != newLength) {
                    self[i] = self[newLength];
                }

                self[newLength] = UNVERIFIABLE_ADDRESS;

                return true;
            }
        }
        return false;
    }

    function contains(address[] memory self, address item) internal returns (bool) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i] == item) {
                return true;
            }
        }
        return false;
    }
}

// File: contracts/lib/Uint256Helpers.sol

pragma solidity ^0.4.24;


library Uint256Helpers {
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

// File: contracts/lib/TimeHelpers.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;



contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
    * @dev Returns the current block number, converted to uint64.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }

    /**
    * @dev Returns the current timestamp.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
    * @dev Returns the current timestamp, converted to uint64.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

// File: contracts/BrightIdRegister.sol

pragma solidity ^0.4.24;





contract BrightIdRegister is TimeHelpers {
    using SafeMath for uint256;
    using ArrayUtils for address[];

    uint256 constant public MIN_BRIGHTID_VERIFIERS = 1;
    uint256 constant public MAX_BRIGHTID_VERIFIERS = 20;

    string private constant ERROR_SENDER_NOT_IN_VERIFICATION = "BRIGHTID_SENDER_NOT_IN_VERIFICATION";
    string private constant ERROR_ADDRESS_VOIDED = "BRIGHTID_ADDRESS_VOIDED";
    string private constant ERROR_NO_UNIQUE_ID_ASSIGNED = "BRIGHTID_NO_UNIQUE_ID_ASSIGNED";
    string private constant ERROR_NO_VERIFIERS = "BRIGHTID_NO_VERIFIERS";
    string private constant ERROR_TOO_MANY_VERIFIERS = "BRIGHTID_TOO_MANY_VERIFIERS";
    string private constant ERROR_NOT_ENOUGH_VERIFICATIONS = "BRIGHTID_NOT_ENOUGH_VERIFICATIONS";
    string private constant ERROR_TOO_MANY_VERIFICATIONS = "BRIGHTID_TOO_MANY_VERIFICATIONS";
    string private constant ERROR_REGISTRATION_PERIOD_ZERO = "BRIGHTID_REGISTRATION_PERIOD_ZERO";
    string private constant ERROR_INCORRECT_TIMESTAMPS = "BRIGHTID_INCORRECT_TIMESTAMPS";
    string private constant ERROR_INCORRECT_SIGNATURES = "BRIGHTID_INCORRECT_SIGNATURES";
    string private constant ERROR_SIGNATURES_DIFFERENT_LENGTHS = "BRIGHTID_SIGNATURES_DIFFERENT_LENGTHS";
    string private constant ERROR_CAN_NOT_DELETE_VERIFIER = "BRIGHTID_CAN_NOT_DELETE_VERIFIER";
    string private constant ERROR_NOT_VERIFIED = "BRIGHTID_NOT_VERIFIED";

    struct UserRegistration {
        address uniqueUserId;
        uint256 registerTime;
        bool addressVoid;
    }

    address public settingsUpdater;
    bytes32 public brightIdContext;
    address[] public brightIdVerifiers;
    uint256 public requiredVerifications;
    uint256 public registrationPeriod;
    uint256 public verificationTimestampVariance;

    mapping (address => UserRegistration) public userRegistrations;

    event Register(address sender);

    modifier onlySettingsUpdater() {
        require(msg.sender == settingsUpdater, "BRIGHTID_NOT_SETTINGS_UPDATER");
        _;
    }

    /**
    * @param _settingsUpdater Address able to update the config
    * @param _brightIdContext BrightId context used for verifying users
    * @param _brightIdVerifiers Addresses used to verify signed BrightId verifications
    * @param _requiredVerifications Number of positive verifications required to register a user
    * @param _registrationPeriod Length of time after a registration before registration is required again
    * @param _verificationTimestampVariance Acceptable period of time between creating a BrightId verification
    *       and registering it with the BrightIdRegister
    */
    constructor(
        address _settingsUpdater,
        bytes32 _brightIdContext,
        address[] memory _brightIdVerifiers,
        uint256 _requiredVerifications,
        uint256 _registrationPeriod,
        uint256 _verificationTimestampVariance
    )
        public
    {
        _setSettingsUpdater(_settingsUpdater);
        _setBrightIdVerifiers(_brightIdVerifiers, _requiredVerifications);
        _setRegistrationPeriod(_registrationPeriod);

        brightIdContext = _brightIdContext;
        verificationTimestampVariance = _verificationTimestampVariance;
    }

    /**
    * @notice Set the settings updater to `_settingsUpdater`
    * @param _settingsUpdater The new settings updater address
    */
    function setSettingsUpdater(address _settingsUpdater) external onlySettingsUpdater {
        _setSettingsUpdater(_settingsUpdater);
    }

    /**
    * @notice Set the BrightId verifier addresses to `_brightIdVerifiers` and required number of verifiers to `_requiredVerifications`
    * @dev Should never use address(0) as a brightIdVerifier as this will allow all verifications.
    * @param _brightIdVerifiers Addresses used to verify signed BrightId verifications
    * @param _requiredVerifications Number of positive verifications required to register a user
    */
    function setBrightIdVerifiers(address[] _brightIdVerifiers, uint256 _requiredVerifications) external onlySettingsUpdater {
        _setBrightIdVerifiers(_brightIdVerifiers, _requiredVerifications);
    }

    /**
    * @notice Set the registration period to `_registrationPeriod`
    * @param _registrationPeriod Length of time after a registration before registration is required again
    */
    function setRegistrationPeriod(uint256 _registrationPeriod) external onlySettingsUpdater {
        _setRegistrationPeriod(_registrationPeriod);
    }

    /**
    * @notice Set the verification timestamp variance to `_verificationTimestampVariance`
    * @param _verificationTimestampVariance Acceptable period of time between fetching a BrightId verification
    *       and registering it with the BrightIdRegister
    */
    function setVerificationTimestampVariance(uint256 _verificationTimestampVariance) external onlySettingsUpdater {
        verificationTimestampVariance = _verificationTimestampVariance;
    }

    function getBrightIdVerifiers() external view returns (address[]) {
        return brightIdVerifiers;
    }

    /**
    * @notice Register the sender as a unique individual with a BrightId verification and assign the first address
    *       they registered with as their unique ID
    * @param _addrs The history of addresses, or contextIds, used by this user to register with BrightID for the _brightIdContext
    * @param _timestamps The time the verification was created for each verifier by a BrightId node
    * @param _v Part of the BrightId nodes signature for each verifier verifying the users uniqueness
    * @param _r Part of the BrightId nodes signature for each verifier verifying the users uniqueness
    * @param _s Part of the BrightId nodes signature for each verifier verifying the users uniqueness
    * @param _registerAndCall Contract to call after registration, set to 0x0 to register without forwarding data
    * @param _functionCallData Function data to call on the contract address after registration
    */
    function register(
        address[] memory _addrs,
        uint256[] memory _timestamps,
        uint8[] memory _v,
        bytes32[] memory _r,
        bytes32[] memory _s,
        RegisterAndCall _registerAndCall,
        bytes _functionCallData
    )
        public // public instead of external to mitigate stack too deep error
    {
        UserRegistration storage userRegistration = userRegistrations[msg.sender];
        require(msg.sender == _addrs[0], ERROR_SENDER_NOT_IN_VERIFICATION);
        _requireIsVerified(_addrs, _timestamps, _v, _r, _s);
        require(!userRegistration.addressVoid, ERROR_ADDRESS_VOIDED);

        userRegistration.registerTime = getTimestamp();

        address uniqueUserId = _addrs[_addrs.length - 1];  // The last address is/was the first address registered with the _brightIdContext
        if (userRegistration.uniqueUserId == address(0)) {
            userRegistration.uniqueUserId = uniqueUserId;
            _voidPreviousRegistrations(_addrs);
        }

        // We do this to ensure calls of uniqueUserId() that use the result of uniqueUserId() will
        // return the uniqueUserId even if the user has not registered their initial address
        if (userRegistrations[uniqueUserId].uniqueUserId == address(0)) {
            userRegistrations[uniqueUserId].uniqueUserId = uniqueUserId;
        }

        if (address(_registerAndCall) != address(0)) {
            _registerAndCall.receiveRegistration(msg.sender, userRegistration.uniqueUserId, _functionCallData);
        }

        emit Register(msg.sender);
    }

    /**
    * @notice Return whether or not the BrightId user is verified
    * @param _brightIdUser The BrightId user's address
    */
    function isVerified(address _brightIdUser) external view returns (bool) {
        UserRegistration storage userRegistration = userRegistrations[_brightIdUser];

        bool hasUniqueId = userRegistration.uniqueUserId != address(0);
        bool userRegisteredWithinPeriod = getTimestamp() < userRegistration.registerTime.add(registrationPeriod);
        bool userValid = !userRegistration.addressVoid;

        return hasUniqueId && userRegisteredWithinPeriod && userValid;
    }

    /**
    * @notice Return whether an address has a unique id assigned/was previously verified
    * @param _brightIdUser The BrightId user's address
    */
    function hasUniqueUserId(address _brightIdUser) external view returns (bool) {
        UserRegistration storage userRegistration = userRegistrations[_brightIdUser];
        return userRegistration.uniqueUserId != address(0);
    }

    /**
    * @notice Return a users unique ID, which is the first address they registered with
    * @dev Addresses that have been used as contextId's within this context that were not registered with the
    *    BrightIdRegister will not have a unique user id set and this function will revert.
    * @param _brightIdUser The BrightId user's address
    */
    function uniqueUserId(address _brightIdUser) external view returns (address) {
        UserRegistration storage userRegistration = userRegistrations[_brightIdUser];
        require(userRegistration.uniqueUserId != address(0), ERROR_NO_UNIQUE_ID_ASSIGNED);

        return userRegistration.uniqueUserId;
    }

    function _setSettingsUpdater(address _settingsUpdater) internal {
        settingsUpdater = _settingsUpdater;
    }

    function _setBrightIdVerifiers(address[] memory _brightIdVerifiers, uint256 _requiredVerifications) internal {
        require(_brightIdVerifiers.length >= MIN_BRIGHTID_VERIFIERS, ERROR_NO_VERIFIERS);
        require(_brightIdVerifiers.length <= MAX_BRIGHTID_VERIFIERS, ERROR_TOO_MANY_VERIFIERS);
        require(_requiredVerifications >= MIN_BRIGHTID_VERIFIERS, ERROR_NOT_ENOUGH_VERIFICATIONS);
        require(_requiredVerifications <= _brightIdVerifiers.length, ERROR_TOO_MANY_VERIFICATIONS);

        brightIdVerifiers = _brightIdVerifiers;
        requiredVerifications = _requiredVerifications;
    }

    function _setRegistrationPeriod(uint256 _registrationPeriod) internal {
        require(_registrationPeriod > 0, ERROR_REGISTRATION_PERIOD_ZERO);

        registrationPeriod = _registrationPeriod;
    }

    function _requireIsVerified(
        address[] memory _addrs,
        uint256[] memory _timestamps,
        uint8[] memory _v,
        bytes32[] memory _r,
        bytes32[] memory _s
    )
        internal view
    {
        require(_timestamps.length >= requiredVerifications, ERROR_INCORRECT_TIMESTAMPS);
        require(_v.length >= requiredVerifications && _r.length >= requiredVerifications && _s.length >= requiredVerifications, ERROR_INCORRECT_SIGNATURES);
        require((_timestamps.length == _v.length) && (_r.length == _s.length) && (_v.length == _s.length), ERROR_SIGNATURES_DIFFERENT_LENGTHS);

        address[] memory brightIdVerifiersCopy = brightIdVerifiers;
        uint256 i = 0;
        uint256 validVerifications = 0;

        while (i < brightIdVerifiers.length && validVerifications < requiredVerifications) {
            bytes32 signedMessage = keccak256(abi.encodePacked(brightIdContext, _addrs, _timestamps[i]));
            address verifierAddress = ecrecover(signedMessage, _v[i], _r[i], _s[i]);

            bool timestampWithinVariance = getTimestamp() < _timestamps[i].add(verificationTimestampVariance);
            if (timestampWithinVariance && brightIdVerifiersCopy.contains(verifierAddress)) {
                require(brightIdVerifiersCopy.deleteItem(verifierAddress), ERROR_CAN_NOT_DELETE_VERIFIER);
                validVerifications++;
            }
            i++;
        }

        require(validVerifications == requiredVerifications, ERROR_NOT_VERIFIED);
    }

    /**
    * @notice Void all previously used addresses to prevent users from registering multiple times using old
    *       BrightID verifications
    */
    function _voidPreviousRegistrations(address[] memory _addrs) internal {
        if (_addrs.length <= 1) {
            return;
        }

        // Loop until we find a voided user registration, from which all
        // subsequent user registrations will already be voided
        uint256 index = 1;
        while (index < _addrs.length && !userRegistrations[_addrs[index]].addressVoid) {
            userRegistrations[_addrs[index]].addressVoid = true;
            index++;
        }
    }
}