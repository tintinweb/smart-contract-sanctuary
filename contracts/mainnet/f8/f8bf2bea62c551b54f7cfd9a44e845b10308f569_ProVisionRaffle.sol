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

contract ProVisionRaffle is owned {
    
    uint public Raffle_ID;
    string public Raffle_Prize;
    uint public Total_Entries;
    bool public Allow_Entries;
    bool public Raffle_Finished;
    address public Winner;
    uint public Winning_Entry;
    uint public Date_Started;
    uint public Date_Finished;
    
    address[] public Raffle_Entries;
    mapping (address => bool) public Address_Submitted;
    
    event RaffleWinner(address target, uint TotalEntries);
    
    constructor() public {
        Raffle_ID = 70935284;
        Raffle_Prize = "iPhone X";
        Allow_Entries = true;       
        Raffle_Finished = false;
        Winning_Entry = 0;
        Total_Entries = 0;
        Date_Started = block.timestamp;
    }

    function addEntry(address _target) onlyOwner public {
        require(Allow_Entries == true);
        require(Address_Submitted[_target] == false);
        Raffle_Entries.push(_target);
        Address_Submitted[_target] = true;
        Total_Entries = Raffle_Entries.length;
    }
    function raffleDraw() onlyOwner public {
        _raffleDraw();
    }
    function _raffleDraw() private {
        require(Raffle_Finished == false);
        uint winnerIndex = random();
        Winning_Entry = winnerIndex;
        Winner = Raffle_Entries[winnerIndex];
        emit RaffleWinner(Winner, Raffle_Entries.length);
        Raffle_Finished = true;
        Allow_Entries = false;
        Date_Finished = block.timestamp;
    }
    
    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % Raffle_Entries.length);
    }
    
    function shutdown() onlyOwner public {
        selfdestruct(owner);
    }
}