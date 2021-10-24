// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract ThePhotonProject is ERC721 {
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

    struct Collaborators {
        address addr;
        uint256 cut;
    }

    uint256 private startClaimDate = 1635094800;
    uint256 private startPresaleDate = 1635080400;
    uint256 private mintPrice = 60000000000000000;
    uint256 private totalTokens = 9998;
    uint256 private totalMintedTokens = 0;
    uint256 private maxPhotonPerTransaction = 20;
    uint128 private basisPoints = 10000;
    string private baseURI =
        "https://photonproject.s3.us-west-1.amazonaws.com/";
    uint256 public giveawayCount = 600;
    uint256 public giveawayAlreadyReserved = 0;
    uint256 public presaleLimit = 5000;
    uint256 public presaleMintedTokens = 0;

    mapping(address => uint256) private claimedPhotonPerWallet;

    uint16[] availablePhotons;
    Collaborators[] private collaborators;

    constructor() ERC721("ThePhotonProject", "PHTN") {}

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
     * @dev Sets the claim price for each photon
     */
    function setMintPrice(uint256 _mintPrice) external onlyCollaborator {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Populates the available photons
     */
    function addAvailablePhotons(uint16 from, uint16 to)
        external
        onlyCollaborator
    {
        for (uint16 i = from; i <= to; i++) {
            availablePhotons.push(i);
        }
    }

    /**
     * @dev Removes a chosen photon from the available list, only a utility function
     */
    function removePhotonFromAvailablePhotons(uint16 tokenId)
        external
        onlyCollaborator
    {
        for (uint16 i; i <= availablePhotons.length; i++) {
            if (availablePhotons[i] != tokenId) {
                continue;
            }

            availablePhotons[i] = availablePhotons[availablePhotons.length - 1];
            availablePhotons.pop();

            break;
        }
    }

    /**
     * @dev Sets the date that users can start claiming photons
     */
    function setStartClaimDate(uint256 _startClaimDate)
        external
        onlyCollaborator
    {
        startClaimDate = _startClaimDate;
    }

    /**
     * @dev Sets the date that users can start claiming photons for presale
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
     * @dev Checks if a photon is in the available list
     */
    function isPhotonAvailable(uint16 tokenId)
        external
        view
        onlyCollaborator
        returns (bool)
    {
        for (uint16 i; i < availablePhotons.length; i++) {
            if (availablePhotons[i] == tokenId) {
                return true;
            }
        }

        return false;
    }


    /**
     * @dev Give random photons to the provided address
     */
    function reservePhotons(address _address, uint256 quantity)
        external
        onlyCollaborator
    {
        require(quantity <= (giveawayCount - giveawayAlreadyReserved), "Quantity is greater than giveaway count");
        require(availablePhotons.length >= quantity, "No photons left to be claimed");
        totalMintedTokens += quantity;
        giveawayAlreadyReserved += quantity;

        uint256[] memory tokenIds = new uint256[](quantity);

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getPhotonToBeClaimed();
        }

        _batchMint(_address, tokenIds);
    }

    // END ONLY COLLABORATORS

    /**
     * @dev Claim a single Photon
     */
    function claimPhoton() external payable callerIsUser claimStarted returns (uint256) {
        require(msg.value >= mintPrice, "Not enough Ether to claim a photon");

        require(availablePhotons.length > 0, "Not enough photons left");

        require(availablePhotons.length - (giveawayCount - giveawayAlreadyReserved) > 0, "No photons left to be claimed");

        claimedPhotonPerWallet[msg.sender]++;
        totalMintedTokens++;

        uint256 tokenId = getPhotonToBeClaimed();

        _mint(msg.sender, tokenId);
        return tokenId;
    }

    /**
     * @dev Claim up to 20 photons at once
     */
    function claimPhotons(uint256 quantity)
        external
        payable
        callerIsUser
        claimStarted
        returns (uint256[] memory)
    {
        require(
            msg.value >= mintPrice * quantity,
            "Not enough Ether to claim the Photons"
        );
        
        require(quantity <= maxPhotonPerTransaction, "You can only claim 20 Photons per transaction");
        
        require(availablePhotons.length >= quantity, "Not enough photons left");

        require(availablePhotons.length - (giveawayCount - giveawayAlreadyReserved) >= quantity, "No Photons left to be claimed");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedPhotonPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getPhotonToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
        return tokenIds;
    }

    /**
     * @dev Claim up to 20 photons at once in presale
     */
    function presaleMintPhotons(uint256 quantity)
        external
        payable
        callerIsUser
        presaleStarted
        returns (uint256[] memory)
    {
        require(
            msg.value >= mintPrice * quantity,
            "Not enough Ether to claim the Photons"
        );
        
        require(quantity <= maxPhotonPerTransaction, "You can only claim 20 Photons per transactions");

        require(availablePhotons.length >= quantity, "Not enough photons left");

        require(availablePhotons.length - (giveawayCount - giveawayAlreadyReserved) >= quantity, "No Photons left to be claimed");

        require(quantity + presaleMintedTokens <= presaleLimit, "No more photons left for presale");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedPhotonPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;
        presaleMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getPhotonToBeClaimed();
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
     * @dev Returns how many Photons are still available to be claimed
     */
    function getAvailablePhotons() external view returns (uint256) {
        return availablePhotons.length;
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
     * @dev Returns a random available Photon to be claimed
     */
    function getPhotonToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availablePhotons.length);
        uint256 tokenId = uint256(availablePhotons[random]);

        availablePhotons[random] = availablePhotons[availablePhotons.length - 1];
        availablePhotons.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availablePhotons.length,
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