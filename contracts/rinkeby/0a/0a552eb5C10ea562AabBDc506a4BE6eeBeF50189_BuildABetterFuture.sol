// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract BuildABetterFuture is ERC721 {
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier mintStarted() {
        require(
            startMintDate != 0 && startMintDate <= block.timestamp,
            "You are too early"
        );

        _;
    }

    modifier contractIsNotFrozen() {
        require(isFrozen == false, "This function can not be called anymore");

        _;
    }

    uint16 public totalTokens = 4676;
    uint16 public totalSupply = 0;
    uint256 public maxMintsPerWallet = 100;
    uint256 public mintPrice = 0.1 ether;
    uint256 private startMintDate = 1635672783; //1635672783
    string private baseURI =
        "ipfs://QmccmDqqeBcuYpmvQKmfkV9hx3emXTyAd4MH6vv1Ebiija/";
    string private secondProof =
        "ipfs://QmQhMirXVNgk6NJE69Ro7HAKWGwcC9J7K7BecbmvWWf916";
    string private blankTokenURI =
        "ipfs://QmXLHJ1Am75PLRUETcCnVPPPar29eUEyKDBYcQ8RaCMVXb/";
    bool private isFrozen = false;

    mapping(address => uint8) public mintedTokensPerWallet;
    mapping(uint16 => uint16) private tokenMatrix;

    constructor() ERC721("BuildABetterFuture", "BABF") {}

    // ONLY OWNER

    /**
     * @dev Allows to withdraw the Ether in the contract
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
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
     * @dev Give random tokens to the provided address
     */
    function devMintTokensToAddresses(address[] memory _addresses)
        external
        onlyOwner
    {
        require(
            getAvailableTokens() >= _addresses.length,
            "No tokens left to be minted"
        );

        uint16 tmpTotalMintedTokens = totalSupply;
        totalSupply += uint16(_addresses.length);

        for (uint256 i; i < _addresses.length; i++) {
            _mint(_addresses[i], _getTokenToBeMinted(tmpTotalMintedTokens));
            tmpTotalMintedTokens++;
        }
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

    /**
     * @dev Mint up to 100 tokens at once
     */
    function mintTokens(uint8 amount)
        external
        payable
        callerIsUser
        mintStarted
    {
        require(amount > 0, "At least one token should be minted");

        uint16 tokensLeft = getAvailableTokens();
        require(tokensLeft > 0, "No tokens left to be minted");

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

        require(
            mintedTokensPerWallet[msg.sender] + amount <= maxMintsPerWallet,
            "You cannot mint more tokens"
        );

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
        if (getAvailableTokens() > 0) {
            return blankTokenURI;
        }

        return baseURI;
    }
}