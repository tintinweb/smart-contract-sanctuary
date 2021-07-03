/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract ContractsCaller {

    function execute(address contractAt)/*, uint _i, bytes32 _b)I*/
        public returns (bool, bytes memory) {
        return(
            contractAt.call(
            abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,uint256,address)",
                
                [
                    0xC44185DF9f5049cca839fe28C5030b23ddE65bEc,
                    0x7b498eFA017CA2f1721FdB6F9a21a7cA7290eB10
                ],
            
                2,
            
                address(0),
            
                0,
            
                address(0),
            
                address(0),
            
                0xE8b4d075bbD31bc80EfbDD064644A41FBeFB821a
            )
       )
       );
    }
}