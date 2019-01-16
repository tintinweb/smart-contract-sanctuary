pragma solidity ^0.4.24;

contract HappyNewyear {
    event HappyNewYear(address indexed _owner,  string _greetings);
    
    
    function happyNewYear() public {
        emit HappyNewYear(msg.sender, "祝大家新年快乐！");
    }
}