//SourceUnit: OpoLotto-Contract-Tron.sol

pragma solidity ^0.5.9;

// SPDX-License-Identifier: MIT License

/*

 ██████╗ ██████╗  ██████╗ ██╗      ██████╗ ████████╗████████╗ ██████╗     ██████╗ ██████╗ ███╗   ███╗
██╔═══██╗██╔══██╗██╔═══██╗██║     ██╔═══██╗╚══██╔══╝╚══██╔══╝██╔═══██╗   ██╔════╝██╔═══██╗████╗ ████║
██║   ██║██████╔╝██║   ██║██║     ██║   ██║   ██║      ██║   ██║   ██║   ██║     ██║   ██║██╔████╔██║
██║   ██║██╔═══╝ ██║   ██║██║     ██║   ██║   ██║      ██║   ██║   ██║   ██║     ██║   ██║██║╚██╔╝██║
╚██████╔╝██║     ╚██████╔╝███████╗╚██████╔╝   ██║      ██║   ╚██████╔╝██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║
 ╚═════╝ ╚═╝      ╚═════╝ ╚══════╝ ╚═════╝    ╚═╝      ╚═╝    ╚═════╝ ╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝

OpoLotto is a decentralized lottery available to anyone, anywhere. It's autonomous and based on blockchain technology using cryptocurrency.

Website:  https://opolotto.com
Blog:     https://blog.opolotto.com/
Telegram: https://t.me/OpoLotto
Twitter:  https://twitter.com/OpoLotto
*/                                                                                                     

