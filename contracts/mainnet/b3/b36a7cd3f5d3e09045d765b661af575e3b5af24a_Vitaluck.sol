pragma solidity ^0.4.24;

/*
 _    _      _                              _        
| |  | |    | |                            | |       
| |  | | ___| | ___ ___  _ __ ___   ___    | |_ ___  
| |/\| |/ _ | |/ __/ _ \| &#39;_ ` _ \ / _ \   | __/ _ \ 
\  /\  |  __| | (_| (_) | | | | | |  __/   | || (_) |
 \/  \/ \___|_|\___\___/|_| |_| |_|\___|    \__\___/            


$$\    $$\ $$\   $$\               $$\                     $$\       
$$ |   $$ |\__|  $$ |              $$ |                    $$ |      
$$ |   $$ |$$\ $$$$$$\    $$$$$$\  $$ |$$\   $$\  $$$$$$$\ $$ |  $$\ 
\$$\  $$  |$$ |\_$$  _|   \____$$\ $$ |$$ |  $$ |$$  _____|$$ | $$  |
 \$$\$$  / $$ |  $$ |     $$$$$$$ |$$ |$$ |  $$ |$$ /      $$$$$$  / 
  \$$$  /  $$ |  $$ |$$\ $$  __$$ |$$ |$$ |  $$ |$$ |      $$  _$$<  
   \$  /   $$ |  \$$$$  |\$$$$$$$ |$$ |\$$$$$$  |\$$$$$$$\ $$ | \$$\ 
    \_/    \__|   \____/  \_______|\__| \______/  \_______|\__|  \__|


This is the main contract for the Vitaluck button game. 
You can access it here: https://vitaluck.com
*/

