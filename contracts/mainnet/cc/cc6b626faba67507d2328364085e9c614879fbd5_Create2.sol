/**
 *Submitted for verification at Etherscan.io on 2021-01-12
*/

pragma solidity ^0.6.12;


contract Create2 {
    
    event ContractDeployed(address indexed addr);
    
    function deploy(bytes32 salt, bytes memory code) public returns (address) {
        // hex of hello world deploy bytecode
        uint len = code.length;
        address deployed;
        assembly{
            deployed := create2(0, add(code, 0x20), len, salt)
        }
        
        emit ContractDeployed(deployed);
        
        return deployed;
    }
    
}