// SPDX-License-Identifier: Anonymice License, Version 1.0

/*
Copyright 2022 LBAC
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./ICheeth.sol";
import "./IAnonymice.sol";
import "./AnonymiceLibrary.sol";
import "./IAnonymiceBreedingDescriptor.sol";

contract Ah1 is ERC721Enumerable, Ownable {
    /*
  A1                                                                                                                                                                                                                         
*/

    using Counters for Counters.Counter;

    //addresses
    address CHEETH_ADDRESS;
    address ANONYMICE_ADDRESS;


    uint256 SEED_NONCE = 0;
    uint256 MAX_BABY_SUPPLY = 3550;

    uint256 BASE_CHEETH_COST = 30000000000000000;
    uint256 CHEETH_COST_PER_BLOCK = 30000000000000;

    uint256 BLOCKS_TILL_REVEAL = 50000;
    uint256 BLOCKS_TILL_RELEASE = 50000;

    uint mintIndex = totalSupply();

    bool public BREEDING_LIVE = false;

    Counters.Counter private _currentBreedingEventId;



        constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        
    }


    function burn() public {


        //Burn cheeth
        ICheeth(CHEETH_ADDRESS).burnFrom(msg.sender, BASE_CHEETH_COST);
    }

    function mint(uint256 numberOfTokens) public {
        // Exceptions that need to be handled + launch switch mechanic

        require(numberOfTokens > 0, "You cannot mint 0 items, please increase to more than 1");
       


            _safeMint(msg.sender, mintIndex);
        

    }


    function burnMint(uint256 numberOfTokens) public {
        // Exceptions that need to be handled + launch switch mechanic

        require(numberOfTokens > 0, "You cannot mint 0 items, please increase to more than 1");
       
        //Burn cheeth
        ICheeth(CHEETH_ADDRESS).burnFrom(msg.sender, BASE_CHEETH_COST);

            _safeMint(msg.sender, mintIndex);
        

    }


    function setAddresses(
        address _anonymiceAddress,
        address _cheethAddress
    ) public onlyOwner {
        CHEETH_ADDRESS = _cheethAddress;
        ANONYMICE_ADDRESS = _anonymiceAddress;
    }

}