/**
 *Submitted for verification at polygonscan.com on 2021-11-03
*/

pragma solidity ^0.8.4;

contract MockWithdrawalScheduler {
    bool private scheduled;
    function scheduleWithdrawal(address _poolAddress) external returns(bool) {
        scheduled = true;
        return scheduled;
    }

    function unscheduleWithdrawal(address _poolAddress) external returns(bool) {
        scheduled = false;
        return scheduled;
    }

    function isScheduled() external view returns(bool) {
        return scheduled;
    }
}