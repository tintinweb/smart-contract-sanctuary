pragma solidity ^0.4.23;

// File: contracts/utilities/DepositAddressRegistrar.sol

interface Registry {
    function setAttributeValue(address who, bytes32 what, uint val) external;
    function hasAttribute(address _who, bytes32 _attribute) external view returns(bool);
}

contract DepositAddressRegistrar {
    Registry public registry;
    
    bytes32 public constant IS_DEPOSIT_ADDRESS = "isDepositAddress"; 
    event DepositAddressRegistered(address registeredAddress);

    constructor(address _registry) public {
        registry = Registry(_registry);
    }
    
    function registerDepositAddress() public {
        address shiftedAddress = address(uint(msg.sender) >> 20);
        require(!registry.hasAttribute(shiftedAddress, IS_DEPOSIT_ADDRESS), "deposit address already registered");
        registry.setAttributeValue(shiftedAddress, IS_DEPOSIT_ADDRESS, uint(msg.sender));
        emit DepositAddressRegistered(msg.sender);
    }
    
    function() external payable {
        registerDepositAddress();
        msg.sender.transfer(msg.value);
    }
}