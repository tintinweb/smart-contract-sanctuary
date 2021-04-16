/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity ^0.6.2;

contract Map {
    
    mapping(string => address) public addressMap;
    
    function setAddressMap(string memory _coinaddress) public {
        require(
            addressMap[_coinaddress] == address(0),
            "Address already mapped"
        );
        addressMap[_coinaddress] = msg.sender;
    }
    
}