pragma solidity ^0.4.0;

library TestLibrary {
    function x(uint z) public {
        address p = address(this);
        p.transfer(z);
    }
}

contract TestContract {
    using TestLibrary for uint;
    
    function y() public {
        uint(5).x();
    }
}