// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract SoDWhitelist is ERC721, Ownable, ReentrancyGuard {

    using MerkleProof for *;

    bytes32 public merkleRoot; // Used for whitelist check

    uint256 public maxSwords = 2222; // Max supply
    uint256 public teamReserved = 50; // 15 for team, 35 for events/giveaways
    uint256 public price = .025 ether; 
    uint256 public maxPerTx = 10; 
    uint256 public totalSupply = 0; 
    uint256 public mintingStartTime = 1635098400; // Oct 24 2pm est
    uint256 public presaleStartTime = 1635012000; // Oct 23 2pm est
    
    bool public licenseLocked = false; // Once locked nothing can be changed anymore
    bool public saleActive = true; // In case anything goes wrong, sales can be paused
    
    string private baseURI; // Site api link for OS to pull metadata from

    mapping(address => uint256) public mintedPerAccount; // Minted per whitelisted account

    constructor() ERC721("Swords of Destiny", "SWORD") Ownable() ReentrancyGuard() {
    }

    // Claim whitelisted tokens using merkle tree
    function claim(uint256 index, address account, uint256 amountReserved, uint256 amountToMint, bytes32[] calldata merkleProof) nonReentrant external payable {
        require(block.timestamp >= presaleStartTime, "Presale has not started yet");
        require(saleActive, "Sale is not currently active.");
        require(merkleRoot != bytes32(0));
        require(amountToMint + mintedPerAccount[account] <= amountReserved, "Cannot mint more than reserved");
        require(msg.value >= amountToMint * price, "Amount sent is not correct");

        // Verify the merkle proof to make sure given information matches whitelist saved info.
        bytes32 node = keccak256(abi.encodePacked(index, account, amountReserved));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Not whitelisted.");

        mintedPerAccount[account] += amountToMint;
        
        for (uint256 i = 0; i < amountToMint; i++) {
            _safeMint(account, totalSupply + i);
        }

        totalSupply += amountToMint;
    }

    function mint(uint256 _amount) nonReentrant public payable {
        require(totalSupply < maxSwords, "Sale has already ended");
        require(block.timestamp >= mintingStartTime, "Sale has not started yet");
        require(saleActive, "Sale is not currently active.");
        require(_amount <= maxPerTx, "Cannot mint more than 10 tokens per transaction");
        require(totalSupply + _amount <= maxSwords - teamReserved, "Cannot exceed max supply");
        require(msg.value >= price * _amount, "Ether sent is not correct");
        
        for (uint256 i; i < _amount; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
        
        totalSupply += _amount;
    }

    function teamMint(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Can't mint 0 tokens");
        require(_amount <= teamReserved, "Cannot exceed reserved supply");
        
        for(uint256 i; i < _amount; i++){
            _safeMint(_to, totalSupply + i);
        }
        
        teamReserved -= _amount;
        totalSupply += _amount;
    }

    function flipSaleState() public onlyOwner {
        require(!licenseLocked, "License locked, cannot make changes anymore");
        saleActive = !saleActive;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        require(!licenseLocked, "License locked, cannot make changes anymore");
        merkleRoot = _root;
    }

    function setMintingStartTime(uint256 _startTime) public onlyOwner {
         require(!licenseLocked, "License locked, cannot make changes anymore");
         mintingStartTime = _startTime;
    }

    function setPresaleStartTime(uint256 _startTime) public onlyOwner {
        require(!licenseLocked, "License locked, cannot make changes anymore");
        presaleStartTime = _startTime;
    }
    
    function setBaseURI(string memory _newURI) public onlyOwner {
        require(!licenseLocked, "License locked, cannot make changes anymore");
        baseURI = _newURI;
    }
    
    function lockLicense() public onlyOwner {
        require(!licenseLocked, "License locked, cannot make changes anymore");
        licenseLocked = !licenseLocked;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function withdraw(address _to, uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Not enough money in the balance");
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}