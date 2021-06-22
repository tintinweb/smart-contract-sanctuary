/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity ^0.8.4;

contract SimpleStorage {
    uint data;

// update the variable
    function updateData(uint _data) external{
        data = _data;
    }
// read the variable
    function readData() external view returns(uint){
        return data;
    }
}