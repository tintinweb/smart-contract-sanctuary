/**
 *Submitted for verification at polygonscan.com on 2021-09-14
*/

pragma solidity ^0.8.4;

// This contract is based in the story of Jorge Luis Borges: "The Library of Babel"
// Author: Fernando Molina
// Twitter: @fergmolina
// Github: https://github.com/fergmolina/library-of-ethbel

contract Babel {
    
    uint lengthOfTitle = 25;
    uint lengthOfPage = (80*40)-lengthOfTitle;
    
    //29 output letters: alphabet plus comma, space, and period
    //in wall: 4
    //in shelf: 5
    //in volumes: 32
    //pages: 410
    //letters per page: 80*40
    //titles have 25 char

    struct Result {
        uint wall;
        uint shelf;
        uint volumes;
        uint pages;
        string title;
        string text;
        bytes textSeed;
    }


    function search(string memory _str) external view returns (Result memory){

        uint wall = rand(4,block.difficulty+1);
        uint shelf = rand(5,block.difficulty+2);
        uint volume = rand(32,block.difficulty+3);
        uint page = rand(410,block.difficulty+4);
        
        uint depth = rand(lengthOfPage-(bytes(_str).length), uint256(keccak256(abi.encodePacked(wall,shelf,volume,page))));

        string[29] memory digs= ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',',','.',' '];
        uint randPadding;
        string memory frontPadding;
        string memory backPadding;
        string memory title;
        uint random = uint256(keccak256(abi.encodePacked(_str)));
        
        for (uint x = 0; x<depth; x++) {
            randPadding=rand(digs.length, random);
            random += 1;
            frontPadding = string(abi.encodePacked(frontPadding, digs[randPadding]));
        }

        for (uint x = 0; x<(lengthOfPage-(depth+bytes(_str).length)); x++) {
            randPadding=rand(digs.length, random);
            random += 1;
            backPadding = string(abi.encodePacked(backPadding, digs[randPadding]));
        }

        for (uint x = 0; x<lengthOfTitle; x++) {
            randPadding=rand(digs.length, random);
            random += 1;
            title = string(abi.encodePacked(title, digs[randPadding]));
        }

        string memory text = string(abi.encodePacked(frontPadding, _str, backPadding));
        bytes memory textSeed = abi.encodePacked(_str);
        Result memory result = Result(wall, shelf, volume, page, title, text, textSeed);

        return (result);
        
    }

    function getRandomPage() external view returns (Result memory){

        uint wall = rand(4,block.difficulty+1);
        uint shelf = rand(5,block.difficulty+2);
        uint volume = rand(32,block.difficulty+3);
        uint page = rand(410,block.difficulty+4);
        

        string[29] memory digs= ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',',','.',' '];

        uint randomSeed = uint256(keccak256(abi.encodePacked(
                        block.timestamp + block.difficulty +
                        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                        block.gaslimit + 
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                        block.number 
                    ))) % digs.length;

        string memory str = digs[randomSeed];
        uint depth = rand(lengthOfPage-(bytes(str).length), uint256(keccak256(abi.encodePacked(wall,shelf,volume,page))));

        uint randPadding;
        string memory frontPadding;
        string memory backPadding;
        string memory title;



        uint random = uint256(keccak256(abi.encodePacked(str)));
        
        for (uint x = 0; x<depth; x++) {
            randPadding=rand(digs.length, random);
            random += 1;
            frontPadding = string(abi.encodePacked(frontPadding, digs[randPadding]));
        }

        for (uint x = 0; x<(lengthOfPage-(depth+bytes(str).length)); x++) {
            randPadding=rand(digs.length, random);
            random += 1;
            backPadding = string(abi.encodePacked(backPadding, digs[randPadding]));
        }

        for (uint x = 0; x<lengthOfTitle; x++) {
            randPadding=rand(digs.length, random);
            random += 1;
            title = string(abi.encodePacked(title, digs[randPadding]));
        }

        Result memory result = Result(wall, shelf, volume, page, title, string(abi.encodePacked(frontPadding, str, backPadding)), abi.encodePacked(str));

        return (result);
        
    }

    function getPage(uint _wall, uint _shelf, uint _volume, uint _page, bytes memory _randomSeed) external view returns (Result memory){
        
        uint depth = rand(lengthOfPage-(_randomSeed.length), uint256(keccak256(abi.encodePacked(_wall,_shelf,_volume,_page))));

        string[29] memory digs= ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',',','.',' '];
        uint randPadding;
        string memory frontPadding;
        string memory backPadding;
        string memory title;
        uint random = uint256(keccak256(_randomSeed));
        
        for (uint x = 0; x<depth; x++) {
            randPadding=rand(digs.length, random);
            random += 1;
            frontPadding = string(abi.encodePacked(frontPadding, digs[randPadding]));
        }

        for (uint x = 0; x<(lengthOfPage-(depth+_randomSeed.length)); x++) {
            randPadding=rand(digs.length, random);
            random += 1;
            backPadding = string(abi.encodePacked(backPadding, digs[randPadding]));
        }

        for (uint x = 0; x<lengthOfTitle; x++) {
            randPadding=rand(digs.length, random);
            random += 1;
            title = string(abi.encodePacked(title, digs[randPadding]));
        }

        Result memory result = Result(_wall, _shelf, _volume, _page, title, string(abi.encodePacked(frontPadding, string(_randomSeed), backPadding)), _randomSeed);

        return (result);
        
    }

    function rand(uint _number, uint _nonce) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_number, _nonce))) % _number;
    }

    function donate() payable public {
        require(msg.value>0,"You didn't send any donation");
        address payable borges = payable(0x923F3E494B10DfBAbEA846aB6346A68a10CDe95E);
        borges.transfer(msg.value);
    }

}