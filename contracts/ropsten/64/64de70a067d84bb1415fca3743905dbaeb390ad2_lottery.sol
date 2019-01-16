pragma solidity ^0.4.25;

contract lottery
{
    address public creator;
    uint public numEntered;
    address[5] public participants;
    uint public amount;

    constructor() public
    {
        creator = msg.sender;
        numEntered = 0;
        amount = 0;
    }

    function restartLottery() private
    {
        numEntered = 0;
        amount = 0;
    }

    function setCount(uint x) private
    {
        numEntered = x;
    }

    function getCount() public view returns(uint) 
    {
        return numEntered;
    }
    
    function getBalance() public view returns (uint)
    {
        return amount;
    }

    function enterLottey() public payable
    {
        participants[getCount() + 1] = msg.sender;
        amount += msg.value;
        setCount(getCount() + 1);
        if(getCount() == 5)
        {
            getWinner();
        }
        return;
    }

    function getWinner() public payable
    {
        address winner = participants[(random()%5)];
        winner.transfer(getBalance());
        restartLottery();
        return;
    }

    function random() private view returns(uint) 
    {
        return uint(keccak256(block.difficulty, block.timestamp, participants));
    }

}