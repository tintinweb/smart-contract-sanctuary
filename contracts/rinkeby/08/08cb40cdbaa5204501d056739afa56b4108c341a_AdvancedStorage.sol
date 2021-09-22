/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

pragma solidity ^0.5.0 ;

contract AdvancedStorage {
    uint256[] public ids;
    
    function add(uint256 id) public{
        
        ids.push(id);
    }
    function get(uint position) view public returns (uint) {
        return ids[position];
        
        }
    function getAll() view public returns (uint[] memory){
        return ids;
        }
    function getSize() view public returns (uint) {
        return ids.length;
    }
}