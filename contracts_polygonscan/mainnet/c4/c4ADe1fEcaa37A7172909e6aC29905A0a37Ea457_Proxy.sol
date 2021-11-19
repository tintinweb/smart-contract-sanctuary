//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Storage.sol";
import "./Ownable.sol";
contract Proxy is Storage, Ownable {
    address public currentAddress;
    constructor(address _currentAddress, address multisigAddress, address payable _pay) {
        currentAddress = _currentAddress;
        _multisig = multisigAddress;
        pay = _pay;
    }
    
    function changePay(address payable _newPay) public onlyMultisig {
        pay = _newPay;
    }

    function upgrade(address _newAddress) public onlyMultisig{
        require(_newAddress != address(0), "Proxy: new address is the zero address");
        require(_newAddress != currentAddress, "Proxy: new address is already current address");
        
        currentAddress = _newAddress;
    }

    fallback () payable external {
        //Redirect to current address
        address implementation = currentAddress;
        require(currentAddress != address(0));
        bytes memory _data = msg.data;

        assembly {
            let result := delegatecall(gas(), implementation, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize()
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result 
            case 0 {revert(ptr, size)}
            default {return(ptr, size)}
        }
    }
    
     receive() external payable virtual { }
    
}