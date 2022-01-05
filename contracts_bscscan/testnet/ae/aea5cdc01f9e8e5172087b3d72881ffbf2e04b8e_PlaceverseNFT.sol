// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMath.sol";

import "./Details.sol";

contract PlaceverseNFT is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using PlaceDetails for PlaceDetails.Details;
    using SafeMath for uint256;

    event MintNFTByAdmin(
        uint256 indexed _tokenId,
        string _uri,
        address _to,
        string _placeId,
        uint256 _rarity
    );

    event MintNFTByUser(
        uint256 indexed _tokenId,
        string _uri,
        address _to,
        string _placeId,
        uint256 _rarity
    );

    event AddedBlackList(address indexed _user);
    event RemovedBlackList(address indexed _user);

    event AddedBlackListToken(uint256 _tokenId);
    event RemoveBlackListToken(uint256 _tokenId);

    event AddMiner(address _miner);
    event RemoveMiner(address _miner);

    event SetMaxRarity(uint256 _rarity);
    event SetMaxLevel(uint256 _level);
    event UpgradeNFTLevel(uint256 _tokenId, uint256 _newLevel);
    event UpgradeNFTRarity(uint256 _tokenId, uint256 _newRarity);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 private constant MIN_RARITY_AND_LEVEL = 1;

    CountersUpgradeable.Counter private _tokenIdCounter;

    mapping(address => bool) public blackListAccounts;
    mapping(uint256 => bool) public blackListTokens;
    mapping(uint256 => uint256) public tokenDetails;
    mapping(string => uint256) public placeIdPerToken;

    uint256 private _maxRarity;
    uint256 private _maxLevel;
    bool private _lockUserMint;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _owner) public initializer {
        __ERC721_init("Placeverse NFT Token", "PLVT");
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(PAUSER_ROLE, _owner);
        _grantRole(MINTER_ROLE, _owner);
        _grantRole(UPGRADER_ROLE, _owner);
        _grantRole(OPERATOR_ROLE, _owner);

        _maxRarity = 5;
        _maxLevel = 10;
        _lockUserMint = true;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    modifier whenNotLockMinted() {
        require(!_lockUserMint, "Lock mint by user.");
        _;
    }

    function mintByAdmin(
        address _to,
        string memory _uri,
        uint256 _rarity,
        string memory _placeId
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId = _mint(_to, _uri, _rarity, _placeId);

        emit MintNFTByAdmin(tokenId, _uri, _to, _placeId, _rarity);
        return tokenId;
    }

    function mintByUser(
        string memory _uri,
        uint256 _rarity,
        string memory _placeId
    ) public whenNotLockMinted returns (uint256) {
        address _to = msg.sender;
        uint256 tokenId = _mint(_to, _uri, _rarity, _placeId);
        emit MintNFTByUser(tokenId, _uri, _to, _placeId, _rarity);
        return tokenId;
    }

    function _mint(
        address _to,
        string memory _uri,
        uint256 _rarity,
        string memory _placeId
    ) internal returns (uint256) {
        require(!blackListAccounts[_to], "ADDRESS_BLACKLIST");
        require(placeIdPerToken[_placeId] == 0, "PLACEID_EXISTS");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        tokenDetails[tokenId] = PlaceDetails.encode(
            PlaceDetails.Details(tokenId, _rarity, MIN_RARITY_AND_LEVEL)
        );
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
        _setPlaceId(tokenId, _placeId);
        return tokenId;
    }

    function addMiner(address _minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_minter != address(0), "ZERO_ADDRESS");
        _grantRole(MINTER_ROLE, _minter);
        emit AddMiner(_minter);
    }

    function removeMiner(address _minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_minter != address(0), "ZERO_ADDRESS");
        _revokeRole(MINTER_ROLE, _minter);
        emit RemoveMiner(_minter);
    }

    function setOperatorRole(address _operator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_operator != address(0), "ZERO_ADDRESS");
        _grantRole(OPERATOR_ROLE, _operator);
    }

    function removeOperatorRole(address _operator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_operator != address(0), "ZERO_ADDRESS");
        _revokeRole(OPERATOR_ROLE, _operator);
    }

    function setMaxRarity(uint256 _rarity) public onlyRole(OPERATOR_ROLE) {
        _maxRarity = _rarity;
        emit SetMaxRarity(_rarity);
    }

    function setMaxLevel(uint256 _level) public onlyRole(OPERATOR_ROLE) {
        _maxLevel = _level;
        emit SetMaxLevel(_level);
    }

    function upgradeNFTLevel(uint256 _tokenId)
        public
        onlyRole(OPERATOR_ROLE)
    {
        uint256 details = tokenDetails[_tokenId];
        require(details > 0, "TOKENID_NOT_FOUND");

        uint256 level = PlaceDetails.decodeLevel(details).add(1);
        require(level <= _maxLevel, "MAX_LEVEL_UPGRADE");
        tokenDetails[_tokenId] = PlaceDetails.increaseLevel(details);
        emit UpgradeNFTLevel(_tokenId, level);
    }

    function upgradeNFTRarity(uint256 _tokenId)
        public
        onlyRole(OPERATOR_ROLE)
    {
        uint256 details = tokenDetails[_tokenId];
        require(details > 0, "TOKENID_NOT_FOUND");

        uint256 rarity = PlaceDetails.decodeRarity(details).add(1);
        require(rarity <= _maxRarity, "MAX_RARITY_UPGRADE");
        tokenDetails[_tokenId] = PlaceDetails.increaseRarity(details);
        emit UpgradeNFTRarity(_tokenId, rarity);
    }

    function downgradeNFTLevel(uint256 _tokenId)
        public
        onlyRole(OPERATOR_ROLE)
    {
        uint256 details = tokenDetails[_tokenId];
        require(details > 0, "TOKENID_NOT_FOUND");

        uint256 level = PlaceDetails.decodeLevel(details).sub(1);
        require(level >= MIN_RARITY_AND_LEVEL, "MIN_LEVEL_UPGRADE");
        tokenDetails[_tokenId] = PlaceDetails.decreaseLevel(details);
        emit UpgradeNFTLevel(_tokenId, level);
    }

    function downgradeNFTRarity(uint256 _tokenId)
        public
        onlyRole(OPERATOR_ROLE)
    {
        uint256 details = tokenDetails[_tokenId];
        require(details > 0, "TOKENID_NOT_FOUND");

        uint256 rarity = PlaceDetails.decodeRarity(details).sub(1);
        require(rarity >= MIN_RARITY_AND_LEVEL, "MAX_RARITY_UPGRADE");
        tokenDetails[_tokenId] = PlaceDetails.decreaseRarity(details);
        emit UpgradeNFTRarity(_tokenId, rarity);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override whenNotPaused {
        require(!blackListAccounts[_from], "ADDRESS_BLACKLIST");
        require(!blackListTokens[_tokenId], "TOKEN_NFT_BLACKLIST");
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    /**
     * @dev function add user into backlist
     * @param _user account to add
     */
    function addBlackListAccount(address _user)
        public
        onlyRole(OPERATOR_ROLE)
    {
        blackListAccounts[_user] = true;
        emit AddedBlackList(_user);
    }

    /**
     * @dev function remove user in blacklist
     * @param _user account to remove
     */
    function removeBlackListAccount(address _user)
        public
        onlyRole(OPERATOR_ROLE)
    {
        blackListAccounts[_user] = false;
        emit AddedBlackList(_user);
    }

    /**
     * @dev function add user into backlist
     * @param _tokenId account to add
     */
    function addBlackListToken(uint256 _tokenId)
        public
        onlyRole(OPERATOR_ROLE)
    {
        blackListTokens[_tokenId] = true;
        emit AddedBlackListToken(_tokenId);
    }

    /**
     * @dev function remove user in blacklist
     * @param _tokenId account to remove
     */
    function removeBlackListToken(uint256 _tokenId)
        public
        onlyRole(OPERATOR_ROLE)
    {
        blackListTokens[_tokenId] = false;
        emit RemoveBlackListToken(_tokenId);
    }

    /**
     * @dev check user in black list
     * @param _user account to check
     */
    function isInBlackListAccount(address _user) public view returns (bool) {
        return blackListAccounts[_user];
    }

    /**
     * @dev check token in black list
     * @param _tokenId account to check
     */
    function isInBlackListToken(uint256 _tokenId) public view returns (bool) {
        return blackListTokens[_tokenId];
    }

    function _setPlaceId(uint256 _tokenId, string memory _placeId) internal {
        placeIdPerToken[_placeId] = _tokenId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev function return current verion of smart contract
     */
    function version() public pure returns (string memory) {
        return "v1.0!";
    }

    /**
     * @dev return token detail
     * @param _tokenId input key value
     * @return level and rarity
     */
    function getTokenDetails(uint256 _tokenId)
        public
        view
        returns (uint256, uint256)
    {
        uint256 details = tokenDetails[_tokenId];
        require(details > 0, "Detail information is invalid");
        PlaceDetails.Details memory data = PlaceDetails.decode(details);
        return (data.level, data.rarity);
    }
}