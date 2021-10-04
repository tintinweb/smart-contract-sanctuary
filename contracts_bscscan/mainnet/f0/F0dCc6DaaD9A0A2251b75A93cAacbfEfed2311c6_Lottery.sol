/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery{
    
    address payable[] public players;
    address payable public admin;
    uint256 public lastgame;
    address public lastwinner;
    uint256 public lastwin;
    
    constructor()
    {
        admin = payable(msg.sender);
        lastgame = block.timestamp;
    }
    
    receive() external payable
    {
        require(msg.value == 1000 ether, "Must be exaclty 1 Ether");
        require(msg.sender != admin, "No Admins allowed");
        
        players.push(payable(msg.sender));
    }
    
    function getBalance() public view returns(uint)
    {
        return address(this).balance;
    }
    
    function random() internal view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    function pickWinner() internal
    {
        require(block.timestamp > lastgame + 24 hours,"24 hours not passed");
        require(players.length >= 3, "Not enough Players");
        
        
        address payable winner;
        
        winner = players[random() % players.length];
        lastwin = getBalance();
        winner.transfer(getBalance());
        
        lastwinner = winner;
        players = new address payable[](0);
        lastgame = block.timestamp;
    }
    
    function lotterypicker() public
    {
        pickWinner();
    }
}