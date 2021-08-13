/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity ^0.8.4;

contract a {
    function call(address _contract) external {
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("doSomething()")
        );
        
        require(success, 'call failed');
    }
}