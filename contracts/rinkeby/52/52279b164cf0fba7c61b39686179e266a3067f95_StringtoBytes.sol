/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma abicoder v2;

contract StringtoBytes{
bytes b3 ="";

function stringToBytes32(string memory source) public returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }
    return byteshash(string_tobytes(source));
 
}
      function string_tobytes(string memory s) internal returns(bytes memory){
         b3 = bytes(s);
         return b3;
    }
    
    function byteshash(bytes memory s) internal returns(bytes32 ){
        bytes32 b4 = sha256(s);
        return b4;
    }
    
    function stringToBytes32M(string[233] memory source) public returns (bytes32[233] memory ) {
   
    bytes32[233] memory res;
 
   
     for (uint i = 0; i < source.length; i++) {
               res[i] = byteshash(string_tobytes(source[i]));
        }
    return res;
 
    }
}