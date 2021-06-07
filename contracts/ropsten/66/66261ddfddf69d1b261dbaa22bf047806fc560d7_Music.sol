/**
 *Submitted for verification at Etherscan.io on 2021-06-07
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

    event AlbumMinted(string title, string artist, string uri, uint price);

    constructor() {}

    function mint(
        string memory _title,
        string memory _artist,
        string memory _uri,
        uint _price
    ) public {
        albums[_id] = Album(_title, _artist, _uri, _price);
        _id++;

        emit AlbumMinted(_title, _artist, _uri, _price);
    }

}