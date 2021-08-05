/**
 *Submitted for verification at Etherscan.io on 2020-05-22
*/

pragma solidity >=0.4.22 <0.7.0;

contract Owner {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}