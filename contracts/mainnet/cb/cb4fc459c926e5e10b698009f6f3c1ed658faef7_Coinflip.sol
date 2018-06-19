pragma solidity ^0.4.0;

contract Coinflip {

    uint public minWager = 10000000000000000;
    uint public joinDelta = 10;
    uint public fee = 1; //1%
    uint public cancelFee = 1; //1%
    uint public maxDuration = 86400; //24h
    bool public canCreateGames = true;

    address public owner = msg.sender;

    uint public gamesCounter = 0;
    mapping(uint => CoinFlipGame) private games;
    event gameStateChanged(uint gameId, uint state);
    event onWithdraw(uint amount, uint time);
    event onDeposit(uint amount, address from, uint time);

    struct CoinFlipGame {
        uint state;
        uint createTime;
        uint endTime;
        uint odds;
        uint fee;
        uint hostWager;
        uint opponentWager;
        uint cancelFee;
        uint winAmount;
        address host;
        address opponent;
        address winner;
    }

    function() public payable {
        onDeposit(msg.value, msg.sender, now);
    }

    modifier onlyBy(address _account)
    {
        require(msg.sender == _account);
        _;
    }

    function terminate() public onlyBy(owner) {
        selfdestruct(owner);
    }

    function randomize() private view returns (uint) {
        var firstPart =  uint(block.blockhash(block.number-1)) % 25;
        var secondPart =  uint(block.blockhash(block.number-2)) % 25;
        var thirdPart =  uint(block.blockhash(block.number-3)) % 25;
        var fourthPart =  uint(block.blockhash(block.number-4)) % 25;
        return firstPart + secondPart + thirdPart + fourthPart;
    }

    function withdraw(uint amount) onlyBy(owner) public {
        require(amount > 0);
        owner.transfer(amount);
        onWithdraw(amount, now);
    }

    function toggleCanCreateGames() onlyBy(owner) public {
        canCreateGames = !canCreateGames;
    }

    function setCancelFee(uint newCancelFee) onlyBy(owner) public {
        require(newCancelFee > 0 && newCancelFee < 25);
        cancelFee = newCancelFee;
    }

    function setMinWager(uint newMinWager) onlyBy(owner) public {
        require(newMinWager > 0);
        minWager = newMinWager;
    }

    function setMaxDuration(uint newMaxDuration) onlyBy(owner) public {
        require(newMaxDuration > 0);
        maxDuration = newMaxDuration;
    }

    function setFee(uint newFee) onlyBy(owner) public {
        require(newFee < 25);
        fee = newFee;
    }

    function setJoinDelta(uint newJoinDelta) onlyBy(owner) public {
        require(newJoinDelta > 0);
        require(newJoinDelta < 100);
        joinDelta = newJoinDelta;
    }

    function getGame(uint id) public constant returns(  uint gameId,
                                                        uint state,
                                                        uint createTime,
                                                        uint endTime,
                                                        uint odds,
                                                        address host,
                                                        uint hostWager,
                                                        address opponent,
                                                        uint opponentWager,
                                                        address winner,
                                                        uint winAmount) {
        require(id <= gamesCounter);
        var game = games[id];
        return (
        id,
        game.state,
        game.createTime,
        game.endTime,
        game.odds,
        game.host,
        game.hostWager,
        game.opponent,
        game.opponentWager,
        game.winner,
        game.winAmount);
    }

    function getGameFees(uint id) public constant returns(  uint gameId,
        uint feeVal,
        uint cancelFeeVal) {
        require(id <= gamesCounter);
        var game = games[id];
        return (
        id,
        game.fee,
        game.cancelFee);
    }

    function cancelGame(uint id) public {
        require(id <= gamesCounter);
        CoinFlipGame storage game = games[id];
        if(msg.sender == game.host) {
            game.state = 3; //cacneled
            game.endTime = now;
            game.host.transfer(game.hostWager);
            gameStateChanged(id, 3);
        } else {
            require(game.state == 1); //active
            require((now - game.createTime) >= maxDuration); //outdated
            require(msg.sender == owner); //server cancel
            gameStateChanged(id, 3);
            game.state = 3; //canceled
            game.endTime = now;
            var cancelFeeValue = game.hostWager * cancelFee / 100;
            game.host.transfer(game.hostWager - cancelFeeValue);
            game.cancelFee = cancelFeeValue;
        }
    }

    function joinGame(uint id) public payable {
        var game = games[id];
        require(game.state == 1);
        require(msg.value >= minWager);
        require((now - game.createTime) < maxDuration); //not outdated
        if(msg.value != game.hostWager) {
            uint delta;
            if( game.hostWager < msg.value ) {
                delta = msg.value - game.hostWager;
            } else {
                delta = game.hostWager - msg.value;
            }
            require( ((delta * 100) / game.hostWager ) <= joinDelta);
        }

        game.state = 2;
        gameStateChanged(id, 2);
        game.opponent = msg.sender;
        game.opponentWager = msg.value;
        game.endTime = now;
        game.odds = randomize() % 100;
        var totalAmount = (game.hostWager + game.opponentWager);
        var hostWagerPercentage = (100 * game.hostWager) / totalAmount;
        game.fee = (totalAmount * fee) / 100;
        var transferAmount = totalAmount - game.fee;
        require(game.odds >= 0 && game.odds <= 100);
        if(hostWagerPercentage > game.odds) {
            game.winner = game.host;
            game.winAmount = transferAmount;
            game.host.transfer(transferAmount);
        } else {
            game.winner = game.opponent;
            game.winAmount = transferAmount;
            game.opponent.transfer(transferAmount);
        }
    }

    function startGame() public payable returns(uint) {
        require(canCreateGames == true);
        require(msg.value >= minWager);
        gamesCounter++;
        var game = games[gamesCounter];
        gameStateChanged(gamesCounter, 1);
        game.state = 1;
        game.createTime = now;
        game.host = msg.sender;
        game.hostWager = msg.value;
    }

}