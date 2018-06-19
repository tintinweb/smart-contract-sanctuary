pragma solidity ^0.4.14;

contract Owned
{
    address public owner;
    
    function Owned()
    {
        owner = msg.sender;
    }
    
    modifier onlyOwner()
    {
        if (msg.sender != owner) revert();
        _;
    }
}

contract ProspectorsDevAllocation is Owned
{
    ProspectorsGoldToken public token;
    uint public initial_time;

    mapping(uint => bool) public unlocked;
    mapping(uint => uint) public unlock_times;
    mapping(uint => uint) unlock_values;
    
    //contract with PGL tokens for Prospectors developers. Tokens will be frozen up to 4 years
    function ProspectorsDevAllocation(address _token)
    {
        token = ProspectorsGoldToken(_token);
    }
    
    function init() onlyOwner
    {
        if (token.balanceOf(this) == 0 || initial_time != 0) revert();
        initial_time = block.timestamp;
        uint unlock_amount = token.balanceOf(this) / 5; //one part - 20% of tokens

        unlock_values[0] = unlock_amount;
        unlock_values[1] = unlock_amount;
        unlock_values[2] = unlock_amount;
        unlock_values[3] = unlock_amount;
        unlock_values[4] = unlock_amount;
        
        unlock_times[0] = 180 days; //20% of tokens will be available after 180 days
        unlock_times[1] = 360 days; //20% of tokens will be available after 360 days
        unlock_times[2] = 720 days; //20% of tokens will be available after 2 years
        unlock_times[3] = 1080 days; //20% of tokens will be available after 3 years
        unlock_times[4] = 1440 days; //20% of tokens will be available after 4 years
    }

    function unlock(uint part)
    {
        if (unlocked[part] == true || block.timestamp < initial_time + unlock_times[part] || unlock_values[part] == 0) revert();
        token.transfer(owner, unlock_values[part]);
        unlocked[part] = true;
    }
}

contract ProspectorsGoldToken {
    function balanceOf( address who ) constant returns (uint value);
    function transfer( address to, uint value) returns (bool ok);
}