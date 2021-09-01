/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

pragma solidity 0.5.16;

contract SimpleStorage {
    uint public data;

    function updateData(uint _data) external {
        data = _data;
    }

    function readData() external view returns(uint) {
        return data;
    }
}