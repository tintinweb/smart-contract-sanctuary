/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

pragma solidity ^0.8.0;

contract MyContract {
    uint256 public data;

    function setData(uint256 _data) external {
        data = _data;
    }
}