// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./BumperAccessControl.sol";

contract Vesting is Initializable, BumperAccessControl {
    using SafeERC20 for IERC20;

    /**
    Paused: Vesting is paused. Recipient can be Unpaused by the owner.
    UnPaused: Vesting is unpaused. The vesting resumes from the time it was paused (in case the recipient was paused).
    Terminated: Recipient is terminated, meaning vesting is stopped and claims are blocked forever. No way to go back. 
    */
    enum Status {Terminated, Paused, UnPaused}

    struct Recipient {
        uint256 startTime; // timestamp at which vesting period will start
        uint256 endTime; // timestamp at which vesting period will end
        uint256 cliffDuration; // time duration after startTime before which the recipient cannot call claim
        uint256 lastPausedAt; // latest timestamp at which vesting was paused
        uint256 vestingPerSec; // constant number of tokens that will be vested per second.
        uint256 totalVestingAmount; // total amount that can be vested over the vesting period.
        uint256 onStartVestingAmount; // amount that can be vested after start + cliffDuration.
        uint256 totalClaimed; // total amount of tokens that have been claimed by the recipient.
        Status recipientVestingStatus; // current vesting status
    }

    mapping(address => Recipient) public recipients; // mapping from recipient address to Recipient struct
    mapping(address => bool) public lockedTokensSeizedFor; // in case of escrow termination, a mapping to keep track of which
    address public token; // vesting token address
    // WARNING: The contract assumes that the token address is NOT malicious.

    uint256 public dust; // total amount of token that is sitting as dust in this contract (unallocatedSupply)
    uint256 public totalClaimed; // total number of tokens that have been claimed.
    uint256 public totalAllocatedSupply; // total token allocated to the recipients via addRecipients.
    uint256 public ESCROW_TERMINATED_AT; // timestamp at which escow terminated.
    address public SAFE_ADDRESS; // an address where all the funds are sent in case any recipient or vesting escrow is terminated.
    bool public ESCROW_TERMINATED; // global switch to terminate the vesting escrow. See more info in terminateVestingEscrow()

    modifier escrowNotTerminated() {
        // escrow should NOT be in terminated state
        require(!ESCROW_TERMINATED, "escrowNotTerminated: escrow terminated");
        _;
    }

    modifier isNonZeroAddress(address recipient) {
        // recipient should NOT be a 0 address
        require(recipient != address(0), "isNonZeroAddress: 0 address");
        _;
    }

    modifier recipientIsUnpaused(address recipient) {
        // recipient should NOT be a 0 address
        require(recipient != address(0), "recipientIsUnpaused: 0 address");
        // recipient should be in UnPaused status
        require(
            recipients[recipient].recipientVestingStatus == Status.UnPaused,
            "recipientIsUnpaused: recipient NOT in UnPaused state"
        );
        _;
    }

    modifier recipientIsNotTerminated(address recipient) {
        // recipient should NOT be a 0 address
        require(recipient != address(0), "recipientIsNotTerminated: 0 address");
        // recipient should NOT be in Terminated status
        require(
            recipients[recipient].recipientVestingStatus != Status.Terminated,
            "recipientIsNotTerminated: recipient terminated"
        );
        _;
    }

    ///@notice Will initialize state variables of this contract
    ///@param _whitelistAddresses Array of white list addresses
    function initialize(address _token, address _safeAddress, address[] memory _whitelistAddresses ) public initializer {
        _BumperAccessControl_init(_whitelistAddresses);
        // SAFE_ADDRESS should NOT be 0 address
        require(
            _safeAddress != address(0),
            "constructor: SAFE_ADDRESS cannot be 0 address"
        );
        // token should NOT be 0 address
        require(_token != address(0), "constructor: token cannot be 0 address");
        SAFE_ADDRESS = _safeAddress;
        token = _token;
        ESCROW_TERMINATED = false;
    }

    /// @notice Terminates the vesting escrow forever.
    /// @dev All the vesting states will be freezed, recipients can still claim their vested tokens.
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Can only be invoked if the escrow is NOT terminated.
    function terminateVestingEscrow() external onlyGovernance escrowNotTerminated {
        // set termination variables
        ESCROW_TERMINATED = true;
        ESCROW_TERMINATED_AT = block.timestamp;
    }

    /// @notice Updates the SAFE_ADDRESS
    /// @dev It is assumed that the SAFE_ADDRESS is NOT malicious
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Can only be invoked if the escrow is NOT terminated.
    /// @param safeAddress An address where all the tokens are transferred in case of a (recipient/escrow) termination
    function updateSafeAddress(address safeAddress)
        external
        onlyGovernance
        escrowNotTerminated
    {
        // Check if the safeAddress is NOT a 0 address
        require(
            safeAddress != address(0),
            "updateSafeAddress: SAFE_ADDRESS cannot be 0 address"
        );
        SAFE_ADDRESS = safeAddress;
    }

    /// @notice Add and fund new recipients.
    /// @dev Owner of the vesting escrow needs to approve tokens to this contract
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Can only be invoked if the escrow is NOT terminated.
    /// @param _recipients An array of recipient addresses
    /// @param _amounts An array of amounts to be vested by the corresponding recipient addresses
    /// @param _totalAmount Total sum of the amounts in the _amounts array
    function addRecipients(
        address[] calldata _recipients,
        bytes[] calldata _amounts,
        bytes[] calldata _times,
        uint256 _totalAmount
    ) external onlyGovernance escrowNotTerminated {
        // Every input should be of equal length (greater than 0)
        require(
            (_recipients.length == _amounts.length) &&
                (_amounts.length == _times.length) &&
                (_recipients.length != 0),
            "addRecipients: invalid params"
        );

        // _totalAmount should be greater than 0
        require(
            _totalAmount > 0,
            "addRecipients: zero totalAmount not allowed"
        );

        // transfer funds from the msg.sender
        // Will fail if the allowance is less than _totalAmount
        IERC20(token).safeTransferFrom(msg.sender, address(this), _totalAmount);

        // register _totalAmount before allocation
        uint256 _before = _totalAmount;

        // populate recipients mapping
        for (uint256 i = 0; i < _amounts.length; i++) {
            address _recipientsAddress = _recipients[i];

            uint256 _startTime;
            uint256 _endTime;
            uint256 _cliffDuration;

            uint256 _amount;
            uint256 _onStartAmount;

            (_startTime, _endTime, _cliffDuration) = abi.decode((_times[i]), (uint256, uint256, uint256));
            (_amount, _onStartAmount) = abi.decode((_amounts[i]), (uint256, uint256));

            // recipient should NOT be a 0 address
            require(
                _recipientsAddress != address(0),
                "addRecipients: recipient cannot be 0 address"
            );

            require(
                _cliffDuration < _endTime - _startTime,
                "addRecipients: cliffDuration too long"
            );

            require(
                _amount + _onStartAmount > 0,
                "addRecipients: vesting amount cannot be 0"
            );

            recipients[_recipientsAddress] = Recipient(
                _startTime, //startTime
                _endTime, //endTime
                _cliffDuration, //cliffDuration
                0, //lastPausedAt
                _amount/(_endTime - (_startTime + _cliffDuration)), //vestingPerSec
                _amount + _onStartAmount, //totalVestingAmount
                _onStartAmount, //onStartVestingAmount
                0, //totalClaimed
                Status.UnPaused //recipientVestingStatus
            );
            // reduce _totalAmount
            // Will revert if the _totalAmount is less than sum of _amounts
            _totalAmount = _totalAmount - (_amount + _onStartAmount);
        }
        // add the allocated token amount to totalAllocatedSupply
        totalAllocatedSupply = totalAllocatedSupply + (_before - _totalAmount);
        // register remaining _totalAmount as dust
        dust = dust + _totalAmount;
    }

    /// @notice Pause recipient vesting
    /// @dev This freezes the vesting schedule for the paused recipient.
    ///      Recipient will NOT be able to claim until unpaused.
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Can only be invoked if the escrow is NOT terminated.
    /// @param recipient The recipient address for which vesting will be paused.
    function pauseRecipient(address recipient)
        external
        onlyGovernance
        escrowNotTerminated
        isNonZeroAddress(recipient)
    {
        // current recipient status should be UnPaused
        require(
            recipients[recipient].recipientVestingStatus == Status.UnPaused,
            "pauseRecipient: cannot pause"
        );
        // set vesting status of the recipient as Paused
        recipients[recipient].recipientVestingStatus = Status.Paused;
        // set lastPausedAt timestamp
        recipients[recipient].lastPausedAt = block.timestamp;
    }

    /// @notice UnPause recipient vesting
    /// @dev This unfreezes the vesting schedule for the paused recipient. Recipient will be able to claim.
    ///      In order to keep vestingPerSec for the recipient a constant, cliffDuration and endTime for the
    ///      recipient are shifted by the pause duration so that the recipient resumes with the same state
    ///      at the time it was paused.
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Can only be invoked if the escrow is NOT terminated.
    /// @param recipient The recipient address for which vesting will be unpaused.
    function unPauseRecipient(address recipient)
        external
        onlyGovernance
        escrowNotTerminated
        isNonZeroAddress(recipient)
    {
        // current recipient status should be Paused
        require(
            recipients[recipient].recipientVestingStatus == Status.Paused,
            "unPauseRecipient: cannot unpause"
        );
        // set vesting status of the recipient as "UnPaused"
        recipients[recipient].recipientVestingStatus = Status.UnPaused;
        // calculate the time for which the recipient was paused for
        uint256 pausedFor = block.timestamp - recipients[recipient].lastPausedAt;
        // extend the cliffDuration by the pause duration
        recipients[recipient].cliffDuration = recipients[recipient].cliffDuration + pausedFor;
        // extend the endTime by the pause duration
        recipients[recipient].endTime = recipients[recipient].endTime + pausedFor;
    }

    /// @notice Terminate recipient vesting
    /// @dev This terminates the vesting schedule for the recipient forever.
    ///      Recipient will NOT be able to claim.
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Can only be invoked if the escrow is NOT terminated.
    /// @param recipient The recipient address for which vesting will be terminated.
    function terminateRecipient(address recipient)
        external
        onlyGovernance
        escrowNotTerminated
        isNonZeroAddress(recipient)
    {
        // current recipient status should NOT be Terminated
        require(
            recipients[recipient].recipientVestingStatus != Status.Terminated,
            "terminateRecipient: cannot terminate"
        );
        // claim for the user if possible
        if (canClaim(recipient)) {
            // transfer unclaimed tokens to the recipient
            _claimFor(claimableAmountFor(recipient), recipient);
            // transfer locked tokens to the SAFE_ADDRESS
        }
        uint256 _bal = recipients[recipient].totalVestingAmount - recipients[recipient].totalClaimed;
        IERC20(token).safeTransfer(SAFE_ADDRESS, _bal);
        // set vesting status of the recipient as "Terminated"
        recipients[recipient].recipientVestingStatus = Status.Terminated;
    }

    /// @notice Claim a specific amount of tokens.
    /// @dev Claim a specific amount of tokens.
    ///      Will revert if amount parameter is greater than the claimable amount
    ///      of tokens for the recipient at the time of function invocation.
    ///      Can be invoked by any non-terminated recipient.
    /// @param amount The amount of tokens recipient wants to claim.
    function claim(uint256 amount) external {
        _claimFor(amount, msg.sender);
    }

    // claim tokens for a specific recipient
    function _claimFor(uint256 _amount, address _recipient) internal {
        // get recipient
        Recipient storage recipient = recipients[_recipient];

        // recipient should be able to claim
        require(canClaim(_recipient), "_claimFor: recipient cannot claim");

        // max amount the user can claim right now
        uint256 claimableAmount = claimableAmountFor(_recipient);

        // amount parameter should be less or equal to than claimable amount
        require(
            _amount <= claimableAmount,
            "_claimFor: cannot claim passed amount"
        );

        // increase user specific totalClaimed
        recipient.totalClaimed = recipient.totalClaimed +_amount;

        // user's totalClaimed should NOT be greater than user's totalVestingAmount
        require(
            recipient.totalClaimed <= recipient.totalVestingAmount,
            "_claimFor: cannot claim more than you deserve"
        );

        // increase global totalClaimed
        totalClaimed = totalClaimed + _amount;

        // totalClaimed should NOT be greater than total totalAllocatedSupply
        require(
            totalClaimed <= totalAllocatedSupply,
            "_claimFor: cannot claim more than allocated to escrow"
        );

        // transfer the amount to the _recipient
        IERC20(token).safeTransfer(_recipient, _amount);
    }

    /// @notice Get total vested tokens for multiple recipients.
    /// @dev Reverts if any of the recipients is terminated.
    /// @param _recipients An array of non-terminated recipient addresses.
    /// @return totalAmount total vested tokens for all _recipients passed.
    function batchTotalVestedOf(address[] memory _recipients)
        public
        view
        returns (uint256 totalAmount)
    {
        for (uint256 i = 0; i < _recipients.length; i++) {
            totalAmount = totalAmount + totalVestedOf(_recipients[i]);
        }
    }

    /// @notice Get total vested tokens of a specific recipient.
    /// @dev Reverts if the recipient is terminated.
    /// @param recipient A non-terminated recipient address.
    /// @return Total vested tokens for the recipient address.
    function totalVestedOf(address recipient)
        public
        view
        recipientIsNotTerminated(recipient)
        returns (uint256)
    {
        // get recipient
        Recipient memory _recipient = recipients[recipient];

        // totalVested = totalClaimed + claimableAmountFor
        return _recipient.totalClaimed + claimableAmountFor(recipient);
    }

    /// @notice Check if a recipient address can successfully invoke claim.
    /// @dev Reverts if the recipient is a zero address.
    /// @param recipient A zero address recipient address.
    /// @return bool representing if the recipient can successfully invoke claim.
    function canClaim(address recipient)
        public
        view
        isNonZeroAddress(recipient)
        returns (bool)
    {
        Recipient memory _recipient = recipients[recipient];

        // terminated recipients cannot claim
        if (_recipient.recipientVestingStatus == Status.Terminated) {
            return false;
        }

        // In case of a paused recipient
        if (_recipient.recipientVestingStatus == Status.Paused) {
            return
                _recipient.lastPausedAt >=
                _recipient.startTime + _recipient.cliffDuration;
        }

        // In case of a unpaused recipient, recipient can claim if the cliff duration (inclusive) has passed.
        return
            block.timestamp >=
            _recipient.startTime + _recipient.cliffDuration;
    }

    /// @notice Check the time after (inclusive) which recipient can successfully invoke claim.
    /// @dev Reverts if the recipient is a zero address.
    /// @param recipient A zero address recipient address.
    /// @return Returns the time after (inclusive) which recipient can successfully invoke claim.
    function claimStartTimeFor(address recipient)
        public
        view
        escrowNotTerminated
        recipientIsUnpaused(recipient)
        returns (uint256)
    {
        return
            recipients[recipient].startTime + recipients[recipient].cliffDuration;
    }

    /// @notice Get amount of tokens that can be claimed by a recipient at the current timestamp.
    /// @dev Reverts if the recipient is terminated.
    /// @param recipient A non-terminated recipient address.
    /// @return Amount of tokens that can be claimed by a recipient at the current timestamp.
    function claimableAmountFor(address recipient)
        public
        view
        recipientIsNotTerminated(recipient)
        returns (uint256)
    {
        // get recipient
        Recipient memory _recipient = recipients[recipient];

        // claimable = totalVestingAmount - (totalClaimed + locked)
        return
            _recipient.totalVestingAmount - (_recipient.totalClaimed + totalLockedOf(recipient));
    }

    /// @notice Get total locked (non-vested) tokens for multiple non-terminated recipient addresses.
    /// @dev Reverts if any of the recipients is terminated.
    /// @param _recipients An array of non-terminated recipient addresses.
    /// @return totalAmount Total locked (non-vested) tokens for multiple non-terminated recipient addresses.
    function batchTotalLockedOf(address[] memory _recipients)
        public
        view
        returns (uint256 totalAmount)
    {
        for (uint256 i = 0; i < _recipients.length; i++) {
            totalAmount = totalAmount + totalLockedOf(_recipients[i]);
        }
    }

    /// @notice Get total locked tokens of a specific recipient.
    /// @dev Reverts if any of the recipients is terminated.
    /// @param recipient A non-terminated recipient address.
    /// @return Total locked tokens of a specific recipient.
    function totalLockedOf(address recipient)
        public
        view
        recipientIsNotTerminated(recipient)
        returns (uint256)
    {
        Recipient storage _recipient = recipients[recipient];

        uint256 _durationLock = 0;
        uint256 _onStartVestingAmountLock = 0;
        (_durationLock, _onStartVestingAmountLock) = getDurationLockAndOnStartVesting(_recipient);
        return _recipient.vestingPerSec * _durationLock + _onStartVestingAmountLock;
    }

    function getDurationLockAndOnStartVesting(Recipient storage _recipient) internal view returns(uint256, uint256){
        // in case escrow is terminated, locked amount stays the constant
        if (ESCROW_TERMINATED) {
            if (ESCROW_TERMINATED_AT > _recipient.startTime +_recipient.cliffDuration) {
                return (
                    _recipient.endTime - ESCROW_TERMINATED_AT, 
                    0
                );
            }
            else {
                return (
                    _recipient.endTime - (_recipient.startTime +_recipient.cliffDuration), 
                    _recipient.onStartVestingAmount
                );
            }
        }

        // We know that vestingPerSec is constant for a recipient for entirety of their vesting period
        // locked = vestingPerSec*(endTime-max(lastPausedAt, startTime+cliffDuration))
        if (_recipient.recipientVestingStatus == Status.Paused) {
            if (_recipient.lastPausedAt >= _recipient.endTime) {
                return (
                    0, 
                    0
                );
            } else if (_recipient.lastPausedAt > _recipient.startTime + _recipient.cliffDuration) {
                return (
                    _recipient.endTime - _recipient.lastPausedAt,
                    0
                );
            }
            else {
                return (
                    _recipient.endTime - (_recipient.startTime + _recipient.cliffDuration),
                    _recipient.onStartVestingAmount
                );
            }
        }

        if (block.timestamp >= _recipient.endTime) {
            return (
                0, 
                0
            );
        } else if (block.timestamp >= _recipient.startTime + _recipient.cliffDuration) {
            return (
                _recipient.endTime - block.timestamp,
                0
            );
        }
        else {
            return (
                _recipient.endTime - (_recipient.startTime + _recipient.cliffDuration),
                _recipient.onStartVestingAmount
            );
        }
    }

    /// @notice Allows owner to transfer the ERC20 assets (other than token) to the "to" address in case of any emergency
    /// @dev It is assumed that the "to" address is NOT malicious
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Reverts if the asset address is a zero address or the token address.
    ///      Reverts if the to address is a zero address.
    /// @param asset Address of the ERC20 asset to be rescued
    /// @param to Address to which all ERC20 asset amount will be transferred
    /// @return rescued Total amount of asset transferred to the SAFE_ADDRESS.
    function inCaseAssetGetStuck(address asset, address to)
        external
        onlyGovernance
        returns (uint256 rescued)
    {
        // asset address should NOT be a 0 address
        require(
            asset != address(0),
            "inCaseAssetGetStuck: asset cannot be 0 address"
        );
        // asset address should NOT be the token address
        require(asset != token, "inCaseAssetGetStuck: cannot withdraw token");
        // to address should NOT a 0 address
        require(
            to != address(0),
            "inCaseAssetGetStuck: to cannot be 0 address"
        );
        // transfer all the balance of the asset this contract hold to the "to" address
        rescued = IERC20(asset).balanceOf(address(this));
        IERC20(asset).safeTransfer(to, rescued);
    }

    /// @notice Transfers the dust to the SAFE_ADDRESS.
    /// @dev It is assumed that the SAFE_ADDRESS is NOT malicious.
    ///      Only owner of the vesting escrow can invoke this function.
    /// @return Amount of dust to the SAFE_ADDRESS.
    function transferDust() external onlyGovernance returns (uint256) {
        // precaution for reentrancy attack
        if (dust > 0) {
            uint256 _dust = dust;
            dust = 0;
            IERC20(token).safeTransfer(SAFE_ADDRESS, _dust);
            return _dust;
        }
        return 0;
    }

    /// @notice Transfers the locked (non-vested) tokens of the passed recipients to the SAFE_ADDRESS
    /// @dev It is assumed that the SAFE_ADDRESS is NOT malicious
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Reverts if any of the recipients is terminated.
    ///      Can only be invoked if the escrow is terminated.
    /// @param _recipients An array of non-terminated recipient addresses.
    /// @return totalSeized Total tokens seized from the recipients.
    function seizeLockedTokens(address[] calldata _recipients)
        external
        onlyGovernance
        returns (uint256 totalSeized)
    {
        // only seize if escrow is terminated
        require(ESCROW_TERMINATED, "seizeLockedTokens: escrow not terminated");
        // get the total tokens to be seized
        for (uint256 i = 0; i < _recipients.length; i++) {
            // only seize tokens from the recipients which have not been seized before
            if (!lockedTokensSeizedFor[_recipients[i]]) {
                totalSeized = totalSeized + totalLockedOf(_recipients[i]);
                lockedTokensSeizedFor[_recipients[i]] = true;
            }
        }
        // transfer the totalSeized amount to the SAFE_ADDRESS
        IERC20(token).safeTransfer(SAFE_ADDRESS, totalSeized);
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

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

///@title BumperAccessControl contract is used to restrict access of functions to onlyGovernance and onlyOwner.
///@notice This contains suitable modifiers to restrict access of functions to onlyGovernance and onlyOwner.
contract BumperAccessControl is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
{
    ///@dev This stores if a particular address is considered as whitelist or not in form of mapping.
    mapping(address => bool) internal whitelist;

    event AddressAddedToWhitelist(address newWhitelistAddress);
    event AddressRemovedFromWhitelist(address removedWhitelistAddress);

    function _BumperAccessControl_init(address[] memory _whitelist)
        internal
        initializer
    {
        __Context_init_unchained();
        __Ownable_init();
        ///Setting white list addresses as true
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
        }
    }

    modifier onlyGovernance {
        require(whitelist[_msgSender()], "Address not in whitelist.");
        _;
    }

    modifier onlyGovernanceOrOwner {
        require(
            whitelist[_msgSender()] || owner() == _msgSender(),
            "Neither a whitelist address nor an owner."
        );
        _;
    }

    ///@dev It sets this address as true in whitelist address mapping
    ///@param addr Address that is set as whitelist address
    function addAddressToWhitelist(address addr) external onlyGovernance {
        whitelist[addr] = true;
        emit AddressAddedToWhitelist(addr);
    }

    ///@dev It sets passed address as false in whitelist address mapping
    ///@param addr Address that is removed as whitelist address
    function removeAddressFromWhitelist(address addr) external onlyGovernance {
        whitelist[addr] = false;
        emit AddressRemovedFromWhitelist(addr);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}