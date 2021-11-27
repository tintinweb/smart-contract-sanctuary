// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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
    modifier whenLocked {
        require(locked, "Lockable: unlocked");
        _;
    }

    /**
     * @dev Throws if called after it was locked.
     */
    modifier whenNotLocked {
        require(!locked, "Lockable: locked");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

// Based on StableMath from mStable
// https://github.com/mstable/mStable-contracts/blob/master/contracts/shared/StableMath.sol

library StableMath {
    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /**
     * @dev Provides an interface to the scaling unit
     * @return Scaling unit (1e18 or 1 * 10**18)
     */
    function getFullScale() internal pure returns (uint256) {
        return FULL_SCALE;
    }

    /**
     * @dev Scales a given integer to the power of the full scale.
     * @param x   Simple uint256 to scale
     * @return    Scaled value a to an exact number
     */
    function scaleInteger(uint256 x) internal pure returns (uint256) {
        return x * FULL_SCALE;
    }

    /***************************************
              PRECISE ARITHMETIC
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @param scale Scale unit
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        // return 9e36 / 1e18 = 9e18
        return (x * y) / scale;
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x * y;
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled + FULL_SCALE - 1;
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil / FULL_SCALE;
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x     Left hand input to division
     * @param y     Right hand input to division
     * @return      Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e18 * 1e18 = 8e36
        // e.g. 8e36 / 10e18 = 8e17
        return (x * FULL_SCALE) / y;
    }

    /***************************************
                    HELPERS
    ****************************************/

    /**
     * @dev Calculates minimum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Minimum of the two inputs
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }

    /**
     * @dev Calculated maximum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Maximum of the two inputs
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @dev Clamps a value to an upper bound
     * @param x           Left hand input
     * @param upperBound  Maximum possible value to return
     * @return            Input x clamped to a maximum value, upperBound
     */
    function clamp(uint256 x, uint256 upperBound) internal pure returns (uint256) {
        return x > upperBound ? upperBound : x;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { StableMath } from "./StableMath.sol";
import { IERC20 } from "./IERC20.sol";
import { Ownable } from "./Ownable.sol";
import { Lockable } from "./Lockable.sol";

/**
 * @title   Vesting
 * @notice  Vesting contract
 * @dev     Vesting is constantly releasing vested tokens every block every second
 */
contract Vesting is Ownable, Lockable {
    using StableMath for uint256;

    /// @notice address of vested token
    address public token;
    /// @notice total tokens vested in contract
    uint256 public totalVested;
    /// @notice total tokens already claimed form vesting
    uint256 public totalClaimed;

    struct Vest {
        uint256 dateStart; // start of claiming
        uint256 dateEnd; // after it all tokens can be claimed
        uint256 totalTokens; // total tokens to claim
        uint256 claimedTokens; // tokens already claimed
    }
    /// @notice storage of vestings
    Vest[] internal vestings;
    /// @notice map of vestings for user
    mapping(address => uint256[]) internal user2vesting;

    /// @dev events
    event Claimed(address indexed user, uint256 amount);
    event Vested(address indexed user, uint256 totalAmount, uint256 endDate);

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
     * @param _totalTokens[] total tokens in vesting
     * @param _startDate date from when tokens can be claimed
     * @param _endDate date after which all tokens can be claimed
     */
    function massAddHolders(
        address[] calldata _users,
        uint256[] calldata _totalTokens,
        uint256 _startDate,
        uint256 _endDate
    ) external onlyOwner whenNotLocked {
        uint256 len = _users.length; //cheaper to use one variable
        require((len == _totalTokens.length), "data size mismatch");
        require(_startDate < _endDate, "startDate cannot exceed endDate");
        uint256 i;
        for (i; i < len; i++) {
            _addHolder(_users[i], _totalTokens[i], _startDate, _endDate);
        }
    }

    /**
     * @dev Add new vesting to contract
     * @param _user address of a holder
     * @param _totalTokens total number of tokens in added vesting
     * @param _startDate date from when tokens can be claimed
     * @param _endDate date after which all tokens can be claimed
     */
    function _addHolder(
        address _user,
        uint256 _totalTokens,
        uint256 _startDate,
        uint256 _endDate
    ) internal {
        require(_user != address(0), "user address cannot be 0");
        Vest memory v;
        v.totalTokens = _totalTokens;
        v.dateStart = _startDate;
        v.dateEnd = _endDate;

        totalVested += _totalTokens;
        vestings.push(v);
        user2vesting[_user].push(vestings.length); // we are skipping index "0" for reasons
        emit Vested(_user, _totalTokens, _endDate);
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
        if (_vesting.dateStart > currentTime) return 0;
        // we are somewhere in the middle
        if (currentTime < _vesting.dateEnd) {
            // how much time passed (as fraction * 10^18)
            // timeRatio = (time passed * 1e18) / duration
            uint256 timeRatio = (currentTime - _vesting.dateStart).divPrecisely(_vesting.dateEnd - _vesting.dateStart);
            // how much tokens we can get in total to date
            canWithdraw = (_vesting.totalTokens).mulTruncate(timeRatio);
        }
        // time has passed, we can take all tokens
        else {
            canWithdraw = _vesting.totalTokens;
        }
        // but maybe we take something earlier?
        canWithdraw -= _vesting.claimedTokens;
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

    /**
     * @dev Extract all the vestings for the user
     *      Also extract not initialized vestings from
     *      sale contracts.
     * @param _user address of holder
     * @return v array of Vest objects
     */
    function getVestings(address _user) external view returns (Vest[] memory) {
        uint256 len = user2vesting[_user].length;
        Vest[] memory v = new Vest[](len);

        // copy vestings
        uint256 i;
        for (i; i < len; i++) {
            v[i] = vestings[user2vesting[_user][i] - 1];
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
    function getVestingByIndex(uint256 _id) external view returns (Vest memory) {
        return vestings[_id];
    }

    /**
     * @dev Read registered vesting list by range from-to
     * @param _start first index
     * @param _end last index
     * @return array of Vest objects
     */
    function getVestingsByRange(uint256 _start, uint256 _end) external view returns (Vest[] memory) {
        uint256 cnt = _end - _start + 1;
        uint256 len = vestings.length;
        require(_end < len, "range error");
        Vest[] memory v = new Vest[](cnt);
        uint256 i;
        for (i; i < cnt; i++) {
            v[i] = vestings[_start + i];
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
    function recoverErc20(address _token) external {
        require(_token != token, "not allowed");
        uint256 amt = IERC20(_token).balanceOf(address(this));
        require(amt > 0, "nothing to recover");
        IBadErc20(_token).transfer(owner, amt);
    }
}

/**
 * @title IBadErc20
 * @dev Interface for emergency recover any ERC20-tokens,
 *      even non-erc20-compliant like USDT not returning boolean
 */
interface IBadErc20 {
    function transfer(address _recipient, uint256 _amount) external;
}