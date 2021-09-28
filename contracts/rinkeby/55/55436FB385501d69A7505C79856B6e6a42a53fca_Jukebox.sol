/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

pragma solidity ^0.8.0;
contract Jukebox {
  uint64 qLength;

  struct Song {
    uint256 start;
    uint256 end;
    string url;
    string coverUrl;
    string title;
    string artist;
    address publisher;
  }

  event SongAdded(address indexed, uint256);

  mapping(uint=>Song) public queue;

  constructor() public {
    qLength = 0;
  }

  function addSong(string memory url, string memory coverUrl, string memory title, string memory artist, uint8 duration) external payable {
    require(msg.value == calculateFee(duration), "Fee provided must equal fee calculation.");
    uint256 startPosition;
    if (getQueueDepth() != 0) {
        startPosition = queue[qLength - 1].end;
    } else {
        startPosition = block.number;
    }

    queue[qLength] = Song(startPosition, startPosition + duration, url, coverUrl, title, artist, msg.sender);

    qLength++;

    emit SongAdded(msg.sender, startPosition);
  }

  function getCurrentSong() public view returns (string memory, string memory, string memory, string memory, address, uint256, uint256) {
    uint256 depth = getQueueDepth();
    if (depth == 0) {
        return ("", "", "", "", 0x0000000000000000000000000000000000000000, 0, 0);
    }
    Song memory song = queue[qLength - depth];
    return (song.url, song.coverUrl, song.title, song.artist, song.publisher, song.start, song.end);
  } 

  function getNextStartTime() public view returns (uint256) {
    if (getQueueDepth() == 0) {
        return block.number;
    }
    
    return (queue[qLength - 1].start);
  }

  function getQueueDepth() public view returns (uint256) {
      uint qDepth = 0;
      for (uint256 i = qLength; i > 0; i--) {
          if (queue[i - 1].start <= block.number && queue[i - 1].end > block.number) {
              qDepth = qLength - i + 1;
              break;
          }
      }
      return qDepth;
  }

  function getSongAtIndex(uint index) public view returns (string memory, string memory, string memory, string memory, address, uint256, uint256) {
    Song memory song = queue[index];
    return (song.url, song.coverUrl, song.title, song.artist, song.publisher, song.start, song.end);
  }

  function getQueueLength() public view returns (uint256) {
      return qLength;
  }
  
  function calculateFee(uint8 duration) private view returns (uint256) {
      return (uint256(duration) * uint256(duration) * 20000000000000 + (getQueueDepth() * 200000000000000));
  }

}