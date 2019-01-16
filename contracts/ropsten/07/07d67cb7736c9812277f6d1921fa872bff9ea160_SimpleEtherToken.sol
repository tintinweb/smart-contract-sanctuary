pragma solidity ^0.5.0;


contract SimpleEtherToken {
    string constant public name = "SimpleEtherToken";
    string constant public symbol = "SETH";
    uint8 constant public decimals = 18;
    
    mapping (address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint amount);
    
    function () external payable {
        if (msg.value > 0) {
            balanceOf[msg.sender] += msg.value;
            emit Transfer(address(0), msg.sender, msg.value);
        } else {
            msg.sender.transfer(balanceOf[msg.sender]);
            balanceOf[msg.sender] = 0;
            emit Transfer(msg.sender, address(0), msg.value);
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