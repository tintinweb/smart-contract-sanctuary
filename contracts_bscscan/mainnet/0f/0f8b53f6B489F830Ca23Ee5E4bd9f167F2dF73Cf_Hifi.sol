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
        0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31,
        0x404460C6A5EdE2D891e8297795264fDe62ADBB75
    ) {
        _baseTokenURI = baseTokenURI;

        keyHash = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c;
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