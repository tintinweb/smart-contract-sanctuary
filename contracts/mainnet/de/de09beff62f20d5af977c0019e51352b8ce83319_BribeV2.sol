/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

interface erc20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

interface GaugeController {
    struct VotedSlope {
        uint slope;
        uint power;
        uint end;
    }
    
    struct Point {
        uint bias;
        uint slope;
    }
    
    function vote_user_slopes(address, address) external view returns (VotedSlope memory);
    function last_user_vote(address, address) external view returns (uint);
    function points_weight(address, uint256) external view returns (Point memory);
    function checkpoint_gauge(address) external;
}

interface ve {
    function get_last_user_slope(address) external view returns (int128);
}

interface bribe {
    function active_period(address, address) external view returns (uint);
    function reward_per_token(address, address) external view returns (uint);
}

contract BribeV2 {
    uint constant WEEK = 86400 * 7;
    uint constant PRECISION = 10**18;
    GaugeController constant GAUGE = GaugeController(0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB);
    ve constant VE = ve(0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2);
    bribe constant BRIBE = bribe(0x7893bbb46613d7a4FbcC31Dab4C9b823FfeE1026);
    
    function tokens_for_bribe(address user, address gauge, address reward_token) external view returns (uint) {
        uint _reward_per_token = BRIBE.reward_per_token(gauge, reward_token);
        uint _active_period = BRIBE.active_period(gauge, reward_token);
        uint _previous_slope = GAUGE.points_weight(gauge, _active_period).slope;
        uint _amount = Math.min(_reward_per_token * _previous_slope / PRECISION, erc20(reward_token).balanceOf(address(BRIBE)));
        uint _slope = GAUGE.points_weight(gauge, _active_period+WEEK).slope;
        return uint(int(VE.get_last_user_slope(user))) * _amount / _slope;
    }
}