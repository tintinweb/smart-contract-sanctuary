// Ethertote - Token Burn contract


// -----------------------------------------------------------------------------
// The following contract allows unsold tokens as part of the token sale
// to be permantnely locked ("burned") so that nobody is able to retrieve them

// This is achieved by passing ownership of the contract to a null address (0x0)
// using the constructor function when the contract is deployed onto the blockchain

// The contract uses a default fallback function to accept Eth and Tokens 
// and the Ethertote team will not be able to retrieve any Eth or tokens sent
// to this contract.

// We decided to use this smart contract in favour of allowing tokens to 
// be sent to the null account of 0x0, as this prevents anyone from ever 
// accidentally sending their own TOTE tokens to 0x0. IF they did this
// accidentally it would throw and the tokens would not be sent there.

// The ERC20 compliant transfer() and transferFrom() function prevent any tokens
// from ever being sent to 0x0
// -----------------------------------------------------------------------------

pragma solidity 0.4.24;

contract TokenBurn {
    
    address public thisContractAddress;
    address public admin;
    
    // upon deployment, ownership of this contract is immediately given to the 
    // null address
    address public newOwner = 0x0000000000000000000000000000000000000000;
    
    // MODIFIERS
    modifier onlyAdmin { 
        require(msg.sender == admin
        ); 
        _; 
    }
    
    // constructor executed upon deployment to the blockchain
    constructor() public {
        thisContractAddress = address(this);
        admin = newOwner;
    }
    
    // FALLBACK - allows Eth and tokens to be sent to this address
    function () private payable {}
  
}