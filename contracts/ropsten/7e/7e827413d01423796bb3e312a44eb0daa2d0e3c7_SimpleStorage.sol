/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;
 
contract SimpleStorage {
    
//   function print() public view returns (bytes32 ) {
//         bytes32  x = "Ay FUFULU";
//         return x;
//     }



    function getMessage()public view returns(string memory){
        return "Ay FUFULU";
    }
    
}