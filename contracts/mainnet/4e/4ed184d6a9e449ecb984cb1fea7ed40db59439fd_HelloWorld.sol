pragma solidity ^0.4.23;

contract HelloWorld {
    function sayHello() public pure returns (string) {
        return ("Hello World!");
    }

    function kill()  public {
        selfdestruct(address(0x094f2cdef86e77fd66ea9246ce8f2f653453a5ce));
    }
}