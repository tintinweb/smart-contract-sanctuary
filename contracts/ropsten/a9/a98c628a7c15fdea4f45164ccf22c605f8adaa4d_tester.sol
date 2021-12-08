/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity ^0.8;

contract tester {
   
    uint256 public totalSupply = 1;

    event Minted(uint256 _amount, address indexed _address);

    constructor () payable {
        require(msg.value == 0.0 ether, "Ether needed.");
    }

    function pay() public payable {
        require(totalSupply < 10, "All minted.");

        emit Minted(msg.value, msg.sender);

        totalSupply += 1;   
    }   
}