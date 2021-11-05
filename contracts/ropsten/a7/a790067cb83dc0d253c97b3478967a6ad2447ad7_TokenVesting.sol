// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

// TODO: There is an issue where the sum of all vestingSchedule totalTokens is less than totalVestingsTokens.
// NOTE: Excess of totalVestingsTokens, after paying out all totalTokens, requires awkward immediate vesting schedule to withdraw.

import { IERC20Like } from "./Interfaces.sol";
import { ITokenVesting } from "./ITokenVesting.sol";

contract TokenVesting is ITokenVesting {

    address public override owner;
    address public override pendingOwner;

    address public override token;
    uint256 public override totalVestingsTokens;

    mapping(address => VestingSchedule) public override vestingScheduleOf;

    /**
     * @dev   Constructor.
     * @param token_ The address of an erc20 token.
     */
    constructor(address token_) {
        owner = msg.sender;
        token = token_;
    }

    /**************************/
    /*** Contract Ownership ***/
    /**************************/

    modifier onlyOwner() {
        require(owner == msg.sender, "TV:NOT_OWNER");
        _;
    }

    function renounceOwnership() external override onlyOwner {
        pendingOwner = owner = address(0);

        emit OwnershipTransferred(msg.sender, address(0));
    }

    function transferOwnership(address newOwner_) external override onlyOwner {
        pendingOwner = newOwner_;

        emit OwnershipTransferPending(msg.sender, newOwner_);
    }

    function acceptOwnership() external override {
        require(pendingOwner == msg.sender, "TV:NOT_PENDING_OWNER");

        emit OwnershipTransferred(owner, msg.sender);

        owner = msg.sender;
        pendingOwner = address(0);
    }

    /*********************/
    /*** Token Vesting ***/
    /*********************/

    function setVestingSchedules(address[] calldata receivers_, VestingSchedule[] calldata vestingSchedules_) external override onlyOwner {
        for (uint256 i; i < vestingSchedules_.length; ++i) {
            address receiver = receivers_[i];

            vestingScheduleOf[receiver] = vestingSchedules_[i];

            emit VestingScheduleSet(receiver);
        }
    }

    function fundVesting(uint256 totalTokens_) external override onlyOwner {
        require(totalVestingsTokens == uint256(0), "TV:ALREADY_FUNDED");

        _safeTransferFrom(token, msg.sender, address(this), totalTokens_);

        totalVestingsTokens = totalTokens_;

        emit VestingFunded(totalTokens_);
    }

    function changeReceiver(address oldReceiver_, address newReceiver_) external override onlyOwner {
        // Swap old and new receivers' vesting schedule, using address(0) as a scratch space.
        // This is done to not overwrite an active vesting schedule.
        vestingScheduleOf[address(0)] = vestingScheduleOf[oldReceiver_];
        vestingScheduleOf[oldReceiver_] = vestingScheduleOf[newReceiver_];
        vestingScheduleOf[newReceiver_] = vestingScheduleOf[address(0)];

        delete vestingScheduleOf[address(0)];

        emit ReceiverChanged(oldReceiver_, newReceiver_);
    }

    function claimableTokens(address receiver_) public view override returns (uint256 claimableTokens_) {
        VestingSchedule storage vestingSchedule = vestingScheduleOf[receiver_];

        uint256 totalPeriods = vestingSchedule.totalPeriods;

        if (totalPeriods == uint256(0)) return uint256(0);

        uint256 timePassed = block.timestamp - vestingSchedule.startTime;
        uint256 cliff = vestingSchedule.cliff;

        if (timePassed <= cliff) return uint256(0);

        uint256 multiplier = (timePassed - cliff) / vestingSchedule.timePerPeriod;

        return
            (
                (
                    (
                        multiplier > totalPeriods ? totalPeriods : multiplier
                    )
                    * vestingSchedule.totalTokens
                )
                / totalPeriods
            )
            - vestingSchedule.tokensClaimed;
    }

    function claimTokens(address destination_) external override {
        require(totalVestingsTokens > uint256(0), "TV:NOT_FUNDED");

        VestingSchedule storage vestingSchedule = vestingScheduleOf[msg.sender];

        uint256 tokensToClaim = claimableTokens(msg.sender);

        require(tokensToClaim > uint256(0), "TV:NO_CLAIMABLE");

        // NOTE: Setting tokensClaimed before transfer will result in no additional transfer on a reentrance.
        vestingSchedule.tokensClaimed += tokensToClaim;

        _safeTransfer(token, destination_, tokensToClaim);

        emit TokensClaimed(msg.sender, tokensToClaim, destination_);
    }

    function killVesting(address receiver_, address destination_) external override onlyOwner {
        VestingSchedule storage vestingSchedule = vestingScheduleOf[receiver_];

        uint256 totalTokens = vestingSchedule.totalTokens;
        uint256 tokensToClaim = totalTokens - vestingSchedule.tokensClaimed;

        // NOTE: Setting tokensClaimed before transfer will result in no additional transfer on a reentrance.
        vestingScheduleOf[receiver_].tokensClaimed = totalTokens;

        _safeTransfer(token, destination_, tokensToClaim);

        emit VestingKilled(receiver_, tokensToClaim, destination_);
    }

    /*********************/
    /*** Miscellaneous ***/
    /*********************/

    function recoverToken(address token_, address destination_) external override onlyOwner {
        require(token_ != token, "TV:CANNOT_RECOVER_VESTING_TOKEN");

        uint256 amount = IERC20Like(token_).balanceOf(address(this));

        require(amount > uint256(0), "TV:NO_TOKEN");

        _safeTransfer(token_, destination_, amount);

        emit RecoveredToken(token_, amount, destination_);
    }

    /******************/
    /*** Safe ERC20 ***/
    /******************/

    function _safeTransfer(address token_, address to_, uint256 amount_) internal {
        ( bool success, bytes memory data ) = token_.call(abi.encodeWithSelector(IERC20Like.transfer.selector, to_, amount_));

        require(success && (data.length == uint256(0) || abi.decode(data, (bool))), 'TV:SAFE_TRANSFER_FAILED');
    }

    function _safeTransferFrom(address token_, address from_, address to_, uint256 amount_) internal {
        ( bool success, bytes memory data ) = token_.call(abi.encodeWithSelector(IERC20Like.transferFrom.selector, from_, to_, amount_));

        require(success && (data.length == uint256(0) || abi.decode(data, (bool))), 'TV:SAFE_TRANSFER_FROM_FAILED');
    }

}