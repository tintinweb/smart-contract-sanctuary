// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract HatchDraco is ERC721 {
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

    modifier premintStarted() {
        require(
            startPremintDate != 0 && startPremintDate <= block.timestamp,
            "Premint not started yet"
        );
        _;
    }

    modifier onlyPreminter() {
        bool isPreminter = false;
        for (uint256 i; i < preminters.length; i++) {
            if (preminters[i] == msg.sender) {
                isPreminter = true;
                break;
            }
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

    uint256 private startClaimDate = 1629806733;
    uint256 private startPremintDate = 1629475200;
    //uint256 private mintPrice = 30000000000000000;
    
    uint256 private mintPriceFirstBracket = 15000000000000000;
    uint256 private mintPriceSecondBracket = 25000000000000000;
    uint256 private mintPriceThirdBracket = 35000000000000000;
    
    uint256 private totalTokens = 8000;
    uint256 private totalMintedTokens = 0;
    uint256 private maxDracoPerWallet = 200;
    uint256 private maxDracoPerTransaction = 10;
    uint128 private basisPoints = 10000;
    string private baseURI =
        "https://richkidztest.s3.us-west-1.amazonaws.com/";
    bool public premintingComplete = false;
    
    uint256 public giveawayCount = 100;
    
    uint256 public premintingCount = 10;
    uint256 private totalPremintedTokens = 0;

    mapping(address => uint256) private claimedDracosPerWallet;

    uint16[] availableDracos;
    Collaborators[] private collaborators;
    address[] preminters;

    constructor() ERC721("HatchDraco", "HDC") {}

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
     * Sets the preminters of the project
     */
    function addPreminters(address[] memory _preminters)
        external
        onlyCollaborator
    {

        for (uint256 i; i < _preminters.length; i++) {
            preminters.push(_preminters[i]);
        }
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyCollaborator {
        baseURI = _uri;
    }

    /**
     * @dev Sets the claim price for each draco
     */
    // function setMintPrice(uint256 _mintPrice) external onlyCollaborator {
    //     mintPrice = _mintPrice;
    // }

    /**
     * @dev Populates the available dracos
     */
    function addAvailableDracos(uint16 from, uint16 to)
        external
        onlyCollaborator
    {
        for (uint16 i = from; i <= to; i++) {
            availableDracos.push(i);
        }
    }

    /**
     * @dev Removes a chosen draco from the available list
     */
    function removeDracosFromAvailableDracos(uint16 tokenId)
        external
        onlyCollaborator
    {
        for (uint16 i; i <= availableDracos.length; i++) {
            if (availableDracos[i] != tokenId) {
                continue;
            }

            availableDracos[i] = availableDracos[availableDracos.length - 1];
            availableDracos.pop();

            break;
        }
    }

    /**
     * @dev Allow devs to hand pick some dracos before the available dracos list is created
     */
    function allocateTokens(uint256[] memory tokenIds)
        external
        onlyCollaborator
    {
        require(availableDracos.length == 0, "Available dracos are already set");

        _batchMint(msg.sender, tokenIds);

        totalMintedTokens += tokenIds.length;
    }

    /**
     * @dev Sets the date that users can start claiming dracos
     */
    function setStartClaimDate(uint256 _startClaimDate)
        external
        onlyCollaborator
    {
        startClaimDate = _startClaimDate;
    }


    /**
     * @dev Checks if an draco is in the available list
     */
    function isDracoAvailable(uint16 tokenId)
        external
        view
        onlyCollaborator
        returns (bool)
    {
        for (uint16 i; i < availableDracos.length; i++) {
            if (availableDracos[i] == tokenId) {
                return true;
            }
        }

        return false;
    }


    /**
     * @dev Give random draco to the provided address
     */
    function reserveDracos(address _address)
        external
        onlyCollaborator
    {
        require(availableDracos.length >= giveawayCount, "No dracos left to be claimed");
        require(!premintingComplete,"Dracos were already reserved for giveaways!");
        totalMintedTokens += giveawayCount;

        uint256[] memory tokenIds = new uint256[](giveawayCount);

        for (uint256 i; i < giveawayCount; i++) {
            tokenIds[i] = getDracoToBeClaimed();
        }

        _batchMint(_address, tokenIds);
        premintingComplete = true;
    }

    // END ONLY COLLABORATORS

    /**
     * @dev Claim a single preminted draco
     */
    function premintDraco() external payable callerIsUser premintStarted onlyPreminter {
        require(
            claimedDracosPerWallet[msg.sender] < maxDracoPerWallet,
            "You cannot claim more dracos"
        );

        require(availableDracos.length > 0, "No dracos left to be claimed");
        require(totalPremintedTokens < premintingCount, "No dracos left to be preminted");

        claimedDracosPerWallet[msg.sender]++;
        totalMintedTokens++;
        totalPremintedTokens++;

        _mint(msg.sender, getDracoToBeClaimed());

        for (uint256 i; i <= preminters.length; i++) {
            if (preminters[i] != msg.sender) {
                continue;
            }
            preminters[i] = preminters[preminters.length - 1];
            preminters.pop();
            break;
        }
    }

    /**
     * @dev Claim a single draco
     */
    function claimDraco() external payable callerIsUser claimStarted {
        require(msg.value >= getCurrentMintPriceInternal(), "Not enough Ether to claim an draco");

        require(
            claimedDracosPerWallet[msg.sender] < maxDracoPerWallet,
            "You cannot claim more dracos"
        );

        require(availableDracos.length > 0, "No dracos left to be claimed");

        claimedDracosPerWallet[msg.sender]++;
        totalMintedTokens++;

        _mint(msg.sender, getDracoToBeClaimed());
    }

    /**
     * @dev Claim up to 10 dracos at once
     */
    function claimDracos(uint256 amount)
        external
        payable
        callerIsUser
        claimStarted
    {
        require(
            msg.value >= getCurrentMintPriceForTokensInternal(amount),
            "Not enough Ether to claim the dracos"
        );
        
        require(amount <= maxDracoPerTransaction, "You can only claim 10 dracos per transactions");

        require(
            claimedDracosPerWallet[msg.sender] + amount <= maxDracoPerWallet,
            "You cannot claim more dracos"
        );

        require(availableDracos.length >= amount, "No dracos left to be claimed");

        uint256[] memory tokenIds = new uint256[](amount);

        claimedDracosPerWallet[msg.sender] += amount;
        totalMintedTokens += amount;

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = getDracoToBeClaimed();
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
     * @dev Returns how many dracos are still available to be claimed
     */
    function getAvailableDracos() external view returns (uint256) {
        return availableDracos.length;
    }

    /**
     * @dev Returns the claim price for external use
     */
    function getCurrentMintPrice() external view returns (uint256) {
        return getCurrentMintPriceInternal();
    }

    /**
     * @dev Returns the claim price for internal use
     */
    function getCurrentMintPriceInternal() private view returns (uint256) {
        if (availableDracos.length <= 8000 && availableDracos.length > 7600) {
            return mintPriceFirstBracket;
        }
        if (availableDracos.length <= 7600 && availableDracos.length > 7200) {
            return mintPriceSecondBracket;
        }
        return mintPriceThirdBracket;
    }

    /**
     * @dev Returns the claim price
     */
    function getCurrentMintPriceForTokens(uint256 amount) external view returns (uint256) {
        return getCurrentMintPriceForTokensInternal(amount);
    }

    /**
     * @dev Returns the claim price
     */
    function getCurrentMintPriceForTokensInternal(uint256 amount) private view returns (uint256) {
        if (amount <= 1) {
            return getCurrentMintPriceInternal();
        }

        if (amount > 1) {
            if (availableDracos.length <= 8000 && availableDracos.length > 7600) {
                if (availableDracos.length - amount > 7600) {
                    return mintPriceFirstBracket * amount;
                } else {
                    return ((availableDracos.length - 7601) * mintPriceFirstBracket) + ((amount - (availableDracos.length - 7601)) * mintPriceSecondBracket);
                }
            }
            if (availableDracos.length <= 7600 && availableDracos.length > 7200) {
                if (availableDracos.length - amount > 7200) {
                    return mintPriceSecondBracket * amount;
                } else {
                    return ((availableDracos.length - 7201) * mintPriceSecondBracket) + ((amount - (availableDracos.length - 7201)) * mintPriceThirdBracket);
                }
            }
        }
        return mintPriceThirdBracket * amount;
    }

    /**
     * @dev Returns the total supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return totalMintedTokens;
    }

    // Private and Internal functions

    /**
     * @dev Returns a random available draco to be claimed
     */
    function getDracoToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availableDracos.length);
        uint256 tokenId = uint256(availableDracos[random]);

        availableDracos[random] = availableDracos[availableDracos.length - 1];
        availableDracos.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableDracos.length,
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