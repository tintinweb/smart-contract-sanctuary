// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './ERC721.sol';
import './Ownable.sol';
import './Strings.sol';
import './IWoG.sol';
import './IWoGMetadata.sol';

contract WoG is ERC721, ERC721Enumerable, Ownable, IWoG, IWoGMetadata {
    using Strings for uint256;

    uint256 public constant WG_GIFT = 103;
    uint256 public WG_PUBLIC = 10_022;
    uint256 public constant PURCHASE_LIMIT = 5;
    uint256 public constant PRICE = 260 ether;
    uint256 public constant PRESALE_PRICE = 220 ether;

    uint256[21] reserved = [
    uint256(1), uint256(9), uint256(54), uint256(181),
    uint256(190), uint256(247), uint256(273), uint256(329),
    uint256(338), uint256(380), uint256(500), uint256(674), uint256(1266),
    uint256(1300), uint256(2816), uint256(3805), uint256(3987),
    uint256(5141), uint256(7407), uint256(9975), uint256(9987)
    ];

    bool public isActive = false;
    bool public isAllowListActive = false;
    string public proof;

    uint256 public totalGiftSupply = 1;
    uint256 public totalPublicSupply;
    uint256 public totalCustomSupply;

    mapping(address => bool) private _allowList;

    string private _contractURI = '';
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = 'ipfs://QmVuGKDLbRGNunXa4fnR5dT1u5B9g4JNgn1N1a12VWELoA/';

    mapping(uint256 => string) private customCID;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        for (uint d = 0; d < reserved.length; d++) {
            _safeMint(msg.sender, reserved[d]);
        }
    }

    function addToAllowList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _allowList[addresses[i]] = true;
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

    function mintCustomNFT(string calldata _cid, address recipient) external onlyOwner {
        require(recipient != address(0), "Can't add the null address");
        uint256 tokenId = WG_PUBLIC + totalCustomSupply + 1;
        customCID[tokenId] = _cid;
        totalCustomSupply += 1;
        _safeMint(recipient, tokenId);
    }

    function purchase(uint256 numberOfTokens) external override payable {
        require(isActive, 'Contract is not active');
        require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');
        require(totalPublicSupply < WG_PUBLIC, 'All tokens have been minted');
        if (isAllowListActive) {
            require(_allowList[msg.sender], 'You are not on the Allow List');
            require(PRESALE_PRICE * numberOfTokens <= msg.value, 'MATIC amount is not sufficient');
        } else {
            require(PRICE * numberOfTokens <= msg.value, 'MATIC amount is not sufficient');
        }
        require(msg.sender == tx.origin, "No transaction from smart contracts!");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalPublicSupply < WG_PUBLIC) {
                uint256 tokenId = WG_GIFT + totalPublicSupply + 1;

                if(_reserved(tokenId)) {
                    totalPublicSupply += 1;
                    tokenId += 1;
                }

                totalPublicSupply += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function gift(address[] calldata to) external override onlyOwner {
        require(totalSupply() < WG_PUBLIC, 'All tokens have been minted');
        require(totalGiftSupply + to.length <= WG_GIFT, 'Not enough tokens left to gift');

        for(uint256 i = 0; i < to.length; i++) {
            uint256 tokenId = totalGiftSupply + 1;

            if(_reserved(tokenId)) {
                totalGiftSupply += 1;
                tokenId += 1;
            }

            totalGiftSupply += 1;
            _safeMint(to[i], tokenId);
        }
    }

    function flipSaleState() external onlyOwner
    {
        isActive = !isActive;
    }

    function flipAllowListState() external onlyOwner
    {
        isAllowListActive = !isAllowListActive;
    }

    function setProof(string calldata proofString) external override onlyOwner {
        proof = proofString;
    }

    function withdraw() external override onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
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
        if (tokenId > WG_PUBLIC) {
            return string(abi.encodePacked('ipfs://', customCID[tokenId]));
        }
        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return bytes(revealedBaseURI).length > 0 ?
        string(abi.encodePacked(revealedBaseURI, tokenId.toString(), '.json')) :
        _tokenBaseURI;
    }

    function _reserved(uint256 tokenId) internal view virtual returns (bool) {
        for (uint d = 0; d < reserved.length; d++) {
            if(reserved[d] == tokenId){
                return true;
            }
        }
        return false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view
    override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}