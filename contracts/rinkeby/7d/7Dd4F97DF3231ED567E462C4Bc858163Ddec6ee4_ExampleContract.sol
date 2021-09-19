/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

pragma solidity ^0.4.22;

contract ExampleContract {
    
    uint[] myArr = [1,2,3,4,5,6,7,8,9,10];
    
    function testCondition(uint n) public pure returns (string) {
        if (n%2 == 0) {
            return "is even number";
        } else {
            return "is odd number";
        }
    }
    
    function testFor() public view returns (uint) {
        uint sum = 0;
        for(uint i=0; i<myArr.length; i++) {
            sum += myArr[i];
        }
        return sum;
    }
    
    function testWhile() public view returns (uint) {
        uint sum = 0;
        uint i = 0;
        while (i<myArr.length) {
            sum += myArr[i];
            i++;
        }
        return sum;
    }
    
    function testDoWhile() public view returns (uint) {
        uint sum = 0;
        uint i = 0;
        do {
            sum += myArr[i];
            i++;
        } while (i<myArr.length);
        return sum;
    }

    modifier divideByZero(uint y) {
        require(y > 0);
        _;
    }
    
    function plus(uint8 x, uint y) public pure returns (uint) {
        return x + y;
    }
    
    function minus(int x, int y) public pure returns (int) {
        return  x - y;
    }
    
    function multiply(uint x, uint y) public pure returns (uint) {
        return x * y;
    }
    
    function divide(uint x, uint y) public divideByZero(y) pure returns (uint) {
        return x/y;
    }
}