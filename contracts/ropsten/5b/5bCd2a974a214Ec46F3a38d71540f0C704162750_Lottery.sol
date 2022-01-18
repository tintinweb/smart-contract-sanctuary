/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;

    function mint() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }
}