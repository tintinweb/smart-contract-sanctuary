/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

pragma solidity ^0.4.26;


contract Test {
    
    uint8 public height;
    uint8 public weigth;
    
    constructor() public {
        height = 100;
        weigth = 10;
    }
    
    function setHeight(uint8 _height) public {
        height = _height;
    }
    
     function setWeigth(uint8 _weigth) public {
        weigth = _weigth;
    }
}