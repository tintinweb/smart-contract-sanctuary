// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/timelock/QuadraticTokenTimelock.sol";

interface IVotingToken is IERC20 {
    function delegate(address delegatee) external;
}

/// @title a timelock for tokens allowing for bulk delegation
/// @author Fei Protocol
/// @notice allows the timelocked tokens to be delegated by the beneficiary while locked
contract QuadraticTimelockedDelegator is QuadraticTokenTimelock {
    /// @notice QuadraticTimelockedDelegator constructor
    /// @param _token the token address
    /// @param _beneficiary admin, and timelock beneficiary
    /// @param _duration duration of the token timelock window
    /// @param _cliff the seconds before first claim is allowed
    /// @param _clawbackAdmin the address which can trigger a clawback
    /// @param _startTime the unix epoch for starting timelock. Use 0 to start at deployment
    constructor(
        address _token,
        address _beneficiary,
        uint256 _duration,
        uint256 _cliff,
        address _clawbackAdmin,
        uint256 _startTime
    ) QuadraticTokenTimelock(_beneficiary, _duration, _token, _cliff, _clawbackAdmin, _startTime) {}

    /// @notice accept beneficiary role over timelocked TRIBE
    function acceptBeneficiary() public override {
        _setBeneficiary(msg.sender);
    }

    /// @notice delegate all held TRIBE to the `to` address
    function delegate(address to) public onlyBeneficiary {
        IVotingToken(address(lockedToken)).delegate(to);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./TokenTimelock.sol";

contract QuadraticTokenTimelock is TokenTimelock {

    constructor (
        address _beneficiary,
        uint256 _duration,
        address _lockedToken,
        uint256 _cliffDuration,
        address _clawbackAdmin,
        uint256 _startTime
    ) TokenTimelock(
        _beneficiary, 
        _duration, 
        _cliffDuration,
        _lockedToken, 
        _clawbackAdmin
    ) {
        if (_startTime != 0) {
            startTime = _startTime;
        }
    }

    function _proportionAvailable(
        uint256 initialBalance,
        uint256 elapsed,
        uint256 duration
    ) internal pure override returns (uint256) {
        return initialBalance * elapsed * elapsed / duration / duration;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

// Inspired by OpenZeppelin TokenTimelock contract
// Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/TokenTimelock.sol

import "../Timed.sol";
import "./ITokenTimelock.sol";

abstract contract TokenTimelock is ITokenTimelock, Timed {

    /// @notice ERC20 basic token contract being held in timelock
    IERC20 public override lockedToken;

    /// @notice beneficiary of tokens after they are released
    address public override beneficiary;

    /// @notice pending beneficiary appointed by current beneficiary
    address public override pendingBeneficiary;

    /// @notice initial balance of lockedToken
    uint256 public override initialBalance;

    uint256 internal lastBalance;

    /// @notice number of seconds before releasing is allowed
    uint256 public immutable cliffSeconds;

    address public immutable clawbackAdmin;

    constructor(
        address _beneficiary,
        uint256 _duration,
        uint256 _cliffSeconds,
        address _lockedToken,
        address _clawbackAdmin
    ) Timed(_duration) {
        require(_duration != 0, "TokenTimelock: duration is 0");
        require(
            _beneficiary != address(0),
            "TokenTimelock: Beneficiary must not be 0 address"
        );

        beneficiary = _beneficiary;
        _initTimed();

        _setLockedToken(_lockedToken);

        cliffSeconds = _cliffSeconds;

        clawbackAdmin = _clawbackAdmin;
    }

    // Prevents incoming LP tokens from messing up calculations
    modifier balanceCheck() {
        if (totalToken() > lastBalance) {
            uint256 delta = totalToken() - lastBalance;
            initialBalance = initialBalance + delta;
        }
        _;
        lastBalance = totalToken();
    }

    modifier onlyBeneficiary() {
        require(
            msg.sender == beneficiary,
            "TokenTimelock: Caller is not a beneficiary"
        );
        _;
    }

    /// @notice releases `amount` unlocked tokens to address `to`
    function release(address to, uint256 amount) external override onlyBeneficiary balanceCheck {
        require(amount != 0, "TokenTimelock: no amount desired");
        require(passedCliff(), "TokenTimelock: Cliff not passed");

        uint256 available = availableForRelease();
        require(amount <= available, "TokenTimelock: not enough released tokens");

        _release(to, amount);
    }

    /// @notice releases maximum unlocked tokens to address `to`
    function releaseMax(address to) external override onlyBeneficiary balanceCheck {
        require(passedCliff(), "TokenTimelock: Cliff not passed");
        _release(to, availableForRelease());
    }

    /// @notice the total amount of tokens held by timelock
    function totalToken() public view override virtual returns (uint256) {
        return lockedToken.balanceOf(address(this));
    }

    /// @notice amount of tokens released to beneficiary
    function alreadyReleasedAmount() public view override returns (uint256) {
        return initialBalance - totalToken();
    }

    /// @notice amount of held tokens unlocked and available for release
    function availableForRelease() public view override returns (uint256) {
        uint256 elapsed = timeSinceStart();

        uint256 totalAvailable = _proportionAvailable(initialBalance, elapsed, duration);
        uint256 netAvailable = totalAvailable - alreadyReleasedAmount();
        return netAvailable;
    }

    /// @notice current beneficiary can appoint new beneficiary, which must be accepted
    function setPendingBeneficiary(address _pendingBeneficiary)
        public
        override
        onlyBeneficiary
    {
        pendingBeneficiary = _pendingBeneficiary;
        emit PendingBeneficiaryUpdate(_pendingBeneficiary);
    }

    /// @notice pending beneficiary accepts new beneficiary
    function acceptBeneficiary() public override virtual {
        _setBeneficiary(msg.sender);
    }

    function clawback() public balanceCheck {
        require(msg.sender == clawbackAdmin, "TokenTimelock: Only clawbackAdmin");
        if (passedCliff()) {
            _release(beneficiary, availableForRelease());
        }
        _release(clawbackAdmin, totalToken());
    }

    function passedCliff() public view returns (bool) {
        return timeSinceStart() >= cliffSeconds;
    }

    function _proportionAvailable(uint256 initialBalance, uint256 elapsed, uint256 duration) internal pure virtual returns (uint256);

    function _setBeneficiary(address newBeneficiary) internal {
        require(
            newBeneficiary == pendingBeneficiary,
            "TokenTimelock: Caller is not pending beneficiary"
        );
        beneficiary = newBeneficiary;
        emit BeneficiaryUpdate(newBeneficiary);
        pendingBeneficiary = address(0);
    }

    function _setLockedToken(address tokenAddress) internal {
        lockedToken = IERC20(tokenAddress);
    }

    function _release(address to, uint256 amount) internal {
        lockedToken.transfer(to, amount);
        emit Release(beneficiary, to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title an abstract contract for timed events
/// @author Fei Protocol
abstract contract Timed {

    /// @notice the start timestamp of the timed period
    uint256 public startTime;

    /// @notice the duration of the timed period
    uint256 public duration;

    event DurationUpdate(uint256 oldDuration, uint256 newDuration);

    event TimerReset(uint256 startTime);

    constructor(uint256 _duration) {
        _setDuration(_duration);
    }

    modifier duringTime() {
        require(isTimeStarted(), "Timed: time not started");
        require(!isTimeEnded(), "Timed: time ended");
        _;
    }

    modifier afterTime() {
        require(isTimeEnded(), "Timed: time not ended");
        _;
    }

    /// @notice return true if time period has ended
    function isTimeEnded() public view returns (bool) {
        return remainingTime() == 0;
    }

    /// @notice number of seconds remaining until time is up
    /// @return remaining
    function remainingTime() public view returns (uint256) {
        return duration - timeSinceStart(); // duration always >= timeSinceStart which is on [0,d]
    }

    /// @notice number of seconds since contract was initialized
    /// @return timestamp
    /// @dev will be less than or equal to duration
    function timeSinceStart() public view returns (uint256) {
        if (!isTimeStarted()) {
            return 0; // uninitialized
        }
        uint256 _duration = duration;
        uint256 timePassed = block.timestamp - startTime; // block timestamp always >= startTime
        return timePassed > _duration ? _duration : timePassed;
    }

    function isTimeStarted() public view returns (bool) {
        return startTime != 0;
    }

    function _initTimed() internal {
        startTime = block.timestamp;
        
        emit TimerReset(block.timestamp);
    }

    function _setDuration(uint256 newDuration) internal {
        require(newDuration != 0, "Timed: zero duration");

        uint256 oldDuration = duration;
        duration = newDuration;
        emit DurationUpdate(oldDuration, newDuration);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title TokenTimelock interface
/// @author Fei Protocol
interface ITokenTimelock {
    // ----------- Events -----------

    event Release(address indexed _beneficiary, address indexed _recipient, uint256 _amount);
    event BeneficiaryUpdate(address indexed _beneficiary);
    event PendingBeneficiaryUpdate(address indexed _pendingBeneficiary);

    // ----------- State changing api -----------

    function release(address to, uint256 amount) external;

    function releaseMax(address to) external;

    function setPendingBeneficiary(address _pendingBeneficiary) external;

    function acceptBeneficiary() external;


    // ----------- Getters -----------

    function lockedToken() external view returns (IERC20);

    function beneficiary() external view returns (address);

    function pendingBeneficiary() external view returns (address);

    function initialBalance() external view returns (uint256);

    function availableForRelease() external view returns (uint256);

    function totalToken() external view returns(uint256);

    function alreadyReleasedAmount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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