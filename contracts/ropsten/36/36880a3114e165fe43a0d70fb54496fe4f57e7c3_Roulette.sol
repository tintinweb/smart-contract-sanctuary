/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity ^0.7.6;

contract Roulette{
    address payable public did;
    constructor () {
        did = msg.sender;
    }
    uint i;
    
    struct Player{
        address payable id; 
        bool ready;
        uint bet_amount;
        uint8 xi;
    }
    int[8] Outcome;
    uint[8] bets;
    uint8[8] xi;
    
    
    Player[8] public Game_Group;
    uint player_count = 0;
    bool ingame;
    uint8 x;
    uint256 r;
    bytes32 public dealer_hash;
    
    address public here;
    
    function update() public{
        here = msg.sender;
    }


    
    function Join_Game() public{
        ingame = false;
        for (i = 0; i < player_count; i++){
            if (msg.sender == Game_Group[i].id){
                ingame = true;
            }
            
        }
        if (player_count < 8 && !ingame && msg.sender != did){
            Game_Group[player_count] = Player(msg.sender, false, 0, 0);
            player_count++;
            address id = msg.sender;
        }
    }
    
    function hash(uint8 x, uint256 r) private returns (bytes32 h){
        h = keccak256(abi.encodePacked(x,r));
    }

    function Ready_to_Play(uint8 guess, uint Bet_Amount) public {
        for (i = 0; i < player_count; i++){
            if (Game_Group[i].id == msg.sender){
                Game_Group[i].ready = true;
                did.transfer(Game_Group[i].bet_amount);
                Game_Group[i].xi = guess;
                Game_Group[i].bet_amount = Bet_Amount;
            }
        }
    }
    
    function Dealer_Set_Hash(uint8 _x, uint256 _r) public returns(bytes32){
        if (msg.sender == did){
            if (_x == 1 || _x == 0){
                x = _x;
                r = _r;
                dealer_hash = hash(x,r);
                return hash(x,r);
            }
        }
    }
    
    function Dealer_Reveal() public view returns(uint8, uint256){
        if (msg.sender == did){
            return (x, r);
        }
    }
    
    function START_GAME() public {
        for (i = 0; i < 8; i++){
            Outcome[i] = 0;
        }
            
        if (msg.sender == did){
            for(i = 0; i < player_count; i++){
                bets[i] = Game_Group[i].bet_amount;
                xi[i] = Game_Group[i].xi;
                if (Game_Group[i].ready = true){
                    if(hash(x,r) != dealer_hash){
                        Outcome[i] = 1; //1 is winning, this means the dealer cheated (changed x or r)
                    }
                    else { //occurs if the dealer didn't cheated
                        if(hash(x,r) == hash(xi[i], r)){
                            Outcome[i] = 1; //player wins
                        }
                        else { //player loses
                            Outcome[i] = -1;
                        }
                    }
                }
            }   //At this point all of the values of the amount of the player's bets have been stored.
                //Also whether the player won or not has been stored. Now we will execute transactions based on the results
            
            for (i = 0; i < player_count; i++){
                if (Outcome[i] == 1){ //player won, dealer pays the player
                    Game_Group[i].id.transfer(bets[i]*2);
                }
            }
        }
    //Game is over, time to resets everyone's stats
        for (i = 0; i < 8; i++){
            Outcome[i] = 0;
            bets[i] = 0;
            xi[i] = 0;
            
            Game_Group[i].id = address(0);
            Game_Group[i].ready = false;
            Game_Group[i].bet_amount = 0;
            Game_Group[i].xi = 0;
           
            
        }
    }
}

/*
This game works similar to roullete in real life. If a player wants to play, they join the game, set their guess,
set their bet amount, and give that much money to the dealer. If the player wins then the player gets their bet back
plus that sum again. If the player loses then the dealer keeps their money. In this game the players trust the
dealer with their money until the game is played. If the dealer cheats and changes the x then the players will know
since the C value is different. If the dealer tries to cheat then the players get paid as if they won.

No player has an advantage here since it is impossible to know x based on C, since C is created from a hash of the
conactenation of the hash of x and r. Additionally, with a cap of 500 the martingale strategy is defeated since the
player is not able to continue doubling their bet until they win. With a starting bet of 5 (the min) the player can
only double their bet 6 times until they are capped.

Also, once the dealer starts the game, all bets and guesses are stored in an array so that players will not be able
to change their bets once the game as started.

Therefore, this protcol is fair and secure if the hash function is secure.
*/