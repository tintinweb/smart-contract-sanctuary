pragma solidity ^0.4.11;

contract mortal
{
    address owner;

    function mortal() { owner = msg.sender; }
    function kill() { if(msg.sender == owner) selfdestruct(owner); }
}

contract myTime is mortal
{
    uint deployTime;

    /* Constructor */
    function myTime() public
    {
        deployTime = block.timestamp;
    }

    function getDeploytimeBlocktimeBlocknumber() constant returns (uint, uint, uint)
    {
        return (deployTime, block.timestamp, block.number);
    }

}