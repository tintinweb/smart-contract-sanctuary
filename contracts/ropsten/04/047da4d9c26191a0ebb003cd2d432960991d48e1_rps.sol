pragma solidity ^0.4.24;

// checklist:
// 1. Checked the number of registered players in add_player()?
// 2. Checked msg.value in add_player()?
// 3. In time_out and check_winner, cleared num_players and two isOpen so that people can play the game again.
// 4. Use transfer() instead of send(), or check the return value of send()

contract rps {
    uint public num_players = 0;
    uint public start_time;
    uint reward = 0;
    
    struct Player {
        address addr;
        int8 choice;//0 means rock, 1 means scissors, 2 means paper, so that you can use (player[0].choice + 3 - player[1].choice) % 3 to determine the winner
        bytes32 commitment;
        bool isOpen;
    }
    
    mapping (uint => Player) public player;
    
   
    function sha3(uint _secret) pure public returns (bytes32) {
        return keccak256(_secret);
    }
    
    function add_player(bytes32 _commitment) external payable {
        require(num_players < 2);
        require(msg.value == 1 finney);
        if (num_players == 0) start_time = now;
        reward += msg.value;
        player[num_players].addr = msg.sender;
        player[num_players].commitment = _commitment;
        num_players++;
    }
    
    function open_commitment(uint _secret) external payable{
        uint8 player_num;
        require(num_players == 2);
        if (msg.sender == player[0].addr) player_num = 0;
        else if (msg.sender == player[1].addr) player_num = 1;
        else revert();
        require (!player[player_num].isOpen, &quot;the commitment is open!&quot;);
        require (keccak256(_secret) == player[player_num].commitment);
        player[player_num].choice = int8(_secret % 3);
        player[player_num].isOpen = true;
        if (player[0].isOpen && player[1].isOpen) _check_winner();
    }
    
    function _check_winner() private {
        int8 who = player[0].choice + 3 - player[1].choice;
        num_players = 0;
        player[0].isOpen = false;
        player[1].isOpen = false;
        if (who % 3 == 1)// Player 0 wins
            player[0].addr.transfer(reward);
        else if (who % 3 == 2)// Player 1 wins
            player[1].addr.transfer(reward);
        else {
            player[0].addr.transfer(reward/2);
            player[1].addr.transfer(reward/2); 
        }
    }
    
    function time_out() external {
        bool timeOut = false;
        if (now > start_time + 10 minutes && num_players == 1){
            player[0].addr.transfer(reward);
            timeOut = true;
        }
        else if (now > start_time + 20 minutes && num_players == 2) {
            if (!player[0].isOpen && player[1].isOpen){
                player[1].addr.transfer(reward);
                timeOut = true;
            }
            else if (player[0].isOpen && !player[1].isOpen) {
                player[0].addr.transfer(reward);
                timeOut = true;
            }
        }
        if (timeOut) {
            num_players = 0;
            player[0].isOpen = false;
            player[1].isOpen = false;
        }
    }
}