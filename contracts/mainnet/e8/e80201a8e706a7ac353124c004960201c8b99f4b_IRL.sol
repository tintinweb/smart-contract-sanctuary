// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract IRLOwnableDelegateProxy {}

contract IRLProxyRegistry {
    mapping(address => IRLOwnableDelegateProxy) public proxies;
}

contract IRL is ERC721Enumerable, Ownable, ContextMixin, NativeMetaTransaction {
    using SafeMath for uint256;
    using Strings for uint256;

    address proxyRegistryAddress;

    uint256 private infiniteOwnerMintingFees = 1e17;
    uint256 private maxMintingFees = 4e18;
    uint256 private minMintingFees = 25e16;

    uint256 private currentIndex = 1;

    mapping(uint256 => string) private serialIdToIRL;
    mapping(string => bool) private existingIRL;
    mapping(uint256 => bool) private infinitesAlreadUsedToMintIRL;

    uint256 private maxInfiniteOwnerMints = 512;
    uint256 private maxNonInfiniteOwnerMints = 512;
    uint256 private currentInfiniteOwnerMints = 1;
    uint256 private currentNonInfiniteOwnerMints = 1;

    uint256 private maxIRLBaseCount = 212;
    uint256 private minIRLBaseIndx = 45;

    uint256 private minBaseSpeed = 2;
    uint256 private maxBaseSpeed = 7;

    uint256 private minNoise = 2;
    uint256 private maxNoise = 46;

    uint256 private minScale = 1;
    uint256 private maxScale = 10;

    uint256 private minReflectivity = 1;
    uint256 private maxReflectivity = 3;

    string private baseURI =
        "https://irl-infinites.s3.us-east-2.amazonaws.com/json/";

    address private dev = 0x7bd8547188e1Dc634D5A340798Ac97581171dC2B;
    address private far = 0x8BC500F715F6Eebf1331F068D0d0a285CFA9AF60;

    ERC721 private infinites;
    uint256 private mintStartTimestamp;
    bool private forceStartInfiniteOwnerMints = false;
    bool private areInfiniteMintsOpenForAll = false;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        address _infinites,
        uint256 _mintStartTimestamp
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        infinites = ERC721(_infinites);
        mintStartTimestamp = _mintStartTimestamp;
        _initializeEIP712(_name);
    }

    function setMintStartTimestamp(uint256 timestamp) public onlyOwner {
        mintStartTimestamp = timestamp;
    }

    function isNonInfinteOwnerMintEnabled() public view returns (bool) {
        return block.timestamp >= mintStartTimestamp;
    }

    function mintNonInfiniteOwner() public payable returns (uint256) {
        require(
            block.timestamp >= mintStartTimestamp,
            "Minting not allowed currently"
        );
        require(
            balanceOf(msg.sender) < 3 || areInfiniteMintsOpenForAll == true,
            "You already own 3 IRLs"
        );
        require(
            msg.value >= currentMintFeesForNonInfiniteOwner(),
            "Incorrect value sent"
        );
        require(
            currentNonInfiniteOwnerMints <= maxNonInfiniteOwnerMints,
            "There aren't any infinites left for non-infinite owners."
        );
        uint256 tokenId = mintNoChecks(msg.sender);
        currentNonInfiniteOwnerMints += 1;
        return tokenId;
    }

    function numNonInfinteOwnerMints() public view returns (uint256) {
        return currentNonInfiniteOwnerMints - 1;
    }

    function forcefullyStartInfiniteOwnerMints() public onlyOwner {
        forceStartInfiniteOwnerMints = true;
    }

    function isInfinteOwnerMintEnabled() public view returns (bool) {
        return
            currentNonInfiniteOwnerMints > maxNonInfiniteOwnerMints ||
            forceStartInfiniteOwnerMints == true;
    }

    function mintInfiniteOwner(uint256 _infiniteId)
        public
        payable
        returns (uint256)
    {
        require(
            currentNonInfiniteOwnerMints > maxNonInfiniteOwnerMints ||
                forceStartInfiniteOwnerMints == true,
            "Infinite Owner Minting not allowed currently"
        );
        require(
            infinites.ownerOf(_infiniteId) == msg.sender,
            "You do not own this infinite"
        );
        require(
            infinitesAlreadUsedToMintIRL[_infiniteId] == false,
            "Infinite already used to mint"
        );
        require(msg.value >= infiniteOwnerMintingFees, "Incorrect value sent");
        require(
            currentInfiniteOwnerMints <= maxInfiniteOwnerMints,
            "There aren't any infinites left for infinite owners."
        );
        infinitesAlreadUsedToMintIRL[_infiniteId] = true;
        uint256 tokenId = mintNoChecks(msg.sender);
        currentInfiniteOwnerMints += 1;
        return tokenId;
    }

    function isInfiniteAvailableToMintIRL(uint256 _infiniteId)
        public
        view
        returns (bool)
    {
        return
            areInfiniteMintsOpenForAll == false &&
            infinitesAlreadUsedToMintIRL[_infiniteId] == false;
    }

    function numInfinteOwnerMints() public view returns (uint256) {
        return currentInfiniteOwnerMints - 1;
    }

    function openInfiniteMintsForAll(uint256 timestamp) public onlyOwner {
        maxNonInfiniteOwnerMints += (maxInfiniteOwnerMints -
            currentInfiniteOwnerMints +
            1);
        maxInfiniteOwnerMints = 0;
        areInfiniteMintsOpenForAll = true;
        mintStartTimestamp = timestamp;
    }

    function currentMintFeesForNonInfiniteOwner()
        public
        view
        returns (uint256)
    {
        uint256 passedIntervals = (block.timestamp - mintStartTimestamp).div(
            900
        );
        uint256 deduction = passedIntervals.mul(1e18).div(4);

        if (deduction <= 175e16) {
            return maxMintingFees.sub(deduction);
        } else {
            return minMintingFees;
        }
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintNoChecks(address _to) private returns (uint256) {
        uint256 tokenId = currentIndex;
        string memory generatedIRL = generateIRL(tokenId);
        require(
            !(isExistingIRL(generatedIRL)),
            "Unable to mint, please try again."
        );
        serialIdToIRL[tokenId] = generatedIRL;
        existingIRL[generatedIRL] = true;
        _mint(_to, tokenId);
        currentIndex = currentIndex + 1;
        return tokenId;
    }

    function getIRLData(uint256 serialId) public view returns (string memory) {
        return serialIdToIRL[serialId];
    }

    function generateIRL(uint256 serialId)
        private
        view
        returns (string memory)
    {
        uint256 randomIRLIndex = (getRandomNumber(
            serialId,
            0,
            maxIRLBaseCount
        ) % (maxIRLBaseCount - minIRLBaseIndx)) + minIRLBaseIndx;

        uint256 randomBaseSpeed = (getRandomNumber(
            randomIRLIndex,
            serialId,
            maxIRLBaseCount
        ) % (maxBaseSpeed - minBaseSpeed)) + minBaseSpeed;

        uint256 randomNoise = (getRandomNumber(
            randomIRLIndex,
            maxIRLBaseCount,
            serialId
        ) % (maxNoise - minNoise)) + minNoise;

        uint256 randomScale = (getRandomNumber(
            randomIRLIndex,
            serialId,
            randomNoise
        ) % (maxScale - minScale)) + minScale;

        uint256 randomReflectivity = (getRandomNumber(
            randomIRLIndex,
            randomNoise,
            serialId
        ) % (maxReflectivity - minReflectivity)) + minReflectivity;

        return
            createIRLStringRepresentation(
                randomIRLIndex,
                randomBaseSpeed,
                randomNoise,
                randomScale,
                randomReflectivity
            );
    }

    function isExistingIRL(string memory irl) private view returns (bool) {
        return existingIRL[irl];
    }

    function createIRLStringRepresentation(
        uint256 index,
        uint256 baseSpeed,
        uint256 randomNoise,
        uint256 randomScale,
        uint256 randomReflectivity
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    convertToString(index),
                    convertToString(baseSpeed),
                    convertToString(randomNoise),
                    convertToString(randomScale),
                    convertToString(randomReflectivity)
                )
            );
    }

    function convertToString(uint256 num) private pure returns (string memory) {
        if (num <= 9) {
            return string(abi.encodePacked("00", Strings.toString(num)));
        } else if (num <= 99) {
            return string(abi.encodePacked("0", Strings.toString(num)));
        } else {
            return Strings.toString(num);
        }
    }

    function getRandomNumber(
        uint256 seed1,
        uint256 seed2,
        uint256 seed3
    ) private view returns (uint256) {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    msg.sender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    blockhash(block.number - 1),
                    seed1,
                    seed2,
                    seed3
                )
            )
        );

        // never return 0, edge cases where first probability of accessory
        // could be 0 while rerolling
        return (randomNum % 10000) + 1;
    }

    function setMaxIRLBaseCount(uint256 _maxIRLBaseCount) public onlyOwner {
        maxIRLBaseCount = _maxIRLBaseCount;
    }

    function withdraw() public onlyOwner {
        payable(dev).transfer(address(this).balance.div(4));
        payable(far).transfer(address(this).balance);
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
        IRLProxyRegistry proxyRegistry = IRLProxyRegistry(proxyRegistryAddress);
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
        return "https://irl-infinites.s3.us-east-2.amazonaws.com/json/irl.json";
    }
}