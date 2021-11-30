// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./VRFConsumerBase.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract Hifi is Context, AccessControlEnumerable, ERC721Enumerable, VRFConsumerBase, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    event RandomReturned(
        bytes32 requestId,
        uint256 randomness
    );

    /// @notice Random digital per tokenId
    mapping(uint256 => uint256) public rngMapping;

    /// @notice keyhash for chainlink rng generator
    bytes32 public keyHash;

    /// @notice fee for chainlink rng generator
    uint256 public rngFee;

    event UpdateBaseURI(string indexed previousBaseUri, string indexed newBaseUri);

    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) VRFConsumerBase(
        0xa555fC018435bef5A13C6c6870a9d4C11DEC329C,
        0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06
    ) {
        _baseTokenURI = baseTokenURI;

        keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
        rngFee = 0.1 * 10 ** 18; // 0.1 LINK

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Update the baseTokenURI of the NFT
    /// @dev The admin of this function is expected to renounce ownership once the base url has been tested and is working
    /// @param baseTokenURI The new bse uri for the contract
    function updateBaseTokenURI(string memory baseTokenURI) external onlyOwner {
        emit UpdateBaseURI(_baseTokenURI, baseTokenURI);
        _baseTokenURI = baseTokenURI;
    }
    
    /// @dev must be called by an account with MINTER_ROLE
    function mint() public virtual onlyOwner {
        requestRNG();
    }

    /**
    * Requests randomness
    */
    function requestRNG() public returns (bytes32) {
        bytes32 requestId = requestRandomness(keyHash, rngFee);
        return requestId;
    }

    /**
    * Callback function used by VRF Coordinator
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit RandomReturned(requestId, randomness);

        uint256 currentTokenId = _tokenIdTracker.current();

        _mint(_msgSender(), currentTokenId);

        rngMapping[currentTokenId] = randomness;
        _tokenIdTracker.increment();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
		public
        view
		override(ERC721)
        returns (string memory)
    {
		return string(abi.encodePacked(_baseTokenURI, rngMapping[tokenId].toString()));
	}

	function randomeeFromTokenId(uint256 tokenId)
		public
        view
        returns (uint256)
    {
		return rngMapping[tokenId];
	}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}