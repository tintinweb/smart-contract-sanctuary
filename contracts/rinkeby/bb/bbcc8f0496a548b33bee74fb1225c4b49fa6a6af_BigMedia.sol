/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BigMedia {
    
    struct Article {
        string title;
        string post;
        uint256 timestamp;
    }
    
    struct Agency {
        string name;
        bool exist;
        uint256 lat;
        uint256 long;
        mapping (bytes32 => Article) articles;
    }
    
    address owner;
    
    mapping(string => Agency) public agencies;
    
    event agencyAdded(string name, uint256 lat, uint256 long);
    event articleAdded(string agencyName, bytes32 ref, string title, string post);
    
    constructor() {
        owner = msg.sender;
    }
    
    function addAgency(uint256 lat, uint256 long, string memory name) public {
        require(msg.sender == owner, "not owner");
        Agency storage agency = agencies[name];
        agency.exist = true;
        agency.name = name;
        agency.lat = lat;
        agency.long = long;
        emit agencyAdded(name, lat, long);
    }
    
    function addArticle(string memory title, string memory post, string memory agencyName) public {
        Agency storage agency = agencies[agencyName];
        require(agency.exist == true, "does not exist");
        bytes32 ref = bytes32(abi.encode(title, post));
        Article storage article = agency.articles[ref];
        article.title = title;
        article.post = post;
        article.timestamp = block.timestamp;
        emit articleAdded(agencyName, ref, title, post);
    }
}