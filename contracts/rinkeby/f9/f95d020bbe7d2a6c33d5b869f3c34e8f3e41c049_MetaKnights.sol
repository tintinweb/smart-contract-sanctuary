// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract MetaKnights is ERC721 {
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

    modifier onlyPreminter() {
        bool isPreminter = false;
        if (preminters[msg.sender] > 0) {
            isPreminter = true;
        }

        require(
            isPreminter,
            "Ownable: caller is not a preminter"
        );

        _;
    }

    struct Collaborators {
        address addr;
        uint256 cut;
    }

    struct PremintersInput {
        address addr;
        uint256 reservedCount;
    }

    uint256 private startClaimDate = 1634572880;
    uint256 private startPresaleDate = 1634572880;
    uint256 private mintPrice = 60000000000000000;
    uint256 private totalTokens = 9999;
    uint256 private totalMintedTokens = 0;
    uint256 private maxMetaknightPerTransaction = 20;
    uint128 private basisPoints = 10000;
    string private baseURI =
        "https://metaknights.s3.us-west-1.amazonaws.com/";
    bool public premintingComplete = false;
    uint256 public giveawayCount = 50;

    mapping(address => uint256) private claimedMetaknightPerWallet;

    uint16[] availableMetaknights;
    Collaborators[] private collaborators;

    mapping(address => uint256) preminters;

    constructor() ERC721("Metaknights", "MKN") {}

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
     * @dev Sets the claim price for each metaknight
     */
    function setMintPrice(uint256 _mintPrice) external onlyCollaborator {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Populates the available metaknights
     */
    function addAvailableMetaknights(uint16 from, uint16 to)
        external
        onlyCollaborator
    {
        for (uint16 i = from; i <= to; i++) {
            availableMetaknights.push(i);
        }
    }

    /**
     * @dev Removes a chosen metaknight from the available list, only a utility function
     */
    function removeMetaknightFromAvailableMetaknights(uint16 tokenId)
        external
        onlyCollaborator
    {
        for (uint16 i; i <= availableMetaknights.length; i++) {
            if (availableMetaknights[i] != tokenId) {
                continue;
            }

            availableMetaknights[i] = availableMetaknights[availableMetaknights.length - 1];
            availableMetaknights.pop();

            break;
        }
    }

    /**
     * @dev Sets the date that users can start claiming metaknights
     */
    function setStartClaimDate(uint256 _startClaimDate)
        external
        onlyCollaborator
    {
        startClaimDate = _startClaimDate;
    }

    /**
     * @dev Sets the date that users can start claiming metaknights
     */
    function setStartPresaleDate(uint256 _startPresaleDate)
        external
        onlyCollaborator
    {
        startPresaleDate = _startPresaleDate;
    }

    /**
     * Sets the preminters of the project
     */
    function addPreminters(PremintersInput[] memory _preminters)
        external
        onlyCollaborator
    {

        for (uint256 i; i < _preminters.length; i++) {
            preminters[_preminters[i].addr] = _preminters[i].reservedCount;
        }
    }


    /**
     * @dev Checks if a metaknight is in the available list
     */
    function isMetaknightAvailable(uint16 tokenId)
        external
        view
        onlyCollaborator
        returns (bool)
    {
        for (uint16 i; i < availableMetaknights.length; i++) {
            if (availableMetaknights[i] == tokenId) {
                return true;
            }
        }

        return false;
    }


    /**
     * @dev Give random metaknights to the provided address
     */
    function reserveMetaknights(address _address)
        external
        onlyCollaborator
    {
        require(availableMetaknights.length >= giveawayCount, "No metaknights left to be claimed");
        require(!premintingComplete,"Metaknights were already reserved for giveaways!");
        totalMintedTokens += giveawayCount;

        uint256[] memory tokenIds = new uint256[](giveawayCount);

        for (uint256 i; i < giveawayCount; i++) {
            tokenIds[i] = getMetaknightToBeClaimed();
        }

        _batchMint(_address, tokenIds);
        premintingComplete = true;
    }

    // END ONLY COLLABORATORS

    /**
     * @dev Claim a single Metaknight
     */
    function claimMetaknight() external payable callerIsUser claimStarted {
        require(msg.value >= mintPrice, "Not enough Ether to claim a metaknight");

        require(availableMetaknights.length > 0, "No metaknights left to be claimed");

        claimedMetaknightPerWallet[msg.sender]++;
        totalMintedTokens++;

        _mint(msg.sender, getMetaknightToBeClaimed());
    }

    /**
     * @dev Claim up to 10 metaknights at once
     */
    function claimMetaknights(uint256 quantity)
        external
        payable
        callerIsUser
        claimStarted
    {
        require(
            msg.value >= mintPrice * quantity,
            "Not enough Ether to claim the Metaknights"
        );
        
        require(quantity <= maxMetaknightPerTransaction, "You can only claim 10 Metaknights per transactions");

        require(availableMetaknights.length >= quantity, "No Metaknights left to be claimed");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedMetaknightPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getMetaknightToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
    }

    /**
     * @dev Claim a single preminted metaknight
     */
    function premintMetaknights(uint256 quantity) external payable callerIsUser presaleStarted onlyPreminter {

        require(availableMetaknights.length > 0, "No metaknights left to be claimed");
        require(preminters[msg.sender] > 0, "You have no premint tokens reserved");

        uint256 reservedQuantity = preminters[msg.sender];

        require(quantity <= reservedQuantity, "You dont have enough metaknights reserved");

        require(
            msg.value >= mintPrice * quantity,
            "Not enough Ether to claim the Metaknights"
        );

        uint256[] memory tokenIds = new uint256[](quantity);

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getMetaknightToBeClaimed();
        }

        claimedMetaknightPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;
        preminters[msg.sender] = reservedQuantity - quantity;

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
     * @dev Returns how many Metaknights are still available to be claimed
     */
    function getAvailableMetaknights() external view returns (uint256) {
        return availableMetaknights.length;
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

    // Private and Internal functions

    /**
     * @dev Returns a random available Metaknight to be claimed
     */
    function getMetaknightToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availableMetaknights.length);
        uint256 tokenId = uint256(availableMetaknights[random]);

        availableMetaknights[random] = availableMetaknights[availableMetaknights.length - 1];
        availableMetaknights.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableMetaknights.length,
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