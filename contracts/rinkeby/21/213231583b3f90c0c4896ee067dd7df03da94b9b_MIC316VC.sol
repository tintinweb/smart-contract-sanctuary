// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Abstract316VC.sol";

contract MIC316VC is Abstract316VC {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
	
    Counters.Counter private TierCounter; 
    mapping(uint256 => Tier) public Tiers;
    event Mint(address indexed account, uint amount);
	
    struct Tier {
        bytes32 merkleRoot;
        uint256 totalSupply;
        uint256 totalMinted;
		uint256 price;
		uint256 mintLimit;
		uint256 mintPerTransectionLimit;
		bool status;
		bool whiteliststatus;
        string ipfsMetadataHash;
		mapping(address => uint256) mintedNFT;
    }
	
    constructor() ERC1155("ipfs://ipfs/") {
    }
	
    function addTier(
		bytes32 _merkleRoot, 
		uint256 _totalSupply, 
		uint256 _price, 
		uint256 _mintLimit, 
		uint256 _mintPerTransectionLimit, 
		string memory _ipfsMetadataHash
	) external onlyOwner {
        Tier storage tier = Tiers[TierCounter.current()];
        tier.merkleRoot = _merkleRoot;
        tier.totalSupply = _totalSupply;
        tier.price = _price;
		tier.mintLimit = _mintLimit;
		tier.mintPerTransectionLimit = _mintPerTransectionLimit;
		tier.ipfsMetadataHash = _ipfsMetadataHash;
		tier.status = false;
		tier.whiteliststatus = false;
        TierCounter.increment();
    }
	
	function editTier (
		bytes32 _merkleRoot, 
		uint256 _totalSupply, 
		uint256 _price, 
		uint256 _mintLimit, 
		uint256 _mintPerTransectionLimit, 
		string memory _ipfsMetadataHash, 
		uint256 _tierIndex
	) external onlyOwner {
        require(_totalSupply >= Tiers[_tierIndex].totalMinted, "Incorrect total supply");
		Tiers[_tierIndex].merkleRoot = _merkleRoot;
        Tiers[_tierIndex].totalSupply = _totalSupply;
        Tiers[_tierIndex].price = _price;
		Tiers[_tierIndex].mintLimit = _mintLimit;
		Tiers[_tierIndex].mintPerTransectionLimit = _mintPerTransectionLimit;
		Tiers[_tierIndex].ipfsMetadataHash = _ipfsMetadataHash;
    }
	
	function mintWhiteListNFT(uint256 _count, uint256 _tierIndex, bytes32[] calldata merkleProof) external payable {
	    bytes32 node = keccak256(abi.encodePacked(msg.sender));
		require(
		   !paused(), 
		   "contract is paused"
		);
        require(
			Tiers[_tierIndex].totalSupply != 0, 
			"Tier does not exist"
		);
		require(
			Tiers[_tierIndex].whiteliststatus, 
			"Sale is not enable"
		);
        require(
			msg.value >= _count.mul(Tiers[_tierIndex].price), 
			"Ether value incorrect"
		);
		require(
			Tiers[_tierIndex].totalMinted.add(_count) <= Tiers[_tierIndex].totalSupply, 
			"Exceeds total supply limit"
		);
        require(
			Tiers[_tierIndex].mintedNFT[msg.sender].add(_count) <= Tiers[_tierIndex].mintLimit, 
			"Exceeds max mint limit per wallet"
		);
		require(
			_count <= Tiers[_tierIndex].mintPerTransectionLimit,
			"Exceeds max mint limit per transaction"
		);
		require(
			MerkleProof.verify(merkleProof, Tiers[_tierIndex].merkleRoot, node), 
			"MerkleDistributor: Invalid proof."
		);
        Tiers[_tierIndex].mintedNFT[msg.sender] = Tiers[_tierIndex].mintedNFT[msg.sender].add(_count);
		Tiers[_tierIndex].totalMinted = Tiers[_tierIndex].totalMinted.add(_count);
        _mint(msg.sender, _tierIndex, _count, "");
        emit Mint(msg.sender, _count);
    }
	
	function mintNFT(uint256 _count, uint256 _tierIndex) external payable {
		require(
		   !paused(), 
		   "contract is paused"
		);
        require(
			Tiers[_tierIndex].totalSupply != 0, 
			"Tier does not exist"
		);
		require(
			Tiers[_tierIndex].status, 
			"Sale is not enable"
		);
        require(
			msg.value >= _count.mul(Tiers[_tierIndex].price), 
			"Ether value incorrect"
		);
		require(
			Tiers[_tierIndex].totalMinted.add(_count) <= Tiers[_tierIndex].totalSupply, 
			"Exceeds total supply limit"
		);
        require(
			Tiers[_tierIndex].mintedNFT[msg.sender].add(_count) <= Tiers[_tierIndex].mintLimit, 
			"Exceeds max mint limit per wallet"
		);
		require(
			_count <= Tiers[_tierIndex].mintPerTransectionLimit,
			"Exceeds max mint limit per transaction"
		);
		
        Tiers[_tierIndex].mintedNFT[msg.sender] = Tiers[_tierIndex].mintedNFT[msg.sender].add(_count);
		Tiers[_tierIndex].totalMinted = Tiers[_tierIndex].totalMinted.add(_count);
		
        _mint(msg.sender, _tierIndex, _count, "");
        emit Mint(msg.sender, _count);
    }
	
	function updateSaleStatus (
		uint256 _tierIndex,
		bool _status
	) external onlyOwner {
		Tiers[_tierIndex].status = _status;
    }
	
	function updateWhitelistStatus (
		uint256 _tierIndex,
		bool _status
	) external onlyOwner {
		Tiers[_tierIndex].whiteliststatus = _status;
    }
	
    function withdrawEther(address payable _to) public onlyOwner{
	    uint256 balance = address(this).balance;
        _to.transfer(balance);
    }
	
	function getSaleMinted(uint256 tier, address userAdress) public view returns (uint256) {
        return Tiers[tier].mintedNFT[userAdress];
    }
	
    function uri(uint256 _id) public view override returns (string memory) {
       require(totalSupply(_id) > 0, "URI: nonexistent token");
       return string(abi.encodePacked(super.uri(_id), Tiers[_id].ipfsMetadataHash));
    }    
}