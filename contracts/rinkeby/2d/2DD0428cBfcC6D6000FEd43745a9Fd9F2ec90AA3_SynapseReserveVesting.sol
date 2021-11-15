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

import { Ownable } from "./Ownable.sol";

abstract contract LockableData {
    bool public locked;
}

abstract contract Lockable is LockableData, Ownable {
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

import { StableMath } from "../libraries/StableMath.sol";
import { Ownable } from "../abstract/Ownable.sol";
import { Beneficiary } from "../abstract/Beneficiary.sol";
import { Lockable } from "../abstract/Lockable.sol";

/**
 * @title   SynapseMultiVesting
 * @notice  Synapse Network Multi Purpose Vesting contract
 * @dev     Vesting is constantly releasing tokens every block every second.
 *          Only beneficiary can claim from the vesting.
 */
contract SynapseMultiVesting is Ownable, Beneficiary, Lockable {
    using StableMath for uint256;

    /// @notice address of Synapse Network token
    address public immutable token;

    /// @notice single vest parameters
    struct Vest {
        uint256 cliff; // tokens claimable at start time
        uint256 total; // total tokens to claim
        uint256 start; // vesting start time
        uint256 end; // vesting end time
        uint256 claimed; // tokens already claimed
    }
    /// @notice list of all vestings in contract, max 2 (LP vest)
    Vest[] public vestings;

    /// @dev events
    event Claimed(address indexed user, uint256 amount);

    /**
     * @notice Contract constructor
     * @param _token SNP token address
     */
    constructor(address _token) {
        require(_token != address(0), "_token address cannot be 0");
        token = _token;
    }

    /**
     * @dev Add vesting for given purpose
     * @param _cliff number of tokens that can be claimed at start time
     * @param _total total number of tokens claimed after end time
     * @param _start timestamp to release first tokens
     * @param _end timestamp to release all tokens
     */
    function addVesting(
        uint256 _cliff,
        uint256 _total,
        uint256 _start,
        uint256 _end
    ) external whenNotLocked onlyOwner {
        require(vestings.length < 2, "Max 2 vestings");
        require(_end > _start, "_start cannot exceed _end");
        require(_total > _cliff, "_cliff cannot exceed _total");
        Vest memory v = Vest(_cliff, _total, _start, _end, 0);
        vestings.push(v);
    }

    /**
     * @dev Claim all possible tokens, only beneficiary can call
     */
    function claim() external whenLocked onlyBeneficiary {
        uint256 i;
        uint256 amt;
        uint256 cl;
        uint256 len = vestings.length;
        for (i; i < len; i++) {
            Vest storage v = vestings[i];
            cl = _claimable(v);
            v.claimed += cl;
            amt += cl;
        }
        if (amt > 0) {
            _transfer(beneficiary, amt);
            emit Claimed(beneficiary, amt);
        } else revert("Nothing to claim");
    }

    /**
     * @dev Count how many tokens can be claimed from vesting to date
     * @param _vesting Vesting object
     * @return canWithdraw number of tokens
     */
    function _claimable(Vest memory _vesting) internal view returns (uint256 canWithdraw) {
        uint256 currentTime = block.timestamp;
        if (_vesting.start > currentTime) return 0;
        // we are somewhere in the middle
        if (currentTime < _vesting.end) {
            // how much time passed (as fraction * 10^18)
            // timeRatio = (time passed * 1e18) / duration
            uint256 timeRatio = (currentTime - _vesting.start).divPrecisely(_vesting.end - _vesting.start);
            // how much tokens we can get in total to date
            canWithdraw = (_vesting.total - _vesting.cliff).mulTruncate(timeRatio) + _vesting.cliff;
        }
        // time has passed, we can take all tokens
        else {
            canWithdraw = _vesting.total;
        }
        // but maybe we take something earlier?
        canWithdraw -= _vesting.claimed;
    }

    /**
     * @dev Internal function to send out claimed tokens
     * @param _user address that we send tokens
     * @param _amt amount of tokens
     */
    function _transfer(address _user, uint256 _amt) internal {
        require(IERC20(token).transfer(_user, _amt), "Token transfer failed");
    }

    /**
     * @dev Read total amount of tokens that beneficiary can claim to date from all vestings
     * @return amount number of tokens
     */
    function claimable() external view returns (uint256 amount) {
        uint256 len = vestings.length;
        uint256 i;
        for (i; i < len; i++) {
            amount += _claimable(vestings[i]);
        }
    }

    /**
     * @dev Extract all the vestings for the beneficiary
     * @return array of Vest objects
     */
    function getVestings() external view returns (Vest[] memory) {
        uint256 len = vestings.length;
        Vest[] memory v = new Vest[](len);
        // copy vestings
        uint256 i;
        for (i; i < len; i++) {
            v[i] = vestings[i];
        }
        return v;
    }

    /**
     * @dev Read total amount of tokens claimed by beneficiary
     * @return amount number of tokens
     */
    function totalClaimed() external view returns (uint256 amount) {
        uint256 len = vestings.length;
        uint256 i;
        for (i; i < len; i++) {
            amount += vestings[i].claimed;
        }
    }

    /**
     * @dev Recover ETH from contract to owner address.
     */
    function recoverETH() external {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev Recover given ERC20 token from contract to owner address.
     *      Can't recover SNP tokens.
     * @param _token address of ERC20 token to recover
     */
    function recoverERC20(address _token) external {
        require(_token != token, "This token is restricted");
        uint256 amt = BadErc20(_token).balanceOf(address(this));
        require(amt > 0, "Nothing to recover");
        BadErc20(_token).transfer(owner, amt);
    }
}

// proper ERC20 interface for SNP token transfers
interface IERC20 {
    function transfer(address, uint256) external returns (bool);
}

// Broken ERC20 interface for recovery (ignore return value in transfer)
interface BadErc20 {
    function balanceOf(address) external returns (uint256);

    function transfer(address, uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { SynapseMultiVesting } from "./SynapseMultiVesting.sol";

/**
 * @title   SynapseReserveVesting
 * @notice  Synapse Network Reserve Vesting contract
 * @dev     Vesting is constantly releasing tokens every block every second
 */
contract SynapseReserveVesting is SynapseMultiVesting {
    /**
     * @notice Contract constructor
     * @param _token SNP token address
     */
    constructor(address _token) SynapseMultiVesting(_token) {}
}

