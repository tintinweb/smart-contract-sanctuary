// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./Ownable.sol";

contract WhelpsPFP is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    
    bool public mintingEnabled = true;
    
    string public baseURI = "https://whelpsio.herokuapp.com/pfp/";
    string public ipfsBaseURI = "https://whelps.mypinata.cloud/ipfs/";
    mapping (uint256 => string) public tokenIdToIpfsHash;
    bool public ipfsLocked = false;
    
    address public approvedAccount = address(0);
    
    function setApprovedAccount(address _acc) public onlyOwner() {
        approvedAccount = _acc;
    }
    
    modifier onlyApprovedAccount() {
        require(approvedAccount == _msgSender() || owner() == _msgSender(), "Unauthorized account");
        _;
    }
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory __name, string memory __symbol)
        ERC721(__name, __symbol)
    {}
    
    function disableMinting() external onlyOwner {
      mintingEnabled = false;
    }

    // Metadata handlers
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function _ipfsBaseURI() internal view returns (string memory) {
        return ipfsBaseURI;
    }
    
    function setBaseUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
    
    function setIpfsBaseUri(string memory _uri) external onlyOwner {
        require(ipfsLocked == false);
        ipfsBaseURI = _uri;
    }
    
    function lockIpfsMetadata() external onlyOwner {
        require(ipfsLocked == false);
        ipfsLocked = true;
    }
    
    function setIpfsHash(uint256 tokenId, string memory hash) external onlyOwner {
        require(ipfsLocked == false);
        tokenIdToIpfsHash[tokenId] = hash;
    }
    
    function setIpfsHashArray(uint256[] calldata tokenIds, string[] calldata hashes) external onlyOwner {
        require(ipfsLocked == false);
        require(tokenIds.length == hashes.length);
        
        for (uint i = 0; i < tokenIds.length; i++) {
          tokenIdToIpfsHash[tokenIds[i]] = hashes[i];
        }
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        
        string memory base = _baseURI();
        string memory ipfsBase = _ipfsBaseURI();
        string memory ipfsHash = tokenIdToIpfsHash[tokenId];
        
        if (bytes(ipfsHash).length == 0) {
            return string(abi.encodePacked(base, tokenId.toString()));
        } else {
            return string(abi.encodePacked(ipfsBase, ipfsHash));
        }
    }
    
    // Minting
            
    function mintArray(address[] calldata owners, uint start, uint end) public onlyApprovedAccount {
      require(mintingEnabled, "Minting disabled");
      for (uint256 i = start; i <= end; i++) {
        _mint(owners[i], totalSupply());
      }
    }
    
    function mintArrayById(address[] calldata owners, uint256[] calldata tokenIds, uint start, uint end) public onlyApprovedAccount {
      require(mintingEnabled, "Minting disabled");
      require(owners.length == tokenIds.length);
      for (uint256 i = start; i <= end; i++) {
        _mint(owners[i], tokenIds[i]);
      }
    }
    
    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}