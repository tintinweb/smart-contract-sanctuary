// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';

contract LosMuertosClub is ERC721Enumerable, Ownable {
    string baseTokenURI;
    uint256 public price = 0.02 ether;
    bool public salePaused = true;
    uint256 public reserved = 26; // Team gets 4 LMC (minted in constructor), 26 are used for giveaways and other competitions
    uint256 public constant MAX_LMCS = 10000;
    string public LMC_PROVENANCE;

    address a1 = 0xFCDE8D498c3C722db4f7aaf554050dDF1B79FaA4;
    address a2 = 0x5c716bEDAe1CE71794F39a2055cbaE235723524F;
    address a3 = 0xe013DF7bED2c8D4E1642e8CD71CBe4FB25856336;
    address a4 = 0xb18ec35495748904279dcCE0c4EDDB49bf4Ef270;

    // constructor is executed when the contract is deployed. Sets name and symbol and mints the first 4 LMCs for team
    constructor(string memory baseURI) ERC721("Los Muertos Club", "LMC") {
        setBaseURI(baseURI);

        // the team gets the first 4 token
        _safeMint( a1, 0);
        _safeMint( a2, 1);
        _safeMint( a3, 2);
        _safeMint( a4, 3);
    }


    // fetch the api endpoint
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }


    // set the api endpoint, useful if the endpoint needs to be changed to a different location
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }


    // let the owner of the contract change the price of the LMC token, set amount in WEI!!!!
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }


    // withdraw the funds of the contract to the owner of the smart contract
    function withdrawAll() public payable onlyOwner {
        //require(payable(msg.sender).send(address(this).balance));
        uint256 _each = address(this).balance / 4;
        require(payable(a1).send(_each));
        require(payable(a2).send(_each));
        require(payable(a3).send(_each));
        require(payable(a4).send(_each));
    }


    // pause or start the sale
    function pause(bool val) public onlyOwner {
        salePaused = val;
    }


    // view the tokens of the holder, if the owner does not hold any tokens, return an empty array
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIDs = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++) {
            tokenIDs[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIDs;
    }


    // mint los muertos, max. 20
    function mintLMC(uint256 amountOfTokens) public payable {
        require(!salePaused,                                        "Sale paused");
        require(amountOfTokens > 0 && amountOfTokens < 21,          "Minimum mint is 1 and max are 20 LMCs at a time");
        require(msg.value == price * amountOfTokens,                "Ether sent is not correct");

        uint256 supply = totalSupply();
        require((supply + amountOfTokens) <= MAX_LMCS - reserved,   "Purchase would exceed max supply of LMCs");

        for (uint256 i; i < amountOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }


    // set the provenance hash
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        LMC_PROVENANCE = provenanceHash;
    }


    // reserve LMCs for giveaways
    function reserveLMC(address to, uint256 amount) public onlyOwner {
        require(amount > 0 && amount <= reserved,                   "Requested LMC amount exceeds reserve");
        uint256 supply = totalSupply();

        for (uint256 i; i < amount; i++) {
            _safeMint(to, supply + i);
        }
        reserved -= amount;
    }
}