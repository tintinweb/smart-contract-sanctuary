/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract ObitoFinance{
    uint256 s;
    address owner;
    
    constructor(uint init) public{ // It is called when deploy.
        s = init;
        owner = msg.sender;
    }
    
    function add(uint val) public {
    	require(msg.sender == owner);
        s += val;
    }
    function getValue() public view returns (uint256){
    	return s;
    }
}