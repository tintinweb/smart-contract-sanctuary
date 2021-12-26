// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./IERC20.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

/// @custom:security-contact [email protected]
contract LeaoTheDog is ERC721, ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  struct Respect {
    address user;
    uint256 time;
  }

  mapping(address => uint256) respected;
  Respect[] respectedList;

  /// Pay respects to Leão
  event PayRespects(address user, uint256 timestamp, uint256 id);

  /// May Leão rest in peace.
  constructor() ERC721(unicode"Leão the Dog", "LEAO") {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(msg.sender, tokenId);
    _setTokenURI(
      tokenId,
      "sia://AABsrhhOBB7z5zd_MsOYxTqoGmUzEMKhcdXNg5SBP4CxfQ"
    );
    respected[msg.sender]++;
    respectedList.push(Respect(msg.sender, block.timestamp));
    emit PayRespects(msg.sender, block.timestamp, tokenId);
  }

  /// Pay respects to the good boy Leao.
  function payRespects() external payable {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(msg.sender, tokenId);
    _setTokenURI(
      tokenId,
      "sia://AABsrhhOBB7z5zd_MsOYxTqoGmUzEMKhcdXNg5SBP4CxfQ"
    );
    respected[msg.sender]++;
    respectedList.push(Respect(msg.sender, block.timestamp));
    emit PayRespects(msg.sender, block.timestamp, tokenId);
  }

  function withdrawERC20(
    address token,
    uint256 amount,
    address receiver
  ) external onlyOwner {
    IERC20(token).transfer(receiver, amount);
  }

  function withdrawNative(uint256 amount, address receiver) external onlyOwner {
    payable(receiver).transfer(amount);
  }

  fallback() external payable {}

  receive() external payable {}

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }
}