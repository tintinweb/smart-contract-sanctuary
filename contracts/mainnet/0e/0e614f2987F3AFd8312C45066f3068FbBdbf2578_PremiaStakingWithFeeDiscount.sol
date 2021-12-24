// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {IERC20} from "@solidstate/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";
import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";

import {PremiaStaking} from "./PremiaStaking.sol";
import {FeeDiscount} from "./FeeDiscount.sol";
import {FeeDiscountStorage} from "./FeeDiscountStorage.sol";

import {IPremiaStakingOld} from "./IPremiaStakingOld.sol";
import {IPremiaStakingWithFeeDiscount} from "./IPremiaStakingWithFeeDiscount.sol";

contract PremiaStakingWithFeeDiscount is
    IPremiaStakingWithFeeDiscount,
    PremiaStaking,
    FeeDiscount
{
    using SafeCast for uint256;

    // The old PremiaFeeDiscount contract
    address private immutable OLD_FEE_DISCOUNT;
    // The old PremiaStaking contract
    address private immutable OLD_STAKING;

    constructor(
        address premia,
        address oldFeeDiscount,
        address oldStaking
    ) PremiaStaking(premia) FeeDiscount(address(this)) {
        OLD_FEE_DISCOUNT = oldFeeDiscount;
        OLD_STAKING = oldStaking;
    }

    function _transferXPremia(
        address holder,
        address recipient,
        uint256 amount
    ) internal override {
        _transfer(holder, recipient, amount);
    }

    /**
     * @notice Migrate old xPremia from old FeeDiscount contract to new xPremia
     * @param user User for whom to migrate
     * @param amount Amount of old xPremia to migrate
     * @param stakePeriod Stake period selected in old contract
     * @param lockedUntil Lock end date from old contract
     */
    function migrate(
        address user,
        uint256 amount,
        uint256 stakePeriod,
        uint256 lockedUntil
    ) external {
        require(msg.sender == OLD_FEE_DISCOUNT, "Not authorized");

        (uint256 premiaDeposited, uint256 xPremiaMinted) = _migrateWithoutLock(
            amount,
            address(this)
        );

        emit Deposit(user, premiaDeposited);

        FeeDiscountStorage.Layout storage l = FeeDiscountStorage.layout();
        FeeDiscountStorage.UserInfo storage userInfo = l.userInfo[user];

        uint64 _lockedUntil = lockedUntil.toUint64();
        uint64 _stakePeriod = stakePeriod.toUint64();

        userInfo.balance += xPremiaMinted;

        if (_lockedUntil > userInfo.lockedUntil) {
            userInfo.lockedUntil = lockedUntil.toUint64();
        }

        if (_stakePeriod > userInfo.stakePeriod) {
            userInfo.stakePeriod = stakePeriod.toUint64();
        }
    }

    /**
     * @notice Migrate old xPremia to new xPremia using IERC2612 permit
     * @param amount Amount of old xPremia to migrate
     * @param deadline Deadline after which permit will fail
     * @param v V
     * @param r R
     * @param s S
     */
    function migrateWithoutLockWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 premiaDeposited, uint256 xPremiaMinted) {
        IERC2612(address(OLD_STAKING)).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        (premiaDeposited, xPremiaMinted) = _migrateWithoutLock(
            amount,
            msg.sender
        );
        emit Deposit(msg.sender, premiaDeposited);
    }

    /**
     * @notice Migrate old xPremia to new xPremia
     * @param amount Amount of old xPremia to migrate
     * @return premiaDeposited Amount of premia deposited
     * @return xPremiaMinted Amount of xPremia minted
     */
    function migrateWithoutLock(uint256 amount)
        external
        returns (uint256 premiaDeposited, uint256 xPremiaMinted)
    {
        (premiaDeposited, xPremiaMinted) = _migrateWithoutLock(
            amount,
            msg.sender
        );
        emit Deposit(msg.sender, premiaDeposited);
    }

    function _migrateWithoutLock(uint256 amount, address to)
        internal
        returns (uint256 premiaDeposited, uint256 xPremiaMinted)
    {
        _updateRewards();

        // Gets the amount of Premia locked in the contract
        uint256 totalPremia = _getStakedPremiaAmount();

        //

        IERC20(OLD_STAKING).transferFrom(msg.sender, address(this), amount);

        uint256 oldPremiaBalance = IERC20(PREMIA).balanceOf(address(this));
        IPremiaStakingOld(OLD_STAKING).leave(amount);
        uint256 newPremiaBalance = IERC20(PREMIA).balanceOf(address(this));

        uint256 toDeposit = newPremiaBalance - oldPremiaBalance;

        return (toDeposit, _mintShares(to, toDeposit, totalPremia));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(address holder, address spender)
        external
        view
        returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Helper library for safe casting of uint and int values
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library SafeCast {
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, 'SafeCast: value does not fit');
        return uint224(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, 'SafeCast: value does not fit');
        return uint128(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, 'SafeCast: value does not fit');
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, 'SafeCast: value does not fit');
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, 'SafeCast: value does not fit');
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, 'SafeCast: value does not fit');
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, 'SafeCast: value does not fit');
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, 'SafeCast: value must be positive');
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            'SafeCast: value does not fit'
        );
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            'SafeCast: value does not fit'
        );
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            'SafeCast: value does not fit'
        );
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            'SafeCast: value does not fit'
        );
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            'SafeCast: value does not fit'
        );
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(
            value <= uint256(type(int256).max),
            'SafeCast: value does not fit'
        );
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice ERC2612 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @notice approve spender to transfer tokens held by owner via signature
     * @dev this function may be vulnerable to approval replay attacks
     * @param owner holder of tokens and signer of permit
     * @param spender beneficiary of approval
     * @param amount quantity of tokens to approve
     * @param v secp256k1 'v' value
     * @param r secp256k1 'r' value
     * @param s secp256k1 's' value
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice get the current ERC2612 nonce for the given address
     * @return current nonce
     */
    function nonces(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {IERC20} from "@solidstate/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@solidstate/contracts/token/ERC20/ERC20.sol";
import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";
import {ERC20Permit} from "@solidstate/contracts/token/ERC20/permit/ERC20Permit.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";

import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";

import {ABDKMath64x64Token} from "../libraries/ABDKMath64x64Token.sol";
import {IPremiaStaking} from "./IPremiaStaking.sol";
import {PremiaStakingStorage} from "./PremiaStakingStorage.sol";

contract PremiaStaking is IPremiaStaking, ERC20, ERC20Permit {
    using SafeERC20 for IERC20;
    using ABDKMath64x64 for int128;

    address internal immutable PREMIA;

    int128 internal constant ONE_64x64 = 0x10000000000000000;
    int128 internal constant DECAY_RATE_64x64 = 0x487a423b63e; // 2.7e-7

    constructor(address premia) {
        PREMIA = premia;
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function addRewards(uint256 amount) external override {
        _updateRewards();

        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();

        IERC20(PREMIA).safeTransferFrom(msg.sender, address(this), amount);
        l.availableRewards += amount;
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getAvailableRewards() external view override returns (uint256) {
        return PremiaStakingStorage.layout().availableRewards;
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getPendingRewards() external view override returns (uint256) {
        return _getPendingRewards();
    }

    function _getPendingRewards() internal view returns (uint256) {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        return
            l.availableRewards -
            _decay(l.availableRewards, l.lastRewardUpdate, block.timestamp);
    }

    function _updateRewards() internal {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();

        if (l.lastRewardUpdate == 0) {
            l.lastRewardUpdate = block.timestamp;
            return;
        }

        if (l.availableRewards == 0) return;

        l.availableRewards -= _getPendingRewards();
        l.lastRewardUpdate = block.timestamp;
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        IERC2612(PREMIA).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        _deposit(amount);
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function deposit(uint256 amount) external override {
        _deposit(amount);
    }

    function _deposit(uint256 amount) internal {
        _updateRewards();

        // Gets the amount of Premia locked in the contract
        uint256 totalPremia = _getStakedPremiaAmount();

        _mintShares(msg.sender, amount, totalPremia);

        // Lock the Premia in the contract
        IERC20(PREMIA).safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, amount);
    }

    function _mintShares(
        address to,
        uint256 amount,
        uint256 totalPremia
    ) internal returns (uint256) {
        // Gets the amount of xPremia in existence
        uint256 totalShares = _totalSupply();
        // If no xPremia exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalPremia == 0) {
            _mint(to, amount);
            return amount;
        }
        // Calculate and mint the amount of xPremia the Premia is worth. The ratio will change overtime, as xPremia is burned/minted and Premia deposited + gained from fees / withdrawn.
        else {
            uint256 shares = (amount * totalShares) / totalPremia;
            _mint(to, shares);
            return shares;
        }
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function startWithdraw(uint256 amount) external override {
        _updateRewards();

        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();

        // Gets the amount of xPremia in existence
        uint256 totalShares = _totalSupply();

        // Calculates the amount of Premia the xPremia is worth
        uint256 premiaAmount = (amount * _getStakedPremiaAmount()) /
            totalShares;
        _burn(msg.sender, amount);
        l.pendingWithdrawal += premiaAmount;

        l.withdrawals[msg.sender].amount += premiaAmount;
        l.withdrawals[msg.sender].startDate = block.timestamp;

        emit StartWithdrawal(msg.sender, premiaAmount, block.timestamp);
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function withdraw() external override {
        _updateRewards();

        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();

        uint256 startDate = l.withdrawals[msg.sender].startDate;

        require(startDate > 0, "No pending withdrawal");
        require(
            block.timestamp > startDate + l.withdrawalDelay,
            "Withdrawal still pending"
        );

        uint256 amount = l.withdrawals[msg.sender].amount;

        l.pendingWithdrawal -= amount;
        delete l.withdrawals[msg.sender];

        IERC20(PREMIA).safeTransfer(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getWithdrawalDelay() external view override returns (uint256) {
        return PremiaStakingStorage.layout().withdrawalDelay;
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function setWithdrawalDelay(uint256 delay) external override {
        PremiaStakingStorage.layout().withdrawalDelay = delay;
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getXPremiaToPremiaRatio()
        external
        view
        override
        returns (uint256)
    {
        return
            ((_getStakedPremiaAmount() + _getPendingRewards()) * 1e18) /
            _totalSupply();
    }

    function getPendingWithdrawal(address user)
        external
        view
        override
        returns (
            uint256 amount,
            uint256 startDate,
            uint256 unlockDate
        )
    {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        amount = l.withdrawals[user].amount;
        startDate = l.withdrawals[user].startDate;
        unlockDate = startDate + l.withdrawalDelay;
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getStakedPremiaAmount() external view override returns (uint256) {
        return _getStakedPremiaAmount() + _getPendingRewards();
    }

    function _getStakedPremiaAmount() internal view returns (uint256) {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        return
            IERC20(PREMIA).balanceOf(address(this)) -
            l.pendingWithdrawal -
            l.availableRewards;
    }

    function _decay(
        uint256 pendingRewards,
        uint256 oldTimestamp,
        uint256 newTimestamp
    ) internal pure returns (uint256) {
        return
            ONE_64x64
                .sub(DECAY_RATE_64x64)
                .pow(newTimestamp - oldTimestamp)
                .mulu(pendingRewards);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";
import {IERC20, SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";

import {FeeDiscountStorage} from "./FeeDiscountStorage.sol";
import {IFeeDiscount} from "./IFeeDiscount.sol";

/**
 * @author Premia
 * @title A contract allowing you to lock xPremia to get Premia protocol fee discounts
 */
contract FeeDiscount is IFeeDiscount {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    address internal immutable xPREMIA;
    uint256 internal constant INVERSE_BASIS_POINT = 1e4;

    constructor(address xPremia) {
        xPREMIA = xPremia;
    }

    //////////////////////////////////////////////////

    //////////
    // Main //
    //////////

    /**
     * @inheritdoc IFeeDiscount
     */
    function stakeWithPermit(
        uint256 amount,
        uint256 period,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC2612(address(xPREMIA)).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        _stake(amount, period);
    }

    /**
     * @inheritdoc IFeeDiscount
     */
    function stake(uint256 amount, uint256 period) external override {
        _stake(amount, period);
    }

    function _stake(uint256 amount, uint256 period) internal {
        FeeDiscountStorage.Layout storage l = FeeDiscountStorage.layout();

        require(
            _getStakePeriodMultiplier(period) > 0,
            "Stake period does not exists"
        );
        FeeDiscountStorage.UserInfo storage user = l.userInfo[msg.sender];

        uint256 lockedUntil = block.timestamp + period;
        require(
            lockedUntil > user.lockedUntil,
            "Cannot add stake with lower stake period"
        );

        _transferXPremia(msg.sender, address(this), amount);
        user.balance = user.balance + amount;
        user.lockedUntil = lockedUntil.toUint64();
        user.stakePeriod = period.toUint64();

        emit Staked(msg.sender, amount, period, lockedUntil);
    }

    /**
     * @inheritdoc IFeeDiscount
     */
    function unstake(uint256 amount) external override {
        FeeDiscountStorage.Layout storage l = FeeDiscountStorage.layout();

        FeeDiscountStorage.UserInfo storage user = l.userInfo[msg.sender];

        // We allow unstake if the stakePeriod that the user used has been disabled
        require(user.lockedUntil <= block.timestamp, "Stake still locked");

        user.balance -= amount;
        _transferXPremia(address(this), msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    //////////////////////////////////////////////////

    //////////
    // View //
    //////////

    /**
     * @inheritdoc IFeeDiscount
     */
    function getStakeAmountWithBonus(address user)
        external
        view
        override
        returns (uint256)
    {
        return _getStakeAmountWithBonus(user);
    }

    /**
     * @inheritdoc IFeeDiscount
     */
    function getDiscount(address user)
        external
        view
        override
        returns (uint256)
    {
        uint256 userBalance = _getStakeAmountWithBonus(user);

        IFeeDiscount.StakeLevel[] memory stakeLevels = _getStakeLevels();

        for (uint256 i = 0; i < stakeLevels.length; i++) {
            IFeeDiscount.StakeLevel memory level = stakeLevels[i];

            if (userBalance < level.amount) {
                uint256 amountPrevLevel;
                uint256 discountPrevLevel;

                // If stake is lower, user is in this level, and we need to LERP with prev level to get discount value
                if (i > 0) {
                    amountPrevLevel = stakeLevels[i - 1].amount;
                    discountPrevLevel = stakeLevels[i - 1].discount;
                } else {
                    // If this is the first level, prev level is 0 / 0
                    amountPrevLevel = 0;
                    discountPrevLevel = 0;
                }

                uint256 remappedDiscount = level.discount - discountPrevLevel;

                uint256 remappedAmount = level.amount - amountPrevLevel;
                uint256 remappedBalance = userBalance - amountPrevLevel;
                uint256 levelProgress = (remappedBalance *
                    INVERSE_BASIS_POINT) / remappedAmount;

                return
                    discountPrevLevel +
                    ((remappedDiscount * levelProgress) / INVERSE_BASIS_POINT);
            }
        }

        // If no match found it means user is >= max possible stake, and therefore has max discount possible
        return stakeLevels[stakeLevels.length - 1].discount;
    }

    /**
     * @inheritdoc IFeeDiscount
     */
    function getStakeLevels()
        external
        pure
        override
        returns (IFeeDiscount.StakeLevel[] memory stakeLevels)
    {
        return _getStakeLevels();
    }

    /**
     * @inheritdoc IFeeDiscount
     */
    function getStakePeriodMultiplier(uint256 period)
        external
        pure
        override
        returns (uint256)
    {
        return _getStakePeriodMultiplier(period);
    }

    /**
     * @inheritdoc IFeeDiscount
     */
    function getUserInfo(address user)
        external
        view
        override
        returns (FeeDiscountStorage.UserInfo memory)
    {
        return FeeDiscountStorage.layout().userInfo[user];
    }

    //////////////////////////////////////////////////

    //////////////
    // Internal //
    //////////////

    /**
     * @notice Utility function to check if a value is inside an array
     * @param value The value to look for
     * @param array The array to check
     * @return Whether the value is in the array or not
     */
    function _isInArray(uint256 value, uint256[] memory array)
        internal
        pure
        returns (bool)
    {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; ++i) {
            if (array[i] == value) {
                return true;
            }
        }

        return false;
    }

    function _getStakeLevels()
        internal
        pure
        returns (IFeeDiscount.StakeLevel[] memory stakeLevels)
    {
        stakeLevels = new IFeeDiscount.StakeLevel[](4);

        stakeLevels[0] = IFeeDiscount.StakeLevel(5000 * 1e18, 2500); // -25%
        stakeLevels[1] = IFeeDiscount.StakeLevel(50000 * 1e18, 5000); // -50%
        stakeLevels[2] = IFeeDiscount.StakeLevel(250000 * 1e18, 7500); // -75%
        stakeLevels[3] = IFeeDiscount.StakeLevel(500000 * 1e18, 9500); // -95%
    }

    function _getStakePeriodMultiplier(uint256 period)
        internal
        pure
        returns (uint256)
    {
        if (period == 30 days) return 10000; // x1
        if (period == 90 days) return 12500; // x1.25
        if (period == 180 days) return 15000; // x1.5
        if (period == 360 days) return 20000; // x2

        return 0;
    }

    function _getStakeAmountWithBonus(address user)
        internal
        view
        returns (uint256)
    {
        FeeDiscountStorage.Layout storage l = FeeDiscountStorage.layout();

        FeeDiscountStorage.UserInfo memory userInfo = l.userInfo[user];
        return
            (userInfo.balance *
                _getStakePeriodMultiplier(userInfo.stakePeriod)) /
            INVERSE_BASIS_POINT;
    }

    /**
     * @notice transfer tokens from holder to recipient
     * @param holder owner of tokens to be transferred
     * @param recipient beneficiary of transfer
     * @param amount quantity of tokens transferred
     */
    function _transferXPremia(
        address holder,
        address recipient,
        uint256 amount
    ) internal virtual {
        if (holder == address(this)) {
            IERC20(xPREMIA).safeTransfer(recipient, amount);
        } else {
            IERC20(xPREMIA).safeTransferFrom(holder, recipient, amount);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

library FeeDiscountStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.staking.PremiaFeeDiscount");

    struct UserInfo {
        uint256 balance; // Balance staked by user
        uint64 stakePeriod; // Stake period selected by user
        uint64 lockedUntil; // Timestamp at which the lock ends
    }

    struct Layout {
        // User data with xPREMIA balance staked and date at which lock ends
        mapping(address => UserInfo) userInfo;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IPremiaStakingOld {
    /**
     * @notice stake PREMIA using IERC2612 permit
     * @param amount quantity of PREMIA to stake
     * @param deadline timestamp after which permit will fail
     * @param v signature "v" value
     * @param r signature "r" value
     * @param s signature "s" value
     */
    function enterWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice stake PREMIA in exchange for xPremia
     * @param amount quantity of PREMIA to stake
     */
    function enter(uint256 amount) external;

    /**
     * @notice burn xPremia in exchange for staked PREMIA
     * @param amount quantity of xPremia to unstake
     */
    function leave(uint256 amount) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import {IPremiaStaking} from "./IPremiaStaking.sol";
import {IFeeDiscount} from "./IFeeDiscount.sol";

interface IPremiaStakingWithFeeDiscount is IPremiaStaking, IFeeDiscount {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20Base } from './base/ERC20Base.sol';
import { ERC20Extended } from './extended/ERC20Extended.sol';
import { ERC20Metadata } from './metadata/ERC20Metadata.sol';

/**
 * @title SolidState ERC20 implementation, including recommended extensions
 */
abstract contract ERC20 is ERC20Base, ERC20Extended, ERC20Metadata {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ECDSA } from '../../../cryptography/ECDSA.sol';
import { ERC20Base } from '../base/ERC20Base.sol';
import { ERC20Metadata } from '../metadata/ERC20Metadata.sol';
import { ERC20PermitStorage } from './ERC20PermitStorage.sol';
import { IERC2612 } from './IERC2612.sol';

/**
 * @title ERC20 extension with support for ERC2612 permits
 * @dev derived from https://github.com/soliditylabs/ERC20-Permit (MIT license)
 */
abstract contract ERC20Permit is IERC2612, ERC20Base, ERC20Metadata {
    using ECDSA for bytes32;

    /**
     * @inheritdoc IERC2612
     * @dev If https://eips.ethereum.org/EIPS/eip-1344[ChainID] ever changes, the
     * EIP712 Domain Separator is automatically recalculated.
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, 'ERC20Permit: expired deadline');

        // Assembly for more efficiently computing:
        // bytes32 hashStruct = keccak256(
        //   abi.encode(
        //     _PERMIT_TYPEHASH,
        //     owner,
        //     spender,
        //     amount,
        //     _nonces[owner].current(),
        //     deadline
        //   )
        // );

        bytes32 hashStruct;
        uint256 nonce = ERC20PermitStorage.layout().nonces[owner];

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
            mstore(
                memPtr,
                0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9
            )
            mstore(add(memPtr, 32), owner)
            mstore(add(memPtr, 64), spender)
            mstore(add(memPtr, 96), amount)
            mstore(add(memPtr, 128), nonce)
            mstore(add(memPtr, 160), deadline)

            hashStruct := keccak256(memPtr, 192)
        }

        bytes32 eip712DomainHash = _domainSeparator();

        // Assembly for more efficient computing:
        // bytes32 hash = keccak256(
        //   abi.encodePacked(uint16(0x1901), eip712DomainHash, hashStruct)
        // );

        bytes32 hash;

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(
                memPtr,
                0x1901000000000000000000000000000000000000000000000000000000000000
            ) // EIP191 header
            mstore(add(memPtr, 2), eip712DomainHash) // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct) // Hash of struct

            hash := keccak256(memPtr, 66)
        }

        address signer = hash.recover(v, r, s);

        require(signer == owner, 'ERC20Permit: invalid signature');

        ERC20PermitStorage.layout().nonces[owner]++;
        _approve(owner, spender, amount);
    }

    /**
     * @dev inhertidoc IERC2612
     */
    function nonces(address owner) public view override returns (uint256) {
        return ERC20PermitStorage.layout().nonces[owner];
    }

    /**
     * @notice update domain separator for new chain ID
     * @return new domain separator
     */
    function _updateDomainSeparator() private returns (bytes32) {
        uint256 chainId = _chainId();

        // no need for assembly, running very rarely
        bytes32 newDomainSeparator = keccak256(
            abi.encode(
                keccak256(
                    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                ),
                keccak256(bytes(name())), // ERC-20 Name
                keccak256(bytes('1')), // Version
                chainId,
                address(this)
            )
        );

        ERC20PermitStorage.layout().domainSeparators[
            chainId
        ] = newDomainSeparator;

        return newDomainSeparator;
    }

    /**
     * @notice update chain ID if changed and return domain separator
     * @return domain separator
     */
    function _domainSeparator() private returns (bytes32) {
        bytes32 domainSeparator = ERC20PermitStorage.layout().domainSeparators[
            _chainId()
        ];

        if (domainSeparator != 0x00) {
            return domainSeparator;
        }

        return _updateDomainSeparator();
    }

    /**
     * @notice get the current chain ID
     * @return chainId chain ID
     */
    function _chainId() private view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '../token/ERC20/IERC20.sol';
import { AddressUtils } from './AddressUtils.sol';

/**
 * @title Safe ERC20 interaction library
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library SafeERC20 {
    using AddressUtils for address;

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
     * @dev safeApprove (like approve) should only be called when setting an initial allowance or when resetting it to zero; otherwise prefer safeIncreaseAllowance and safeDecreaseAllowance
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
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
                'SafeERC20: decreased allowance below zero'
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
     * @notice send transaction data and check validity of return value, if present
     * @param token ERC20 token interface
     * @param data transaction data
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );

        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                'SafeERC20: ERC20 operation did not succeed'
            );
        }
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";

library ABDKMath64x64Token {
    using ABDKMath64x64 for int128;

    /**
     * @notice convert 64x64 fixed point representation of token amount to decimal
     * @param value64x64 64x64 fixed point representation of token amount
     * @param decimals token display decimals
     * @return value decimal representation of token amount
     */
    function toDecimals(int128 value64x64, uint8 decimals)
        internal
        pure
        returns (uint256 value)
    {
        value = value64x64.mulu(10**decimals);
    }

    /**
     * @notice convert decimal representation of token amount to 64x64 fixed point
     * @param value decimal representation of token amount
     * @param decimals token display decimals
     * @return value64x64 64x64 fixed point representation of token amount
     */
    function fromDecimals(uint256 value, uint8 decimals)
        internal
        pure
        returns (int128 value64x64)
    {
        value64x64 = ABDKMath64x64.divu(value, 10**decimals);
    }

    /**
     * @notice convert 64x64 fixed point representation of token amount to wei (18 decimals)
     * @param value64x64 64x64 fixed point representation of token amount
     * @return value wei representation of token amount
     */
    function toWei(int128 value64x64) internal pure returns (uint256 value) {
        value = toDecimals(value64x64, 18);
    }

    /**
     * @notice convert wei representation (18 decimals) of token amount to 64x64 fixed point
     * @param value wei representation of token amount
     * @return value64x64 64x64 fixed point representation of token amount
     */
    function fromWei(uint256 value) internal pure returns (int128 value64x64) {
        value64x64 = fromDecimals(value, 18);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import {PremiaStakingStorage} from "./PremiaStakingStorage.sol";

interface IPremiaStaking {
    event Deposit(address indexed user, uint256 amount);
    event StartWithdrawal(
        address indexed user,
        uint256 premiaAmount,
        uint256 startDate
    );
    event Withdrawal(address indexed user, uint256 amount);

    /**
     * @notice add premia tokens as available tokens to be distributed as rewards
     * @param amount amount of premia tokens to add as rewards
     */
    function addRewards(uint256 amount) external;

    /**
     * @notice get amount of tokens that have not yet been distributed as rewards
     * @return amount of tokens not yet distributed as rewards
     */
    function getAvailableRewards() external view returns (uint256);

    /**
     * @notice get pending amount of tokens to be distributed as rewards to stakers
     * @return amount of tokens pending to be distributed as rewards
     */
    function getPendingRewards() external view returns (uint256);

    /**
     * @notice stake PREMIA using IERC2612 permit
     * @param amount quantity of PREMIA to stake
     * @param deadline timestamp after which permit will fail
     * @param v signature "v" value
     * @param r signature "r" value
     * @param s signature "s" value
     */
    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice stake PREMIA in exchange for xPremia
     * @param amount quantity of PREMIA to stake
     */
    function deposit(uint256 amount) external;

    /**
     * @notice Initiate the withdrawal process by burning xPremia, starting the delay period
     * @param amount quantity of xPremia to unstake
     */
    function startWithdraw(uint256 amount) external;

    /**
     * @notice withdraw PREMIA after withdrawal delay has passed
     */
    function withdraw() external;

    /**
     * @notice get current withdrawal delay
     * @return withdrawal delay
     */
    function getWithdrawalDelay() external view returns (uint256);

    /**
     * @notice set current withdrawal delay
     * @param delay withdrawal delay
     */
    function setWithdrawalDelay(uint256 delay) external;

    /**
     * @notice get the xPREMIA : PREMIA ratio (with 18 decimals)
     * @return xPREMIA : PREMIA ratio (with 18 decimals)
     */
    function getXPremiaToPremiaRatio() external view returns (uint256);

    /**
     * @notice get pending withdrawal data of a user
     * @return amount pending withdrawal amount
     * @return startDate start timestamp of withdrawal
     * @return unlockDate timestamp at which withdrawal becomes available
     */
    function getPendingWithdrawal(address user)
        external
        view
        returns (
            uint256 amount,
            uint256 startDate,
            uint256 unlockDate
        );

    /**
     * @notice get the amount of PREMIA staked (subtracting all pending withdrawals)
     * @return amount of PREMIA staked
     */
    function getStakedPremiaAmount() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

library PremiaStakingStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.staking.PremiaStaking");

    struct Withdrawal {
        uint256 amount; // Premia amount
        uint256 startDate; // Will unlock at startDate + withdrawalDelay
    }

    struct Layout {
        uint256 pendingWithdrawal;
        uint256 withdrawalDelay;
        mapping(address => Withdrawal) withdrawals;
        uint256 availableRewards;
        uint256 lastRewardUpdate; // Timestamp of last reward distribution update
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '../IERC20.sol';
import { ERC20BaseInternal } from './ERC20BaseInternal.sol';
import { ERC20BaseStorage } from './ERC20BaseStorage.sol';

/**
 * @title Base ERC20 implementation, excluding optional extensions
 */
abstract contract ERC20Base is IERC20, ERC20BaseInternal {
    /**
     * @inheritdoc IERC20
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC20
     */
    function allowance(address holder, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return ERC20BaseStorage.layout().allowances[holder][spender];
    }

    /**
     * @inheritdoc IERC20
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = ERC20BaseStorage.layout().allowances[holder][
            msg.sender
        ];
        require(
            currentAllowance >= amount,
            'ERC20: transfer amount exceeds allowance'
        );
        unchecked {
            _approve(holder, msg.sender, currentAllowance - amount);
        }
        _transfer(holder, recipient, amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20Base, ERC20BaseStorage } from '../base/ERC20Base.sol';

/**
 * @title ERC20 safe approval extensions
 * @dev mitigations for transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
 */
abstract contract ERC20Extended is ERC20Base {
    /**
     * @notice increase spend amount granted to spender
     * @param spender address whose allowance to increase
     * @param amount quantity by which to increase allowance
     * @return success status (always true; otherwise function will revert)
     */
    function increaseAllowance(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        unchecked {
            mapping(address => uint256) storage allowances = ERC20BaseStorage
                .layout()
                .allowances[msg.sender];

            uint256 allowance = allowances[spender];
            require(
                allowance + amount >= allowance,
                'ERC20Extended: excessive allowance'
            );

            _approve(
                msg.sender,
                spender,
                allowances[spender] = allowance + amount
            );

            return true;
        }
    }

    /**
     * @notice decrease spend amount granted to spender
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     * @return success status (always true; otherwise function will revert)
     */
    function decreaseAllowance(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        unchecked {
            mapping(address => uint256) storage allowances = ERC20BaseStorage
                .layout()
                .allowances[msg.sender];

            uint256 allowance = allowances[spender];
            require(
                amount <= allowance,
                'ERC20Extended: insufficient allowance'
            );

            _approve(
                msg.sender,
                spender,
                allowances[spender] = allowance - amount
            );

            return true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20MetadataStorage } from './ERC20MetadataStorage.sol';
import { IERC20Metadata } from './IERC20Metadata.sol';

/**
 * @title ERC20 metadata extensions
 */
abstract contract ERC20Metadata is IERC20Metadata {
    /**
     * @inheritdoc IERC20Metadata
     */
    function name() public view virtual override returns (string memory) {
        return ERC20MetadataStorage.layout().name;
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC20MetadataStorage.layout().symbol;
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function decimals() public view virtual override returns (uint8) {
        return ERC20MetadataStorage.layout().decimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20Internal } from '../IERC20Internal.sol';
import { ERC20BaseStorage } from './ERC20BaseStorage.sol';

/**
 * @title Base ERC20 implementation, excluding optional extensions
 */
abstract contract ERC20BaseInternal is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function _totalSupply() internal view virtual returns (uint256) {
        return ERC20BaseStorage.layout().totalSupply;
    }

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function _balanceOf(address account)
        internal
        view
        virtual
        returns (uint256)
    {
        return ERC20BaseStorage.layout().balances[account];
    }

    /**
     * @notice enable spender to spend tokens on behalf of holder
     * @param holder address on whose behalf tokens may be spent
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     */
    function _approve(
        address holder,
        address spender,
        uint256 amount
    ) internal virtual {
        require(holder != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        ERC20BaseStorage.layout().allowances[holder][spender] = amount;

        emit Approval(holder, spender, amount);
    }

    /**
     * @notice mint tokens for given account
     * @param account recipient of minted tokens
     * @param amount quantity of tokens minted
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), 'ERC20: mint to the zero address');

        _beforeTokenTransfer(address(0), account, amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        l.totalSupply += amount;
        l.balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice burn tokens held by given account
     * @param account holder of burned tokens
     * @param amount quantity of tokens burned
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        uint256 balance = l.balances[account];
        require(balance >= amount, 'ERC20: burn amount exceeds balance');
        unchecked {
            l.balances[account] = balance - amount;
        }
        l.totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice transfer tokens from holder to recipient
     * @param holder owner of tokens to be transferred
     * @param recipient beneficiary of transfer
     * @param amount quantity of tokens transferred
     */
    function _transfer(
        address holder,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(holder != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

        _beforeTokenTransfer(holder, recipient, amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        uint256 holderBalance = l.balances[holder];
        require(
            holderBalance >= amount,
            'ERC20: transfer amount exceeds balance'
        );
        unchecked {
            l.balances[holder] = holderBalance - amount;
        }
        l.balances[recipient] += amount;

        emit Transfer(holder, recipient, amount);
    }

    /**
     * @notice ERC20 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param amount quantity of tokens transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC20BaseStorage {
    struct Layout {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC20Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC20MetadataStorage {
    struct Layout {
        string name;
        string symbol;
        uint8 decimals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC20Metadata');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setName(Layout storage l, string memory name) internal {
        l.name = name;
    }

    function setSymbol(Layout storage l, string memory symbol) internal {
        l.symbol = symbol;
    }

    function setDecimals(Layout storage l, uint8 decimals) internal {
        l.decimals = decimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Elliptic Curve Digital Signature Algorithm (ECDSA) operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library ECDSA {
    /**
     * @notice recover signer of hashed message from signature
     * @param hash hashed data payload
     * @param signature signed data payload
     * @return recovered message signer
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        require(signature.length == 65, 'ECDSA: invalid signature length');

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @notice recover signer of hashed message from signature v, r, and s values
     * @param hash hashed data payload
     * @param v signature "v" value
     * @param r signature "r" value
     * @param s signature "s" value
     * @return recovered message signer
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), 'ECDSA: invalid signature');

        return signer;
    }

    /**
     * @notice generate an "Ethereum Signed Message" in the format returned by the eth_sign JSON-RPC method
     * @param hash hashed data payload
     * @return signed message hash
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked('\x19Ethereum Signed Message:\n32', hash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC20PermitStorage {
    struct Layout {
        mapping(address => uint256) nonces;
        // Mapping of ChainID to domain separators. This is a very gas efficient way
        // to not recalculate the domain separator on every call, while still
        // automatically detecting ChainID changes.
        mapping(uint256 => bytes32) domainSeparators;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC20Permit');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressUtils {
    function toString(address account) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(account)));
        bytes memory alphabet = '0123456789abcdef';
        bytes memory chars = new bytes(42);

        chars[0] = '0';
        chars[1] = 'x';

        for (uint256 i = 0; i < 20; i++) {
            chars[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            chars[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }

        return string(chars);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

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
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import {FeeDiscountStorage} from "./FeeDiscountStorage.sol";

interface IFeeDiscount {
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 stakePeriod,
        uint256 lockedUntil
    );
    event Unstaked(address indexed user, uint256 amount);

    struct StakeLevel {
        uint256 amount; // Amount to stake
        uint256 discount; // Discount when amount is reached
    }

    /**
     * @notice Stake using IERC2612 permit
     * @param amount The amount of xPremia to stake
     * @param period The lockup period (in seconds)
     * @param deadline Deadline after which permit will fail
     * @param v V
     * @param r R
     * @param s S
     */
    function stakeWithPermit(
        uint256 amount,
        uint256 period,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Lockup xPremia for protocol fee discounts
     *          Longer period of locking will apply a multiplier on the amount staked, in the fee discount calculation
     * @param amount The amount of xPremia to stake
     * @param period The lockup period (in seconds)
     */
    function stake(uint256 amount, uint256 period) external;

    /**
     * @notice Unstake xPremia (If lockup period has ended)
     * @param amount The amount of xPremia to unstake
     */
    function unstake(uint256 amount) external;

    //////////
    // View //
    //////////

    /**
     * Calculate the stake amount of a user, after applying the bonus from the lockup period chosen
     * @param user The user from which to query the stake amount
     * @return The user stake amount after applying the bonus
     */
    function getStakeAmountWithBonus(address user)
        external
        view
        returns (uint256);

    /**
     * @notice Calculate the % of fee discount for user, based on his stake
     * @param user The _user for which the discount is for
     * @return Percentage of protocol fee discount (in basis point)
     *         Ex : 1000 = 10% fee discount
     */
    function getDiscount(address user) external view returns (uint256);

    /**
     * @notice Get stake levels
     * @return Stake levels
     *         Ex : 2500 = -25%
     */
    function getStakeLevels() external returns (StakeLevel[] memory);

    /**
     * @notice Get stake period multiplier
     * @param period The duration (in seconds) for which tokens are locked
     * @return The multiplier for this staking period
     *         Ex : 20000 = x2
     */
    function getStakePeriodMultiplier(uint256 period)
        external
        returns (uint256);

    /**
     * @notice Get staking infos of a user
     * @param user The user address for which to get staking infos
     * @return The staking infos of the user
     */
    function getUserInfo(address user)
        external
        view
        returns (FeeDiscountStorage.UserInfo memory);
}