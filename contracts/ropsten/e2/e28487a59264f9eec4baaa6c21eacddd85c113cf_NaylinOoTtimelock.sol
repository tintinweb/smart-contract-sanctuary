/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

//SPDX-License-Identifier:MIT 


pragma solidity ^0.6.0;

contract NaylinOoTtimelock {

    
    mapping (address => uint256) private balances;
    mapping (address => uint256) private locktime;

    

    function depositSeconds(uint256 lockseconds) public payable {
        require(lockseconds < 24*60*60);
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = balance + msg.value;
        if(balance == 0) {
            locktime[msg.sender] += ( now + lockseconds );
        } else {
            locktime[msg.sender] += ( lockseconds );
        }
    }

    function balance() public view returns(uint){
        return balances[msg.sender];
    }



    function withdraw() external {
        require(balances[msg.sender] > 0,"No funds in account");
        require(block.timestamp > locktime[msg.sender],"Too soon to withdraw");
        uint256 amount = balances[msg.sender];
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success, "Transfer failed.");
    }

    

    
    


    
}