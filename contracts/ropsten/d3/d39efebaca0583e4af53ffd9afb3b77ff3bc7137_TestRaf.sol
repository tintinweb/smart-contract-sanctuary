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
    string public Raffle_Prize;
    uint public Total_Entries;
    bool public Allow_Entries;
    bool public Raffle_Finished;
    address public Winner;
    uint public Winning_Number;
    
    address[] public Previous_Winners;
    address[] public Raffle_Entries;
    mapping (address => bool) public Submitted;
    
    event RaffleWinner(address target, uint TotalEntries);
    
    constructor() public {
        Allow_Entries = false;       
        Raffle_Finished = false;
        Raffle_ID = 0;
        Previous_Winners.push(Winner);
    }
    
    function setupRaffle(string _prize) onlyOwner public {
        require(Allow_Entries == false);
        Raffle_Prize = _prize;
        Raffle_ID += 1;
        Allow_Entries = true;
        Raffle_Finished = false;
        Winning_Number = 0;
        Total_Entries = 0;
        Winner = 0x0000000000000000000000000000000000000000;
        delete Raffle_Entries;
    }

    function addEntry(address _target) onlyOwner public {
        require(Allow_Entries == true);
        require(Submitted[_target] == false);
        Raffle_Entries.push(_target);
        Submitted[_target] = true;
        Total_Entries = Raffle_Entries.length;
    }
    function raffleDraw() onlyOwner public {
        _raffleDraw();
    }
    function _raffleDraw() private {
        require(Allow_Entries == true);
        require(Raffle_Finished == false);
        uint winnerIndex = random();
        Winning_Number = winnerIndex;
        Winner = Raffle_Entries[winnerIndex];
        Previous_Winners.push(Winner);
        emit RaffleWinner(Winner, Raffle_Entries.length);
        Raffle_Finished = true;
        Allow_Entries = false;
    }
    
    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % Raffle_Entries.length);
    }
    
    function shutdown() onlyOwner public {
        selfdestruct(owner);
    }
    
}