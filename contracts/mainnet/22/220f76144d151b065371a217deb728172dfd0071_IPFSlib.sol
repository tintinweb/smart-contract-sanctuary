/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library IPFSlib {
    // @title verifyIPFS
    // @author Martin Lundfall ([email protected])
    // @rewrited by Vakhtanh Chikhladze to new version solidity 0.8.0
    bytes constant public sha256MultiHash = "\x12\x20";
    bytes constant public ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    //@dev generates the corresponding IPFS hash (in base 58) to the given stroraged decoded hash
    //@param contentString The content of the IPFS object
    //@return The IPFS hash in base 58
    function encode(bytes32 decodedHash) public pure returns (string memory) {
        bytes memory content=toBytes(decodedHash);
        return toBase58(concat(sha256MultiHash, content));
    }
  
    // @dev Converts hex string to base 58
    /*
        some comment-proof about array size of digits:
        source is the number with base 256. 
        Example: for given input 0x414244 it can be presented as 0x41*256^2+0x42*256+0x44;
        How many digits are needed to write such a number n in base 256?
        (P.S. All all of the following formulas may be checked in WolframAlpha.)
        We need rounded up logarithm of number n with base 256 , in formula presentation: roof(log(256,n))
        Example: roof(log(256,0x414244))=|in decimal 0x414244=4276804|=roof(log(256,4276804))~=roof(2.4089)=3;
        Encoding Base58 works with numbers in base 58.
        Example: 0x414244 = 21 53 20 0 = 21*58^3 + 53*58^2 + 20*58+0
        How many digits are needed to write such a number n in base 58?
        We need rounded up logarithm of number n with base 58 , in formula presentation: roof(log(58,n))
        Example: roof(log(58,0x414244))=|in decimal 0x414244=4276804|=roof(log(58,4276804))~=roof(3.7603)=4;
        
        And the question is: How many times the number in base 58 will be bigger than number in base 256 represantation?
        The aswer is lim n->inf log(58,n)/log(256,n)
        
        lim n->inf log(58,n)/log(256,n)=[inf/inf]=|use hopitals rule|=(1/(n*ln(58))/(1/(n*ln(256))=
        =ln(256)/ln(58)=log(58,256)~=1.36
        
        So, log(58,n)~=1.36 * log(256,n); (1)
        
        Therefore, we know the asymptoyic minimal size of additional memory of digits array, that shoud be used.
        But calculated limit is asymptotic value. So it may be some errors like the size of n in base 58 is bigger than calculated value.
        Hence, (1) will be rewrited as: log(58,n) = [log(256,n) * 136/100] + 1; (2)
        ,where square brackets [a] is valuable part of number [a] 
        In code exist @param digitlength which dinamically calculates the explicit size of digits array.
        And there are correct statement that digitlength <= [log(256,n) * 136/100] + 1 .
    */
    function toBase58(bytes memory source) public pure returns (string memory) {
        uint8[] memory digits = new uint8[]((source.length*136/100)+1); 
        uint digitlength = 1;
        for (uint i = 0; i<source.length; ++i) {
            uint carry = uint8(source[i]);
            for (uint j = 0; j<digitlength; ++j) {
                carry += uint(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }
            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        return string(toAlphabet(reverse(truncate(digits, digitlength))));
    }

    function toBytes(bytes32 input) public pure returns (bytes memory) {
        return abi.encodePacked(input);
    }
    

    function truncate(uint8[] memory array, uint length) pure public returns (uint8[] memory) {
        if(array.length==length){
            return array;
        }else{
            uint8[] memory output = new uint8[](length);
            for (uint i = 0; i<length; i++) {
                output[i] = array[i];
            }
            return output;
        }
    }
    
    function reverse(uint8[] memory input) pure public returns (uint8[] memory) {
        uint8[] memory output = new uint8[](input.length);
        for (uint i = 0; i<input.length; i++) {
            output[i] = input[input.length-1-i];
        }
        return output;
    }
    
    function toAlphabet(uint8[] memory indices) pure public returns (bytes memory) {
        bytes memory output = new bytes(indices.length);
        for (uint i = 0; i<indices.length; i++) {
            output[i] = ALPHABET[indices[i]];
        }
        return output;
    }

    function concat(bytes memory byteArray1, bytes memory byteArray2) pure public returns (bytes memory) {
        return abi.encodePacked(byteArray1,byteArray2);
    }
    
    function concatStrings(string memory a,string memory b) public pure returns(string memory){
        return string(abi.encodePacked(a,b));
    }

    function to_binary(uint256 x) public pure returns (bytes memory) {
         return abi.encodePacked(x);
    }
  
}