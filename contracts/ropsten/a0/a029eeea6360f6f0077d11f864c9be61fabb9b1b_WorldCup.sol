pragma solidity ^0.4.24;

/**
 * @File: worldcup_bet_game.sol
 * @Description: The user obtains rewards by interacting with the smart 
 *      contract to guess the score of the World Cup match. At the same time, 
 *      the publisher charges a small fee for gas.
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
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

/**
 * @title contract WorldCup
 * @dev worldcup bet game
 */
contract WorldCup {
    using SafeMath for uint256;

    address public owner;

    uint256 public partionPrice;                   // every partion price
    uint256 public serverGasPer;                   // owner profit. bonus*(serverGasper%)
    uint256 public bonusPool;                      // All - server fee

    // game structure
    struct Game {
        bytes32 team1;                      // first team
        bytes32 team2;                      // second team
        bytes32 matchStartTime;             // match start time

        uint256 resultTeam1;                // team1&#39;s score
        uint256 resultTeam2;                // team2&#39;s score

        bool betEnd;                        // game can bet
                                            // n minutes after the start of the match, stop betting
        bool matchFinish;                   // match finished
        bool gameFinish;                    // game finished
    }

    // user structure
    struct User {
        address addr;                       // user address
        uint256 scoreTeam1;                 // bet team1&#39;s score
        uint256 scoreTeam2;                 // bet team2&#39;s score
        uint256 betWeight;                  // bet weight
        bool victory;
    }

    //
    Game public game;
    User[] public users;

    // construtor
    function WorldCup(bytes32 t1, bytes32 t2, bytes32 time) public {
        owner = msg.sender;
        partionPrice = 1 ether;
        serverGasPer = 20;                   // 20% server gas

        game.team1 = t1;
        game.team2 = t2;
        game.matchStartTime = time;
        game.resultTeam1 = 0;
        game.resultTeam2 = 0;
        game.betEnd = false;
        game.matchFinish = false;
        game.gameFinish = false;
    }

    // bet function
    // s1 = team1&#39;s score, s2 = team2&#39;s score
    function bet(uint256 s1, uint256 s2, uint256 weight) public payable {
        require(game.betEnd == false);
        require(weight > 0 && weight <= 1000);
        require(msg.value >= partionPrice.mul(weight));

        // refund extra ETH
        if (msg.value > partionPrice.mul(weight)) {
            uint256 refund = msg.value.sub(partionPrice.mul(weight));
            msg.sender.transfer(refund);
        }

        // add user
        users.push(User({
            addr: msg.sender,
            scoreTeam1: s1,
            scoreTeam2: s2,
            betWeight: weight,
            victory: false
        }));
    }

    // close bet and calcute bonusPool
    // when n minutes after the start of the match, stop betting
    function setbetEnd() public {
        require(owner == msg.sender);
        
        game.betEnd = true;

        uint256 serverGas = this.balance.div(100).mul(serverGasPer);
        bonusPool = this.balance.div(serverGas);
    }

    // set match result
    function setResult(uint256 s1, uint256 s2) public {
        require(owner == msg.sender);
        require(game.matchFinish == false);
        require(game.betEnd == true);

        game.resultTeam1 = s1;
        game.resultTeam2 = s2;
        game.matchFinish = true;
    }

    // settle and award bonus
    function settle() public payable {
        require(owner == msg.sender);
        require(game.gameFinish == false);
        require(game.matchFinish == true);

        uint256 victorsWeight = 0;          // all victors&#39; weight
        uint256 bonus = 0;                  // the bonus every weight
        User u;
        uint256 i = 0;

        // count victoy
        for (i = 0; i < users.length; i++) {
            u = users[i];
            if (u.scoreTeam1 == game.resultTeam1 && u.scoreTeam2 == game.resultTeam2) {
                u.victory = true;
                victorsWeight = victorsWeight.add(u.betWeight);
            }
        }

        // settle
        bonus = bonusPool.div(victorsWeight);

        // award bonus
        for (i = 0; i < users.length; i++) {
            u = users[i];
            if (u.victory == true) {
                u.addr.transfer(u.betWeight.mul(bonus));
            }
        }

        // set game finished
        game.gameFinish = true;
    }

    // kill and get server gas
    function kill() public {
        require(owner == msg.sender);
        require(game.gameFinish == true);

        selfdestruct(owner);
    }
}