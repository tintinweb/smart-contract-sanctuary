// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './INiftyNafty.sol';
import './INiftyNaftyMetadata.sol';

contract NiftyNafty is ERC721Enumerable, Ownable, INiftyNafty, INiftyNaftyMetadata {
    using Strings for uint256;

    uint256 public constant CP_GIFT = 1000;
    uint256 public CP_PUBLIC = 8999;
    uint256 public CP_MAX = 9999;
    uint256 public constant PURCHASE_LIMIT = 3;
    uint256 public PRICE = 0.05 ether;

    bool public isActive = false;
    bool public isAllowListActive = false;
    string public proof;

    uint256 public allowListMaxMint = 3;

    uint256 public totalGiftSupply;
    uint256 public totalPublicSupply;
    uint256 public startDate;

    address[] private _ownersList;

    mapping(address => bool) private _allowList;
    mapping(uint256 => address) private _minters;
    mapping(address => uint256) private _claimed;

    string private _contractURI = '';
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function updateOwnersList(address[] calldata addresses) external override onlyOwner {
        require(_ownersList.length == 0, "You can update the list of owners once");
        _ownersList = addresses;
    }

    function onOwnersList(address addr) external view override returns (bool) {
        for(uint i = 0; i < _ownersList.length; i++) {
            if (_ownersList[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function addToAllowList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _allowList[addresses[i]] = true;
            _claimed[addresses[i]] > 0 ? _claimed[addresses[i]] : 0;
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

    function setPrice(uint256 newPrice) external override onlyOwner {
        PRICE = newPrice;
    }

    function setMaxTotalSupply(uint256 newCount) external override onlyOwner {
        CP_MAX = newCount;
        CP_PUBLIC = newCount - CP_GIFT;
    }

    function setStartDate(uint256 newDate) external override onlyOwner {
        startDate = newDate;

        for (uint256 i = 0; i < totalPublicSupply; i++) {
            if (_minters[i] != address(0)) {
                _claimed[_minters[i]] = 0;
            }
        }
    }

    function claimedBy(address owner) external view override returns (uint256){
        require(owner != address(0), "Can't check the null address");
        return _claimed[owner];
    }

    function purchase(uint256 numberOfTokens) external override payable {
        require(block.timestamp > startDate, 'Sale not started');
        require(isActive, 'Contract is not active');
        if (isAllowListActive) {
            require(_allowList[msg.sender], 'You are not on the Allow List');
        }
        require(_claimed[msg.sender] + numberOfTokens <= allowListMaxMint, 'Purchase exceeds max allowed');
        require(totalSupply() < CP_MAX, 'All tokens have been minted');
        require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');
        require(totalPublicSupply < CP_PUBLIC, 'Purchase would exceed CP_PUBLIC');
        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalPublicSupply < CP_PUBLIC) {
                uint256 tokenId = CP_GIFT + totalPublicSupply + 1;

                _claimed[msg.sender] += 1;
                _minters[totalPublicSupply] = msg.sender;
                totalPublicSupply += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function gift(address[] calldata to) external override onlyOwner {
        require(totalSupply() < CP_MAX, 'All tokens have been minted');
        require(totalGiftSupply + to.length <= CP_GIFT, 'Not enough tokens left to gift');

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
        require(_ownersList.length > 0, "Can't withdraw where owners list empty");
        uint256 part = address(this).balance / _ownersList.length;
        for(uint256 i = 0; i < _ownersList.length; i++) {
            payable(_ownersList[i]).transfer(part);
        }
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

        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return bytes(revealedBaseURI).length > 0 ?
            string(abi.encodePacked(revealedBaseURI, tokenId.toString(), '.json')) :
            _tokenBaseURI;
    }
}