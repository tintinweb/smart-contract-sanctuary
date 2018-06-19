pragma solidity ^0.4.19;

// File: contracts/erc20/Token.sol

contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// File: contracts/math/SafeMath.sol

contract SafeMath {
    function safeMul(uint a, uint b) internal constant returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal constant returns (uint) {
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b) internal constant returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal constant returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}

// File: contracts/ownership/Ownable.sol

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */

contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

// File: contracts/vesting/VestingWallet.sol

contract VestingWallet is Ownable, SafeMath {

    mapping(address => VestingSchedule) public schedules;        // vesting schedules for given addresses
    mapping(address => address) public addressChangeRequests;    // requested address changes

    Token public vestingToken;

    address public approvedWallet;

    event VestingScheduleRegistered(
        address indexed registeredAddress,
        address depositor,
        uint startTimeInSec,
        uint cliffTimeInSec,
        uint endTimeInSec,
        uint totalAmount
    );


    event Withdrawal(address indexed registeredAddress, uint amountWithdrawn);

    event VestingEndedByOwner(address indexed registeredAddress, uint amountWithdrawn, uint amountRefunded);

    event AddressChangeRequested(address indexed oldRegisteredAddress, address indexed newRegisteredAddress);

    event AddressChangeConfirmed(address indexed oldRegisteredAddress, address indexed newRegisteredAddress);

    struct VestingSchedule {
        uint startTimeInSec;
        uint cliffTimeInSec;
        uint endTimeInSec;
        uint totalAmount;
        uint totalAmountWithdrawn;
        address depositor;
    }

    modifier addressRegistered(address target) {
        VestingSchedule storage vestingSchedule = schedules[target];
        require(vestingSchedule.depositor != address(0));
        _;
    }

    modifier addressNotRegistered(address target) {
        VestingSchedule storage vestingSchedule = schedules[target];
        require(vestingSchedule.depositor == address(0));
        _;
    }

    modifier pendingAddressChangeRequest(address target) {
        require(addressChangeRequests[target] != address(0));
        _;
    }

    modifier pastCliffTime(address target) {
        VestingSchedule storage vestingSchedule = schedules[target];
        require(getTime() > vestingSchedule.cliffTimeInSec);
        _;
    }

    modifier validVestingScheduleTimes(uint startTimeInSec, uint cliffTimeInSec, uint endTimeInSec) {
        require(cliffTimeInSec >= startTimeInSec);
        require(endTimeInSec >= cliffTimeInSec);
        _;
    }

    modifier addressNotNull(address target) {
        require(target != address(0));
        _;
    }

    /// @dev Assigns a vesting token to the wallet.
    /// @param _vestingToken Token that will be vested.
    function VestingWallet(address _vestingToken) {
        vestingToken = Token(_vestingToken);
        approvedWallet = msg.sender;
    }

    function registerVestingScheduleWithPercentage(
        address _addressToRegister,
        address _depositor,
        uint _startTimeInSec,
        uint _cliffTimeInSec,
        uint _endTimeInSec,
        uint _totalAmount,
        uint _percentage
    )
    public
    onlyOwner
    addressNotNull(_depositor)
    validVestingScheduleTimes(_startTimeInSec, _cliffTimeInSec, _endTimeInSec)
    {
        require(_percentage <= 100);
        uint vestedAmount = safeDiv(safeMul(
                _totalAmount, _percentage
            ), 100);
        registerVestingSchedule(_addressToRegister, _depositor, _startTimeInSec, _cliffTimeInSec, _endTimeInSec, vestedAmount);
    }

    /// @dev Registers a vesting schedule to an address.
    /// @param _addressToRegister The address that is allowed to withdraw vested tokens for this schedule.
    /// @param _depositor Address that will be depositing vesting token.
    /// @param _startTimeInSec The time in seconds that vesting began.
    /// @param _cliffTimeInSec The time in seconds that tokens become withdrawable.
    /// @param _endTimeInSec The time in seconds that vesting ends.
    /// @param _totalAmount The total amount of tokens that the registered address can withdraw by the end of the vesting period.
    function registerVestingSchedule(
        address _addressToRegister,
        address _depositor,
        uint _startTimeInSec,
        uint _cliffTimeInSec,
        uint _endTimeInSec,
        uint _totalAmount
    )
    public
    onlyOwner
    addressNotNull(_depositor)
    validVestingScheduleTimes(_startTimeInSec, _cliffTimeInSec, _endTimeInSec)
    {

        require(vestingToken.transferFrom(approvedWallet, address(this), _totalAmount));
        require(vestingToken.balanceOf(address(this)) >= _totalAmount);

        schedules[_addressToRegister] = VestingSchedule({
            startTimeInSec : _startTimeInSec,
            cliffTimeInSec : _cliffTimeInSec,
            endTimeInSec : _endTimeInSec,
            totalAmount : _totalAmount,
            totalAmountWithdrawn : 0,
            depositor : _depositor
            });

        VestingScheduleRegistered(
            _addressToRegister,
            _depositor,
            _startTimeInSec,
            _cliffTimeInSec,
            _endTimeInSec,
            _totalAmount
        );
    }

    /// @dev Allows a registered address to withdraw tokens that have already been vested.
    function withdraw()
    public
    pastCliffTime(msg.sender)
    {
        VestingSchedule storage vestingSchedule = schedules[msg.sender];
        uint totalAmountVested = getTotalAmountVested(vestingSchedule);
        uint amountWithdrawable = safeSub(totalAmountVested, vestingSchedule.totalAmountWithdrawn);
        vestingSchedule.totalAmountWithdrawn = totalAmountVested;

        if (amountWithdrawable > 0) {
            require(vestingToken.transfer(msg.sender, amountWithdrawable));
            Withdrawal(msg.sender, amountWithdrawable);
        }
    }

    /// @dev Allows contract owner to terminate a vesting schedule, transfering remaining vested tokens to the registered address and refunding owner with remaining tokens.
    /// @param _addressToEnd Address that is currently registered to the vesting schedule that will be closed.
    /// @param _addressToRefund Address that will receive unvested tokens.
    function endVesting(address _addressToEnd, address _addressToRefund)
    public
    onlyOwner
    addressNotNull(_addressToRefund)
    {
        VestingSchedule storage vestingSchedule = schedules[_addressToEnd];

        uint amountWithdrawable = 0;
        uint amountRefundable = 0;

        if (getTime() < vestingSchedule.cliffTimeInSec) {
            amountRefundable = vestingSchedule.totalAmount;
        }
        else {
            uint totalAmountVested = getTotalAmountVested(vestingSchedule);
            amountWithdrawable = safeSub(totalAmountVested, vestingSchedule.totalAmountWithdrawn);
            amountRefundable = safeSub(vestingSchedule.totalAmount, totalAmountVested);
        }

        delete schedules[_addressToEnd];
        require(amountWithdrawable == 0 || vestingToken.transfer(_addressToEnd, amountWithdrawable));
        require(amountRefundable == 0 || vestingToken.transfer(_addressToRefund, amountRefundable));

        VestingEndedByOwner(_addressToEnd, amountWithdrawable, amountRefundable);
    }

    /// @dev Allows a registered address to request an address change.
    /// @param _newRegisteredAddress Desired address to update to.
    function requestAddressChange(address _newRegisteredAddress)
    public
    addressNotRegistered(_newRegisteredAddress)
    addressNotNull(_newRegisteredAddress)
    {
        addressChangeRequests[msg.sender] = _newRegisteredAddress;
        AddressChangeRequested(msg.sender, _newRegisteredAddress);
    }

    /// @dev Confirm an address change and migrate vesting schedule to new address.
    /// @param _oldRegisteredAddress Current registered address.
    /// @param _newRegisteredAddress Address to migrate vesting schedule to.
    function confirmAddressChange(address _oldRegisteredAddress, address _newRegisteredAddress)
    public
    onlyOwner
    pendingAddressChangeRequest(_oldRegisteredAddress)
    addressNotRegistered(_newRegisteredAddress)
    {
        address newRegisteredAddress = addressChangeRequests[_oldRegisteredAddress];
        require(newRegisteredAddress == _newRegisteredAddress);
        // prevents race condition

        VestingSchedule memory vestingSchedule = schedules[_oldRegisteredAddress];
        schedules[newRegisteredAddress] = vestingSchedule;

        delete schedules[_oldRegisteredAddress];
        delete addressChangeRequests[_oldRegisteredAddress];

        AddressChangeConfirmed(_oldRegisteredAddress, _newRegisteredAddress);
    }

    function setApprovedWallet(address _approvedWallet)
    public
    addressNotNull(_approvedWallet)
    onlyOwner {
        approvedWallet = _approvedWallet;
    }

    function getTime() internal view returns (uint) {
        return now;
    }

    function allowance(address _target) public view returns (uint) {
        VestingSchedule storage vestingSchedule = schedules[_target];
        uint totalAmountVested = getTotalAmountVested(vestingSchedule);
        uint amountWithdrawable = safeSub(totalAmountVested, vestingSchedule.totalAmountWithdrawn);
        return amountWithdrawable;
    }

    /// @dev Calculates the total tokens that have been vested for a vesting schedule, assuming the schedule is past the cliff.
    /// @param vestingSchedule Vesting schedule used to calculate vested tokens.
    /// @return Total tokens vested for a vesting schedule.
    function getTotalAmountVested(VestingSchedule vestingSchedule)
    internal
    view
    returns (uint)
    {
        if (getTime() >= vestingSchedule.endTimeInSec) {
            return vestingSchedule.totalAmount;
        }

        uint timeSinceStartInSec = safeSub(getTime(), vestingSchedule.startTimeInSec);
        uint totalVestingTimeInSec = safeSub(vestingSchedule.endTimeInSec, vestingSchedule.startTimeInSec);
        uint totalAmountVested = safeDiv(
            safeMul(timeSinceStartInSec, vestingSchedule.totalAmount), totalVestingTimeInSec
        );

        return totalAmountVested;
    }
}