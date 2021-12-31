// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Address.sol";

    /*
    @dev:   * Extends ERC721 Non-Fungible Token Standard basic implementation.
            * Additional Extensions includes: ERC721Enumerable, ERC721Metadata, Ownable, Content reference from openzapplin-contracts.
            * Ideal for part sale of the entire token supply.
            
            NOTE: this contract does not implement any token burnable functionality
    */

contract RanSomeWhere is ERC721, Ownable{
    
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    /*
    @dev Emitted when `updateNewCollection()` function is called
    */
    event NewCollection(uint indexed id, uint256 indexed facevalue);

    /*
    @dev Emitted when `flipSaleStatus()` function is called
    */
    event FlipSales(uint256 indexed id, bool status);

    /*
    @dev:   * provenance hash of the entire supply.
            * this is only valid after the entire supply has been minted.
    */
    string public rswProvenance = "";

    /*
    @dev:   * Maximum supply of the token
    */
    uint256 public maxRSW;

    /*
    @dev:   * Maximum collection of the project
    */
    uint256 public maxCollection;

    /*
    @dev:   * maxRSW / maxCollection, sets maximum number of token for each collection.
    */
    uint256 public maxTokenPerCollection;

    /*
    @dev:   * MAX_RSW_PURCHASE is the total number of token that can be minted in a single purchase.
    */
    uint public constant MAX_RSW_PURCHASE = 3;

    /*
    @dev:   * Returns the current status of the sale.
    */
    bool public isSaleActive = false;

    /*
    @dev:   * Recommended faceValue not be constant, 
            as multi year project might be affected by inflation.
    */
    uint public faceValue = 290000000000000000; // 0.29 ETH

    /*
    @dev:   * Map of collectio-id to collection-provenance-hash.
            * calling flipSaleStatus, adds new collection onto the map.
    */
    mapping (uint256 => string) public _allCollection;

    /*
    @dev:   * stores the collection-id of the last sales.
            * calling flipSaleStatus, increments by 1.
    */
    uint256 public lastCollectionId;

    /*
    @dev:   * stores the collection-provenance-hash of the last sales.
            * calling flipSaleStatus, sets lastCollection to upcomingCollection.
    */
    string public lastCollection = "";

    /*
    @dev:   * stores collection-provenance-hash of the upcomming sales.
            * set by the deployer/owner.
            * calling flipSaleStatus, sets empty value for upcommingCollection.
    */
    string public upcomingCollection = "";

    /*
    @dev:   * stores the end index of the current sale.
            * calling flipSaleStatus, add MaxTokenPerCollection to totalSupply()
    */
    uint256 public endIndex;



    constructor(string memory name, string memory symbol, uint256 maxNftSupply, uint256 maxNftCollection) ERC721(name, symbol){
        maxRSW = maxNftSupply;
        maxCollection = maxNftCollection;
        lastCollectionId = 0;
        maxTokenPerCollection = maxNftSupply.div(maxNftCollection);
    }

    /*
    @dev:   * withdrawls contract balance to the deployer/owner
            * restricted to owner only 
    */
    function withdrawl() public onlyOwner(){
        uint _balance  = address(this).balance;
        payable(msg.sender).transfer(_balance);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner{
        rswProvenance = provenanceHash;
    }

    /*
    @dev:   * updates upcoming event on the contract.
    */
    function updateNewCollection(uint256 newFaceValue, string memory newCollection) public onlyOwner{
        require(bytes(upcomingCollection).length == 0, "Upcoming Collection is set");
        require(lastCollectionId < maxCollection, "Maximum Collection has been reached");
        
        faceValue = newFaceValue;
        upcomingCollection = newCollection;

        emit NewCollection(lastCollectionId.add(1), newFaceValue);
    }

    /*
    @dev:   * returns the collection-name for the argued collection-id
    */
    function getCollectionById(uint256 id) public view returns(string memory){
        require(id <= lastCollectionId, "Collection Id out of bound");
        return _allCollection[id];
    }

    /*
    @dev:   * sets the sales live for the buyer.
            * restricted to owner only.
    */
    function flipSaleStatus() public onlyOwner{
        require(bytes(upcomingCollection).length > 0, "New Edition has Not been Updated");
        require(lastCollectionId < maxCollection, "Maximum Collection has been reached");

        endIndex = lastCollectionId.add(1);
        endIndex = endIndex.mul(maxTokenPerCollection);

        isSaleActive = true;
        lastCollection = upcomingCollection;
        upcomingCollection = "";
        
        emit FlipSales(lastCollectionId.add(1), true);
    }

    /*
    @dev:   * sets isSaleActive to false, hence ending currect sale.
            * restricted to owner only.
    */
    function endSales() public onlyOwner{
        require(totalSupply() == endIndex, "Maximum Token for current collection has not been minted");
        
        lastCollectionId += 1;
        _allCollection[lastCollectionId] = upcomingCollection;
        
        isSaleActive = false;
    }

    /*
    NOTE:   * if the project implements ipfs, updation of baseURI is recommended after each sale.
    */
    function setBaseURI(string memory baseURI) public onlyOwner{
        _setBaseURI(baseURI);
    }

    /*
    @dev:   * minting fuction for the token.
            * payable allows contract to hold ether.
    */
    function mint(uint tokenCount) public payable{

        //isSaleActive should be set to true
        require(isSaleActive, "Sale is not active");

        //maximum token purchase is restricted to 3 tokens only
        require(tokenCount <= MAX_RSW_PURCHASE, "Can only mint 3 tokens at a time");

        //check maxRSW reached
        require(totalSupply().add(tokenCount) <= maxRSW, "Exceeds maximum RSW token supply");

        //check for maximum token supply of the token
        require(totalSupply().add(tokenCount) <= endIndex, "Purchase exceeds maximum supply for the collection");

        //check for offered price
        require(faceValue.mul(tokenCount) <= msg.value, "Insufficient ether sent" );

        for(uint i = 0 ; i < tokenCount; i++ ){
            uint index = totalSupply();
            if(totalSupply() < endIndex){
                //@dev: Refer to ERC721 contract
                _safeMint(msg.sender, index); 
            }else{
                revert("Revert: Purchase exceeds maximum supply for the collection");
            }            
        }
    }

    /*
    @dev:   * reserve token funtion
            * This allow the deployer to mint one entire collection as reserve 
              without an active sale
    */
    function reserveTokens()public onlyOwner{
        flipSaleStatus();
        uint index = totalSupply();
        for(uint i = 0; i < maxTokenPerCollection; i++){
            if(totalSupply() <= endIndex){
                _safeMint(msg.sender, index + i);
            }
        }
        endSales();
    }

    /*
    NOTE:   * store on-chain token souce code.
            * recommended not to use this function. Inefficient for gas consumption.
    */
    function setSourceCode(uint tokenId, string memory tokenSourceCode)public onlyOwner{
        _setTokenSourceCode(tokenId, tokenSourceCode);
    }
}