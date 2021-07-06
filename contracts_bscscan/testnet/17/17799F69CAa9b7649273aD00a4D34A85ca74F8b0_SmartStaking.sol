/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;



/* ~~~~~~~~~~~~ TO TEST ~~~~~~~~~~~~~~ */
interface ISmartStaking {
    function contractStake(
        address _account,
        uint256 _stakeSteps,
        uint256 _stakedSmart,
        uint256 _rewardSmart,
        uint256 _stakeBonus
    ) external;
    function contractAddSmartToPool(uint256 _Smart) external;
}

/* ~~~~~~~~~~~~ TO TEST ~~~~~~~~~~~~~~ */
interface IAutoStaking {
    function addInflatedForSaleSmart(uint256 _stakeSteps, uint256 _Smart) external;
}


/* ~~~~~~~~~~~~ TO TEST ~~~~~~~~~~~~~~ */
interface ISmartToken {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
    function getBalanceOf(address _account) external view returns (uint256);
}


/* ~~~~~~~~~~~~ GOOD ~~~~~~~~~~~~~~ */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    struct Bytes32Set {
        Set _inner;
    }
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
    struct UintSet {
        Set _inner;
    }
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


/* ~~~~~~~~~~~~ GOOD ~~~~~~~~~~~~~~ */
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}




interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}


abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }
    mapping(bytes32 => RoleData) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }
    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }
    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}




library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



