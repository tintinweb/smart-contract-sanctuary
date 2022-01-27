// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import './Strings.sol';
import './BytesLib.sol';
import './base64.sol';

interface IPunksOnChain {
  function punkImageSvg(uint16) external view returns (string calldata);
  function punkAttributes(uint16) external view returns (string calldata);
}

interface IPunks {
  function punksOfferedForSale(uint256)
    external view returns (bool, uint256, address, uint256, address);

  function punkBids(uint256)
    external view returns (bool, uint256, address, uint256);
}

contract PunksUriAdapter {
  using Strings for uint256;
  using BytesLib for bytes;

  address constant punksContract = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
  address constant punksOnChainData = 0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2;

  function uri(uint256 _tokenId) external view returns (string memory) {
    bytes memory slices;
    bytes memory attributeString = bytes(
      IPunksOnChain(punksOnChainData).punkAttributes(uint16(_tokenId))
    );

    uint256 attributeCount;
    uint256 leftCursor;
    uint256 rightCursor;

    for(uint256 i; i<attributeString.length; ++i) {
      ++rightCursor;
      if (
        attributeString[i] == bytes1(0x2C)
        || i == attributeString.length - 1
      ) {
        slices = slices.concat(attributeCount != 0
          ? _generateAccessoryProp(
            attributeString.slice(leftCursor, rightCursor)
          )
          : _generateTypeProp(
            attributeString.slice(leftCursor, rightCursor - 3)
          )
        );
        leftCursor = i + 1;
        rightCursor = 0;
        ++attributeCount;
      }
    }
    
    bytes memory attributesList = abi.encodePacked(
      '"attributes":[',
        slices,
        '{'
          '"trait_type": "accessory",'
          '"value": "', (attributeCount-1).toString(), ' Attributes"'
        '}'
      '],'
    );

    string memory bgColor;
    {
        (bool onOffer,,,,) = IPunks(punksContract).punksOfferedForSale(_tokenId);
        (bool hasBid,,,) = IPunks(punksContract).punkBids(_tokenId);
        if (onOffer) {
          bgColor = '95554F'; //offer red
        } else if (hasBid) {
          bgColor = '8E6FB6'; // bid purple
        } else {
          bgColor = '638596'; // default blue
        }
    }

    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(abi.encodePacked(
        '{'
          '"name":"CryptoPunk #', _tokenId.toString(), '",'
          '"background_color": "', bgColor, '",',
          attributesList,
          '"image": "', _encodeSvg(IPunksOnChain(punksOnChainData).punkImageSvg(uint16(_tokenId))), '",'
          '"external_url": "https://www.larvalabs.com/cryptopunks/details/', _tokenId.toString(), '"'
        '}'
      ))
    ));
  }

  function _encodeSvg(string memory _svg) private pure returns (bytes memory) {
    bytes memory svg = bytes(_svg);
    svg = svg.slice(24, svg.length-24);
    svg = bytes(Base64.encode(svg));
    return bytes('data:image/svg+xml;base64,').concat(svg);
  }

  function _generateAccessoryProp(bytes memory _accessory) private pure returns (bytes memory) {
    return abi.encodePacked(
      '{'
        '"trait_type": "accessory",'
        '"value": "', _accessory, '"'
      '},'
    );
  }

  function _generateTypeProp(bytes memory _type) private pure returns (bytes memory) {
    return abi.encodePacked(
      '{'
        '"trait_type": "type",'
        '"value": "', _type, '"'
      '},'
    );
  }
}