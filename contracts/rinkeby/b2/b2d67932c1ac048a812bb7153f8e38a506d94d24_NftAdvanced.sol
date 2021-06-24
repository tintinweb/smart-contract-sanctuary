// SPDX-License-Identifier: MIT

// MIT License

// Copyright (c) 2020 Patrick Collins

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// See https://betterprogramming.pub/how-to-create-nfts-with-solidity-4fa1398eb70a

pragma solidity >=0.8.5 <0.9.0;

import "./ERC721Abstract.sol";
import "./VRFConsumerBase.sol";
import "./StringsCustomlyCombined.sol";

contract NftAdvanced is ERC721, VRFConsumerBase {
  using StringsCustomlyCombined for string;
  uint256 public tokenCounter;
  // add something specific to the contract
  mapping(bytes32 => address) public requestIdToSender;
  mapping(bytes32 => string) public requestIdToTokenURI;
  mapping(bytes32 => uint256) public requestIdToTokenId;

  event requestCollectible(bytes32 indexed requestId);

  bytes32 internal keyHash;
  uint256 internal fee;
  uint256 public randomResult;

  constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyhash)
  VRFConsumerBase(_VRFCoordinator, _LinkToken)
  ERC721("Item", "ITM")
  {
    tokenCounter = 0;
    keyHash = _keyhash;
    fee = 0.1 * 10 ** 18;
  }

  function baseTokenURI() public pure returns (string memory) {
    return "";
  }
  function getTokenURI(uint256 _tokenId) public pure returns (string memory) {
    return StringsCustomlyCombined.strConcat(
      baseTokenURI(),
      StringsCustomlyCombined.uint2str(_tokenId)
    );
  }

  function createCollectible(string memory tokenURI, uint256 userProvidedSeed)
  public returns (bytes32) {
    bytes32 requestId = requestRandomness(keyHash, fee, userProvidedSeed);
    requestIdToSender[requestId] = msg.sender;
    requestIdToTokenURI[requestId] = tokenURI;
    emit requestCollectible(requestId);
    return requestId;
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
    address itemOwner = requestIdToSender[requestId];
    string memory tokenURI = requestIdToTokenURI[requestId];
    tokenCounter ++;
    uint256 newItemId = tokenCounter;
    _safeMint(itemOwner, newItemId);
    requestIdToTokenId[requestId] = newItemId;
  }     
}