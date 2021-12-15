/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract BrzRpc {

    address private owner;
    bool private saleIsActive = false;
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
    
    function flipSaleState() public isOwner {
        saleIsActive = !saleIsActive;
    }

    function mint() external isOwner view returns(bool) { 
        require(saleIsActive, "Sale is not active");
        return true;
    }
}