/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

pragma solidity >=0.7.0 <0.8.0;

contract Owner {

    address private owner;
    string private data = "Hello ABCD!";
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
    
    function getData() external view returns (string memory) {
        return data;
    }
    
}