// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IVesting.sol";
import "./ISheeshaStaking.sol";

/**
 * @title Sheesha vesting contract
 * @author Sheesha Finance
 */
contract Vesting is IVesting, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum VestingType {
        SEED,
        PRIVATE,
        STRATEGIC,
        PUBLIC,
        TEAM_ADVISORS,
        RESERVES
    }

    struct RecipientInfo {
        uint256 amount;
        VestingType vestingType;
        uint256 paidAmount;
    }

    struct VestingSchedule {
        uint256 durationInPeriods;
        uint256 cliffInPeriods;
        uint256 tokensAllocation;
        uint256 tokensInVestings;
    }

    uint256 private constant PERIOD = 30 days;
    uint256 private constant DECIMALS_MUL = 10**18;
    uint256 private constant SEED = 150_000_000 * DECIMALS_MUL;
    uint256 private constant PRIVATE = 80_000_000 * DECIMALS_MUL;
    uint256 private constant STRATEGIC = 40_000_000 * DECIMALS_MUL;
    uint256 private constant PUBLIC = 5_000_000 * DECIMALS_MUL;
    uint256 private constant TEAM_ADVISORS = 100_000_000 * DECIMALS_MUL;
    uint256 private constant RESERVES = 100_000_000 * DECIMALS_MUL;

    IERC20 public immutable mSheesha;
    ISheeshaStaking public immutable sheeshaStaking;
    uint256 public immutable tgeTimestamp;

    mapping(address => RecipientInfo[]) public vestings;
    mapping(VestingType => VestingSchedule) public vestingSchedules;

    /**
     * @dev Emitted when a new recipient added to vesting
     * @param recipient Address of recipient.
     * @param amount The amount of tokens to be vested.
     */
    event RecipientAdded(address indexed recipient, uint256 amount);

    /**
     * @dev Emitted when a staked to staking contract
     * @param recipient Address of user for which deposit was made.
     * @param pool Pool's unique ID.
     * @param amount The amount of deposited tokens.
     */
    event DepositedToStaking(
        address indexed recipient,
        uint256 pool,
        uint256 amount
    );

    /**
     * @dev Emitted when withdraw of tokens was made on vesting contract.
     * @param recipient Address of user for which withdraw tokens.
     * @param amount The amount of tokens which was withdrawn.
     */
    event WithdrawFromVesting(address indexed recipient, uint256 amount);

    /**
     * @dev Emitted when withdraw of tokens was made on staking contract.
     * @param _recipient Address of user for which withdraw from staking.
     * @param _amount The amount of tokens which was withdrawn.
     */
    event WithdrawFromStaking(address indexed _recipient, uint256 _amount);

    modifier onlyStaking() {
        require(
            address(sheeshaStaking) == _msgSender(),
            "Only Staking allowed"
        );
        _;
    }

    /**
     * @dev Constructor of the contract.
     * @notice Initialize all vesting schedules.
     * @param _tgeTimestamp Token generetaion event unix timestamp.
     * @param _mSheesha Address of mSheesha token.
     * @param _sheeshaStaking Address of staking contract.
     */
    constructor(
        uint256 _tgeTimestamp,
        IERC20 _mSheesha,
        address _sheeshaStaking
    ) {
        require(address(_mSheesha) != address(0), "Wrong Sheesha token address");
        require(_sheeshaStaking != address(0), "Wrong Sheesha staking address");
        tgeTimestamp = _tgeTimestamp;
        mSheesha = _mSheesha;
        sheeshaStaking = ISheeshaStaking(_sheeshaStaking);
        _mSheesha.safeApprove(_sheeshaStaking, type(uint256).max);
        _initializeVestingSchedules();
    }

    /**
     * @dev Adds recipients for vesting.
     * @param _recipients Addresses of recipients.
     * @param _amount The amounts of tokens to be vested.
     * @param _vestingType Type of vesting.
     */
    function addRecipients(
        address[] calldata _recipients,
        uint256[] calldata _amount,
        VestingType _vestingType
    ) external onlyOwner {
        require(
            _recipients.length == _amount.length,
            "Parameters length mismatch"
        );

        for (uint256 i = 0; i < _recipients.length; i++) {
            _addRecipient(_recipients[i], _amount[i], _vestingType);
        }
    }

    /**
     * @dev Withdraws tokens from vesting.
     * @notice Check function caller for available withdrawable amount and
     * transfer tokens to his wallet
     */
    function withdrawFromVesting() external {
        require(block.timestamp >= tgeTimestamp, "TGE didn't start yet");
        RecipientInfo[] storage vesting = vestings[msg.sender];
        uint256 totalToPay;
        for (uint256 i = 0; i < vesting.length; i++) {
            if (!_isForStaking(vesting[i].vestingType)) {
                (, uint256 amountToPay) = _recipientAvailableAmount(
                    msg.sender,
                    i
                );
                totalToPay = totalToPay.add(amountToPay);
                vesting[i].paidAmount = vesting[i].paidAmount.add(amountToPay);
            }
        }
        require(totalToPay > 0, "Nothing to withdraw");
        mSheesha.safeTransfer(msg.sender, totalToPay);
        emit WithdrawFromVesting(msg.sender, totalToPay);
    }

    /**
     * @dev Updates user paid amount when withdraw was called on staking contract.
     * @notice Can be called only by staking contract
     */
    function withdrawFromStaking(address recipient, uint256 amount)
        external
        override
        onlyStaking
    {
        RecipientInfo[] storage vesting = vestings[recipient];
        uint256 amountLeft = amount;
        for (uint256 i = 0; i < vesting.length; i++) {
            if (!_isForStaking(vesting[i].vestingType)) continue;
            (, uint256 amountAvailable) = _recipientAvailableAmount(
                recipient,
                i
            );
            if (amountAvailable >= amountLeft) {
                vesting[i].paidAmount = vesting[i].paidAmount.add(amountLeft);
                amountLeft = 0;
                break;
            } else {
                vesting[i].paidAmount = vesting[i].paidAmount.add(
                    amountAvailable
                );
                amountLeft = amountLeft.sub(amountAvailable);
            }
        }
        require(amountLeft == 0, "Something went wrong");
        emit WithdrawFromStaking(recipient, amount);
    }

    /**
     * @dev Withdraw tokens that wasn't added to vesting.
     * @param _type Vesting type to withdraw from
     * @param recipient Address where tokens needed to be send
     */
    function withdrawLeftovers(VestingType _type, address recipient) external onlyOwner {
        require(recipient != address(0), "Wrong recipient address");
        VestingSchedule storage vestingSchedule = vestingSchedules[_type];
        uint256 availableToWithdraw = vestingSchedule.tokensAllocation.sub(vestingSchedule.tokensInVestings);
        vestingSchedule.tokensInVestings = vestingSchedule.tokensAllocation;
        mSheesha.safeTransfer(recipient, availableToWithdraw);
    }

    /**
     * @dev Calculates available amount of tokens to withdraw for vesting types
     * which not participate in staking for FE.
     * @return _totalAmount  Recipient total amount in vesting.
     * @return _totalAmountAvailable Recipient available amount to withdraw.
     */
    function calculateAvailableAmount(address _recipient)
        external
        view
        returns (uint256 _totalAmount, uint256 _totalAmountAvailable)
    {
        RecipientInfo[] memory vesting = vestings[_recipient];
        uint256 totalAmount;
        uint256 totalAmountAvailable;
        for (uint256 i = 0; i < vesting.length; i++) {
            if (_isForStaking(vesting[i].vestingType)) continue;
            (
                uint256 _amount,
                uint256 _amountAvailable
            ) = _recipientAvailableAmount(_recipient, i);
            totalAmount = totalAmount.add(_amount);
            totalAmountAvailable = totalAmountAvailable.add(_amountAvailable);
        }
        return (totalAmount, totalAmountAvailable);
    }

    /**
     * @dev Calculates available amount of tokens to withdraw for vesting types
     * which participate in staking for FE.
     * @return _leftover Recipient amount which wasn't withdrawn.
     * @return _amountAvailable Recipient available amount to withdraw.
     */
    function calculateAvailableAmountForStaking(address _recipient)
        external
        view
        override
        returns (uint256 _leftover, uint256 _amountAvailable)
    {
        RecipientInfo[] memory vesting = vestings[_recipient];
        uint256 leftover;
        uint256 amountAvailable;
        for (uint256 i = 0; i < vesting.length; i++) {
            if (!_isForStaking(vesting[i].vestingType)) continue;
            (uint256 amount, uint256 available) = _recipientAvailableAmount(
                _recipient,
                i
            );
            uint256 notPaid = amount.sub(vesting[i].paidAmount);
            leftover = leftover.add(notPaid);
            amountAvailable = amountAvailable.add(available);
        }
        return (leftover, amountAvailable);
    }

    /**
     * @dev Internal function initialize all vesting types with their schedule
     */
    function _initializeVestingSchedules() internal {
        _addVestingSchedule(
            VestingType.SEED,
            VestingSchedule({
                durationInPeriods: 24,
                cliffInPeriods: 2,
                tokensAllocation: SEED,
                tokensInVestings: 0
            })
        );
        _addVestingSchedule(
            VestingType.PRIVATE,
            VestingSchedule({
                durationInPeriods: 12,
                cliffInPeriods: 1,
                tokensAllocation: PRIVATE,
                tokensInVestings: 0
            })
        );
        _addVestingSchedule(
            VestingType.STRATEGIC,
            VestingSchedule({
                durationInPeriods: 6,
                cliffInPeriods: 1,
                tokensAllocation: STRATEGIC,
                tokensInVestings: 0
            })
        );
        _addVestingSchedule(
            VestingType.PUBLIC,
            VestingSchedule({
                durationInPeriods: 0,
                cliffInPeriods: 0,
                tokensAllocation: PUBLIC,
                tokensInVestings: 0
            })
        );
        _addVestingSchedule(
            VestingType.TEAM_ADVISORS,
            VestingSchedule({
                durationInPeriods: 24,
                cliffInPeriods: 3,
                tokensAllocation: TEAM_ADVISORS,
                tokensInVestings: 0
            })
        );
        _addVestingSchedule(
            VestingType.RESERVES,
            VestingSchedule({
                durationInPeriods: 24,
                cliffInPeriods: 24,
                tokensAllocation: RESERVES,
                tokensInVestings: 0
            })
        );
    }

    /**
     * @dev Internal function adds vesting schedules for vesting type
     */
    function _addVestingSchedule(
        VestingType _type,
        VestingSchedule memory _schedule
    ) internal {
        vestingSchedules[_type] = _schedule;
    }

    /**
     * @dev Internal function used to add recipient for vesting.
     * @param _recipient Address of recipient.
     * @param _amount The amount of tokens to be vested.
     * @param _vestingType Type of vesting.
     */
    function _addRecipient(
        address _recipient,
        uint256 _amount,
        VestingType _vestingType
    ) internal {
        require(_recipient != address(0), "Wrong recipient address");
        require(_amount > 0, "Amount should not be equal to zero");
        require(
            vestingSchedules[_vestingType].tokensInVestings.add(_amount) <=
            vestingSchedules[_vestingType].tokensAllocation,
            "Amount exeeds vesting schedule allocation"
        );
        RecipientInfo[] storage vesting = vestings[_recipient];
        for (uint256 i = 0; i < vesting.length; i++) {
            require(
                vesting[i].vestingType != _vestingType,
                "Recipient with this vesting schedule already exists"
            );
        }
        vestings[_recipient].push(
            RecipientInfo({
                amount: _amount,
                vestingType: _vestingType,
                paidAmount: 0
            })
        );
        vestingSchedules[_vestingType].tokensInVestings = vestingSchedules[
            _vestingType
        ].tokensInVestings.add(_amount);
        if (_isForStaking(_vestingType)) {
            _depositForRecipientInStaking(_recipient, _amount);
        }
        emit RecipientAdded(_recipient, _amount);
    }

    /**
     * @dev Internal function used to stake for recipient in staking contract.
     * @param _recipient Address of recipient.
     * @param _amount The amount of tokens to be staked.
     */
    function _depositForRecipientInStaking(address _recipient, uint256 _amount)
        internal
    {
        sheeshaStaking.depositFor(_recipient, 0, _amount);
        emit DepositedToStaking(_recipient, 0, _amount);
    }

    function _isForStaking(VestingType _type) internal pure returns (bool) {
        bool result = (_type != VestingType.TEAM_ADVISORS && _type != VestingType.RESERVES)
            ? true
            : false;
        return result;
    }

    /**
     * @dev Internal function used to calculate available tokens for specific recipient.
     * @param _recipient Address of recipient.
     * @return _amount  Recipient total amount in vesting.
     * @return _amountAvailable Recipient available amount to withdraw.
     */
    function _recipientAvailableAmount(address _recipient, uint256 index)
        internal
        view
        returns (uint256 _amount, uint256 _amountAvailable)
    {
        RecipientInfo[] memory recipient = vestings[_recipient];
        uint256 amount = recipient[index].amount;
        if (block.timestamp <= tgeTimestamp) return (amount, 0);
        uint256 unlockedAmount;
        VestingSchedule memory vestingSchedule = vestingSchedules[
            recipient[index].vestingType
        ];
        unlockedAmount = _getVestingTypeAvailableAmount(
            vestingSchedule,
            recipient[index].amount
        );
        uint256 amountAvailable = unlockedAmount.sub(
            recipient[index].paidAmount
        );
        return (amount, amountAvailable);
    }

    /**
     * @dev Internal function used to calculate available tokens for specific vesting schedule.
     * @param _vestingSchedule vesting schedule.
     * @param _vestingSchedule amount for which calculation should be made
     * @return Available amount for specific schedule.
     */
    function _getVestingTypeAvailableAmount(
        VestingSchedule memory _vestingSchedule,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 elapsedPeriods = _calculateElapsedPeriods();
        if (elapsedPeriods < _vestingSchedule.cliffInPeriods) {
            return 0;
        } else if (
            elapsedPeriods >=
            (_vestingSchedule.cliffInPeriods).add(
                _vestingSchedule.durationInPeriods
            )
        ) {
            return _amount;
        } else {
            uint256 periodsWithoutCliff = elapsedPeriods.sub(
                _vestingSchedule.cliffInPeriods
            );
            uint256 availableAmount = _amount.mul(periodsWithoutCliff).div(
                _vestingSchedule.durationInPeriods
            );
            return availableAmount;
        }
    }

    /**
     * @dev Internal function used to calculate elapsed periods from tge timestamp.
     * @return Number of periods from tge timestamp.
     */
    function _calculateElapsedPeriods() internal view returns (uint256) {
        return block.timestamp.sub(tgeTimestamp).div(PERIOD);
    }
}