pragma solidity >=0.4.22 <0.6.0;


library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract RobotRun{
    //Prevent overflow attacks
    using SafeMath for uint256;
    
    struct Robot{
        string name;
        uint bet_thisRound;
        uint bet_total;
        uint step_count;
        address last_buyer;
    }
    
    struct Player{
        address addr;
        uint256 bet_Flash_total;
        uint256 bet_Turbo_total;
        uint256 balance;
        bool exists;
    }
    
    //Player mapping
    mapping(address => Player) private players;
    //Robot list
    Robot[] private robots;
    //Player address list
    address[] private Players;
    //the starter of this game
    address game_owner;
    //game state
    uint block_state;
    //game round
    uint current_round;
    //game reward pool
    uint256 money_pool;
    //reward of this game
    uint256 reward_this_game;
    //constructor
    constructor() public {
        game_owner = msg.sender;
        block_state = block.number;
        current_round=0;
        //two robots in game
        robots.push(Robot({
            name:"Flash",
            bet_total:0,
            bet_thisRound:0,
            step_count:0,
            last_buyer:msg.sender
        }));
        robots.push(Robot({
            name:"Turtle",
            bet_total:0,
            bet_thisRound:0,
            step_count:0,
            last_buyer:msg.sender
        }));
    }
    //emit current state of the game
    event CURRENT_STATE(
        string name,
        uint256 bet,
        uint256 step,
        uint256 current_round,
        uint256 cash_pool_current
        );
    //emit winner robot and lucky player
    event WINNER(
        string winner,
        uint256 each_ticket_wins,
        address lucky_winner,
        uint256 bonus,
        uint256 cash_pool_nextRound
        );
    //if player exists
    modifier player_exists(){
        require(players[msg.sender].exists);
        _;
    }
    //creating game account
    function create_account() public returns(string,address,uint){
        //if player doesn&#39;t exists
        if(!players[msg.sender].exists){
            Players.push(msg.sender);
            players[msg.sender] = Player(msg.sender,0,0,0,true);
            return("Success",players[msg.sender].addr,players[msg.sender].balance);
        }
        else{return("Account already exists",players[msg.sender].addr,players[msg.sender].balance);}
    }
    //returns ticket price
    function ticket_price() private returns(uint){
        //a linear function to calculate ticket price
        uint256 tic_price=100+5*current_round;
        if(tic_price>=200){
            tic_price = 200;
        }
        return(tic_price);
    }
    //bet that Flash wins
    function bet_on_Flash(uint ticket) public player_exists returns(address,uint,uint256 current_cash_pool)  {
        buy_ticket(ticket);
        //change player state
        robots[0].bet_thisRound += ticket;
        robots[0].bet_total +=ticket;
        robots[0].last_buyer = msg.sender;
        players[msg.sender].bet_Flash_total += ticket;
        return(players[msg.sender].addr,players[msg.sender].balance,money_pool);
    }
    //bet that Turbo wins
    function bet_on_Turbo(uint ticket) public player_exists returns(address,uint,uint256 current_cash_pool)  {
        buy_ticket(ticket);
        robots[1].bet_thisRound += ticket;
        robots[1].bet_total += ticket;
        robots[1].last_buyer = msg.sender;
        players[msg.sender].bet_Turbo_total +=ticket;
        return(players[msg.sender].addr,players[msg.sender].balance,money_pool);
    }
    //change player balance && check current game state
    function buy_ticket(uint ticket) private{
        //a player can buy at most 10 ticket one time.
        require(ticket<=10||ticket>0);
        uint256 tic_price=ticket_price();
        //calculate cost
        uint256 pay_amount = tic_price.mul(ticket);
        require(players[msg.sender].balance>= pay_amount);
        //if current block state ahead of game block state,and each robot has bet on him
        if(block_state<block.number && robots[0].bet_thisRound !=0 && robots[1].bet_thisRound !=0){
            move();
        }
        players[msg.sender].balance -= pay_amount;
        money_pool +=pay_amount;
        
    }
    //judge which robot moves
    function move() private{
        block_state=block.number;
        current_round +=1;
        uint256 flash = robots[0].bet_thisRound;
        uint256 turbo = robots[1].bet_thisRound;
        uint256 tickets_this_round = flash.add(turbo);
        uint256 share=0;
        //standard is like percentage times 100
        uint256 standard = flash.mul(100).div(tickets_this_round);
        //if no more than 30% of players bet on Flash, Flash makes a move.
        //if same condition with Turbo, Turbo makes a move.
        //in other situations, both robots remain stay.
        if(standard  >0 && standard < 30){
            //Flash makes one step forward
            robots[0].step_count +=1;
            if(robots[0].step_count == 1){
                clear(0);
            }
        }
        else if(standard > 70 && standard < 100){
            //Turbo makes one step forward
            robots[1].step_count +=1;
            if(robots[1].step_count == 4){
                clear(1);
            }
        }
        else{
            //robots remain stay
        }
        CURRENT_STATE(
            robots[0].name,
            robots[0].bet_thisRound,
            robots[0].step_count,
            current_round,
            money_pool
            );
        CURRENT_STATE(
            robots[1].name,
            robots[1].bet_thisRound,
            robots[1].step_count,
            current_round,
            money_pool
            );
        robots[0].bet_thisRound = 0;
        robots[1].bet_thisRound = 0;
    }
    //end of each game and split reward
    function clear(uint256 whowins) private {
        //in each game, players bet on winner robots split 40% of ether in money_pool
        //10% of money_pool goes to the last_buyer of the winner.
        uint256 share = 0;
        reward_this_game = money_pool.mul(4).div(10);
        uint256 bonus = reward_this_game.div(4);
        uint256 reward;
        share = reward_this_game.div(robots[whowins].bet_total);
        money_pool = money_pool.sub(reward_this_game).sub(bonus);
        for(uint i = 0; i < Players.length; i++){
            reward = share.mul(players[Players[i]].bet_Flash_total);
            players[Players[i]].balance = players[Players[i]].balance.add(reward);
            players[Players[i]].bet_Turbo_total=0;
            players[Players[i]].bet_Flash_total=0;
        }
        WINNER(
            robots[whowins].name,
            share,
            robots[whowins].last_buyer,
            bonus,
            money_pool
            );
        players[robots[whowins].last_buyer].balance += bonus;
        //init game state
        robots[0].bet_total = 0;
        robots[0].step_count = 0;
        robots[1].bet_total = 0;
        robots[1].step_count = 0;
        current_round = 0;
        
    }
    //put ether in account
    function deposit() player_exists payable public returns(uint256,uint256){
        
        players[msg.sender].balance = players[msg.sender].balance.add(msg.value);
        return(money_pool,players[msg.sender].balance);
    }
    //withdraw ether from account
    function withdraw(uint256 amount) player_exists public returns(uint256){
        require(players[msg.sender].balance.sub(amount)>=0);
        players[msg.sender].balance=players[msg.sender].balance.sub(amount);
        msg.sender.transfer(amount);
        return(players[msg.sender].balance);
    }
    
    function validation() public returns(uint current_cash_pool,uint256 current_round,uint player_hold,uint player_amount){
        return(money_pool,current_round,players[msg.sender].balance,Players.length);

    }
    //fallback function
    function() payable private{
        deposit();
    }
    
    
}