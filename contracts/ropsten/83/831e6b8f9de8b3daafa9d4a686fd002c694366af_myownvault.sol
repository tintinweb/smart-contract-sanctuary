pragma solidity ^0.4.25;

contract myownvault
{
    // not public so the hash does not show
    bytes32 hashedpassword;
    
    // set up passowrd
    function setup(string _input) public {
        if (hashedpassword == 0x0) {
            hashedpassword = keccak256(abi.encodePacked(_input));            
        }
    }
    
    // take back my money
    function retrieveMyEth(string _input) payable public {
        // requires 1 ether with transaction to prevent people from attempting
        if (msg.value == 1 ether) {
            if (hashedpassword == keccak256(abi.encodePacked(_input))) {
                msg.sender.transfer(address(this).balance);            
            }
        }
    }
    
    function() public payable { }
}