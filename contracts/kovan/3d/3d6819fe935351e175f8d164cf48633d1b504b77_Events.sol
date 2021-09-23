/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

pragma solidity ^0.5.8;


contract Events {
    
    int256  testInt256;
    uint256 testUint256;
    int192  testInt192;
    uint192 testUint192;
    uint16  testUint16;
    uint8   testUint81;
    uint8   testUint80;
    bytes   testBytes;
 
    event test256(int256 indexed testInt256, uint256 indexed testUint256);
    event test192(int192 indexed testInt192, uint192 indexed testUint192);
    event test16(uint16 indexed testUint16, uint8 indexed testUint80, uint8 indexed testUint81);
    event testBytesEvent(bytes indexed testBytes);
    
    function emitEvent() public {

        testInt256 = 256000;
        testUint256 = 256001;
        testInt192 = 192000;
        testUint192 = 192001;
        testUint16 = 16;
        testUint81 = 1;
        testUint80 = 0;
        testBytes = "test";

        emit test256(testInt256, testUint256);
        emit test192(testInt192, testUint192);
        emit test16(testUint16, testUint80, testUint81);
        emit testBytesEvent(testBytes);


    }


    
}