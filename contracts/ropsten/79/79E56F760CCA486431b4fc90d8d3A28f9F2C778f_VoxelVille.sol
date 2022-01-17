// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract VoxelVille is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant MAX_SUPPLY = 7777;

    uint256 public constant MAX_MINT_PER_TX = 3;

    uint256 public constant MAX_MINT_PER_TX_PRESALE = 1;

    uint256 public constant PRICE = 0.05 ether;

    string public baseURI;

    uint256 public batchSize;

    uint256 public batchCount;

    bool public mintable = false;

    bool public preSaleMintable = false;

    uint256 public totalSupplyRemaining = MAX_SUPPLY;

    mapping(address => bool) public allowList;

    event Mintable(bool mintable);

    event PreSaleMintable(bool preSaleMintable);

    event BaseURI(string baseURI);

    event BatchSize(uint256 batchSize);

    event BatchCount(uint256 batchCount);

    event AddToAllowList(address[] accounts);

    event RemoveFromAllowList(address account);

    constructor() ERC721("Voxel Ville", "VOVI") {
        _tokenIds.increment();
    }

    modifier isMintable() {
        require(mintable, "Voxel Ville: NFT cannot be minted yet.");
        _;
    }

    modifier isPreSaleMintable() {
        require(preSaleMintable, "Voxel Ville: NFT cannot be minted yet.");
        _;
    }

    modifier isNotExceedMaxMintPerTx(uint256 amount) {
        require(
            amount <= MAX_MINT_PER_TX,
            "Voxel Ville: Mint amount exceeds max limit per tx."
        );
        _;
    }

    modifier isNotExceedMaxMintPerTxPresale(uint256 amount) {
        require(
            amount <= MAX_MINT_PER_TX_PRESALE,
            "Voxel Ville: Mint amount exceeds max limit per tx."
        );
        _;
    }

    modifier isNotExceedAvailableSupply(uint256 amount) {
        require(
            batchCount + amount <= batchSize,
            "Voxel Ville: There are no more remaining NFT's to mint."
        );
        _;
    }

    modifier isPaymentSufficient(uint256 amount) {
        require(
            msg.value == amount * PRICE,
            "Voxel Ville: There was not enough/extra ETH transferred to mint an NFT."
        );
        _;
    }

    modifier isAllowList() {
        require(
            allowList[msg.sender],
            "Voxel Ville: You're not on the list for the presale."
        );
        _;
    }

    function preSaleMint(uint256 amount)
        public
        payable
        isPreSaleMintable
        isNotExceedMaxMintPerTxPresale(amount)
        isAllowList
        isNotExceedAvailableSupply(amount)
        isPaymentSufficient(amount)
    {
        uint256 id = _tokenIds.current();
        _safeMint(msg.sender, id);
        _tokenIds.increment();
        totalSupplyRemaining--;
        batchCount++;
        allowList[msg.sender] = false;
    }

    function mint(uint256 amount)
        public
        payable
        isMintable
        isNotExceedMaxMintPerTx(amount)
        isNotExceedAvailableSupply(amount)
        isPaymentSufficient(amount)
    {
        for (uint256 index = 0; index < amount; index++) {
            uint256 id = _tokenIds.current();
            _safeMint(msg.sender, id);
            _tokenIds.increment();
            totalSupplyRemaining--;
            batchCount++;
        }
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;

        emit BaseURI(baseURI);
    }

    function setMintable(bool _mintable) public onlyOwner {
        mintable = _mintable;

        emit Mintable(mintable);
    }

    function setPreSaleMintable(bool _preSaleMintable) public onlyOwner {
        preSaleMintable = _preSaleMintable;

        emit PreSaleMintable(preSaleMintable);
    }

    function setBatchSize(uint256 _batchSize) public onlyOwner {
        batchSize = _batchSize;

        emit BatchSize(batchSize);
    }

    function setBatchCount(uint256 _batchCount) public onlyOwner {
        batchCount = _batchCount;

        emit BatchCount(batchCount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setAddressesToAllowList(address[] memory _addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowList[_addresses[i]] = true;
        }

        emit AddToAllowList(_addresses);
    }

    function removeAddressFromAllowList(address _address) public onlyOwner {
        allowList[_address] = false;
        emit RemoveFromAllowList(_address);
    }
}