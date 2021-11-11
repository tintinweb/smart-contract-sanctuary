/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

pragma solidity ^0.8;

contract Proxy {
    event Deploy(address);
    
    fallback() external payable {}
    
    function deploy(bytes memory _code) external payable returns (address addr) {
        assembly {
            addr := create(callvalue(), add(_code, 0x20), mload(_code))       
        }
        // return address 0 on error
        require(addr != address(0), "deploy failed");
        
        emit Deploy(addr);
     }
    
    function execute(address _target, bytes memory _data)
        external
        payable
    {
        (bool success, ) = _target.call{value: msg.value}(_data);
        require(success, "failed");
    }
}