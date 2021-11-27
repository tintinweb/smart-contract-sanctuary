/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

pragma solidity ^0.8.7;

contract MyContract {
    uint public data;

    function setData(uint _data) external {
        data = _data;
    }
}