// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";
import "GolfMatch.sol";

contract MatchFactory {

    address owner;
    GolfMatch[] public matches;
    mapping(address => GolfMatch) public addressToGolfMatch;
    mapping(address => address[]) public playerAddressToMatchAdresses;

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

    function add_player(address _player, address _match) public {
        
        playerAddressToMatchAdresses[_player].push(_match);
    }

    function remove_player(address _player, address _match) public {
     
        //Remove from Factory
    }

    function query_player_address(address _player) public view returns(address[] memory) {
        return playerAddressToMatchAdresses[_player];
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
        Score score;
        bool isCoordinator;
    }

    enum MATCH_STATE {
        PLACE_BETS,
        PLAYING,
        SCORES_POSTED,
        PAYOUT
    }
    MATCH_STATE public match_state;

    MatchFactory private factory;
    Player[] public players;
    address public coordinator;
    string public match_name;
    uint256 private scores_reported;
    uint256 front_score;
    uint256 back_score;
    uint256 total_score;

    mapping(address => Player) public addressToPlayer;

    event OnPlayerAdded(string player_name, address player_address);
    event OnPlayerInfoUpdated(address player_address, Player player);
    event OnScorePosted(string player_name, address player_Address);
    event OnMatchStarted(string match_name, address match_address);
    event OnMatchEnded(string match_name, address match_address);

    constructor(string memory _match_name, address _coordintator_address, address factory_address) {
        factory = MatchFactory(factory_address);
        coordinator = _coordintator_address;
        match_name = _match_name;
        scores_reported = 0;
        front_score = 999;
        back_score = 999;
        total_score = 999;

        match_state = MATCH_STATE.PLACE_BETS;
    }

    function startMatch() public {

        require(msg.sender == coordinator, "only the coordinator role can start the match!");

        match_state = MATCH_STATE.PLAYING;

        emit OnMatchStarted(match_name, address(this));
    }

    function endMatch() public payable {
        require(msg.sender == coordinator, "only the coordinator role can start the match!");
        require(match_state == MATCH_STATE.PAYOUT, "Match not in payout mode yet...");

        //Pay everyone who won money
        for(uint i=0; i < players.length; ++i) {
            Player memory player = addressToPlayer[players[i].addr];
            if (player.winnings > 0) {
                address payable wallet = payable(player.addr);
                wallet.transfer(player.winnings);
            }
        }

        emit OnMatchEnded(match_name, address(this));
    }

    function get_match_status() public view returns (string memory name, Player[] memory player_list) {
        Player[] memory all_players = new Player[](players.length);
        for(uint i = 0; i < players.length; ++i) {
            all_players[i] = addressToPlayer[players[i].addr];
        }
        return(match_name, all_players);
    }

    function add_player(string memory _player_name, address _address) public {

        bool isCoordinator = _address == coordinator ? true : false;
        Player memory new_player = Player(_address, _player_name, 0, 0, 0, Score(0,0,0), isCoordinator);

        players.push(new_player);

        addressToPlayer[_address] = new_player;

        //Add to Factory as well
        factory.add_player(_address, address(this));

        emit OnPlayerAdded(_player_name, _address);
    }

    function removePlayer(address _address) public {
        delete addressToPlayer[_address];
        
        for(uint i=0; i < players.length; i++) {
            if(_address == players[i].addr) {
                delete players[i];
            }
        }  
        //Also remove from Factory
        //....
    }

    function updatePlayerInfo(uint256 _handicap) public payable {

        addressToPlayer[msg.sender].bet += msg.value;
        addressToPlayer[msg.sender].handicap = _handicap;

        emit OnPlayerInfoUpdated(msg.sender, addressToPlayer[msg.sender]);
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
        }

        emit OnScorePosted(player.name, player.addr);
    }

    function calculate_winners() private {

        for(uint i = 0; i < players.length; ++i) {
            address player_address = players[i].addr;
            Player storage player = addressToPlayer[player_address];
            if(player.score.front < front_score) {
                front_score = player.score.front;
                player.winnings += player.bet / 3;
            }
            if(player.score.back < back_score) {
                back_score = player.score.back;
                player.winnings += player.bet / 3;
            }
            if(player.score.total < total_score) {
                total_score = player.score.total;
                player.winnings += player.bet / 3;
            }
        }

        match_state = MATCH_STATE.PAYOUT;
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