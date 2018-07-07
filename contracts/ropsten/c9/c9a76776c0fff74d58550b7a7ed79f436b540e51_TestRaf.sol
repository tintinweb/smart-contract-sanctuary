pragma solidity ^0.4.0;
contract owned {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract TestRaf is owned {
    
    uint public Raffle_ID;
    //string public Raffle_Prize;
    uint public Total_Entries;
    uint public Date_Started;
    bool public is_Started;
    bool public is_Finished;
    address public Winner;
    uint public blockNum;
    uint public getRand;
    
    uint[][] public RaffleEvents;
    address[] public RaffleWinners;
    address[] public RaffleEntries;
    mapping (address => bool) public Submitted;
    
    event RaffleWinner(address target, uint TotalEntries);

    constructor() public {
        is_Started = false;   
        is_Finished = false;
    }
    
    function SetupRaffle(uint _id) public {
        require(is_Started = false);
        //Raffle_Prize = _RafflePrize;
        Raffle_ID = _id;
        Date_Started = now;
        is_Started = true;
        is_Finished = false;
        RaffleEvents.push([Raffle_ID, Date_Started]);
        
        if(RaffleEntries.length > 0)
        {
            delete RaffleEntries;
        }
    }
    
    function () payable public {
        require(Submitted[msg.sender] == false);
        RaffleEntries.push(msg.sender);
        Submitted[msg.sender] = true;
        Total_Entries = RaffleEntries.length;
        blockNum = uint(blockhash(block.number-1));
        getRand = uint(blockhash(block.number-1)) % RaffleEntries.length;
    }
    function raffleDraw()  onlyOwner public {
        _raffleDraw();
    }
    function _raffleDraw() private {
        require(is_Started == true);
        require(is_Finished == false);
        blockNum = uint(blockhash(block.number-1));
        uint winnerIndex = uint(blockhash(block.number-1)) % RaffleEntries.length;
        Winner = RaffleEntries[winnerIndex];
        RaffleWinners.push(Winner);
        emit RaffleWinner(Winner, RaffleEntries.length);
        is_Finished = true;
        is_Started = false;
    }
    
    function shutdown() onlyOwner public {
        if (msg.sender == owner) {
            selfdestruct(owner);
        }
    }
    function reDraw() onlyOwner public {
        is_Finished = false;
        is_Started = true;
        _raffleDraw();
    }
    
}