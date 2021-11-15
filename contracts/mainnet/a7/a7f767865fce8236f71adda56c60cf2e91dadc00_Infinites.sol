// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Infinites is
    ERC721Enumerable,
    Ownable,
    ContextMixin,
    NativeMetaTransaction
{
    using SafeMath for uint256;
    using Strings for uint256;

    address proxyRegistryAddress;

    uint256 private mintingFees = 15e16;

    uint256 private currentIndex = 1;

    mapping(uint256 => string) public serialIdToInfinite;
    mapping(string => bool) public existingInfinites;

    uint256 private maxMints = 512;
    uint256 private maxInfinites = 44;

    uint256 private minBaseSpeed = 2;
    uint256 private maxBaseSpeed = 10;

    uint256 private minNoise = 2;
    uint256 private maxNoise = 46;

    string private baseURI =
        "https://infinites.s3.us-east-2.amazonaws.com/json/";

    address dev = 0x7bd8547188e1Dc634D5A340798Ac97581171dC2B;
    address far = 0x20E40560434FC25f8BafFaac820Eab5C369D4589;

    bool private isMintingEnabled = true;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    function setMintingEnabled(bool isEnabled) public onlyOwner {
        isMintingEnabled = isEnabled;
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mint(address _to) public payable returns (uint256) {
        uint256 tokenId = currentIndex;
        require(isMintingEnabled == true, "Minting not allowed currently");
        require(msg.value == mintingFees, "Need to send correct ETH.");
        require(tokenId <= maxMints, "There aren't any infinites left.");
        string memory generatedInfinite = generateInfinite(tokenId);
        require(
            !(isExistingInfinite(generatedInfinite)),
            "Unable to mint, please try again."
        );
        serialIdToInfinite[tokenId] = generatedInfinite;
        existingInfinites[generatedInfinite] = true;
        _mint(_to, tokenId);
        currentIndex = currentIndex + 1;
        return tokenId;
    }

    function generateInfinite(uint256 serialId)
        internal
        view
        returns (string memory)
    {
        uint256 randomInfiniteIndex = (getRandomNumber(
            serialId,
            0,
            maxInfinites
        ) % (maxInfinites - 1)) + 1;

        uint256 randomBaseSpeed = (getRandomNumber(
            randomInfiniteIndex,
            serialId,
            maxInfinites
        ) % (maxBaseSpeed - minBaseSpeed)) + minBaseSpeed;

        uint256 randomNoise = (getRandomNumber(
            randomInfiniteIndex,
            maxInfinites,
            serialId
        ) % (maxNoise - minNoise)) + minNoise;

        return
            createInfiniteStringRepresentation(
                randomInfiniteIndex,
                randomBaseSpeed,
                randomNoise
            );
    }

    function isExistingInfinite(string memory infinite)
        internal
        view
        returns (bool)
    {
        return existingInfinites[infinite];
    }

    function createInfiniteStringRepresentation(
        uint256 index,
        uint256 baseSpeed,
        uint256 randomNoise
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    convertToString(index),
                    convertToString(baseSpeed),
                    convertToString(randomNoise)
                )
            );
    }

    function convertToString(uint256 num)
        internal
        pure
        returns (string memory)
    {
        if (num == 0) {
            return "00";
        } else if (num == 1) {
            return "01";
        } else if (num == 2) {
            return "02";
        } else if (num == 3) {
            return "03";
        } else if (num == 4) {
            return "04";
        } else if (num == 5) {
            return "05";
        } else if (num == 6) {
            return "06";
        } else if (num == 7) {
            return "07";
        } else if (num == 8) {
            return "08";
        } else if (num == 9) {
            return "09";
        }

        return Strings.toString(num);
    }

    function getRandomNumber(
        uint256 seed1,
        uint256 seed2,
        uint256 seed3
    ) internal view returns (uint256) {
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

    function setMaxInfinites(uint256 _maxInfinites) public onlyOwner {
        maxInfinites = _maxInfinites;
    }

    function setMintingFees(uint256 _fees) public onlyOwner {
        mintingFees = _fees;
    }

    function withdraw() public onlyOwner {
        payable(dev).transfer(address(this).balance.div(2));
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
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
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
        return
            "https://infinites.s3.us-east-2.amazonaws.com/json/infinite.json";
    }
}