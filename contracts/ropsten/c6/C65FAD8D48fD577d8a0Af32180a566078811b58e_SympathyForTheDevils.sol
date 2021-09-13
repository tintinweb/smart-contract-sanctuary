// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";

contract SympathyForTheDevils is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public constant MAX_MINTS_PER_TXN = 16;

    uint256 public mintPrice = 66600000 gwei; // 0.0666 ETH

    bool public saleIsActive = false;

    bool public cookingIsActive = false;

    string public baseURI;

    string public provenance;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    address[3] private _shareholders;

    uint256[3] private _shares;

    address private _manager;

    // Mapping from token ID to the amount of claimable eth in gwei
    mapping(uint256 => uint256) private _claimableEth;

    event DevilCooked(
        uint256 firstTokenId,
        uint256 secondTokenId,
        uint256 cookedDevilTokenId
    );

    event PaymentReleased(address to, uint256 amount);

    event EthDeposited(uint256 amount);

    event EthClaimed(address to, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxDevilSupply
    ) ERC721(name, symbol) {
        maxTokenSupply = maxDevilSupply;

        _shareholders[0] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        _shareholders[1] = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
        _shareholders[2] = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;

        _shares[0] = 4000;
        _shares[1] = 3000;
        _shares[2] = 3000;
    }

    function setMaxTokenSupply(uint256 maxDevilSupply) public onlyOwner {
        maxTokenSupply = maxDevilSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function withdrawForGiveaway(uint256 amount, address payable to)
        public
        onlyOwner
    {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");

        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 3; i++) {
            uint256 payment = (amount * _shares[i]) / totalShares;

            Address.sendValue(payable(_shareholders[i]), payment);
            emit PaymentReleased(_shareholders[i], payment);
        }
    }

    /*
     * Mint reserved NFTs for giveaways, devs, etc.
     */
    function reserveMint(uint256 reservedAmount) public onlyOwner {
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(msg.sender, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
     * Mint reserved NFTs for giveaways, devs, etc.
     */
    function reserveMint(uint256 reservedAmount, address mintAddress)
        public
        onlyOwner
    {
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(mintAddress, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
     * Pause sale if active, make active if paused.
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
     * Pause cooking if active, make active if paused.
     */
    function flipCookingState() public onlyOwner {
        cookingIsActive = !cookingIsActive;
    }

    /*
     * Mint Devil NFTs, woo!
     */
    function mintDevils(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint devils");
        require(
            numberOfTokens <= MAX_MINTS_PER_TXN,
            "You can only mint 16 devils at a time"
        );
        require(
            totalSupply() + numberOfTokens <= maxTokenSupply,
            "Purchase would exceed max available devils"
        );
        require(
            mintPrice * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _safeMint(msg.sender, mintIndex);
                _tokenIdCounter.increment();
            }
        }

        // If we haven't set the starting index, set the starting index block.
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }
    }

    /*
     * Set the manager address for deposits.
     */
    function setManager(address manager) public onlyOwner {
        _manager = manager;
    }

    /**
     * @dev Throws if called by any account other than the owner or manager.
     */
    modifier onlyOwnerOrManager() {
        require(
            owner() == _msgSender() || _manager == _msgSender(),
            "Caller is not the owner or manager"
        );
        _;
    }

    /*
     * Deposit eth for distribution to token owners.
     */
    function deposit() public payable onlyOwnerOrManager {
        uint256 tokenCount = totalSupply();
        uint256 claimableAmountPerToken = msg.value / tokenCount;

        for (uint256 i = 0; i < tokenCount; i++) {
            // Iterate over all existing tokens (that have not been burnt)
            _claimableEth[tokenByIndex(i)] += claimableAmountPerToken;
        }

        emit EthDeposited(msg.value);
    }

    /*
     * Get the claimable balance of a token ID.
     */
    function claimableBalanceOfTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _claimableEth[tokenId];
    }

    /*
     * Get the total claimable balance for an owner.
     */
    function claimableBalance(address owner) public view returns (uint256) {
        uint256 balance = 0;
        uint256 numTokens = balanceOf(owner);

        for (uint256 i = 0; i < numTokens; i++) {
            balance += claimableBalanceOfTokenId(tokenOfOwnerByIndex(owner, i));
        }

        return balance;
    }

    function claim() public {
        uint256 amount = 0;
        uint256 numTokens = balanceOf(msg.sender);

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            amount += _claimableEth[tokenId];
            // Empty out all the claimed amount so as to protect against re-entrancy attacks.
            _claimableEth[tokenId] = 0;
        }

        require(amount > 0, "There is no amount left to claim");

        emit EthClaimed(msg.sender, amount);

        // We must transfer at the very end to protect against re-entrancy.
        Address.sendValue(payable(msg.sender), amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * Set the starting index for the collection.
     */
    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % maxTokenSupply;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (block.number - startingIndexBlock > 255) {
            startingIndex =
                uint256(blockhash(block.number - 1)) %
                maxTokenSupply;
        }
        // Prevent default sequence.
        if (startingIndex == 0) {
            startingIndex = 1;
        }
    }

    /**
     * Set the starting index block for the collection. Usually, this will be set after the first sale mint.
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }

    /*
     * Set provenance once it's calculated.
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
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

    function cookDevil(uint256 firstTokenId, uint256 secondTokenId) public {
        require(
            cookingIsActive && !saleIsActive,
            "Either sale is currently active or cooking is inactive"
        );
        require(
            _isApprovedOrOwner(_msgSender(), firstTokenId) &&
                _isApprovedOrOwner(_msgSender(), secondTokenId),
            "Caller is not owner nor approved"
        );

        // burn the 2 tokens
        _burn(firstTokenId);
        _burn(secondTokenId);

        // mint new token
        uint256 cookedDevilTokenId = _tokenIdCounter.current() + 1;
        _safeMint(msg.sender, cookedDevilTokenId);
        _tokenIdCounter.increment();

        // fire event in logs
        emit DevilCooked(firstTokenId, secondTokenId, cookedDevilTokenId);
    }
}