/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

pragma solidity 0.6.6;

contract Bank {
    address public owner;
    mapping(address => uint) private balances;
    
    constructor () public payable {
        owner = msg.sender;
    }
    
    function isOwner() public view returns(bool){
        return msg.sender == owner;
    }
    
    modifier onlyOwner(){
        require(isOwner());
        _;
    }
    
    function deposit() public payable{
        require((balances[msg.sender] + msg.value) >= balances[msg.sender]);
        balances[msg.sender] += msg.value;
    }
    
    function withdraw(uint withdrawAmount) public{
        require(withdrawAmount <= balances[msg.sender]);
        
        balances[msg.sender] -= withdrawAmount;
        msg.sender.transfer(withdrawAmount);
    }
    
    function withdrawAll() public onlyOwner{
        msg.sender.transfer(address(this).balance);
    }
    
    function getBalance() public view returns(uint){
        return balances[msg.sender];
    }
}