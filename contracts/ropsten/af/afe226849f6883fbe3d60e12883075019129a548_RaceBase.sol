pragma solidity 0.4.24;

contract Rate {
  mapping(uint => mapping(bytes32 => uint)) public rates;

  function setRates(uint time, bytes32[] names, uint[] amounts) external {
    require(time % 5 == 0);
    require(names.length == amounts.length);
    for (uint i = 0; i < names.length; i++) {
      rates[time][names[i]] = amounts[i];
    }
  }

  function getRate(uint time, bytes32 name) public view returns (uint) {
    return rates[time][name];
  }

  function getRates(uint time, bytes32[] memory names) public view returns (uint[]) {
    uint[] memory amounts = new uint[](names.length);

    for (uint i = 0; i < names.length; i++) {
      amounts[i] = rates[time][names[i]];
    }

    return amounts;
  }
}

contract RaceCore {
    
  struct Player {
    uint id;
    uint portfolioElements;
    address addr;
    bytes32[] portfolioIndex;
        
    mapping(bytes32 => uint) portfolio;
  }
    
  struct Track {
    uint readyCount;
    uint duration;
    uint numPlayers;
    uint betAmount;
    address[] playerAddresses;
    bool[] readyPlayers;
    
    mapping(address => Player) players;
  }
    
  struct RunningTrack {
    uint startTime;
  }
  
  mapping(bytes32 => Track) public tracks;
  mapping(bytes32 => mapping(address => uint)) public deposites;
  mapping(bytes32 => RunningTrack) public runningTracks;
}

