/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

pragma solidity ^0.8.0;

contract Lottery {
    address []players;
    uint256 fee = 1;

    function enter() public payable{
        require(msg.value == fee);
        players.push(msg.sender);
    }

    function pickWinner() public payable{
        uint256 winner = uint256(block.timestamp*block.number) % players.length;
        payable(players[winner]).transfer(address(this).balance);
    }
}