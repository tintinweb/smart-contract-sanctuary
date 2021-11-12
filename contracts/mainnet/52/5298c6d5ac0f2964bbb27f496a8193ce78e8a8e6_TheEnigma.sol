// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract TheEnigma is ERC721 {
    event Mint(address indexed from, uint256 indexed tokenId);

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyCollaborator() {
        bool isCollaborator = false;
        for (uint256 i; i < collaborators.length; i++) {
            if (collaborators[i].addr == msg.sender) {
                isCollaborator = true;

                break;
            }
        }

        require(
            owner() == _msgSender() || isCollaborator,
            "Ownable: caller is not the owner nor a collaborator"
        );

        _;
    }

    modifier claimStarted() {
        require(
            startClaimDate != 0 && startClaimDate <= block.timestamp,
            "You are too early"
        );

        _;
    }

    modifier presaleStarted() {
        require(
            startPresaleDate != 0 && startPresaleDate <= block.timestamp,
            "Presale not started yet"
        );

        _;
    }

    modifier onlyWhitelisted() {
        require(whitelistedAddresses[msg.sender] == true, "You are not whitelisted for presale");

        _;
    }

    struct Collaborators {
        address addr;
        uint256 cut;
    }

    uint256 private startClaimDate = 1636912800;
    uint256 private startPresaleDate = 1636750800;
    uint256 private mintPrice = 140000000000000000;
    uint256 private presaleMintPrice = 70000000000000000;

    uint256 private totalTokens = 8000;
    uint256 private totalMintedTokens = 0;

    uint256 private maxMinerPerTransactionDuringPresale = 3;
    uint256 private maxMinerPerTransaction = 6;

    uint256 private maxMinerPerWalletDuringPresale = 3;
    uint256 private maxMinerPerWallet = 9;

    uint128 private basisPoints = 10000;
    string private baseURI =
        "https://enigmaminer.s3.amazonaws.com/";
    
    uint256 public giveawayCount = 200;
    bool public giveawayReservationComplete = false;
    
    uint256 public presaleLimit = 6300;
    uint256 public presaleMintedTokens = 0;

    mapping(address => uint256) private claimedMinerPerWallet;

    uint16[] availableMiners;
    Collaborators[] private collaborators;

    mapping (address => bool) whitelistedAddresses;

    constructor() ERC721("TheEnigma", "ENG") {}

    // ONLY OWNER

    /**
     * Sets the collaborators of the project with their cuts
     */
    function addCollaborators(Collaborators[] memory _collaborators)
        external
        onlyOwner
    {
        require(collaborators.length == 0, "Collaborators were already set");

        uint128 totalCut;
        for (uint256 i; i < _collaborators.length; i++) {
            collaborators.push(_collaborators[i]);
            totalCut += uint128(_collaborators[i].cut);
        }

        require(totalCut == basisPoints, "Total cut does not add to 100%");
    }

    // ONLY COLLABORATORS

    /**
     * @dev Allows to withdraw the Ether in the contract and split it among the collaborators
     */
    function withdraw() external onlyCollaborator {
        uint256 totalBalance = address(this).balance;

        for (uint256 i; i < collaborators.length; i++) {
            payable(collaborators[i].addr).transfer(
                mulScale(totalBalance, collaborators[i].cut, basisPoints)
            );
        }
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyCollaborator {
        baseURI = _uri;
    }

    /**
     * @dev Sets the claim price for each miner
     */
    function setMintPrice(uint256 _mintPrice) external onlyCollaborator {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Sets the claim price for each miner
     */
    function setPresaleMintPrice(uint256 _presaleMintPrice) external onlyCollaborator {
        presaleMintPrice = _presaleMintPrice;
    }

    /**
     * @dev Populates the available miners
     */
    function addAvailableMiners(uint16 from, uint16 to)
        external
        onlyCollaborator
    {
        for (uint16 i = from; i <= to; i++) {
            availableMiners.push(i);
        }
    }

    /**
     * @dev Removes a chosen miner from the available list, only a utility function
     */
    function removeMinerFromAvailableMiners(uint16 tokenId)
        external
        onlyCollaborator
    {
        for (uint16 i; i <= availableMiners.length; i++) {
            if (availableMiners[i] != tokenId) {
                continue;
            }

            availableMiners[i] = availableMiners[availableMiners.length - 1];
            availableMiners.pop();

            break;
        }
    }

    /**
     * @dev Sets the date that users can start claiming miners
     */
    function setStartClaimDate(uint256 _startClaimDate)
        external
        onlyCollaborator
    {
        startClaimDate = _startClaimDate;
    }

    /**
     * @dev Sets the date that users can start claiming miners for presale
     */
    function setStartPresaleDate(uint256 _startPresaleDate)
        external
        onlyCollaborator
    {
        startPresaleDate = _startPresaleDate;
    }

    /**
     * @dev Sets the presale limit for presale
     */
    function setPresaleLimit(uint256 _presaleLimit)
        external
        onlyCollaborator
    {
        presaleLimit = _presaleLimit;
    }

    /**
     * @dev Checks if a miner is in the available list
     */
    function isMinerAvailable(uint16 tokenId)
        external
        view
        onlyCollaborator
        returns (bool)
    {
        for (uint16 i; i < availableMiners.length; i++) {
            if (availableMiners[i] == tokenId) {
                return true;
            }
        }

        return false;
    }


    /**
     * @dev Give random miners to the provided address
     */
    function reserveGiveawayMiners(address _address)
        external
        onlyCollaborator
    {
        require(availableMiners.length >= giveawayCount, "No miners left to be claimed");
        require(!giveawayReservationComplete, "Miners were already reserved for giveaways!");
        
        totalMintedTokens += giveawayCount;

        uint256[] memory tokenIds = new uint256[](giveawayCount);

        for (uint256 i; i < giveawayCount; i++) {
            tokenIds[i] = getMinerToBeClaimed();
        }

        _batchMint(_address, tokenIds);
        giveawayReservationComplete = true;
    }

    /**
    * @dev Whitelist addresses
     */
    function whitelistAddress (address[] memory users) external onlyCollaborator {
        for (uint i = 0; i < users.length; i++) {
            whitelistedAddresses[users[i]] = true;
        }
    }

    // END ONLY COLLABORATORS

    /**
     * @dev Claim a single Miner
     */
    function claimMiner() external payable callerIsUser claimStarted returns (uint256) {
        require(msg.value >= mintPrice, "Not enough Ether to claim a miner");

        require(availableMiners.length > 0, "Not enough miners left");

        require(availableMiners.length - giveawayCount > 0, "No miners left to be claimed");

        require(claimedMinerPerWallet[msg.sender] < maxMinerPerWallet, "You can only claim 9 miners per wallet");

        claimedMinerPerWallet[msg.sender]++;
        totalMintedTokens++;

        uint256 tokenId = getMinerToBeClaimed();

        _mint(msg.sender, tokenId);
        return tokenId;
    }

    /**
     * @dev Claim up to 6 miners at once
     */
    function claimMiners(uint256 quantity)
        external
        payable
        callerIsUser
        claimStarted
        returns (uint256[] memory)
    {
        require(
            msg.value >= mintPrice * quantity,
            "Not enough Ether to claim the Miners"
        );
        
        require(quantity <= maxMinerPerTransaction, "You can only claim 6 Miners per transaction");
        
        require(availableMiners.length >= quantity, "Not enough miners left");

        require(availableMiners.length - giveawayCount >= quantity, "No Miners left to be claimed");

        require(claimedMinerPerWallet[msg.sender] + quantity <= maxMinerPerWallet, "You can only claim 9 miners per wallet");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedMinerPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getMinerToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
        return tokenIds;
    }

    /**
     * @dev Claim up to 3 miners at once in presale
     */
    function presaleMintMiners(uint256 quantity)
        external
        payable
        callerIsUser
        presaleStarted
        onlyWhitelisted
        returns (uint256[] memory)
    {
        require(
            msg.value >= presaleMintPrice * quantity,
            "Not enough Ether to claim the Miners"
        );
        
        require(quantity <= maxMinerPerTransactionDuringPresale, "You can only claim 3 miners per transaction during presale");

        require(availableMiners.length >= quantity, "Not enough miners left");

        require(availableMiners.length - giveawayCount >= quantity, "No Miners left to be claimed");

        require(quantity + presaleMintedTokens <= presaleLimit, "No more miners left for presale");

        require(claimedMinerPerWallet[msg.sender] + quantity <= maxMinerPerWalletDuringPresale, "You can only claim 3 miners during presale");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedMinerPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;
        presaleMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getMinerToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
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

    /**
     * @dev Returns how many Miners are still available to be claimed
     */
    function getAvailableMiners() external view returns (uint256) {
        return availableMiners.length;
    }

    /**
     * @dev Returns the claim price
     */
    function getmintPrice() external view returns (uint256) {
        return mintPrice;
    }

    /**
     * @dev Returns the total supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return totalMintedTokens;
    }

    /**
     * @dev Returns the total minted tokens in presale
     */
    function totalPresaleMintCount() external view virtual returns (uint256) {
        return presaleMintedTokens;
    }

    // Private and Internal functions

    /**
     * @dev Returns a random available Miner to be claimed
     */
    function getMinerToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availableMiners.length);
        uint256 tokenId = uint256(availableMiners[random]);

        availableMiners[random] = availableMiners[availableMiners.length - 1];
        availableMiners.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableMiners.length,
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