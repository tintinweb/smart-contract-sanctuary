/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Drive {
    mapping (address => uint) reward;
    mapping (address => uint) action_count;

    uint count = 0;
    uint fee = 0;
    uint fee_rate = 25;

    function settlement(address _to) public {
        require(reward[_to] != 0);
        require(_to != address(0));
        uint avg = getAvg();
        cumulativeReward(_to, avg*action_count[_to]);
        payable(_to).transfer(reward[_to]);
        reward[_to] = 0;
        action_count[_to] = 0;
    }

    function cumulativeReward(address _owner, uint _count) public {
        require(_owner != address(0));
        require(_count != 0);
        reward[_owner] += _count;
    }

    function addCount(address _owner) public {
        require(_owner != address(0));
        action_count[_owner] += 1;
        count += 1;
    }

    function rebate(address _sell, address _buy, uint _value) public {
        require( _sell != address(0) && _buy != address(0) && _sell != _buy);
        require(_buy != msg.sender);
        require(_value > 0);
        uint _count;
        fee += _value * fee_rate * 30 / 100 / 100;
        if (_buy != address(0)){
            _count = _value * fee_rate * 50 / 100 / 100;
            cumulativeReward(_sell, _count);
            _count = _value * fee_rate * 20 / 100 / 100;
            cumulativeReward(_buy, _count);
        } else {
            _count = _value * fee_rate * 70 / 100 / 100;
            cumulativeReward(_sell, _count);
        }
    }

    function getAvg() private view returns(uint) {
        uint avg = fee * 50 / count / 100;
        return avg;
    }
}