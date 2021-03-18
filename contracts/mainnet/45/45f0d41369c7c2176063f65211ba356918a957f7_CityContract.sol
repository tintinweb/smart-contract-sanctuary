/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity ^0.6.1;

contract CityContract {
    struct Tile { uint locator; uint currentPrice; address payable owner; }
    address payable gameMaster;
    Tile[70] public tiles;

    constructor() public payable {
        gameMaster = msg.sender;
    }

    function buyTile(uint tileLocator) public payable {
        Tile memory tile = tiles[tileLocator];
        uint minimalPrice = 17e16;

        // send money to gameMaster if nobody bought it yet
        if (tile.currentPrice < minimalPrice) {
            tile.owner = gameMaster;
            tile.currentPrice = minimalPrice;
        }

        //  Upgrade tile locator on the fily
        if (tile.locator < 1 && tileLocator > 0) {
            tiles[tileLocator].locator = tileLocator;
        }

        uint price = tile.currentPrice * 2;
        require(msg.sender != tile.owner, "you cannot buy your own tile");
        require(msg.value > price - 1, "you must pay at least double the price to get the tile");
        tile.owner.transfer(msg.value);
        tiles[tileLocator].owner = msg.sender;
        tiles[tileLocator].currentPrice = price;
    }
}