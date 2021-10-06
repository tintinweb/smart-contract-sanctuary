// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import './Ownable.sol';
import "./Strings.sol";
import "./ERC721Enumerable.sol";


contract Panthers is ERC721Enumerable, Ownable {
    using Strings for uint;
    
    // CONSTANTS
    uint public MAX_SUPPLY = 3333;
    
    // SEMI-CONSTANTS
    uint public minting_price = 0.05 ether;
    
    // VARIABLES
    mapping(address => uint) public presale_allocations;
    mapping(address => uint8) public free_allocations;
    
    bool public minting_allowed = false;
    string base_uri = "https://crazypanthersparty.com/metadata/";
    
    constructor() ERC721 ("Crazy Panthers Party", "PANTHERS") {
        
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(base_uri, (tokenId + 1).toString()));
    }
    
    function freeMint(uint _quantity) external {
        require(free_allocations[msg.sender] >= _quantity, "Insufficient presale allocation");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Not enough tokens left to mint");
        
        for (uint i = 0; i < _quantity; ++i) {
            _safeMint(msg.sender, totalSupply());
            free_allocations[msg.sender]--;
        }
    }
    
    function presaleMint(uint _quantity) external payable {
        require(presale_allocations[msg.sender] >= _quantity, "Insufficient presale allocation");
        require(msg.value == _quantity * minting_price, "Incorrect ETH sent to premint");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Not enough tokens left to mint");
        
        for (uint i = 0; i < _quantity; ++i) {
            _safeMint(msg.sender, totalSupply());
            presale_allocations[msg.sender]--;
        }
    }
    
    function publicSaleMint(uint _quantity) external payable {
        require(minting_allowed, "Minting is currently disabled");
        require(_quantity <= 20, "Invalid number of tokens queries for minting");
        require(msg.value == _quantity * minting_price, "Incorrect ETH sent to mint");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Not enough tokens left to mint");
        
        for (uint i = 0; i < _quantity; ++i) {
            _safeMint(msg.sender, totalSupply());
        }
    }
    
    function ownerMint(address _to, uint _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Not enough left to mint");
        
        for (uint i = 0; i < _quantity; ++i) _safeMint(_to, totalSupply());
    }
    
    function setMintingPrice(uint _minting_price) external onlyOwner {
        minting_price = _minting_price;
    }
    
    function setBaseURI(string memory _new_uri) external onlyOwner {
        base_uri = _new_uri;
    }
    
    function toggleMinting() external onlyOwner {
        minting_allowed = !minting_allowed;
    }
    
    function withdraw() external onlyOwner {
        address main_team = 0x2Bd2ae185E6EB8Fc6d60efC6ED560126f25159b5;
        address dev_1_address = 0x22438B6e5732d0827Dd95Fb5762B93B721001380;
        address dev_2_address = 0x9408c666a65F2867A3ef3060766077462f84C717;
        
        payable(main_team).transfer(70 * address(this).balance / 100);
        payable(dev_1_address).transfer(address(this).balance / 2);
        payable(dev_2_address).transfer(address(this).balance);
    }
    
    function addFreeMint(address [] memory addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; ++i) {
            free_allocations[addresses[i]]++;
        }
    }
    
    function addPresale(address [] memory addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; ++i) {
            presale_allocations[addresses[i]]++;
        }
    }
}