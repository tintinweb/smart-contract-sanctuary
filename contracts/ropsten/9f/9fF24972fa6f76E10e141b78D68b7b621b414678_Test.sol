/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

pragma solidity ^0.8.0;

contract Test{
    uint256 private _value=3;
    function getValue() public view virtual returns (uint256) {
        return _value;
    }
}