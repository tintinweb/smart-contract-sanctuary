/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

pragma solidity >=0.8.7 <0.9.0;

contract DeployFactory {
    
    event Deployed(address addr);

    function deploy(bytes32 salt, bytes memory bytecode) public {
        bytes memory bytecodeWithConstructor = abi.encodePacked(bytecode, abi.encode(msg.sender));
        address addr;
      
        assembly {
            addr := create2(0, add(bytecodeWithConstructor, 0x20), mload(bytecodeWithConstructor), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        
        emit Deployed(addr);
    }
}