pragma solidity ^0.4.23;

contract PartnerContract
{
    mapping(address => uint) private balances;
    
    function() external payable
    {
        if(msg.value > 0)
        {
            uint part = msg.value / 2;
            balances[0x28097585e3F4c94eb0da78293C7c83bDc9FD0968] += part;
            balances[0xe09f3630663B6b86e82D750b00206f8F8C6F8aD4] += part;
        }
        else
        {
            require(balances[msg.sender] > 0);
            
            uint sum = balances[msg.sender];
            balances[msg.sender] = 0;
            msg.sender.transfer(sum);
        }
    }
}