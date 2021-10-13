/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

pragma solidity >=0.4.22;

contract EthInteraction {
    mapping(address => bytes32) public students;
    address owner;

    // modifier onlyOwner {
    //     require(msg.sender == owner);
    //     _;
    // }

    constructor () public {
        owner = msg.sender;
    }

    function put (string token) public {
        students[msg.sender] = keccak256(abi.encodePacked(token));
    }
    
    // function get (string memory s_addr) onlyOwner public {
    //     students[s_addr]
    // }
}