// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "Address.sol";
contract Caller {
    
    constructor(bool flag,int  x) public {
         
    }
         
    event Response(bool success, bytes data);

    // Let's imagine that contract B does not have the source code for
    // contract A, but we do know the address of A and the function to call.
    function testCallFoo(address payable _addr) public payable {
        // You can send ether and specify a custom gas amount
        (bool success, bytes memory data) = _addr.call{value: msg.value, gas: 5000}(
            abi.encodeWithSignature("foo(string,uint256)", "call foo", 123)
        );

        emit Response(success, data);
    }

    // Calling a function that does not exist triggers the fallback function.
    function testCallDoesNotExist(address _addr) public {
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("doesNotExist()")
        );

        emit Response(success, data);
    }
    
    
     // Calling a function isContract.
    function isContract(address _addr) public view returns (bool winningProposal_){
        return (Address.isContract(_addr));
    }
    
    
}