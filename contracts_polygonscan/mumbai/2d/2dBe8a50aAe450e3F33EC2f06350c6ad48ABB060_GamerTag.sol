// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IUNSResolver.sol";
import "./IUNSRegistryReader.sol";
import "./StringLib.sol";

// @name Gamer Tag
contract GamerTag {
  mapping(address => string) private tags;          // Gamer addresses -> tags (unique)
  mapping(address => string) private nicknames;     // Gamer addresses -> nicknames (not unique)
  mapping(address => uint256) public tagClaimedAt;  // Gamer addresses -> tag claim time
  mapping(string => address) claimedTags;           // Tags -> gamer address with it set

  //Unstoppable Domains support
  IUNSResolver private unsResolver;
  IUNSRegistryReader private unsRegistryReader;

  constructor(address _unsResolver, address _unsRegistryReader) {
    unsResolver = IUNSResolver(_unsResolver);
    unsRegistryReader = IUNSRegistryReader(_unsRegistryReader);
  }

  // @name Get Nickname
  // @param _address address to lookup nickname for
  function getNickname(address _address) external view returns(string memory) {
    return nicknames[_address];
  }

  // @name Set Nickname
  // @param _nickname nickname to set for caller
  function setNickname(string memory _nickname) public {
    nicknames[msg.sender] = _nickname;
  }

  // @name Get Tag
  // @param _address address to tag nickname for
  function getTag(address _address) external view returns(string memory) {
    return tags[_address];
  }

  // @name Set Tag
  // @dev Will throw an error if the tag has already been claimed
  // @param _tag gamer tag to set for caller
  function setTag(string memory _tag) external {
    require(claimedTags[_tag] == address(0) || claimedTags[_tag] == msg.sender, "GameTag: that tag has already been claimed");

    if(StringLib.equals(tags[msg.sender], "")){
      claimedTags[tags[msg.sender]] = address(0); // Already have a claimed tag, remove it first
    }

    // Update tag claim
    tags[msg.sender] = _tag;
    claimedTags[_tag] = msg.sender;
    tagClaimedAt[msg.sender] = block.timestamp;
  }

  // @name Claim Tag
  function _claimTag(string memory _tag) internal {
    if(StringLib.equals(tags[msg.sender], "")){
      claimedTags[tags[msg.sender]] = address(0); // Already have a claimed tag, remove it first
    }

    // Update tag claim
    tags[msg.sender] = _tag;
    claimedTags[_tag] = msg.sender;
    tagClaimedAt[msg.sender] = block.timestamp;
  }

  // @name Use Unstoppable Domain for Tag
  function useUnstoppableDomainForTag() public {
    uint256 tokenId = unsResolver.reverseOf(msg.sender);
    _claimTag(unsRegistryReader.tokenURI(tokenId));
  }

  // @name Use Unstoppable Domain for Nickname
  function useUnstoppableDomainForNickname() public {
    uint256 tokenId = unsResolver.reverseOf(msg.sender);
    setNickname(unsRegistryReader.tokenURI(tokenId));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// @name String Lib
// @dev String utilities library
library StringLib {

    // @name Equals
    // @dev Checks if two strings are equal
    function equals(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IUNSResolver {
    function reverseOf(address account) external view returns (uint256);
    function register(uint256 tokenId) external;
    function remove() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// @author Unstoppable Domains, Inc. - IRegistryReader
// @date June 16th, 2021

interface IUNSRegistryReader {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @dev Returns whether the given spender can transfer a given token ID. Registry related function.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

    /**
     * @dev Gets the resolver of the specified token ID. Registry related function.
     * @param tokenId uint256 ID of the token to query the resolver of
     * @return address currently marked as the resolver of the given token ID
     */
    function resolverOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Provides child token (subdomain) of provided tokenId. Registry related function.
     * @param tokenId uint256 ID of the token
     * @param label label of subdomain (for `aaa.bbb.crypto` it will be `aaa`)
     */
    function childIdOf(uint256 tokenId, string calldata label) external view returns (uint256);

    /**
     * @dev Returns the number of NFTs in `owner`'s account. ERC721 related function.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`. ERC721 related function.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev ERC721 related function.
     */
    function getApproved(uint256 tokenId) external view returns (address);

    /**
     * @dev ERC721 related function.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Returns whether token exists or not.
     */
    function exists(uint256 tokenId) external view returns (bool);
}