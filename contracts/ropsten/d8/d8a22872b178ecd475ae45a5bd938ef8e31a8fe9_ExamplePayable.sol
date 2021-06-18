pragma solidity ^0.8.0;

import "./ERC20Example.sol";

contract ExamplePayable {
    mapping (address => bool) registeredPayableAddresses;
    mapping (address => uint256) registeredValuePayableAddresses;
    mapping (address => bool) registeredNonPayableAddresses;
    address payable currentReceiver;

    constructor(address payable receiver) { currentReceiver = receiver;}


    // It is important to also provide the
    // `payable` keyword here, otherwise the function will
    // automatically reject all Ether sent to it.
    function registerPayable() public payable {
        registeredPayableAddresses[msg.sender] = true;
        registeredValuePayableAddresses[msg.sender] = msg.value;
        currentReceiver.transfer(msg.value);
    }
    
     function registerNonPayable() public {
        registeredNonPayableAddresses[msg.sender] = true;
    }
    
    function isRegisteredAsPayableAddress (address addressSender) external view returns(bool){
        return registeredPayableAddresses[addressSender];
    }
    
     function registeredValueAsPayableAddress (address addressSender) external view returns(uint256){
        return registeredValuePayableAddresses[addressSender];
    }
    
     function getRegisteredAsNonPayableAddress (address addressSender) external view returns(bool){
        return registeredNonPayableAddresses[addressSender];
    }
    
     function getReceiver () external view returns(address){
        return currentReceiver;
    }

}