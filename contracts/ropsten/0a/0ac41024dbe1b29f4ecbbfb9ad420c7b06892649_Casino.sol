pragma solidity 0.4.24;

contract Casino {
    address public owner;

    uint public minimumBet = 1;
    uint public totalBet;
    uint public numberOfBets;
    uint public maxAmountOfBets = 10;
    address[] public players;

    struct Player {
        uint amountBet;
        uint numberSelected;
    }

    // The address of the player and => the user info   
    mapping(address => Player) public playerInfo;

    constructor(uint _minimumBet) public {
        require(_minimumBet >= minimumBet);

        owner = msg.sender;
        minimumBet = _minimumBet;
    }

    function kill() public {
        if(msg.sender == owner) selfdestruct(owner);
    }

    // To bet for a number between 1 and 10 both inclusive
    function bet(uint256 numberSelected) public payable {
        uint _amount = msg.value;
        address _player = msg.sender;

        require(!checkPlayerExists(_player));
        require(numberSelected >= 1 && numberSelected <= 10);
        require(_amount >= minimumBet);
        playerInfo[_player].amountBet = _amount;
        playerInfo[_player].numberSelected = numberSelected;
        numberOfBets++;
        players.push(_player);
        totalBet += _amount;

        if(numberOfBets >= maxAmountOfBets) generateNumberWinner();
    }

    function checkPlayerExists(address player) public view returns(bool){
        for(uint i = 0; i < players.length; i++){
            if(players[i] == player) return true;
        }
        return false;
    }

    // Generates a number between 1 and 10 that will be the winner
    function generateNumberWinner() public {
        uint256 numberGenerated = block.number % 10 + 1; // This isn&#39;t secure
        distributePrizes(numberGenerated);
    }

    // Sends the corresponding ether to each winner depending on the total bets
    function distributePrizes(uint256 numberWinner) public {
        address[100] memory winners; // We have to create a temporary in memory array with fixed size
        uint count = 0; // This is the count for the array of winners
        for(uint i = 0; i < players.length; i++){
            address playerAddress = players[i];
            if(playerInfo[playerAddress].numberSelected == numberWinner){
                winners[count] = playerAddress;
                count++;
            }
            delete playerInfo[playerAddress]; // Delete all the players
        }
        players.length = 0; // Delete all the players array
        uint winnerEtherAmount = totalBet / winners.length; // How much each winner gets
        for(uint256 j = 0; j < count; j++){
            if(winners[j] != address(0)) // Check that the address in this fixed array is not empty
            winners[j].transfer(winnerEtherAmount);
        }

        totalBet = 0;
        numberOfBets = 0;
    }

    function() public payable {}
}