/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

pragma solidity 0.8.10;

contract SimpleStorage {
    uint data;

    function updateData(uint _data) external {
        data = _data;
    }

    function readData() external view returns(uint) {
        return data;
    }
}