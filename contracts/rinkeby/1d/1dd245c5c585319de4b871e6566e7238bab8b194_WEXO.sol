// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";
import "./MerkleProof.sol";

contract WEXO is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    
	uint256 public MAX_BY_MINT_IN_TRANSACTION = 4;
	uint256 public MAX_BY_MINT = 20;
	
	uint256 public P1T1_NFT = 2217;
	uint256 public P1T2_NFT = 468;
	uint256 public P1T3_NFT = 298;
	uint256 public P1T4_NFT = 152;
	uint256 public P1T5_NFT = 198;
	
	uint256 public P1T1_PRICE = 2 * 10**17;
	uint256 public P1T2_PRICE = 5 * 10**17;
	uint256 public P1T3_PRICE = 8 * 10**17;
	uint256 public P1T4_PRICE = 11 * 10**17;
	uint256 public P1T5_PRICE = 25 * 10**17;
	
	uint256 public PHASE_ONE_NFT = P1T1_NFT.add(P1T2_NFT).add(P1T3_NFT).add(P1T4_NFT).add(P1T5_NFT);
	
	uint256 public P2T1_NFT = 2345;
	uint256 public P2T2_NFT = 515;
	uint256 public P2T3_NFT = 300;
	uint256 public P2T4_NFT = 173;
	
	uint256 public P2T1_PRICE = 3 * 10**17;
	uint256 public P2T2_PRICE = 7 * 10**17;
	uint256 public P2T3_PRICE = 11 * 10**17;
	uint256 public P2T4_PRICE = 15 * 10**17;
	
	uint256 public PHASE_TWO_NFT = P2T1_NFT.add(P2T2_NFT).add(P2T3_NFT).add(P2T4_NFT);
	
	uint256 public P3T1_NFT = 2345;
	uint256 public P3T2_NFT = 515;
	uint256 public P3T3_NFT = 300;
	uint256 public P3T4_NFT = 173;

	uint256 public P3T1_PRICE = 4 * 10**17;
	uint256 public P3T2_PRICE = 9 * 10**17;
	uint256 public P3T3_PRICE = 14 * 10**17;
	uint256 public P3T4_PRICE = 19 * 10**17;
	
	uint256 public PHASE_THREE_NFT = P3T1_NFT.add(P3T2_NFT).add(P3T3_NFT).add(P3T4_NFT);
	uint256 public MAX_NFT = PHASE_ONE_NFT.add(PHASE_TWO_NFT).add(PHASE_THREE_NFT);
	
	uint256 public PHASE_ONE_MINTED;
	uint256 public PHASE_TWO_MINTED;
	uint256 public PHASE_THREE_MINTED;
	
	struct User {
	   uint256 salemint;
    }
	
	mapping (address => User) public users;
	bool public phaseOneEnable = false;
	bool public phaseTwoEnable = false;
	bool public phaseThreeEnable = false;
	
	string public baseTokenURI;
	bytes32 public merkleRoot;
    event CreateNFT(uint256 indexed id);
	
    constructor(string memory baseURI) ERC721("Wild EXOplanet Game", "WEXO") {
		setBaseURI(baseURI);
        pause(true);
    }
	
    modifier saleIsOpen {
        require(_totalSupply() <= MAX_NFT, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }
	
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
	
	function mintPhaseOneNFT(uint256 _count, bytes32[] calldata merkleProof) public payable saleIsOpen {
        uint256 total = PHASE_ONE_MINTED;
		bytes32 node = keccak256(abi.encodePacked(msg.sender));
		require(
			phaseOneEnable, 
			"Phase one is not enable"
		);
		require(
			MerkleProof.verify(merkleProof, merkleRoot, node), 
			"MerkleDistributor: Invalid proof."
		);
		require(
		    _count <= MAX_BY_MINT_IN_TRANSACTION,
			"Exceeds max mint limit per transaction"
		);
		require(
			total.add(_count) <= PHASE_ONE_NFT, 
			"Exceeds max limit"
		);
		require(
			users[msg.sender].salemint.add(_count) <= MAX_BY_MINT, 
			"Exceeds max mint limit per wallet"
		);
		if (_msgSender() != owner()) {
		   require(
			   msg.value >= phaseOnePrice(_count),
			   "Value below price"
			);
		}
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			PHASE_ONE_MINTED++;
        }
		users[msg.sender].salemint = users[msg.sender].salemint.add(_count);
    }
	
	function phaseOnePrice(uint256 _count) public view returns (uint256) {
	    uint256 total = PHASE_ONE_MINTED;
		uint256 priceAllNFT;
		for(uint256 i = 1; i <= _count; i++) 
		{
		    if(total + i > P1T1_NFT.add(P1T2_NFT).add(P1T3_NFT).add(P1T4_NFT)) 
			{
				priceAllNFT = priceAllNFT.add(P1T5_PRICE);
			}
			else if(total + i > P1T1_NFT.add(P1T2_NFT).add(P1T3_NFT)) 
			{
				priceAllNFT = priceAllNFT.add(P1T4_PRICE);
			}
			else if(total + i > P1T1_NFT.add(P1T2_NFT)) 
			{
				priceAllNFT = priceAllNFT.add(P1T3_PRICE);
			}
			else if(total + i >  P1T1_NFT) 
			{
				priceAllNFT = priceAllNFT.add(P1T2_PRICE);
			}
			else 
			{
				priceAllNFT = priceAllNFT.add(P1T1_PRICE);
			}
        }
        return priceAllNFT; 		
    }
	
	function mintPhaseTwoNFT(uint256 _count) public payable saleIsOpen {
        uint256 total = PHASE_TWO_MINTED;
		require(
			phaseTwoEnable, 
			"Phase two is not enable"
		);
		require(
			total.add(_count) <= PHASE_TWO_NFT, 
			"Exceeds max limit"
		);
		require(
		    _count <= MAX_BY_MINT_IN_TRANSACTION,
			"Exceeds max mint limit per transaction"
		);
		require(
			users[msg.sender].salemint.add(_count) <= MAX_BY_MINT, 
			"Exceeds max mint limit per wallet"
		);
		if (_msgSender() != owner()) {
		   require(
			   msg.value >= phaseTwoPrice(_count),
			   "Value below price"
			);
		}
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			PHASE_TWO_MINTED++;
        }
		users[msg.sender].salemint = users[msg.sender].salemint.add(_count);
    }
	
	function phaseTwoPrice(uint256 _count) public view returns (uint256) {
	    uint256 total = PHASE_TWO_MINTED;
		uint256 priceAllNFT;
		for(uint256 i = 1; i <= _count; i++) 
		{
			if(total + i > P2T1_NFT.add(P2T2_NFT).add(P2T3_NFT)) 
			{
				priceAllNFT = priceAllNFT.add(P2T4_PRICE);
			}
			else if(total + i >  P2T1_NFT.add(P2T2_NFT)) 
			{
				priceAllNFT = priceAllNFT.add(P2T3_PRICE);
			}
			else if(total + i > P2T1_NFT) 
			{
				priceAllNFT = priceAllNFT.add(P2T2_PRICE);
			}
			else 
			{
				priceAllNFT = priceAllNFT.add(P2T1_PRICE);
			}
        }
        return priceAllNFT; 		
    }
	
	function mintPhaseThreeNFT(uint256 _count) public payable saleIsOpen {
        uint256 total = PHASE_THREE_MINTED;
		require(
			phaseThreeEnable, 
			"Phase three is not enable"
		);
		require(
			total.add(_count) <= PHASE_THREE_NFT, 
			"Exceeds max limit"
		);
		require(
		    _count <= MAX_BY_MINT_IN_TRANSACTION,
			"Exceeds max mint limit per transaction"
		);
		require(
			users[msg.sender].salemint.add(_count) <= MAX_BY_MINT, 
			"Exceeds max mint limit per wallet"
		);
		if (_msgSender() != owner()) {
		   require(
			   msg.value >= phaseThreePrice(_count),
			   "Value below price"
			);
		}
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			PHASE_THREE_MINTED++;
        }
		users[msg.sender].salemint = users[msg.sender].salemint.add(_count);
    }
	
	function phaseThreePrice(uint256 _count) public view returns (uint256) {
	    uint256 total = PHASE_THREE_MINTED;
		uint256 priceAllNFT;
		for(uint256 i = 1; i <= _count; i++) 
		{
			if(total + i > P3T1_NFT.add(P3T2_NFT).add(P3T3_NFT)) 
			{
				priceAllNFT = priceAllNFT.add(P3T4_PRICE);
			}
			else if(total + i > P3T1_NFT.add(P3T2_NFT)) 
			{
				priceAllNFT = priceAllNFT.add(P3T3_PRICE);
			}
			else if(total + i > P3T1_NFT) 
			{
				priceAllNFT = priceAllNFT.add(P3T2_PRICE);
			}
			else 
			{
				priceAllNFT = priceAllNFT.add(P3T1_PRICE);
			}
        }
        return priceAllNFT; 		
    }
	
    function _mintAnElement(address _to) private {
        _tokenIdTracker.increment();
        _safeMint(_to, _tokenIdTracker.current());
        emit CreateNFT(_tokenIdTracker.current());
    }
	
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
	
	function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
	
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }
	
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
	
	function withdraw(uint256 amount) public onlyOwner {
		uint256 balance = address(this).balance;
        require(balance >= amount);
		payable(msg.sender).transfer(amount);
    }
	
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
	
	function setPhaseOneStatus(bool status) public onlyOwner {
	   require(phaseOneEnable != status);
       phaseOneEnable = status;
    }
	
	function setPhaseTwoStatus(bool status) public onlyOwner {
	   require(phaseTwoEnable != status);
       phaseTwoEnable = status;
    }
	
	function setPhaseThreeStatus(bool status) public onlyOwner {
	   require(phaseThreeEnable != status);
       phaseThreeEnable = status;
    }
	
	function updateMintLimitPerTransection(uint256 newLimit) external onlyOwner {
       MAX_BY_MINT_IN_TRANSACTION = newLimit;
    }
	
	function updateSaleMintLimit(uint256 newLimit) external onlyOwner {
       MAX_BY_MINT = newLimit;
    }
	
	function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
	    merkleRoot = newRoot;
	}
	
	function setPhaseOnePrice(uint256 _P1T1_PRICE, uint256 _P1T2_PRICE, uint256 _P1T3_PRICE, uint256 _P1T4_PRICE, uint256 _P1T5_PRICE) external onlyOwner{
        P1T1_PRICE = _P1T1_PRICE;
		P1T2_PRICE = _P1T2_PRICE;
		P1T3_PRICE = _P1T3_PRICE;
		P1T4_PRICE = _P1T4_PRICE;
		P1T5_PRICE = _P1T5_PRICE;
    }
	
	function setPhaseTwoPrice(uint256 _P2T1_PRICE, uint256 _P2T2_PRICE, uint256 _P2T3_PRICE, uint256 _P2T4_PRICE) external onlyOwner{
        P2T1_PRICE = _P2T1_PRICE;
		P2T2_PRICE = _P2T2_PRICE;
		P2T3_PRICE = _P2T3_PRICE;
		P2T4_PRICE = _P2T4_PRICE;
    }
	
	function setPhaseThreePrice(uint256 _P3T1_PRICE, uint256 _P3T2_PRICE, uint256 _P3T3_PRICE, uint256 _P3T4_PRICE) external onlyOwner{
        P3T1_PRICE = _P3T1_PRICE;
		P3T2_PRICE = _P3T2_PRICE;
		P3T3_PRICE = _P3T3_PRICE;
		P3T4_PRICE = _P3T4_PRICE;
    }
	
	function setPhaseOneLimit(uint256 _P1T1_NFT, uint256 _P1T2_NFT, uint256 _P1T3_NFT, uint256 _P1T4_NFT, uint256 _P1T5_NFT) external onlyOwner{
        P1T1_NFT = _P1T1_NFT;
		P1T2_NFT = _P1T2_NFT;
		P1T3_NFT = _P1T3_NFT;
		P1T4_NFT = _P1T4_NFT;
		P1T5_NFT = _P1T5_NFT;
    }
	
	function setPhaseTwoLimit(uint256 _P2T1_NFT, uint256 _P2T2_NFT, uint256 _P2T3_NFT, uint256 _P2T4_NFT) external onlyOwner{
        P2T1_NFT = _P2T1_NFT;
		P2T2_NFT = _P2T2_NFT;
		P2T3_NFT = _P2T3_NFT;
		P2T4_NFT = _P2T4_NFT;
    }
	
	function setPhaseThreeLimit(uint256 _P3T1_NFT, uint256 _P3T2_NFT, uint256 _P3T3_NFT, uint256 _P3T4_NFT) external onlyOwner{
        P3T1_NFT = _P3T1_NFT;
		P3T2_NFT = _P3T2_NFT;
		P3T3_NFT = _P3T3_NFT;
		P3T4_NFT = _P3T4_NFT;
    }

}