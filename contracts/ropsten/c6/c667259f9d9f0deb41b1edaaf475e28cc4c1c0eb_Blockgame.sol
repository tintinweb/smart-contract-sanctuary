contract Blockgame {

  uint public ENTRY_FEE = 0.075 ether;
  uint public POINTS_TO_SPEND = 150;
  uint public TEAMS_PER_ENTRY = 6;
  uint public MAX_ENTRIES = 200;

  address public owner;
  uint[6] public payoutPercentages;
  uint public debt;

  uint[] public allTeamsCosts;
  uint[] public allTeamsScores;

  DailyGame[] public allTimeGames;
  mapping(uint => bool) public gamesList; //uint == dateOfGame...does this game exist?
  mapping(uint => DailyGame) public gameRecords; // uint == dateOfGame
  mapping(address => uint) public availableWinnings;

  event NewEntry(address indexed player, uint[] selectedTeams);

  struct Entry {
    uint timestamp;
    uint[] teamsSelected;
    address player;
    uint entryIndex;
  }

  // Pre and post summary
  struct DailyGame {
    uint numPlayers;
    uint pool;
    uint date;
    uint closedTime;
    uint[] playerScores; // A
    uint[] topPlayersScores; // B
    uint[] winnerAmounts; // C
    address[] players; // A
    uint[] topPlayersIndices; // B
    address[] topPlayersAddresses; // B
    address[] winnerAddresses; // C
    Entry[] entries;
  }

  constructor(){
    owner = msg.sender;

    payoutPercentages[0] = 0;
    payoutPercentages[1] = 50;
    payoutPercentages[2] = 16;
    payoutPercentages[3] = 12;
    payoutPercentages[4] = 8;
    payoutPercentages[5] = 4;
  }


  //UTILITIES
  function() external payable { }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function changeEntryFee(uint _value) onlyOwner {
    ENTRY_FEE = _value;
  }

  function changeMaxEntries(uint _value) onlyOwner {
    MAX_ENTRIES = _value;
  }

  //submit alphabetically
  function changeTeamCosts(uint[] _costs) onlyOwner {
    allTeamsCosts = _costs;
  }

  function changeAvailableSpend(uint _value) onlyOwner {
    POINTS_TO_SPEND = _value;
  }

  // _closedTime == Unix timestamp
  function createGame(uint _gameDate, uint _closedTime) onlyOwner {
    gamesList[_gameDate] = true;
    gameRecords[_gameDate].closedTime = _closedTime;
  }

  function withdraw(uint amount) onlyOwner returns(bool) {
    require(amount <= (address(this).balance - debt));
    owner.transfer(amount);
    return true;
  }

  function selfDestruct() onlyOwner {
    selfdestruct(owner);
  }


  // SUBMITTING AN ENTRY

  // Verify that game exists
  modifier gameOpen(uint _gameDate) {
    require(gamesList[_gameDate] == true);
    _;
  }

  // Verify that teams selection is within cost
  modifier withinCost(uint[] teamIndices) {
      require(teamIndices.length == 6);
      uint sum = 0;

      for(uint i = 0;i < 6; i++){
        uint cost = allTeamsCosts[teamIndices[i]];
        sum += cost;
      }

      require(sum <= POINTS_TO_SPEND);
      _;
  }

  // Verify that constest hasn&#39;t closed
  modifier beforeCutoff(uint _date) {
    require(gameRecords[_date].closedTime > currentTime());
    _;
  }

  function createEntry(uint date, uint[] teamIndices) payable
                       withinCost(teamIndices)
                       gameOpen(date)
                       beforeCutoff(date)
                       external {

    require(msg.value == ENTRY_FEE);
    require(gameRecords[date].numPlayers < MAX_ENTRIES);

    Entry memory entry;
    entry.timestamp = currentTime();
    entry.player = msg.sender;
    entry.teamsSelected = teamIndices;

    gameRecords[date].entries.push(entry);
    gameRecords[date].numPlayers++;
    gameRecords[date].pool += ENTRY_FEE;

    uint entryIndex = gameRecords[date].players.push(msg.sender) - 1;
    gameRecords[date].entries[entryIndex].entryIndex = entryIndex;

    emit NewEntry(msg.sender, teamIndices);
  }


  // ANALYZING SCORES

  // Register teams (alphabetically) points total for each game
  function registerTeamScores(uint[] _scores) onlyOwner {
    allTeamsScores = _scores;
  }

  function registerTopPlayers(uint _date, uint[] _topPlayersIndices, uint[] _topScores) onlyOwner {
    gameRecords[_date].topPlayersIndices = _topPlayersIndices;
    for(uint i = 0; i < _topPlayersIndices.length; i++){
      address player = gameRecords[_date].entries[_topPlayersIndices[i]].player;
      gameRecords[_date].topPlayersAddresses.push(player);
    }
    gameRecords[_date].topPlayersScores = _topScores;
  }

  // Allocate winnings to top 5 (or 5+ if ties) players
  function generateWinners(uint _date) onlyOwner {
    /* require(gameRecords[_date].closedTime < currentTime()); */
    /* require(gameRecords[_date].topPlayersIndices.length != 0); */
    uint place = 1;
    uint iterator = 0;
    uint placeCount = 1;
    uint currentScore = 1;
    uint percentage = 0;
    uint amount = 0;

    while(place <= 5){
      currentScore = gameRecords[_date].topPlayersScores[iterator];
      if(gameRecords[_date].topPlayersScores[iterator + 1] == currentScore){
        placeCount++;
        iterator++;
      } else {
        amount = 0;

        if(placeCount > 1){
          percentage = 0;
          for(uint n = place; n <= (place + placeCount);n++){
            if(n <= 5){
              percentage += payoutPercentages[n];
            }
          }
          amount = gameRecords[_date].pool / placeCount * percentage / 100;
        } else {
          amount = gameRecords[_date].pool * payoutPercentages[place] / 100;
        }


        for(uint i = place - 1; i < (place + placeCount - 1); i++){
          address winnerAddress = gameRecords[_date].entries[gameRecords[_date].topPlayersIndices[i]].player;
          gameRecords[_date].winnerAddresses.push(winnerAddress);
          gameRecords[_date].winnerAmounts.push(amount);
        }

        iterator++;
        place += placeCount;
        placeCount = 1;
      }

    }
    allTimeGames.push(gameRecords[_date]);
  }

  function assignWinnings(uint _date) onlyOwner {
    address[] storage winners = gameRecords[_date].winnerAddresses;
    uint[] storage winnerAmounts = gameRecords[_date].winnerAmounts;

    for(uint z = 0; z < winners.length; z++){
      address currentWinner = winners[z];
      uint currentRedeemable = availableWinnings[currentWinner];
      uint newRedeemable = currentRedeemable + winnerAmounts[z];
      availableWinnings[currentWinner] = newRedeemable;
      debt += winnerAmounts[z];
    }
  }

  function redeem() external returns(bool success) {
    require(availableWinnings[msg.sender] > 0);
    uint amount = availableWinnings[msg.sender];
    availableWinnings[msg.sender] = 0;
    debt -= amount;
    msg.sender.transfer(amount);
    return true;
  }

  function getAvailableWinnings(address _address) view returns(uint amount){
    return availableWinnings[_address];
  }


  // OTHER USEFUL FUNCTIONS / TESTING

  function currentTime() view returns (uint _currentTime) {
    return now;
  }

  function getPointsToSpend() view returns(uint _POINTS_TO_SPEND) {
    return POINTS_TO_SPEND;
  }

  function getGameNumberOfEntries(uint _date) view returns(uint _length){
    return gameRecords[_date].entries.length;
  }

  function getCutoffTime(uint _date) view returns(uint cutoff){
    return gameRecords[_date].closedTime;
  }

  function getTeamScore(uint _teamIndex) view returns(uint score){
    return allTeamsScores[_teamIndex];
  }

  function getAllTeamScores() view returns(uint[] scores){
    return allTeamsScores;
  }

  function getAllPlayers(uint _date) view returns(address[] _players){
    return gameRecords[_date].players;
  }

  function getTopPlayerScores(uint _date) view returns(uint[] scores){
    return gameRecords[_date].topPlayersScores;
  }

  function getTopPlayers(uint _date) view returns(address[] _players){
    return gameRecords[_date].topPlayersAddresses;
  }

  function getWinners(uint _date) view returns(uint[] _amounts, address[] _players){
    return (gameRecords[_date].winnerAmounts, gameRecords[_date].winnerAddresses);
  }

  function getNumEntries(uint _date) view returns(uint _num){
    return gameRecords[_date].numPlayers;
  }

  function getPoolValue(uint _date) view returns(uint amount){
    return gameRecords[_date].pool;
  }

  function getBalance() view returns(uint _amount) {
    return address(this).balance;
  }

  function getTeamCost(uint _index) constant returns(uint cost){
    return allTeamsCosts[_index];
  }

  function getAllTeamCosts() view returns(uint[] costs){
    return allTeamsCosts;
  }

  function getPastGameResults(uint _gameIndex) view returns(address[] topPlayers,
                                                            uint[] topPlayersScores,
                                                            uint[] winnings){
    return (allTimeGames[_gameIndex].topPlayersAddresses,
            allTimeGames[_gameIndex].topPlayersScores,
            allTimeGames[_gameIndex].winnerAmounts
    );
  }

  function getPastGamesLength() view returns(uint _length){
    return allTimeGames.length;
  }

  function getEntry(uint _date, uint _index) view returns(
    address playerAddress,
    uint[] teamsSelected,
    uint entryIndex
  ){
    return (gameRecords[_date].entries[_index].player,
            gameRecords[_date].entries[_index].teamsSelected,
            gameRecords[_date].entries[_index].entryIndex);
  }

}