/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract wallet {
    uint256 public number;
    string public hi;
    address public owner;
    event Deposited(address depositor,uint i1n);

    function assign(uint256 num,string memory hello) external{
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
        emit Deposited(msg.sender,msg.value);
        return msg.value;
    }
    
    function withdraw(uint amount) public returns(uint amountSentOut){
        payable(msg.sender).transfer(amount);
        return amount;
    }
    
    receive() external payable{
        owner = msg.sender;
    }
}