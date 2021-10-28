// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC721URIStorage.sol";
import "./VRFConsumerBase.sol";
import "./AggregatorV3Interface.sol";

contract Trees is ERC721URIStorage, VRFConsumerBase {

    using Strings for uint256;
    using Strings for uint16;

    struct Tree {
        // zero genome means that genome is not set yet
        uint256 genome;
        uint16  iteration;
        uint40  birthdate;
        uint128 prevPrice;
        uint128 price;
        address creator;
        string  name;
    }

    mapping (uint256 => Tree) public trees;
    uint constant public MAX_ITERATION = 10;
    uint constant public EMPTY_GENOME = 0;
    mapping (bytes32 => uint) public linkRequestId;
    uint256 public chainLinkFee;
    bytes32 chainLinkKeyHash;
    address priceProviderAddress;

    event Birth(uint256 tokenId);
    event Iterated(uint256 tokenId);
    event NameChange(uint256 tokenId, string name);

    // Chainlink constants: https://docs.chain.link/docs/vrf-contracts/
    constructor(
        string memory name_,
        string memory symbol_,
        address _link,
        address _vrfCoordinator,
        bytes32 _chainLinkKeyHash,
        uint256 _chainLinkFee,
        address _priceProviderAddress
    )
    ERC721(name_, symbol_)
    VRFConsumerBase(_vrfCoordinator, _link)
    {
        chainLinkFee = _chainLinkFee;
        chainLinkKeyHash = _chainLinkKeyHash;
        priceProviderAddress = _priceProviderAddress;
    }

    function _mintRaw(
        address _to,
        uint256 _genome
    ) internal {
        uint _tokenId = totalSupply();
        trees[_tokenId] = Tree(
            _genome,
            0,
            (uint40)(block.timestamp),
            0,
            0,
            _to,
            "");
        updatePrice(_tokenId);
        if (_genome == EMPTY_GENOME) {
            _requestGenome(_tokenId);
        } else {
            onBirth(_tokenId);
        }
    }

    function mint(address _to, uint256 _genome) external onlyOwner {
        _mintRaw(_to, _genome);
    }

    function _requestGenome(uint256 _tokenId) internal {
        require(LINK.balanceOf(address(this)) >= chainLinkFee, "Not enough LINK to pay fee");
        bytes32 requestId = requestRandomness(chainLinkKeyHash, chainLinkFee);
        linkRequestId[requestId] = _tokenId;
    }

    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    )
    internal
    override
    {
        uint tokenId = linkRequestId[requestId];
        delete linkRequestId[requestId];
        // If randomness will be 0, your unlucky tree will not be alive
        onGenomeArrived(tokenId, randomness);
    }

    function onGenomeArrived(uint256 _tokenId, uint256 _randomness) internal {
        trees[_tokenId].genome = _randomness;
        onBirth(_tokenId);
    }

    function onBirth(uint256 _tokenId) internal {
        _mint(trees[_tokenId].creator, _tokenId);
        emit Birth(_tokenId);
    }

    function claim() external {
        _mintRaw(msg.sender, 0);
    }

    function iterationUnlocked(uint256 _tokenId) public returns (bool) {
        return trees[_tokenId].iteration < MAX_ITERATION;
    }

    function isBorn(uint256 _tokenId) public returns (bool) {
        return trees[_tokenId].genome != EMPTY_GENOME;
    }

    function canIterate(uint256 _tokenId) public returns (bool) {
        return isBorn(_tokenId) && iterationUnlocked(_tokenId);
    }

    function iterate(uint256 _tokenId) external {
        require(canIterate(_tokenId), "Can' iterate");
        trees[_tokenId].iteration++;
        updatePrice(_tokenId);
        emit Iterated(_tokenId);
    }

    function updatePrice(uint256 _tokenId) internal {
        (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
        ) = AggregatorV3Interface(priceProviderAddress).latestRoundData();

        trees[_tokenId].prevPrice = trees[_tokenId].price;
        trees[_tokenId].price = (uint128)(price);
    }

    function setName(uint256 tokenId, string calldata _name) external {
        require(ownerOf(tokenId) == msg.sender, 'Only owner can change name');
        require(bytes(trees[tokenId].name).length == 0, 'The name has already been given');

        trees[tokenId].name = _name;
        emit NameChange(tokenId, _name);
    }

    function getUsersTokens(address _owner) external view returns (uint256[] memory) {
        uint256 n = balanceOf(_owner);

        uint256[] memory result = new uint256[](n);
        for (uint16 i = 0; i < n; i++) {
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }

    function getUsersTokensWithIteration(address _owner) external view returns (uint256[] memory) {
        uint256 n = balanceOf(_owner);

        uint256[] memory result = new uint256[](n*2);
        for (uint16 i = 0; i < n; i++) {
            uint tokenId = tokenOfOwnerByIndex(_owner, i);
            result[i*2] =
            result[i*2 + 1] = trees[tokenId].iteration;
        }
        return result;
    }

    function baseURI() public view override returns (string memory) {
        return 'http://bitreemeta.degens.farm/meta/tree/';
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            //return string(abi.encodePacked(base, _tokenURI));
            //Due customer requirements
            return _tokenURI;
        }

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString(), '/', trees[tokenId].iteration.toString()));
    }
}