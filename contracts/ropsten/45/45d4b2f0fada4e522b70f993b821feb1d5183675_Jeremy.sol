/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract Jeremy {
    // use int to collect decimal places.  need to have an agreed upon power of 10 (how many decimal places)
    // int a; // default is 256
    // uint b; // unsigned interger -> no negative
    // mapping (uint256 => string) c; //-> dict
    // address d; // ethereamAddress
    // mapping (uint256 => address) nft;
    // mapping (address => uint256) balance;
    
    // metamask will help sign the contract for deployment
    uint256 s;
    address owner;
    // get called when deployed
    constructor(uint256 init) public {
        s = init;
        owner = msg.sender; //address that makes the smart contract
    }
    
    function add(uint256 val) public {
        require(msg.sender == owner);
        s += val;
    }
    
    function getValue() public view returns (uint256) { // not collecting gas for the transaction
        return s;
    }
}