// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './IUniCorn.sol';
import './IUniCornMetadata.sol';

contract UniCorn is ERC721Enumerable, Ownable, IUniCorn, IUniCornMetadata {
    using Strings for uint256;

    uint256 public constant UNI_GIFT = 100;
    uint256 public constant UNI_PUBLIC = 4_100;
    uint256 public constant UNI_MAX = UNI_GIFT + UNI_PUBLIC;
    uint256 public constant PURCHASE_LIMIT = 10;
    uint256 public constant PRICE = 0.12 ether;

    bool public isActive = false;
    bool public isAllowListActive = false;
    string public proof;

    uint256 public allowListMaxMint = 2;

    /// @dev We will use these to be able to calculate remaining correctly.
    uint256 public totalGiftSupply;
    uint256 public totalPublicSupply;

    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _allowListClaimed;

    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function addToAllowList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _allowList[addresses[i]] = true;
            /**
            * @dev We don't want to reset _allowListClaimed count
            * if we try to add someone more than once.
            */
            _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
        }
    }

    function onAllowList(address addr) external view override returns (bool) {
        return _allowList[addr];
    }

    function removeFromAllowList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            /// @dev We don't want to reset possible _allowListClaimed numbers.
            _allowList[addresses[i]] = false;
        }
    }

    /**
    * @dev We want to be able to distinguish tokens bought during isAllowListActive
    * and tokens bought outside of isAllowListActive
    */
    function allowListClaimedBy(address owner) external view override returns (uint256){
        require(owner != address(0), 'Zero address not on Allow List');

        return _allowListClaimed[owner];
    }

    function purchase(uint256 numberOfTokens) external override payable {
        require(isActive, 'Contract is not active');
        require(!isAllowListActive, 'Only allowing from Allow List');
        require(totalSupply() < UNI_MAX, 'All tokens have been minted');
        require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');
        /**
        * @dev The last person to purchase might pay too much.
        * This way however they can't get sniped.
        * If this happens, we'll refund the Eth for the unavailable tokens.
        */
        require(totalPublicSupply < UNI_PUBLIC, 'Purchase would exceed UNI_PUBLIC');
        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            /**
            * @dev Since they can get here while exceeding the UNI_MAX,
            * we have to make sure to not mint any additional tokens.
            */
            if (totalPublicSupply < UNI_PUBLIC) {
                /**
                * @dev Public token numbering starts after UNI_GIFT.
                * And we don't want our tokens to start at 0 but at 1.
                */
                uint256 tokenId = UNI_GIFT + totalPublicSupply + 1;

                totalPublicSupply += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function purchaseAllowList(uint256 numberOfTokens) external override payable {
        require(isActive, 'Contract is not active');
        require(isAllowListActive, 'Allow List is not active');
        require(_allowList[msg.sender], 'You are not on the Allow List');
        require(totalSupply() < UNI_MAX, 'All tokens have been minted');
        require(numberOfTokens <= allowListMaxMint, 'Cannot purchase this many tokens');
        require(totalPublicSupply + numberOfTokens <= UNI_PUBLIC, 'Purchase would exceed UNI_PUBLIC');
        require(_allowListClaimed[msg.sender] + numberOfTokens <= allowListMaxMint, 'Purchase exceeds max allowed');
        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            /**
            * @dev Public token numbering starts after UNI_GIFT.
            * We don't want our tokens to start at 0 but at 1.
            */
            uint256 tokenId = UNI_GIFT + totalPublicSupply + 1;

            totalPublicSupply += 1;
            _allowListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function gift(address[] calldata to) external override onlyOwner {
        require(totalSupply() < UNI_MAX, 'All tokens have been minted');
        require(totalGiftSupply + to.length <= UNI_GIFT, 'Not enough tokens left to gift');

        for(uint256 i = 0; i < to.length; i++) {
            /// @dev We don't want our tokens to start at 0 but at 1.
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

    function setBaseURI(string calldata URI) external override onlyOwner {
        _tokenBaseURI = URI;
    }

    function setRevealedBaseURI(string calldata revealedBaseURI) external override onlyOwner {
        _tokenRevealedBaseURI = revealedBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');

        /// @dev Convert string to bytes so we can check if it's empty or not.
        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return bytes(revealedBaseURI).length > 0 ?
        string(abi.encodePacked(revealedBaseURI, tokenId.toString(), ".json")) :
        _tokenBaseURI;
    }
}