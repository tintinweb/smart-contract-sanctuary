/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity ^0.5.8;


contract Events {
    
    address custumAddress = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    string name;
    uint256 number = 5;
    
    event test(address custumAddress, string name, uint256 number);
    event test2(address indexed custumAddress, string indexed name, uint256 number);
        
    function setName(string memory newName) public {

        name = newName;


        emit test(custumAddress, name, number);
        emit test2(custumAddress, name, number);

    }


    function getName() public view returns (string memory) {

        return name;

    }
    
}