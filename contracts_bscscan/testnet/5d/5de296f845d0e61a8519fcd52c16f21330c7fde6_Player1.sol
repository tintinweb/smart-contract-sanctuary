/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

pragma solidity >=0.5.0 <0.8.6;
contract Player1 {
    address public owner;
    constructor() public {
      owner = msg.sender;
    }
    function pick_online(address[] memory players)  public returns (address) {
        require(msg.sender == owner);
        uint index= uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players))) % players.length;
        return players[index];
    }      
    function pick_offline(address[] memory players, uint256 block_difficulty, uint256 block_timestamp) pure public returns (address) {
        uint index= uint(keccak256(abi.encodePacked(block_difficulty , block_timestamp, players))) % players.length;
        return players[index];
    }
}