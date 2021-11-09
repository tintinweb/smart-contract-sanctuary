pragma solidity 0.6.10;
//SPDX-License-Identifier: MIT
import "./ERC20TokenTemplate.sol";

contract TokenGenerator {
    
    address[] public deployedTokensAddresses;
    address payable owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function generateToken(string memory _name, string memory _symbol, uint256 _decimals, uint256 _supply, address payable tokenOwner ) public returns(address) {
        require(keccak256(bytes(_name)) != keccak256(bytes("")) && keccak256(bytes(_symbol))!=keccak256(bytes("")) && _decimals>=0 && _supply > 0,"Check the inputs");
        require(address(this).balance > 0.05 ether,"Not enough balance in parent contract");
        address newToken = address(new ERC20TokenTemplate(_name,_symbol,_decimals, _supply, tokenOwner));
        deployedTokensAddresses.push(newToken);
        tokenOwner.transfer(0.05 ether);
        return newToken;
    }

    function getAllAddresses() public view returns (address[] memory){
        return deployedTokensAddresses;
    }

    function addMoney() public payable returns(string memory) {
        require(msg.sender == owner, "Only owner is allowed!");
        return 'added';
    }
    function withdraw() public {
        require(msg.sender == owner, "Only owner is allowed!");
        owner.transfer(address(this).balance);
    }
}