contract Vitaluck {
    
    //
    // Admin
    //

    address ownerAddress = 0x3dcd6f0d7860f93b8bb7d6dcb85346c814243d63;
    address cfoAddress = 0x5b665218efCE2a15BD64Bd1dE50a27286f456863;
    
    modifier onlyCeo() {
        require (msg.sender == ownerAddress);
        _;
    }
    
    //
    // Events
    //
    
    event NewPress(address player, uint countPress, uint256 pricePaid, uint32 _timerEnd);

    //
    // Game
    //

    uint countPresses;
    uint256 countInvestorDividends;

    uint amountPlayed;

    uint32 timerEnd;                                        // The timestamp for the end after this time stamp, the winner can withdraw its reward
    uint32 timerInterval = 21600;                           // We set the interval of 3h

    address winningAddress;
    uint256 buttonBasePrice = 20000000000000000;              // This is the current price for a button press (this is updated every 100 presses)
    uint256 buttonPriceStep = 2000000000000000;
    //
    // Mapping for the players
    //
    struct Player {
        address playerAddress;                              // We save the address of the player
        uint countVTL;                                      // The count of VTL Tokens (should be the same as the count of presses)
    }
    Player[] players;
    mapping (address => uint) public playersToId;      // We map the player address to its id to make it easier to retrieve

    //
    // Core
    //

    // This function is called when a player sends ETH directly to the contract
    function() public payable {
        // We calculate the correct amount of presses
        uint _countPress = msg.value / getButtonPrice();
        
        // We call the function
        Press(_countPress, 0);
    }
        
    // We use this function to initially fund the contract
    function FundContract() public payable {
        
    }
    
    // This function is being called when a user presses the button on the website (or call it directly from the contract)
    function Press(uint _countPresses, uint _affId) public payable {
        // We verify that the _countPress value is not < 1
        require(_countPresses >= 1);
        
        // We double check that the players aren&#39;t trying to send small amount of ETH to press the button
        require(msg.value >= buttonBasePrice);
        
        // We verify that the game is not finished.
        require(timerEnd > now);

        // We verify that the value paid is correct.
        uint256 _buttonPrice = getButtonPrice();
        require(msg.value >= safeMultiply(_buttonPrice, _countPresses));

        // Process the button press
        timerEnd = uint32(now + timerInterval);
        winningAddress = msg.sender;

        // Transfer the commissions to affiliate, investor, pot and dev
        uint256 TwoPercentCom = (msg.value / 100) * 2;
        uint256 TenPercentCom = msg.value / 10;
        uint256 FifteenPercentCom = (msg.value / 100) * 15;
        

        // Commission #1. Affiliate
        if(_affId > 0 && _affId < players.length) {
            // If there is an affiliate we transfer his commission otherwise we keep the commission in the pot
            players[_affId].playerAddress.transfer(TenPercentCom);
        }
        // Commission #2. Main investor
        uint[] memory mainInvestors = GetMainInvestor();
        uint mainInvestor = mainInvestors[0];
        players[mainInvestor].playerAddress.transfer(FifteenPercentCom);
        countInvestorDividends = countInvestorDividends + FifteenPercentCom;
        
        // Commission #3. 2 to 10 main investors
        // We loop through all of the top 10 investors and send them their commission
        for(uint i = 1; i < mainInvestors.length; i++) {
            if(mainInvestors[i] != 0) {
                uint _investorId = mainInvestors[i];
                players[_investorId].playerAddress.transfer(TwoPercentCom);
                countInvestorDividends = countInvestorDividends + TwoPercentCom;
            }
        }

        // Commission #4. Dev
        cfoAddress.transfer(FifteenPercentCom);

        // Update or create the player and issue the VTL Tokens
        if(playersToId[msg.sender] > 0) {
            // Player exists, update data
            players[playersToId[msg.sender]].countVTL = players[playersToId[msg.sender]].countVTL + _countPresses;
        } else {
            // Player doesn&#39;t exist create it
            uint playerId = players.push(Player(msg.sender, _countPresses)) - 1;
            playersToId[msg.sender] = playerId;
        }

        // Send event
        emit NewPress(msg.sender, _countPresses, msg.value, timerEnd);
        
        // Increment the total count of presses
        countPresses = countPresses + _countPresses;
        amountPlayed = amountPlayed + msg.value;
    }

    // This function can be called only by the winner once the timer has ended
    function withdrawReward() public {
        // We verify that the game has ended and that the address asking for the withdraw is the winning address
        require(timerEnd < now);
        require(winningAddress == msg.sender);
        
        // Send the balance to the winning player
        winningAddress.transfer(address(this).balance);
    }
    
    // This function returns the details for the players by id (instead of by address)
    function GetPlayer(uint _id) public view returns(address, uint) {
        return(players[_id].playerAddress, players[_id].countVTL);
    }
    
    // Return the player id and the count of VTL for the connected player
    function GetPlayerDetails(address _address) public view returns(uint, uint) {
        uint _playerId = playersToId[_address];
        uint _countVTL = 0;
        if(_playerId > 0) {
            _countVTL = players[_playerId].countVTL;
        }
        return(_playerId, _countVTL);
    }

    // We loop through all of the players to get the main investor (the one with the largest amount of VTL Token)
    function GetMainInvestor() public view returns(uint[]) {
        uint depth = 10;
        bool[] memory _checkPlayerInRanking = new bool[] (players.length);
        
        uint[] memory curWinningVTLAmount = new uint[] (depth);
        uint[] memory curWinningPlayers = new uint[] (depth);
        
        // Loop through the depth to find the player for each rank
        for(uint j = 0; j < depth; j++) {
            // We reset some value
            curWinningVTLAmount[j] = 0;
            
            // We loop through all of the players
            for (uint8 i = 0; i < players.length; i++) {
                // Iterate through players and insert the current best at the correct position
                if(players[i].countVTL > curWinningVTLAmount[j] && _checkPlayerInRanking[i] != true) {
                    curWinningPlayers[j] = i;
                    curWinningVTLAmount[j] = players[i].countVTL;
                }
            }
            // We record that this player is in the ranking to make sure we don&#39;t integrate it multiple times in the ranking
            _checkPlayerInRanking[curWinningPlayers[j]] = true;
        }

        // We return the winning player
        return(curWinningPlayers);
    }
    
    // This function returns the current important stats of the game such as the timer, current balance and current winner, the current press prices...
    function GetCurrentNumbers() public view returns(uint, uint256, address, uint, uint256, uint256, uint256) {
        return(timerEnd, address(this).balance, winningAddress, countPresses, amountPlayed, getButtonPrice(), countInvestorDividends);
    }
    
    // This is the initial function called when we create the contract 
    constructor() public onlyCeo {
        timerEnd = uint32(now + timerInterval);
        winningAddress = ownerAddress;
        
        // We create the initial player to avoid any bugs
        uint playerId = players.push(Player(0x0, 0)) - 1;
        playersToId[msg.sender] = playerId;
    }
    
    // This function returns the current price of the button according to the amount pressed.
    function getButtonPrice() public view returns(uint256) {
        // Get price multiplier according to the amount of presses
        uint _multiplier = 0;
        if(countPresses > 100) {
            _multiplier = buttonPriceStep * (countPresses / 100);
        }
        
        // Calculate final button price
        uint256 _buttonPrice = buttonBasePrice + _multiplier;
        return(_buttonPrice);
        
    }
    
    //
    // Safe Math
    //

     // Guards against integer overflows.
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }
    
}