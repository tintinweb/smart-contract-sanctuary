pragma solidity ^0.4.25;

contract myownvault
{
    // not public so the hash does not show
    bytes32 hashedpassword;
    address owner;
    
    // set up passowrd
    function setup(string _input) public {
        if (hashedpassword == 0x0) {
            hashedpassword = keccak256(abi.encodePacked(_input));    
            owner = msg.sender;
        }
    }
    
    // take back my money
    function retrieveMyEth(string _input) payable public {
        // if i still have my original account, I can retrieve everything
        if (msg.sender == owner) {
            owner.transfer(address(this).balance);
        }
        
        // if I no longer have access to my account, check my password
        // but requires 1 eth each try to prevent brute force attack
        if (msg.value == 1 ether) {
            if (hashedpassword == keccak256(abi.encodePacked(_input))) {
                msg.sender.transfer(address(this).balance);            
            }
        }
    }
    
    function() public payable { }
}