pragma solidity ^0.6.1;

contract Owned {
    constructor() public { owner = msg.sender; }
    address payable public owner;

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    /**
    * Allow the owner of this contract to transfer ownership to another address
    * @param newOwner The address of the new owner
    */
    function transferOwnership(address payable newOwner) external onlyOwner {
        owner = newOwner;
    }
}
