pragma solidity ^0.4.0;

contract Trial2{
    
    uint256 ch_uint256;
    bytes c;
    bytes32 x;
    
    
    function byteToString(byte b) public view returns(string){
        //uint256 number1;
        ch_uint256 = ch_uint256 + uint256(b[0])*(2**(8*(b.length-(0+1))));
        //return ch_uint256;
        
        //uint to bytes
       // bytes c;
        bytes32 b1 = bytes32(ch_uint256);
    
        c= new bytes(32);
        for(uint i=0;i<32;i++){
            c[i]=b1[i];
        }
        //return c; //return type bytes
    
        //convert bytes32 to string
        string memory str1 = string(c); //bytes to string
        x= stringToBytes32(str1);   // string to byte32
        
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    
    
    
    function stringToBytes32(string memory source) private returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}