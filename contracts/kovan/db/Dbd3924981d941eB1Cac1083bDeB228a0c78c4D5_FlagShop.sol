/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

pragma solidity ^0.8.10;


contract FlagShop {
    bool public flag_bought;
    mapping(address => uint) public point_balances;
    uint private secret;

    constructor(uint _secret) {
        secret = _secret;
    }

    function buy_flag() external {
        require(point_balances[msg.sender] >= 10, "Not enough points");
        flag_bought = true;
    }

    function get_points() external {
        require(point_balances[msg.sender] <= 5, "Only 5 free points");
        point_balances[msg.sender] += 1;
    }

    function play_roulette(bytes32 guess) external {
        require(point_balances[msg.sender] >= 1, "Should have at least 1 point to play");
        if (guess == keccak256(abi.encodePacked(block.timestamp, secret))) {
            point_balances[msg.sender] += 10;
        }
    }
}