pragma solidity ^0.4.25;

contract modifiedWeth {
    
    address public owner;
    
    mapping (address => uint ) public balanceOf;

    constructor () public {
    
        owner = msg.sender;

    }

    function deposit() public payable {

        balanceOf[msg.sender] += msg.value;
    }

    function () public payable {

        deposit();

    }

    function withdraw(uint amount) public {

        require(balanceOf[msg.sender] >= amount);

        balanceOf[msg.sender] -= amount; 
        
        msg.sender.transfer(amount);
    }

    function transfer(address dst, uint amount) public  returns (bool) {

        require(balanceOf[msg.sender] >= amount);

        balanceOf[msg.sender] -= amount;

        balanceOf[dst] += amount;

        return true;

    }

    function totalSupply() public view returns (uint) {


        return  address(this).balance;
        
    }
}