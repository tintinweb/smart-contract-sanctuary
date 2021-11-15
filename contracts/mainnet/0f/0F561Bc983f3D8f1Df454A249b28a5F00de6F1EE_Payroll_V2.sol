// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.

///@author Zapper
///@notice This contract splits shares among a group of recipients on a payroll. Payment schedules can be created
/// using paymentPeriods and timelock. E.g. For a bimonthly salary of 4,000 USDC, paymentPeriods = 2, timelock = 1209600

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "../oz/0.8.0/token/ERC20/IERC20.sol";
import "../oz/0.8.0/token/ERC20/utils/SafeERC20.sol";
import "../oz/0.8.0/access/Ownable.sol";

contract Payroll_V2 is Ownable {
    using SafeERC20 for IERC20;

    struct Payroll {
        // Payroll ID
        uint256 id;
        // ERC20 token used for payment for this payroll
        IERC20 paymentToken;
        // Recurring number of periods over which shares are distributed
        uint256 paymentPeriods;
        // Number of seconds to lock payment for subsequent to a distribution
        uint256 timelock;
        // Timestamp of most recent payment
        uint256 lastPayment;
        // Quantity of tokens owed to each recipient
        mapping(address => uint256) shares;
        // Quantity of tokens paid to each recipient
        mapping(address => uint256) released;
        // Total quantity of tokens owed to all recipients
        uint256 totalShares;
        // Total quantity of tokens paid to all recipients
        uint256 totalReleased;
        // Recipients on the payroll
        address[] recipients;
    }

    //Payroll managers
    mapping(address => bool) public managers;

    // Payroll ID => Payroll
    mapping(uint256 => Payroll) private payrolls;

    // Number of payrolls that exist
    uint256 public numPayrolls;

    // Pause and unpause payments
    bool public paused;

    // Only valid managers may manage this contract
    modifier onlyManagers {
        require(managers[msg.sender], "Unapproved manager");
        _;
    }

    // Only the owner may pause this contract
    modifier Pausable {
        require(paused == false, "Paused");
        _;
    }

    // Check for valid payrolls
    modifier validPayroll(uint256 payrollID) {
        require(payrollID < numPayrolls, "Invalid payroll");
        _;
    }

    event NewPayroll(
        uint256 payrollID,
        address paymentToken,
        uint256 paymentPeriods,
        uint256 timelock
    );
    event Payment(address recipient, uint256 shares, uint256 payrollID);
    event AddRecipient(address recipient, uint256 shares, uint256 payrollID);
    event RemoveRecipient(address recipient, uint256 payrollID);
    event UpdateRecipient(address recipient, uint256 shares, uint256 payrollID);
    event UpdatePaymentToken(address token, uint256 payrollID);
    event UpdatePaymentPeriod(uint256 paymentPeriod, uint256 payrollID);
    event UpdateTimelock(uint256 timelock, uint256 payrollID);

    /**
    @notice Initializes a new empty payroll
    @param paymentToken The ERC20 token with which to make payments
    @param paymentPeriods The number of payment periods to distribute the shares owed to each recipient by
    @param timelock The number of seconds to lock payments for subsequent to a distribution
    @return payrollID - The ID of the newly created payroll
    */
    function createPayroll(
        IERC20 paymentToken,
        uint256 paymentPeriods,
        uint256 timelock
    ) external onlyManagers returns (uint256) {
        require(paymentPeriods > 0, "Payment periods must be greater than 0");

        Payroll storage payroll = payrolls[numPayrolls];
        payroll.id = numPayrolls;
        payroll.paymentToken = paymentToken;
        payroll.paymentPeriods = paymentPeriods;
        payroll.timelock = timelock;

        emit NewPayroll(
            numPayrolls++,
            address(paymentToken),
            paymentPeriods,
            timelock
        );

        return numPayrolls;
    }

    /**
    @notice Adds a new recipient to a payroll given its ID
    @param payrollID The ID of the payroll
    @param recipient The new recipient's address
    @param shares The quantitiy of tokens owed to the recipient per epoch
    */
    function addRecipient(
        uint256 payrollID,
        address recipient,
        uint256 shares
    ) public onlyManagers validPayroll(payrollID) {
        Payroll storage payroll = payrolls[payrollID];

        require(
            payroll.shares[recipient] == 0,
            "Recipient exists, use updateRecipient instead"
        );
        require(shares > 0, "Amount cannot be 0!");

        payroll.recipients.push(recipient);
        payroll.shares[recipient] = shares;
        payroll.totalShares += shares;

        emit AddRecipient(recipient, shares, payrollID);
    }

    /**
    @notice Adds several new recipients to the payroll
    @param payrollID The ID of the payroll 
    @param recipients An arary of new recipient addresses
    @param shares An array of the quantitiy of tokens owed to each recipient per payment period
    */
    function addRecipients(
        uint256 payrollID,
        address[] calldata recipients,
        uint256[] calldata shares
    ) external onlyManagers validPayroll(payrollID) {
        require(
            recipients.length == shares.length,
            "Length of recipients does not match length of shares!"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            addRecipient(payrollID, recipients[i], shares[i]);
        }
    }

    /**
    @notice Removes a recipient from a payroll given its ID
    @param payrollID The ID of the payroll
    @param recipient The address of the recipient being removed
    */
    function removeRecipient(uint256 payrollID, address recipient)
        external
        onlyManagers
        validPayroll(payrollID)
    {
        Payroll storage payroll = payrolls[payrollID];

        require(payroll.shares[recipient] > 0, "Recipient does not exist");

        payroll.totalShares -= payroll.shares[recipient];
        payroll.shares[recipient] = 0;

        uint256 i;
        for (; i < payroll.recipients.length; i++) {
            if (payroll.recipients[i] == recipient) {
                break;
            }
        }

        payroll.recipients[i] = payroll.recipients[
            payroll.recipients.length - 1
        ];
        payroll.recipients.pop();

        emit RemoveRecipient(recipient, payrollID);
    }

    /**
    
    @notice Updates recipient's owed shares
    @param payrollID The ID of the payroll
    @param recipient The recipient's address
    @param shares The quantitiy of tokens owed to the recipient per payment period
    */
    function updateRecipient(
        uint256 payrollID,
        address recipient,
        uint256 shares
    ) public onlyManagers validPayroll(payrollID) {
        require(shares > 0, "Amount cannot be 0, use removeRecipient instead");

        Payroll storage payroll = payrolls[payrollID];

        require(payroll.shares[recipient] > 0, "Recipient does not exist");

        payroll.totalShares -= payroll.shares[recipient];
        payroll.totalShares += shares;

        payroll.shares[recipient] = shares;

        emit UpdateRecipient(recipient, shares, payrollID);
    }

    /**
    @notice Updates several recipients' owed shares
    @param payrollID The ID of the payroll
    @param recipients An arary of recipient addresses
    @param shares An array of the quantitiy of tokens owed to each recipient per epoch
    */
    function updateRecipients(
        uint256 payrollID,
        address[] calldata recipients,
        uint256[] calldata shares
    ) external onlyManagers validPayroll(payrollID) {
        require(
            recipients.length == shares.length,
            "Number of recipients does not match amounts!"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            updateRecipient(payrollID, recipients[i], shares[i]);
        }
    }

    /** 
    @notice Updates the payment token
    @param payrollID The ID of the payroll
    @param paymentToken The new ERC20 token with which to make payments
    */
    function updatePaymentToken(uint256 payrollID, IERC20 paymentToken)
        external
        onlyManagers
        validPayroll(payrollID)
    {
        payrolls[payrollID].paymentToken = paymentToken;

        emit UpdatePaymentToken(address(paymentToken), payrollID);
    }

    /** 
    @notice Updates the number of payment periods
    @param payrollID The ID of the payroll to add the recipients to
    @param paymentPeriod The new number of payment periods
    */
    function updatePaymentPeriods(uint256 payrollID, uint256 paymentPeriod)
        external
        onlyManagers
        validPayroll(payrollID)
    {
        payrolls[payrollID].paymentPeriods = paymentPeriod;

        emit UpdatePaymentPeriod(paymentPeriod, payrollID);
    }

    /** 
    @notice Updates the epoch (i.e. the number of days to divide payment period by)
    @param payrollID The ID of the payroll
    @param timelock The number of seconds to lock payment for following a distribution
    */
    function updateTimelock(uint256 payrollID, uint256 timelock)
        external
        onlyManagers
        validPayroll(payrollID)
    {
        payrolls[payrollID].timelock = timelock;

        emit UpdateTimelock(timelock, payrollID);
    }

    /** 
    @notice Gets the current timelock in seconds
    @param payrollID The ID of the payroll
    */
    function getTimelock(uint256 payrollID) external view returns (uint256) {
        return payrolls[payrollID].timelock;
    }

    /** 
    @notice Gets the payment token for a payroll
    @param payrollID The ID of the payroll
    */
    function getPaymentToken(uint256 payrollID)
        external
        view
        returns (address)
    {
        return address(payrolls[payrollID].paymentToken);
    }

    /** 
    @notice Returns the quantity of tokens owed to a recipient per pay period
    @param payrollID The ID of the payroll
    @param recipient The address of the recipient
    */
    function getRecipientShares(uint256 payrollID, address recipient)
        public
        view
        returns (uint256)
    {
        Payroll storage payroll = payrolls[payrollID];
        return payroll.shares[recipient] / payroll.paymentPeriods;
    }

    /** 
    @notice Returns the total quantity of tokens paid to the recipient
    @param payrollID The ID of the payroll
    @param recipient The address of the recipient
    */
    function getRecipientReleased(uint256 payrollID, address recipient)
        public
        view
        returns (uint256)
    {
        return payrolls[payrollID].released[recipient];
    }

    /** 
    @notice Returns the quantity of tokens owed to all recipients per pay period
    @param payrollID The ID of the payroll
    */
    function getTotalShares(uint256 payrollID) public view returns (uint256) {
        return
            payrolls[payrollID].totalShares /
            payrolls[payrollID].paymentPeriods;
    }

    /** 
    @notice Returns the quantity of tokens paid to all recipients
    @param payrollID The ID of the payroll
    */
    function getTotalReleased(uint256 payrollID) public view returns (uint256) {
        return payrolls[payrollID].totalReleased;
    }

    /** 
    @notice Returns the number of recipients on the payroll
    @param payrollID The ID of the payroll
    */
    function getNumRecipients(uint256 payrollID)
        external
        view
        returns (uint256)
    {
        return payrolls[payrollID].recipients.length;
    }

    /** 
    @notice Returns the timestamp of the next payment
    @param payrollID The ID of the payroll
    */
    function getNextPayment(uint256 payrollID) public view returns (uint256) {
        Payroll storage payroll = payrolls[payrollID];
        if (payroll.lastPayment == 0) return 0;
        return payroll.lastPayment + payroll.timelock;
    }

    /** 
    @notice Returns the timestamp of the last payment
    @param payrollID The ID of the payroll
    */
    function getLastPayment(uint256 payrollID) public view returns (uint256) {
        return payrolls[payrollID].lastPayment;
    }

    /** 
    @notice Pulls the total quantity of tokens owed to all recipients for the pay period
     and pays each recipient their share
    @dev This contract must have approval to transfer the payment token from the msg.sender
    @param payrollID The ID of the payroll
    */
    function pullPayment(uint256 payrollID)
        external
        Pausable
        onlyManagers
        validPayroll(payrollID)
        returns (uint256)
    {
        require(
            block.timestamp >= getNextPayment(payrollID),
            "Payment was recently made"
        );

        Payroll storage payroll = payrolls[payrollID];

        require(payroll.totalShares > 0, "No Payees");

        uint256 totalPaid;

        for (uint256 i = 0; i < payroll.recipients.length; i++) {
            address recipient = payroll.recipients[i];
            uint256 recipientShares = payroll.shares[recipient];
            uint256 recipientOwed = recipientShares / payroll.paymentPeriods;

            payroll.paymentToken.safeTransferFrom(
                msg.sender,
                recipient,
                recipientOwed
            );
            payroll.released[recipient] += recipientOwed;

            totalPaid += recipientOwed;

            emit Payment(recipient, recipientOwed, payrollID);
        }
        payroll.totalReleased += totalPaid;
        payroll.lastPayment = block.timestamp;

        return totalPaid;
    }

    /** 
    @notice Pushes the total quantity of tokens required for the pay period and pays each recipient their share
    @dev ensure timelock is appropriately set to prevent overpayment
    @dev This contract must possess the required quantity of tokens to pay all recipients on the payroll
    @param payrollID The ID of the payroll
    */
    function pushPayment(uint256 payrollID)
        external
        Pausable
        validPayroll(payrollID)
        returns (uint256)
    {
        uint256 totalOwed = getTotalShares(payrollID);

        Payroll storage payroll = payrolls[payrollID];

        require(payroll.totalShares > 0, "No Payees");

        require(
            payroll.paymentToken.balanceOf(address(this)) >= totalOwed,
            "Insufficient balance for payment"
        );

        require(
            block.timestamp >= getNextPayment(payrollID),
            "Payment was recently made"
        );

        uint256 totalPaid;

        for (uint256 i = 0; i < payroll.recipients.length; i++) {
            address recipient = payroll.recipients[i];
            uint256 recipientShares = payroll.shares[recipient];
            uint256 recipientOwed = recipientShares / payroll.paymentPeriods;

            payroll.paymentToken.safeTransfer(recipient, recipientOwed);
            payroll.released[recipient] += recipientOwed;

            emit Payment(recipient, recipientOwed, payrollID);
        }
        payroll.totalReleased += totalPaid;

        payroll.lastPayment = block.timestamp;

        return totalPaid;
    }

    /** 
    @notice Withdraws tokens from this contract
    @param _token The token to remove (0 address if ETH)
    */
    function withdrawTokens(address _token) external onlyManagers {
        if (_token == address(0)) {
            (bool success, ) =
                msg.sender.call{ value: address(this).balance }("");
            require(success, "Error sending ETH");
        } else {
            IERC20 token = IERC20(_token);
            token.safeTransfer(msg.sender, token.balanceOf(address(this)));
        }
    }

    /** 
    @notice Updates the payroll's managers
    @param manager The address of the manager
    @param enabled Set false to revoke permission or true to grant permission
    */
    function updateManagers(address manager, bool enabled) external onlyOwner {
        managers[manager] = enabled;
    }

    /** 
    @notice Pause or unpause payments
    */
    function toggleContractActive() external onlyOwner {
        paused = !paused;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
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
        assembly {
            size := extcodesize(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

