/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Caller {

    
    function testCalltransferERC20Tokens(address _addr, address dst, uint rawAmount) public {
         _addr.call(abi.encodeWithSignature("transfer(address, uint)", dst, rawAmount));

        
    }
    
    function testCalltransferMyTokens(address dst, uint rawAmount) public {
       address(0xd9145CCE52D386f254917e481eB44e9943F39138).call(abi.encodeWithSignature("transfer(address, uint)", dst, rawAmount));

        
    }
    
    function testCalltotalsupplyMyTokens() public returns(bool truefalse, bytes memory data){
       (bool truefalse, bytes memory data) = address(0xd5ff0625b94Aeb7CC4FAF2ff7AA19C95f39021DD).call(abi.encodeWithSignature("totalSupply()"));
      
        
    }
    
    
    

}