pragma solidity ^0.4.18;


interface token {
    function transfer(address receiver, uint amount) public;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a==0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract GameTable {
    using SafeMath for uint;

    struct Player {
        address addr;
        uint amount;
        uint profit;
    }

    struct Option {
        uint optionid;
        bytes32 optionName;
        bytes32 optionImage;
        uint amount;
        uint numPlayers;
        mapping (uint => Player) players;
        mapping (address => uint) playeramounts;
    }

    struct Game {
        address gameManager;
        bytes32 gameName;
        uint numOptions;
        uint amount;
        uint balance;
        uint winner;
        uint startTime;
        uint endTime;
        uint openTime;
        uint runingStatus;
        mapping (uint => Option) options;
    }

    address owner;
    uint numGames;
    mapping (uint => Game) games;
    address gameDeveloper = 0x18d91206b297359e8aed91810a86D6bFF0AF3462;
    //0x18d91206b297359e8aed91810a86d6bff0af3462
    
    function GameTable() public { 
        owner = msg.sender;
        numGames=0;
    }
    
    function kill() public {
       if (owner == msg.sender) { 
          selfdestruct(owner);
       }
    }

    function newGame(bytes32 name, uint startDuration, uint endDuration, uint openDuration)  public returns (uint) {
        if(startDuration < 1 || openDuration>888888888888 || endDuration<startDuration || openDuration<startDuration || openDuration<endDuration || owner != msg.sender) revert();
        address manager =  msg.sender;
        uint startTime = now + startDuration * 1 minutes;
        uint endTime = now + endDuration * 1 minutes;
        uint openTime = now + openDuration * 1 minutes;
        games[numGames] = Game(manager, name, 0, 0, 0, 0, startTime, endTime, openTime, 0);
        numGames = numGames+1; 
        return (numGames-1);
    }

    function getGameNum() public constant returns(uint) {return numGames;}

    function getGameInfo (uint gameinx) public constant returns(bytes32 _gamename,uint _numoptions,uint _amount,uint _startTime,uint _endTime,uint _openTime,uint _runingStatus) {
        _gamename = games[gameinx].gameName;
        _numoptions = games[gameinx].numOptions;
        _amount = games[gameinx].amount;
        _startTime = games[gameinx].startTime;
        _endTime = games[gameinx].endTime;
        _openTime = games[gameinx].openTime;
        _runingStatus = games[gameinx].runingStatus;
    }
    

    function newOption(uint gameinx, uint optionid, bytes32 name, bytes32 optionimage)  public returns (uint) {
        if (owner != msg.sender) revert();
        if (gameinx > numGames) revert();
        if (now >= games[gameinx].startTime) revert();
        if (games[gameinx].runingStatus == 0){
            games[gameinx].runingStatus = 1;
        }
        games[gameinx].numOptions = games[gameinx].numOptions+1;
        games[gameinx].options[games[gameinx].numOptions-1] = Option(optionid, name, optionimage, 0, 0);
        return games[gameinx].numOptions-1;
    }


    function getGameWinner (uint gameinx) public constant returns(uint) {return games[gameinx].winner;}
    function getOptionInfo (uint gameinx, uint optioninx) public constant returns(uint _gameinx, uint _optionid, uint _optioninx,bytes32 _optionname,bytes32 _optionimage,uint _numplayers, uint _amount, uint _playeramount) {
        _gameinx = gameinx;
        _optioninx = optioninx;
        _optionid = games[gameinx].options[optioninx].optionid;
        _optionname = games[gameinx].options[optioninx].optionName;
        _optionimage = games[gameinx].options[optioninx].optionImage;
        _numplayers = games[gameinx].options[optioninx].numPlayers;
        _amount = games[gameinx].options[optioninx].amount;
        _playeramount = games[gameinx].options[optioninx].playeramounts[msg.sender];
    }

    function getPlayerPlayInfo (uint gameinx, uint optioninx, uint playerinx) public constant returns(address _addr, uint _amount, uint _profit) {
        if(msg.sender != owner) revert();
        _addr = games[gameinx].options[optioninx].players[playerinx].addr;
        _amount = games[gameinx].options[optioninx].players[playerinx].amount;
        _profit = games[gameinx].options[optioninx].players[playerinx].profit;
    }

    function getPlayerAmount (uint gameinx, uint optioninx, address addr) public constant returns(uint) {
        if(msg.sender != owner) revert();
        return games[gameinx].options[optioninx].playeramounts[addr];
    }

  
    function contribute(uint gameinx,uint optioninx)  public payable {
        if ((gameinx<0)||(gameinx>999999999999999999999999999999999999)||(optioninx<0)) revert();
        if (optioninx >= games[gameinx].numOptions) revert();
        if (now <= games[gameinx].startTime) revert();
        if (now >= games[gameinx].endTime) revert();
        //1000000000000000000=1eth
        //5000000000000000  = 0.005 ETH
        if (msg.value<5000000000000000 || msg.value>1000000000000000000000000000) revert();
        if (games[gameinx].amount > 99999999999999999999999999999999999999999999999999999999) revert();

        games[gameinx].options[optioninx].players[games[gameinx].options[optioninx].numPlayers++] = Player({addr: msg.sender, amount: msg.value, profit:0});
        games[gameinx].options[optioninx].amount = games[gameinx].options[optioninx].amount.add(msg.value);
        games[gameinx].options[optioninx].playeramounts[msg.sender] = games[gameinx].options[optioninx].playeramounts[msg.sender].add(msg.value);
        games[gameinx].amount = games[gameinx].amount.add(msg.value);
    }

    function setWinner(uint gameinx,bytes32 gameName, uint optioninx, uint optionid, bytes32 optionName) public returns(bool res) {
        if (owner != msg.sender) revert();
        if ((now <= games[gameinx].openTime)||(games[gameinx].runingStatus>1)) revert();
        if (gameName != games[gameinx].gameName) revert();
        if (games[gameinx].options[optioninx].optionName != optionName) revert();
        if (games[gameinx].options[optioninx].optionid != optionid) revert();

        games[gameinx].winner = optioninx;
        games[gameinx].runingStatus = 2;
        safeWithdrawal(gameinx);
        return true;
    }

    function safeWithdrawal(uint gameid) private {
        
        if ((gameid<0)||(gameid>999999999999999999999999999999999999)) revert();
        if (now <= games[gameid].openTime) revert();
        if (games[gameid].runingStatus != 2) revert();

        uint winnerID = games[gameid].winner;
        if (winnerID >0 && winnerID < 9999) {
            
            games[gameid].runingStatus = 3;
            uint totalWinpool = games[gameid].options[winnerID].amount;
            totalWinpool = games[gameid].amount.sub(totalWinpool);
            //Calculate Fee
            uint fee = totalWinpool.mul(15);
            fee = fee.div(1000);
            uint reward=totalWinpool.sub(fee);
            //1000000000000000000=1eth
            if(games[gameid].options[winnerID].amount<100000000000){
                gameDeveloper.transfer(reward);
            }
            else{
                uint ratio = reward.mul(100);
                ratio = ratio.div(games[gameid].options[winnerID].amount); //safe????
                uint totalReturn = 0;
                for(uint i = 0; i < games[gameid].options[winnerID].numPlayers; i++) {
                    uint returnWinAmount = games[gameid].options[winnerID].players[i].amount.mul(ratio);
                    returnWinAmount = returnWinAmount.div(100);
                    returnWinAmount = games[gameid].options[winnerID].players[i].amount.add(returnWinAmount);
                    games[gameid].options[winnerID].players[i].addr.transfer(returnWinAmount);
                    games[gameid].options[winnerID].players[i].profit = returnWinAmount;
                    totalReturn = totalReturn.add(returnWinAmount);
                }  
                uint totalFee = games[gameid].amount.sub(totalReturn);
                gameDeveloper.transfer(totalFee);
            }
        }
    } 

}