/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity 0.8.7;

contract Test {
    event SetA(uint256 a);
    event SetB(uint256 b);
    
    uint256 public a;
    uint256 public b;
    
    function setA(uint256 _a) external {
        a = _a;
    }
    
    function setB(uint256 _b) external {
        require(a != 0, "A not set yet");
        b = _b;
    }
}