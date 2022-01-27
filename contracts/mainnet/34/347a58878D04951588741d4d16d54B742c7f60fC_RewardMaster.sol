// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "./actions/RewardAdvisersList.sol";
import "./interfaces/IActionMsgReceiver.sol";
import "./interfaces/IErc20Min.sol";
import "./interfaces/IRewardAdviser.sol";
import "./interfaces/IRewardPool.sol";
import "./utils/ImmutableOwnable.sol";
import "./utils/Claimable.sol";
import "./utils/NonReentrant.sol";
import "./utils/Utils.sol";

/***
 * @title RewardMaster
 * @notice It accounts rewards and distributes reward tokens to users.
 * @dev It withdraws the reward token from (or via) the "REWARD_POOL" contract,
 * and keeps tokens, aka "Treasury", on its balance until distribution.
 * It issues to users "shares" in the Treasury, or redeems shares, paying out
 * tokens from the Treasury to users, or on behalf of users, as follows.
 * It receives messages (calls) on "actions" to be rewarded from authorized
 * "ActionOracle" contracts.
 * On every "action" message received, it calls a "RewardAdviser" contract,
 * assigned for that ActionOracle and action type, which advices on how many
 * shares shall be created and to whom, or whose shares must be redeemed, and
 * where reward tokens shall be sent to.
 * The owner may add or remove addresses of ActionOracle`s and RewardAdviser`s.
 */
