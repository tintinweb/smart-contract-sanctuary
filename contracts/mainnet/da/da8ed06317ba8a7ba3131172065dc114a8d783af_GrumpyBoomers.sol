// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./VRFConsumerBase.sol";
import "./Mintable.sol";

contract GrumpyBoomers is 
    Context,
    ERC721Enumerable,
    ReentrancyGuard,
    Ownable,
    Mintable,
    VRFConsumerBase {
  uint256 private constant maxTokens = 8888;
  bytes32 private constant linkKeyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;

  string private baseTokenURI;

  uint256 private linkFee = 2 ether;

  uint256 private winnerId = 0;

  constructor(address _owner, address _imx) ERC721('Grumpy Boomers', 'GRUMPY') Mintable(_owner, _imx) VRFConsumerBase(0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, 0x514910771AF9Ca656af840dff83E8264EcF986CA) {}

  function _baseURI() internal view override returns (string memory) {
      return baseTokenURI;
  }

  function winnerTokenId() public view returns (uint256) {
    return winnerId;
  }

  function _mintFor(
      address user,
      uint256 id,
      bytes memory
  ) internal override {
      _safeMint(user, id);
  }

  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setLinkFee(uint256 _linkFee) public onlyOwner {
    linkFee = _linkFee;
  }
  
  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    Address.sendValue(payable(owner()), balance);
  }

  function requestRandomWinner() public onlyOwner {
    require(LINK.balanceOf(address(this)) >= linkFee, "Not enough LINK");
    requestRandomness(linkKeyHash, linkFee);
  }

  /**
    * Callback function used by VRF Coordinator
    */
  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    winnerId = randomness % maxTokens;
  }
}