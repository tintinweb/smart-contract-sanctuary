pragma solidity ^0.4.25;

contract ModifyWETH {
    
    address public owner;
    mapping (address => uint) public balanceOf;

    constructor() public {
       owner = msg.sender; 
    }
    
    // must modify balanceOf such that balanceOf the msg.sender is increased by msg.value
    function deposit () public payable {
       balanceOf[msg.sender] += msg.value; 
    }
    
    // Calls the deposit function IE. deposit()
    function() public payable {
        deposit();
    }
    
    //  withdraws the weth into senders account only if the sender has sufficient weth
    function withdraw(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }
    
    // transfers eth from msg.sender to dst address
    function transfer(address dst, uint256 amount) public returns (bool){
        require(balanceOf[dst] >= amount);
        
        balanceOf[msg.sender] -= amount;
        balanceOf[dst] += amount;
        return true;
    } 
    
    // returns total supply of weth
    function totalSupply() public view returns (uint) {
        
        return balanceOf[msg.sender];
        //return address(this).balance;
    }
    
}