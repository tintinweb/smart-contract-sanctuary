/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

pragma solidity ^0.4.11;

contract RPSGame {
    
    event Record(uint _round, address _player, string _choose, string match_result);

    struct gameRecord {
        address player;
        string choose;
        string matchResult;
    }
    
    mapping(uint=>gameRecord) public gameSearch;

    uint public randomNumber;
    uint public totalRound = 0;
    address banker;
    
    constructor() payable public {
       require(msg.value == 1 ether);
       banker = msg.sender;
    }
    
    function newRandom() public {
      bytes32 a = keccak256(abi.encodePacked(block.coinbase, block.timestamp));
      randomNumber = (uint(a) % 3) + 1;
    }

    modifier check{
        require(address(this).balance >= 0.02 ether, "獎金已經被賺光光啦！");
        require(msg.value == 0.01 ether, "請下注0.01 ether");
        _;
    }

    function option(uint a) private pure returns(string) {
        if (a == 1)
          return "Scissors";
        if (a == 2)
          return "Rock";
        if (a == 3)
          return "Paper";
    }

    function scissors() payable public check returns(string rivalChoose, string) {
        string memory wlt;
        totalRound++;
        newRandom();
        
        if (randomNumber == 1) {
            msg.sender.transfer(0.01 ether);
            wlt = "tie";                  
        }
        else if (randomNumber == 2) {
            wlt = "lose";            
        }
        else if (randomNumber == 3) {
            msg.sender.transfer(0.02 ether);
            wlt = "win";            
        }

        gameSearch[totalRound] = gameRecord(msg.sender, "scissors", wlt);
        emit Record(totalRound, msg.sender, "scissors", wlt);

        return (option(randomNumber), wlt);
    }

    function rock() payable public check returns(string rivalChoose, string){
        string memory wlt;
        totalRound++;
        newRandom();
        
        if (randomNumber == 1) {
            msg.sender.transfer(0.02 ether);
            wlt = "win";
        }
        else if (randomNumber == 2) {
            msg.sender.transfer(0.01 ether);
            wlt = "tie";
        }
        else if (randomNumber == 3) {
            wlt = "lose";
        }

        gameSearch[totalRound] = gameRecord(msg.sender, "rock", wlt);
        emit Record(totalRound, msg.sender, "rock", wlt);

        return (option(randomNumber), wlt);
    }

    function paper() payable public check returns(string rivalChoose, string){
        string memory wlt;
        totalRound++;
        newRandom();        

        if (randomNumber == 1) {
            wlt = "lose";
        }
        else if (randomNumber == 2) {
            msg.sender.transfer(0.02 ether);
            wlt = "win";
        }
        else if (randomNumber == 3) {
            msg.sender.transfer(0.01 ether);
            wlt = "tie";
        }

        gameSearch[totalRound] = gameRecord(msg.sender, "paper", wlt);
        emit Record(totalRound, msg.sender, "paper", wlt);

        return (option(randomNumber), wlt);
    }
    
    function playerRecord(address who) public view returns(uint yourGames, uint wins, uint loss, uint ties) {

    uint[4] memory count;

    for (uint i=1 ; i<=totalRound ; i++) {
        if (gameSearch[i].player == who) {
            count[0]++;

            if (keccak256(abi.encodePacked(gameSearch[i].matchResult)) == keccak256(abi.encodePacked("win")))
               count[1]++;
            else if (keccak256(abi.encodePacked(gameSearch[i].matchResult)) == keccak256(abi.encodePacked("lose")))
               count[2]++;
            else if (keccak256(abi.encodePacked(gameSearch[i].matchResult)) == keccak256(abi.encodePacked("tie")))
               count[3]++;
        }
    }

    return (count[0], count[1], count[2], count[3]);
    }

    function donate() public payable returns(string){
        return "Thank you!";
    }

    function bankerWithdraw(uint amount) public returns(string){
        require (msg.sender == banker);
        require (amount>0 && amount<=address(this).balance);

        msg.sender.transfer(amount);
        return "done";
    }





}