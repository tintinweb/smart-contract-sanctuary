// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";
import "./Strings.sol";
import "./Mintable.sol";

contract Pigtograph is ERC721, ERC721Enumerable, Ownable, Mintable {
    using Counters for Counters.Counter;
    string public baseURI;
    Counters.Counter private _tokenIdCounter;

    // Where funds should be sent to
    address payable public fundsTo;

    // Maximum supply of the NFT
    uint256 public maxSupply;

    // Maximum mints per transaction
    uint256 public maxPerTx;

    // Is sale on?
    bool public sale;

    // Sale price
    uint256 public pricePer;
    uint256 public pricePerPre;
    uint256 public maxPreMint;
    uint256 public maxWallet = 5;
    uint256 public totalSupplied = 0;
    bool public presale = false;
    mapping(address => bool) userAddr;
    mapping(address => uint256) public minted; // To check how many tokens an address has minted
    mapping(address => uint256) public mintedLog; // To check how many tokens an address has minted
    event Deposit(address indexed _from, uint256 _value, uint256 _nfcount);

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
        minted[user] += 1;
    }

    constructor(
        address _owner,
        address _imx,
        address payable fundsTo_,
        uint256 maxSupply_,
        uint256 maxPerTx_,
        uint256 pricePer_,
        uint256 pricePerPre_
    ) ERC721("Pigtograph", "PIGTO") Mintable(_owner, _imx) {
        imx = _imx;
        require(_owner != address(0), "Owner must not be empty");
        transferOwnership(_owner);
        fundsTo = fundsTo_;
        maxSupply = maxSupply_;
        maxPerTx = maxPerTx_;
        sale = false;
        pricePer = pricePer_;
        pricePerPre = pricePerPre_;
    }

    function updateFundsTo(address payable newFundsTo) public onlyOwner {
        fundsTo = newFundsTo;
    }

    function switchOnSale() public onlyOwner {
        sale = true;
    }

    function claimBalance() public onlyOwner {
        (bool success, ) = fundsTo.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    function safeMintOwner(address to, uint256 quantity) public onlyOwner {
        require(quantity != 0, "Requested quantity cannot be zero");
        // Cannot mint more than maximum
        require(quantity <= maxPerTx, "Requested quantity more than maximum");
        // Transaction must have at least quantity * price (any more is considered a tip)
        require(
            super.totalSupply() + quantity <= maxSupply,
            "Total supply will exceed limit"
        );

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
        minted[to] += quantity;
    }

    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    function setMaxPreMint(uint256 __maxPreMint) external onlyOwner {
        maxPreMint = __maxPreMint;
    }

    function setMaxPerTX(uint256 __maxPerTX) external onlyOwner {
        maxPerTx = __maxPerTX;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function flipSaleState() public onlyOwner {
        sale = !sale;
    }

    function flipPresaleState() public onlyOwner {
        presale = !presale;
    }

    function setMaxWallet(uint256 _newMaxWallet) external onlyOwner {
        maxWallet = _newMaxWallet;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setPrePrice(uint256 prePrice_) external onlyOwner {
        pricePerPre = prePrice_;
    }

    function setPostPrice(uint256 postPrice_) external onlyOwner {
        pricePer = postPrice_;
    }

    function _preMintPrice() public view returns (uint256) {
        return pricePerPre;
    }

    function _totalMintLog() public view returns (uint256) {
        return totalSupplied;
    }

    function _salePrice() public view returns (uint256) {
        return pricePer;
    }

    function checkTokenExists(uint256 tokenId) public view returns (bool) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return true;
    }

    function transfer(uint256 quantity) external payable {
        // Sale must NOT be enabled
        require(sale, "Sale already in progress");
        require(quantity != 0, "Requested quantity cannot be zero");
        require(quantity <= maxPerTx, "Requested quantity more than maximum");
        require(quantity * pricePer <= msg.value, "Not enough ether sent");
        require(
            totalSupplied + quantity <= maxSupply,
            "Purchase would exceed max tokens for presale"
        );
        require(
            mintedLog[msg.sender] + quantity <= maxWallet,
            "Purchase would exceed max tokens per wallet"
        );
        require(
            !Address.isContract(msg.sender),
            "Contracts are not allowed to mint"
        );
        totalSupplied += quantity;
        mintedLog[msg.sender] += quantity;
        emit Deposit(msg.sender, msg.value, quantity);
    }

    function transferPreSale(uint256 quantity) external payable {
        // Sale must NOT be enabled
        require(!sale, "Sale already in progress");
        require(presale, "Presale must be active");
        require(quantity != 0, "Requested quantity cannot be zero");
        require(quantity <= maxPerTx, "Requested quantity more than maximum");
        require(quantity * pricePerPre <= msg.value, "Not enough ether sent");
        require(
            totalSupplied + quantity <= maxPreMint,
            "Purchase would exceed max tokens for presale"
        );
        require(
            mintedLog[msg.sender] + quantity <= maxWallet,
            "Purchase would exceed max tokens per wallet"
        );
        require(
            !Address.isContract(msg.sender),
            "Contracts are not allowed to mint"
        );

        mintedLog[msg.sender] += quantity;
        totalSupplied += quantity;
        emit Deposit(msg.sender, msg.value, quantity);
    }
}