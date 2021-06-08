/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

contract Music {
    
    struct Album {
        string title;
        string artist;
        string uri;
        uint price;
    }
    
    uint private _id = 1;

    mapping(uint => Album) public albums;

    event AlbumMinted(uint albumId, string title, string artist, string uri, uint price);

    constructor() {}

    function mint(
        string memory _title,
        string memory _artist,
        string memory _uri,
        uint _price
    ) public {
        uint id = _id; _id++;
        albums[id] = Album(_title, _artist, _uri, _price);

        emit AlbumMinted(id, _title, _artist, _uri, _price);
    }

}