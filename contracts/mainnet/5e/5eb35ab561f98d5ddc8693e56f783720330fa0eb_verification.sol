/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity ^0.8.0;

contract verification{
    mapping(string => uint) private Pairs;
    function set(string calldata _hash) external{
        require(Pairs[_hash] == 0, "Message Already on Blockchain!");
        Pairs[_hash] = block.timestamp;
    }
    function get(string calldata _hash) external view returns (uint){
        require(Pairs[_hash] != 0, "Message NOT on Blockchain!");
        return Pairs[_hash];
    }
}