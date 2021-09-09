/**
 *Submitted for verification at polygonscan.com on 2021-09-08
*/

pragma solidity ^0.8.3;
contract ReturnData {
    function returnData() external view returns(bytes memory response) {
        response = bytes("0x736f796c656e745f677265656e5f69735f70656f706c65");
    }
}