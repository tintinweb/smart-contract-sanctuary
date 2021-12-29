/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.5.0;

contract Hold{
    mapping(address => uint) public heldAmount;
    address admin;
    uint maturity;

    constructor() public {
        admin = msg.sender;
        maturity = block.timestamp + 60;
    }

    function isMatured() public view returns (bool){
        return block.timestamp>=maturity;
    }
    modifier onlyAdmin(){
        require(msg.sender==admin,'Admins only');
        _;
    }
    function updateMaturity(uint _seconds) onlyAdmin external{
        maturity = block.timestamp + _seconds;
    }
    function deposit() external payable{
        require(msg.value>=0,'No Amount Entered');
        heldAmount[msg.sender] = msg.value;
    }

    function withdraw() external{
        require(heldAmount[msg.sender]>0, 'Insufficient balance');
        require(block.timestamp>=maturity,'Too early to withdraw');
        msg.sender.transfer(heldAmount[msg.sender]);
    }
}