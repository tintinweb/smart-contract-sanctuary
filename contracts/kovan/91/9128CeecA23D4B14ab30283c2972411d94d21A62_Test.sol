/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity ^0.5.16;

contract Test {
    uint256 public number = 100;
    
    function setNum(uint256 _input) public {
        number = _input;
    }
    
    function getNum() public view returns(uint256) {
        return number;
    }
}