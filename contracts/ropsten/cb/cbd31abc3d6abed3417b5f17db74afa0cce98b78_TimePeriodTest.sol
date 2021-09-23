/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

pragma solidity 0.8.6;


contract TimePeriodTest {

    uint constant WEEK = 86400 * 7;
    uint constant PRECISION = 10**18;
    uint public tester1;
    uint public tester2;
    mapping(address => mapping(address => uint)) public active_period;

function _update_period1(address gauge, address reward_token) public returns (uint) {
        uint _period = active_period[gauge][reward_token];
        if (block.timestamp >= _period + WEEK) {
            _period = block.timestamp / WEEK * WEEK;
            tester1 = 1;
            active_period[gauge][reward_token] = _period;
        }
        return _period;
    }
    
function _update_period2(address gauge, address reward_token, uint extra_time) public returns (uint) {
        uint _period = active_period[gauge][reward_token];
        if (block.timestamp >= (_period + extra_time) + WEEK) {
            _period = block.timestamp / WEEK * WEEK;
            tester2 = 1;
            active_period[gauge][reward_token] = _period;
        }
        return _period;
    }

function timestamp() external view returns (uint) {
        uint _test = block.timestamp;
        return _test;
    }

function divisor() external view returns (uint) {
        uint _test = WEEK * WEEK;
        return _test;
    }
    
function component() external view returns (uint) {
        uint _test = block.timestamp / WEEK;
        return _test;
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
        uint _test = block.timestamp / (WEEK * WEEK);
        return _test;
    }
}