// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract Dominapes is ERC721 {
    event Mint(address indexed from, uint256 indexed tokenId);

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier saleStarted() {
        require(
            startMintDate != 0 && startMintDate <= block.timestamp,
            "You are too early"
        );

        _;
    }

    uint256 public startMintDate = 1628636400;
    uint256 private salePrice = 15000000000000000;
    uint256 private totalTokens = 8000;
    uint256 private totalMintedTokens = 0;
    uint256 private maxSlicesPerWallet = 200;
    uint256 private maxSlicesPerTransaction = 10;
    string private baseURI =
        "https://dominapes.s3.us-west-1.amazonaws.com/";
    bool public premintingComplete = false;
    uint256 public giveawayCount = 50;

    mapping(address => uint256) private claimedSlicesPerWallet;

    uint16[] availableSlices;

    constructor() ERC721("Dominapes", "DPE") {
        addAvailableSlices();
        premintSlices();
    }


    // ONLY OWNER

    /**
     * @dev Allows to withdraw the Ether in the contract
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
     * @dev Sets the claim price for each slice
     */
    function setsalePrice(uint256 _salePrice) external onlyOwner {
        salePrice = _salePrice;
    }

    /**
     * @dev Populates the available slices
     */
    function addAvailableSlices()
        internal
        onlyOwner
    {
        for (uint16 i = 0; i <= 7999; i++) {
            availableSlices.push(i);
        }
    }

    /**
     * @dev Removes a chosen slice from the available list
     */
    function removeSlicesFromAvailableSlices(uint16 tokenId)
        external
        onlyOwner
    {
        for (uint16 i; i <= availableSlices.length; i++) {
            if (availableSlices[i] != tokenId) {
                continue;
            }

            availableSlices[i] = availableSlices[availableSlices.length - 1];
            availableSlices.pop();

            break;
        }
    }

    /**
     * @dev Allow devs to hand pick some slices before the available slices list is created
     */
    function allocateTokens(uint256[] memory tokenIds)
        external
        onlyOwner
    {
        require(availableSlices.length == 0, "Available slices are already set");

        _batchMint(msg.sender, tokenIds);

        totalMintedTokens += tokenIds.length;
    }

    /**
     * @dev Sets the date that users can start claiming slices
     */
    function setStartSaleDate(uint256 _startSaleDate)
        external
        onlyOwner
    {
        startMintDate = _startSaleDate;
    }

    /**
     * @dev Sets the date that users can start minting slices
     */
    function setStartMintDate(uint256 _startMintDate)
        external
        onlyOwner
    {
        startMintDate = _startMintDate;
    }

    /**
     * @dev Checks if an slice is in the available list
     */
    function isSliceAvailable(uint16 tokenId)
        external
        view
        onlyOwner
        returns (bool)
    {
        for (uint16 i; i < availableSlices.length; i++) {
            if (availableSlices[i] == tokenId) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Give random slices to the provided addresses
     */
    function ownerMintSlices(address[] memory addresses)
        external
        onlyOwner
    {
        require(
            availableSlices.length >= addresses.length,
            "No slices left to be claimed"
        );
        totalMintedTokens += addresses.length;

        for (uint256 i; i < addresses.length; i++) {
            _mint(addresses[i], getSliceToBeClaimed());
        }
    }

    /**
     * @dev Give random slices to the provided address
     */
    function premintSlices()
        internal
        onlyOwner
    {
        require(availableSlices.length >= giveawayCount, "No slices left to be claimed");
        require(
            !premintingComplete,
            "You can only premint the horses once"
            );
        totalMintedTokens += giveawayCount;

        uint256[] memory tokenIds = new uint256[](giveawayCount);

        for (uint256 i; i < giveawayCount; i++) {
            tokenIds[i] = getSliceToBeClaimed();
        }
        _batchMint(msg.sender, tokenIds);
        premintingComplete = true;
    }

    // END ONLY OWNER

    /**
     * @dev Claim a single slice
     */
    function mintSlice() external payable callerIsUser saleStarted {
        require(msg.value >= salePrice, "Not enough Ether to claim an slice");

        require(
            claimedSlicesPerWallet[msg.sender] < maxSlicesPerWallet,
            "You cannot claim more slices"
        );

        require(availableSlices.length > 0, "No slices left to be claimed");

        claimedSlicesPerWallet[msg.sender]++;
        totalMintedTokens++;

        _mint(msg.sender, getSliceToBeClaimed());
    }

    /**
     * @dev Claim up to 10 slices at once
     */
    function mintSlices(uint256 amount)
        external
        payable
        callerIsUser
        saleStarted
    {
        require(
            msg.value >= salePrice * amount,
            "Not enough Ether to claim the slices"
        );

        require(
            claimedSlicesPerWallet[msg.sender] + amount <= maxSlicesPerWallet,
            "You cannot claim more slices"
        );
        require(amount <= maxSlicesPerTransaction, "You can only claim 10 slices in 1 transaction");

        require(availableSlices.length >= amount, "No slices left to be claimed");

        uint256[] memory tokenIds = new uint256[](amount);

        claimedSlicesPerWallet[msg.sender] += amount;
        totalMintedTokens += amount;

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = getSliceToBeClaimed();
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
     * @dev Returns how many slices are still available to be claimed
     */
    function getAvailableSlices() external view returns (uint256) {
        return availableSlices.length;
    }

    /**
     * @dev Returns the claim price
     */
    function getSalePrice() external view returns (uint256) {
        return salePrice;
    }

    /**
     * @dev Returns the total supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return totalMintedTokens;
    }

    // Private and Internal functions

    /**
     * @dev Returns a random available slice to be claimed
     */
    function getSliceToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availableSlices.length);
        uint256 tokenId = uint256(availableSlices[random]);

        availableSlices[random] = availableSlices[availableSlices.length - 1];
        availableSlices.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableSlices.length,
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