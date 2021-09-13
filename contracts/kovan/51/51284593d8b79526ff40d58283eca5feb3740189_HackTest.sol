/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

pragma solidity ^0.6.0;

contract HackTest {
    
    uint256 _amount;
    uint256 public param1;
    address public param2;
    uint256 public param3;
    uint8 public param4;
    uint256 public param5;
    uint256 public param6;
    
    constructor() public {
        
    }
    
    function withdraw(uint256 amount) public payable {
        _amount = amount;
    }
    
    function withdrawToken(uint256 _param1, address _param2, uint256 _param3, uint8 _param4, uint256 _param5, uint256 _param6) public payable{
        param1 = _param1;
        param2 = _param2;
        param3 = _param3;
        param4 = _param4;
        param5 = _param5;
        param6 = _param6;
    }
}