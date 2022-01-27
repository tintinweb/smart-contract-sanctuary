// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "./actions/StakingMsgProcessor.sol";
import "./interfaces/IActionMsgReceiver.sol";
import "./interfaces/IErc20Min.sol";
import "./interfaces/IStakingTypes.sol";
import "./interfaces/IVotingPower.sol";
import "./utils/ImmutableOwnable.sol";
import "./utils/Utils.sol";

/**
 * @title Staking
 * @notice It lets users stake $ZKP token for governance voting and rewards.
 * @dev At request of smart contracts and off-chain requesters, it computes
 * user "voting power" on the basis of tokens users stake.
 * It acts as the "ActionOracle" for the "RewardMaster": if stake terms presume
 * rewarding, it sends "messages" on stakes made and stakes claimed to the
 * "RewardMaster" contract which rewards stakers.
 * It supports multiple types of stakes (terms), which the owner may add or
 * remove without contract code upgrades.
 */
contract Staking is
    ImmutableOwnable,
    Utils,
    StakingMsgProcessor,
    IStakingTypes,
    IVotingPower
{
    // solhint-disable var-name-mixedcase
    /// @notice Staking token
    IErc20Min public immutable TOKEN;

    /// @dev Block the contract deployed in
    uint256 public immutable START_BLOCK;

    /// @notice RewardMaster contract instance
    IActionMsgReceiver public immutable REWARD_MASTER;

    // solhint-enable var-name-mixedcase

    // Scale for min/max limits
    uint256 private constant SCALE = 1e18;

    /// @notice Total token amount staked
    /// @dev Staking token is deemed to have max total supply of 1e27
    uint96 public totalStaked = 0;

    /// @dev Mapping from stake type to terms
    mapping(bytes4 => Terms) public terms;

    /// @dev Mapping from the staker address to stakes of the staker
    mapping(address => Stake[]) public stakes;

    // Special address to store global state
    address private constant GLOBAL_ACCOUNT = address(0);

    /// @dev Voting power integrants for each account
    // special case: GLOBAL_ACCOUNT for total voting power
    mapping(address => Power) public power;

    /// @dev Snapshots of each account
    // special case: GLOBAL_ACCOUNT for global snapshots
    mapping(address => Snapshot[]) private snapshots;

    /// @dev Emitted on a new stake made
    event StakeCreated(
        address indexed account,
        uint256 indexed stakeID,
        uint256 amount,
        bytes4 stakeType,
        uint256 lockedTill
    );

    /// @dev Emitted on a stake claimed (i.e. "unstaked")
    event StakeClaimed(address indexed account, uint256 indexed stakeID);

    /// @dev Voting power delegated
    event Delegation(
        address indexed owner,
        address indexed from,
        address indexed to,
        uint256 stakeID,
        uint256 amount
    );

    /// @dev New terms (for the given stake type) added
    event TermsAdded(bytes4 stakeType);

    /// @dev Terms (for the given stake type) are disabled
    event TermsDisabled(bytes4 stakeType);

    /// @dev Call to REWARD_MASTER reverted
    event RewardMasterRevert(address staker, uint256 stakeID);

    /**
     * @notice Sets staking token, owner and
     * @param stakingToken - Address of the {ZKPToken} contract
     * @param rewardMaster - Address of the {RewardMaster} contract
     * @param owner - Address of the owner account
     */
    constructor(
        address stakingToken,
        address rewardMaster,
        address owner
    ) ImmutableOwnable(owner) {
        require(
            stakingToken != address(0) && rewardMaster != address(0),
            "Staking:C1"
        );
        TOKEN = IErc20Min(stakingToken);
        REWARD_MASTER = IActionMsgReceiver(rewardMaster);
        START_BLOCK = blockNow();
    }

    /**
     * @notice Stakes tokens
     * @dev This contract should be approve()'d for amount
     * @param amount - Amount to stake
     * @param stakeType - Type of the stake
     * @param data - Arbitrary data for "RewardMaster" (zero, if inapplicable)
     * @return stake ID
     */
    function stake(
        uint256 amount,
        bytes4 stakeType,
        bytes calldata data
    ) public returns (uint256) {
        return _createStake(msg.sender, amount, stakeType, data);
    }

    /**
     * @notice Approves this contract to transfer `amount` tokens from the `msg.sender`
     * and stakes these tokens. Only the owner of tokens (i.e. the staker) may call.
     * @dev This contract does not need to be approve()'d in advance - see EIP-2612
     * @param owner - The owner of tokens being staked (i.e. the `msg.sender`)
     * @param amount - Amount to stake
     * @param v - "v" param of the signature from `owner` for "permit"
     * @param r - "r" param of the signature from `owner` for "permit"
     * @param s - "s" param of the signature from `owner` for "permit"
     * @param stakeType - Type of the stake
     * @param data - Arbitrary data for "RewardMaster" (zero, if inapplicable)
     * @return stake ID
     */
    function permitAndStake(
        address owner,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes4 stakeType,
        bytes calldata data
    ) external returns (uint256) {
        require(owner == msg.sender, "Staking: owner must be msg.sender");
        TOKEN.permit(owner, address(this), amount, deadline, v, r, s);
        return _createStake(owner, amount, stakeType, data);
    }

    /**
     * @notice Claims staked token
     * @param stakeID - ID of the stake to claim
     * @param data - Arbitrary data for "RewardMaster" (zero, if inapplicable)
     * @param _isForced - Do not revert if "RewardMaster" fails
     */
    function unstake(
        uint256 stakeID,
        bytes calldata data,
        bool _isForced
    ) external stakeExist(msg.sender, stakeID) {
        Stake memory _stake = stakes[msg.sender][stakeID];

        require(_stake.claimedAt == 0, "Staking: Stake claimed");
        require(_stake.lockedTill < safe32TimeNow(), "Staking: Stake locked");

        if (_stake.delegatee != address(0)) {
            _undelegatePower(_stake.delegatee, msg.sender, _stake.amount);
        }
        _removePower(msg.sender, _stake.amount);

        stakes[msg.sender][stakeID].claimedAt = safe32TimeNow();

        totalStaked = safe96(uint256(totalStaked) - uint256(_stake.amount));

        emit StakeClaimed(msg.sender, stakeID);

        // known contract - reentrancy guard and `safeTransfer` unneeded
        require(
            TOKEN.transfer(msg.sender, _stake.amount),
            "Staking: transfer failed"
        );

        Terms memory _terms = terms[_stake.stakeType];
        if (_terms.isRewarded) {
            _sendUnstakedMsg(msg.sender, _stake, data, _isForced);
        }
    }

    /**
     * @notice Updates vote delegation
     * @param stakeID - ID of the stake to delegate votes uber
     * @param to - address to delegate to
     */
    function delegate(uint256 stakeID, address to)
        public
        stakeExist(msg.sender, stakeID)
    {
        require(
            to != GLOBAL_ACCOUNT,
            "Staking: Can't delegate to GLOBAL_ACCOUNT"
        );

        Stake memory s = stakes[msg.sender][stakeID];
        require(s.claimedAt == 0, "Staking: Stake claimed");
        require(s.delegatee != to, "Staking: Already delegated");

        if (s.delegatee == address(0)) {
            _delegatePower(msg.sender, to, s.amount);
        } else {
            if (to == msg.sender) {
                _undelegatePower(s.delegatee, msg.sender, s.amount);
            } else {
                _reDelegatePower(s.delegatee, to, s.amount);
            }
        }

        emit Delegation(msg.sender, s.delegatee, to, stakeID, s.amount);

        stakes[msg.sender][stakeID].delegatee = to;
    }

    /**
     * @notice Delegates voting power of stake back to self
     * @param stakeID - ID of the stake to delegate votes back to self
     */
    function undelegate(uint256 stakeID) external {
        delegate(stakeID, msg.sender);
    }

    /// @notice Returns number of stakes of given _account
    function stakesNum(address _account) external view returns (uint256) {
        return stakes[_account].length;
    }

    /// @notice Returns stakes of given account
    function accountStakes(address _account)
        external
        view
        returns (Stake[] memory)
    {
        Stake[] memory _stakes = stakes[_account];
        return _stakes;
    }

    /// @inheritdoc IVotingPower
    function totalVotingPower() external view override returns (uint256) {
        Power memory _power = power[GLOBAL_ACCOUNT];
        return _power.own + _power.delegated;
    }

    /// @inheritdoc IVotingPower
    function totalPower() external view override returns (Power memory) {
        return power[GLOBAL_ACCOUNT];
    }

    /// @inheritdoc IVotingPower
    function latestGlobalsSnapshotBlock()
        public
        view
        override
        returns (uint256)
    {
        return latestSnapshotBlock(GLOBAL_ACCOUNT);
    }

    /// @inheritdoc IVotingPower
    function latestSnapshotBlock(address _account)
        public
        view
        override
        returns (uint256)
    {
        if (snapshots[_account].length == 0) return 0;

        return snapshots[_account][snapshots[_account].length - 1].beforeBlock;
    }

    /// @inheritdoc IVotingPower
    function globalsSnapshotLength() external view override returns (uint256) {
        return snapshots[GLOBAL_ACCOUNT].length;
    }

    /// @inheritdoc IVotingPower
    function snapshotLength(address _account)
        external
        view
        override
        returns (uint256)
    {
        return snapshots[_account].length;
    }

    /// @inheritdoc IVotingPower
    function globalsSnapshot(uint256 _index)
        external
        view
        override
        returns (Snapshot memory)
    {
        return snapshots[GLOBAL_ACCOUNT][_index];
    }

    /// @inheritdoc IVotingPower
    function snapshot(address _account, uint256 _index)
        external
        view
        override
        returns (Snapshot memory)
    {
        return snapshots[_account][_index];
    }

    /// @inheritdoc IVotingPower
    function globalSnapshotAt(uint256 blockNum, uint256 hint)
        external
        view
        override
        returns (Snapshot memory)
    {
        return _snapshotAt(GLOBAL_ACCOUNT, blockNum, hint);
    }

    /// @inheritdoc IVotingPower
    function snapshotAt(
        address _account,
        uint256 blockNum,
        uint256 hint
    ) external view override returns (Snapshot memory) {
        return _snapshotAt(_account, blockNum, hint);
    }

    /// Only for the owner functions

    /// @notice Adds a new stake type with given terms
    /// @dev May be only called by the {OWNER}
    function addTerms(bytes4 stakeType, Terms memory _terms)
        external
        onlyOwner
        nonZeroStakeType(stakeType)
    {
        Terms memory existingTerms = terms[stakeType];
        require(!_isDefinedTerms(existingTerms), "Staking:E1");
        require(_terms.isEnabled, "Staking:E2");

        uint256 _now = timeNow();

        if (_terms.allowedTill != 0) {
            require(_terms.allowedTill > _now, "Staking:E3");
            require(_terms.allowedTill > _terms.allowedSince, "Staking:E4");
        }

        if (_terms.maxAmountScaled != 0) {
            require(
                _terms.maxAmountScaled > _terms.minAmountScaled,
                "Staking:E5"
            );
        }

        // only one of three "lock time" parameters must be non-zero
        if (_terms.lockedTill != 0) {
            require(
                _terms.exactLockPeriod == 0 && _terms.minLockPeriod == 0,
                "Staking:E6"
            );
            require(
                _terms.lockedTill > _now &&
                    _terms.lockedTill >= _terms.allowedTill,
                "Staking:E7"
            );
        } else {
            require(
                // one of two params must be non-zero
                (_terms.exactLockPeriod == 0) != (_terms.minLockPeriod == 0),
                "Staking:E8"
            );
        }

        terms[stakeType] = _terms;
        emit TermsAdded(stakeType);
    }

    function disableTerms(bytes4 stakeType)
        external
        onlyOwner
        nonZeroStakeType(stakeType)
    {
        Terms memory _terms = terms[stakeType];
        require(_isDefinedTerms(terms[stakeType]), "Staking:E9");
        require(_terms.isEnabled, "Staking:EA");

        terms[stakeType].isEnabled = false;
        emit TermsDisabled(stakeType);
    }

    /// Internal and private functions follow

    function _createStake(
        address staker,
        uint256 amount,
        bytes4 stakeType,
        bytes calldata data
    ) internal nonZeroStakeType(stakeType) returns (uint256) {
        Terms memory _terms = terms[stakeType];
        require(_terms.isEnabled, "Staking: Terms unknown or disabled");

        require(amount > 0, "Staking: Amount not set");
        uint256 _totalStake = amount + uint256(totalStaked);
        require(_totalStake < 2**96, "Staking: Too big amount");

        require(
            _terms.minAmountScaled == 0 ||
                amount >= SCALE * _terms.minAmountScaled,
            "Staking: Too small amount"
        );
        require(
            _terms.maxAmountScaled == 0 ||
                amount <= SCALE * _terms.maxAmountScaled,
            "Staking: Too large amount"
        );

        uint32 _now = safe32TimeNow();
        require(
            _terms.allowedSince == 0 || _now >= _terms.allowedSince,
            "Staking: Not yet allowed"
        );
        require(
            _terms.allowedTill == 0 || _terms.allowedTill > _now,
            "Staking: Not allowed anymore"
        );

        // known contract - reentrancy guard and `safeTransferFrom` unneeded
        require(
            TOKEN.transferFrom(staker, address(this), amount),
            "Staking: transferFrom failed"
        );

        uint256 stakeID = stakes[staker].length;

        uint32 lockedTill = _terms.lockedTill;
        if (lockedTill == 0) {
            uint256 period = _terms.exactLockPeriod == 0
                ? _terms.minLockPeriod
                : _terms.exactLockPeriod;
            lockedTill = safe32(period + _now);
        }

        Stake memory _stake = Stake(
            uint32(stakeID), // overflow risk ignored
            stakeType,
            _now, // stakedAt
            lockedTill,
            0, // claimedAt
            uint96(amount),
            address(0) // no delegatee
        );
        stakes[staker].push(_stake);

        totalStaked = uint96(_totalStake);
        _addPower(staker, amount);

        emit StakeCreated(staker, stakeID, amount, stakeType, lockedTill);

        if (_terms.isRewarded) {
            _sendStakedMsg(staker, _stake, data);
        }
        return stakeID;
    }

    function _addPower(address to, uint256 amount) private {
        _takeSnapshot(GLOBAL_ACCOUNT);
        _takeSnapshot(to);
        power[GLOBAL_ACCOUNT].own += uint96(amount);
        power[to].own += uint96(amount);
    }

    function _removePower(address from, uint256 amount) private {
        _takeSnapshot(GLOBAL_ACCOUNT);
        _takeSnapshot(from);
        power[GLOBAL_ACCOUNT].own -= uint96(amount);
        power[from].own -= uint96(amount);
    }

    function _delegatePower(
        address from,
        address to,
        uint256 amount
    ) private {
        _takeSnapshot(GLOBAL_ACCOUNT);
        _takeSnapshot(to);
        _takeSnapshot(from);
        power[GLOBAL_ACCOUNT].own -= uint96(amount);
        power[from].own -= uint96(amount);
        power[GLOBAL_ACCOUNT].delegated += uint96(amount);
        power[to].delegated += uint96(amount);
    }

    function _reDelegatePower(
        address from,
        address to,
        uint256 amount
    ) private {
        _takeSnapshot(to);
        _takeSnapshot(from);
        power[from].delegated -= uint96(amount);
        power[to].delegated += uint96(amount);
    }

    function _undelegatePower(
        address from,
        address to,
        uint256 amount
    ) private {
        power[GLOBAL_ACCOUNT].delegated -= uint96(amount);
        power[from].delegated -= uint96(amount);
        power[GLOBAL_ACCOUNT].own += uint96(amount);
        power[to].own += uint96(amount);
    }

    function _takeSnapshot(address _account) internal {
        uint32 curBlockNum = safe32BlockNow();
        if (latestSnapshotBlock(_account) < curBlockNum) {
            // make new snapshot as the latest one taken before current block
            snapshots[_account].push(
                Snapshot(
                    curBlockNum,
                    power[_account].own,
                    power[_account].delegated
                )
            );
        }
    }

    function _snapshotAt(
        address _account,
        uint256 blockNum,
        uint256 hint
    ) internal view returns (Snapshot memory) {
        _sanitizeBlockNum(blockNum);

        Snapshot[] storage snapshotsInfo = snapshots[_account];

        if (
            // hint is correct?
            hint <= snapshotsInfo.length &&
            (hint == 0 || snapshotsInfo[hint - 1].beforeBlock < blockNum) &&
            (hint == snapshotsInfo.length ||
                snapshotsInfo[hint].beforeBlock >= blockNum)
        ) {
            // yes, return the hinted snapshot
            if (hint < snapshotsInfo.length) {
                return snapshotsInfo[hint];
            } else {
                return
                    Snapshot(
                        uint32(blockNum),
                        power[_account].own,
                        power[_account].delegated
                    );
            }
        }
        // no, fall back to binary search
        else return _snapshotAt(_account, blockNum);
    }

    function _snapshotAt(address _account, uint256 blockNum)
        internal
        view
        returns (Snapshot memory)
    {
        _sanitizeBlockNum(blockNum);

        // https://en.wikipedia.org/wiki/Binary_search_algorithm
        Snapshot[] storage snapshotsInfo = snapshots[_account];
        uint256 index;
        uint256 low = 0;
        uint256 high = snapshotsInfo.length;

        while (low < high) {
            uint256 mid = (low + high) / 2;

            if (snapshotsInfo[mid].beforeBlock > blockNum) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // `low` is the exclusive upper bound. Find the inclusive upper bounds and set to index
        if (low > 0 && snapshotsInfo[low - 1].beforeBlock == blockNum) {
            return snapshotsInfo[low - 1];
        } else {
            index = low;
        }

        // If index is equal to snapshot array length, then no update made after the requested blockNum.
        // This means the latest value is the right one.
        if (index == snapshotsInfo.length) {
            return
                Snapshot(
                    uint32(blockNum),
                    uint96(power[_account].own),
                    uint96(power[_account].delegated)
                );
        } else {
            return snapshotsInfo[index];
        }
    }

    function _sanitizeBlockNum(uint256 blockNum) private view {
        require(blockNum <= safe32BlockNow(), "Staking: Too big block number");
    }

    function _isDefinedTerms(Terms memory _terms) internal pure returns (bool) {
        return
            (_terms.minLockPeriod != 0) ||
            (_terms.exactLockPeriod != 0) ||
            (_terms.lockedTill != 0);
    }

    function _sendStakedMsg(
        address staker,
        Stake memory _stake,
        bytes calldata data
    ) internal {
        bytes4 action = _encodeStakeActionType(_stake.stakeType);
        bytes memory message = _packStakingActionMsg(staker, _stake, data);
        // known contract - reentrancy guard unneeded
        // solhint-disable-next-line no-empty-blocks
        try REWARD_MASTER.onAction(action, message) {} catch {
            revert("Staking: onStake msg failed");
        }
    }

    function _sendUnstakedMsg(
        address staker,
        Stake memory _stake,
        bytes calldata data,
        bool _isForced
    ) internal {
        bytes4 action = _encodeUnstakeActionType(_stake.stakeType);
        bytes memory message = _packStakingActionMsg(staker, _stake, data);
        // known contract - reentrancy guard unneeded
        // solhint-disable-next-line no-empty-blocks
        try REWARD_MASTER.onAction(action, message) {} catch {
            emit RewardMasterRevert(staker, _stake.id);
            // REWARD_MASTER must be unable to revert forced calls
            require(_isForced, "Staking: REWARD_MASTER reverts");
        }
    }

    modifier stakeExist(address staker, uint256 stakeID) {
        require(
            stakes[staker].length > stakeID,
            "Staking: Stake doesn't exist"
        );
        _;
    }

    modifier nonZeroStakeType(bytes4 stakeType) {
        require(stakeType != bytes4(0), "Staking: Invalid stake type 0");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "../interfaces/IStakingTypes.sol";

abstract contract StakingMsgProcessor {
    bytes4 internal constant STAKE_ACTION = bytes4(keccak256("stake"));
    bytes4 internal constant UNSTAKE_ACTION = bytes4(keccak256("unstake"));

    function _encodeStakeActionType(bytes4 stakeType)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(STAKE_ACTION, stakeType)));
    }

    function _encodeUnstakeActionType(bytes4 stakeType)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(UNSTAKE_ACTION, stakeType)));
    }

    function _packStakingActionMsg(
        address staker,
        IStakingTypes.Stake memory stake,
        bytes calldata data
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                staker, // address
                stake.amount, // uint96
                stake.id, // uint32
                stake.stakedAt, // uint32
                stake.lockedTill, // uint32
                stake.claimedAt, // uint32
                data // bytes
            );
    }

    // For efficiency we use "packed" (rather than "ABI") encoding.
    // It results in shorter data, but requires custom unpack function.
    function _unpackStakingActionMsg(bytes memory message)
        internal
        pure
        returns (
            address staker,
            uint96 amount,
            uint32 id,
            uint32 stakedAt,
            uint32 lockedTill,
            uint32 claimedAt,
            bytes memory data
        )
    {
        // staker, amount, id and 3 timestamps occupy exactly 48 bytes
        // (`data` may be of zero length)
        require(message.length >= 48, "SMP: unexpected msg length");

        uint256 stakerAndAmount;
        uint256 idAndStamps;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // the 1st word (32 bytes) contains the `message.length`
            // we need the (entire) 2nd word ..
            stakerAndAmount := mload(add(message, 0x20))
            // .. and (16 bytes of) the 3rd word
            idAndStamps := mload(add(message, 0x40))
        }

        staker = address(uint160(stakerAndAmount >> 96));
        amount = uint96(stakerAndAmount & 0xFFFFFFFFFFFFFFFFFFFFFFFF);

        id = uint32((idAndStamps >> 224) & 0xFFFFFFFF);
        stakedAt = uint32((idAndStamps >> 192) & 0xFFFFFFFF);
        lockedTill = uint32((idAndStamps >> 160) & 0xFFFFFFFF);
        claimedAt = uint32((idAndStamps >> 128) & 0xFFFFFFFF);

        uint256 dataLength = message.length - 48;
        data = new bytes(dataLength);
        for (uint256 i = 0; i < dataLength; i++) {
            data[i] = message[i + 48];
        }
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
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

