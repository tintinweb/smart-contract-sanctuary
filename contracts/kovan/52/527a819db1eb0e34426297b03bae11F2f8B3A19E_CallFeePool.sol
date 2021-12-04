// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFeePool {
    function feesAvailable(address account)
        external
        view
        returns (uint256, uint256);

    function isFeesClaimable(address account) external view returns (bool);

    function recentFeePeriods(uint256 index)
        external
        view
        returns (
            uint64 feePeriodId,
            uint64 startingDebtIndex,
            uint64 startTime,
            uint256 feesToDistribute,
            uint256 feesClaimed,
            uint256 rewardsToDistribute,
            uint256 rewardsClaimed
        );

    // Mutative Functions

    function claimOnBehalf(address claimingForAddress) external returns (bool);
}

contract CallFeePool {
    address public constant FEE_POOL =
        address(0xc43b833F93C3896472dED3EfF73311f571e38742);

    function isFeesClaimable(address _addr)
        external
        view
        returns (bool claimable)
    {
        claimable = IFeePool(FEE_POOL).isFeesClaimable(_addr);
    }
}