/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

pragma solidity 0.8.0;

contract Judge {
    
    string public details;
    
    function judgment(string calldata _details) external {
        details = _details;
    }
}