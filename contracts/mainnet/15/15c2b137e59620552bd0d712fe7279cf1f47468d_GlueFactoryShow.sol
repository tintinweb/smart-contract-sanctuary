// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract GlueFactoryShow is ERC721 {
    event Mint(address indexed from, uint256 indexed tokenId);

     modifier mintingStarted() {
        require(
            startMintDate != 0 && startMintDate <= block.timestamp,
            "You are too early"
        );
        _;
    }

    modifier callerNotAContract() {
        require(tx.origin == msg.sender, "The caller can only be a user and not a contract");
        _;
    }

    // 10k total NFTs
    uint256 private totalHorses = 10000;

    // Each transaction allows the user to mint only 10 NFTs. One user can't mint more than 150 NFTs.
    uint256 private maxHorsesPerWallet = 150;
    uint256 private maxHorsesPerTransaction = 10;

    // Setting Mint date to 4pm PST, 08/08/2021
    uint256 private startMintDate = 1628524800;

    // Price per NFT: 0.1 ETH
    uint256 private horsePrice = 100000000000000000;

    uint256 private totalMintedHorses = 0;

    uint256 public premintCount = 125;
    
    bool public premintingComplete = false;
    
    // IPFS base URI for NFT metadata for OpenSea
    string private baseURI = "https://ipfs.io/ipfs/Qmbd9N5yse7xAUiQAHrdezaJH6z2VAW5jc7FavLxDvK5kk/";

    // Ledger of NFTs minted and owned by each unique wallet address.
    mapping(address => uint256) private claimedHorsesPerWallet;

    uint16[] availableHorses;

    constructor() ERC721("Glue Factory Show", "GFS") {
        addAvailableHorses();
    }


    // ONLY OWNER

    /**
     * @dev Allows to withdraw the Ether in the contract to the address of the owner.
     */
    function withdraw() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        payable(msg.sender).transfer(totalBalance);
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
     * @dev Sets the mint price for each horse
     */
    function setHorsePrice(uint256 _horsePrice) external onlyOwner {
        horsePrice = _horsePrice;
    }

    /**
     * @dev Adds all horses to the available list.
     */
    function addAvailableHorses()
        internal
        onlyOwner
    {
        for (uint16 i = 0; i <= 9999; i++) {
            availableHorses.push(i);
        }
    }

    /**
     * @dev Handpick horses for promised giveaways.
     */
    function allocateSpecificHorsesForGiveaways(uint256[] memory tokenIds)
        internal
    {
        require(availableHorses.length == 0, "Available horses are already set");

        _batchMint(msg.sender, tokenIds);

        totalMintedHorses += tokenIds.length;
    }

    /**
     * @dev Prem
     */
    function premintHorses()
        external
        onlyOwner
    {
        require(
            !premintingComplete,
            "You can only premint the horses once"
            );
        require(
            availableHorses.length >= premintCount,
            "No horses left to be claimed"
        );
        totalMintedHorses += premintCount;

        for (uint256 i; i < premintCount; i++) {
            _mint(msg.sender, getHorseToBeClaimed());
        }
        premintingComplete = true;
    }

    // END ONLY OWNER FUNCTIONS

    /**
     * @dev Claim up to 10 horses at once
     */
    function mintHorses(uint256 amount)
        external
        payable
        callerNotAContract
        mintingStarted
    {
        require(
            msg.value >= horsePrice * amount,
            "Not enough Ether to claim the horses"
        );

        require(
            claimedHorsesPerWallet[msg.sender] + amount <= maxHorsesPerWallet,
            "You cannot claim more horses"
        );

        require(availableHorses.length >= amount, "No horses left to be claimed");

        uint256[] memory tokenIds = new uint256[](amount);

        claimedHorsesPerWallet[msg.sender] += amount;
        totalMintedHorses += amount;

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = getHorseToBeClaimed();
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

    /**
     * @dev Returns how many horses are still available to be claimed
     */
    function getAvailableHorses() external view returns (uint256) {
        return availableHorses.length;
    }

    /**
     * @dev Returns the claim price
     */
    function gethorsePrice() external view returns (uint256) {
        return horsePrice;
    }

    /**
     * @dev Returns the minting start date
     */
    function getMintingStartDate() external view returns (uint256) {
        return startMintDate;
    }

    /**
     * @dev Returns the total supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return totalMintedHorses;
    }

    // Private and Internal functions

    /**
     * @dev Returns a random available horse to be claimed
     */
    function getHorseToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availableHorses.length);
        uint256 tokenId = uint256(availableHorses[random]);

        availableHorses[random] = availableHorses[availableHorses.length - 1];
        availableHorses.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableHorses.length,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender
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

    function mulScale(
        uint256 x,
        uint256 y,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + (b * d) / scale;
    }
}