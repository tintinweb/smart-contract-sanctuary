/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.1;

contract Peppe{
    bytes32 public answer_hash;
    uint public attempts_count;
    
    constructor(string memory cleartext_answer) payable{
        answer_hash = keccak256(abi.encodePacked(cleartext_answer));
    }
    
    function get_attempts() public view returns (uint) {
        return attempts_count;
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function insert_passphrase(string memory _passphrase) external returns (uint){
        attempts_count += 1;
        require(keccak256(abi.encodePacked(_passphrase)) == answer_hash, "Wrong passphrase; hey, you are not Peppe!");
        uint amount = address(this).balance;
        require(amount>0, "Correct passphrase! Unfortunately, the prize was already collected :(");
        address sender = msg.sender; // address of the caller
        (bool sent,) = payable(sender).call{value: amount}("");
        require(sent, "Failed to send Ether");
        return amount;
    }
}