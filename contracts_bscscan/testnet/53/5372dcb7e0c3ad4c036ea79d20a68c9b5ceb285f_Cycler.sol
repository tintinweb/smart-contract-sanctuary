/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;
contract Cycler {
    uint256 public Total;
    struct Line {
        uint8 lvl;
        address addr;
    }
    struct Acc {
        uint256 id;
    }
    mapping(uint256 => Line) public Position;
    mapping(address => Acc) public Account;
    constructor() public {
        Position[Total] = Line(0, msg.sender);
    }
    function Buy() external payable returns (bool) {
        require(msg.value == 1000000000000000, "Amount doesn't match position cost!");
        uint256 x = Total / 5;
        Position[x].lvl = Position[x].lvl + 1;
        if(Position[x].lvl == 5){
            payable(Position[x].addr).transfer(5000000000000000);
        }
        Position[++Total] = Line(0, msg.sender);
        Account[msg.sender].id = Total;
        return true;
    }
}