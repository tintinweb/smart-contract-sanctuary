/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

pragma solidity ^0.6.7;
contract wheels_mcfantini {
    uint256 number;
    
    function changeNumber(uint256 _num) public {
        number = number +  _num;
    }
    
    function getNumber() public view returns (uint256) {
        return number;
    }
    
    function getNumberMultiplied(uint256 _num) public view returns (uint256) {
        return number * _num;
    }
    
    function addNumbers(uint256 _num1, uint256 _num2) public {
        number = _num1 + _num2;
    }
}