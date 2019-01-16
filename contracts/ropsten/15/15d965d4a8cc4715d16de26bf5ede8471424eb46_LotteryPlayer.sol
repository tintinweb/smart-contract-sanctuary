pragma solidity ^0.4.25;

contract Lottery {
    function play(uint256 _seed) external payable;
}

contract LotteryPlayer {
    function play(address addr) external payable
    {
        require(msg.value >= 1 finney);
        bytes32 entropy = blockhash(block.number);
        bytes32 entropy2 = keccak256(abi.encodePacked(this));
        bytes32 seed = entropy^entropy2;
        Lottery(addr).play.value(msg.value)(uint256(seed));
    }
}