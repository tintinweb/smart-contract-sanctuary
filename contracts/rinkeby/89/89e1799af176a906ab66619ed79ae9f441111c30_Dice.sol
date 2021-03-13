/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

pragma solidity ^0.7.6;

contract Dice {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    // 下注，猜对大小，就赢 下注x2 的ETH
    function bet(uint8 dd) external payable returns (bool win) {
        require(msg.value > 0, "please pay for bet");
        require(address(this).balance > msg.value, "amount too large");

        uint8 r = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 100);
        if (dd > 50 && r > 50) win = true;
        if (dd <= 50 && r <= 50) win = true;

        if (win) msg.sender.call{value: msg.value * 2}("");
    }

    function balance() external view returns (uint256) {
        require(msg.sender == owner);
        return address(this).balance;
    }
    
    // 提取收入
    function bonus() external {
        require(msg.sender == owner);
        msg.sender.call{value: address(this).balance}("");
    }
}