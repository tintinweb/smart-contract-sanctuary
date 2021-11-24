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
    
    uint256 public maxFreeSupply = 777;
    uint256 public constant maxPublicSupply = 3777;
    uint256 public constant maxTotalSupply = 7777;
    uint256 public constant mintPrice = 0.0420 ether; // will be set later
    uint256 public constant maxPerTx = 10;
    uint256 public constant maxFreePerWallet = 100;
    uint256 public stakingStartTime; //Track time staking for $Fluff begins

    address public constant dev1Address = 0x8DeE7cF46359fe2C30F1ABe898568487BeCFe5e7;
    address public constant dev2Address = 0x601edb6bE9641856c20E377FA9992D8C8223a8CD;

    bool public staking = false;
    bool mintActive = false;
    
    mapping(uint256 => uint256) public timeClaimed; //Track time $Fluff claimed by ID
    mapping(address => uint256) public freeMintsClaimed; //Track free mints claimed per wallet
    
    string public baseTokenURI;

    constructor() ERC721("Space Hammies", "SH") {}
    
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
        require(total + _count <= maxPublicSupply, "No hammys left");
        require(_count <= maxPerTx, "10 max per tx");
        require(msg.value >= price(_count), "Not enough eth sent");

        for (uint256 i = 0; i < _count; i++) {
            _mintHammy(msg.sender);
        }
    }
    
     //Free Mint for first 777
    function freeMint(uint256 _count) public {
        uint256 total = _totalSupply();
        require(mintActive, "Public Sale is not active");
        require(total + _count <= maxFreeSupply, "No more free hammys");
        require(_count + freeMintsClaimed[msg.sender] <= maxFreePerWallet, "Only 10 free mints per wallet");
        require(_count <= maxPerTx, "10 max per tx");

        for (uint256 i = 0; i < _count; i++) {
            freeMintsClaimed[msg.sender]++;
            _mintHammy(msg.sender);
        }
    }
    
    //Public Mint
    function mintHammyForFluff() public {
        uint256 total = _totalSupply();
        require(total < maxTotalSupply, "No hammys left");

        fluff.burn(msg.sender, getFluffCost(total));
        _mintHammy(msg.sender);
    }
    
    function getFluffCost(uint256 totalSupply) internal pure returns (uint256 cost){
        if (totalSupply < 4777)
            return 100;
        else if (totalSupply < 5777)
            return 500;
        else if (totalSupply < 7777)
            return 1000;
    }
    
    //Mint mouse
    function _mintHammy(address _to) private {
        uint id = _tokenIdTracker.current();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
    }

    //Function to get price of minting a hammy
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