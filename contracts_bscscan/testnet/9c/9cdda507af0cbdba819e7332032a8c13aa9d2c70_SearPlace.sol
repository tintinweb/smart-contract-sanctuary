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
import "./IERC20.sol";

contract SearPlace is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    CountersUpgradeable.Counter private _tokenIdCounter;
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // number of token to mint nft
    uint256 private _feeToMint;
    address private _searToken;
    // addresss to send token when mint
    address private _commission;

    mapping(address => bool) public blackList;

    event MintNFTByAdmin(uint256 indexed tokenId, string _uri, address to);
    event MintNFTByUser(uint256 indexed tokenId, string _uri, address to);

    event AddedBlackListNFT(address indexed _user);
    event RemovedBlackListNFT(address indexed _user);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address __commission,
        address __searToken,
        uint256 __feeToMint
    ) public initializer {
        __ERC721_init("SearPlace", "SEARP");
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _commission = __commission;
        _searToken = __searToken;
        _feeToMint = __feeToMint;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address _to, string memory _uri)
        public
        onlyRole(MINTER_ROLE)
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
        emit MintNFTByAdmin(tokenId, _uri, _to);
    }

    function changeFeeToMint(uint256 _newFee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _feeToMint = _newFee;
    }

    /**
     @notice function create a token
     @param _uri url image published in ipfs
     */
    function mintByUser(string memory _uri) public {
        require(!blackList[msg.sender], "Address is in blackList.");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        require(
            IERC20(_searToken).transferFrom(
                msg.sender,
                _commission,
                _feeToMint
            ),
            "Fail to transfer to the commission."
        );

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, _uri);

        emit MintNFTByUser(tokenId, _uri, msg.sender);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override whenNotPaused {
        require(!blackList[_from], "Address is in blackList.");
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
        require(!blackList[msg.sender], "Address is in blackList.");
        super._burn(tokenId);
    }

    /**
     * @dev function add user into backlist
     * @param _user account to add
     */
    function addBlackList(address _user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        blackList[_user] = true;
        emit AddedBlackListNFT(_user);
    }

    /**
     * @dev function remove user in blacklist
     * @param _user account to remove
     */
    function removeBlackList(address _user)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        blackList[_user] = false;
        emit AddedBlackListNFT(_user);
    }

    /**
     * @dev check user in black list
     * @param _user account to check
     */
    function isInBlackList(address _user) public view returns (bool) {
        return blackList[_user];
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
        return "v1!";
    }
}