/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MNS {
    
    uint public price = 0*10**18;
    mapping(string => address) public domains;
    address private owner;
    bool public alive;
    
    constructor() {
        owner = msg.sender;
        alive = false;
    }
    
    modifier onlyOwner() {
        require(msg.sender==owner, 'You are not the owner of this contract.');
        _;
    }
    
    function enable() public onlyOwner {
        alive = true;
    }
    function disable() public onlyOwner {
        alive = false;
    }
    
    function exists(string memory domain) public view returns(bool) {
        return domains[domain]!=address(0x0);
    }
    
    function find(string memory domain) public view returns(address) {
        return domains[domain];
    }
    
    function register(string memory domain) public payable {
        require(alive, 'Registrations are closed for now.');
        require(domains[domain]==address(0x0), 'This domain name is already used.');
        require(msg.value >= price, 'The value sent is less than the required price.');
        
        domains[domain] = msg.sender;
    }
    
    
    function transfer(string memory domain, address _to) public {
        require(domains[domain]==msg.sender, 'You cannot modify ownership on a domain that is not yours !');
        domains[domain] = _to;
    }
    
    function renounce(string memory domain) public {
        transfer(domain, address(0x0));
    }
    
    // Private Mint pour les owners de faction par exemple, pour avoir des adresses officielles
    function privateMint(string memory domain, address _to) public onlyOwner {
        domains[domain] = _to;
    }
    
    
    
}