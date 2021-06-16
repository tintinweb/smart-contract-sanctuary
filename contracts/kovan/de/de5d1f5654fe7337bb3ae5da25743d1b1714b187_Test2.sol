/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity 0.5.16;

contract Test {
    
    function get(bool _flag) public pure returns (uint) {
        if (_flag) {
            return 100;
        }
    }
}

contract Test2 {
    uint public num;
    Test public test;
    
    constructor() public {
        test = new Test();
    }
    
    function set(bool _flag) public {
        uint _num = test.get(_flag);
        if (_flag) {
            num = _num;
        }
    }
}