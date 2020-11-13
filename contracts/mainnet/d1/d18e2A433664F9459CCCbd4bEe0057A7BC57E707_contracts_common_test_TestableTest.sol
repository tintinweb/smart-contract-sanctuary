pragma solidity ^0.6.0;

import "../implementation/Testable.sol";


// TestableTest is derived from the abstract contract Testable for testing purposes.
contract TestableTest is Testable {
    // solhint-disable-next-line no-empty-blocks
    constructor(address _timerAddress) public Testable(_timerAddress) {}

    function getTestableTimeAndBlockTime() external view returns (uint256 testableTime, uint256 blockTime) {
        // solhint-disable-next-line not-rely-on-time
        return (getCurrentTime(), now);
    }
}
