// SPDX-License-Identifier: ABC

// pragma solidity ^0.4.2;
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";


// import "./football.sol";

contract FootballManagerBet {
    struct Bet {
        uint256 stake;
        uint256 win;
        address sender;
    }

    enum Result {
        HOMETEAMWIN,
        AWAYTEAMWIN,
        DRAW,
        PENDING,
        UNKNOWN
    }

    struct Game {
        string gameId;
        uint256 betValue;
        string date;
        string status;
        string homeTeam;
        string awayTeam;
        string homeFur;
        string awayFur;
        address ownerPlayer;
        address oppositePlayer;
        uint256 homeTeamGoals;
        uint256 awayTeamGoals;
        uint256 totalStake;
        bool isCancel;
        bool isFinish;
        Result result;
        uint256 receivedGoalMsgs;
        mapping(uint8 => Bet[]) bets;
        mapping(uint8 => uint256) betSums;
        mapping(address => uint256) pendingWithdrawals;
    }

    struct GameInfo {
        string gameId;
        uint256 betValue;
        string date;
        string status;
        string homeTeam;
        string awayTeam;
        string homeFur;
        string awayFur;
        address ownerPlayer;
        address oppositePlayer;
        uint256 homeTeamGoals;
        uint256 awayTeamGoals;
        uint256 totalStake;
        bool isCancel;
        bool isFinish;
        string resultMessage;
    }

    mapping(string => Game) games;
    string[] indexGames;

    event BetEvent(uint256 stake, uint256 win, address sender);

    // function inquiryHttp() public view returns (string[] memory) {
    //     string memory url = generateUrl("http://ip.jsontest.com");
    //     return url;
    // }

    function getListGamesIndex() public view returns (string[] memory) {
        return indexGames;
    }

    function inquiryGame(string memory gameId)
        private
        view
        returns (Game storage)
    {
        Game storage game = games[gameId];
        return game;
    }

    function inquiryBets(string memory gameId, uint8 _bet)
        public
        view
        returns (Bet[] memory)
    {
        Game storage game = inquiryGame(gameId);
        Bet[] memory bets = game.bets[_bet];
        return bets;
    }

    function inquiryPendingWithdrawals(string memory gameId, address address1)
        public
        view
        returns (uint256)
    {
        Game storage game = inquiryGame(gameId);
        return game.pendingWithdrawals[address1];
    }

    function cancelGame(string memory gameId) public payable {
        Game storage game = inquiryGame(gameId);
        game.isCancel = true;
    }

    function placeBet(string memory gameId, uint8 _bet) public payable {
        require(msg.value > 0, "input bet cannot zero");

        Game storage game = inquiryGame(gameId);
        // string memory errMsg = string(
        //     abi.encodePacked("bet value not same", game.betValue)
        // );
        // require(msg.value == game.betValue, errMsg);
        require(msg.value == game.betValue, "bet value not same");

        Bet memory b = Bet(msg.value, 0, msg.sender);
        require(game.isCancel == false, "game is cancelled");
        require(game.isFinish == false, "game is finish");
        require(game.totalStake < 2, "max player is 2");
        game.bets[_bet].push(b);
        game.betSums[_bet] += msg.value;

        if (game.ownerPlayer != msg.sender) {
            game.oppositePlayer = msg.sender;
        }
        // game.totalStake++;
        game.totalStake = game.totalStake + 1;
        emit BetEvent(b.stake, b.win, b.sender);
    }

    function infoPlaceBetSum(string memory gameId, uint8 _bet)
        public
        view
        returns (uint256)
    {
        Game storage game = inquiryGame(gameId);
        uint256 output = game.betSums[_bet];
        return output;
    }

    function inquiryGameStatus(string memory gameId)
        public
        view
        returns (string memory)
    {
        Game storage game = inquiryGame(gameId);
        return game.status;
    }

    function inquiryGameInfo(string memory gameId)
        public
        view
        returns (GameInfo memory)
    {
        Game storage game = inquiryGame(gameId);
        string memory result = getResult(gameId);
        GameInfo memory gameInfo = GameInfo(
            gameId,
            game.betValue,
            game.date,
            game.status,
            game.homeTeam,
            game.awayTeam,
            game.homeFur,
            game.awayFur,
            game.ownerPlayer,
            game.oppositePlayer,
            game.homeTeamGoals,
            game.awayTeamGoals,
            game.totalStake,
            game.isCancel,
            game.isFinish,
            result
        );

        return gameInfo;
    }

    function inquiryGameDescription(string memory gameId)
        public
        view
        returns (string memory)
    {
        Game storage game = inquiryGame(gameId);
        string memory homeTeamGoals = Strings.toString(game.homeTeamGoals);
        string memory awayTeamGoals = Strings.toString(game.awayTeamGoals);

        string memory output = string(
            abi.encodePacked(
                game.gameId,
                " - ",
                game.status,
                " - ",
                game.homeTeam,
                " - ",
                game.awayTeam,
                " - ",
                homeTeamGoals,
                " - ",
                awayTeamGoals
            )
        );
        return output;
    }

    function createGame(
        string memory gameId,
        string memory homeTeam,
        string memory awayTeam,
        uint256 betValue,
        string memory homeFur,
        string memory awayFur
    ) public payable {
        Game storage game = games[gameId];
        game.gameId = gameId;
        game.status = "init";
        game.homeTeam = homeTeam;
        game.awayTeam = awayTeam;
        game.homeTeamGoals = 1000;
        game.awayTeamGoals = 1000;
        game.result = Result.UNKNOWN;
        game.ownerPlayer = msg.sender;
        game.homeFur = homeFur;
        game.awayFur = awayFur;
        game.betValue = betValue;
        indexGames.push(gameId);
    }

    function compareStrings(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function updateGame(
        string memory gameId,
        string memory status,
        uint256 homeTeamGoals,
        uint256 awayTeamGoals
    ) public payable {
        Game storage game = inquiryGame(gameId);
        require(
            game.ownerPlayer == msg.sender,
            "Ownable: caller is not the owner"
        );
        game.status = status;

        game.homeTeamGoals = homeTeamGoals;
        game.awayTeamGoals = awayTeamGoals;

        game.result = determineResult(game.homeTeamGoals, game.awayTeamGoals);
    }

    function updateFur(
        string memory gameId,
        string memory homeFur,
        string memory awayFur
    ) public payable {
        Game storage game = inquiryGame(gameId);
        require(
            game.ownerPlayer == msg.sender,
            "Ownable: caller is not the owner"
        );
        require(
            game.oppositePlayer == address(0),
            "opposite player already set"
        );

        game.homeFur = homeFur;
        game.awayFur = awayFur;
    }

    function updateGameInfo(
        string memory gameId,
        string memory homeTeam,
        string memory awayTeam
    ) public payable {
        Game storage game = inquiryGame(gameId);
        require(
            game.ownerPlayer == msg.sender,
            "Ownable: caller is not the owner"
        );
        require(
            game.oppositePlayer == address(0),
            "opposite player already set"
        );
        game.homeTeam = homeTeam;
        game.awayTeam = awayTeam;
    }

    function getResult(string memory gameId)
        public
        view
        returns (string memory)
    {
        Game storage game = inquiryGame(gameId);
        string memory result = "N/A";
        if (game.result == Result.HOMETEAMWIN) {
            result = "homeTeamWin";
        } else if (game.result == Result.AWAYTEAMWIN) {
            result = "awayTeamWin";
        } else if (game.result == Result.DRAW) {
            result = "draw";
        }

        return result;
    }

    function withdraw(string memory gameId) public payable returns (bool) {
        Game storage game = inquiryGame(gameId);
        uint256 amount = game.pendingWithdrawals[msg.sender];
        game.pendingWithdrawals[msg.sender] = 0;
        // lastWithdraw = msg.sender;
        if (payable(msg.sender).send(amount)) {
            return true;
        } else {
            game.pendingWithdrawals[msg.sender] = amount;
            return false;
        }
    }

    function determineResult(uint256 homeTeam, uint256 awayTeam)
        private
        pure
        returns (Result)
    {
        if (homeTeam > awayTeam) {
            return Result.HOMETEAMWIN;
        }
        if (homeTeam == awayTeam) {
            return Result.DRAW;
        }
        return Result.AWAYTEAMWIN;
    }

    function inquiryBetStakePerAddress(
        string memory gameId,
        uint8 _bet,
        address input
    ) public view returns (uint256) {
        Game storage game = inquiryGame(gameId);
        uint256 total = 0;
        Bet[] memory items = game.bets[_bet];
        for (uint256 i = 0; i < items.length; i++) {
            Bet memory b = items[i];
            if (b.sender == input) {
                total = total + b.stake;
            }
        }
        return total;
    }

    function inquiryBetWinPerAddress(
        string memory gameId,
        uint8 _bet,
        address input
    ) public view returns (uint256) {
        Game storage game = inquiryGame(gameId);
        uint256 total = 0;
        Bet[] memory items = game.bets[_bet];
        for (uint256 i = 0; i < items.length; i++) {
            Bet memory b = items[i];
            if (b.sender == input) {
                uint256 win = b.win;
                total = total + win;
            }
        }
        return total;
    }

    function inquiryWinPerWei(string memory gameId, uint8 type1)
        public
        view
        returns (uint256)
    {
        Game storage game = inquiryGame(gameId);
        uint256 loosingStake = game.betSums[type1];
        uint256 winPerWei = loosingStake / game.betSums[uint8(game.result)];
        return winPerWei;
    }

    function inquiryLoosingStakeTotal(string memory gameId)
        public
        view
        returns (uint256)
    {
        Game storage game = inquiryGame(gameId);
        // uint256 loosingStake = betSums[uint8(Result.HOMETEAMWIN)];
        uint256 loosingStake = game.betSums[0] +
            game.betSums[1] +
            game.betSums[2];
        return loosingStake;
    }

    function setWinners(string memory gameId) public {
        uint256 loosingStake = 0;
        Game storage game = inquiryGame(gameId);
        require(game.isFinish == false, "game is finish");

        if (game.result != Result.HOMETEAMWIN) {
            loosingStake += game.betSums[uint8(Result.HOMETEAMWIN)];
        }

        if (game.result != Result.AWAYTEAMWIN) {
            loosingStake += game.betSums[uint8(Result.AWAYTEAMWIN)];
        }

        if (game.result != Result.DRAW) {
            loosingStake += game.betSums[uint8(Result.DRAW)];
        }

        // determine the win per wei
        uint256 winPerWei = loosingStake / game.betSums[uint8(game.result)];

        for (uint256 i = 0; i < game.bets[uint8(game.result)].length; i++) {
            Bet memory b = game.bets[uint8(game.result)][i];
            b.win = winPerWei * b.stake;
            BetEvent(b.stake, b.win, b.sender);
            game.pendingWithdrawals[b.sender] = b.stake + b.win;
        }
        game.isFinish = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

