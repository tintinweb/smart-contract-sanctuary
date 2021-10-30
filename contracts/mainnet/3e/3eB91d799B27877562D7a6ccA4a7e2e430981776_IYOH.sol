// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract IYOHOwnableDelegateProxy {}

contract IYOHProxyRegistry {
    mapping(address => IYOHOwnableDelegateProxy) public proxies;
}

contract IYOHRandomizer {
    function generateIYOH(uint256 serialId) public view returns (string memory) {}
}

contract IYOH is ERC721Enumerable, Ownable, ContextMixin, NativeMetaTransaction {
    using SafeMath for uint256;
    using Strings for uint256;

    address proxyRegistryAddress;
    IYOHRandomizer private randomizer;

    mapping(uint256 => string) private serialIdToIYOH;
    mapping(string => bool) private existingIYOH;

    ERC721 private whitelistContract;
    mapping(uint256 => bool) private whitelistedTokens;
    mapping(uint256 => bool) private tokensAlreadyUsedToMintIYOH;

    uint256 private mintStartTimestamp;
    uint256 private tokenOwnerMintingFees = 2e17;

    uint256 private currentIndex = 1;
    uint256 private maxMints = 150;

    bool private areMintsOpenForAll = false;
    uint256 private mintingFees = 25e16;

    string private baseURI = "";

    address private dev = 0x7bd8547188e1Dc634D5A340798Ac97581171dC2B;
    address private das = 0x666FDd2160D19dC763DE299dcb657DdEB222Bb36;
    address private art = 0x19dBcF92Ab399C5E05Df253Caf36A8F1aF8902ab;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        address _whitelistContract,
        address _randomizer,
        uint256 _mintStartTimestamp
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        whitelistContract = ERC721(_whitelistContract);
        randomizer = IYOHRandomizer(_randomizer);
        mintStartTimestamp = _mintStartTimestamp;
        _initializeEIP712(_name);
    }

    function setRandomizer(address _randomizer) public onlyOwner {
        randomizer = IYOHRandomizer(_randomizer);
    }

    function setWhitelistContract(address _whitelistContract) public onlyOwner {
        whitelistContract = ERC721(_whitelistContract);
    }

    function whitelistTokens(uint256[] memory tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            whitelistedTokens[tokenIds[i]] = true;
        }
    } 

    function setMintStartTimestamp(uint256 timestamp) public onlyOwner {
        mintStartTimestamp = timestamp;
    }

    function setMaxSupply(uint256 maxSupply) public onlyOwner {
        maxMints = maxSupply;
    }

    function setTokenOwnerMintingFees(uint256 fees) public onlyOwner {
        tokenOwnerMintingFees = fees;
    }

    function isTokenOwnerMintEnabled() public view returns (bool) {
        return block.timestamp >= mintStartTimestamp && areMintsOpenForAll == false;
    }

    function isTokenAvailableToMintIYOH(uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return
            areMintsOpenForAll == false &&
            whitelistedTokens[_tokenId] == true && 
            tokensAlreadyUsedToMintIYOH[_tokenId] == false;
    }

    function mintTokenOwner(uint256 _tokenId)
        public
        payable
        returns (uint256)
    {
        require(
            isTokenOwnerMintEnabled(),
            "Token Owner Minting not allowed currently"
        );
        require(
            whitelistContract.ownerOf(_tokenId) == msg.sender,
            "You do not own this token"
        );
        require(
            isTokenAvailableToMintIYOH(_tokenId),
            "Token cannot be used to mint"
        );
        require(msg.value >= tokenOwnerMintingFees, "Incorrect value sent");
        require(
            currentIndex <= maxMints,
            "Sold out"
        );
        tokensAlreadyUsedToMintIYOH[_tokenId] = true;
        return mintNoChecks(msg.sender);
    }

    function isMintEnabledForAll() public view returns (bool) {
        return block.timestamp >= mintStartTimestamp && areMintsOpenForAll == true;
    }

    function setMintingFeesForAll(uint256 fees) public onlyOwner {
        mintingFees = fees;
    }

    function mintForAll() public payable returns (uint256) {
        require(
            isMintEnabledForAll(),
            "Minting not allowed currently"
        );
        require(
            msg.value >= mintingFees,
            "Incorrect value sent"
        );
        require(
            currentIndex <= maxMints,
            "Sold out"
        );
        return mintNoChecks(msg.sender);
    }

    function setMintsForAll(bool open) public onlyOwner {
        areMintsOpenForAll = open;
    }

    function mintNoChecks(address _to) private returns (uint256) {
        uint256 tokenId = currentIndex;
        string memory generatedIYOH = randomizer.generateIYOH(tokenId);
        require(
            !(isExistingIYOH(generatedIYOH)),
            "Unable to mint, please try again."
        );
        serialIdToIYOH[tokenId] = generatedIYOH;
        existingIYOH[generatedIYOH] = true;
        _mint(_to, tokenId);
        currentIndex = currentIndex + 1;
        return tokenId;
    }

    function getIYOHData(uint256 serialId) public view returns (string memory) {
        return serialIdToIYOH[serialId];
    }

    function isExistingIYOH(string memory _IYOH) private view returns (bool) {
        return existingIYOH[_IYOH];
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(dev).transfer(balance.div(4));
        payable(das).transfer(balance.div(4));
        payable(art).transfer(address(this).balance);
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        IYOHProxyRegistry proxyRegistry = IYOHProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://Qme24GpTW1QwrpP1RozkwG6b3kueCFgeyT6qXjsV1J8mZ7";
    }
}