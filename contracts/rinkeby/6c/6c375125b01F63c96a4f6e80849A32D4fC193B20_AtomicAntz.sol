// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract AtomicAntz is ERC721 {
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

    uint256 private startClaimDate = 1629475200;
    uint256 private mintPrice = 80000000000000000;
    uint256 private totalTokens = 11000;
    uint256 private totalMintedTokens = 0;
    uint256 private maxAntzPerWallet = 200;
    uint256 private maxAntzPerTransaction = 10;
    uint128 private basisPoints = 10000;
    string private baseURI =
        "https://atomicantz.s3.us-west-1.amazonaws.com/";
    bool public premintingComplete = false;
    uint256 public giveawayCount = 715;

    mapping(address => uint256) private claimedAntzPerWallet;

    uint16[] availableAntz;
    Collaborators[] private collaborators;

    constructor() ERC721("AtomicAntz", "AAZ") {}

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
     * @dev Sets the claim price for each ant
     */
    function setMintPrice(uint256 _mintPrice) external onlyCollaborator {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Populates the available antz
     */
    function addAvailableAntz(uint16 from, uint16 to)
        external
        onlyCollaborator
    {
        for (uint16 i = from; i <= to; i++) {
            availableAntz.push(i);
        }
    }

    /**
     * @dev Removes a chosen ant from the available list
     */
    function removeAntzFromAvailableAntz(uint16 tokenId)
        external
        onlyCollaborator
    {
        for (uint16 i; i <= availableAntz.length; i++) {
            if (availableAntz[i] != tokenId) {
                continue;
            }

            availableAntz[i] = availableAntz[availableAntz.length - 1];
            availableAntz.pop();

            break;
        }
    }

    /**
     * @dev Allow devs to hand pick some antz before the available antz list is created
     */
    function allocateTokens(uint256[] memory tokenIds)
        external
        onlyCollaborator
    {
        require(availableAntz.length == 0, "Available antz are already set");

        _batchMint(msg.sender, tokenIds);

        totalMintedTokens += tokenIds.length;
    }

    /**
     * @dev Sets the date that users can start claiming antz
     */
    function setStartClaimDate(uint256 _startClaimDate)
        external
        onlyCollaborator
    {
        startClaimDate = _startClaimDate;
    }


    /**
     * @dev Checks if an ant is in the available list
     */
    function isAntAvailable(uint16 tokenId)
        external
        view
        onlyCollaborator
        returns (bool)
    {
        for (uint16 i; i < availableAntz.length; i++) {
            if (availableAntz[i] == tokenId) {
                return true;
            }
        }

        return false;
    }


    /**
     * @dev Give random antz to the provided address
     */
    function reserveAntz(address _address)
        external
        onlyCollaborator
    {
        require(availableAntz.length >= giveawayCount, "No antz left to be claimed");
        require(!premintingComplete,"Antz were already reserved for giveaways!");
        totalMintedTokens += giveawayCount;

        uint256[] memory tokenIds = new uint256[](giveawayCount);

        for (uint256 i; i < giveawayCount; i++) {
            tokenIds[i] = getAntToBeClaimed();
        }

        _batchMint(_address, tokenIds);
        premintingComplete = true;
    }

    // END ONLY COLLABORATORS

    /**
     * @dev Claim a single ant
     */
    function claimAnt() external payable callerIsUser claimStarted {
        require(msg.value >= mintPrice, "Not enough Ether to claim an ant");

        require(
            claimedAntzPerWallet[msg.sender] < maxAntzPerWallet,
            "You cannot claim more antz"
        );

        require(availableAntz.length > 0, "No antz left to be claimed");

        claimedAntzPerWallet[msg.sender]++;
        totalMintedTokens++;

        _mint(msg.sender, getAntToBeClaimed());
    }

    /**
     * @dev Claim up to 10 antz at once
     */
    function claimAntz(uint256 amount)
        external
        payable
        callerIsUser
        claimStarted
    {
        require(
            msg.value >= mintPrice * amount,
            "Not enough Ether to claim the antz"
        );
        
        require(amount <= maxAntzPerTransaction, "You can only claim 10 Antz per transactions");

        require(
            claimedAntzPerWallet[msg.sender] + amount <= maxAntzPerWallet,
            "You cannot claim more antz"
        );

        require(availableAntz.length >= amount, "No antz left to be claimed");

        uint256[] memory tokenIds = new uint256[](amount);

        claimedAntzPerWallet[msg.sender] += amount;
        totalMintedTokens += amount;

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = getAntToBeClaimed();
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
     * @dev Returns how many antz are still available to be claimed
     */
    function getAvailableAntz() external view returns (uint256) {
        return availableAntz.length;
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
     * @dev Returns a random available ant to be claimed
     */
    function getAntToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availableAntz.length);
        uint256 tokenId = uint256(availableAntz[random]);

        availableAntz[random] = availableAntz[availableAntz.length - 1];
        availableAntz.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableAntz.length,
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