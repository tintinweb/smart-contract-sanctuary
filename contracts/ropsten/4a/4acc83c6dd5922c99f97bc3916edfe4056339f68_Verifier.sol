/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

// pragma solidity ^0.5.1;
// contract Verifier {
//     function recoverAddr(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s)public returns (address) {
//         address res =  ecrecover(msgHash, v, r, s);
//     return res;
        
//     }
    
//     function isSigned(address _addr, bytes32 msgHash, uint8 v, bytes32 r, bytes32 s)public returns (bool) {
//         return ecrecover(msgHash, v, r, s) == _addr;
//     }
// }

pragma solidity >=0.4.0 <0.6.0;


contract Verifier {
  // Returns the address that signed a given string message 
  string private checkString = "KDEX";
  
  function checking(string message,uint8 v,bytes32 r,bytes32 s)public  returns(bool result){
      require(validate(message));
      require(verify(message,v,r,s)==msg.sender);
      return true;
  }
  
  function verify(string  message, uint8 v, bytes32 r, bytes32 s) private pure returns (address signer) {
    // The message header; we will fill in the length next 
    
    string memory header = "\x19Ethereum Signed Message:\n000000";
    uint256 lengthOffset;
    uint256 length;
    assembly {
      
// The first word of a string is its length   
    length := mload(message)
      // The beginning of the base-10 message length in the prefix  
      lengthOffset := add(header, 57)
    }
    // Maximum length we support  
    require(length <= 999999);
    // The length of the message&#39;s length in base-10    
    uint256 lengthLength = 0;
    // The divisor to get the next left-most message length digit   
    uint256 divisor = 100000;
    // Move one digit of the message length to the right at a time   
    while (divisor != 0) {
      // The place value at the divisor 
      uint256 digit = length / divisor;
      if (digit == 0) {
        
// Skip leading zeros       
if (lengthLength == 0) {
          divisor /= 10;
          continue;
        }
      }
      // Found a non-zero digit or non-leading zero digit   
      lengthLength++;
      // Remove this digit from the message length&#39;s current value  
      length -= digit * divisor;
      // Shift our base-10 divisor over      
      divisor /= 10;
      
      
// Convert the digit to its ASCII representation (man ascii)      
    digit += 0x30;
      // Move to the next character and write the digit      
      lengthOffset++;
      assembly {
        mstore8(lengthOffset, digit)
      }
    }
    // The null string requires exactly 1 zero (unskip 1 leading 0)   
    if (lengthLength == 0) {
      lengthLength = 1 + 0x19 + 1;
    } else {
      lengthLength += 1 + 0x19;
    }
    // Truncate the tailing zeros from the header   
    assembly {
      mstore(header, lengthLength)
    }
    // Perform the elliptic curve recover operation   
    bytes32 check = keccak256(header, message);
    return ecrecover(check, v, r, s);
  }
  
  
  function validate(string str)private constant returns (bool) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(4-0);
    for(uint i = 0; i < 4; i++) {
        result[i-0] = strBytes[i];
    }
    if(hashCompareWithLengthCheck(string(result))){
        return true;
    }
    else{
        return false;
    }
}
function hashCompareWithLengthCheck(string a) private returns (bool) {
    if(bytes(a).length != bytes(checkString).length) {
        return false;
    } else {
        return keccak256(a) == keccak256(checkString);
    }
}
}