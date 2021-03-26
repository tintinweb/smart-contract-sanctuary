/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity 0.5.0;

contract Proxy {
    address private targetAddress;

    address private admin;
    constructor() public {
        targetAddress = 0x04336D2731B263D0abb59A8AAE54017Fc3a04742;
        admin = msg.sender;
    }

    function setTargetAddress(address _address) public {
        require(msg.sender==admin , "Admin only function");
        require(_address != address(0));
        targetAddress = _address;
    }

    function getContAdr() public view returns (address) {
        require(msg.sender==admin , "Admin only function");
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