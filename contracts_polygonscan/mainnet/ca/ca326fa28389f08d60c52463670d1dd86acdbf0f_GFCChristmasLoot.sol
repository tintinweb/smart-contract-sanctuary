// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Supply.sol";

import "./Ownable.sol";

import "./Strings.sol";

contract GFCChristmasLoot is ERC1155Supply, Ownable{
    using Strings for uint256;

    //Used to mix up the random numbers in a single transaction
    uint256 private nounce;
    
    //OpenSea's Proxy contract for ERC1155 on Polygon
    address public OPEN_SEA = 0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101;

    //Timestamp for the openCrackers function to open
    //26th of Dec 2021, 12pm EST
    uint256 boxingDay = 1640538000;

    constructor(string memory path) ERC1155(path) {}

    /** 
     * Airdrop Christmas Crackers
     */
    function airdropCracker(address[] calldata addrs, uint256[] calldata amount) public onlyOwner {
        for(uint256 i; i < addrs.length; i++){
            _mint(addrs[i], 0, amount[i], "");
        }
    }

    /**
     *  Function made for Christmas Cracker holders to burn their Cracker NFT for a chance of getting the Christmas hat
     *  @param amount - the number of Christmas Cracker you would like to burn in this particular transaction
     */
    function openCrackers(uint256 amount) public {
        require(block.timestamp >= boxingDay, "Be patient, you can only open your Cracker after Christmas on 12pm EST Boxing Day");
        require(balanceOf(msg.sender, 0) >= amount, "You are trying to open more Christmas Cracker than you currently have");
        uint256 winCount;
        //Call getCrackerResult() in a loop
        //To get randomised result of the caller
        //incrementing the nounce every loop
        for(uint256 i; i < amount; i++) {
            if(getCrackerResult()) {
                winCount++;
            }
            nounce++;
        }
        //Mint the Christmas hats if they won any
        if(winCount > 0) {
            _mint(msg.sender, 1, winCount, "");
        }
        //Burn the cracker NFTs
        _burn(msg.sender, 0, amount);
    }

    //Generate a random number between 0 and 9999
    //if the random number is less than 5000, return true
    //otherwise return false
    function getCrackerResult() public view returns (bool) {
        return (uint256(keccak256(abi.encode(block.difficulty, block.timestamp, nounce))) % 10000 < 5000);
    }

    /*
     * Only the owner can do these things
     */
    function setURI(string memory newURI) public onlyOwner {
      _setURI(newURI);
    }
    
    function setOpenSea(address addr) public onlyOwner {
      OPEN_SEA = addr;
    }

    function setBoxingDay(uint256 timestamp) public onlyOwner {
        boxingDay = timestamp;
    }

    //VIEW FUNCTIONS
    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory baseURI = ERC1155.uri(tokenId);
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function tokenURI(uint256 tokenId) public view returns (string memory)
    {
        return uri(tokenId);
    }

    function name() external pure returns (string memory) {
        return "GFCChristmasLoot";
    }

    function symbol() external pure returns (string memory) {
        return "GFCXmas";
    }
    
    /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
       if (_operator == OPEN_SEA) {
            return true;
        }
        // otherwise, use the default ERC1155.isApprovedForAll()
        return ERC1155.isApprovedForAll(_owner, _operator);
    }
}