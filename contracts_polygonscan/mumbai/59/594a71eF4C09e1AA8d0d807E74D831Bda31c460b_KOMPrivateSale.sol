// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./KOMPrivateSaleGift.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract KOMPrivateSale is ERC721 {

    using SafeMath for uint256;
    event LogShow(address ref);

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier mintStarted() {
        require(
            startMintDate != 0 && startMintDate <= block.timestamp,
            "early"
        );
        _;
    }

    modifier contractIsNotFrozen() {
        require(isFrozen == false, "This function can not be called anymore");
        _;
    }

    uint16 public totalTokens = 10000;
    uint16 public totalSupply = 0;
    uint256 public maxMintsPerWallet = 50;
    uint256 public daiMintPrice = 20000000000000000000;
    uint8 public giftCount = 1;
    uint256 private startMintDate = 1638777600;
    string private baseURI =
        "https://ipfs.io/ipfs/QmYJSp9tCsDiWMcPCeVwSUX4GdoXp1NaYuK7MauGELRzc1?filename=kittyohmprivatesalenft.json";
    bool private isFrozen = false;
    bool private enableWhilteList = true;

    mapping(address => uint16) public mintedTokensPerWallet;
    mapping(uint16 => uint16) private tokenMatrix;
    mapping(address => mapping(address => uint8)) public mintedGiftTokenPerWallet;
    mapping(address=>bool) private whitelist;
    IERC20 public dai;
    KOMPrivateSaleGift public gift;

    constructor() ERC721("KOMPrivateSaleNFT", "KOMPSNFT") { }

    // ONLY OWNER

    function setGiftNFTContractAddress(KOMPrivateSaleGift _giftAddr) external onlyOwner {
        gift = _giftAddr;
    }
    
    function setDAIAddress(address _daiAddr) external onlyOwner {
        dai = IERC20(_daiAddr);
    }
    
    function setEnablewhitelist(bool _enableWhitelist) external onlyOwner {
        enableWhilteList = _enableWhitelist;
    }
    
    function setMintDAIPrice(uint256 _daiMintPrice) external onlyOwner {
        daiMintPrice = _daiMintPrice;
    }
 
    function addWhiteList(address account) external onlyOwner {
        whitelist[account] = true;
    }
    
    function removeWhiteList(address account) external onlyOwner {
        whitelist[account] = false;
    }

    function withdrawDAI(address _to, uint256 _amount) external onlyOwner {
        dai.transfer(_to, _amount);
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        baseURI = _uri;
    }
    
    function setGiftNFTAmount(uint8 _giftCount) external onlyOwner
    {
        require(_giftCount >0, 'gift count zero');
        giftCount = _giftCount;
    }

    /**
     * @dev Sets the date that users can start minting tokens
     */
    function setStartMintDate(uint256 _startMintDate) external onlyOwner {
        startMintDate = _startMintDate;
    }

    /**
     * @dev Set the total amount of tokens
     */
    function setTotalTokens(uint16 _totalTokens)
        external
        onlyOwner
        contractIsNotFrozen
    {
        totalTokens = _totalTokens;
    }

    /**
     * @dev Set amount of mints that a single wallet can do.
     */
    function setMaxMintsPerWallet(uint16 _maxMintsPerWallet)
        external
        onlyOwner
    {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    /**
     * @dev Sets the isFrozen variable to true
     */
    function freezeSmartContract() external onlyOwner {
        isFrozen = true;
    }

    // END ONLY OWNER
    
    function mintTokensByDAI(uint16 amount,uint256 _DaiAmount)
        external
        callerIsUser
        mintStarted
    {
        require(amount > 0, "one should be minted");
        require(amount < totalTokens, "Can't mint more than total tokens");

        uint16 tokensLeft = getAvailableTokens();
        require(tokensLeft > 0, "No tokens left to be minted");

        if(enableWhilteList){
            require(whitelist[msg.sender],"not in whitelist");
        }

        if (amount > tokensLeft) {
            amount = uint16(tokensLeft);
        }

        uint256 totalMintDAIPrice = daiMintPrice.mul(amount);
        require(
            _DaiAmount >= totalMintDAIPrice,
            "Not enough DAI to mint the tokens"
        );
        
        require(
            mintedTokensPerWallet[msg.sender] + amount <= maxMintsPerWallet,
            "You can not mint more tokens"
        );

        if (_DaiAmount >= totalMintDAIPrice) {
            dai.transferFrom(msg.sender, address(this), totalMintDAIPrice);
        }
        
        uint256[] memory tokenIds = new uint256[](amount);
        uint16 tmpTotalMintedTokens = totalSupply;
        mintedTokensPerWallet[msg.sender] += amount;
        totalSupply = totalSupply+amount;

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = _getTokenToBeMinted(tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }

        _batchMint(msg.sender, tokenIds);
    }
    
    function mintTokensFromInviteByDAI(uint16 amount, address _ref,uint256 _daiAmount)
        external
        callerIsUser
        mintStarted
    {
        require(amount > 0, "At least one token should be minted");
        require(amount < totalTokens, "Can't mint more than total tokens");
        require(_daiAmount > 0, " At least Have DAI");
        require(daiMintPrice > 0,"At least DAI price larger than 0");
        
        uint16 tokensLeft = getAvailableTokens();
        require(tokensLeft > 0, "No tokens left to be minted");
        require(!enableWhilteList,'can not work in enable whitelist');

        if (amount > tokensLeft) {
            amount = uint8(tokensLeft);
        }

        uint256 totalMintDAIPrice = daiMintPrice.mul(amount);
        require(
            _daiAmount >= totalMintDAIPrice,
            "Not enough DAI to mint the tokens"
        );

        if (_daiAmount >= totalMintDAIPrice) {
            dai.transferFrom(msg.sender, address(this), totalMintDAIPrice);
        }

        uint256[] memory tokenIds = new uint256[](amount);

        uint16 tmpTotalMintedTokens = totalSupply;
        mintedTokensPerWallet[msg.sender] += amount;
        totalSupply += amount;

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = _getTokenToBeMinted(tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }

        require(
            address(0) != _ref,
            "The inviter address can not be zero"
        );
        
        require(_ref !=address(msg.sender),
            "The inviter can't be yourself"
        );
        
        require(
            mintedTokensPerWallet[msg.sender] <= maxMintsPerWallet,
            "You can not mint more tokens"
        );

        
        if (mintedTokensPerWallet[_ref] >= maxMintsPerWallet) {
            if (mintedTokensPerWallet[msg.sender] >= 1){
                if(mintedGiftTokenPerWallet[msg.sender][_ref] == 0){
                    gift.mintTokens(giftCount,_ref);
                    mintedGiftTokenPerWallet[msg.sender][_ref] = giftCount;
                }
            }
        }
        
        _batchMint(msg.sender, tokenIds); 
        emit LogShow(_ref);
    }

    /**
     * @dev Returns the tokenId by index
     */
    function tokenByIndex(uint256 tokenId) external view returns (uint256) {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );

        return tokenId;
    }

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    function getAvailableTokens() public view returns (uint16) {
        return totalTokens - totalSupply;
    }
    
    function checkIfExistInWhiteList(address account) public view returns (bool) {
        return whitelist[account];
    }

    // Private and Internal functions

    /**
     * @dev Returns a random available token to be minted
     *
     * Code used as reference:
     * https://github.com/1001-digital/erc721-extensions/blob/main/contracts/RandomlyAssigned.sol
     */
    function _getTokenToBeMinted(uint16 _totalMintedTokens)
        private
        returns (uint16)
    {
        uint16 maxIndex = totalTokens - _totalMintedTokens;
        uint16 random = _getRandomNumber(maxIndex, _totalMintedTokens);

        uint16 tokenId = tokenMatrix[random];
        if (tokenMatrix[random] == 0) {
            tokenId = random;
        }

        tokenMatrix[maxIndex - 1] == 0
            ? tokenMatrix[random] = maxIndex - 1
            : tokenMatrix[random] = tokenMatrix[maxIndex - 1];

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint16 _upper, uint16 _totalMintedTokens)
        private
        view
        returns (uint16)
    {
        uint16 random = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _totalMintedTokens,
                        blockhash(block.number - 1),
                        block.coinbase,
                        block.difficulty,
                        msg.sender
                    )
                )
            )
        );

        return random % _upper;
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}