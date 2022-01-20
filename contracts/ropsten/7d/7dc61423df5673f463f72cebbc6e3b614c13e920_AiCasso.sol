// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './IAiCasso.sol';
import './IAiCassoMetadata.sol';
import './IAiCassoNFTStaking.sol';

contract AiCasso is ERC721Enumerable, Ownable, IAiCasso, IAiCassoMetadata {
    using Strings for uint256;

    uint256 public constant AIC_GIFT = 0;
    uint256 public constant AIC_PUBLIC = 3_000;
    uint256 public AIC_GENERATOR = 10_000;
    uint256 public constant AIC_MAX = AIC_GIFT + AIC_PUBLIC;
    uint256 public constant PURCHASE_LIMIT = 10;
    uint256 public constant PRICE = 0.5 ether;

    bool public isActive = false;
    bool public isAllowListActive = false;
    string public proof;

    uint256 public allowListMaxMint = 1;

    uint256 public totalGiftSupply;
    uint256 public totalPublicSupply;
    uint256 public totalGeneratorSupply;

    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _allowListClaimed;
    mapping(uint256 => string) private _generatorImage;

    string private _contractURI = '';
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';

    address private _generator;
    IAiCassoNFTStaking private _stake;

    modifier onlyGenerator() {
        require(_generator == msg.sender);
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function setGeneratorContract(address generator) external override onlyOwner {
        require(generator != address(0), "Can't add the null address");
        _generator = generator;
    }

    function setStakeContract(address stakeContract) external override onlyOwner {
        require(stakeContract != address(0), "Can't add the null address");
        _stake = IAiCassoNFTStaking(stakeContract);
    }

    function addToAllowList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _allowList[addresses[i]] = true;
            _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
        }
    }

    function onAllowList(address addr) external view override returns (bool) {
        return _allowList[addr];
    }

    function removeFromAllowList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _allowList[addresses[i]] = false;
        }
    }

    function allowListClaimedBy(address owner) external view override returns (uint256){
        require(owner != address(0), 'Zero address not on Allow List');
        return _allowListClaimed[owner];
    }

    function stake(uint256 numberOfTokens) external override {
        require(address(_stake) != address(0), 'Stake is not active');
        require(numberOfTokens <= balanceOf(_msgSender()));

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 _tokenId = tokenOfOwnerByIndex(_msgSender(), i);
            _stake.stake(_tokenId, _msgSender());
            _transfer(_msgSender(), address(_stake), _tokenId);
        }
    }

    function mintGenerator(string memory ipfs, address buyer) external override onlyGenerator {
        require(isActive, 'Contract is not active');
        require(totalGeneratorSupply < AIC_GENERATOR, 'All tokens have been minted');

        uint256 tokenId = AIC_MAX + totalGeneratorSupply + 1;
        totalGeneratorSupply += 1;
        _generatorImage[tokenId] = ipfs;
        _safeMint(buyer, tokenId);
    }

    function purchase(uint256 numberOfTokens) external override payable {
        require(isActive, 'Contract is not active');
        require(!isAllowListActive, 'Only allowing from Allow List');
        require(totalSupply() < AIC_MAX, 'All tokens have been minted');
        require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');
        require(totalPublicSupply < AIC_PUBLIC, 'Purchase would exceed AIC_PUBLIC');
        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalPublicSupply < AIC_PUBLIC) {
                uint256 tokenId = AIC_GIFT + totalPublicSupply + 1;
                totalPublicSupply += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function purchaseAllowList(uint256 numberOfTokens) external override payable {
        require(isActive, 'Contract is not active');
        require(isAllowListActive, 'Allow List is not active');
        require(_allowList[msg.sender], 'You are not on the Allow List');
        require(totalSupply() < AIC_MAX, 'All tokens have been minted');
        require(numberOfTokens <= allowListMaxMint, 'Cannot purchase this many tokens');
        require(totalPublicSupply + numberOfTokens <= AIC_PUBLIC, 'Purchase would exceed AIC_PUBLIC');
        require(_allowListClaimed[msg.sender] + numberOfTokens <= allowListMaxMint, 'Purchase exceeds max allowed');
        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = AIC_GIFT + totalPublicSupply + 1;
            totalPublicSupply += 1;
            _allowListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function gift(address[] calldata to) external override onlyOwner {
        require(totalSupply() < AIC_MAX, 'All tokens have been minted');
        require(totalGiftSupply + to.length <= AIC_GIFT, 'Not enough tokens left to gift');

        for(uint256 i = 0; i < to.length; i++) {
            uint256 tokenId = totalGiftSupply + 1;
            totalGiftSupply += 1;
            _safeMint(to[i], tokenId);
        }
    }

    function setIsActive(bool _isActive) external override onlyOwner {
        isActive = _isActive;
    }

    function setIsAllowListActive(bool _isAllowListActive) external override onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowListMaxMint(uint256 maxMint) external override onlyOwner {
        allowListMaxMint = maxMint;
    }

    function setProof(string calldata proofString) external override onlyOwner {
        proof = proofString;
    }

    function withdraw() external override onlyOwner {
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

        if (tokenId > AIC_MAX) {
            return string(abi.encodePacked('ipfs://', _generatorImage[tokenId]));
        }

        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return bytes(revealedBaseURI).length > 0 ?
        string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
        _tokenBaseURI;
    }
}