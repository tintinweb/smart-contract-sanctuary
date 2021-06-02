/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

pragma solidity ^0.6.12;

contract MockProxy {
    event Test(address sender, address signer, string testdata);
    event TestStr(uint256 str);
    
    uint256 private _data;

    function test(address signer, string memory testdata) public returns (bool success) {
        emit Test(msg.sender, signer, testdata);
        return true;
    }

    function setData(uint256 data) public returns (bool success) {
        _data = data;
        return true;
    }

    function getData() public view returns (uint256 success) {
        return _data;
    }
}