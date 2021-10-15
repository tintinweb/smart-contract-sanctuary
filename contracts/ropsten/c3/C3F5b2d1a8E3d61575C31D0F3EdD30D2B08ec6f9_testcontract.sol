/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract testcontract{
    // using Counters for Counters.Counter;
    // Counters.Counter private _tokenIds;
    // uint256 minting_code
    address public admin;
    string public baseURI;
    constructor(){
        admin = msg.sender;
    }

    event minted(
        address indexed caller,
        uint256 tokenID
    );

    function updateBaseURI(string memory newBaseURI) public onlyOwner{
        baseURI = newBaseURI;
    }

    function publicfunc() public pure returns(string memory){
        return("hello im a public func");
    }
    function ownablefunc() public onlyOwner{
        emit minted(msg.sender, 55);
    }

    modifier onlyOwner{
        require(msg.sender == admin);
        _;
    }

}