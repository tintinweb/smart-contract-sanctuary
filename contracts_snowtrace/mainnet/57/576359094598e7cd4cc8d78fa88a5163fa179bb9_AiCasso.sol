// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './IAiCassoMetadata.sol';
import './IAiCassoNFTStaking.sol';

contract AiCasso is ERC721Enumerable, Ownable, IAiCassoMetadata {
    using Strings for uint256;

    uint256 public constant AIC_PUBLIC = 10_000;
    uint256 public constant AIC_GENERATOR = 10_000;
    uint256 public constant PURCHASE_LIMIT = 10;

    uint256 public PRICE = 1 ether;
    uint256 public WHITELIST_PRICE = 0.95 ether;

    bool public isActive = false;
    string public proof;

    uint256 public totalGiftSupply;
    uint256 public totalPublicSupply;
    uint256 public totalGeneratorSupply;

    mapping(address => bool) private _allowList;
    mapping(uint256 => string) private _generatorImage;

    string private _contractURI = '';
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';

    address private _generator;
    address private _stake;
    IAiCassoNFTStaking private _stakeContract;

    modifier onlyGenerator() {
        require(_generator == msg.sender);
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function setGeneratorContract(address generator) external onlyOwner {
        require(generator != address(0), "Can't add the null address");
        _generator = generator;
    }

    function setPrice(uint256 _price, uint256 _wl_price) external onlyOwner {
        require(_price >= 0.01 ether);
        require(_wl_price >= 0.01 ether);
        PRICE = _price;
        WHITELIST_PRICE = _wl_price;
    }

    function setStakeContract(address stakeContract) external onlyOwner {
        require(stakeContract != address(0), "Can't add the null address");
        _stake = stakeContract;
        _stakeContract = IAiCassoNFTStaking(stakeContract);
    }

    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _allowList[addresses[i]] = true;
        }
    }

    function onAllowList(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    function _getPrice(address addr) private view returns (uint256) {
        return _allowList[addr] ? WHITELIST_PRICE : PRICE;
    }

    function removeFromAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _allowList[addresses[i]] = false;
        }
    }

    function stake(uint256 numberOfTokens) external {
        require(_stake != address(0), 'Stake is not active');
        require(numberOfTokens <= balanceOf(_msgSender()));

        uint[] memory _tokenIds = new uint[](numberOfTokens);
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIds[i] = tokenOfOwnerByIndex(_msgSender(), i);
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _stakeContract.stake(_tokenIds[i], _msgSender());
            safeTransferFrom(_msgSender(), _stake, _tokenIds[i]);
        }
    }

    function mintGenerator(string memory ipfs, address buyer) external onlyGenerator {
        require(_generator != address(0), 'Generator is not active');
        require(isActive, 'Contract is not active');
        require(totalGeneratorSupply < AIC_GENERATOR, 'All tokens have been minted');

        uint256 tokenId = AIC_PUBLIC + totalGeneratorSupply + 1;
        totalGeneratorSupply += 1;
        _generatorImage[tokenId] = ipfs;
        _safeMint(buyer, tokenId);
    }

    function purchase(uint256 numberOfTokens) external payable {
        require(isActive, 'Contract is not active');
        require(totalSupply() < AIC_PUBLIC, 'All tokens have been minted');
        require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');
        require(totalPublicSupply < AIC_PUBLIC, 'Purchase would exceed AIC_PUBLIC');
        require(_getPrice(msg.sender) * numberOfTokens <= msg.value, 'AVAX amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalPublicSupply < AIC_PUBLIC) {
                uint256 tokenId = totalPublicSupply + 1;
                totalPublicSupply += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function setIsActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function setProof(string calldata proofString) external onlyOwner {
        proof = proofString;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setContractURI(string calldata URI) external override onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external override onlyOwner {
        _tokenBaseURI = URI;
    }

    function setRevealedBaseURI(string calldata revealedBaseURI) external override onlyOwner {
        _tokenRevealedBaseURI = revealedBaseURI;
    }

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');

        if (tokenId > AIC_PUBLIC) {
            return string(abi.encodePacked('ipfs://', _generatorImage[tokenId]));
        }

        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return bytes(revealedBaseURI).length > 0 ?
        string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
        _tokenBaseURI;
    }
}