interface IStakingTypes {
    // Stake type terms
    struct Terms {
        // if stakes of this kind allowed
        bool isEnabled;
        // if messages on stakes to be sent to the {RewardMaster}
        bool isRewarded;
        // limit on the minimum amount staked, no limit if zero
        uint32 minAmountScaled;
        // limit on the maximum amount staked, no limit if zero
        uint32 maxAmountScaled;
        // Stakes not accepted before this time, has no effect if zero
        uint32 allowedSince;
        // Stakes not accepted after this time, has no effect if zero
        uint32 allowedTill;
        // One (at least) of the following three params must be non-zero
        // if non-zero, overrides both `exactLockPeriod` and `minLockPeriod`
        uint32 lockedTill;
        // ignored if non-zero `lockedTill` defined, overrides `minLockPeriod`
        uint32 exactLockPeriod;
        // has effect only if both `lockedTill` and `exactLockPeriod` are zero
        uint32 minLockPeriod;
    }

    struct Stake {
        // index in the `Stake[]` array of `stakes`
        uint32 id;
        // defines Terms
        bytes4 stakeType;
        // time this stake was created at
        uint32 stakedAt;
        // time this stake can be claimed at
        uint32 lockedTill;
        // time this stake was claimed at (unclaimed if 0)
        uint32 claimedAt;
        // amount of tokens on this stake (assumed to be less 1e27)
        uint96 amount;
        // address stake voting power is delegated to
        address delegatee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IStaking
interface IVotingPower {
    struct Snapshot {
        uint32 beforeBlock;
        uint96 ownPower;
        uint96 delegatedPower;
    }

