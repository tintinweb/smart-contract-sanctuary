/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

pragma solidity 0.8.0;

contract AddressSetter {
    
    address public _address;
    
    function setAddress() public { 
        require(_address == 0x0000000000000000000000000000000000000000, "address has already been set");
        _address = msg.sender;
    }
    
    function whatIsTheAddress() public view returns (address) {
        return _address;
    }
      
}