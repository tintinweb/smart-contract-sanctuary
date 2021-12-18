/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

pragma solidity ^0.8.9;

interface Level3 {
    function obtainFlag() external;
}

//contract Level3 {
//    
//    function obtainFlag() external {
//        IFlagReciever(msg.sender).recieveFlag(0x0520677c632922681048dbf8837b239b0f1e9447d89d9ee9639f567e66de3fbb);
//    }
//    
//}

contract IFlagReciever {

    Level3 d;

    bytes32 public x;

    function call(address t) external {
        d = Level3(t);
        d.obtainFlag();
    }
    
    function recieveFlag(bytes32 flag) external returns (bytes32) {
        x = flag;
        return flag;
    }

    function print() public returns (bytes32) {
        return x;
    }

}