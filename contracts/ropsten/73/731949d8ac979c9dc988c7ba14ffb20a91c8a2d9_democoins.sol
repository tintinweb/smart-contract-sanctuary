/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract democoins {
    uint256 s;
    address owner;
    constructor(uint256 init) public {
        // Is called automatically when deploy
        s = init;
        owner = msg.sender;
    }
    
    // public keyword allow other smart contract to call this function
    function add(uint256 val) public {
        require(msg.sender == owner);
        s += val;
    }
    
    // view keywords allow other to view without gas needed
    function get() public view  returns(uint256){
        return s;
    }

}