/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

pragma solidity 0.5.0;

contract Proxy {
    address private targetAddress;

    address private admin;
    constructor() public {
        targetAddress = 0x75187dbC3E2d5e49b3D4F8ee8980937cbbf382eD;
        admin = msg.sender;
    }

    function setTargetAddress(address _address) public {
        require(msg.sender==admin , "Admin only function");
        require(_address != address(0));
        targetAddress = _address;
    }
    
    function setOwner(address _address) public {
        require(msg.sender==admin , "Admin only function");
        require(_address != address(0));
        admin = _address;
    }

    function getContAdr() public view returns (address) {
        return targetAddress;
    }
    
    function () external payable {
        address contractAddr = targetAddress;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, contractAddr, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}