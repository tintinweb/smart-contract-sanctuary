pragma solidity ^0.4.24;

contract DiceGame {

    address public owner;
    address public gamemaster;
    uint weiBalance;
    mapping(address => uint) public rewards;
    PlayRound public playRound;
    PlayRound[] public pastPlayRounds;

    event PlayRoundStarted();
    event BetPlaced(address player, uint numberOfPips, uint weiBalance);
    event RewardAllocated(address player, uint oldReward, uint newReward);
    event PlayRoundClosed(address winner, address second, address third);

    struct Bet {
        uint blockNumber;
        uint8 numberOfPips;
        uint8 points;
    }

    struct PlayRound {
        mapping(address => Bet) bets;
        address[] players;
        uint8 numberOfPips;
        uint weiRequired;
        address winner;
        address second;
        address third;
        bool placingPhaseActive;
    }

    constructor() public {
        owner = msg.sender;
        gamemaster = msg.sender;
    }

    modifier placingPhaseActive() {
        require(playRound.placingPhaseActive);
        _;
    }

    modifier betConditions(uint8 _numberOfPips) {
        require(playRound.placingPhaseActive);
        require(msg.value >= playRound.weiRequired);
        require(_numberOfPips > 0 && _numberOfPips <= 6);
        require(playRound.bets[msg.sender].numberOfPips == 0);
        _;
    }

    modifier startConditions() {
        require(msg.sender == owner || msg.sender == gamemaster);
        require(!playRound.placingPhaseActive);
        _;
    }

    modifier closeConditions() {
        require(msg.sender == owner || msg.sender == gamemaster);
        require(playRound.placingPhaseActive);
        require(playRound.players.length >= 3);
        _;
    }

    modifier hasRewards(address _player) {
        require(rewards[_player] > 0);
        _;
    }

    modifier contractModificationConditions() {
        require(msg.sender == owner);
        require(!playRound.placingPhaseActive);
        _;
    }

    modifier changeGamemasterConditions() {
        require(msg.sender == owner || msg.sender == gamemaster);
        _;
    }

    function startPlacingPhase(uint _weiRequired) public startConditions {
        playRound.placingPhaseActive = true;
        playRound.weiRequired = _weiRequired;
        emit PlayRoundStarted();
    }

    function placeBet(uint8 _numberOfPips) payable public betConditions(_numberOfPips) {
        Bet storage bet = playRound.bets[msg.sender];
        bet.numberOfPips = _numberOfPips;
        bet.blockNumber = block.number;
        weiBalance = weiBalance + msg.value;
        playRound.players.push(msg.sender);
        emit BetPlaced(msg.sender, _numberOfPips, weiBalance);
    }

    function closePlacingPhase() public closeConditions {
        playRound.placingPhaseActive = false;
        _calculatePointsAndRewards();
        _resetPlayRound();
    }

    function pastPlayRoundsCount() public view returns (uint) {
        return pastPlayRounds.length;
    }

    function getPlayerBetForCurrentPlayRound(address playerAddress) public view returns (uint8) {
        return playRound.bets[playerAddress].numberOfPips;
    }

    function getPlayerBetForPlayRound(address playerAddress, uint playRoundId) public view returns (uint8) {
        return pastPlayRounds[playRoundId].bets[playerAddress].numberOfPips;
    }

    function _calculatePointsAndRewards() private {
        uint8 random = _generateRandomNumber();
        playRound.numberOfPips = random;
        address tmpWinner;
        address tmpSecond;
        address tmpThird;
        for( uint i = 0; i < playRound.players.length; i++ ) {
            address tmpAddress = playRound.players[i];
            if (playRound.bets[tmpAddress].numberOfPips == random) {
                playRound.bets[tmpAddress].points = 10;
            } else if (random + 1 == playRound.bets[tmpAddress].numberOfPips || random - 1 == playRound.bets[tmpAddress].numberOfPips) {
                playRound.bets[tmpAddress].points = 5;
            } else if (random + 2 == playRound.bets[tmpAddress].numberOfPips || random - 2 == playRound.bets[tmpAddress].numberOfPips) {
                playRound.bets[tmpAddress].points = 1;
            }
            if (_betterThan(tmpAddress, tmpWinner) ) {
                tmpThird = tmpSecond;
                tmpSecond = tmpWinner;
                tmpWinner = tmpAddress;
            } else if (_betterThan(tmpAddress, tmpSecond)) {
                tmpThird = tmpSecond;
                tmpSecond = tmpAddress;
            } else if (_betterThan(tmpAddress, tmpThird)) {
                tmpThird = tmpAddress;
            }
        }
        uint oldReward = rewards[tmpWinner];
        rewards[tmpWinner] += weiBalance * 60 / 100;
        emit RewardAllocated(tmpWinner, oldReward, rewards[tmpWinner]);
        oldReward = rewards[tmpSecond];
        rewards[tmpSecond] += weiBalance * 30 / 100;
        emit RewardAllocated(tmpSecond, oldReward, rewards[tmpSecond]);
        oldReward = rewards[tmpThird];
        rewards[tmpThird] += weiBalance * 10 / 100;
        emit RewardAllocated(tmpThird, oldReward, rewards[tmpThird]);
        playRound.winner = tmpWinner;
        playRound.second = tmpSecond;
        playRound.third = tmpThird;
        pastPlayRounds.push(playRound);
        emit PlayRoundClosed(tmpWinner, tmpSecond, tmpThird);
    }

    function claimReward() public hasRewards(msg.sender) {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        msg.sender.transfer(reward);
    }

    // https://ethereum.stackexchange.com/questions/419/when-can-blockhash-be-safely-used-for-a-random-number-when-would-it-be-unsafe
    function _generateRandomNumber() private view returns (uint8) {
        uint b = block.number;
        uint timestamp = block.timestamp;
        return uint8(uint256(keccak256(abi.encodePacked(blockhash(b), timestamp))) % 6 + 1);
    }

    function _betterThan(address player1, address player2) private view returns(bool) {
        if (player2 == address(0)) {
            return true;
        }
        else if(playRound.bets[player1].points > playRound.bets[player2].points) {
            return true;
        } else if (playRound.bets[player1].points == playRound.bets[player2].points) {
            return playRound.bets[player1].blockNumber < playRound.bets[player2].blockNumber;
        }
        return false;
    }

    function _resetPlayRound() private {
        playRound.weiRequired = 0;
        for (uint i = 0; i < playRound.players.length; i++) {
            playRound.bets[playRound.players[i]].numberOfPips = 0;
            playRound.bets[playRound.players[i]].blockNumber = 0;
            playRound.bets[playRound.players[i]].points = 0;
        }
        delete playRound.players;
        weiBalance = 0;
        playRound.numberOfPips = 0;
        playRound.winner = address(0);
        playRound.second = address(0);
        playRound.third = address(0);
    }

    function destroy() public contractModificationConditions {
        selfdestruct(owner);
    }

    function transferOwnership(address newOwnerAddress) public contractModificationConditions {
        owner = newOwnerAddress;
    }

    function changeGamemaster(address newGamemasterAddress) public changeGamemasterConditions {
        gamemaster = newGamemasterAddress;
    }
}