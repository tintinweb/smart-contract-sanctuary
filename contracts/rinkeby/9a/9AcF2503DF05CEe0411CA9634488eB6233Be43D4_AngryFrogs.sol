// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";
import "./IERC721.sol";

interface IRandomNumGenerator {
    function getRandomNumber(
        uint256 _seed,
        uint256 _limit,
        uint256 _random
    ) external view returns (uint16);
}

interface IGoldStaking {
    function stake(address owner, uint16[] memory tokenIds) external;
}

/**
 * @title AngryFrogs Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract AngryFrogs is ERC721Burnable {
    uint16 private mintedCount;

    uint16 public MAX_SUPPLY;
    uint16 public CLAIM_COUNT;
    uint16 public HUNTER_COUNT;

    uint256 public mintPrice;
    uint16 public maxByMint;

    address public wallet1;
    address public wallet2;

    address public metaAddress;
    address public stakingAddress;
    IRandomNumGenerator randomGen;

    bool public publicSale;
    bool public privateSale;

    uint16[] private _availableTokens;

    mapping(uint8 => bool) public mintedFromMeta;
    mapping(address => uint8) public mintableFromRaccoon;

    mapping(address => bool) public whitelist;

    constructor() ERC721("Angry Frogs", "AngryFrogs") {
        MAX_SUPPLY = 10000;
        CLAIM_COUNT = 1462;
        HUNTER_COUNT = 300;
        mintPrice = 8 * 10**16;
        maxByMint = 30;

        addAvailableTokens(0, 10000);

        wallet1 = 0xE1bF6046BC0F602F8c31E5dd4e090bd959F9B7a4;
        wallet2 = 0xE1bF6046BC0F602F8c31E5dd4e090bd959F9B7a4;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setMaxByMint(uint16 newMaxByMint) external onlyOwner {
        maxByMint = newMaxByMint;
    }

    function setCount(
        uint16 _max_supply,
        uint16 _claim_count,
        uint16 _hunter_count
    ) external onlyOwner {
        MAX_SUPPLY = _max_supply;
        CLAIM_COUNT = _claim_count;
        HUNTER_COUNT = _hunter_count;
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        publicSale = status;
    }

    function setPrivateSaleStatus(bool status) external onlyOwner {
        privateSale = status;
    }

    function setMetaAddress(address _metaAddress) external onlyOwner {
        metaAddress = _metaAddress;
    }

    function setRandomContract(IRandomNumGenerator _randomGen)
        external
        onlyOwner
    {
        randomGen = _randomGen;
    }

    function setStakingAddress(address _stakingAddress) external onlyOwner {
        stakingAddress = _stakingAddress;
    }

    function setRaccoonOwners(address[] memory _owners, uint8[] memory _counts)
        external
        onlyOwner
    {
        require(_owners.length == _counts.length, "Not same count");
        for (uint16 i; i < _owners.length; i++) {
            mintableFromRaccoon[_owners[i]] = _counts[i];
        }
    }

    function setWhitelist(address[] memory _owners) external onlyOwner {
        for (uint16 i; i < _owners.length; i++) {
            whitelist[_owners[i]] = true;
        }
    }

    function addAvailableTokens(uint16 _from, uint16 _to) public onlyOwner {
        for (uint16 i = _from; i < _to; i++) {
            _availableTokens.push(i);
        }
    }

    function isHunter(uint16 tokenId) public view returns (bool) {
        return (tokenId < HUNTER_COUNT);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Hardcode the Manager's approval so that users don't have to waste gas approving
        if (_msgSender() != stakingAddress)
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    function getTokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIdList = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIdList[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIdList;
    }

    function _getTokenToBeMinted() private returns (uint16) {
        uint256 random = randomGen.getRandomNumber(
            _availableTokens.length,
            _availableTokens.length,
            totalSupply()
        );
        uint16 tokenId = _availableTokens[random];

        _availableTokens[random] = _availableTokens[
            _availableTokens.length - 1
        ];
        _availableTokens.pop();

        return tokenId;
    }

    function mintByUserPrivate(uint8 _numberOfTokens, bool _stake)
        external
        payable
    {
        require(privateSale, "Private Sale is not active");
        require(tx.origin == msg.sender, "Only EOA");
        require(whitelist[msg.sender], "Not Whitelist");
        require(
            mintedCount + _numberOfTokens <= MAX_SUPPLY - CLAIM_COUNT,
            "Max Limit To Presale"
        );
        require(_numberOfTokens <= maxByMint, "Exceeds Amount");
        require(mintPrice * _numberOfTokens <= msg.value, "Low Price To Mint");

        mintedCount = mintedCount + _numberOfTokens;

        uint16[] memory tokenIds = _stake
            ? new uint16[](_numberOfTokens)
            : new uint16[](0);

        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            uint16 tokenId = _getTokenToBeMinted();
            if (_stake) {
                tokenIds[i] = tokenId;
                _safeMint(stakingAddress, tokenId);
            } else {
                _safeMint(msg.sender, tokenId);
            }
        }

        if (_stake) {
            IGoldStaking(stakingAddress).stake(msg.sender, tokenIds);
        }
    }

    function mintByUser(uint8 _numberOfTokens, bool _stake) external payable {
        require(publicSale, "Public Sale is not active");
        require(tx.origin == msg.sender, "Only EOA");
        require(
            mintedCount + _numberOfTokens <= MAX_SUPPLY - CLAIM_COUNT,
            "Max Limit To Presale"
        );
        require(_numberOfTokens <= maxByMint, "Exceeds Amount");
        require(mintPrice * _numberOfTokens <= msg.value, "Low Price To Mint");

        mintedCount = mintedCount + _numberOfTokens;

        uint16[] memory tokenIds = _stake
            ? new uint16[](_numberOfTokens)
            : new uint16[](0);

        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            uint16 tokenId = _getTokenToBeMinted();
            if (_stake) {
                tokenIds[i] = tokenId;
                _safeMint(stakingAddress, tokenId);
            } else {
                _safeMint(msg.sender, tokenId);
            }
        }

        if (_stake) {
            IGoldStaking(stakingAddress).stake(msg.sender, tokenIds);
        }
    }

    function claimByMeta(uint8[] memory ids, bool _stake) external {
        require(publicSale || privateSale, "Sale is not active");
        require(tx.origin == msg.sender, "Only EOA");

        uint8 length = uint8(ids.length);
        for (uint8 i; i < length; i++) {
            address owner = IERC721(metaAddress).ownerOf(ids[i]);
            require(owner == msg.sender, "Not Owned");
            require(!mintedFromMeta[ids[i]], "Already Claimed");
        }

        for (uint8 i; i < length; i++) {
            mintedFromMeta[ids[i]] = true;
        }

        uint256 _numberOfTokens = length * 2;

        uint16[] memory tokenIds = _stake
            ? new uint16[](_numberOfTokens)
            : new uint16[](0);

        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            uint16 tokenId = _getTokenToBeMinted();
            if (_stake) {
                tokenIds[i] = tokenId;
                _safeMint(stakingAddress, tokenId);
            } else {
                _safeMint(msg.sender, tokenId);
            }
        }

        if (_stake) {
            IGoldStaking(stakingAddress).stake(msg.sender, tokenIds);
        }
    }

    function claimByRaccoon(
        address account,
        uint8 count,
        bool _stake
    ) external {
        require(publicSale || privateSale, "Sale is not active");
        require(tx.origin == msg.sender, "Only EOA");
        require(mintableFromRaccoon[account] >= count, "Already Claimed");

        uint8 _numberOfTokens = count * 2;

        mintableFromRaccoon[account] = mintableFromRaccoon[account] - count;

        uint16[] memory tokenIds = _stake
            ? new uint16[](_numberOfTokens)
            : new uint16[](0);

        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            uint16 tokenId = _getTokenToBeMinted();
            if (_stake) {
                tokenIds[i] = tokenId;
                _safeMint(stakingAddress, tokenId);
            } else {
                _safeMint(msg.sender, tokenId);
            }
        }

        if (_stake) {
            IGoldStaking(stakingAddress).stake(msg.sender, tokenIds);
        }
    }

    function withdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 amount2 = totalBalance / 10;
        payable(wallet2).transfer(amount2);
        payable(wallet1).transfer(totalBalance - amount2);
    }
}