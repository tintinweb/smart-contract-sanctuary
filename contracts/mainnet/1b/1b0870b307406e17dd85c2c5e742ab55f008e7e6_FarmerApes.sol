// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

interface IERC721Contract {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface YieldToken {
    function updateRewardOnMint(address _user) external;

    function updateReward(address _from, address _to) external;

    function claimReward(address _to) external;
}

/**
 * @title FarmerApes
 */
contract FarmerApes is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    Ownable
{
    using SafeMath for uint256;

    string public baseTokenURI;
    uint256 private _currentTokenId;
    uint256 public constant MAX_SUPPLY = 8888;
    uint8 public constant MAX_MINT_LIMIT = 10;
    uint256 private constant GIFT_COUNT = 88;
    uint256 public mintBeforeReserve;
    uint256 public totalAirdropNum;
    address public hawaiiApe;
    uint256 public totalReserved;
    uint256 public presalePrice = .0588 ether;
    uint256 public publicSalePrice = .06 ether;
    uint256 public presaleTime = 1639584000;
    uint256 public publicSaleTime = 1639670415;
    bool public ApprovedAsHolder = true;
    bool public inPublic;

    mapping(address => bool) public whitelisters;
    mapping(address => bool) public presaleStatus;
    mapping(address => uint8) public reserved;
    mapping(address => uint8) public claimed;
    mapping(address => uint8) public airdropNum;
    mapping(uint256 => RarityType) private apeType;
    mapping(address => uint256) private yield;

    enum RarityType {
        Null,
        Common,
        Rare,
        SuperRare,
        Epic,
        Lengendary
    }

    YieldToken public yieldToken;
    IERC721Contract public BAYC;
    IERC721Contract public MAYC;

    event ValueChanged(string indexed fieldName, uint256 newValue);
    event LuckyApe(uint256 indexed tokenId, address indexed luckyAddress);
    event LegendaryDrop(uint256 indexed tokenId, address indexed luckyAddress);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(
            checkWhiteList(msg.sender),
            "FarmerApes: Oops, sorry you're not whitelisted."
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _BAYC,
        address _MAYC
    ) ERC721(_name, _symbol) {
        baseTokenURI = _uri;
        _initializeEIP712(_name);
        BAYC = IERC721Contract(_BAYC);
        MAYC = IERC721Contract(_MAYC);
    }

    /**
     * @dev Check user is on the whitelist or not.
     * @param user msg.sender
     */

    function checkWhiteList(address user) public view returns (bool) {
        if (ApprovedAsHolder) {
            return
                whitelisters[user] ||
                BAYC.balanceOf(user) > 0 ||
                MAYC.balanceOf(user) > 0;
        } else {
            return whitelisters[user];
        }
    }

    function setPresalePrice(uint256 newPrice) external onlyOwner {
        presalePrice = newPrice;
        emit ValueChanged("presalePrice", newPrice);
    }

    function setPublicPrice(uint256 newPrice) external onlyOwner {
        publicSalePrice = newPrice;
        emit ValueChanged("publicSalePrice", newPrice);
    }

    /**
     * @dev Mint to msg.sender. Only whitelisted users can participate
     */
    function presale() external payable onlyWhitelisted {
        require(
            block.timestamp >= presaleTime &&
                block.timestamp < presaleTime + 1 days,
            "FarmerApes: Presale has yet to be started."
        );
        require(msg.value == presalePrice, "FarmerApes: Invalid value.");
        require(
            !presaleStatus[msg.sender],
            "FarmerApe: You had already participated in presale."
        );
        require(
            totalSupply() + 1 <= MAX_SUPPLY - GIFT_COUNT,
            "FarmerApes: Sorry, we are sold out."
        );
        _mintMany(1);
        presaleStatus[msg.sender] = true;
    }

    /**
     * @dev Reserve for the purchase. Each address is allowed to purchase up to 10 FarmerApes.
     * @param _num Quantity to purchase
     */
    function reserve(uint8 _num) external payable {
        require(
            block.timestamp >= publicSaleTime &&
                block.timestamp <= publicSaleTime + 7 days,
            "FarmerApes: Public sale has yet to be started."
        );
        if (mintBeforeReserve == 0) {
            mintBeforeReserve = totalSupply();
        }
        require(
            (_num + reserved[msg.sender] + claimed[msg.sender]) <=
                MAX_MINT_LIMIT,
            "FarmerApes: Each address is allowed to purchase up to 10 FarmerApes."
        );
        require(
            mintBeforeReserve + uint256(_num) <=
                MAX_SUPPLY - totalReserved - (GIFT_COUNT - totalAirdropNum),
            "FarmerApes: Sorry, we are sold out."
        );
        require(
            msg.value == uint256(_num) * publicSalePrice,
            "FarmerApes: Invalid value."
        );
        reserved[msg.sender] += _num;
        totalReserved += uint256(_num);
    }

    /**
     * @dev FarmerApes can only be claimed after your reservation.
     */
    function claim() external {
        require(
            block.timestamp >= publicSaleTime &&
                block.timestamp <= publicSaleTime + 7 days,
            "FarmerApes: You have missed the time window. Your Farmer Ape has escaped."
        );
        _mintMany(reserved[msg.sender]);
        claimed[msg.sender] += reserved[msg.sender];
        reserved[msg.sender] = 0;
    }

    /**
     * @dev set the presale and public sale time only by Admin
     */
    function updateTime(uint256 _preSaleTime, uint256 _publicSaleTime)
        external
        onlyOwner
    {
        require(
            _publicSaleTime > _preSaleTime,
            "FarmerApes: Invalid time set."
        );
        presaleTime = _preSaleTime;
        publicSaleTime = _publicSaleTime;
        emit ValueChanged("presaleTime", _preSaleTime);
        emit ValueChanged("publicSaleTime", _publicSaleTime);
    }

    function setAPCToken(address _APC) external onlyOwner {
        yieldToken = YieldToken(_APC);
    }

    function setInPublic(bool _inPublic) external onlyOwner {
        inPublic = _inPublic;
    }

    function setIfApprovedAsHolder(bool _ApprovedAsHolder) external onlyOwner {
        ApprovedAsHolder = _ApprovedAsHolder;
    }

    /**
     * @dev Mint and airdrop apes to several addresses directly.
     * @param _recipients addressses of the future holder of Farmer Apes.
     * @param rTypes rarity types of the future holder of Farmer Apes.
     */
    function mintTo(address[] memory _recipients, uint8[] memory rTypes)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _recipients.length; i++) {
            uint256 newTokenId = _getNextTokenId();
            _mintTo(_recipients[i], newTokenId, rTypes[i]);
            checkRoadmap(newTokenId);
            _incrementTokenId();
        }
        require(
            GIFT_COUNT - totalAirdropNum >= _recipients.length,
            "We've reached the maximum of airdrop limits."
        );
        totalAirdropNum += _recipients.length;
    }

    function _mintTo(
        address to,
        uint256 tokenId,
        uint8 rType
    ) internal {
        yieldToken.updateRewardOnMint(to);

        if (rType == 0) {
            apeType[tokenId] = randomRarity();
        } else {
            apeType[tokenId] = RarityType(rType);
        }

        super._mint(to, tokenId);
        yield[to] += getApeYield(tokenId);
    }

    function randomRarity() internal view returns (RarityType rtype) {
        uint256 randomNumber = (random(_currentTokenId) % 10000) + 1;
        if (randomNumber <= 8000) {
            return RarityType.Common;
        } else if (randomNumber <= 9387) {
            return RarityType.Rare;
        } else if (randomNumber <= 9887) {
            return RarityType.SuperRare;
        } else if (randomNumber <= 9987) {
            return RarityType.Epic;
        } else {
            return RarityType.Lengendary;
        }
    }

    /**
     * @dev Airdrop apes to several addresses.
     * @param _recipients Holders are able to mint Farmer Apes for free.
     */
    function airdrop(address[] memory _recipients, uint8[] memory _amounts)
        external
        onlyOwner
    {
        uint256 _airdropNum;
        require(
            block.timestamp >= publicSaleTime,
            "FarmerApes: Public sale has yet to be started."
        );

        for (uint256 i = 0; i < _recipients.length; i++) {
            _airdropNum += _amounts[i];
            airdropNum[_recipients[i]] = _amounts[i];
        }
        require(
            GIFT_COUNT - totalAirdropNum >= _airdropNum,
            "We've reached the maximum of airdrop limits."
        );
        totalAirdropNum += _airdropNum;
    }

    function getAirdrop() external {
        require(
            airdropNum[msg.sender] > 0 &&
                block.timestamp <= publicSaleTime + 7 days,
            "FarmerApes: You have missed the time window. Your Farmer Ape has escaped."
        );
        _mintMany(airdropNum[msg.sender]);
        airdropNum[msg.sender] = 0;
    }

    function checkRoadmap(uint256 newTokenId) internal {
        if (newTokenId % 888 == 0) {
            uint256 apeId = newTokenId - (random(newTokenId) % 888);
            address luckyAddress = ownerOf(apeId);
            payable(luckyAddress).transfer(.888 ether);
            emit LuckyApe(apeId, luckyAddress);
        }

        // For every 4444 sales, a legendary NFT will be airdropped to a lucky ape holder.
        if (newTokenId == 4444 || newTokenId == MAX_SUPPLY + 2 - GIFT_COUNT) {
            uint256 apeId = newTokenId - (random(newTokenId) % 4444);
            address luckyAddress = ownerOf(apeId);
            emit LegendaryDrop(apeId, luckyAddress);
        }
    }

    /**
     * @dev Mint Farmer Apes.
     */
    function _mintMany(uint8 _num) private {
        for (uint8 i = 0; i < _num; i++) {
            uint256 newTokenId = _getNextTokenId();
            _mint(msg.sender, newTokenId);
            _incrementTokenId();
            checkRoadmap(newTokenId);
        }
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev Once we sell out, a lucky Hawaii ape holder with at least 2 Farmer Apes will be selected to jump to a paid trip.
     */
    function _randomTripApeAddress(uint256 seed) internal returns (address) {
        uint256 apeId = (random(seed) % _currentTokenId) + 1;
        address apeAddress = ownerOf(apeId);
        if (balanceOf(apeAddress) >= 2) {
            return apeAddress;
        }
        return _randomTripApeAddress(random(seed));
    }

    /**
     * @dev Get the lucky ape for a paid trip to Hawaii
     * @return address
     */
    function randomTripApeAddress() external onlyOwner returns (address) {
        require(hawaiiApe == address(0), "The ape has already selected.");
        hawaiiApe = _randomTripApeAddress(_currentTokenId);
        return hawaiiApe;
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        require(_currentTokenId < MAX_SUPPLY);
        _currentTokenId++;
    }

    /**
     * @dev change the baseTokenURI only by Admin
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(address(0xa297c335fF5De7b2a8f2F95283456FDA26ddbfE4)).transfer(
            (balance * 3) / 100
        );
        payable(address(0x25f9454ABf96C656A151D85cD74EFD008838Aa54)).transfer(
            (balance * 8) / 1000
        );
        payable(address(0xa9b16C30a17D91a91746b072D7700971651e8d7A)).transfer(
            (balance * 3) / 100
        );
        
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    /**
     * @dev Set whitelist
     * @param whitelistAddresses Whitelist addresses
     */
    function addWhitelisters(address[] calldata whitelistAddresses)
        external
        onlyOwner
    {
        for (uint256 i; i < whitelistAddresses.length; i++) {
            whitelisters[whitelistAddresses[i]] = true;
        }
    }

    /**
     * @dev To know each Token's type and daily Yield.
     * @param tokenId token id
     */
    function getApeTypeAndYield(uint256 tokenId)
        external
        view
        returns (RarityType rType, uint256 apeYield)
    {
        if (inPublic) {
            rType = apeType[tokenId];
            apeYield = getApeYield(tokenId);
        } else {
            rType = RarityType.Null;
            apeYield = 0;
        }
    }

    /**
     * @dev To know each Token's daily Yield.
     * @param tokenId token id
     */

    function getApeYield(uint256 tokenId)
        internal
        view
        returns (uint256 apeYield)
    {
        if (apeType[tokenId] == RarityType.Common) {
            return 6;
        }
        if (apeType[tokenId] == RarityType.Rare) {
            return 7;
        }
        if (apeType[tokenId] == RarityType.SuperRare) {
            return 8;
        }
        if (apeType[tokenId] == RarityType.Epic) {
            return 9;
        }
        if (apeType[tokenId] == RarityType.Lengendary) {
            return 15;
        }
    }

    /**
     * @dev To know each address's total daily Yield.
     * @param user address
     */
    function getUserYield(address user) external view returns (uint256) {
        if (!inPublic) return 0;
        return yield[user] * 1e18;
    }

    /**
     * @dev To claim your total reward.
     */
    function claimReward() external {
        yieldToken.updateReward(msg.sender, address(0));
        yieldToken.claimReward(msg.sender);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        yieldToken.updateRewardOnMint(to);
        apeType[tokenId] = randomRarity();
        super._mint(to, tokenId);
        yield[to] += getApeYield(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        yieldToken.updateReward(from, to);
        yield[from] -= getApeYield(tokenId);
        yield[to] += getApeYield(tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        yieldToken.updateReward(from, to);
        yield[from] -= getApeYield(tokenId);
        yield[to] += getApeYield(tokenId);
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}