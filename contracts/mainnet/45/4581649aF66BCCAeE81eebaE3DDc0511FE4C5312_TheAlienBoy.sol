//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./EnumerableMap.sol";
import "./ERC721Enumerable.sol";
import "./ERC1155.sol";
		                                                                          
//                        ,(((((((((((((((((((((((((,                          
//                    #####((((((((((((((((((((((((((((((.                     
//                ,#######((((((((((((((((((((((((((((((((((/                  
//             .##########(((((((((((((((((((((((((((((((((((((                
//          ..#########(##((((((((((((((///***,,,,,....,,,##%%(%#%             
//       ....############(((##%(*,,.....,,,/(////#/#(#,*,*%#(/*/*(%            
//      ....###########(/%(,,,(/#/##%%*&#**,/,(((#&/%(&#%##((%(*///#           
//    .....#######(/*,(**#(*##&#&@%%%&/%*/*%(*%,(,,./(/.#*#,%#(%%.,##          
//  &%.....###&%%#**(*/*(((,/%*/%((&%&(#((((((((((((((((((((((((((((,          
//   #(##,,#(**(&*#/%%#%((((((((((((((((((((((((((((((((((((((((((((/          
//  ..##/###&##########(((((((((((((((((((((((((((((((((((((((((((((/          
// /(/,,/&,#############((((((((((((((((((((((((((((((((((((((((((((*          
//  ....,,,###@&&&&@&@@@&&&%%#&@@@@@@@@@@@@@@@@@%(((((((((#&@@@@@@@&           
//  ....,,,##@###########(#&@@@@@@@(&@@@@@@@&%##(#@@@@@&(((((@@&%#(@&&         
//  .....,,,#############(#(((((%@((@@@@@@@@&%##%&%@@&@(((%@@@@&%//,&          
//  .....,,,,################((((@((#@@@@@@@&%#%&&@&(#@(#@@@@@@(// &,          
//   .....,,,,#################((#@(((#@@@@&%##%&@@(((#@@@@@@(((/  @           
//    .....,,,,,###################@(((((##%%#((@%((((((@((((((  @&            
//      ....,,,,,,##################%@@@&&&@@@&(((((((((((#&&&&%               
//       .......,,,,,####################################/                     
//          ......,,,,,,,,%%##########%%%%%%%%%%%%%%/.                         
//            .........,,,,,,,%@@@@@@@@@@*///*@@@@,                            
//                 .........,@@@@*@@@@@#@#([email protected]&&/@(                            
//                    [email protected]@@@@@@@@@@@@@&&&%&%&@&@@                           
//                    [email protected]@@@@@@@@@@@@@@@@@&&@@@@@@@                          
//                   [email protected]&@&&@&@@@&&@&&&&&&@@&/@@@@@@                         
//                  ....&&&&&&&&&@@@&&&#&&&&&&&%&&&&@@@                        
//                 ....&&&&&%&&&&@&&%%&%%%%%&&%&&&&&@@&&                       
//                ....%%%%%%%%&&&&&&%%%%%%%%%%&%%&&&&@&&*      
//
//
//  F#ck you nerd. You found me!
//  Join #IFoundTheAlienBoyContract at https://discord.gg/4TCeBSDbSh


contract TheAlienBoy is ERC721Enumerable, Ownable  {

    using SafeMath for uint256;

    // Token detail
    struct AlienDetail {
        uint256 first_encounter;
    }

    // Events
    event TokenMinted(uint256 tokenId, address owner, uint256 first_encounter);

    // Token Detail
    mapping( uint256 => AlienDetail) private _alienDetails;

    // Provenance number
    string public PROVENANCE = "";

    // Starting index
    uint256 public STARTING_INDEX;

    // Max amount of token to purchase per account each time
    uint public MAX_PURCHASE = 50;

    // Maximum amount of tokens to supply.
    uint256 public MAX_TOKENS = 10000;

    // Current price.
    uint256 public CURRENT_PRICE = 80000000000000000;

    // Define if sale is active
    bool public saleIsActive = true;

    // Base URI
    string private baseURI;

    /**
     * Contract constructor
     */
    constructor(string memory name, string memory symbol, string memory baseURIp, uint256 startingIndex) ERC721(name, symbol) {
        setBaseURI(baseURIp);
        STARTING_INDEX = startingIndex;
    }

    /**
     * Withdraw
     */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Reserve tokens
     */
    function reserveTokens() public onlyOwner {
        uint i;
        uint tokenId;
        uint256 first_encounter = block.timestamp;

        for (i = 1; i <= 50; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _alienDetails[tokenId] = AlienDetail(first_encounter);
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }

    /**
     * Mint a specific token. 
     */
    function mintTokenId(uint tokenId) public onlyOwner {
        require(!_exists(tokenId), "Token was minted");
        uint256 first_encounter = block.timestamp;
        
        _safeMint(msg.sender, tokenId);
        _alienDetails[tokenId] = AlienDetail(first_encounter);
        emit TokenMinted(tokenId, msg.sender, first_encounter);
    }

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }

    /*     
    * Set max tokens
    */
    function setMaxTokens(uint256 maxTokens) public onlyOwner {
        MAX_TOKENS = maxTokens;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    /**
    * Mint Alien
    */
    function mintAlien(uint numberOfTokens) public payable {
        require(saleIsActive, "Mint is not available right now");
        require(numberOfTokens <= MAX_PURCHASE, "Can only mint 50 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Aliens");
        require(CURRENT_PRICE.mul(numberOfTokens) <= msg.value, "Value sent is not correct");
        uint256 first_encounter = block.timestamp;
        uint tokenId;
        
        for(uint i = 1; i <= numberOfTokens; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _alienDetails[tokenId] = AlienDetail(first_encounter);
                
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex(uint256 startingIndex) public onlyOwner {
        STARTING_INDEX = startingIndex;
    }

    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function setBaseURI(string memory BaseURI) public onlyOwner {
       baseURI = BaseURI;
    }

     /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

   /**
     * Set the current token price
     */
    function setCurrentPrice(uint256 currentPrice) public onlyOwner {
        CURRENT_PRICE = currentPrice;
    }

    /**
     * Get the token detail
     */
    function getAlienDetail(uint256 tokenId) public view returns(AlienDetail memory detail) {
        require(_exists(tokenId), "Token was not minted");

        return _alienDetails[tokenId];
    }
}