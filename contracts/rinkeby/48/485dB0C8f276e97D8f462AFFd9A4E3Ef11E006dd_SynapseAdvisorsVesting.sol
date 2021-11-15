// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { Ownable } from "./Ownable.sol";

abstract contract BeneficiaryData {
    address public beneficiary;
}

abstract contract Beneficiary is Ownable, BeneficiaryData {
    event BeneficiaryChanged(address indexed previousBeneficiary, address indexed newBeneficiary);

    /**
     * @dev `beneficiary` defaults to msg.sender on construction.
     */
    constructor() {
        beneficiary = msg.sender;
        emit BeneficiaryChanged(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than Beneficiary.
     */
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "caller is not beneficiary");
        _;
    }

    /**
     * @dev Change the beneficiary - only called by owner
     * @param _beneficiary Address of the new distributor
     */
    function setBeneficiary(address _beneficiary) external onlyOwner {
        require(_beneficiary != address(0), "zero address");

        emit BeneficiaryChanged(beneficiary, _beneficiary);
        beneficiary = _beneficiary;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract OwnableData {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is OwnableData {
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
     * @param _direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
     */
    function transferOwnership(address _newOwner, bool _direct) external onlyOwner {
        if (_direct) {
            require(_newOwner != address(0), "zero address");

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

pragma solidity 0.8.6;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    // EIP 2612
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

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

pragma solidity 0.8.6;

import { SynapseTeamVesting } from "./SynapseTeamVesting.sol";

/**
 * @title   SynapseAdvisorsVesting
 * @notice  Synapse Network Advisors Vesting contract
 * @dev     Vesting is constantly releasing tokens every block every second
 */
contract SynapseAdvisorsVesting is SynapseTeamVesting {
    /**
     * @dev deployer is owner
     * @param _token SNP token address
     * @param _startTime global vest start time
     * @param _startDelay time to enable claiming
     * @param _vestLength time to claim everything
     * @param _startTokens tokens claimable at start time
     * @param _totalTokens total tokens claimable
     */
    constructor(
        address _token,
        uint256 _startTime,
        uint256 _startDelay,
        uint256 _vestLength,
        uint256 _startTokens,
        uint256 _totalTokens
    ) SynapseTeamVesting(_token, _startTime, _startDelay, _vestLength, _startTokens, _totalTokens) {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { StableMath } from "../libraries/StableMath.sol";
import { IERC20 } from "../interfaces/IERC20.sol";
import { Ownable } from "../abstract/Ownable.sol";
import { Beneficiary } from "../abstract/Beneficiary.sol";

/**
 * @title   SynapseTeamVesting
 * @notice  Synapse Network Team Vesting contract
 * @dev     Vesting is constantly releasing tokens every block every second
 */
contract SynapseTeamVesting is Ownable, Beneficiary {
    using StableMath for uint256;

    /// @notice address of Synapse Network token
    address public immutable token;
    /// @notice total tokens already claimed form vesting
    uint256 public totalClaimed;

    struct Vest {
        uint256 dateStart; // start of claiming, can claim startTokens
        uint256 dateEnd; // after it all tokens can be claimed
        uint256 totalTokens; // total tokens to claim
        uint256 startTokens; // tokens to claim on start
        uint256 claimedTokens; // tokens already claimed
    }
    /// @notice storage of vestings
    Vest[] internal vestings;
    /// @notice map of vestings for team members
    mapping(address => uint256[]) internal user2vesting;

    /// @notice main contract vesting, owner set beneficiary for it
    Vest public contractVest;

    /// @notice time that need to pass from start of vesting to enable claiming
    uint256 public immutable startVestDelay;
    /// @notice time that need to pass from start to end of vesting
    uint256 public immutable totalVestLength;
    /// @notice total/start tokens ratio for every vest
    uint256 public immutable vestingDiv;

    /// @dev events
    event Claimed(address indexed user, uint256 amount);
    event Vested(address indexed user, uint256 totalAmount, uint256 endDate);
    event VestRemoved(address indexed user, uint256 amount);

    /**
     * @notice Contract constructor, deployer is owner and beneficiary
     * @param _token SNP token address
     * @param _startTime global vest start time
     * @param _startDelay time to enable claiming / cliff time
     * @param _vestLength time to claim everything
     * @param _startTokens tokens claimable at start time
     * @param _totalTokens total tokens claimable
     */
    constructor(
        address _token,
        uint256 _startTime,
        uint256 _startDelay,
        uint256 _vestLength,
        uint256 _startTokens,
        uint256 _totalTokens
    ) {
        require(_token != address(0), "_token address cannot be 0");
        require(_vestLength > _startDelay, "startDelay cannot exceed vestLength");
        require(_totalTokens > _startTokens, "startTokens cannot exceed totalTokens");

        token = _token;
        startVestDelay = _startDelay;
        totalVestLength = _vestLength;
        vestingDiv = _startTokens.divPrecisely(_totalTokens);

        contractVest.dateStart = _startTime + _startDelay;
        contractVest.dateEnd = _startTime + _vestLength;
        contractVest.startTokens = _startTokens;
        contractVest.totalTokens = _totalTokens;
    }

    /**
     * @dev Add single vesting to contract
     * @param _user address of holder
     * @param _totalTokens total tokens in vesting
     */
    function addHolder(address _user, uint256 _totalTokens) external onlyOwner {
        uint256 startTokens = _totalTokens.mulTruncate(vestingDiv);
        uint256 startDate = block.timestamp + startVestDelay;
        uint256 endDate = block.timestamp + totalVestLength;
        _addHolder(_user, startTokens, _totalTokens, startDate, endDate);
    }

    /**
     * @dev Add single vesting to contract starting from start time
     * @param _user address of holder
     * @param _totalTokens total tokens in vesting
     */
    function addHolderFromStart(address _user, uint256 _totalTokens) external onlyOwner {
        uint256 startTokens = _totalTokens.mulTruncate(vestingDiv);
        _addHolder(_user, startTokens, _totalTokens, contractVest.dateStart, contractVest.dateEnd);
    }

    /**
     * @dev Add multiple vesting to contract by arrays of data
     * @param _user[] address of holder
     * @param _totalTokens[] total tokens in vesting
     */
    function massAddHolders(address[] calldata _user, uint256[] calldata _totalTokens) external onlyOwner {
        uint256 len = _user.length; //cheaper to use one variable
        require((len == _totalTokens.length), "Data size mismatch");
        uint256 startDate = block.timestamp + startVestDelay;
        uint256 endDate = block.timestamp + totalVestLength;
        uint256 i;
        for (i; i < len; i++) {
            uint256 startTokens = _totalTokens[i].mulTruncate(vestingDiv);
            _addHolder(_user[i], startTokens, _totalTokens[i], startDate, endDate);
        }
    }

    /**
     * @dev Add multiple vesting to contract by arrays of data from start time
     * @param _user[] address of holder
     * @param _totalTokens[] total tokens in vesting
     */
    function massAddHoldersFromStart(address[] calldata _user, uint256[] calldata _totalTokens) external onlyOwner {
        uint256 len = _user.length; //cheaper to use one variable
        require((len == _totalTokens.length), "Data size mismatch");
        uint256 startDate = contractVest.dateStart;
        uint256 endDate = contractVest.dateEnd;
        uint256 i;
        for (i; i < len; i++) {
            uint256 startTokens = _totalTokens[i].mulTruncate(vestingDiv);
            _addHolder(_user[i], startTokens, _totalTokens[i], startDate, endDate);
        }
    }

    /**
     * @dev Add new vesting to contract
     * @param _user address of holder
     * @param _startTokens how many tokens are claimable at start date
     * @param _totalTokens total number of tokens in vesting
     * @param _startDate date from when tokens can be claimed
     * @param _endDate date after which all tokens can be claimed
     */
    function _addHolder(
        address _user,
        uint256 _startTokens,
        uint256 _totalTokens,
        uint256 _startDate,
        uint256 _endDate
    ) internal {
        require(_user != address(0), "user address cannot be 0");
        require(contractVest.totalTokens - contractVest.claimedTokens >= _totalTokens, "No more tokens");

        Vest memory v;
        v.startTokens = _startTokens;
        v.totalTokens = _totalTokens;
        v.dateStart = _startDate;
        v.dateEnd = _endDate;

        contractVest.totalTokens -= _totalTokens; // will throw if one want to cheat
        contractVest.startTokens -= _startTokens;
        vestings.push(v);
        user2vesting[_user].push(vestings.length); // we are skipping index "0" for reasons
        emit Vested(_user, _totalTokens, _endDate);
    }

    /**
     * @dev Remove user from vesting, sending claimable tokens
     * @param _user to be removed
     */
    function removeHolder(address _user) external onlyOwner returns (uint256 claimed) {
        require(_user != beneficiary, "not possible");
        claimed = _claim(_user, _user);
        uint256 totalLeft;
        uint256 len = user2vesting[_user].length;
        uint256 i;
        for (i; i < len; i++) {
            Vest memory v = vestings[user2vesting[_user][i] - 1];
            totalLeft += (v.totalTokens - v.claimedTokens);
        }
        contractVest.totalTokens += totalLeft;
        contractVest.startTokens += totalLeft.mulTruncate(vestingDiv);
        delete user2vesting[_user];
        emit VestRemoved(_user, totalLeft);
    }

    /**
     * @dev Claim tokens from msg.sender vestings
     * @return amount of tokens released
     */
    function claim() external returns (uint256) {
        return _claim(msg.sender, msg.sender);
    }

    /**
     * @dev Claim tokens from msg.sender vestings to external address
     * @param _target transfer address for claimed tokens
     * @return number of tokens released
     */
    function claimTo(address _target) external returns (uint256) {
        return _claim(msg.sender, _target);
    }

    /**
     * @dev Internal claim function
     * @param _user address of holder
     * @param _target where tokens should be send
     * @return amt number of tokens claimed
     */
    function _claim(address _user, address _target) internal returns (uint256 amt) {
        require(_target != address(0), "claim, then burn");
        uint256 cl;
        if (_user != beneficiary) {
            uint256 len = user2vesting[_user].length;
            require(len > 0, "No vestings for user");
            uint256 i;
            for (i; i < len; i++) {
                Vest storage v = vestings[user2vesting[_user][i] - 1];
                cl = _claimable(v);
                v.claimedTokens += cl;
                amt += cl;
            }
        } else {
            cl = _claimable(contractVest);
            contractVest.claimedTokens += cl;
            amt += cl;
        }

        if (amt > 0) {
            _transfer(_target, amt);
            emit Claimed(_user, amt);
        }
    }

    /**
     * @dev Internal function to send out claimed tokens
     * @param _user address that we send tokens
     * @param _amt amount of tokens
     */
    function _transfer(address _user, uint256 _amt) internal {
        totalClaimed += _amt;
        require(IERC20(token).transfer(_user, _amt), "Token transfer failed");
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
            canWithdraw = (_vesting.totalTokens - _vesting.startTokens).mulTruncate(timeRatio) + _vesting.startTokens;
        }
        // time has passed, we can take all tokens
        else {
            canWithdraw = _vesting.totalTokens;
        }
        // but maybe we take something earlier?
        if (canWithdraw > _vesting.claimedTokens) {
            canWithdraw -= _vesting.claimedTokens;
        } else {
            canWithdraw = 0;
        }
    }

    /**
     * @dev Read amount of claimable tokens by user and by vesting number
     * @param _user address of holder
     * @param _id his vesting number (starts from 0)
     * @return amount of tokens
     */
    function getClaimable(address _user, uint256 _id) external view returns (uint256 amount) {
        amount = _claimable(vestings[user2vesting[_user][_id] - 1]);
    }

    /**
     * @dev Read total amount of tokens that user can claim to date from all vestings
     * @param _user address of holder
     * @return amount of tokens
     */
    function getAllClaimable(address _user) external view returns (uint256 amount) {
        uint256 len = user2vesting[_user].length;
        uint256 i;
        for (i; i < len; i++) {
            amount += _claimable(vestings[user2vesting[_user][i] - 1]);
        }
    }

    /**
     * @dev Read total amount of tokens that beneficiary can claim
     * @return amount of tokens
     */
    function getBeneficiaryClaimable() external view returns (uint256 amount) {
        amount += _claimable(contractVest);
    }

    /**
     * @dev Extract all the vestings for the user
     * @param _user address of holder
     * @return array of Vest objects
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
        require(_end < len, "Range error");
        Vest[] memory v = new Vest[](cnt);
        uint256 i;
        for (i; i < cnt; i++) {
            v[i] = vestings[_start + i];
        }
        return v;
    }
}

