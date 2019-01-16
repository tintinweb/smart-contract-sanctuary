pragma solidity ^0.4.21;

contract MetaTestContract {
    int public myNumber = 10;

    function increaseNumber() public {
        myNumber++;
    }
}