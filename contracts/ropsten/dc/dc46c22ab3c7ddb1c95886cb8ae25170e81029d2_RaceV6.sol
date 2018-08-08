pragma solidity ^0.4.0;

contract RaceV6 {
    
    struct Player {
        uint id;
        uint portfolioElements;
        address addr;
        bytes32[] portfolioIndex;
        
        mapping(bytes32 => uint) portfolio;
    }
    
    struct Track {
        uint id;
        uint readyCount;
        uint duration;
        uint numPlayers;
        address[] playerAddresses;
        bool[] readyPlayers;
        
        mapping(address => Player) players;
    }
    
    struct RunningTrack {
        uint startTime;
    }
    
    mapping(uint => Track) public tracks;
    uint trackElements;
    
    mapping(uint => RunningTrack) public runningTracks;
    
    event DebugUint(uint v);
    event DebugArray(bool[] a);
    
    modifier onlyFreeTrack(uint _trackId) {
        require(tracks[_trackId].playerAddresses.length < 2, "onlyFreeTrack");
        _;
    }
    
    constructor() public {
        trackElements = 0;
    }
    
    function newTrack() public returns(uint) {
        tracks[trackElements] = createEmptyTrack();
        Track storage t = tracks[trackElements];
        addPlayer(t, createPlayer(msg.sender, t.playerAddresses.length));
        trackElements++;
    }
    
    function getCountPlayerByTrackId(uint _id) public view returns(uint) {
        return tracks[_id].playerAddresses.length;
    }
    
    function getCountReadyPlayerByTrackId(uint _id) public view returns(uint) {
        return tracks[_id].readyCount;
    }
    
    function getCreatorByTrackId(uint _id) public view returns(address) {
        return tracks[_id].players[ tracks[_id].playerAddresses[0] ].addr;
    }
    
    function getPlayersByTrackId(uint _id) public view returns(address[]) {
        address[] memory a = new address[](tracks[_id].playerAddresses.length);
        
        for (uint i = 0; i < tracks[_id].playerAddresses.length; i++) {
            a[i] = (tracks[_id].playerAddresses[i]);
        }
        
        return a;
    }
    
    function getCountTrack() public view returns(uint) {
        return trackElements;
    }
    
    
    function joinToTrack(uint _id) public onlyFreeTrack(_id) {
        Track storage t = tracks[_id];
        
        require(!(t.players[msg.sender].addr == msg.sender));
        require(!isReadyToStart(_id));
        
        addPlayer(t, createPlayer(msg.sender, t.playerAddresses.length));
    }
    
    function setPortfolio(uint _trackId, bytes32[] names, uint8[] values) public {
        require(names.length == values.length);
        require(!isReadyToStart(_trackId));
        
        Track storage t = tracks[_trackId];
        Player storage p = t.players[msg.sender];
        p.portfolioElements = 0;
        
        
        uint8 totalPercent = 0;
        for (uint i = 0; i < names.length; i++) {
            require(values[i] > 0 && values[i] <= 100);
            require(!isNameExists(p.portfolioIndex, names[i], p.portfolioElements));
            
            p.portfolioIndex.push(names[i]);
            p.portfolio[names[i]] = values[i];
            p.portfolioElements++;
            totalPercent += values[i];
            require(totalPercent <= 100);
        }
        
        emit DebugUint(p.id);
        emit DebugArray(t.readyPlayers);
        
        if (!t.readyPlayers[p.id]) {
            t.readyCount++;
            t.readyPlayers[p.id] = true;
        }
        
        if (tracks[_trackId].readyCount == tracks[_trackId].numPlayers) {
            runningTracks[_trackId] = RunningTrack({startTime: now + (5 - (now % 5))});
        }
    }
    
    function getPortfolio(uint _trackId, address _addr) public view returns(bytes32[], uint[]) {
        bytes32[] memory n = new bytes32[](tracks[_trackId].players[_addr].portfolioElements);
        uint[] memory v = new uint[](tracks[_trackId].players[_addr].portfolioElements);
        
        for (uint i = 0; i < tracks[_trackId].players[_addr].portfolioElements; i++) {
            n[i] = tracks[_trackId].players[_addr].portfolioIndex[i];
            v[i] = tracks[_trackId].players[_addr].portfolio[n[i]];
        }
        
        return(n, v);
    }
    
    function isReadyToStart(uint _trackId) public view returns(bool) {
        Track storage t = tracks[_trackId];
        
        return t.readyCount == t.numPlayers;
    }
    
    function isEndedTrack(uint _trackId) public view returns(bool) {
        Track storage t = tracks[_trackId];
        return now < runningTracks[_trackId].startTime + t.duration;
    }
    
    
    // === internal functions ===
    function isNameExists(bytes32[] storage names, bytes32 name, uint numNames) internal view returns(bool) {
        for (uint i = 0; i < numNames; i++) {
            if (names[i] == name) {
                return true;
            }
        }
        
        return false;
    }
    
    function createEmptyTrack() internal view returns(Track) {
        return Track({
            id: trackElements,
            playerAddresses: new address[](0),
            readyCount: 0,
            readyPlayers: new bool[](0),
            duration: 5 minutes,
            numPlayers: 2
        });
    }
    
    function createPlayer(address _addr, uint _id) internal pure returns(Player) {
        return Player({addr: _addr, portfolioIndex: new bytes32[](0), portfolioElements: 0, id: _id});
    }
    
    function addPlayer(Track storage t, Player p) internal {
        t.players[p.addr] = p;
        t.playerAddresses.push(p.addr);
        t.readyPlayers.push(false);
    }
}