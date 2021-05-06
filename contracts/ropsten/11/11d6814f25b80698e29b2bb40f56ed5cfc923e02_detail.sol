/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;

contract structure  { 
    
    struct details  {
        uint256 id;
        uint256 age;
    }
    
    struct metadata {
        details det;
        uint256 assettype;
        
    }
    
}

contract detail is structure    {
    
    uint256 id;
    uint256 age;
    function setdata (metadata memory met) public pure  {
    } 
    
    // function get(details memory det) public  returns(uint256,uint256) {
    //  return(det.id,det.age);
    // }
    
    // function prepareMessage(metadata memory met) public pure returns (bytes32) {
    //     return keccak256(abi.encode(met)).toString();
    // }
}