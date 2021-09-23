/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0; // koja verzija sooliditi compilera se izvršava

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */

contract Storage {

    uint256 number;
    uint256 current_fee = 0.0001 ether;
    uint256 max_fee = 0.01 ether;
    
    struct NumberOwner{
        uint256 number;
        address owner;
    }
    address payable contract_owner;
    
    NumberOwner[] public number_owners;

    
    uint256[] public numbers;
    
    constructor() {
        contract_owner = payable(msg.sender);
    }
    
    function withdraw() external payable onlyOwner{
        contract_owner.transfer(0.01 ether);
    }
    
    modifier onlyOwner() {
        require(msg.sender==contract_owner);
        _;
    }
    
    function store(uint256 num, uint256 new_fee) public payable { 
        require(msg.value >= current_fee);
        require(new_fee <= max_fee);
        
        NumberOwner memory new_number_owner;
        
        current_fee = new_fee;

        new_number_owner.number = num;
        
        new_number_owner.owner = msg.sender;
        
        number = num;
        
        number_owners.push(new_number_owner);
        
        
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    
    }
}