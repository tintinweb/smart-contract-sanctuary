pragma solidity ^0.5.0;


contract SimpleEtherToken {
    mapping (address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint amount);
    
    function () external payable {
        if (msg.value > 0) {
            balanceOf[msg.sender] += msg.value;
        } else {
            msg.sender.transfer(balanceOf[msg.sender]);
            balanceOf[msg.sender] = 0;
        }
    }
    
    function transfer(address to, uint amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}