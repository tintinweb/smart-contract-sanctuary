/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract RedGrapeJuice {
    uint256 s;
    address owner;
    constructor(uint256 init) public {
        // invoke when deploy on blockchain first time 
        s = init;
        owner = msg.sender;
    }
    
    function add(uint256 val) public {
        require(msg.sender == owner);
        s += val;
    }
    function getValue() public view returns(uint256){
        return s;
    }
}