contract RaceBase is RaceCore {

  Rate public rate;
  
  modifier onlyFreeTrack(bytes32 _trackId) {
    require(tracks[_trackId].playerAddresses.length < 2);
    _;
  }

  event DebugUint(uint i);
  event DebugBytes(bytes32 b);
  event DebugArray(uint[] a);

  constructor (address _rateAddress) public {
    rate = Rate(_rateAddress);
  }

  // External functions
  function createTrack(bytes32 _trackId) external payable {
    require(tracks[_trackId].numPlayers == 0);

    tracks[_trackId] = createEmptyTrack(msg.value);
    Track storage t = tracks[_trackId];

    addPlayer(t, createPlayer(msg.sender, t.playerAddresses.length));

    deposites[_trackId][msg.sender] = msg.value;
  }

  function createTrackFromBack(bytes32 _trackId, uint bet) external {
    require(tracks[_trackId].numPlayers == 0);

    tracks[_trackId] = createEmptyTrack(bet);
  }

  function joinToTrack(bytes32 _id) external payable onlyFreeTrack(_id) {
    require(msg.value == deposites[_id][getTrackOwner(_id)]);
    Track storage t = tracks[_id];
      
    require(!(t.players[msg.sender].addr == msg.sender));
    require(!isReadyToStart(_id));
      
    addPlayer(t, createPlayer(msg.sender, t.playerAddresses.length));
  }

  function withdrawRewards(bytes32 _trackId) external {
    Track storage t = tracks[_trackId];
    
    address[] memory winners = getWinners(_trackId);
    uint amount = (getBetAmount(_trackId) * t.numPlayers) / winners.length;
    uint i = 0;
    for(i = 0; i < t.playerAddresses.length; i++) {
      deposites[_trackId][t.playerAddresses[i]] = 0;
    }
    
    DebugUint(amount);
    for (i = 0; i < winners.length; i++) {
      winners[i].transfer(amount);
    }
  }

  function setPortfolio(bytes32 _trackId, bytes32[] names, uint[] values) external {
    require(names.length == values.length);
    require(!isReadyToStart(_trackId));
      
    Track storage t = tracks[_trackId];
    Player storage p = t.players[msg.sender];
    p.portfolioElements = 0; 
      
    uint totalPercent = 0;
    for (uint i = 0; i < names.length; i++) {
      require(values[i] > 0 && values[i] <= 100);
      require(!isNameExists(p.portfolioIndex, names[i], p.portfolioElements));
          
      p.portfolioIndex.push(names[i]);
      p.portfolio[names[i]] = values[i];
      p.portfolioElements++;
      totalPercent += values[i];
      require(totalPercent <= 100);
    }
      
    if (!t.readyPlayers[p.id]) {
      t.readyCount++;
      t.readyPlayers[p.id] = true;
    }
  }

  function startTrack(bytes32 _trackId, uint _start) external {
    if (tracks[_trackId].readyCount == tracks[_trackId].numPlayers) {
      runningTracks[_trackId] = RunningTrack({startTime: _start + (5 - (_start % 5))});
    }
  }
  
  // External functions that are view
  // ...
  
  // External functions that are pure
  // ...
  
  // Public functions
  function getCountPlayerByTrackId(bytes32 _id) public view returns (uint) {
    return tracks[_id].playerAddresses.length;
  }
  
  function getCountReadyPlayerByTrackId(bytes32 _id) public view returns (uint) {
    return tracks[_id].readyCount;
  }
  
  function getTrackOwner(bytes32 _id) public view returns (address) {
    return tracks[_id].players[tracks[_id].playerAddresses[0]].addr;
  }
  
  function getPlayersByTrackId(bytes32 _id) public view returns (address[]) {
    address[] memory a = new address[](tracks[_id].playerAddresses.length);
      
    for (uint i = 0; i < tracks[_id].playerAddresses.length; i++) {
      a[i] = (tracks[_id].playerAddresses[i]);
    }
      
    return a;
  }

  function getPortfolio(bytes32 _trackId, address _addr) public view returns (bytes32[], uint[]) {
    bytes32[] memory n = new bytes32[](tracks[_trackId].players[_addr].portfolioElements);
    uint[] memory v = new uint[](tracks[_trackId].players[_addr].portfolioElements);
      
    for (uint i = 0; i < tracks[_trackId].players[_addr].portfolioElements; i++) {
      n[i] = tracks[_trackId].players[_addr].portfolioIndex[i];
      v[i] = tracks[_trackId].players[_addr].portfolio[n[i]];
    }
      
    return(n, v);
  }
  
  function isReadyToStart(bytes32 _trackId) public view returns (bool) {
    Track storage t = tracks[_trackId];
    
    return t.readyCount == t.numPlayers;
  }

  function getBetAmount(bytes32 _trackId) public view returns (uint) {
    return tracks[_trackId].betAmount;
  }
  
  function isEndedTrack(bytes32 _trackId) public view returns (bool) {
    Track storage t = tracks[_trackId];
    return now > runningTracks[_trackId].startTime + t.duration;
  }

  function endTime(bytes32 _trackId) public view returns (uint) {
    Track storage t = tracks[_trackId];
    return runningTracks[_trackId].startTime + t.duration;
  }

  function getPlayers(bytes32 _trackId) public view returns(address[]) {
    return tracks[_trackId].playerAddresses;
  }

  function getWinners(bytes32 _trackId) public view returns (address[]) {
    (address[] memory players, int[] memory points) = getStats(_trackId);

    uint i = 0;
    uint w_min = 0;
    int tmpI;
    address tmpA;

    for(uint pos = 0; pos < points.length - 1; pos++) {
      w_min = pos;
      for(i = pos; i < points.length; i++) {
        if(points[i] < points[w_min]) {
          w_min = i;
        }
      }
      if(w_min == pos) continue;
      tmpI = points[pos];
      points[pos] = points[w_min];
      points[w_min] = tmpI;

      tmpA = players[pos];
      players[pos] = players[w_min];
      players[w_min] = tmpA;
    }

    i = 0;
    uint count = countWinners(points);
    address[] memory winners = new address[](count);

    for (pos = players.length - 1; pos >= players.length - count; pos--) {
      winners[i++] = players[pos];
    }

    return winners;
  }

  function getStat(bytes32 _trackId, address _player) public view returns (int) {
    Track memory t = tracks[_trackId];
    int points = 0;
    (bytes32[] memory names, uint[] memory amounts) = getPortfolio(_trackId, _player);
    uint[] memory ratesAtStart = rate.getRates(runningTracks[_trackId].startTime, names);
    uint[] memory ratesAtEnd = rate.getRates(runningTracks[_trackId].startTime + 300 seconds, names);

    for (uint i = 0; i < names.length; i++) {
      points += int(((ratesAtEnd[i] - ratesAtStart[i])* 1 ether * amounts[i])/ratesAtStart[i]);
    }

    return points;
  }

  function getStats(bytes32 _trackId) public view returns (address[], int[]) {
    Track memory t = tracks[_trackId];
    address[] memory players = new address[](t.playerAddresses.length);
    int[] memory points = new int[](t.playerAddresses.length);

    for (uint i = 0; i < t.playerAddresses.length; i++) {
      players[i] = t.playerAddresses[i];
      points[i] = getStat(_trackId, players[i]);
    }

    return (players, points);
  }
  
  // Internal functions
  function createPlayer(address _addr, uint _id) internal pure returns (Player) {
    return Player({addr: _addr, portfolioIndex: new bytes32[](0), portfolioElements: 0, id: _id});
  }

  function createEmptyTrack(uint betAmount) internal view returns (Track) {
    return Track({
      playerAddresses: new address[](0),
      readyCount: 0,
      readyPlayers: new bool[](0),
      duration: 5 minutes,
      numPlayers: 2,
      betAmount: betAmount
    });
  }

  function countWinners(int[] memory _points) internal pure returns (uint) {
    uint count = 1;
    for (uint i = _points.length - 2; i >= 0; i--) {
      if (_points[i] == _points[_points.length - 1]) {
        count++;
      } else {
        return count;
      }
    }

    return count;
  }
  
  function addPlayer(Track storage t, Player p) internal {
    t.players[p.addr] = p;
    t.playerAddresses.push(p.addr);
    t.readyPlayers.push(false);
  }

  function isNameExists(bytes32[] storage names, bytes32 name, uint numNames) internal view returns (bool) {
    for (uint i = 0; i < numNames; i++) {
      if (names[i] == name) {
        return true;
      }
    }
      
    return false;
  }

  
  
  // Private functions
  // ...
}