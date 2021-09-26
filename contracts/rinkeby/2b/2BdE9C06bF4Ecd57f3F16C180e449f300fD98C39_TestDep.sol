// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/**
 * @title TestDep
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract TestDep is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Address for address;

    struct Conf {
        bool mintEnabled;
        uint8 perMint;
        uint16 perAccount;
        uint16 supply;
        uint16 maxTests;
        uint64 price;
    }

    address private controller;
    uint256 public imagesHash;

    string private defaultURI;
    string private baseURI;
    string private metaURI;

    mapping(uint256 => uint256) private metaHashes;

    Conf private conf;

    event updateMetaHash(address, uint256, uint256);

    modifier isController(address sender) {
        require(
            sender != address(0) && (sender == owner() || sender == controller)
        );
        _;
    }

    /**
     * @notice Setup ERC721 and initial config
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory _defaultURI
    ) ERC721(name, symbol) {
        conf = Conf(false, 10, 250, 1, 20, 80000000000000000);
        defaultURI = _defaultURI;
    }

    /**
     * @notice Mint reserved TestDep.
     * @param accounts Array of accounts to receive reserves.
     * @param start Index to start minting at.
     * @dev Utilize unchecked {} and calldata for gas savings.
     */
    function mintReserved(address[] calldata accounts, uint16 start)
        public
        onlyOwner
    {
        address[] memory _accounts = accounts;
        unchecked {
            for (uint8 i = 0; i < _accounts.length; i++) {
                _safeMint(_accounts[i], start + i);
            }
        }
    }

    /**
     * @notice Take eth out of the contract
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @notice Bring new Tests into the world.
     * @param amount Number of Tests to mint.
     * @dev Utilize unchecked {} and calldata for gas savings.
     */
    function mint(uint256[1] calldata amount) public payable {
        require(conf.mintEnabled, "Minting is disabled.");
        require(
            conf.supply + amount[0] < conf.maxTests,
            "Amount exceeds maximum supply of Test."
        );
        require(
            balanceOf(msg.sender) + amount[0] <= conf.perAccount,
            "Amount exceeds current maximum mints per account."
        );
        require(
            amount[0] <= conf.perMint,
            "Amount exceeds current maximum Tests per mint."
        );
        require(
            conf.price * amount[0] <= msg.value,
            "Ether value sent is not correct."
        );

        uint16 supply = conf.supply;
        unchecked {
            for (uint16 i = 0; i < amount[0]; i++) {
                _safeMint(msg.sender, supply++);
            }
        }
        conf.supply = supply;
    }

    /**
     * @notice Set meta hash for token.
     * @param id Token id.
     * @param _hash Hash value.
     * @dev Only authorized accounts.
     */
    function setMetaHash(uint256 id, uint256 _hash)
        public
        isController(msg.sender)
    {
        require(_exists(id), "Token does not exist.");
        metaHashes[id] = _hash;
        emit updateMetaHash(msg.sender, id, _hash);
    }

    /**
     * @notice Return meta hash for token.
     */
    function getMetaHash(uint256 id) public view returns (uint256) {
        return metaHashes[id];
    }

    /**
     * @notice Sets URI for image hashes.
     */
    function setImagesHash(uint256 _imagesHash) public onlyOwner {
        imagesHash = _imagesHash;
    }

    /**
     * @dev Returns minting state.
     */
    function getMintEnabled() public view returns (bool) {
        return conf.mintEnabled;
    }

    /**
     * @notice Toggles minting state.
     */
    function toggleMintEnabled() public onlyOwner {
        conf.mintEnabled = !conf.mintEnabled;
    }

    /**
     * @notice Returns max Tests per mint.
     */
    function getPerMint() public view returns (uint8) {
        return conf.perMint;
    }

    /**
     * @notice Sets max Tests per mint.
     */
    function setPerMint(uint8 _perMint) public onlyOwner {
        conf.perMint = _perMint;
    }

    /**
     * @notice Returns max mints per account.
     */
    function getPerAccount() public view returns (uint16) {
        return conf.perAccount;
    }

    /**
     * @notice Sets max mints per account.
     */
    function setPerAccount(uint16 _perAccount) public onlyOwner {
        conf.perAccount = _perAccount;
    }

    /**
     * @notice Set base URI.
     */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist.");

        if (bytes(baseURI).length == 0) {
            return defaultURI;
        } else {
            return string(abi.encodePacked(baseURI, (tokenId + 1).toString()));
        }
    }
}