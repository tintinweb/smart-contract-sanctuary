/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

pragma solidity >=0.4.21 <0.7.0;

contract sendToMany{
    address public  owner;
    constructor() public {
        owner = msg.sender;
    }
    
    function investment2(address[] memory addresses) public payable {
        uint amount;
        for(uint8 i = 0; i < addresses.length; i++) {
           amount = msg.value/addresses.length;
            address(uint160(addresses[i])).transfer(amount);
            
        }
    }
}