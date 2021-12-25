/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

pragma solidity ^0.8.0;

contract MyContract {
    uint256 data;

    function setData(uint256 _data) external {
        data = _data;
    }

    function getData() external view returns (uint256) {
        return data;
    }
}