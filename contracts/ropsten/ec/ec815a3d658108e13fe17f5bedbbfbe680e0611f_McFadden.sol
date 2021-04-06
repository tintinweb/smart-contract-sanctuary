/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity >=0.7.0 <0.9.0;

contract McFadden {
    address payable public owner;
    string public url = "https://www.youtube.com/watch?v=2nmtB7rBs3M";
    uint64 price;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    constructor() {
        owner = payable(msg.sender);
        price = 1 ether;
        emit OwnerSet(address(0), owner);
    }
    
    function claim() payable external {
        require(msg.value >= price, "You gotta pay full price!");
        owner.transfer(msg.value);
        price += 1 ether;
        emit OwnerSet(owner, msg.sender);
        owner = payable(msg.sender);
    }
}