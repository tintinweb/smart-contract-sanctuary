/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

pragma solidity ^0.6.12;

contract Deployer {
    
    function onBehalf(bytes memory _bytecode, uint _salt) public payable {
        (bool res,) = msg.sender.delegatecall(abi.encodePacked(bytes4(keccak256("deploy(bytes, uint)")), _bytecode, _salt));
        if(!res) revert();
    }
    
    function deploy(bytes memory bytecode, uint _salt) public payable {
        address addr;

        assembly {
            addr := create2( callvalue(), add(bytecode, 0x20), mload(bytecode), _salt )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }
}