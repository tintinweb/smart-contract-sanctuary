/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity >=0.7.0 <0.8.0;

interface Canary{
    function ping(string memory) external;
}

contract CanaryProxy {
    
    function proxyPing(address target, string memory name) public {
        Canary(target).ping(name);
    }
    
}