pragma solidity ^0.4.25;

contract Hello{
    function setInvalidWithReturn() public returns(bool){}
}

contract Hello2{
    Hello h1;
    address _a = 0x41b0D68ef885Aee1A99D987A3c9c6cC2827C0Afa;
    function Hello2() public {
        h1 = Hello(_a);
    }

    function setHello() public returns (bool result){
        h1.setInvalidWithReturn();
        return true;
    }
}