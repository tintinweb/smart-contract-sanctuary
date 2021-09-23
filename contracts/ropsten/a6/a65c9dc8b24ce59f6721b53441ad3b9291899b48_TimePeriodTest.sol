/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

pragma solidity 0.8.6;


contract TimePeriodTest {

    uint constant WEEK = 86400 * 7;
    uint constant PRECISION = 10**18;
    mapping(address => mapping(address => uint)) public active_period;

function _update_period(address gauge, address reward_token) public returns (uint) {
        uint _period = active_period[gauge][reward_token];
        if (block.timestamp >= _period + WEEK) {
            _period = block.timestamp / WEEK * WEEK;
            active_period[gauge][reward_token] = _period;
        }
        return _period;
    }
    
function _math_test_1() external view returns (uint) {
        uint _test = block.timestamp / WEEK * WEEK;
        return _test;
    }
    
function _math_test_2() external view returns (uint) {
        uint _test = (block.timestamp / WEEK) * WEEK;
        return _test;
    }
    
function _math_test_3() external view returns (uint) {
        uint _test = block.timestamp / 7 * 7;
        return _test;
    }
}