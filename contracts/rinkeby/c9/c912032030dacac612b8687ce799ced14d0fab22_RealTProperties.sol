/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

pragma solidity >=0.4.22 <0.7.0;

/**
 * title: Contract to track RealT properties
 * description: This contract is creating events that can be picked up by a subgraph to create an open API of RealT properties.
 */
 
contract RealTProperties {
   
   address public admin = 0xadAfC1e419D03c84661b00c022ecD0101F190172;

    /** Setters */ 
    function createProperty(string memory _name, address _contractAddress, string memory _city, string memory _cityAddress, uint _expectedYield, uint _rentPerTokenPerYear, uint _tokenSupply, uint _tokenPrice) public {
        // Only admin can perform this action
        require(msg.sender == admin);
        
        // Create new property event
        emit CreateProperty(_name, _contractAddress, _city, _cityAddress, _expectedYield, _rentPerTokenPerYear, _tokenSupply, _tokenPrice, now); 
    }
    
    function updateProperty(string memory _name, address _contractAddress, string memory _city, string memory _cityAddress, uint _expectedYield, uint _rentPerTokenPerYear, uint _tokenSupply, uint _tokenPrice) public {
        // Only admin can perform this action
        require(msg.sender == admin);
        
        // Update property event
        emit UpdateProperty(_name, _contractAddress, _city, _cityAddress, _expectedYield, _rentPerTokenPerYear, _tokenSupply, _tokenPrice, now);
    }
    
    /** Handle events */
    event CreateProperty(string name, address contractAddress, string city, string cityAddress, uint expectedYield, uint rentPerTokenPerYear, uint tokenSupply, uint tokenPrice, uint time);
    event UpdateProperty(string name, address contractAddress, string city, string cityAddress, uint expectedYield, uint rentPerTokenPerYear, uint tokenSupply, uint tokenPrice, uint time);
}