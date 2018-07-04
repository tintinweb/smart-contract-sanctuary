pragma solidity ^0.4.24;

contract Race {
    uint countTrack;
    
    struct Player {
        address addr;
    }
    
    struct Track {
        uint id;
        mapping(uint => Player) players;
        uint playersSize;
    }
    
    Track[] tracks;
    
    function createTrack() external returns(uint id) {
        countTrack++;
        tracks.push(Track({id: countTrack, playersSize: 0}));
        Track storage t = tracks[countTrack];
        t.players[t.playersSize] = Player({addr: msg.sender});
        t.playersSize++;
        
        return countTrack;
    }
    
    function joinToTrack(uint id) external {
        Track storage t = tracks[id];
        t.players[t.playersSize] = Player({addr: msg.sender});
        t.playersSize++;
    }
}