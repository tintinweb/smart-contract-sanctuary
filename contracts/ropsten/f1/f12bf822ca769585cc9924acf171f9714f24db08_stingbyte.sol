/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;  

contract stingbyte{
    

    event stringbyte(bytes32 bytesSring);
    
    function stringToBytes32(string memory source) public returns(bytes32 result){

        assembly {
        result := mload(add(source, 32))
        }
        
        emit stringbyte(result);
    }
    

}