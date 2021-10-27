// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import './Ownable.sol';
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./Panthers.sol";

contract ScaryPanthers is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    uint256 public MAX_SUPPLY = 3333;
    
    bool public freemint_running = false;
    
    bool public public_sale_running = false;
    
    mapping (uint => bool) public token_id_claimed;
    
    Panthers private immutable panthers;
    
    string public base_uri = "https://crazypanthersparty.com/scary-metadata/";
    
    constructor(address _panthers_address) ERC721 ("Scary Panthers Party", "SCARY PANTHERS") {
        panthers = Panthers(_panthers_address);
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(base_uri, (tokenId + 1).toString()));
    }
    
    function maxFreeClaimsRemaining(address _user) public view returns (uint256) {
        uint256 user_balance = panthers.balanceOf(_user);
        uint256 count = 0;
        
        for (uint i = 0; i < user_balance; ++i) {
            uint token_id = panthers.tokenOfOwnerByIndex(_user, i);
            
            if (!token_id_claimed[token_id]) {
                ++count;
            }
        }
        
        return count;
    }
    
    function claimFromCrazyPanthers(uint256 _quantity) external {
        require(freemint_running, "Free claim period is not running");
        require(totalSupply() <= MAX_SUPPLY, "Not enough tokens left to mint");
        require(_quantity <= panthers.balanceOf(msg.sender), "Not enough allocation left");
        
        uint256 num_minted = 0;
        
        for (uint i = 0; i < panthers.balanceOf(msg.sender); ++i) {
            if (totalSupply() == MAX_SUPPLY || num_minted == _quantity) {
                break;
            }
            
            uint token_id = panthers.tokenOfOwnerByIndex(msg.sender, i);
            if (!token_id_claimed[token_id]) {
                token_id_claimed[token_id] = true;
                _safeMint(msg.sender, totalSupply());
                ++num_minted;
            }
        }
        
    }
    
    function publicMint(uint256 _quantity) external payable {
        require(public_sale_running, "Public minting not currently allowed");
        require(_quantity + totalSupply() <= MAX_SUPPLY, "Not enough tokens left to publicly mint");
        
        require(msg.value == _quantity * 0.05 ether, "Incorrect ETH sent for minting");
        require(_quantity <= 10, "Too many Panthers queried for minting");
        
        for (uint256 i = 0; i < _quantity; ++i) {
            _safeMint(msg.sender, totalSupply());
        }
    }
    
    function ownerMint(address _to, uint256 _quantity) external onlyOwner {
        require(_quantity + totalSupply() <= MAX_SUPPLY, "Not enough left to mint");
        
        for (uint i = 0; i < _quantity; ++i) {
            _safeMint(_to, totalSupply());
        }
    }
    
    function toggleFreeMinting() external onlyOwner {
        freemint_running = !freemint_running;
    }
    
    function togglePublicMinting() external onlyOwner {
        public_sale_running = !public_sale_running;
    }
    
    function withdraw() external onlyOwner {
        address main_team = 0x2Bd2ae185E6EB8Fc6d60efC6ED560126f25159b5;
        address dev_1_address = 0x22438B6e5732d0827Dd95Fb5762B93B721001380;
        address dev_2_address = 0x9408c666a65F2867A3ef3060766077462f84C717;
        
        payable(main_team).transfer(70 * address(this).balance / 100);
        payable(dev_1_address).transfer(address(this).balance / 2);
        payable(dev_2_address).transfer(address(this).balance);
    }
}