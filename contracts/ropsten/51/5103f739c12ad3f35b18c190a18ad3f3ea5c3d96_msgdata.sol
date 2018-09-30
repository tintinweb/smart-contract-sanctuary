pragma solidity ^0.4.24;

contract msgdata {
    function msgdata(){

    }

    uint public x;

    function bytesToUint(bytes source) internal pure returns(uint) {
        uint result;
        uint mul = 1;
        for(uint i = 20; i > 0; i--) {
            result += uint8(source[i-1])*mul;
            mul = mul*256;
        }
        return result;
    }
    
    function bytesToUint1(bytes b) public returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(b[i])*(2**(8*(b.length-(i+1))));
        }
        return number;
    }

    function() public payable {
        x = bytesToUint(bytes(msg.data));
    }
    
}