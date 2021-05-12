/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

pragma solidity 0.6.12;

contract Test {
    uint256 public value;

    function setValue(uint256 _value) external{
        value = _value;
    }

    function getValue() external view returns(uint256){
        return value;
    }
}