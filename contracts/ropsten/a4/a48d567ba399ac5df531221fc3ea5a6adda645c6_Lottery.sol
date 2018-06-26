pragma solidity 0.4.24;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function Ownable() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Lottery is Ownable{
    uint public minBet;
    uint public totalBets;
    uint public maxPlayers;
    uint public numberofBets;
    uint public maxAmountofBets;
    address[] public players;

    struct Player {
        uint betAmount;
        uint numSelect;
    }

    // Mapping the address of player to his corresponding info
    mapping (address => Player) public playerInfo;

    function() public payable {}

    function kill() public {
        if(msg.sender == owner) selfdestruct(owner);
    }

    // constructor
    function Lottery(uint256 _minBet, uint _maxPlayers, uint _maxAmountofBets) public {
        owner = msg.sender;
        if (_minBet > 0 ) minBet = _minBet;
        maxPlayers = _maxPlayers;
        maxAmountofBets = _maxAmountofBets;
    }
    
    // betting for a number between 1 to 10
    function bet(uint numberSelect) public payable {
        require (numberSelect >= 1 && numberSelect <= 10);
        require (msg.value >= minBet);

        playerInfo[msg.sender].betAmount = msg.value;
        playerInfo[msg.sender].numSelect = numberSelect;
        numberofBets++;
        players.push(msg.sender);
        totalBets += msg.value;
        if(numberofBets >= maxAmountofBets) generateNum2Win();
    }
    // generating a number between 1 to 10 that will find the winner
    function generateNum2Win() public returns (uint){
        uint numberGenerated = uint (keccak256(msg.sender)) % 10;
        // distributePrices(numberGenerated);
        return numberGenerated;
    }
    
    function getPlayers(uint index) returns(address) {
        address location =  players[0];
        return location;
    }
    
    // send ether to each winner depending on total bets
    function distributePrices (uint numberWinner) public {
        // generate an array in memory of fixed size of winners by 
        // chceking if players.numSelect is the winning number
        address[10] memory winners;
        // count for array of winners
        uint count = 0;
        for(uint i = 0; i < players.length; i++){
            // check each players number selected
            address playerAddress = players[i];
            if (playerInfo[playerAddress].numSelect == numberWinner) {
                // add players address to winners array
                winners[count] = playerAddress;
                count ++;
            }
            // reset the game by deleting all players
            delete playerInfo[playerAddress];
        }
        // delete all players 
        players.length = 0;
        // Amount of ether each players get is total pool / amount of winners
        uint winnerEtherAmount = totalBets / winners.length;
        // transfer ether to each player
        for(uint j = 0; j < count; j++){
            winners[j].transfer(winnerEtherAmount);
        }
        totalBets = 0;
        numberofBets = 0;
    }
}