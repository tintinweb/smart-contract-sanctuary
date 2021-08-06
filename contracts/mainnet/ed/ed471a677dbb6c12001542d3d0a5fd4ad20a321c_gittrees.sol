// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// contract inheritance
import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./Ownable.sol";

contract gittrees is ERC721Enumerable, Ownable { 

    uint public mintingCost = 0.2 ether;

    uint public constant maxTokens = 256;
    uint public constant maxReservedTokens = 24;
    uint public constant maxGlyphTokens = 8;
    uint public availableTokens = 0;

    uint public normalTokensMinted = 0;
    uint public reservedTokensMinted = 0;
    uint public glyphTokensMinted = 0;

    bool public mintingEnabled = false;
    bool public claimingEnabled = false;

    string private baseTokenURI;

    address autoglyphsAddress = 0xd4e4078ca3495DE5B1d4dB434BEbc5a986197782;
    mapping(uint => uint) public glyphUsedForMint;

    event Mint(address indexed to, uint indexed tokenId);
    event MintWithGlyph(address indexed to, uint indexed tokenId, uint indexed GlyphId);

    constructor() payable ERC721("GitTrees", "GITTREES") {}

    modifier onlySender() {
        require(msg.sender == tx.origin, "Sender must be origin!");
        _;
    }
    modifier publicMinting() {
        require(mintingEnabled == true, "Public Minting is not available.");
        _;
    }
    modifier publicClaiming() {
        require(claimingEnabled == true, "Public Claiming is not available.");
        _;
    }

    // funds withdrawals
    function withdrawEther() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // internal workers
    function addReservedTokensMinted() internal {
        reservedTokensMinted++;
    }
    function getReservedMintId() internal view returns (uint) {
        return reservedTokensMinted;
    }
    function addGlyphTokensMinted() internal {
        glyphTokensMinted++;
    }
    function getGlyphMintId() internal view returns (uint) {
        return glyphTokensMinted + maxReservedTokens;
    }
    function addNormalTokensMinted() internal {
        normalTokensMinted++;
    }
    function getNormalMintId() internal view returns (uint) {
        return normalTokensMinted + maxReservedTokens + maxGlyphTokens;
    }
    function getPublicMintableTokens() internal view returns (uint) {
        return availableTokens - normalTokensMinted;
    }
    function hasGlyphBeenUsedForMinting(uint glyphId_) internal view returns (bool) {
        return glyphUsedForMint[glyphId_] == 1;
    }

    // contract administration
    function setMintingQuota(uint quotaAmount_) external onlyOwner {
        require (quotaAmount_ <= (maxTokens - maxReservedTokens - maxGlyphTokens), "Quota over limit!" );
        availableTokens = quotaAmount_;
    }
    function addMintingQuota(uint quotaAmount_) external onlyOwner {
        require (availableTokens + quotaAmount_ <= (maxTokens - maxReservedTokens - maxGlyphTokens), "Quota over limit!" );
        availableTokens = availableTokens + quotaAmount_;
    }
    function setMintingCost(uint mintingCost_) external onlyOwner {
        mintingCost = mintingCost_;
    }
    function setBaseTokenURI(string memory uri_) external onlyOwner {
        baseTokenURI = uri_;
    }
    function setPublicMinting(bool status_) external onlyOwner {
        mintingEnabled = status_;
    }
    function setPublicClaiming(bool status_) external onlyOwner {
        claimingEnabled = status_;
    }
    function setAutoglyphsAddress(address address_) external onlyOwner {
        autoglyphsAddress = address_;
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
    function getAvailableSeeds() public view returns (uint) {
        return availableTokens - normalTokensMinted;
    }
    function getRemainingGlyphMints() public view returns (uint) {
        return maxGlyphTokens - glyphTokensMinted;
    }

    // minting functions (owner only)
    function ownerMintReservedTokens() external onlyOwner {
        require(reservedTokensMinted + 1 <= maxReservedTokens, "Over Maximum Reserved Tokens!");
        uint _mintId = getReservedMintId();
        addReservedTokensMinted();
        _mint(msg.sender, _mintId);
        emit Mint(msg.sender, _mintId);
    }

    function ownerMintNormalTokens() external onlyOwner {
        require(normalTokensMinted + 1 <= availableTokens, "No available tokens remaining!");
        uint _mintId = getNormalMintId();
        addNormalTokensMinted();
        _mint(msg.sender, _mintId);
        emit Mint(msg.sender, _mintId);
    }

    function ownerMintWithGlyph() external onlyOwner {
        require(glyphTokensMinted + 1 <= maxGlyphTokens, "No Glyph tokens remaining!");
        uint _mintId = getGlyphMintId();
        addGlyphTokensMinted();
        _mint(msg.sender, _mintId);
        emit Mint(msg.sender, _mintId);
    }

    // minting functions (normal)
    function normalMint() payable external onlySender publicMinting {
        require(msg.value == mintingCost, "Wrong Cost!");
        require(normalTokensMinted + 1 <= availableTokens, "No available tokens remaining!");
        uint _mintId = getNormalMintId();
        addNormalTokensMinted();
        _mint(msg.sender, _mintId);
        emit Mint(msg.sender, _mintId);
    }

    function mintWithGlyph(uint glyphId_) external onlySender publicClaiming {
        require(msg.sender == IERC721(autoglyphsAddress).ownerOf(glyphId_), "You do not own this Autoglyph!");
        require(hasGlyphBeenUsedForMinting(glyphId_) == false, "Glyph already used for minting!");
        require(glyphTokensMinted + 1 <= maxGlyphTokens, "No Glyph tokens remaining!");
        uint _mintId = getGlyphMintId();
        glyphUsedForMint[glyphId_]++;
        addGlyphTokensMinted();
        _mint(msg.sender, _mintId);
        emit MintWithGlyph(msg.sender, _mintId, glyphId_);
    }
}