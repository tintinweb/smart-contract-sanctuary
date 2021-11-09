/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

contract TokenInfos {
    
    /* Fallback function, don't accept any ETH */
    receive() external payable {
        // revert();
        revert("BalanceChecker does not accept payments");
    }
    
    function isContract(address token) internal view returns(bool){
        // check if token is actually a contract
        uint256 tokenCode;
        assembly { tokenCode := extcodesize(token) } // contract code size
        return tokenCode > 0;
    }
    
    function testCall(address token) public returns(bool){
        bytes4 IS_CONTRACT = bytes4(keccak256(bytes("isContract(address)")));
        (bool success, ) =  address(this).call( abi.encodeWithSelector(IS_CONTRACT, token) );
        return success;
    }
    
    function testCall2(address token) public view returns(bool){
        return isContract(token);
    }
   
}