/* ~~~~~~~~~~~~ TO TEST || CORE ~~~~~~~~~~~~~~ */
contract SmartStaking is ISmartStaking, AccessControl {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    struct UserStaking {
        address account;
        uint256 steps;
        uint256 stakingId;
        uint256 startDate;
        uint256 unstakeDate;
        uint256 Smart;
        uint256 shares;
    }

    struct Settings {
        uint256 LATE_PENALTY_RATE_PER_STEP; // 1
        uint256 BASE_BONUS_STEPS; // 30
        uint256 MAX_STAKE_STEPS; // 1820
        uint256 MAX_LATE_STEPS; // 28
        uint256 STEP_SECONDS; // 86400
        uint256 BURN_PENALTY_RATE; // 5
    }

    struct Addresses {
        ISmartToken Smart_TOKEN;
        IAutoStaking AUTO_STAKING;
    }

    event Stake(
        address indexed account,
        address caller,
        uint256 steps,
        uint256 startDate,
        uint256 indexed stakingId,
        uint256 indexed shares,
        uint256 Smart,
        uint256 stakeBonus,
        uint256 daysBonus,
        uint256 totalStakedSmart,
        uint256 totalUnstakedSmart,
        uint256 totalStakedShares,
        uint256 totalUnstakedShares
    );

    event Unstake(
        address indexed account,
        uint256 unstakeDate,
        uint256 indexed stakingId,
        uint256 indexed payoutSmart,
        uint256 penaltyRate,
        uint256 penaltySmart,
        uint256 totalStakedSmart,
        uint256 totalUnstakedSmart,
        uint256 totalStakedShares,
        uint256 totalUnstakedShares
    );

    event UnstakeFullPenalty(
        address indexed caller,
        uint256 indexed stakingId,
        uint256 date,
        uint256 indexed Smart
    );

    event AddSmartToPool(uint256 indexed Smart, address indexed caller);

    event SetAutoStaking(address indexed caller, address indexed autoStaking);

    event UpdateSettings(
        bytes32 indexed setting,
        uint256 indexed newValue,
        address indexed caller
    );

    bytes32 public constant SETTER_ROLE = keccak256('SETTER_ROLE');
    bytes32 public constant STAKER_ROLE = keccak256('STAKER_ROLE');
    bytes32 public constant Smart_ADDER_ROLE = keccak256('Smart_ADDER_ROLE');
    bytes32 public constant SETTINGS_MANAGER_ROLE =
        keccak256('SETTINGS_MANAGER_ROLE');

    // SETTINGS
    Settings public SETTINGS;
    Addresses public ADDRESSES;

    // states
    uint256 public totalStakedSmart;
    uint256 public totalUnstakedSmart;

    uint256 public interestPoolSmart;
    uint256 public totalPaidSmart;

    uint256 public totalStakedShares;
    uint256 public totalUnstakedShares;

    uint256 public currentStakingId;

    // stakingId => UserStaking
    mapping(uint256 => UserStaking) public userStakingOf;

    // account => stakingId[]
    mapping(address => EnumerableSet.UintSet) private stakingIdsOf;

    modifier onlySetter() {
        require(
            hasRole(SETTER_ROLE, msg.sender),
            'SmartStaking: Caller is not a setter'
        );
        _;
    }

    modifier onlyStaker() {
        require(
            hasRole(STAKER_ROLE, msg.sender),
            'SmartStaking: Caller is not a staker'
        );
        _;
    }

    modifier onlySmartAdder() {
        require(
            hasRole(Smart_ADDER_ROLE, msg.sender),
            'SmartStaking: Caller is not a Smart adder'
        );
        _;
    }

    modifier onlySettingsManager() {
        require(
            hasRole(SETTINGS_MANAGER_ROLE, msg.sender),
            'SmartStaking: Caller is not a settings manager'
        );
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SETTER_ROLE, msg.sender);
    }

    function init(
        address _SmartToken,
        address _autoStaking,
        uint256 _latePenaltyRatePerStep,
        uint256 _maxStakeSteps,
        uint256 _maxLateSteps,
        uint256 _baseBonusSteps,
        uint256 _stepSeconds,
        uint256 _burnPenaltyRate,
        address[] calldata _stakerAccounts,
        address[] calldata _SmartAdderAccounts
    ) external onlySetter {
        ADDRESSES.Smart_TOKEN = ISmartToken(_SmartToken);
        ADDRESSES.AUTO_STAKING = IAutoStaking(_autoStaking);

        SETTINGS.STEP_SECONDS = _stepSeconds;
        SETTINGS.MAX_STAKE_STEPS = _maxStakeSteps;
        SETTINGS.MAX_LATE_STEPS = _maxLateSteps;
        SETTINGS.LATE_PENALTY_RATE_PER_STEP = _latePenaltyRatePerStep;
        SETTINGS.BASE_BONUS_STEPS = _baseBonusSteps;
        SETTINGS.BURN_PENALTY_RATE = _burnPenaltyRate;

        for (uint256 idx = 0; idx < _stakerAccounts.length; idx = idx.add(1)) {
            _setupRole(STAKER_ROLE, _stakerAccounts[idx]);
        }

        for (
            uint256 idx = 0;
            idx < _SmartAdderAccounts.length;
            idx = idx.add(1)
        ) {
            _setupRole(Smart_ADDER_ROLE, _SmartAdderAccounts[idx]);
        }

        renounceRole(SETTER_ROLE, msg.sender);
    }

    function userStake(uint256 _stakeSteps, uint256 _Smart) external {
        // Smart - burn
        ADDRESSES.Smart_TOKEN.burn(msg.sender, _Smart);

        _stake(msg.sender, _stakeSteps, _Smart, 0);

        // add Smart to the "for sale pool"
        ADDRESSES.AUTO_STAKING.addInflatedForSaleSmart(_stakeSteps, _Smart);
    }

    /* contract must burn the tokens before calling this method */
    function contractStake(
        address _account,
        uint256 _stakeSteps,
        uint256 _stakedSmart,
        uint256 _rewardSmart,
        uint256 _stakeBonus
    ) external override onlyStaker {
        _stake(_account, _stakeSteps, _stakedSmart, _stakeBonus);

        if (_rewardSmart != 0) {
            _addSmartToPool(_rewardSmart);
        }
    }

    function _stake(
        address _userAccount,
        uint256 _stakeSteps,
        uint256 _Smart,
        uint256 _stakeBonus
    ) private {
        require(_stakeSteps > 0, 'SmartStaking[stake]: _stakeSteps <= 0');
        require(_Smart > 0, 'SmartStaking[stake]: _Smart <= 0');
        require(
            _stakeSteps <= SETTINGS.MAX_STAKE_STEPS,
            'Staking[stake]: _stakeSteps > SETTINGS.MAX_STAKE_STEPS'
        );

        (uint256 shares, uint256 daysBonus) =
            getShares(_stakeSteps, _Smart, _stakeBonus);
        uint256 startDate = block.timestamp;

        // state - update
        uint256 stakingId = currentStakingId;
        userStakingOf[currentStakingId] = UserStaking({
            account: _userAccount,
            steps: _stakeSteps,
            stakingId: stakingId,
            startDate: startDate,
            unstakeDate: 0,
            Smart: _Smart,
            shares: shares
        });
        stakingIdsOf[_userAccount].add(currentStakingId);

        totalStakedSmart = totalStakedSmart.add(_Smart);
        totalStakedShares = totalStakedShares.add(shares);

        currentStakingId = currentStakingId.add(1);

        // [event]
        emit Stake(
            _userAccount,
            msg.sender,
            _stakeSteps,
            startDate,
            stakingId,
            shares,
            _Smart,
            _stakeBonus,
            daysBonus,
            totalStakedSmart,
            totalUnstakedSmart,
            totalStakedShares,
            totalUnstakedShares
        );
    }

    function unstake(uint256 stakingId) external {
        UserStaking storage userStaking = userStakingOf[stakingId];
        address userAccount = msg.sender;

        require(
            userStaking.account == userAccount,
            'SmartStaking[unstake]: userStaking.account != userAccount'
        );
        require(
            userStaking.unstakeDate == 0,
            'SmartStaking[unstake]: userStaking.unstakeDate != 0'
        );

        uint256 SmartLeftInPool = interestPoolSmart.sub(totalPaidSmart);
        uint256 sharesLeft = totalStakedShares.sub(totalUnstakedShares);

        uint256 fullStakedBonusSmart =
            SmartLeftInPool.mul(userStaking.shares).div(sharesLeft);

        uint256 fullPayoutWithoutPenalty =
            userStaking.Smart.add(fullStakedBonusSmart);

        uint256 actualStakeSteps = getActualSteps(userStaking.startDate);
        uint256 penaltyRateWei =
            getPenaltyRateWei(userStaking.startDate, userStaking.steps);
        uint256 rateSmartToGetBack = uint256(1e18).sub(penaltyRateWei);
        uint256 payoutSmart = 0;

        if (actualStakeSteps < userStaking.steps) {
            payoutSmart = userStaking.Smart.mul(rateSmartToGetBack).div(1e18);
        } else {
            payoutSmart = (userStaking.Smart.add(fullStakedBonusSmart))
                .mul(rateSmartToGetBack)
                .div(1e18);
        }
        uint256 penaltySmart = fullPayoutWithoutPenalty.sub(payoutSmart);

        // state - update
        uint256 unstakeDate = block.timestamp;
        userStaking.unstakeDate = unstakeDate;

        totalUnstakedSmart = totalUnstakedSmart.add(userStaking.Smart);
        totalUnstakedShares = totalUnstakedShares.add(userStaking.shares);
        totalPaidSmart = totalPaidSmart.add(fullStakedBonusSmart);

        if (penaltySmart > 0) {
            _addSmartToPool(
                penaltySmart
                    .mul(uint256(100).sub(SETTINGS.BURN_PENALTY_RATE))
                    .div(100)
            );
        }

        if (payoutSmart > 0) {
            // Smart - mint
            ADDRESSES.Smart_TOKEN.mint(userAccount, payoutSmart);
        }

        // [event]
        emit Unstake(
            userAccount,
            unstakeDate,
            userStaking.stakingId,
            payoutSmart,
            penaltyRateWei,
            penaltySmart,
            totalStakedSmart,
            totalUnstakedSmart,
            totalStakedShares,
            totalUnstakedShares
        );
    }

    function unstakeFullPenalty(uint256 stakingId) external {
        UserStaking storage userStaking = userStakingOf[stakingId];

        require(
            userStaking.startDate != 0,
            'SmartStaking[unstakeFullPenalty]: userStaking.startDate == 0'
        );

        require(
            userStaking.unstakeDate == 0,
            'SmartStaking[unstakeFullPenalty]: userStaking.unstakeDate != 0'
        );

        uint256 endDate =
            userStaking.startDate.add(
                (SETTINGS.STEP_SECONDS.mul(userStaking.steps))
            );
        require(
            block.timestamp > endDate,
            'SmartStaking[unstakeFullPenalty]: the stake is not ended yet'
        );

        uint256 penaltyRate =
            getPenaltyRateWei(userStaking.startDate, userStaking.steps);

        require(
            penaltyRate == 1e18,
            'SmartStaking[unstakeFullPenalty]: the stake is not full penalty'
        );

        uint256 SmartLeftInPool = interestPoolSmart.sub(totalPaidSmart);
        uint256 sharesLeft = totalStakedShares.sub(totalUnstakedShares);
        uint256 fullStakedBonusSmart =
            SmartLeftInPool.mul(userStaking.shares).div(sharesLeft);
        uint256 fullPayout = userStaking.Smart.add(fullStakedBonusSmart);

        // state - update
        uint256 unstakeDate = block.timestamp;
        userStaking.unstakeDate = unstakeDate;

        totalUnstakedSmart = totalUnstakedSmart.add(userStaking.Smart);
        totalUnstakedShares = totalUnstakedShares.add(userStaking.shares);
        totalPaidSmart = totalPaidSmart.add(fullStakedBonusSmart);

        _addSmartToPool(
            fullPayout.mul(uint256(100).sub(SETTINGS.BURN_PENALTY_RATE)).div(
                100
            )
        );

        emit UnstakeFullPenalty(
            msg.sender,
            stakingId,
            unstakeDate,
            userStaking.Smart
        );
    }

    function userAddSmartToPool(uint256 _Smart) external {
        ADDRESSES.Smart_TOKEN.burn(msg.sender, _Smart);

        _addSmartToPool(_Smart);
    }

    /** Settings */
    function setAutoStaking(address _autoStaking) external onlySettingsManager {
        ADDRESSES.AUTO_STAKING = IAutoStaking(_autoStaking);
        emit SetAutoStaking(msg.sender, _autoStaking);
    }

    function setLatePenaltyRatePerStep(uint256 _rate)
        external
        onlySettingsManager
    {
        SETTINGS.LATE_PENALTY_RATE_PER_STEP = _rate;
        emit UpdateSettings('LATE_PENALTY_RATE_PER_STEP', _rate, msg.sender);
    }

    function setBaseBonusSteps(uint256 _steps) external onlySettingsManager {
        SETTINGS.BASE_BONUS_STEPS = _steps;
        emit UpdateSettings('BASE_BONUS_STEPS', _steps, msg.sender);
    }

    function setMaxStakeSteps(uint256 _steps) external onlySettingsManager {
        SETTINGS.MAX_STAKE_STEPS = _steps;
        emit UpdateSettings('MAX_STAKE_STEPS', _steps, msg.sender);
    }

    function setMaxLateSteps(uint256 _steps) external onlySettingsManager {
        SETTINGS.MAX_LATE_STEPS = _steps;
        emit UpdateSettings('MAX_LATE_STEPS', _steps, msg.sender);
    }

    function setBurnPenaltyRate(uint256 _rate) external onlySettingsManager {
        SETTINGS.BURN_PENALTY_RATE = _rate;
        emit UpdateSettings('BURN_PENALTY_RATE', _rate, msg.sender);
    }

    /* end settings */

    /* contract must burn the tokens before calling this method */
    function contractAddSmartToPool(uint256 _Smart) external override onlySmartAdder {
        _addSmartToPool(_Smart);
    }

    function _addSmartToPool(uint256 _Smart) private {
        interestPoolSmart = interestPoolSmart.add(_Smart);

        // [event]
        emit AddSmartToPool(_Smart, msg.sender);
    }

    /*
     * 100% = 1e18
     */
    function getPenaltyRateWei(uint256 _startDate, uint256 expectedSteps)
        public
        view
        returns (uint256)
    {
        uint256 actualSteps = getActualSteps(_startDate);

        // no penalty
        if (actualSteps == expectedSteps) {
            return 0;
        }

        // early penalty
        if (actualSteps < expectedSteps) {
            return
                (expectedSteps.sub(actualSteps)).mul(1e18).div(expectedSteps);
        }

        // late penalty
        uint256 lateSteps = actualSteps.sub(expectedSteps);

        if (lateSteps <= SETTINGS.MAX_LATE_STEPS) {
            return 0;
        }
        uint256 penaltyLateSteps = lateSteps.sub(SETTINGS.MAX_LATE_STEPS);

        uint256 latePenalty =
            penaltyLateSteps.mul(1e16).mul(SETTINGS.LATE_PENALTY_RATE_PER_STEP);

        if (latePenalty > 1e18) {
            return 1e18;
        }

        return latePenalty;
    }

    function getActualSteps(uint256 _startDate) public view returns (uint256) {
        return (block.timestamp.sub(_startDate)).div(SETTINGS.STEP_SECONDS);
    }

    function getShares(
        uint256 _stakeSteps,
        uint256 _Smart,
        uint256 _stakeBonus // 0, 20
    ) public view returns (uint256 shares, uint256 daysBonus) {
        uint256 base = _stakeSteps.mul(_Smart);
        uint256 stakeBonus = (_stakeBonus.add(100));
        daysBonus = getDaysBonus(_stakeSteps);
        shares = base.mul(stakeBonus).mul(daysBonus).div(1e20);
    }

    function getDaysBonus(uint256 _stakeSteps) public view returns (uint256) {
        uint256 bonusScore =
            _stakeSteps.mul(1e9).div(SETTINGS.BASE_BONUS_STEPS);
        uint256 bonusBase = bonusScore.add(100e9);

        return bonusBase.mul(bonusBase).div(1e18);
    }

    function getUserStakingCount(address _account)
        external
        view
        returns (uint256)
    {
        return stakingIdsOf[_account].length();
    }

    function getUserStakingId(address _account, uint256 idx)
        external
        view
        returns (uint256)
    {
        return stakingIdsOf[_account].at(idx);
    }
}