// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './ICryptoPlush.sol';
import './ICryptoPlushMetadata.sol';

contract CryptoPlush is ERC721Enumerable, Ownable, ICryptoPlush, ICryptoPlushMetadata {
    using Strings for uint256;

    address public constant CP_PARTNER = 0x8C48E7e19dACb3E63b1F00fFe767eB1FB56081c4;
    uint256 public constant CP_GIFT = 86;
    uint256 public CP_PUBLIC = 300;
    uint256 public constant CP_MAX = 5000;
    uint256 public constant PURCHASE_LIMIT = 20;
    uint256 public PRICE = 0.05 ether;

    uint256[16] reserved = [
        uint256(134), uint256(189), uint256(119), uint256(144), uint256(111), uint256(136), uint256(10), uint256(2),
        uint256(1129), uint256(579), uint256(965), uint256(1304), uint256(3882), uint256(2519), uint256(4284), uint256(4693)
    ];

    bool public isActive = false;
    bool public isAllowListActive = false;
    string public proof;

    uint256 public allowListMaxMint = 20;

    uint256 public totalGiftSupply;
    uint256 public totalPublicSupply;

    mapping(address => bool) private _allowList;
    mapping(uint256 => address) private _minters;
    mapping(address => uint256) private _allowListClaimed;
    mapping(uint256 => uint) private _mintedAt;

    string private _contractURI = '';
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

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

    function setPrice(uint256 newPrice) external override onlyOwner {
        PRICE = newPrice;
    }

    function setCountNFT(uint256 newCount) external override onlyOwner {
        require(newCount <= CP_MAX, 'Too much value');
        CP_PUBLIC = newCount;

        for (uint256 i = 0; i < totalPublicSupply; i++) {
            if (_minters[i] != address(0)) {
                _allowListClaimed[_minters[i]] = 0;
            }
        }
    }

    function allowListClaimedBy(address owner) external view override returns (uint256){
        require(owner != address(0), 'Zero address not on Allow List');

        return _allowListClaimed[owner];
    }

    function purchase(uint256 numberOfTokens) external override payable {
        require(isActive, 'Contract is not active');
        if (isAllowListActive) {
            require(_allowList[msg.sender], 'You are not on the Allow List');
        }
        require(_allowListClaimed[msg.sender] + numberOfTokens <= allowListMaxMint, 'Purchase exceeds max allowed');
        require(totalSupply() < CP_MAX, 'All tokens have been minted');
        require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');
        require(totalPublicSupply < CP_PUBLIC, 'Purchase would exceed CP_PUBLIC');
        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalPublicSupply < CP_PUBLIC) {
                uint256 tokenId = CP_GIFT + totalPublicSupply + 1;

                if(_reserved(tokenId)) {
                    totalPublicSupply += 1;
                    tokenId += 1;
                }

                _allowListClaimed[msg.sender] += 1;
                _minters[totalPublicSupply] = msg.sender;
                _mintedAt[tokenId] = block.timestamp;
                totalPublicSupply += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function purchaseAllowList(uint256 numberOfTokens) external override payable {
        require(isActive, 'Contract is not active');
        require(isAllowListActive, 'Allow List is not active');
        require(_allowList[msg.sender], 'You are not on the Allow List');
        require(totalSupply() < CP_MAX, 'All tokens have been minted');

        require(numberOfTokens <= allowListMaxMint, 'Cannot purchase this many tokens');
        require(totalPublicSupply + numberOfTokens <= CP_PUBLIC, 'Purchase would exceed CP_PUBLIC');
        require(_allowListClaimed[msg.sender] + numberOfTokens <= allowListMaxMint, 'Purchase exceeds max allowed');

        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = CP_GIFT + totalPublicSupply + 1;

            if(_reserved(tokenId)) {
                totalPublicSupply += 1;
                tokenId += 1;
            }

            _allowListClaimed[msg.sender] += 1;
            _minters[totalPublicSupply] = msg.sender;
            _mintedAt[tokenId] = block.timestamp;
            totalPublicSupply += 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function gift(address[] calldata to) external override onlyOwner {
        require(totalSupply() < CP_MAX, 'All tokens have been minted');
        require(totalGiftSupply + to.length <= CP_GIFT, 'Not enough tokens left to gift');

        for(uint256 i = 0; i < to.length; i++) {
            uint256 tokenId = totalGiftSupply + 1;

            if(_reserved(tokenId)) {
                totalGiftSupply += 1;
                tokenId += 1;
            }

            totalGiftSupply += 1;
            _mintedAt[tokenId] = block.timestamp;
            _safeMint(to[i], tokenId);
        }
    }

    function giftReserve(address to, uint256 tokenId) external onlyOwner {
        require(_owners[tokenId] == address(0), 'This token have been minted');
        require(_reserved(tokenId), 'This token is not reserved');

        _mintedAt[tokenId] = block.timestamp;
        _safeMint(to, tokenId);
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

        uint _totalOwners = 0;

        address[] memory _holders = new address[](totalPublicSupply);

        for(uint256 i = 1; i < totalPublicSupply + 1; i++) {
            if (_owners[i] != address(0)) {
                bool find = false;
                for(uint256 d = 0; d < _totalOwners; d++) {
                    if (_holders[d] == _owners[i]) {
                        find = true;
                        break;
                    }
                }
                if (!find) {
                    _holders[_totalOwners] = _owners[i];
                    _totalOwners += 1;
                }
            }
        }

        uint256 partner = balance / 5; // 20% to partner
        uint256 distribution = balance / 10; // 10% to holders
        balance -= partner;
        payable(CP_PARTNER).transfer(partner);

        if (_totalOwners > 0) {
            uint256 oneDistribution = distribution / _totalOwners;
            balance -= distribution;

            for(uint256 i = 0; i < _totalOwners; i++) {
                distribution -= oneDistribution;
                payable(_holders[i]).transfer(oneDistribution);
            }
            balance += distribution;
        }

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

        if (block.timestamp >= _mintedAt[tokenId] + 7 days) {
            string memory revealedBaseURI = _tokenRevealedBaseURI;
            return bytes(revealedBaseURI).length > 0 ?
            string(abi.encodePacked(revealedBaseURI, tokenId.toString(), '.json')) :
            _tokenBaseURI;
        }

        return _tokenBaseURI;
    }

    function _reserved(uint256 tokenId) internal view virtual returns (bool) {
        for (uint d = 0; d < reserved.length; d++) {
            if(reserved[d] == tokenId){
                return true;
            }
        }
        return false;
    }
}