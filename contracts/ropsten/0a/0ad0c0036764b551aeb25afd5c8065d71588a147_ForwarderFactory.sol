pragma solidity ^0.4.21;

// File: contracts/Forwarder.sol

contract Forwarder {
    // Address to which any funds (ETH) sent to this contract will be forwarded
    address public beneficiary;

    event Transfer(address _to, uint _value);
    /**
    * Create the contract, and sets the destination address to that of the creator
    */
    function Forwarder(address _beneficiary) public {
        beneficiary = _beneficiary;
    }

    /**
    * Default function; Gets called when Ether is deposited, and forwards it to the parent address
    */
    function() public payable {
        // throws on failure
        beneficiary.transfer(msg.value);

        emit Transfer(beneficiary, msg.value);
    }
}

// File: contracts/ForwarderFactory.sol

contract ForwarderFactory {

    event ContractDeployed(address forwarderAddress, address beneficiaryAddress);
    
    function create(address beneficiary, uint256 number) public {
    
        for (uint256 i = 0; i < number; i++) { 
            emit ContractDeployed(new Forwarder(beneficiary), beneficiary);
        }
        
    }
}