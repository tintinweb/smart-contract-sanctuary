/**
 *  NonagonCup
 *  An ERC721 NFT consisting of on-chain STL files describing unique nine-sided cups
 *  by Jacob Robbins
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./HasFile.sol";


contract NonagonCup is ERC721Enumerable, ReentrancyGuard, Ownable, HasFile {
  using Strings for uint256;

  bytes32 private constant header = hex"53544C42204154462031302E31302E302E3133393120434F4C4F523DA0A0A0FF";
  uint32 private constant facetCount = 68;
  uint8 private constant heightProgVal = 254;
  uint8 private constant thickProgVal = 253;

  // Era 1
  bytes4 private constant thick0 = hex'000080C0';
  bytes private constant verts0 = hex'F095DBC123E09A40000000000B538FC1AECEAA41B519C1C121F95EC1CB8518C1B786D1C1CB851841B519C141F095DB410B538F41000020A721F9DE41DF449AC1C5D9B741975AECC1C7B3A6409AD8CFC1000070C16F2B24C1B786E1C16F2B2441DF449A410000F041975AEC419AD8CF41';
  bytes private constant prog0 = hex'0001020304020001FE0001FE0304020304FE0506020001020506FE0506FE0001020001FE0708020506020708FE0708FE0506020506FE0908020708020908FE0908FE0708020708FE0A06020908020A06FE0A06FE0908020908FE0B01020A06020B01FE0B01FE0A06020A06FE0C04020B01020C04FE0C04FE0B01020B01FE0D0E020C04020D0EFE0D0EFE0C04020C04FE0304020D0E020304FE0304FE0D0E020D0EFE0D0EFE0F10FE0304FE0304FE0F10FE1112FE0304FE1112FE0001FE0001FE1112FE0506FE0506FE1112FE1314FE0506FE1314FE0708FE0708FE1314FE1516FE0708FE1516FE1716FE0C04FE1810FE0D0EFE0D0EFE1810FE0219FE0D0EFE0219FE0F10FE1810FE0C04FE1A12FE1A12FE0C04FE0B01FE1A12FE0B01FE0A06FE1A12FE0A06FE1B14FE1B14FE0A06FE0908FE1B14FE0908FE1716FE1716FE0908FE0708FE0219FD0F10FD0219FE0219FE0F10FD0F10FE0F10FD1112FD0F10FE0F10FE1112FD1112FE1112FD1314FD1112FE1112FE1314FD1314FE1314FD1516FD1314FE1314FE1516FD1516FE1516FD1716FD1516FE1516FE1716FD1716FE1716FD1B14FD1716FE1716FE1B14FD1B14FE1B14FD1A12FD1B14FE1B14FE1A12FD1A12FE1A12FD1810FD1A12FE1A12FE1810FD1810FE1810FD0219FD1810FE1810FE0219FD0219FE0001020B01020304020304020B01020C04020304020C04020D0E020B01020001020A06020A06020001020506020A06020506020908020908020506020708020219FD1810FD0F10FD0F10FD1810FD1112FD1112FD1810FD1A12FD1112FD1A12FD1314FD1314FD1A12FD1B14FD1314FD1B14FD1516FD1516FD1B14FD1716FD';

  // Era 2
  bytes4 private constant thick1 = hex'0000FEC0';
  bytes private constant verts1 = hex'C3131CC23C2ADC40000000008BBECBC122D0F241824009C2257C9EC1F7D158C158ED14C2F7D1584182400942C3131C428BBECB41257C1E42731EDDC178C203420E6329C29DF0EE40D5F414C20000ACC1534F6BC18CA021C2534F6B41731EDD4100002C420E632942D5F41442';
  bytes private constant prog1 = hex'0001020304020001FE0001FE0304020304FE0506020001020506FE0506FE0001020001FE0708020506020708FE0708FE0506020506FE0908020708020908FE0908FE0708020708FE0A06020908020A06FE0A06FE0908020908FE0B01020A06020B01FE0B01FE0A06020A06FE0C04020B01020C04FE0C04FE0B01020B01FE020D020C0402020DFE020DFE0C04020C04FE030402020D020304FE0304FE020D02020DFE020DFE0E0FFE0304FE0304FE0E0FFE1011FE0304FE1011FE0001FE0001FE1011FE0506FE0506FE1011FE1213FE0506FE1213FE0708FE0708FE1213FE1415FE0708FE1415FE1615FE0C04FE170FFE020DFE020DFE170FFE0218FE020DFE0218FE0E0FFE170FFE0C04FE1911FE1911FE0C04FE0B01FE1911FE0B01FE0A06FE1911FE0A06FE1A13FE1A13FE0A06FE0908FE1A13FE0908FE1615FE1615FE0908FE0708FE0218FD0E0FFD0218FE0218FE0E0FFD0E0FFE0E0FFD1011FD0E0FFE0E0FFE1011FD1011FE1011FD1213FD1011FE1011FE1213FD1213FE1213FD1415FD1213FE1213FE1415FD1415FE1415FD1615FD1415FE1415FE1615FD1615FE1615FD1A13FD1615FE1615FE1A13FD1A13FE1A13FD1911FD1A13FE1A13FE1911FD1911FE1911FD170FFD1911FE1911FE170FFD170FFE170FFD0218FD170FFE170FFE0218FD0218FE0001020B01020304020304020B01020C04020304020C0402020D020B01020001020A06020A06020001020506020A06020506020908020908020506020708020218FD170FFD0E0FFD0E0FFD170FFD1011FD1011FD170FFD1911FD1011FD1911FD1213FD1213FD1911FD1A13FD1213FD1A13FD1415FD1415FD1A13FD1615FD';

  // Era 3
  bytes4 private constant thick2 = hex'000048C1';
  bytes private constant verts2 = hex'3BE137C21FB1014100000000BD09F0C179080F4281B321C269B7BAC172717FC1C1742FC272717F4181B321423BE13742BD09F0410000A02769B73A4228B305C256561F420BD74CC2AC7910411F2234C20000D0C1C7478EC1C17443C2C7478E4128B30542000050420BD74C421F223442';
  bytes private constant prog2 = hex'0001020304020001FE0001FE0304020304FE0506020001020506FE0506FE0001020001FE0708020506020708FE0708FE0506020506FE0908020708020908FE0908FE0708020708FE0A06020908020A06FE0A06FE0908020908FE0B01020A06020B01FE0B01FE0A06020A06FE0C04020B01020C04FE0C04FE0B01020B01FE0D0E020C04020D0EFE0D0EFE0C04020C04FE0304020D0E020304FE0304FE0D0E020D0EFE0D0EFE0F10FE0304FE0304FE0F10FE1112FE0304FE1112FE0001FE0001FE1112FE0506FE0506FE1112FE1314FE0506FE1314FE0708FE0708FE1314FE1516FE0708FE1516FE1716FE0C04FE1810FE0D0EFE0D0EFE1810FE0219FE0D0EFE0219FE0F10FE1810FE0C04FE1A12FE1A12FE0C04FE0B01FE1A12FE0B01FE0A06FE1A12FE0A06FE1B14FE1B14FE0A06FE0908FE1B14FE0908FE1716FE1716FE0908FE0708FE0219FD0F10FD0219FE0219FE0F10FD0F10FE0F10FD1112FD0F10FE0F10FE1112FD1112FE1112FD1314FD1112FE1112FE1314FD1314FE1314FD1516FD1314FE1314FE1516FD1516FE1516FD1716FD1516FE1516FE1716FD1716FE1716FD1B14FD1716FE1716FE1B14FD1B14FE1B14FD1A12FD1B14FE1B14FE1A12FD1A12FE1A12FD1810FD1A12FE1A12FE1810FD1810FE1810FD0219FD1810FE1810FE0219FD0219FE0001020B01020304020304020B01020C04020304020C04020D0E020B01020001020A06020A06020001020506020A06020506020908020908020506020708020219FD1810FD0F10FD0F10FD1810FD1112FD1112FD1810FD1A12FD1112FD1A12FD1314FD1314FD1A12FD1B14FD1314FD1B14FD1516FD1516FD1B14FD1716FD';

  bool private _mintApprovalRequired = true;

  mapping(address => bool) private _allowedToMint;

  mapping(uint256 => string) private _ownerSetURIs;

  constructor() ERC721("NonagonCup", "NON") Ownable() {}

  event Supported(
    address indexed supported,
    uint32 amount
  );

  event AllowedToMint(
    address indexed recipient,
    bool allowed
  );

  receive() external payable {
    emit Supported(_msgSender(), uint32(msg.value));
  }

  function allowedToMint(address a) public view returns(bool) {
    return(_allowedToMint[a]);
  }

  // when minting approval is required, accounts can mint when they have been added to the allowed mapping
  function claim() public nonReentrant {
    if (_mintApprovalRequired) {
      require(_allowedToMint[_msgSender()], 'address not allowed');
    }
    uint256 tokenId = 1 + totalSupply();
    require(tokenId < 2001);
    _allowedToMint[_msgSender()] = false;
    _safeMint(_msgSender(), tokenId);
  }

  // owner can add accounts to the allowed mapping
  function updateAllowedToMint(address[] calldata toAddresses, bool isAllowed) public onlyOwner {
    address curr;
    for (uint256 i=0; i < toAddresses.length; i++) {
      curr = toAddresses[i];
      require(curr !=  address(0));
      _allowedToMint[curr] = isAllowed;
      emit AllowedToMint(curr, isAllowed);
    }
  }

  // owner can airdop to any address
  function mintFullRide(address to) public onlyOwner {
    uint256 tokenId = 1 + totalSupply();
    require(tokenId < 2001);
    _safeMint(to, tokenId);
  }

  // owner can withdraw funds, partially motivated by need to carry out admin actions
  function withdrawFunds(uint256 amount) public onlyOwner {
    payable(owner()).transfer(amount);
  }

  function setMintApprovalRequired(bool val) public onlyOwner {
    _mintApprovalRequired = val;
  }

  function _baseURI() internal pure override returns (string memory) {
    return "https://nonagoncup.com/tokenId/";
  }

  // token owners can set their token's URI to point to an external URL
  // Note that it must return JSON matching the ERC-721 Non-Fungible Token Standard, optional metadata extension
  // See https://eips.ethereum.org/EIPS/eip-721
  function ownerSetTokenURI(uint256 tokenId, string calldata userSuppliedURI) public {
    require(_msgSender() == ownerOf(tokenId));
    _ownerSetURIs[tokenId] = userSuppliedURI;
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    bytes memory userSetURI = bytes(_ownerSetURIs[tokenId]);
    if (userSetURI.length != 0) {
      return(_ownerSetURIs[tokenId]);
    }
    return(super.tokenURI(tokenId));
  }

  // Implementation of the HasFile interface

  function getFilename(uint256 tokenId) public pure override returns(string memory filename) {
    require(tokenId > 0 && tokenId < 2001, "Token ID invalid");
    filename = string(abi.encodePacked("NonagonCup-", tokenId.toString(), ".stl" ));
  }

  function getFullFile(uint256 tokenId) public pure override returns(bytes memory fileContents) {
    for (uint256 i=0; i < 10; i++) {
      fileContents = bytes.concat(fileContents, getFileChunk(tokenId, i));
    }
  }

  function getFileChunksTotal(uint256) public pure override returns(uint256 count) {
    count = 10;
  }

  function getFileChunk(uint256 tokenId, uint256 index) public pure override returns(bytes memory data) {
    require(tokenId > 0 && tokenId < 2001, "Token ID invalid");
    require(index < 10, "index too large");
    if (index == 0) {
      // first chunk is header
      // STL File Header -- https://en.wikipedia.org/wiki/STL_(file_format)
      // 80 bytes -- descriptive text
      // 4 bytes -- little-endian unsigned int holding the total number of triangles
      bytes8 _c = hex"2020202020202020";
      data = bytes.concat(header, _c, _c, _c, _c, _c, _c, bytes4(facetCount << 24));
    } else {
      // body chunks have 8 triangles, except for last chunk which has 4
      index = (index - 1) * 8;
      data = bytes.concat(_getTriangleData(tokenId, index), _getTriangleData(tokenId, index + 1),
                          _getTriangleData(tokenId, index + 2), _getTriangleData(tokenId, index + 3));
      if (index < 64) {
        data = bytes.concat(data, _getTriangleData(tokenId, index + 4), _getTriangleData(tokenId, index + 5),
                                  _getTriangleData(tokenId, index + 6), _getTriangleData(tokenId, index + 7));
      }
    }
  }

  // STL File Triangle -- https://en.wikipedia.org/wiki/STL_(file_format)
  // total size - 50 bytes
  // 3 floats - normal -- NB omitted as interpreter will generate via right-hand rule
  // 3 floats - vertex 1
  // 3 floats - vertex 2
  // 3 floats - vertex 3
  // 2 bytes - attribute byte count (unused)
  function _getTriangleData(uint256 tokenId, uint256 triangle_offset) private pure returns(bytes memory data) {
    uint256 progOffset = triangle_offset * 9;
    bytes4[9] memory triData;
    bytes4 zeroFloat;
    bytes2 attrData;

    for (uint256 i=0; i < 9; i++) {
      triData[i] = _getVertexFloatValue(tokenId, progOffset + i);
    }

    bytes memory firstPart = bytes.concat(zeroFloat, zeroFloat, zeroFloat, triData[0], triData[1], triData[2], triData[3], triData[4], triData[5]);
    data =  bytes.concat(firstPart, triData[6], triData[7], triData[8], attrData);
  }

  function _getVertexFloatValue(uint256 tokenId, uint256 progOffset) private pure returns(bytes4 value){
    uint8 progVal;
    progVal = _getProgVals(tokenId, progOffset);

    // height scales with tokenId
    if (progVal == heightProgVal) {
      return(getHeightFloatValue(tokenId));
    }


    if ( tokenId < 460 ) {
      if (progVal == thickProgVal) {
        return(thick0);
      } else {
        uint256 start = progVal * 4;
        value = bytes4(bytes.concat(verts0[start], verts0[start + 1], verts0[start + 2], verts0[start + 3]));
      }
    } else if ( tokenId < 1144) {
      if (progVal == thickProgVal) {
        return(thick1);
      } else {
        uint256 start = progVal * 4;
        value = bytes4(bytes.concat(verts1[start], verts1[start + 1], verts1[start + 2], verts1[start + 3]));
      }
    } else {
      if (progVal == thickProgVal) {
        return(thick2);
      } else {
        uint256 start = progVal * 4;
        value = bytes4(bytes.concat(verts2[start], verts2[start + 1], verts2[start + 2], verts2[start + 3]));
      }
    }
  }

  function _getProgVals(uint256 tokenId, uint256 stepNo) private pure returns(uint8 progVal) {
    if (tokenId < 460) {
      progVal = uint8(prog0[stepNo]);
    }else if (tokenId < 1144) {
      progVal = uint8(prog1[stepNo]);
    }else {
      progVal = uint8(prog0[stepNo]);
    }
  }

  // returns height of cup for token in millimeters as IEEE 754 32-bit little-endian float
  // this is the interior height and does not include the vertical thickness of the base
  // To get the full height add the appropriate thick constant for the cup's era
  function getHeightFloatValue(uint256 tokenId) public pure returns(bytes4 value) {
    require(tokenId > 0 && tokenId < 2001, "Token ID invalid");
    uint32 heightBase = uint32(tokenId - 1);

    // determine height to nearest millimeter
    uint32 mmHeight = 50 + heightBase / 8;

    // determine mm height most significant bit
    uint32 mmHeightMSB = 6;
    if (mmHeight > 255) {
      mmHeightMSB = 9;
    } else if (mmHeight > 127) {
      mmHeightMSB = 8;
    } else if (mmHeight > 63) {
      mmHeightMSB = 7;
    }

    // position bits into mantissa
    mmHeight <<= 24 - mmHeightMSB;
    // clip off implicit first bit of mantissa
    uint32 mmHeightMask = 8388607;
    mmHeight &= mmHeightMask;

    // determine height fraction in 1/8 of a millimeter
    uint32 mmHeightFraction = heightBase % 8;
    // position bits into mantissa
    mmHeightFraction <<= 20 - mmHeightMSB;

    // normalize mantissa
    uint32 exponent = 126 + mmHeightMSB;
    // position bits into exponent
    exponent <<= 23;

    // combine parts
    bytes4 b_val = bytes4(exponent | mmHeight | mmHeightFraction);
    // return little-endian representation
    value = bytes4(bytes.concat(b_val[3], b_val[2], b_val[1], b_val[0]));
  }

}