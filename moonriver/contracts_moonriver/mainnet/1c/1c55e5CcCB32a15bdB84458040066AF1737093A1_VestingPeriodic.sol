// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import { IERC20 } from "./interfaces/IERC20.sol";
import { Ownable } from "./helpers/Ownable.sol";
import { Lockable } from "./helpers/Lockable.sol";

/**
 * @title   Vesting
 * @notice  Vesting contract
 * @dev     Vesting is constantly releasing vested tokens every block every second
 */
contract VestingPeriodic is Ownable, Lockable {
    /// @notice address of vested token
    address public token;
    /// @notice total tokens vested in contract
    uint256 public totalVested;
    /// @notice total tokens already claimed form vesting
    uint256 public totalClaimed;

    enum VestingType {
        DAILY,
        WEEKLY,
        MONTHLY,
        QUARTERLY,
        HALFYEARLY,
        YEARLY
    }

    mapping(VestingType => uint256) public periods;

    struct Vest {
        uint256 dateStart; // start of claiming, can claim startTokens
        uint256 dateEnd; // after it all tokens can be claimed
        uint256 totalTokens; // total tokens to claim
        uint256 startTokens; // tokens to claim on start
        uint256 claimedTokens; // tokens already claimed
        uint256 cliffLength;
        uint256 recurrences;
        VestingType vType;
    }
    /// @notice storage of vestings
    Vest[] internal vestings;
    /// @notice map of vestings for user
    mapping(address => uint256[]) internal user2vesting;

    /// @dev events
    event Claimed(address indexed user, uint256 amount);
    event Vested(address indexed user, uint256 totalAmount, uint256 endDate);

    constructor() {
        periods[VestingType.DAILY] = 1;
        periods[VestingType.WEEKLY] = 7;
        periods[VestingType.MONTHLY] = 30;
        periods[VestingType.QUARTERLY] = 90;
        periods[VestingType.HALFYEARLY] = 180;
        periods[VestingType.YEARLY] = 360;
    }

    /**
     * @dev Contract initiator
     * @param _token address of vested token
     */
    function init(address _token) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        require(token == address(0), "init already done");
        token = _token;
    }

    /**
     * @dev Add multiple vesting to contract by arrays of data
     * @param _users[] addresses of holders
     * @param _startTokens[] tokens that can be withdrawn at startDate
     * @param _totalTokens[] total tokens in vesting
     * @param _startDate date from when tokens can be claimed
     * @param _cliffLength cliff length in sec
     * @param _recurrences how many recurrences
     * @param _vType type of recurrence lengths
     */
    function massAddHolders(
        address[] calldata _users,
        uint256[] calldata _startTokens,
        uint256[] calldata _totalTokens,
        uint256 _startDate,
        uint256 _cliffLength,
        uint256 _recurrences,
        uint256 _vType
    ) external onlyOwner whenNotLocked {
        uint256 len = _users.length; //cheaper to use one variable
        require((len == _startTokens.length) && (len == _totalTokens.length), "data size mismatch");
        uint256 i;
        for (i; i < len; i++) {
            _addHolder(_users[i], _startTokens[i], _totalTokens[i], _startDate, _cliffLength, _recurrences, _vType);
        }
    }

    /**
     * @dev Add new vesting to contract
     * @param _user address of a holder
     * @param _startTokens how many tokens are claimable at start date
     * @param _totalTokens total number of tokens in added vesting
     * @param _startDate date from when tokens can be claimed
     * @param _cliffLength cliff length in sec
     * @param _recurrences how many recurrences
     * @param _vType type of recurrence lengths
     */
    function _addHolder(
        address _user,
        uint256 _startTokens,
        uint256 _totalTokens,
        uint256 _startDate,
        uint256 _cliffLength,
        uint256 _recurrences,
        uint256 _vType
    ) internal {
        require(_user != address(0), "user address cannot be 0");
        Vest memory v;
        v.dateStart = _startDate;
        v.cliffLength = _cliffLength;
        v.startTokens = _startTokens;
        v.totalTokens = _totalTokens;
        v.recurrences = _recurrences;
        v.vType = VestingType(_vType);
        v.dateEnd = _startDate + (_recurrences * periods[VestingType(_vType)] * 86400) + _cliffLength;

        totalVested += _totalTokens;
        vestings.push(v);
        user2vesting[_user].push(vestings.length); // we are skipping index "0" for reasons
        emit Vested(_user, v.totalTokens, v.dateEnd);
    }

    /**
     * @dev Claim tokens from msg.sender vestings
     */
    function claim() external {
        _claim(msg.sender, msg.sender);
    }

    /**
     * @dev Claim tokens from msg.sender vestings to external address
     * @param _target transfer address for claimed tokens
     */
    function claimTo(address _target) external {
        _claim(msg.sender, _target);
    }

    /**
     * @dev internal claim function
     * @param _user address of holder
     * @param _target where tokens should be send
     * @return amt number of tokens claimed
     */
    function _claim(address _user, address _target) internal returns (uint256 amt) {
        require(_target != address(0), "claim, then burn");
        uint256 len = user2vesting[_user].length;
        require(len > 0, "no vestings for user");
        uint256 cl;
        uint256 i;
        for (i; i < len; i++) {
            Vest storage v = vestings[user2vesting[_user][i] - 1];
            cl = _claimable(v);
            v.claimedTokens += cl;
            amt += cl;
        }
        if (amt > 0) {
            totalClaimed += amt;
            _transfer(_target, amt);
            emit Claimed(_user, amt);
        } else revert("nothing to claim");
    }

    /**
     * @dev Internal function to send out claimed tokens
     * @param _user address that we send tokens
     * @param _amt amount of tokens
     */
    function _transfer(address _user, uint256 _amt) internal {
        require(IERC20(token).transfer(_user, _amt), "token transfer failed");
    }

    /**
     * @dev Count how many tokens can be claimed from vesting to date
     * @param _vesting Vesting object
     * @return canWithdraw number of tokens
     */
    function _claimable(Vest memory _vesting) internal view returns (uint256 canWithdraw) {
        uint256 currentTime = block.timestamp;
        uint256 cliffTime = _vesting.dateStart + _vesting.cliffLength;
        uint256 period = periods[_vesting.vType];

        // not started
        if (_vesting.dateStart > currentTime) return 0;

        if (currentTime <= cliffTime) {
            // we are after start but before cliff
            canWithdraw = _vesting.startTokens;
        } else if (currentTime > cliffTime && currentTime < _vesting.dateEnd) {
            // we are somewhere in the middle
            uint256 vestedAmount = _vesting.totalTokens - _vesting.startTokens;
            uint256 everyRecurrenceReleaseAmount = vestedAmount / _vesting.recurrences;

            uint256 occurrences = diffDays(cliffTime, currentTime) / period;
            uint256 vestingUnlockedAmount = occurrences * everyRecurrenceReleaseAmount;

            canWithdraw = vestingUnlockedAmount + _vesting.startTokens; // total unlocked amount
        } else {
            // time has passed, we can take all tokens
            canWithdraw = _vesting.totalTokens;
        }

        // but maybe we take something earlier?
        canWithdraw -= _vesting.claimedTokens;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp, "fromTimestamp > toTimestamp");
        _days = (toTimestamp - fromTimestamp) / 86400;
    }

    /**
     * @dev Read number of claimable tokens by user and vesting no
     * @param _user address of holder
     * @param _id his vesting number (starts from 0)
     * @return amount number of tokens
     */
    function getClaimable(address _user, uint256 _id) external view returns (uint256 amount) {
        amount = _claimable(vestings[user2vesting[_user][_id] - 1]);
    }

    /**
     * @dev Read total amount of tokens that user can claim to date from all vestings
     *      Function also includes tokens to claim from sale contracts that were not
     *      yet initiated for user.
     * @param _user address of holder
     * @return amount number of tokens
     */
    function getAllClaimable(address _user) public view returns (uint256 amount) {
        uint256 len = user2vesting[_user].length;
        uint256 i;
        for (i; i < len; i++) {
            amount += _claimable(vestings[user2vesting[_user][i] - 1]);
        }
    }

    struct VestReturn {
        uint256 dateStart; // start of claiming, can claim startTokens
        uint256 dateEnd; // after it all tokens can be claimed
        uint256 totalTokens; // total tokens to claim
        uint256 startTokens; // tokens to claim on start
        uint256 claimedTokens; // tokens already claimed
    }

    /**
     * @dev Extract all the vestings for the user
     *      Also extract not initialized vestings from
     *      sale contracts.
     * @param _user address of holder
     * @return v array of Vest objects
     */
    function getVestings(address _user) external view returns (VestReturn[] memory) {
        uint256 len = user2vesting[_user].length;
        VestReturn[] memory v = new VestReturn[](len);

        // copy vestings
        uint256 i;
        for (i; i < len; i++) {
            v[i].dateStart = vestings[user2vesting[_user][i] - 1].dateStart;
            v[i].dateEnd = vestings[user2vesting[_user][i] - 1].dateEnd;
            v[i].totalTokens = vestings[user2vesting[_user][i] - 1].totalTokens;
            v[i].startTokens = vestings[user2vesting[_user][i] - 1].startTokens;
            v[i].claimedTokens = vestings[user2vesting[_user][i] - 1].claimedTokens;
        }

        return v;
    }

    /**
     * @dev Read total number of vestings registered
     * @return number of registered vestings on contract
     */
    function getVestingsCount() external view returns (uint256) {
        return vestings.length;
    }

    /**
     * @dev Read single registered vesting entry
     * @param _id index of vesting in storage
     * @return Vest object
     */
    function getVestingByIndex(uint256 _id) external view returns (VestReturn memory) {
        VestReturn memory v;

        v.dateStart = vestings[_id].dateStart;
        v.dateEnd = vestings[_id].dateEnd;
        v.totalTokens = vestings[_id].totalTokens;
        v.startTokens = vestings[_id].startTokens;
        v.claimedTokens = vestings[_id].claimedTokens;

        return v;
    }

    /**
     * @dev Read registered vesting list by range from-to
     * @param _start first index
     * @param _end last index
     * @return array of Vest objects
     */
    function getVestingsByRange(uint256 _start, uint256 _end) external view returns (VestReturn[] memory) {
        uint256 cnt = _end - _start + 1;
        uint256 len = vestings.length;
        require(_end < len, "range error");
        VestReturn[] memory v = new VestReturn[](cnt);

        uint256 i;
        for (i; i < cnt; i++) {
            v[i].dateStart = vestings[_start + i].dateStart;
            v[i].dateEnd = vestings[_start + i].dateEnd;
            v[i].totalTokens = vestings[_start + i].totalTokens;
            v[i].startTokens = vestings[_start + i].startTokens;
            v[i].claimedTokens = vestings[_start + i].claimedTokens;
        }

        return v;
    }

    /**
     * @dev Recover ETH from contract to owner address.
     */
    function recoverETH() external {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev Recover given ERC20 token from contract to owner address.
     *      Can't recover vested tokens.
     * @param _token address of ERC20 token to recover
     */
    function recoverErc20(address _token) external onlyOwner {
        uint256 amt = IERC20(_token).balanceOf(address(this));
        require(amt > 0, "nothing to recover");
        IERC20(_token).transfer(owner, amt);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import { Ownable } from "./Ownable.sol";

contract LockableData {
    bool public locked;
}

contract Lockable is LockableData, Ownable {
    /**
     * @dev Locks functions with whenNotLocked modifier
     */
    function lock() external onlyOwner {
        locked = true;
    }

    /**
     * @dev Throws if called when unlocked.
     */
    modifier whenLocked() {
        require(locked, "Lockable: unlocked");
        _;
    }

    /**
     * @dev Throws if called after it was locked.
     */
    modifier whenNotLocked() {
        require(!locked, "Lockable: locked");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract OwnableData {
    address public owner;
    address public pendingOwner;
}

contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev `owner` defaults to msg.sender on construction.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
     *      Can only be invoked by the current `owner`.
     * @param _newOwner Address of the new owner.
     * @param _direct True if `_newOwner` should be set immediately. False if `_newOwner` needs to use `claimOwnership`.
     * @param _renounce Allows the `_newOwner` to be `address(0)` if `_direct` and `_renounce` is True. Has no effect otherwise
     */
    function transferOwnership(
        address _newOwner,
        bool _direct,
        bool _renounce
    ) external onlyOwner {
        if (_direct) {
            require(_newOwner != address(0) || _renounce, "zero address");

            emit OwnershipTransferred(owner, _newOwner);
            owner = _newOwner;
            pendingOwner = address(0);
        } else {
            pendingOwner = _newOwner;
        }
    }

    /**
     * @dev Needs to be called by `pendingOwner` to claim ownership.
     */
    function claimOwnership() external {
        address _pendingOwner = pendingOwner;
        require(msg.sender == _pendingOwner, "caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /**
     * @dev Throws if called by any account other than the Owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}