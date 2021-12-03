// ___  ___  ________  _____ ______   _____ ______   ___  _______           ________  ________  _____ ______   _______      
//|\  \|\  \|\   __  \|\   _ \  _   \|\   _ \  _   \|\  \|\  ___ \         |\   ____\|\   __  \|\   _ \  _   \|\  ___ \     
//\ \  \\\  \ \  \|\  \ \  \\\__\ \  \ \  \\\__\ \  \ \  \ \   __/|        \ \  \___|\ \  \|\  \ \  \\\__\ \  \ \   __/|    
// \ \   __  \ \   __  \ \  \\|__| \  \ \  \\|__| \  \ \  \ \  \_|/__       \ \  \  __\ \   __  \ \  \\|__| \  \ \  \_|/__  
//  \ \  \ \  \ \  \ \  \ \  \    \ \  \ \  \    \ \  \ \  \ \  \_|\ \       \ \  \|\  \ \  \ \  \ \  \    \ \  \ \  \_|\ \ 
//   \ \__\ \__\ \__\ \__\ \__\    \ \__\ \__\    \ \__\ \__\ \_______\       \ \_______\ \__\ \__\ \__\    \ \__\ \_______\
//    \|__|\|__|\|__|\|__|\|__|     \|__|\|__|     \|__|\|__|\|_______|        \|_______|\|__|\|__|\|__|     \|__|\|_______|                                                                                                                                                                                                                           

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Fluff.sol";
import "./Galaxy.sol";

contract Hammies is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;
    
    Counters.Counter private _tokenIdTracker;

    Fluff fluff;
    
    uint256 public maxFreeSupply = 888;
    uint256 public constant maxPublicSupply = 4888;
    uint256 public constant maxTotalSupply = 8888;
    uint256 public constant mintPrice = 0.06 ether;
    uint256 public constant maxPerTx = 10;
    uint256 public constant maxFreePerWallet = 10;

    address public constant dev1Address = 0xcd2367Fcfbd8bf8eF87C98fC53Cc2EA27437f6EE;
    address public constant dev2Address = 0x2E824997ACE675F5BdB0d56121Aa04B2599BDa8B;

    bool mintActive = false;
    bool public fluffMinting = false;
    
    mapping(address => uint256) public freeMintsClaimed; //Track free mints claimed per wallet
    
    string public baseTokenURI;

    constructor() ERC721("Hammies", "HG") {}
    
    //-----------------------------------------------------------------------------//
    //------------------------------Mint Logic-------------------------------------//
    //-----------------------------------------------------------------------------//
    
    //Resume/pause Public Sale
    function toggleMint() public onlyOwner {
        mintActive = !mintActive;
    }

    //Public Mint
    function mint(uint256 _count) public payable {
        uint256 total = _totalSupply();
        require(mintActive, "Sale has not begun");
        require(total + _count <= maxPublicSupply, "No hammies left");
        require(_count <= maxPerTx, "10 max per tx");
        require(msg.value >= price(_count), "Not enough eth sent");

        for (uint256 i = 0; i < _count; i++) {
            _mintHammie(msg.sender);
        }
    }
    
    //Free Mint for first 888
    function freeMint(uint256 _count) public {
        uint256 total = _totalSupply();
        require(mintActive, "Public Sale is not active");
        require(total + _count <= maxFreeSupply, "No more free hammies");
        require(_count + freeMintsClaimed[msg.sender] <= maxFreePerWallet, "Only 10 free mints per wallet");
        require(_count <= maxPerTx, "10 max per tx");

        for (uint256 i = 0; i < _count; i++) {
            freeMintsClaimed[msg.sender]++;
            _mintHammie(msg.sender);
        }
    }
    
    //Public Mint until 4888
    function mintHammieForFluff() public {
        uint256 total = _totalSupply();
        require(total < maxTotalSupply, "No Hammies left");
        require(fluffMinting, "Minting with $fluff has not begun");
        fluff.burn(msg.sender, getFluffCost(total));
        _mintHammie(msg.sender);
    }
    
    function getFluffCost(uint256 totalSupply) internal pure returns (uint256 cost){
        if (totalSupply < 5888)
            return 100;
        else if (totalSupply < 6887)
            return 200;
        else if (totalSupply < 7887)
            return 400;
        else if (totalSupply < 8887)
            return 800;
    }
    
    //Mint Hammie
    function _mintHammie(address _to) private {
        uint id = _tokenIdTracker.current();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
    }

    //Function to get price of minting a hammie
    function price(uint256 _count) public pure returns (uint256) {
        return mintPrice.mul(_count);
    }
    
    //-----------------------------------------------------------------------------//
    //---------------------------Admin & Internal Logic----------------------------//
    //-----------------------------------------------------------------------------//

    //Set address for $Fluff
    function setFluffAddress(address fluffAddr) external onlyOwner {
        fluff = Fluff(fluffAddr);
    }
    
    //Internal URI function
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    //Start/Stop minting hammies for $fluff
    function toggleFluffMinting() public onlyOwner {
        fluffMinting = !fluffMinting;
    }
    
    //Set URI for metadata
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    
    //Withdraw from contract
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 dev1Share = balance.mul(50).div(100);
        uint256 dev2Share = balance.mul(50).div(100);

        require(balance > 0);
        _withdraw(dev1Address, dev1Share);
        _withdraw(dev2Address, dev2Share);
    }

    //Internal withdraw
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    
    //Return total supply of hammies
    function _totalSupply() public view returns (uint) {
        return _tokenIdTracker.current();
    }
}