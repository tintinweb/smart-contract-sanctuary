/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

pragma solidity ^0.6.12;

contract Mapping {

    mapping(string => address) private addressMap;


    function setAddressMap(string memory _coinaddress) public {

        addressMap[_coinaddress] = msg.sender;
    }

    function getAddressMap(string memory _coinAddress)
        public
        view
        returns (address)
    {
        return addressMap[_coinAddress];
    }
}