/**
 *Submitted for verification at polygonscan.com on 2021-09-08
*/

pragma solidity ^0.8.3;
contract ReturnData {
    function returnData() external view returns(bytes memory response) {
        response = bytes("aaa");
    }
}