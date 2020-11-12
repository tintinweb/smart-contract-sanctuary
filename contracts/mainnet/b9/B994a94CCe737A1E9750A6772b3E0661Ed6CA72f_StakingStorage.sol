pragma solidity ^0.5.0;

/// @title Staking Storage Contract
/// @author growlot (@growlot)
contract StakingStorage {
    struct Checkpoint {
        uint256 blockNumberOrCheckpointIndex;
        uint256 stakedAmount;
    }

    /// @notice Initialized flag - indicates that initialization was made once
    bool internal _initialized;

    address public _guardian;
    address public _authorizedNewGuardian;

    address public _sxpTokenAddress;

    uint256 public _minimumStakeAmount;
    mapping (address => mapping (uint256 => Checkpoint)) internal _stakedMap;
    uint256 public _totalStaked;

    uint256 public _prevRewardCycle;
    uint256 public _prevRewardAmount;
    uint256 public _prevRewardCycleTimestamp;
    uint256 public _rewardCycle;
    uint256 public _rewardAmount;
    uint256 public _rewardCycleTimestamp;
    uint256 public _rewardPoolAmount;
    address public _rewardProvider;

    uint256 public _claimNonce;
    mapping (address => mapping (uint256 => uint256)) public _approvedClaimMap;
}
