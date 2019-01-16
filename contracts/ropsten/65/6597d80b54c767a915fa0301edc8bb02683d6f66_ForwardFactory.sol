// Bytecode origin https://www.reddit.com/r/ethereum/comments/6ic49q/any_assembly_programmers_willing_to_write_a/dj5ceuw/
// Modified version of Vitalik&#39;s https://www.reddit.com/r/ethereum/comments/6c1jui/delegatecall_forwarders_how_to_save_5098_on/
// Credits to Jordi Baylina for this way of deploying contracts https://gist.github.com/jbaylina/e8ac19b8e7478fd10cf0363ad1a5a4b3

// Forwarder is slightly modified to only return 256 bytes (8 normal returns)

// Deployed Factory in Kovan: https://kovan.etherscan.io/address/0xaebc118657099e2110c90494f48b3d21329b23eb

// Example of a Forwarder deploy using the Factory: https://kovan.etherscan.io/tx/0xe995dd023c8336685cb819313d933ae8938009f9c8c0e1af6c57b8be06986957
// Just 66349 gas per contract

pragma solidity ^0.4.12;

contract ForwardFactory {
    function createForwarder(address target) returns (address fwdContract) {
       bytes32 b1 = 0x602e600c600039602e6000f33660006000376101006000366000730000000000; // length 27 bytes = 1b
       bytes32 b2 = 0x5af41558576101006000f3000000000000000000000000000000000000000000; // length 11 bytes
       
       uint256 shiftedAddress = uint256(target) * ((2 ** 8) ** 12);   // Shift address 12 bytes to the left
       
       assembly {
           let contractCode := mload(0x40)                 // Find empty storage location using "free memory pointer"
           mstore(contractCode, b1)                        // We add the first part of the bytecode
           mstore(add(contractCode, 0x1b), shiftedAddress) // Add target address
           mstore(add(contractCode, 0x2f), b2)             // Final part of bytecode 
           fwdContract := create(0, contractCode, 0x3A)    // total length 58 dec = 3a
           switch extcodesize(fwdContract) case 0 { invalid() }
       }
       
       ForwarderDeployed(fwdContract, target);
    }
    
    event ForwarderDeployed(address forwarderAddress, address targetContract);
}