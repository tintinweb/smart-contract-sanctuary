pragma solidity 0.4.25;

contract Ownable {

    address public owner;

    event NewOwner(address indexed old, address indexed current);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _new)
        public
        onlyOwner
    {
        require(_new != address(0));
        owner = _new;
        emit NewOwner(owner, _new);
    }
}

interface IERC20 {
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);
    
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract SafeMath {

    function safeMul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(
            c / a == b,
            "UINT256_OVERFLOW"
        );
        return c;
    }

    function safeDiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(
            b <= a,
            "UINT256_UNDERFLOW"
        );
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        require(
            c >= a,
            "UINT256_OVERFLOW"
        );
        return c;
    }

    function max64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

contract VestingWallet is Ownable, SafeMath {

    mapping(address => VestingSchedule) public schedules;        // vesting schedules for given addresses
    mapping(address => address) public addressChangeRequests;    // requested address changes

    IERC20 vestingToken;

    event VestingScheduleRegistered(
        address indexed registeredAddress,
        address depositor,
        uint startTimeInSec,
        uint cliffTimeInSec,
        uint endTimeInSec,
        uint totalAmount
    );

    event VestingScheduleConfirmed(
        address indexed registeredAddress,
        address depositor,
        uint startTimeInSec,
        uint cliffTimeInSec,
        uint endTimeInSec,
        uint totalAmount
    );

    event Withdrawal(
        address indexed registeredAddress,
        uint amountWithdrawn
    );

    event VestingEndedByOwner(
        address indexed registeredAddress,
        uint amountWithdrawn, uint amountRefunded
    );

    event AddressChangeRequested(
        address indexed oldRegisteredAddress,
        address indexed newRegisteredAddress
    );

    event AddressChangeConfirmed(
        address indexed oldRegisteredAddress,
        address indexed newRegisteredAddress
    );

    struct VestingSchedule {
        uint startTimeInSec;
        uint cliffTimeInSec;
        uint endTimeInSec;
        uint totalAmount;
        uint totalAmountWithdrawn;
        address depositor;
        bool isConfirmed;
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

    modifier vestingScheduleConfirmed(address target) {
        VestingSchedule storage vestingSchedule = schedules[target];
        require(vestingSchedule.isConfirmed);
        _;
    }

    modifier vestingScheduleNotConfirmed(address target) {
        VestingSchedule storage vestingSchedule = schedules[target];
        require(!vestingSchedule.isConfirmed);
        _;
    }

    modifier pendingAddressChangeRequest(address target) {
        require(addressChangeRequests[target] != address(0));
        _;
    }

    modifier pastCliffTime(address target) {
        VestingSchedule storage vestingSchedule = schedules[target];
        require(block.timestamp > vestingSchedule.cliffTimeInSec);
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
    constructor(address _vestingToken) public {
        vestingToken = IERC20(_vestingToken);
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
        vestingScheduleNotConfirmed(_addressToRegister)
        validVestingScheduleTimes(_startTimeInSec, _cliffTimeInSec, _endTimeInSec)
    {
        schedules[_addressToRegister] = VestingSchedule({
            startTimeInSec: _startTimeInSec,
            cliffTimeInSec: _cliffTimeInSec,
            endTimeInSec: _endTimeInSec,
            totalAmount: _totalAmount,
            totalAmountWithdrawn: 0,
            depositor: _depositor,
            isConfirmed: false
        });

        emit VestingScheduleRegistered(
            _addressToRegister,
            _depositor,
            _startTimeInSec,
            _cliffTimeInSec,
            _endTimeInSec,
            _totalAmount
        );
    }

    /// @dev Confirms a vesting schedule and deposits necessary tokens. Throws if deposit fails or schedules do not match.
    /// @param _startTimeInSec The time in seconds that vesting began.
    /// @param _cliffTimeInSec The time in seconds that tokens become withdrawable.
    /// @param _endTimeInSec The time in seconds that vesting ends.
    /// @param _totalAmount The total amount of tokens that the registered address can withdraw by the end of the vesting period.
    function confirmVestingSchedule(
        uint _startTimeInSec,
        uint _cliffTimeInSec,
        uint _endTimeInSec,
        uint _totalAmount
    )
        public
        addressRegistered(msg.sender)
        vestingScheduleNotConfirmed(msg.sender)
    {
        VestingSchedule storage vestingSchedule = schedules[msg.sender];

        require(vestingSchedule.startTimeInSec == _startTimeInSec);
        require(vestingSchedule.cliffTimeInSec == _cliffTimeInSec);
        require(vestingSchedule.endTimeInSec == _endTimeInSec);
        require(vestingSchedule.totalAmount == _totalAmount);

        vestingSchedule.isConfirmed = true;
        require(vestingToken.transferFrom(vestingSchedule.depositor, address(this), _totalAmount));

        emit VestingScheduleConfirmed(
            msg.sender,
            vestingSchedule.depositor,
            _startTimeInSec,
            _cliffTimeInSec,
            _endTimeInSec,
            _totalAmount
        );
    }

    /// @dev Allows a registered address to withdraw tokens that have already been vested.
    function withdraw()
        public
        vestingScheduleConfirmed(msg.sender)
        pastCliffTime(msg.sender)
    {
        VestingSchedule storage vestingSchedule = schedules[msg.sender];

        uint totalAmountVested = getTotalAmountVested(vestingSchedule);
        uint amountWithdrawable = safeSub(totalAmountVested, vestingSchedule.totalAmountWithdrawn);
        vestingSchedule.totalAmountWithdrawn = totalAmountVested;

        if (amountWithdrawable > 0) {
            require(vestingToken.transfer(msg.sender, amountWithdrawable));
            emit Withdrawal(msg.sender, amountWithdrawable);
        }
    }

    /// @dev Allows contract owner to terminate a vesting schedule, transfering remaining vested tokens to the registered address and refunding owner with remaining tokens.
    /// @param _addressToEnd Address that is currently registered to the vesting schedule that will be closed.
    /// @param _addressToRefund Address that will receive unvested tokens.
    function endVesting(address _addressToEnd, address _addressToRefund)
        public
        onlyOwner
        vestingScheduleConfirmed(_addressToEnd)
        addressNotNull(_addressToRefund)
    {
        VestingSchedule storage vestingSchedule = schedules[_addressToEnd];

        uint amountWithdrawable = 0;
        uint amountRefundable = 0;

        if (block.timestamp < vestingSchedule.cliffTimeInSec) {
            amountRefundable = vestingSchedule.totalAmount;
        } else {
            uint totalAmountVested = getTotalAmountVested(vestingSchedule);
            amountWithdrawable = safeSub(totalAmountVested, vestingSchedule.totalAmountWithdrawn);
            amountRefundable = safeSub(vestingSchedule.totalAmount, totalAmountVested);
        }

        delete schedules[_addressToEnd];
        require(amountWithdrawable == 0 || vestingToken.transfer(_addressToEnd, amountWithdrawable));
        require(amountRefundable == 0 || vestingToken.transfer(_addressToRefund, amountRefundable));

        emit VestingEndedByOwner(_addressToEnd, amountWithdrawable, amountRefundable);
    }

    /// @dev Allows a registered address to request an address change.
    /// @param _newRegisteredAddress Desired address to update to.
    function requestAddressChange(address _newRegisteredAddress)
        public
        vestingScheduleConfirmed(msg.sender)
        addressNotRegistered(_newRegisteredAddress)
        addressNotNull(_newRegisteredAddress)
    {
        addressChangeRequests[msg.sender] = _newRegisteredAddress;
        emit AddressChangeRequested(msg.sender, _newRegisteredAddress);
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
        require(newRegisteredAddress == _newRegisteredAddress);    // prevents race condition

        VestingSchedule memory vestingSchedule = schedules[_oldRegisteredAddress];
        schedules[newRegisteredAddress] = vestingSchedule;

        delete schedules[_oldRegisteredAddress];
        delete addressChangeRequests[_oldRegisteredAddress];

        emit AddressChangeConfirmed(_oldRegisteredAddress, _newRegisteredAddress);
    }

    /// @dev Calculates the total tokens that have been vested for a vesting schedule, assuming the schedule is past the cliff.
    /// @param vestingSchedule Vesting schedule used to calculate vested tokens.
    /// @return Total tokens vested for a vesting schedule.
    function getTotalAmountVested(VestingSchedule vestingSchedule)
        internal
        view
        returns (uint)
    {
        if (block.timestamp >= vestingSchedule.endTimeInSec) return vestingSchedule.totalAmount;

        uint timeSinceStartInSec = safeSub(block.timestamp, vestingSchedule.startTimeInSec);
        uint totalVestingTimeInSec = safeSub(vestingSchedule.endTimeInSec, vestingSchedule.startTimeInSec);
        uint totalAmountVested = safeDiv(
            safeMul(timeSinceStartInSec, vestingSchedule.totalAmount),
            totalVestingTimeInSec
        );

        return totalAmountVested;
    }
}