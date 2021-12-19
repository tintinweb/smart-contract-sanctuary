/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

pragma solidity ^0.8.10;

contract MyRegistry {

    mapping ( string => address ) public registry;
    
    event Registered(address registrant, string domain);

    function registerDomain(string memory domain) public {
        // Can only reserve new unregistered domain names
        require(registry[domain] == address(0));
        
        // Update the owner of this domain
        registry[domain] = msg.sender;
        
        emit Registered(msg.sender, domain);
    }
}