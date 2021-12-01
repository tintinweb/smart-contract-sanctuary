/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

pragma solidity ^0.8.7;

contract test {
    bytes1 public type_bytes;
    bytes1 public type_uint256;
    bytes1 public type_address;
    bytes1 public type_uint256array;

    function bytesToUint(bytes calldata data) public returns(uint256) {

    }

    function bytesToArray(bytes calldata data) public returns(uint256[] memory) {

    }

    function testtype(bytes memory data, uint256 id, address name, uint256[] memory fimary) public {
        type_bytes = bytes1(keccak256(bytes('bytes')));
        type_uint256 = bytes1(keccak256(bytes('uint256')));
        type_address = bytes1(keccak256(bytes('address')));
        type_uint256array = bytes1(keccak256(bytes('uint256[]')));
    }
}