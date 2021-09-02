// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// contract inheritance
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/* 

    complexminter is a "core" contract that mints desired NFTs.
    it does not have a mint function available for the public, but
    rather needs to interface with a minter "front" which will
    determine the specificites required for each mint. 
    this contract is not payable.
    
*/

contract ComplexMinterCore is ERC721Enumerable, Ownable {
    
    address public minterAddress;
    address public claimerAddress;
    
    uint public startMintId;
    uint public nextMintId;
    uint public finalMintId;
    
    string private baseTokenURI;
    
    event Mint(address indexed to, uint indexed tokenId);
    event Claim(address indexed to, uint indexed tokenId);
    event NewConfiguration(uint indexed startId, uint indexed nextId, uint indexed finalId);
    
    constructor() payable ERC721("Complex Minter Core", "COMPLEX") {}
    
    // modifiers
    modifier onlyMinter() { 
        require(msg.sender == minterAddress, "You are not the chosen Minter.");
        _;
    }
    modifier onlyClaimer() {
        require(msg.sender == claimerAddress, "You are not the chosen Claimer.");
        _;
    }
    
    // withdrawal
    function withdrawEther() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    // internal viewers (theyre actually public) 
    function maxAvailableTokensForConfig() public view returns (uint) {
        return (finalMintId - startMintId) + 1;
    }
    function availableTokensRemaining() public view returns (uint) {
        return (finalMintId - nextMintId) + 1;
    }
    
    // internal workers
    /* core setter */
    function setMinterAddress(address address_) external onlyOwner {
        minterAddress = address_;
    }
    function setClaimerAddress(address address_) external onlyOwner {
        claimerAddress = address_;
    }
    function setStartMintId(uint id_) public onlyOwner {
        startMintId = id_;
    }
    function setFinalMintId(uint id_) public onlyOwner {
        finalMintId = id_;
    }
    function setNextMintId(uint id_) public onlyOwner {
        nextMintId = id_;
    }
    function initNewMintingSet(uint startId_, uint nextId_, uint finalId_) external onlyOwner {
        setStartMintId(startId_);
        setNextMintId(nextId_);
        setFinalMintId(finalId_);
        emit NewConfiguration(startId_, nextId_, finalId_);
    }
    /* these are for other configs */
    function setBaseTokenURI(string memory uri_) external onlyOwner {
        baseTokenURI = uri_;
    }
    
    // internal maths
    function incrementNextMintId() internal {
        require(nextMintId < finalMintId, "Next Mint ID is equal to or Exceeds Final Mint ID!");
        nextMintId = nextMintId++;
    }
    
    // view functions
    function tokenURI(uint tokenId_) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId_)));
    }
    function getTokensOfAddress(address address_) public view returns (uint[] memory) {
        uint _tokenBalance = balanceOf(address_);
        uint[] memory _tokenIds = new uint[](_tokenBalance);
        for (uint i = 0; i < _tokenBalance; i++) {
            _tokenIds[i] = tokenOfOwnerByIndex(address_, i);
        }
        return _tokenIds;
    }
    
    // owner mint
    function ownerMint(address to_, uint amount_) external onlyOwner {
        require(availableTokensRemaining() >= amount_, "Not enough available tokens remaining!");
        for (uint i = 0; i < amount_; i++) {
            uint _tokenId = nextMintId;
            incrementNextMintId();
            _mint(to_, _tokenId);
            emit Mint(to_, _tokenId);
        }
    }

    // minter mint
    function minterMint(address to_) external onlyMinter {
        require(availableTokensRemaining() >= 1, "Not enough available tokens remaining!");
        uint _tokenId = nextMintId;
        incrementNextMintId();
        _mint(to_, _tokenId);
        emit Mint(to_, _tokenId);
    }
    
    // claimer mint
    function claimerMint(address to_) external onlyClaimer {
        require(availableTokensRemaining() >= 1, "Not enough available tokens remaining!");
        uint _tokenId = nextMintId;
        incrementNextMintId();
        _mint(to_, _tokenId);
        emit Claim(to_, _tokenId);
    }
}