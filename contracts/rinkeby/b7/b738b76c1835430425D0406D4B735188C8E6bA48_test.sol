// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface ILiquidityRegistry {
    struct LiquidityInfo {
        address policyBookAddr;
        uint256 lockedAmount;
        uint256 availableAmount;
        uint256 bmiXRatio; // multiply availableAmount by this num to get stable coin
    }

    struct WithdrawalRequestInfo {
        address policyBookAddr;
        uint256 requestAmount;
        uint256 requestSTBLAmount;
        uint256 availableLiquidity;
        uint256 readyToWithdrawDate;
        uint256 endWithdrawDate;
    }

    struct WithdrawalSetInfo {
        address policyBookAddr;
        uint256 requestAmount;
        uint256 requestSTBLAmount;
        uint256 availableSTBLAmount;
    }

    function withdrawlListCounter() external view returns (uint256);

    /// @notice finds the next withdrawal index after a given timestamp
    /// @param _time uint256 lookup timesamp
    /// @return _index of the withdrawal matching the lookup
    function findWithdrawlAfterTime(uint256 _time) external view returns (uint256);

    /// @notice sets the withdrawlListCounter to a specific item
    /// @param _index uint256 new withdrawlListCounter value;
    function adjustWithdrawlListCounter(uint256 _index) external;

    function tryToAddPolicyBook(address _userAddr, address _policyBookAddr) external;

    function tryToRemovePolicyBook(address _userAddr, address _policyBookAddr) external;

    function getPolicyBooksArrLength(address _userAddr) external view returns (uint256);

    function getPolicyBooksArr(address _userAddr)
        external
        view
        returns (address[] memory _resultArr);

    function getLiquidityInfos(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    ) external view returns (LiquidityInfo[] memory _resultArr);

    function getWithdrawalRequests(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    ) external view returns (uint256 _arrLength, WithdrawalRequestInfo[] memory _resultArr);

    function getWithdrawalSet(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    ) external view returns (uint256 _arrLength, WithdrawalSetInfo[] memory _resultArr);

    function registerWithdrawl(address _policyBook, address _users) external;

    function getWithdrawalRequestsInWindowTime(
        uint256 startCount,
        uint256 _startTime,
        uint256 _endTime
    )
        external
        view
        returns (
            address[] memory _pbooks,
            address[] memory _users,
            uint256 _acumulatedAmount,
            uint256 _count,
            uint256 _start
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./interfaces/ILiquidityRegistry.sol";

contract test {
    event Results(uint256 index, uint256 startTime, uint256 endTime, uint256 acum, uint256 count);

    function runTest(
        address _contractAddress, uint256 _index, uint256 _startTime, uint256 _endTime
    )  public returns (
            address[] memory _pbooks,
            address[] memory _users,
            uint256 _acumulatedAmount,
            uint256 _count,
            uint256 _start
        )

        {

            (_pbooks, _users, _acumulatedAmount, _count, _start) =
                ILiquidityRegistry(_contractAddress).getWithdrawalRequestsInWindowTime(
                _index,
               _startTime,
               _endTime
            );

            emit Results(_index, _startTime, _endTime, _acumulatedAmount, _count);

        }

}