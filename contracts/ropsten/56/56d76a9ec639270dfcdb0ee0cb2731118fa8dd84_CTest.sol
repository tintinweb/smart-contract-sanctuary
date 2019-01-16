pragma solidity ^0.5.0;

contract ITest {
    function test() public returns(uint);
}

contract Test is ITest {
    
    function test() public returns(uint) {
        return 1234;
    }
    
}

contract CTest {
    
    function test(ITest _itest) public returns(uint) {
        return _itest.test();
    }
}