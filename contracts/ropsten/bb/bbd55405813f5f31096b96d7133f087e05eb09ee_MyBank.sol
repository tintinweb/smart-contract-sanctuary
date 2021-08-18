/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity 0.5.16;

contract MyBank {
    

    mapping (address=>uint) public deposits;
    uint public totalDeposits = 0;
    
    function deposit() public payable {
        deposits [msg.sender] = deposits [msg.sender] + msg.value;
        totalDeposits = totalDeposits + msg.value;
    }
    function withdraw(uint amount) public {
        require (amount <=deposits[msg.sender]);
        msg.sender. transfer (amount);
        deposits [msg.sender] = deposits [msg.sender] - amount;
        totalDeposits = totalDeposits - amount;
    }
}