/*
    Contract Owned is here to manage the dev wallet address.
*/
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Restricted to the owner of the contract."
        );
        _;
    }

    /*
        @function Transfer dev reward share of the contract to a new wallet
        @param address _newOwner The new address
    */
    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract OpoLotto is Owned {
    // Variables and const
    uint16 constant winner1RewardShare = 800;
    uint16 constant winner2RewardShare = 50;
    uint16 constant winner3RewardShare = 30;
    uint16 constant drawerRewardShare = 20;
    uint16 constant earlybirdRewardShare = 1;
    uint16 minimumPlayers = 10;
    uint48 secondsUntilDrawIsOpen = 28800;
    uint48 private currentRoundNumber;
    uint48 private numberOfPlayersThisRound;
    uint256 private totalPrizeThisRound;
    uint256 private lastDrawTime;
    uint256 minimumToPlay = 50 trx;
    uint256 minimumToDraw = 1000 trx;

    mapping(uint128 => PreviousGameResult) previousGameResults;
    mapping(uint48 => Player) players;
    mapping(address => uint48) playersIndex;

    // Structs
    struct Player {
        address payable playerAddress;
        uint256 value;
    }

    struct PreviousGameResult {
        address[] winners;
        address[] earlyBirds;
        address drawerAddress;
        uint48 numberOfPlayers;
        uint48 roundNumber;
        uint256 drawTime;
        uint256 totalPrize;
        uint256 blockNumber;
    }

    // Constructor
    constructor() public {
        lastDrawTime = block.timestamp;
        currentRoundNumber = 1;
    }

    // Modifiers
    modifier validValue() {
        require(
            msg.value >= minimumToPlay,
            "Minimum amount to play is not reached."
        );
        _;
    }

    modifier validRoundNumber(uint256 _roundNumber) {
        require(
            _roundNumber == currentRoundNumber,
            "You are too late for this round."
        );
        _;
    }

    modifier validMinimums(
        uint16 _newMinimumPlayers,
        uint48 _newSecondsUntilDrawIsOpen,
        uint256 _newMinimumToPlay,
        uint256 _newMinimumToDraw
    ) {
        require(
            _newSecondsUntilDrawIsOpen >= 3600 &&
            _newSecondsUntilDrawIsOpen <= 604800 &&
            _newMinimumToPlay >= 50 trx &&
            _newMinimumToPlay <= 500 trx &&
            _newMinimumToDraw >= 500 trx &&
            _newMinimumToDraw <= 500000 trx &&
            _newMinimumPlayers >= 5 &&
            _newMinimumPlayers <= 1000,
            "Minimums are not in valid range."
        );
        _;
    }

    modifier validToDraw() {
        require(
            totalPrizeThisRound >= minimumToDraw &&
                numberOfPlayersThisRound >= minimumPlayers,
            "Minimum amount or minimum players is not reached."
        );
        _;
    }

    modifier validToDrawTime() {
        require(
            block.timestamp > lastDrawTime + secondsUntilDrawIsOpen,
            "Too early to draw."
        );
        _;
    }

    modifier isPlayerInThisRound() {
        uint48 index = playersIndex[msg.sender];
        require(
            index > 0 &&
                index <= numberOfPlayersThisRound &&
                players[index].playerAddress == msg.sender,
            "Player not eligible to draw."
        );
        _;
    }

    // Payable Public Functions
    /*
        @function Allows a player to enter the current round
        @param uint256 _roundNumber The round number (must be the current round)
        @return string Success message
    */
    function enter(uint256 _roundNumber)
        public
        payable
        validValue
        validRoundNumber(_roundNumber)
        returns (string memory)
    { 
        return enterThirdParty(_roundNumber, msg.sender);
    }
  
    /*
        @function Allows a player to enter the current round
        @param uint256 _roundNumber The round number (must be the current round)
        @return string Success message
    */
    function enterThirdParty(uint256 _roundNumber, address payable _toAddress)
        public
        payable
        validValue
        validRoundNumber(_roundNumber)
        returns (string memory)
    {
        totalPrizeThisRound += msg.value;
        uint48 index = playersIndex[_toAddress];

        if (
            index > numberOfPlayersThisRound ||
            index == 0 ||
            players[index].playerAddress != _toAddress
        ) {
            numberOfPlayersThisRound++;
            players[numberOfPlayersThisRound] = Player(_toAddress, msg.value);
            playersIndex[_toAddress] = numberOfPlayersThisRound;
        } else players[index].value += msg.value;

        return "You're now in the draw. Good luck.";
    }

    /*
        @function Allows a player to attempt to Draw the current round
        @return address[] A list of the 3 Placed winners
    */
    function draw()
        public
        payable
        validToDraw
        validToDrawTime
        isPlayerInThisRound
        returns (address payable[] memory)
    {
        address payable[] memory winners = new address payable[](3);
        address emptyAddress;
        uint256 totalValue = 0;
        uint256 maxrnd = totalPrizeThisRound;
        uint256 rnds = random(maxrnd, 1);
        uint32 _count = 0;
        uint32 i = 0;

        while (_count < 3) {
            totalValue += players[i].value;

            if (winners[0] == emptyAddress) {
                if (totalValue > rnds) {
                    winners[0] = players[i].playerAddress;
                    totalValue = 0;
                    _count++;
                    maxrnd -= players[i].value;
                    rnds = random(maxrnd, 2);
                    players[i].value = 0;
                    i = 0;
                    continue;
                }
            } else if (winners[1] == emptyAddress) {
                if (totalValue > rnds) {
                    winners[1] = players[i].playerAddress;
                    totalValue = 0;
                    _count++;
                    maxrnd -= players[i].value;
                    rnds = random(maxrnd, 3);
                    players[i].value = 0;
                    i = 0;
                    continue;
                }
            } else if (winners[2] == emptyAddress) {
                if (totalValue > rnds) {
                    winners[2] = players[i].playerAddress;
                    _count++;
                }
            }
            i++;
        }

        winners[0].transfer((totalPrizeThisRound * winner1RewardShare) / 1000);
        winners[1].transfer((totalPrizeThisRound * winner2RewardShare) / 1000);
        winners[2].transfer((totalPrizeThisRound * winner3RewardShare) / 1000);
        msg.sender.transfer((totalPrizeThisRound * drawerRewardShare) / 1000);

        players[1].playerAddress.transfer(
            (totalPrizeThisRound * earlybirdRewardShare) / 1000
        );
        players[2].playerAddress.transfer(
            (totalPrizeThisRound * earlybirdRewardShare) / 1000
        );
        players[3].playerAddress.transfer(
            (totalPrizeThisRound * earlybirdRewardShare) / 1000
        );
        players[4].playerAddress.transfer(
            (totalPrizeThisRound * earlybirdRewardShare) / 1000
        );
        players[5].playerAddress.transfer(
            (totalPrizeThisRound * earlybirdRewardShare) / 1000
        );
        owner.transfer(address(this).balance);

        previousGameResults[currentRoundNumber].winners = winners;
        previousGameResults[currentRoundNumber].earlyBirds = earlyBirdList();
        previousGameResults[currentRoundNumber]
            .roundNumber = currentRoundNumber;
        previousGameResults[currentRoundNumber]
            .totalPrize = totalPrizeThisRound;
        previousGameResults[currentRoundNumber]
            .numberOfPlayers = numberOfPlayersThisRound;
        previousGameResults[currentRoundNumber].drawTime = block.timestamp;
        previousGameResults[currentRoundNumber].blockNumber = block.number;
        previousGameResults[currentRoundNumber].drawerAddress = msg.sender;

        numberOfPlayersThisRound = 0;
        currentRoundNumber++;
        totalPrizeThisRound = 0;
        lastDrawTime = block.timestamp;
        return winners;
    }

    /*
        @function Allows admin to change the minimum requirments of the game.
        @return string Success message
    */
    function updateMinimums(
        uint16 _newMinimumPlayers,
        uint48 _newSecondsUntilDrawIsOpen,
        uint256 _newMinimumToPlay,
        uint256 _newMinimumToDraw
    )
        public
        onlyOwner
        validMinimums(
            _newMinimumPlayers,
            _newSecondsUntilDrawIsOpen,
            _newMinimumToPlay,
            _newMinimumToDraw
        )
        returns (string memory)
    {
        secondsUntilDrawIsOpen = _newSecondsUntilDrawIsOpen;
        minimumToPlay = _newMinimumToPlay;
        minimumToDraw = _newMinimumToDraw;
        minimumPlayers = _newMinimumPlayers;
        return "Minimums are set";
    }

    /*
        @function Get results for a previous round
        @param uint256 roundNum The round number (must prior to the current round)
    */
    function getPreviousGameResult(uint128 roundNum)
        public
        view
        returns (
            address[3] memory winners,
            address[5] memory earlyBirds,
            address drawerAddress,
            uint48 numberOfPlayers,
            uint128 roundNumber,
            uint256 totalPrize,
            uint256 drawTime,
            uint256 blockNumber
        )
    {
        require(
            roundNum > 0 && roundNum < currentRoundNumber,
            "Invalid round number."
        );
        winners[0] = previousGameResults[roundNum].winners[0];
        winners[1] = previousGameResults[roundNum].winners[1];
        winners[2] = previousGameResults[roundNum].winners[2];
        earlyBirds[0] = previousGameResults[roundNum].earlyBirds[0];
        earlyBirds[1] = previousGameResults[roundNum].earlyBirds[1];
        earlyBirds[2] = previousGameResults[roundNum].earlyBirds[2];
        earlyBirds[3] = previousGameResults[roundNum].earlyBirds[3];
        earlyBirds[4] = previousGameResults[roundNum].earlyBirds[4];
        drawerAddress = previousGameResults[roundNum].drawerAddress;
        roundNumber = previousGameResults[roundNum].roundNumber;
        totalPrize = previousGameResults[roundNum].totalPrize;
        numberOfPlayers = previousGameResults[roundNum].numberOfPlayers;
        drawTime = previousGameResults[roundNum].drawTime;
        blockNumber = previousGameResults[roundNum].blockNumber;
    }

    /*
        @function Get game stats for the current round
    */
    function gameStats()
        public
        view
        returns (
            uint256 _totalPrizeThisRound,
            uint256 _lastDrawTime,
            uint256 _remainTime,
            uint256 _minimumToPlay,
            uint256 _numberOfPlayers,
            uint256 _minimumToDraw,
            uint256 _minimumPlayers,
            uint16 _winner1RewardShare,
            uint16 _winner2RewardShare,
            uint16 _winner3RewardShare,
            uint16 _drawerRewardShare,
            uint16 _earlybirdRewardShare,
            uint256 _currentRoundNumber,
            address[] memory _earlybirds
        )
    {
        _currentRoundNumber = currentRoundNumber;
        _totalPrizeThisRound = totalPrizeThisRound;
        _numberOfPlayers = numberOfPlayersThisRound;
        _lastDrawTime = lastDrawTime;
        _remainTime = remainTime();
        _minimumToPlay = minimumToPlay;
        _minimumToDraw = minimumToDraw;
        _minimumPlayers = minimumPlayers;
        _winner1RewardShare = winner1RewardShare;
        _winner2RewardShare = winner2RewardShare;
        _winner3RewardShare = winner3RewardShare;
        _drawerRewardShare = drawerRewardShare;
        _earlybirdRewardShare = earlybirdRewardShare;
        _earlybirds = earlyBirdList();
    }

    /*
        @function Get the latest 20 players in the current round
        @return {address[], values[]} An object with arrays of addresses and entry values
    */
    function playerList()
        public
        view
        returns (address[] memory _addresses, uint256[] memory _values)
    {
        if (numberOfPlayersThisRound == 0) {
            return (_addresses, _values);
        }
        uint256 max = 20;
        if (numberOfPlayersThisRound < max) {
            max = numberOfPlayersThisRound;
        }
        _values = new uint256[](max);
        _addresses = new address[](max);

        for (uint48 i = 0; i < max; i++) {
            _addresses[i] = players[numberOfPlayersThisRound - i].playerAddress;
            _values[i] = players[numberOfPlayersThisRound - i].value;
        }
    }

    /*
        @function Get the entry amount for a player
        @param address _address The players address
        @return uint256 The players entry amount
    */
    function playerTotal(address _address) public view returns (uint256) {
        uint48 index = playersIndex[_address];
        if (
            index > numberOfPlayersThisRound ||
            index == 0 ||
            players[index].playerAddress != _address
        ) {
            return 0;
        }

        return players[index].value;
    }

    /// Private Functions
    function remainTime() private view returns (uint256) {
        int256 time = int256(
            secondsUntilDrawIsOpen + lastDrawTime - block.timestamp
        );
        if (time < 0) return 0;
        else return uint256(time);
    }

    function random(uint256 max, uint8 randomnessType)
        private
        view
        returns (uint256)
    {
        uint256 timeNow = block.timestamp;
        if (randomnessType == 1) {
            return
                uint256(
                    keccak256(
                        abi.encodePacked(
                            timeNow * block.difficulty * block.number,
                            timeNow + totalPrizeThisRound,
                            totalPrizeThisRound * timeNow,
                            block.coinbase,
                            block.coinbase
                        )
                    )
                ) % max;
        } else if (randomnessType == 2) {
            return
                uint256(
                    keccak256(
                        abi.encodePacked(
                            timeNow * block.number,
                            timeNow + block.difficulty + totalPrizeThisRound,
                            block.number + totalPrizeThisRound,
                            block.coinbase,
                            msg.sender
                        )
                    )
                ) % max;
        } else {
            return
                uint256(
                    keccak256(
                        abi.encodePacked(
                            timeNow * block.difficulty,
                            timeNow + block.number,
                            totalPrizeThisRound + block.difficulty + timeNow,
                            block.number * block.number + block.difficulty,
                            block.coinbase
                        )
                    )
                ) % max;
        }
    }

    function earlyBirdList()
        private
        view
        returns (address[] memory _addresses)
    {
        if (numberOfPlayersThisRound == 0) {
            return _addresses;
        }

        uint48 max = 5;
        if (numberOfPlayersThisRound < max) {
            max = numberOfPlayersThisRound;
        }
        _addresses = new address[](max);

        for (uint48 i = 0; i < max; i++) {
            _addresses[i] = players[i + 1].playerAddress;
        }
    }
}