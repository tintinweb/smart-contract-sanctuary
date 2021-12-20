// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";
import "GolfMatch.sol";

contract MatchFactory {

    address owner;
    GolfMatch[] public matches;
    mapping(address => GolfMatch) public addressToGolfMatch;
    mapping(address => address) public playerAddressToMatchAdress;

    AggregatorV3Interface public priceFeed;

    event OnMatchCreated(string match_name, address match_address);

    constructor(address _priceFeed) {

        owner = msg.sender;

        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function createMatch(string memory coordinator_name, string memory _match_name) public {

        GolfMatch golfMatch = new GolfMatch(_match_name, msg.sender, address(this));

        matches.push(golfMatch);

        addressToGolfMatch[address(golfMatch)] = golfMatch;

        // Add the Coordinator by default
        golfMatch.add_player(coordinator_name, msg.sender);

        emit OnMatchCreated(_match_name, address(golfMatch));
    }

    function removeMatch(address match_address) public {
        delete addressToGolfMatch[match_address];
    }

    function add_player(address _player, address _match) public {
        
        require(playerAddressToMatchAdress[_player] == address(0), "Player is already in a match");

        playerAddressToMatchAdress[_player] = _match;
    }

    function remove_player(address _player) public {
        delete playerAddressToMatchAdress[_player];
    }

    function query_player_address(address _player) public view returns(address) {
        return playerAddressToMatchAdress[_player];
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    // Chainlink Price Feed
    function get_version() public view returns (uint256) {
        return priceFeed.version();
    }

    function get_price() public view returns(uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function get_dollar_to_eth(uint256 _dollar_amount) public view returns (uint256) {
        uint256 dollar_amount = _dollar_amount * 10**18;
        uint256 price = get_price();
        uint256 precision = 1 * 10**18;
        return (dollar_amount * precision) / price;
    }

    function get_eth_to_dollar(uint256 eth_amount) public view returns(uint256) {
        uint256 price = get_price();
        uint256 precision = 1 * 10**18;
        return (price / precision) * eth_amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

import "MatchFactory.sol";

pragma solidity >=0.6.0 <0.9.0;

contract GolfMatch {

    struct Score {
        uint256 front;
        uint256 back;
        uint256 total;
    }

    struct Player {
        address addr;
        string name;
        uint256 bet;
        uint256 handicap;
        uint256 winnings;
        uint256[3][] bets_won;
        Score score;
        bool isCoordinator;
    }

    struct Winner {
        Player player;
        string betName;
        uint256 amount;
    }

    enum MATCH_STATE {
        CREATED,
        STARTED,
        SCORES_POSTED,
        PAYOUT,
        ENDED
    }
    MATCH_STATE public match_state;

    MatchFactory private factory;
    Player[] public players;
    address public coordinator;
    string public match_name;
    uint256 private scores_reported;
    uint256 private wager_count;
    uint256 front_bet;
    uint256 back_bet;
    uint256 total_bet;
    uint256 FRONT=0;
    uint256 BACK=1;
    uint256 TOTAL=2;
    
    mapping(address => Player) public addressToPlayer;

    event OnScorePosted(MATCH_STATE state, Player player, Player[] players);
    event OnPlayerInfoUpdated(address player_Address, Player player, MATCH_STATE state, Player[] players);
    event OnPlayerAdded(string match_name, MATCH_STATE state, Player[] players);
    event OnMatchStarted(string match_name, MATCH_STATE state, Player[] players);
    event OnMatchEnded(string match_name, MATCH_STATE state, Player[] players);

    constructor(string memory _match_name, address _coordintator_address, address factory_address) {
        factory = MatchFactory(factory_address);
        coordinator = _coordintator_address;
        match_name = _match_name;
        scores_reported = 0;

        match_state = MATCH_STATE.CREATED;
    }

    function startMatch() public {

        require(msg.sender == coordinator, "only the coordinator role can start the match!");
        require(wager_count == players.length, "Not all bets are in.");

        uint256 balance = getBalance();
        front_bet = balance / 3;
        back_bet = front_bet;
        total_bet = balance - (front_bet + back_bet);

        match_state = MATCH_STATE.STARTED;

        emit OnMatchStarted(match_name, match_state, allPlayers());
    }

    function endMatch() private {
        //require(msg.sender == coordinator, "only the coordinator role can start the match!");
        require(match_state == MATCH_STATE.PAYOUT, "Match not in payout mode yet...");

        //Pay everyone who won money
        for(uint i=0; i < players.length; ++i) {
            Player storage player = addressToPlayer[players[i].addr];

            factory.remove_player(player.addr);

            if (player.winnings > 0) {
                address payable wallet = payable(player.addr);
                wallet.transfer(player.winnings);
            }
        }

        match_state = MATCH_STATE.ENDED;

        Player[] memory player_list = allPlayers();
        emit OnMatchEnded(match_name, match_state, player_list);
    }

    function deleteMatch() public {
        require(msg.sender == coordinator, "only the coordinator role can delete the match!");
        require(address(this).balance <= 1, "Can't kill a match with funds");

        factory.removeMatch(address(this));

        address payable kill = payable(address(this));
        selfdestruct(kill);
    }

    function get_match_status() public view returns (string memory name, MATCH_STATE state, Player[] memory player_list) {

        return(match_name, match_state, allPlayers());
    }

    function allPlayers() private view returns (Player[] memory player_list) {
        Player[] memory all_players = new Player[](players.length);
        for(uint i = 0; i < players.length; ++i) {
            all_players[i] = addressToPlayer[players[i].addr];
        }

        return all_players;
    }

    function add_player(string memory _player_name, address _address) public {
        
        require(addressToPlayer[_address].addr == address(0), "Player is already in this match" );

        bool isCoordinator = _address == coordinator ? true : false;
        uint256[3][] memory bets;
        Player memory new_player = Player(_address, _player_name, 0, 0, 0, bets, Score(0,0,0), isCoordinator);

        players.push(new_player);

        addressToPlayer[_address] = new_player;

        //Add to Factory as well
        factory.add_player(_address, address(this));

        emit OnPlayerAdded(match_name, match_state, allPlayers());
    }

    function removePlayer(address _address) public {
        require(msg.sender == coordinator, "only the coordinator role can remove players!");

        delete addressToPlayer[_address];
        
        for(uint i=0; i < players.length; i++) {
            if(_address == players[i].addr) {
                delete players[i];
            }
        } 

        factory.remove_player(_address);
    }

    function updatePlayerInfo(uint256 _handicap) public payable {
        require(addressToPlayer[msg.sender].bet == 0, "Wager already posted. You cannot change it.");

        addressToPlayer[msg.sender].bet += msg.value;
        addressToPlayer[msg.sender].handicap = _handicap;

        wager_count++;

        emit OnPlayerInfoUpdated(msg.sender, addressToPlayer[msg.sender], match_state, allPlayers());
    }

    function getBetForPlayer(address _address) public view returns(uint256) {
        return addressToPlayer[_address].bet;
    }

    function postScore(uint256 front, uint256 back) public {
        Player storage player = addressToPlayer[msg.sender];
        require(player.score.total == 0, "Player score has already been reported");

        uint256 total = front + back;

        player.score = Score(front, back, total);

        scores_reported += 1;

        if( scores_reported == players.length) {
            match_state = MATCH_STATE.SCORES_POSTED;
            calculate_winners();
        } else {
            emit OnScorePosted(match_state, player, allPlayers());
        }
    }

    function calculate_winners() private {
        uint256 front_score = 9999;
        uint256 back_score = 9999;
        uint256 total_score = 9999;
        Player[] memory front_winners = new Player[](players.length);
        Player[] memory back_winners = new Player[](players.length);
        Player[] memory total_winners = new Player[](players.length);
        uint index_front = 0;
        uint index_back = 0;
        uint index_total = 0;
        //Find lowest score
        for(uint i = 0; i < players.length; ++i) {
            address player_address = players[i].addr;
            Player storage player = addressToPlayer[player_address];

            uint netScore = (player.score.front * 10) - ((player.handicap * 10)/2);
            if(netScore < front_score) {
                front_winners = new Player[](players.length);
                index_front = 0;
            }
            if(netScore <= front_score) {
                front_winners[index_front] = player;
                front_score = netScore;
                index_front++;
            }

            netScore = (player.score.back * 10) - ((player.handicap * 10)/2);
            if(netScore < back_score) {
                back_winners  = new Player[](players.length);
                index_back = 0;
            }
            if(netScore <= back_score) {
                back_winners[index_back] = player;
                back_score = netScore;
                index_back++;
            }

            netScore = (player.score.total * 10) - (player.handicap * 10);
            if(netScore < total_score) {
                total_winners = new Player[](players.length);
                index_total = 0;
            }
            if(netScore <= total_score) {
                total_winners[index_total] = player;
                total_score = netScore;
                index_total++;
            }
        }
        
        for(uint i = 0; i < index_front; ++i) {
            Player storage p = addressToPlayer[front_winners[i].addr];
            uint256 bet = front_bet / index_front;
            p.winnings += bet;
            p.bets_won.push([FRONT, bet, p.score.front]);
        }
        for(uint i = 0; i < index_back; ++i) {
            Player storage p = addressToPlayer[back_winners[i].addr];
            uint256 bet = back_bet / index_back;
            p.winnings += bet;
            p.bets_won.push([BACK, bet, p.score.back]);
        }
        for(uint i = 0; i < index_total; ++i) {
            Player storage p = addressToPlayer[total_winners[i].addr];
            uint256 bet = total_bet / index_total;
            p.winnings += bet;
            p.bets_won.push([TOTAL, bet, p.score.total]);
        }

        match_state = MATCH_STATE.PAYOUT;

        endMatch();
    }

    function getPlayerAtIndex(uint index) public view returns(string memory name, address player) {
        return (players[index].name, players[index].addr);
    }

    function getPlayerCount() public view returns(uint count) {
        return players.length;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
}