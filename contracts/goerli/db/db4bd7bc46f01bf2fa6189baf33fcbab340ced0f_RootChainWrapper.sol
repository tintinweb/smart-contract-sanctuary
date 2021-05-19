/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity >=0.6.0 <0.8.0;

interface RootChainManager {
    function exit(bytes calldata inputData) external;
}

contract RootChainWrapper {
    
    
    function exit(address rootChainManager, bytes calldata inputData) public returns(bool)  {
        RootChainManager(rootChainManager).exit(inputData);
        
        return true;
    }
    
    
}