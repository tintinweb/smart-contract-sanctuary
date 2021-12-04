// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract KOMPrivateSaleGift is ERC721 {
    
    event GiftNFTSend(address ref);
    event LogShow(uint256[] tokenids);

    modifier onlyCreator() {
        require(msg.sender == invokeContractAddress,"This function can only be called by special contract");
        _;
    } 
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier contractIsNotFrozen() {
        require(isFrozen == false, "This function can not be called anymore");
        _;
    }

    uint16 public totalTokens = 10000;
    uint16 public totalSupply = 0;
    address public invokeContractAddress = address(0);
    string private baseURI =
        "https://ipfs.io/ipfs/QmNqiDpVEayfex4aJUU1vzKd5grBEYvRMxYU7zQPgijqML?filename=kittyohmprivategiftnft.json";
    bool private isFrozen = false;

    mapping(address => uint8) public mintedTokensPerWallet;
    mapping(uint16 => uint16) private tokenMatrix;

    constructor() ERC721("KOMPrivateSaleGift", "KOMPSGNFT") { }

    // ONLY OWNER

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
     * @dev Sets the isFrozen variable to true
     */
    function freezeSmartContract() external onlyOwner {
        isFrozen = true;
    }
    
    function setInvokeContractAddress(address creator) external onlyOwner {
        invokeContractAddress = creator;
    }

    // END ONLY OWNER

    /**
     * @dev mint token
     */
    function mintTokens(uint8 amount,address _ref) onlyCreator public returns (uint256[] memory) {
        require(amount > 0, "At least one token should be minted");

        uint16 tokensLeft = getAvailableTokens();
        require(tokensLeft > 0, "No tokens left to be minted");

        if (amount > tokensLeft) {
            amount = uint8(tokensLeft);
        }

        uint256[] memory tokenIds = new uint256[](amount);

        uint16 tmpTotalMintedTokens = totalSupply;
        mintedTokensPerWallet[msg.sender] += amount;
        totalSupply += amount;

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = _getTokenToBeMinted(tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }

        _batchMint(address(_ref),tokenIds);
        require(tokenIds.length>0, "The gift token id can't be empty");
        emit LogShow(tokenIds);
        return tokenIds;
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
        return baseURI;
    }
}