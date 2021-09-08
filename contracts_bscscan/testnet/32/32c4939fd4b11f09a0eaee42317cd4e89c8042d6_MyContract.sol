pragma solidity ^0.4.19;

import "./ownable.sol";
import "./safemath.sol";


contract MyContract {
    string public functioncalled;
    
    function sendEther() external payable {
        functioncalled = 'sendEther';
    }
    
    function() external payable {
        functioncalled = 'fallback';
    }
    
    
}