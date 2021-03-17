/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract CosmoDistributor {
    using SafeMath for uint256;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;

    address private _owner;

    address public constant token = 0x27cd7375478F189bdcF55616b088BE03d9c4339c;
    uint256 public constant timeStart = 1615820400;  // 2021-03-15T15:00:00.000Z = 1615820400
    uint256 public constant timeEnd = 1647356400;    // 2022-03-15T15:00:00.000Z = 1647356400

    mapping(address => uint256) public vestedAmount;
    mapping(address => uint256) public totalDrawn;
    mapping(address => uint256) public lastDrawnAt;

    string public url = "https://CosmoFund.space/";

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ScheduleCreated(address indexed beneficiary);
    event DrawDown(address indexed beneficiary, uint256 indexed amount);

    constructor() public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
        setup();
    }

    function setup() internal {
        vestedAmount[0xB2F8234571eEF9B222DEca1307A03c6c2E376b73] = 1800000000e18;
        vestedAmount[0x3A7F0d57928d7dCE60E11470e528c47CF5084f33] = 18000000e18;
    }

    /**
    * @notice Create new vesting schedules in a batch
    * @notice A transfer is used to bring tokens into the VestingDepositAccount so pre-approval is required
    * @param beneficiaries array of beneficiaries of the vested tokens
    * @param amounts array of amount of tokens (in wei)
    * @dev array index of address should be the same as the array index of the amount
    */
    function createVestingSchedules(address[] calldata beneficiaries, uint256[] calldata amounts) external onlyOwner returns (bool) {
        require(beneficiaries.length > 0, "Empty Data");
        require(beneficiaries.length == amounts.length, "Array lengths do not match");
        for (uint256 i = 0; i < beneficiaries.length; i = i.add(1)) {
            address beneficiary = beneficiaries[i];
            uint256 amount = amounts[i];
            _createVestingSchedule(beneficiary, amount);
        }
        return true;
    }

    /**
    * @notice Create a new vesting schedule
    * @notice A transfer is used to bring tokens into the VestingDepositAccount so pre-approval is required
    * @param beneficiary beneficiary of the vested tokens
    * @param amount amount of tokens (in wei)
    */
    function createVestingSchedule(address beneficiary, uint256 amount) external onlyOwner returns (bool) {
        return _createVestingSchedule(beneficiary, amount);
    }

    /**
    * @notice Draws down any vested tokens due
    * @dev Must be called directly by the beneficiary assigned the tokens in the schedule
    */
    function drawDown() nonReentrant external returns (bool) {
        return _drawDown(_msgSender());
    }

    /**
    * @notice Vesting schedule and associated data for a beneficiary
    * @dev Must be called directly by the beneficiary assigned the tokens in the schedule
    * @return _amount
    * @return _totalDrawn
    * @return _lastDrawnAt
    * @return _remainingBalance
    */
    function vestingScheduleForBeneficiary(address beneficiary) external view
    returns (uint256 _amount, uint256 _totalDrawn, uint256 _lastDrawnAt, uint256 _remainingBalance) {
        return (
            vestedAmount[beneficiary],
            totalDrawn[beneficiary],
            lastDrawnAt[beneficiary],
            vestedAmount[beneficiary].sub(totalDrawn[beneficiary])
        );
    }

    /**
    * @notice Draw down amount currently available (based on the block timestamp)
    * @param beneficiary beneficiary of the vested tokens
    * @return amount tokens due from vesting schedule
    */
    function availableDrawDownAmount(address beneficiary) external view returns (uint256) {
        return _availableDrawDownAmount(beneficiary);
    }

    /**
    * @notice Balance remaining in vesting schedule
    * @param beneficiary beneficiary of the vested tokens
    * @return remainingBalance tokens still due (and currently locked) from vesting schedule
    */
    function remainingBalance(address beneficiary) external view returns (uint256) {
        return vestedAmount[beneficiary].sub(totalDrawn[beneficiary]);
    }

    function _createVestingSchedule(address beneficiary, uint256 amount) internal returns (bool) {
        require(beneficiary != address(0), "Beneficiary cannot be empty");
        require(amount > 0, "Amount cannot be empty");
        // Ensure one per address
        require(vestedAmount[beneficiary] == 0, "Schedule already in flight");
        vestedAmount[beneficiary] = amount;
        // Vest the tokens into the deposit account and delegate to the beneficiary
        require(IERC20(token).transferFrom(_msgSender(), address(this), amount), "Unable to escrow tokens");
        emit ScheduleCreated(beneficiary);
        return true;
    }

    function _drawDown(address beneficiary) internal returns (bool) {
        require(vestedAmount[beneficiary] > 0, "There is no schedule currently in flight");
        uint256 amount = _availableDrawDownAmount(beneficiary);
        require(amount > 0, "No allowance left to withdraw");
        // Update last drawn to now
        lastDrawnAt[beneficiary] = _getNow();
        // Increase total drawn amount
        totalDrawn[beneficiary] = totalDrawn[beneficiary].add(amount);
        // Safety measure - this should never trigger
        require(totalDrawn[beneficiary] <= vestedAmount[beneficiary], "Safety Mechanism - Drawn exceeded Amount Vested");
        // Issue tokens to beneficiary
        require(IERC20(token).transfer(beneficiary, amount), "Unable to transfer tokens");
        emit DrawDown(beneficiary, amount);
        return true;
    }

    function _availableDrawDownAmount(address beneficiary) internal view returns (uint256) {
        uint256 nowTime = _getNow();
        // Schedule complete
        if (nowTime > timeEnd) {
            return vestedAmount[beneficiary].sub(totalDrawn[beneficiary]);
        }
        // Schedule is active
        // Work out when the last invocation was
        uint256 timeLastDrawnOrStart = lastDrawnAt[beneficiary] == 0 ? timeStart : lastDrawnAt[beneficiary];
        // Find out how much time has past since last invocation
        uint256 timePassedSinceLastInvocation = nowTime.sub(timeLastDrawnOrStart);
        // Work out how many due tokens - time passed * rate per second
        uint256 drawDownRate = vestedAmount[beneficiary].mul(1e18).div(timeEnd.sub(timeStart));
        uint256 amount = timePassedSinceLastInvocation.mul(drawDownRate).div(1e18);
        return amount;
    }

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Caller is not the owner");
        _;
    }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}