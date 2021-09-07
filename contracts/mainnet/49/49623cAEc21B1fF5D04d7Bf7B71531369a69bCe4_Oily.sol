// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Oily is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    
    mapping (address => bool) public presaleWhitelist;
    uint256 public _price = 0.1 ether;
    uint256 private _remaining_airdrops = 200;
    // uint256 private _extra = 100;
    phases public phase;

    enum phases {
        INIT,
        PRESALE,
        OPEN
    }

    
    address constant LOGAN = 0x8b5B9497e096ee6FfD6041D1Db37a2ac2b41AB0d;
    address constant DD0SXX = 0xd491e93c6b05e3cdA3073482a5651BCFe3DC1cc7;

    constructor(string memory baseURI) ERC721("Oilys", "OILYS") {
        setBaseURI(baseURI);
        phase = phases.INIT;
        // team gets the first 2 Oilys
        _safeMint( LOGAN, 1);
        _safeMint( DD0SXX, 2);
        _remaining_airdrops -= 2;
    }

    
    function initPresaleWhitelist (address[200] memory whitelist) external onlyOwner {
        require (whitelist.length == 200, 'whitelist must have a length of 200');
        for (uint i; i < whitelist.length; i++) {
            presaleWhitelist[whitelist[i]] = true;
        }
    }

    
    function mintPresale() external payable {
        uint256 supply = totalSupply();
        require( phase == phases.PRESALE,                    "Phase is not presale" );
        require( presaleWhitelist[msg.sender] == true,      
            "You are not on the presale whitelist or have already claimed your oily");
        require( supply <= 300,                       "Exceeds maximum Oilys supply" );
        require( msg.value >= _price,                   "Ether sent is not correct" );

        presaleWhitelist[msg.sender] = false;
        _safeMint( msg.sender, supply + 1 );
    }

    
    function mint(uint256 num) external payable {
        uint256 supply = totalSupply();
        require( phase == phases.OPEN,                          "Phase is not open" );
        require( num <= 3,                      "You can mint a maximum of 3 Oilys" );
        require( supply + num <= 300,                 "Exceeds maximum Oilys supply" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );

        for(uint256 i = 1; i <= num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    
    function airdrop(address _to, uint256 _amount) external onlyOwner {
        require( _amount <= _remaining_airdrops, "Exceeds reserved Oily supply" );
        require(_to != address(0), 'cannot giveaway to address(0)');

        uint256 supply = totalSupply();

        _remaining_airdrops -= _amount;

        for(uint256 i = 1; i <= _amount; i++) {
            _safeMint( _to, supply + i );
        }
    }

    
    function walletOfOwner(address _walletOwner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_walletOwner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_walletOwner, i);
        }
        return tokensId;
    }

    
    function setPrice(uint256 _newPrice) external onlyOwner() {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory json = ".json";
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), json)) : "";
    }

    
    function changePhaseToPresale() external onlyOwner {
        phase = phases.PRESALE;
    }

    
    function changePhaseToOpen() external onlyOwner {
        require(phase == phases.PRESALE, 'phase must be in presale first');
        phase = phases.OPEN;
    }
    
    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0);
        uint256 _each = address(this).balance / 2;
        (bool status1, ) = payable(LOGAN).call{value: _each}("");
        (bool status2, ) = payable(DD0SXX).call{value: _each}("");
        require(status1 == true && status2 == true, 'withdraw failed');
    }
    
    fallback() external payable {
        revert('You sent ether to this contract without specifying a function');
    }
    receive() external payable {
        revert('You sent ether to this contract without specifying a function');
    }
}