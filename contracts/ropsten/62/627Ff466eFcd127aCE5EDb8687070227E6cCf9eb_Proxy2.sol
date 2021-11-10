/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.25;

contract StorageStructure2 {
    address public implementation;
    address public owner;
    mapping (address => uint) internal points;
    uint internal totalPlayers;
    
}

contract Proxy2 is StorageStructure2 {
    
    //确保只有所有者可以运行这个函数
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
   //设置管理者owner地址
    constructor() public {
        owner = msg.sender;
    }
    
   //更新实现合约地址
    function upgradeTo(address _newImplementation) external onlyOwner {
        require(implementation != _newImplementation);
        _setImplementation(_newImplementation);
    }
    
   //回调
    function () payable public {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
    
    //设置当前实现地址
    function _setImplementation(address _newImp) internal {
        implementation = _newImp;
    }
}