    /// @dev Voting power integrants
    struct Power {
        uint96 own; // voting power that remains after delegating to others
        uint96 delegated; // voting power delegated by others
    }

    /// @notice Returns total voting power staked
    /// @dev "own" and "delegated" voting power summed up
    function totalVotingPower() external view returns (uint256);

    /// @notice Returns total "own" and total "delegated" voting power separately
    /// @dev Useful, if "own" and "delegated" voting power treated differently
    function totalPower() external view returns (Power memory);

    /// @notice Returns global snapshot for given block
    /// @param blockNum - block number to get state at
    /// @param hint - off-chain computed index of the required snapshot
    function globalSnapshotAt(uint256 blockNum, uint256 hint)
        external
        view
        returns (Snapshot memory);

    /// @notice Returns snapshot on given block for given account
    /// @param _account - account to get snapshot for
    /// @param blockNum - block number to get state at
    /// @param hint - off-chain computed index of the required snapshot
    function snapshotAt(
        address _account,
        uint256 blockNum,
        uint256 hint
    ) external view returns (Snapshot memory);

    /// @dev Returns block number of the latest global snapshot
    function latestGlobalsSnapshotBlock() external view returns (uint256);

    /// @dev Returns block number of the given account latest snapshot
    function latestSnapshotBlock(address _account)
        external
        view
        returns (uint256);

    /// @dev Returns number of global snapshots
    function globalsSnapshotLength() external view returns (uint256);

    /// @dev Returns number of snapshots for given account
    function snapshotLength(address _account) external view returns (uint256);

    /// @dev Returns global snapshot at given index
    function globalsSnapshot(uint256 _index)
        external
        view
        returns (Snapshot memory);

    /// @dev Returns snapshot at given index for given account
    function snapshot(address _account, uint256 _index)
        external
        view
        returns (Snapshot memory);
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