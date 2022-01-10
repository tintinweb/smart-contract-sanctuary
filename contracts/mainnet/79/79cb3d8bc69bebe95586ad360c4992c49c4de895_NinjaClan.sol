// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NinjaClan is ERC721Enumerable, Ownable {
    uint256 public mintPrice = 0.25 ether;
    uint256 public presalePrice = 0.2 ether;
    uint256 public privateSalePrice = 0.125 ether;

    uint256 private reserveAtATime = 52;
    uint256 private reservedCount = 0;
    uint256 private maxReserveCount = 156;

    string _baseTokenURI;

    bool public isActive = false;
    bool public isPrivateSaleActive = false;
    bool public isPreSaleActive = false;

    uint256 public maximumMintSupply = 5555;
    uint256 public maximumAllowedTokensPerPurchase = 5;
    uint256 public maximumAllowedTokensPerWallet = 11;
    uint256 public allowListMaxMint = 6;
    uint256 public privateListMaxMint = 3;

    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _allowListClaimed;

    event AssetMinted(uint256 tokenId, address sender);
    event SaleActivation(bool isActive);

    constructor(string memory baseURI) ERC721("Ninja Clan", "NC") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen {
        require(totalSupply() <= maximumMintSupply, "Sale has ended.");
        _;
    }

    modifier onlyAuthorized() {
        require(owner() == msg.sender);
        _;
    }

    function setMaximumAllowedTokens(uint256 _count) public onlyAuthorized {
        maximumAllowedTokensPerPurchase = _count;
    }

    function setMaximumAllowedTokensPerWallet(uint256 _count) public onlyAuthorized {
        maximumAllowedTokensPerWallet = _count;
    }

    function setActive(bool val) public onlyAuthorized {
        isActive = val;
        emit SaleActivation(val);
    }

    function setMaxMintSupply(uint256 maxMintSupply) external  onlyAuthorized {
        maximumMintSupply = maxMintSupply;
    }

    function setPresaleActive(bool _isAllowListActive) external onlyAuthorized {
        isPreSaleActive = _isAllowListActive;
    }

    function setPrivateSale(bool _isPrivateSaleActive) external onlyAuthorized {
        isPrivateSaleActive = _isPrivateSaleActive;
    }

    function setAllowListMaxMint(uint256 maxMint) external  onlyAuthorized {
        allowListMaxMint = maxMint;
    }

    function setPrivateListMaxMint(uint256 _privateListMaxMint) external  onlyAuthorized {
        privateListMaxMint = _privateListMaxMint;
    }

    function addToAllowList(address[] calldata addresses) external onlyAuthorized {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add a null address");
            _allowList[addresses[i]] = true;
            _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
        }
    }

    function checkIfOnAllowList(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    function removeFromAllowList(address[] calldata addresses) external onlyAuthorized {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add a null address");
            _allowList[addresses[i]] = false;
        }
    }

    function allowListClaimedBy(address owner) external view returns (uint256){
        require(owner != address(0), 'Zero address not on Allow List');
        return _allowListClaimed[owner];
    }

    function setReserveAtATime(uint256 val) public onlyAuthorized {
        reserveAtATime = val;
    }

    function setMaxReserve(uint256 val) public onlyAuthorized {
        maxReserveCount = val;
    }

    function setPrice(uint256 _price) public onlyAuthorized {
        mintPrice = _price;
    }

    function setPresalePrice(uint256 _price) public onlyAuthorized {
        presalePrice = _price;
    }

    function setPrivateSalePrice(uint256 _price) public onlyAuthorized {
        privateSalePrice = _price;
    }

    function setBaseURI(string memory baseURI) public onlyAuthorized {
        _baseTokenURI = baseURI;
    }

    function getReserveAtATime() external view returns (uint256) {
        return reserveAtATime;
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function getContractOwner() public view returns (address) {
        return owner();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function reserveNft() public onlyAuthorized {
        require(reservedCount <= maxReserveCount, "Max Reserves taken already!");
        uint256 supply = totalSupply();
        uint256 i;

        for (i = 0; i < reserveAtATime; i++) {
            emit AssetMinted(supply + i, msg.sender);
            _safeMint(msg.sender, supply + i);
            reservedCount++;
        }
    }

    function reserveToCustomWallet(address _walletAddress, uint256 _count) public onlyAuthorized {
        for (uint256 i = 0; i < _count; i++) {
            emit AssetMinted(totalSupply(), _walletAddress);
            _safeMint(_walletAddress, totalSupply());
        }
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        if (msg.sender != owner()) {
            require(isActive, "Sale is not active currently.");
        }

        if(_to != owner()) {
            require(balanceOf(_to) + _count <= maximumAllowedTokensPerWallet, "Max holding cap reached.");
        }

        require(totalSupply() + _count <= maximumMintSupply, "Total supply exceeded.");
        require(totalSupply() <= maximumMintSupply, "Total supply spent.");
        require(
            _count <= maximumAllowedTokensPerPurchase,
            "Exceeds maximum allowed tokens"
        );

        require(msg.value >= mintPrice * _count, "Insuffient ETH amount sent.");

        for (uint256 i = 0; i < _count; i++) {
            emit AssetMinted(totalSupply(), _to);
            _safeMint(_to, totalSupply());
        }
    }

    function privateMint(uint256 _count) public payable saleIsOpen {
        if(!isPrivateSaleActive && !isPreSaleActive) {
            require(isPreSaleActive, 'Sale is not active');
        }

        require(_allowList[msg.sender], 'You are not on the Allow List');

        if(isPreSaleActive) {
            require(_count <= allowListMaxMint, 'Cannot purchase this many tokens');
            require(_allowListClaimed[msg.sender] + _count <= allowListMaxMint, 'Purchase exceeds max allowed');
            require(msg.value >= presalePrice * _count, 'Insufficient ETH amount sent.');
        }

        if(isPrivateSaleActive) {
            require(_count <= privateListMaxMint, 'Cannot purchase this many tokens');
            require(_allowListClaimed[msg.sender] + _count <= privateListMaxMint, 'Purchase exceeds max allowed');
            require(msg.value >= privateSalePrice * _count, 'Insufficient ETH amount sent.');
        }

        for (uint256 i = 0; i < _count; i++) {
            _allowListClaimed[msg.sender] += 1;
            emit AssetMinted(totalSupply(), msg.sender);
            _safeMint(msg.sender, totalSupply());
        }
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() external onlyAuthorized {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}