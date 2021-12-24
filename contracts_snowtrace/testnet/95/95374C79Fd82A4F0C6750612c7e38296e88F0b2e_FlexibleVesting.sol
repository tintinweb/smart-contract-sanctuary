/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-24
*/

pragma solidity 0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }


    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a & b) + (a ^ b) / 2;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b + (a % b == 0 ? 0 : 1);
    }

    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            return uint256(n >= 0 ? n : -n);
        }
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract FlexibleVesting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // address of the ERC20 token
    IERC20 immutable private _token;

    constructor(address token_) {
        require(token_ != address(0x0));
        _token = IERC20(token_);
    }

    struct VestingSchedule {
        bool initialized; // if vesting is already scheduled per address
        uint256 start; // start date (unix timestamp)
        address beneficiary; // address of wallet for vesting schedule
        uint256 amount; // amount to be vested
        uint256 releasedAmount; // amount claimed/released
        VestingSchedulePeriod[] periods; // set of periods
        uint currentPeriodIndex; // current period index
    }


    struct VestingSchedulePeriod {
        uint256 periodDays; // days for each period FROM START date like interval(!)
        uint256 percentagesPerPeriod; // percentage per period 
    }


    mapping(address => VestingSchedule) private vestingSchedules;

    event Claimed(address claimAddress, uint256 amount);

// checks if vesting schedule does not exists for specified address
    modifier onlyIfVestingScheduleExists(address vestingAddress) {
        require(vestingSchedules[vestingAddress].initialized, "Vesting configuration for such address does not exists");
        _;
    }

    // checks if vesting schedule does already exists for specified address
    modifier onlyIfVestingScheduleDoesNotExists(address vestingAddress) {
        require(!vestingSchedules[vestingAddress].initialized, "Vesting configuration for such address already exists");
        _;
    }

    // Check if specifier perios configuration is correct by validating sequence of period days and amount of percentages
    modifier periodsAreCorrect(VestingSchedulePeriod[] memory periods) {
        uint256 previousPeriodDay = 0; 
        uint256 totalPeriodsPercentages = 0;
        for(uint256 i = 0; i < periods.length; i++) {
            require(periods[i].periodDays > previousPeriodDay, "Each period days should be greater than previous");
            previousPeriodDay = periods[i].periodDays;
            totalPeriodsPercentages += periods[i].percentagesPerPeriod;
        }

        require(totalPeriodsPercentages == 100, "Total percentages amount for periods should be 100");
        _;
    }

    // create allocation schedule for specific address by periods
    function createScheduleForAddress(address vestingAddress, uint256 amount, uint256 start, VestingSchedulePeriod[] memory periods) 
        public
        onlyOwner
        onlyIfVestingScheduleDoesNotExists(vestingAddress)
        periodsAreCorrect(periods) {
        require(amount > 0, "Vesting amount must be greater than 0");
        require(start > 0, "Vesting start shoulde be positive value");

        vestingSchedules[vestingAddress].initialized = true;
        vestingSchedules[vestingAddress].start = start;
        vestingSchedules[vestingAddress].beneficiary = vestingAddress;
        vestingSchedules[vestingAddress].amount = amount;
        vestingSchedules[vestingAddress].releasedAmount = 0;
        vestingSchedules[vestingAddress].currentPeriodIndex = 0;

        uint256 length = periods.length;
        for (uint256 i = 0; i < length; i += 1) {
            vestingSchedules[vestingAddress].periods.push(
                VestingSchedulePeriod(
                    periods[i].periodDays,
                    periods[i].percentagesPerPeriod
                )
            );
        }
    }

    function changeAllocation(address vestingAddress, uint256 allocatedAmount)
    public
    onlyOwner
    onlyIfVestingScheduleExists(vestingAddress) {
        vestingSchedules[vestingAddress].amount = allocatedAmount;
    }

    function claimTokensForAddress(address vestingAddress, uint256 amount) 
        public
        nonReentrant
        onlyIfVestingScheduleExists(vestingAddress) {   
        bool isBeneficiary = msg.sender == vestingAddress;
        bool isOwner = msg.sender == owner();
        require(isBeneficiary || isOwner, "Only beneficiary and owner can claim vested tokens");
        
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingAddress];
        
        uint256 currentPeriodIndex = vestingSchedule.currentPeriodIndex;
        VestingSchedulePeriod storage currentPeriod = vestingSchedule.periods[currentPeriodIndex];
       
        uint256 currentTime = getCurrentTime();
        uint256 start = vestingSchedule.start;
        uint256 periodDuration = currentPeriod.periodDays * 86400; //seconds in a day
        uint256 timeFromStart = start.add(periodDuration);
        require(currentTime >= timeFromStart, "Too early to claim tokens");

        uint256 amountCanBeClaimed = (vestingSchedule.amount * currentPeriod.percentagesPerPeriod) / 100;
        require(amountCanBeClaimed >= amount, "Can't claim tokens, not enough vested tokens");

        vestingSchedule.currentPeriodIndex = vestingSchedule.currentPeriodIndex + 1;
        vestingSchedule.releasedAmount = vestingSchedule.releasedAmount.add(amountCanBeClaimed);
        address payable beneficiaryPayable = payable(vestingSchedule.beneficiary);

        uint256 claimAmount = amount * 10 ** 2;
        _token.transfer(beneficiaryPayable, claimAmount);
        emit Claimed(beneficiaryPayable, amount);
    }

    function getAmountToBeClaimed(address vestingAddress)
        external
        view
        onlyIfVestingScheduleExists(vestingAddress) 
        returns(uint256) {

        VestingSchedule storage vestingSchedule = vestingSchedules[vestingAddress];
        uint256 currentPeriodIndex = vestingSchedule.currentPeriodIndex;
        VestingSchedulePeriod storage currentPeriod = vestingSchedule.periods[currentPeriodIndex];
       
        uint256 currentTime = getCurrentTime();
        uint256 start = vestingSchedule.start;
        uint256 periodDuration = currentPeriod.periodDays * 86400; //seconds in a day
        uint256 timeFromStart = start.add(periodDuration);

        if(currentTime < timeFromStart) {
             return uint256(0);
        }

        uint256 amountCanBeClaimed = (vestingSchedule.amount * currentPeriod.percentagesPerPeriod) / 100;
        return uint256(amountCanBeClaimed);
    }

    function getAddressVestingSchedule(address vestingAddress) 
    public 
    view  
    onlyIfVestingScheduleExists(vestingAddress)  
    returns (VestingSchedule memory) {
        VestingSchedule memory schedule = vestingSchedules[vestingAddress];
        return schedule;
    }

     function getCurrentTime()
        internal
        virtual
        view
        returns(uint256){
        return block.timestamp;
    }
}