contract RewardMaster is
    ImmutableOwnable,
    Utils,
    Claimable,
    NonReentrant,
    RewardAdvisersList,
    IActionMsgReceiver
{
    // solhint-disable var-name-mixedcase

    /// @notice Token rewards are given in
    address public immutable REWARD_TOKEN;

    /// @notice RewardPool instance that vests the reward token
    address public immutable REWARD_POOL;

    /// @dev Block the contract deployed in
    uint256 public immutable START_BLOCK;

    // solhint-enable var-name-mixedcase

    /**
     * At any time, the amount of the reward token a user is entitled to is:
     *   tokenAmountEntitled = accumRewardPerShare * user.shares - user.offset
     *
     * This formula works since we update parameters as follows ...
     *
     * - when a new reward token amount added to the Treasury:
     *   accumRewardPerShare += tokenAmountAdded / totalShares
     *
     * - when new shares granted to a user:
     *   user.offset += sharesToCreate * accumRewardPerShare
     *   user.shares += sharesToCreate
     *   totalShares += sharesToCreate
     *
     * - when shares redeemed to a user:
     *   redemptionRate = accumRewardPerShare - user.offset/user.shares
     *   user.offset -= user.offset/user.shares * sharesToRedeem
     *   user.shares -= sharesToRedeem
     *   totalShares -= sharesToRedeem
     *   tokenAmountPayable = redemptionRate * sharesToRedeem
     *
     * (Scaling omitted in formulas above for clarity.)
     */

    /// @dev Block when reward tokens were last time were vested in
    uint32 public lastVestedBlock;
    /// @dev Reward token balance (aka Treasury) after last vesting
    /// (token total supply is supposed to not exceed 2**96)
    uint96 public lastBalance;

    /// @notice Total number of unredeemed shares
    /// (it is supposed to not exceed 2**128)
    uint128 public totalShares;
    /// @dev Min number of unredeemed shares being rewarded
    uint256 private constant MIN_SHARES_REWARDED = 1000;
    /// @dev Min number of blocks between vesting in the Treasury
    uint256 private constant MIN_VESTING_BLOCKS = 300;

    // see comments above for explanation
    uint256 public accumRewardPerShare;
    // `accumRewardPerShare` is scaled (up) with this factor
    uint256 private constant SCALE = 1e9;

    // see comments above for explanation
    struct UserRecord {
        // (limited to 2**96)
        uint96 shares;
        uint160 offset;
    }

    // Mapping from user address to UserRecord data
    mapping(address => UserRecord) public records;

    /// @dev Emitted when new shares granted to a user
    event SharesGranted(address indexed user, uint256 amount);
    /// @dev Emitted when shares of a user redeemed
    event SharesRedeemed(address indexed user, uint256 amount);
    /// @dev Emitted when new reward token amount vested to this contract
    event RewardAdded(uint256 reward);
    /// @dev Emitted when reward token amount paid to/for a user
    event RewardPaid(address indexed user, uint256 reward);
    /// @dev Emitted when the Treasury counts for "extra" reward tokens.
    /// "Extra" tokens are ones sent to this contract directly (rather than
    /// vested via the REWARD_POOL).
    event BalanceAdjusted(uint256 adjustment);

    constructor(
        address _rewardToken,
        address _rewardPool,
        address _owner
    ) ImmutableOwnable(_owner) {
        require(
            _rewardToken != address(0) && _rewardPool != address(0),
            "RM:C1"
        );

        REWARD_TOKEN = _rewardToken;
        REWARD_POOL = _rewardPool;
        START_BLOCK = blockNow();
    }

    /// @notice Returns reward token amount entitled to the given user/account
    // This amount the account would get if shares would be redeemed now
    function entitled(address account) public view returns (uint256 reward) {
        UserRecord memory rec = records[account];
        if (rec.shares == 0) return 0;

        // no reentrancy guard needed for the known contract call
        uint256 releasable = IRewardPool(REWARD_POOL).releasableAmount();
        uint256 _accumRewardPerShare = accumRewardPerShare;
        uint256 _totalShares = uint256(totalShares);
        if (releasable != 0 && _totalShares >= MIN_SHARES_REWARDED) {
            _accumRewardPerShare += (releasable * SCALE) / _totalShares;
        }

        (reward, , ) = _computeRedemption(
            uint256(rec.shares),
            rec,
            _accumRewardPerShare
        );
    }

    function onAction(bytes4 action, bytes memory message) external override {
        IRewardAdviser adviser = _getRewardAdviserOrRevert(msg.sender, action);
        // no reentrancy guard needed for the known contract call
        IRewardAdviser.Advice memory advice = adviser.getRewardAdvice(
            action,
            message
        );
        if (advice.sharesToCreate > 0) {
            _grantShares(advice.createSharesFor, advice.sharesToCreate);
        }
        if (advice.sharesToRedeem > 0) {
            _redeemShares(
                advice.redeemSharesFrom,
                advice.sharesToRedeem,
                advice.sendRewardTo
            );
        }
    }

    function triggerVesting() external {
        _triggerVesting(true, false);
    }

    /* ========== ONLY FOR OWNER FUNCTIONS ========== */

    /**
     * @notice Adds the "RewardAdviser" for given ActionOracle and action type
     * @dev May be only called by the {OWNER}
     * !!!!! Before adding a new "adviser", ensure "shares" it "advices" can not
     * overflow `UserRecord.shares`, `UserRecord.offset` and `totalShares`.
     */
    function addRewardAdviser(
        address oracle,
        bytes4 action,
        address adviser
    ) external onlyOwner {
        _addRewardAdviser(oracle, action, adviser);
    }

    /// @notice Remove "RewardAdviser" for given ActionOracle and action type
    /// @dev May be only called by the {OWNER}
    function removeRewardAdviser(address oracle, bytes4 action)
        external
        onlyOwner
    {
        _removeRewardAdviser(oracle, action);
    }

    /// @notice Withdraws accidentally sent token from this contract
    /// @dev May be only called by the {OWNER}
    function claimErc20(
        address claimedToken,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        if (claimedToken == address(REWARD_TOKEN)) {
            // Not allowed if unclaimed shares remain
            require(totalShares == 0, "RM: Failed to claim");
        }
        _claimErc20(claimedToken, to, amount);
    }

    /* ========== INTERNAL & PRIVATE FUNCTIONS ========== */

    function _computeRedemption(
        uint256 sharesToRedeem,
        UserRecord memory rec,
        uint256 _accumRewardPerShare
    )
        internal
        pure
        returns (
            uint256 reward,
            uint256 newShares,
            uint256 newOffset
        )
    {
        // `rec.shares` and `sharesToRedeem` are assumed to be non-zero here,
        // and `sharesToRedeem` does not exceed `rec.shares`
        newShares = uint256(rec.shares) - sharesToRedeem;

        uint256 offsetRedeemed = newShares == 0
            ? uint256(rec.offset)
            : (uint256(rec.offset) * sharesToRedeem) / uint256(rec.shares);
        newOffset = uint256(rec.offset) - offsetRedeemed;

        reward = 0;
        if (_accumRewardPerShare != 0) {
            reward = (sharesToRedeem * _accumRewardPerShare) / SCALE;
            // avoid eventual overflow resulted from rounding
            reward -= reward >= offsetRedeemed ? offsetRedeemed : reward;
        }
    }

    function _grantShares(address to, uint256 shares)
        internal
        nonZeroAmount(shares)
        nonZeroAddress(to)
    {
        (uint256 _accumRewardPerShare, , ) = _triggerVesting(true, true);

        UserRecord memory rec = records[to];
        uint256 newOffset = uint256(rec.offset) +
            (shares * _accumRewardPerShare) /
            SCALE;
        uint256 newShares = uint256(rec.shares) + shares;

        records[to] = UserRecord(safe96(newShares), safe160(newOffset));
        totalShares = safe128(uint256(totalShares) + shares);

        emit SharesGranted(to, shares);
    }

    function _redeemShares(
        address from,
        // `shares` assumed to be non-zero
        uint256 shares,
        address to
    ) internal nonZeroAmount(shares) nonZeroAddress(from) nonZeroAddress(to) {
        UserRecord memory rec = records[from];
        require(rec.shares >= shares, "RM: Not enough shares to redeem");

        (
            uint256 _accumRewardPerShare,
            uint256 newBalance,
            uint256 oldBalance
        ) = _triggerVesting(false, true);

        (
            uint256 reward,
            uint256 newShares,
            uint256 newOffset
        ) = _computeRedemption(shares, rec, _accumRewardPerShare);

        records[from] = UserRecord(safe96(newShares), safe160(newOffset));
        totalShares = safe128(uint256(totalShares) - shares);

        uint256 _lastBalance = newBalance - reward;
        if (oldBalance != _lastBalance) {
            lastBalance = safe96(_lastBalance);
        }

        if (reward != 0) {
            // known contract - nether reentrancy guard nor safeTransfer required
            require(
                IErc20Min(REWARD_TOKEN).transfer(to, reward),
                "RM: Internal transfer failed"
            );
            emit RewardPaid(to, reward);
        }

        emit SharesRedeemed(from, shares);
    }

    function _triggerVesting(
        bool isLastBalanceToBeUpdated,
        bool isMinVestingBlocksApplied
    )
        internal
        returns (
            uint256 newAccumRewardPerShare,
            uint256 newBalance,
            uint256 oldBalance
        )
    {
        uint32 _blockNow = safe32BlockNow();
        newAccumRewardPerShare = accumRewardPerShare;
        oldBalance = uint256(lastBalance);
        uint256 _totalShares = totalShares;

        uint32 blocksPast = _blockNow - lastVestedBlock;
        if (
            (blocksPast == 0) ||
            (isMinVestingBlocksApplied && blocksPast < MIN_VESTING_BLOCKS) ||
            _totalShares < MIN_SHARES_REWARDED
        ) {
            // Do not request vesting from the REWARD_POOL
            return (newAccumRewardPerShare, oldBalance, oldBalance);
        }

        // known contracts, no reentrancy guard needed
        uint256 newlyVested = IRewardPool(REWARD_POOL).vestRewards();
        newBalance = IErc20Min(REWARD_TOKEN).balanceOf(address(this));

        uint256 expectedBalance = oldBalance + newlyVested;
        if (newBalance > expectedBalance) {
            // somebody transferred tokens to this contract directly
            uint256 adjustment = newBalance - expectedBalance;
            newlyVested += adjustment;
            emit BalanceAdjusted(adjustment);
        }
        if (newlyVested != 0) {
            newAccumRewardPerShare += (newlyVested * SCALE) / _totalShares;
            accumRewardPerShare = newAccumRewardPerShare;
            emit RewardAdded(newlyVested);
        }
        lastVestedBlock = _blockNow;
        if (isLastBalanceToBeUpdated && (oldBalance != newBalance)) {
            lastBalance = safe96(newBalance);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, "RM: Zero amount provided");
        _;
    }

    modifier nonZeroAddress(address account) {
        require(account != address(0), "RM: Zero address provided");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "../interfaces/IRewardAdviser.sol";

/**
 * @title ActionControllers
 * @notice It maintains a list of "ActionOracle" and "RewardAdviser" instances.
 * For a tuple of ActionOracle address and action type, an RewardAdviser
 * instance of  may be mapped.
 */
abstract contract RewardAdvisersList {
    /// @dev Emitted when RewardAdviser added, updated, or removed
    event AdviserUpdated(
        address indexed oracle,
        bytes4 indexed action,
        address adviser
    );

    /// @dev mapping from ActionOracle and (type of) action to ActionController
    mapping(address => mapping(bytes4 => address)) public rewardAdvisers;

    function _addRewardAdviser(
        address oracle,
        bytes4 action,
        address adviser
    ) internal {
        require(
            oracle != address(0) &&
                adviser != address(0) &&
                action != bytes4(0),
            "ACM:E1"
        );
        require(rewardAdvisers[oracle][action] == address(0), "ACM:E2");
        rewardAdvisers[oracle][action] = adviser;
        emit AdviserUpdated(oracle, action, adviser);
    }

    function _removeRewardAdviser(address oracle, bytes4 action) internal {
        require(rewardAdvisers[oracle][action] != address(0), "ACM:E3");
        rewardAdvisers[oracle][action] = address(0);
        emit AdviserUpdated(oracle, action, address(0));
    }

    function _getRewardAdviserOrRevert(address oracle, bytes4 action)
        internal
        view
        returns (IRewardAdviser)
    {
        address adviser = rewardAdvisers[oracle][action];
        require(adviser != address(0), "ACM:E4");
        return IRewardAdviser(adviser);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IActionMsgReceiver {
    function onAction(bytes4 action, bytes memory message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IErc20Min {
    /// @dev ERC-20 `balanceOf`
    function balanceOf(address account) external view returns (uint256);

    /// @dev ERC-20 `transfer`
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /// @dev ERC-20 `transferFrom`
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @dev EIP-2612 `permit`
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardAdviser {
    struct Advice {
        // advice on new "shares" (in the reward pool) to create
        address createSharesFor;
        uint96 sharesToCreate;
        // advice on "shares" to redeem
        address redeemSharesFrom;
        uint96 sharesToRedeem;
        // advice on address the reward against redeemed shares to send to
        address sendRewardTo;
    }

    function getRewardAdvice(bytes4 action, bytes memory message)
        external
        returns (Advice memory);
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.0;

interface IRewardPool {
    /// @notice Returns token amount that may be released (vested) now
    function releasableAmount() external view returns (uint256);

    /// @notice Vests releasable token amount to the {recipient}
    /// @dev {recipient} only may call
    function vestRewards() external returns (uint256 amount);

    /// @notice Emitted on vesting to the {recipient}
    event Vested(uint256 amount);

    /// @notice Emitted on parameters initialized.
    event Initialized(uint256 _poolId, address _recipient, uint256 _endTime);
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

/// @title Staking
abstract contract ImmutableOwnable {
    /// @notice The owner who has privileged rights
    // solhint-disable-next-line var-name-mixedcase
    address public immutable OWNER;

    /// @dev Throws if called by any account other than the {OWNER}.
    modifier onlyOwner() {
        require(OWNER == msg.sender, "ImmOwn: unauthorized");
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "ImmOwn: zero owner address");
        OWNER = _owner;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

/**
 * @title Claimable
 * @notice It withdraws accidentally sent tokens from this contract.
 */
contract Claimable {
    bytes4 private constant SELECTOR_TRANSFER =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    /// @dev Withdraws ERC20 tokens from this contract
    /// (take care of reentrancy attack risk mitigation)
    function _claimErc20(
        address token,
        address to,
        uint256 amount
    ) internal {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR_TRANSFER, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "claimErc20: TRANSFER_FAILED"
        );
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

/**
 * @title NonReentrant
 * @notice It provides reentrancy guard.
 * The code borrowed from openzeppelin-contracts.
 * Unlike original, this version requires neither `constructor` no `init` call.
 */
abstract contract NonReentrant {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _reentrancyStatus;

    modifier nonReentrant() {
        // Being called right after deployment, when _reentrancyStatus is 0 ,
        // it does not revert (which is expected behaviour)
        require(_reentrancyStatus != _ENTERED, "claimErc20: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

abstract contract Utils {
    function safe32(uint256 n) internal pure returns (uint32) {
        require(n < 2**32, "UNSAFE32");
        return uint32(n);
    }

    function safe96(uint256 n) internal pure returns (uint96) {
        require(n < 2**96, "UNSAFE96");
        return uint96(n);
    }

    function safe128(uint256 n) internal pure returns (uint128) {
        require(n < 2**128, "UNSAFE128");
        return uint128(n);
    }

    function safe160(uint256 n) internal pure returns (uint160) {
        require(n < 2**160, "UNSAFE160");
        return uint160(n);
    }

    function safe32TimeNow() internal view returns (uint32) {
        return safe32(timeNow());
    }

    function safe32BlockNow() internal view returns (uint32) {
        return safe32(blockNow());
    }

    /// @dev Returns the current block timestamp (added to ease testing)
    function timeNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @dev Returns the current block number (added to ease testing)
    function blockNow() internal view virtual returns (uint256) {
        return block.number;
    }
}