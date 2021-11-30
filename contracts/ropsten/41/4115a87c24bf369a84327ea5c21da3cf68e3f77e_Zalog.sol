/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

pragma solidity 0.5.1;
contract Zalog {
    address owner;
    mapping(address => uint) balances;
    
    function Bank() public {
        owner = msg.sender;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }


    function getMyBalance() public view returns(uint) {
        return balances[msg.sender];
    }

    
}