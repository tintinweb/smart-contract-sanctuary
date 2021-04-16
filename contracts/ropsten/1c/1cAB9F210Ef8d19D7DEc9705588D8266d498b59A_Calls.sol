/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity ^0.6.12;

contract Calls {
    constructor () public {}
    
    event Called(address indexed addr);
    event DelegateCalled(address indexed addr);
    
    function callAny (address addr, bytes memory data) payable public {
        (bool success, bytes memory returndata) = addr.call(data);
        require(success, 'call failed');
        
        emit Called(addr);
    } 
    
    function deleCallAny (address addr, bytes memory data) payable public {
        (bool success, bytes memory returndata) = addr.delegatecall(data);
        require(success, 'delegateCall failed');
        
        emit DelegateCalled(addr);
    }
}