// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract MetalootProject is ERC721 {
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

    struct Collaborators {
        address addr;
        uint256 cut;
    }

    uint256 private startClaimDate = 1634572880;
    uint256 private mintPrice = 10000000000000000;
    uint256 private totalTokens = 8000;
    uint256 private totalMintedTokens = 0;
    uint256 private maxMetalootPerTransaction = 20;
    uint128 private basisPoints = 10000;
    string private baseURI =
        "https://metaloot.s3.us-west-1.amazonaws.com/";
    bool public premintingComplete = false;
    uint256 public giveawayCount = 50;

    mapping(address => uint256) private claimedMetalootPerWallet;

    uint16[] availableMetaloots;
    Collaborators[] private collaborators;

    constructor() ERC721("MetalootProject", "MTL") {}

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
     * @dev Sets the claim price for each metaloot
     */
    function setMintPrice(uint256 _mintPrice) external onlyCollaborator {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Populates the available metaloots
     */
    function addAvailableMetaloots(uint16 from, uint16 to)
        external
        onlyCollaborator
    {
        for (uint16 i = from; i <= to; i++) {
            availableMetaloots.push(i);
        }
    }

    /**
     * @dev Removes a chosen metaloot from the available list
     */
    function removeMetalootFromAvailableMetaloots(uint16 tokenId)
        external
        onlyCollaborator
    {
        for (uint16 i; i <= availableMetaloots.length; i++) {
            if (availableMetaloots[i] != tokenId) {
                continue;
            }

            availableMetaloots[i] = availableMetaloots[availableMetaloots.length - 1];
            availableMetaloots.pop();

            break;
        }
    }

    /**
    * @dev Reserve particular customized tokens for giveways
     */
    function airdropTokens(address[] memory owners, uint16[] memory tokenIds)
        external
        onlyCollaborator
    {
        for(uint16 i = 0; i < tokenIds.length; i++){
            _mint(owners[i], tokenIds[i]);

            for (uint16 j; j <= availableMetaloots.length; j++) {
                if (availableMetaloots[j] != tokenIds[i]) {
                    continue;
                }

                availableMetaloots[j] = availableMetaloots[availableMetaloots.length - 1];
                availableMetaloots.pop();

                break;
            }
        }

        totalMintedTokens += tokenIds.length;
    }

    /**
     * @dev Sets the date that users can start claiming metaloots
     */
    function setStartClaimDate(uint256 _startClaimDate)
        external
        onlyCollaborator
    {
        startClaimDate = _startClaimDate;
    }


    /**
     * @dev Checks if a metaloot is in the available list
     */
    function isMetalootAvailable(uint16 tokenId)
        external
        view
        onlyCollaborator
        returns (bool)
    {
        for (uint16 i; i < availableMetaloots.length; i++) {
            if (availableMetaloots[i] == tokenId) {
                return true;
            }
        }

        return false;
    }


    /**
     * @dev Give random metaloots to the provided address
     */
    function reserveMetaloots(address _address)
        external
        onlyCollaborator
    {
        require(availableMetaloots.length >= giveawayCount, "No metaloots left to be claimed");
        require(!premintingComplete,"Metaloots were already reserved for giveaways!");
        totalMintedTokens += giveawayCount;

        uint256[] memory tokenIds = new uint256[](giveawayCount);

        for (uint256 i; i < giveawayCount; i++) {
            tokenIds[i] = getMetalootToBeClaimed();
        }

        _batchMint(_address, tokenIds);
        premintingComplete = true;
    }

    // END ONLY COLLABORATORS

    /**
     * @dev Claim a single Metaloot
     */
    function claimMetaloot() external payable callerIsUser claimStarted {
        require(msg.value >= mintPrice, "Not enough Ether to claim a metaloot");

        require(availableMetaloots.length > 0, "No metaloots left to be claimed");

        claimedMetalootPerWallet[msg.sender]++;
        totalMintedTokens++;

        _mint(msg.sender, getMetalootToBeClaimed());
    }

    /**
     * @dev Claim up to 10 metaloots at once
     */
    function claimMetaloots(uint256 quantity)
        external
        payable
        callerIsUser
        claimStarted
    {
        require(
            msg.value >= mintPrice * quantity,
            "Not enough Ether to claim the Metaloots"
        );
        
        require(quantity <= maxMetalootPerTransaction, "You can only claim 10 Metaloots per transactions");

        require(availableMetaloots.length >= quantity, "No Metaloots left to be claimed");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedMetalootPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getMetalootToBeClaimed();
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
     * @dev Returns how many Metaloots are still available to be claimed
     */
    function getAvailableMetaloots() external view returns (uint256) {
        return availableMetaloots.length;
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
     * @dev Returns a random available Metaloot to be claimed
     */
    function getMetalootToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availableMetaloots.length);
        uint256 tokenId = uint256(availableMetaloots[random]);

        availableMetaloots[random] = availableMetaloots[availableMetaloots.length - 1];
        availableMetaloots.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableMetaloots.length,
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