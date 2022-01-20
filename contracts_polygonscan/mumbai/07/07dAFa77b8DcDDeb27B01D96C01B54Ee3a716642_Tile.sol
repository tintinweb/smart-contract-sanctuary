/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

pragma solidity ^0.5.2;

contract Tile {

    mapping (uint => Tiles) public id;
    uint256 public count = 0;

    struct Tiles {
        uint _id;
        string _tileName;
    }

    function addTile(string memory _tileName) public {
        count += 1;
        id[count] = Tiles(count, _tileName);
    }
    
}