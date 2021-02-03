pragma solidity 0.5.17;

import {IStakerRewards, StakerRewardsBeneficiary} from "../PhasedEscrow.sol";

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

/// @title KeepTokenGeyserRewardsEscrowBeneficiary
/// @notice Intermediate contract used to transfer tokens from PhasedEscrow to a
/// designated KeepTokenGeyser contract.
contract KeepTokenGeyserRewardsEscrowBeneficiary is StakerRewardsBeneficiary {
    constructor(IERC20 _token, IStakerRewards _stakerRewards)
        public
        StakerRewardsBeneficiary(_token, _stakerRewards)
    {}
}