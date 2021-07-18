/**
 *Submitted for verification at Etherscan.io on 2021-07-18
*/

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    
    string public name = "";
    uint256 public age = 0;
    bool public isMarry = false;
    
    function setInfo(string memory _name, uint256 _age, bool _isMarry) public {
        name = _name;
        age = _age;
        isMarry = _isMarry;
    }
    
    
}