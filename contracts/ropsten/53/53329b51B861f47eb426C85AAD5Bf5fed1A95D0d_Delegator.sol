/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Delegator {
    address delegateAddress = 0xF01a4D5feb4fE060d93549cfC964c509DaB67207;
    uint8 num;
    
    function storeYonder(uint8 n) public {
        bytes memory payload = abi.encodeWithSignature("store(uint8)", n);
        (bool succ,) = address(delegateAddress).call(payload);
        require(succ);
    }
    
    function retrieveYonder() public {
        bytes memory payload = abi.encodeWithSignature("retrieve()");
        (bool succ, bytes memory ret) = address(delegateAddress).call(payload);
        require(succ);
        num = abi.decode(ret, (uint8)); 
    }
    
    function retrieve() public view returns (uint8){
        return num;
    }
}