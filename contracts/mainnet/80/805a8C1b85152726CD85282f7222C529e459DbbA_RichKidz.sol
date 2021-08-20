// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract RichKidz is ERC721 {
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
    uint256 private mintPrice = 30000000000000000;
    uint256 private totalTokens = 10000;
    uint256 private totalMintedTokens = 0;
    uint256 private maxKidzPerWallet = 200;
    uint256 private maxKidzPerTransaction = 10;
    uint128 private basisPoints = 10000;
    string private baseURI =
        "https://richkidztest.s3.us-west-1.amazonaws.com/";
    bool public premintingComplete = false;
    uint256 public giveawayCount = 269;

    mapping(address => uint256) private claimedKidzPerWallet;

    uint16[] availableKidz;
    Collaborators[] private collaborators;

    constructor() ERC721("RichKidz", "RK") {}

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
     * @dev Sets the claim price for each kid
     */
    function setMintPrice(uint256 _mintPrice) external onlyCollaborator {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Populates the available kidz
     */
    function addAvailableKidz(uint16 from, uint16 to)
        external
        onlyCollaborator
    {
        for (uint16 i = from; i <= to; i++) {
            availableKidz.push(i);
        }
    }

    /**
     * @dev Removes a chosen kid from the available list
     */
    function removeKidzFromAvailableKidz(uint16 tokenId)
        external
        onlyCollaborator
    {
        for (uint16 i; i <= availableKidz.length; i++) {
            if (availableKidz[i] != tokenId) {
                continue;
            }

            availableKidz[i] = availableKidz[availableKidz.length - 1];
            availableKidz.pop();

            break;
        }
    }

    /**
     * @dev Allow devs to hand pick some kidz before the available kidz list is created
     */
    function allocateTokens(uint256[] memory tokenIds)
        external
        onlyCollaborator
    {
        require(availableKidz.length == 0, "Available kidz are already set");

        _batchMint(msg.sender, tokenIds);

        totalMintedTokens += tokenIds.length;
    }

    /**
     * @dev Sets the date that users can start claiming kidz
     */
    function setStartClaimDate(uint256 _startClaimDate)
        external
        onlyCollaborator
    {
        startClaimDate = _startClaimDate;
    }


    /**
     * @dev Checks if an kid is in the available list
     */
    function isKidAvailable(uint16 tokenId)
        external
        view
        onlyCollaborator
        returns (bool)
    {
        for (uint16 i; i < availableKidz.length; i++) {
            if (availableKidz[i] == tokenId) {
                return true;
            }
        }

        return false;
    }


    /**
     * @dev Give random kidz to the provided address
     */
    function reserveKidz(address _address)
        external
        onlyCollaborator
    {
        require(availableKidz.length >= giveawayCount, "No kidz left to be claimed");
        require(!premintingComplete,"Kidz were already reserved for giveaways!");
        totalMintedTokens += giveawayCount;

        uint256[] memory tokenIds = new uint256[](giveawayCount);

        for (uint256 i; i < giveawayCount; i++) {
            tokenIds[i] = getKidToBeClaimed();
        }

        _batchMint(_address, tokenIds);
        premintingComplete = true;
    }

    // END ONLY COLLABORATORS

    /**
     * @dev Claim a single kid
     */
    function claimKid() external payable callerIsUser claimStarted {
        require(msg.value >= mintPrice, "Not enough Ether to claim an kid");

        require(
            claimedKidzPerWallet[msg.sender] < maxKidzPerWallet,
            "You cannot claim more kidz"
        );

        require(availableKidz.length > 0, "No kidz left to be claimed");

        claimedKidzPerWallet[msg.sender]++;
        totalMintedTokens++;

        _mint(msg.sender, getKidToBeClaimed());
    }

    /**
     * @dev Claim up to 10 kidz at once
     */
    function claimKidz(uint256 amount)
        external
        payable
        callerIsUser
        claimStarted
    {
        require(
            msg.value >= mintPrice * amount,
            "Not enough Ether to claim the kidz"
        );
        
        require(amount <= maxKidzPerTransaction, "You can only claim 10 Kidz per transactions");

        require(
            claimedKidzPerWallet[msg.sender] + amount <= maxKidzPerWallet,
            "You cannot claim more kidz"
        );

        require(availableKidz.length >= amount, "No kidz left to be claimed");

        uint256[] memory tokenIds = new uint256[](amount);

        claimedKidzPerWallet[msg.sender] += amount;
        totalMintedTokens += amount;

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = getKidToBeClaimed();
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
     * @dev Returns how many kidz are still available to be claimed
     */
    function getAvailableKidz() external view returns (uint256) {
        return availableKidz.length;
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
     * @dev Returns a random available kid to be claimed
     */
    function getKidToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availableKidz.length);
        uint256 tokenId = uint256(availableKidz[random]);

        availableKidz[random] = availableKidz[availableKidz.length - 1];
        availableKidz.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableKidz.length,
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