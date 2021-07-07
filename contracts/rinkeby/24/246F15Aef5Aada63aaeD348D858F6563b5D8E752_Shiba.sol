/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Shiba {

    uint256 number;
    string hi;
    event deposited(address depositor, uint i1n);

    /**
     * @dev Store value in variable
     * @param num value to store
     */
     function buy(uint256 num,string memory hello) public {
        number = num;
        hi = hello;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function rugpull() public view returns (uint256,string memory){
        
        return (number,hi);
    }

    function deposit() public payable returns(uint amountSentIn){
        return msg.value;
    }

    function withdraw(uint amount) public returns(uint aountSentOut){
        payable(msg.sender).transfer(amount);
        return amount;
    }
    
    receive() external payable{
        
    }
}