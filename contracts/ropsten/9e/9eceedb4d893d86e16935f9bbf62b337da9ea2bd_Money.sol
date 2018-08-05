pragma solidity ^0.4.24;
contract Money{
    
    uint256 public saved_money;
    
    event Send(uint256 money);
    
    
    function addMoney(uint256 value) external {
        saved_money = value;
        emit Send(saved_money);
    }
}