// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract TheVoxelUniverse is ERC721, Ownable {    
    string public baseURI;

    uint256 public MINT_PRICE = 1 gwei;
    uint256 public totalSupply;

    bool public presaleActive = false;
    bool public publicSaleActive = false;

    uint32 public batchCounter = 0;
    uint32 public constant BATCH_SIZE = 20;

    mapping(address => mapping(uint => uint)) presaleMintsTracker;
    mapping(address => mapping(uint => uint)) publicSaleMintsTracker;

    mapping(uint => uint) public maxPresaleMintsPerWalletForBatch;
    mapping(uint => uint) public maxPublicMintsPerWalletForBatch;
    mapping(uint => uint) public batchTotalMintsCounter;

    bytes32 public merkleRoot;

    constructor() ERC721("The Voxel Universe", "VOXU") {
        batchTotalMintsCounter[batchCounter] = 0;
        maxPresaleMintsPerWalletForBatch[batchCounter] = 2;
        maxPublicMintsPerWalletForBatch[batchCounter] = 2;
    }

    function mint(uint numberOfMints) public payable {
        require(tx.origin == msg.sender, "Only EOA");
        require(publicSaleActive, "Sale must be active to mint");
        require((batchTotalMintsCounter[batchCounter] + numberOfMints) <= BATCH_SIZE, "Reached max supply for this collection");
        require((publicSaleMintsTracker[msg.sender][batchCounter] + numberOfMints) <= maxPublicMintsPerWalletForBatch[batchCounter], "You can't mint more for this batch");
        require((MINT_PRICE * numberOfMints) == msg.value, "Invalid ETH value sent");

        for (uint i = 0; i < numberOfMints; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        totalSupply += numberOfMints;
        batchTotalMintsCounter[batchCounter] += numberOfMints;
        publicSaleMintsTracker[msg.sender][batchCounter] += numberOfMints;
    }

    function presaleMint(uint numberOfMints, bytes32[] calldata _merkleProof) public payable {
        require(tx.origin == msg.sender, "Only EOA");
        require(presaleActive, "Sale must be active to mint");
        require((batchTotalMintsCounter[batchCounter] + numberOfMints) <= BATCH_SIZE, "Reached max supply for this collection");
        require((presaleMintsTracker[msg.sender][batchCounter] + numberOfMints) <= maxPresaleMintsPerWalletForBatch[batchCounter], "You can't mint more for this batch");
        require((MINT_PRICE * numberOfMints) == msg.value, "Invalid ETH value sent");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof");

        for (uint i = 0; i < numberOfMints; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        totalSupply += numberOfMints;
        batchTotalMintsCounter[batchCounter] += numberOfMints;
        presaleMintsTracker[msg.sender][batchCounter] += numberOfMints;
    }

    function gift(address[] calldata destinations) public onlyOwner {
        require((batchTotalMintsCounter[batchCounter] + destinations.length) <= BATCH_SIZE, "Reached max supply for this collection");

        for (uint i = 0; i < destinations.length; i++) {
            _safeMint(destinations[i], totalSupply + i);
        }

        totalSupply += destinations.length;
        batchTotalMintsCounter[batchCounter] += destinations.length;
    }

    function setSaleStatus(bool _presale, bool _public) public onlyOwner {
        require(!(_presale == true && _public == true), "Can't both be active");

        presaleActive = _presale;
        publicSaleActive = _public;
    }

    function goToNextBatch(uint _maxPresaleMintsPerWallet, uint _maxPublicSaleMintsPerWallet, bytes32 _merkleRoot) public onlyOwner {
        require(totalSupply % BATCH_SIZE == 0, "Current batch did not mint out yet");
        batchCounter++;

        merkleRoot = _merkleRoot;
        batchTotalMintsCounter[batchCounter] = 0;
        maxPresaleMintsPerWalletForBatch[batchCounter] = _maxPresaleMintsPerWallet;
        maxPublicMintsPerWalletForBatch[batchCounter] = _maxPublicSaleMintsPerWallet;

        presaleActive = false;
        publicSaleActive = false;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMintPrice(uint new_price) public onlyOwner {
        MINT_PRICE = new_price;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}