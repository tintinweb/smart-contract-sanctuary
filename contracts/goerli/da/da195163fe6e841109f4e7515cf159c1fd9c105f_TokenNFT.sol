/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

/**************************************************************************
 *            ____        _                              
 *           / ___|      | |     __ _  _   _   ___  _ __ 
 *          | |    _____ | |    / _` || | | | / _ \| '__|
 *          | |___|_____|| |___| (_| || |_| ||  __/| |   
 *           \____|      |_____|\__,_| \__, | \___||_|   
 *                                     |___/             
 * 
 **************************************************************************
 *
 *  The MIT License (MIT)
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2016-2021 Cyril Lapinte
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 **************************************************************************
 *
 * Flatten Contract: TokenNFT
 *
 **************************************************************************/
// File contracts/interface/INFT.sol

pragma solidity ^0.8.0;


/**
 * @title INFT interface
 *
 * @author Cyril Lapinte - <[email protected]>
 */
interface INFT {

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
  event ApprovalMaskUpdate(
    address indexed owner, address indexed approvee, uint256 indexed mask);

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function baseURI() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function tokenURI(uint256 _indexId) external view returns (string memory);

  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function tokenByIndex(uint256 _index) external view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index)
    external view returns (uint256);

  function approvals(address _owner, address _spender)
    external view returns (uint256);
  function isApproved(address _owner, address _spender, uint256 _tokenId)
    external view returns (bool);
  function isApprovedForAll(address _owner, address _spender)
    external view returns (bool);

  function transfer(address _to, uint256 _tokenId) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _tokenId)
    external returns (bool);

  function approve(address _approved, uint256 _tokenId) external returns (bool);

  function setApprovalMask(address _spender, uint256 _mask) external returns (bool);
}


// File contracts/convert/Bytes32Convert.sol

pragma solidity ^0.8.0;


/**
 * @title Bytes32Convert
 * @dev Convert bytes32 to string
 *
 * @author Cyril Lapinte - <[email protected]>
 **/
library Bytes32Convert {

  /**
  * @dev toString
  */
  function toString(bytes32 _input) internal pure returns (string memory result) {
    bytes memory reversed = new bytes(32);
    uint256 i = 0;
    uint256 v = uint256(_input);
    while (v != 0) {
      reversed[i++] = bytes1(uint8(48 + (v % 16)));
      v = v / 16;
    }
    bytes memory s = new bytes(i);
    for (uint j = 0; j < i; j++) {
      s[j] = reversed[i - j - 1];
    }

    result = string(s);
  }
}


// File contracts/token/TokenNFT.sol

pragma solidity ^0.8.0;


/**
 * @title TokenNFT contract
 *
 * @author Cyril Lapinte - <[email protected]>
 *
 * Error messages
 *   NFT01: Recipient is invalid
 *   NFT02: Sender is not the owner
 *   NFT03: Sender is not approved
 */
contract TokenNFT is INFT {
  using Bytes32Convert for bytes32;

  uint256 constant ALL_TOKENS = ~uint256(0);
  uint256 constant NO_TOkENS = uint256(0);

  string internal name_;
  string internal symbol_;
  string internal baseURI_;

  uint256 internal totalSupply_;

  struct Owner {
    uint256 balance;
    mapping (uint256 => uint256) ownedTokenIds;
    mapping (uint256 => uint256) ownedTokenIndexes;
    mapping (address => uint256) approvalMasks;
  }

  mapping (uint256 => uint256) internal tokenIds;
  mapping (uint256 => address) internal ownersAddresses;
  mapping (address => Owner) internal owners;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseURI,
    address _initialOwner,
    uint256[] memory _initialTokenIds
  ) {
    name_ = _name;
    symbol_ = _symbol;
    baseURI_ = _baseURI;
    totalSupply_ = _initialTokenIds.length;

    Owner storage owner_ = owners[_initialOwner];
    owner_.balance = _initialTokenIds.length;

    for(uint256 i=0; i < _initialTokenIds.length; i++) {
      tokenIds[i] = _initialTokenIds[i];
      ownersAddresses[_initialTokenIds[i]] = _initialOwner;
      owner_.ownedTokenIds[i] = _initialTokenIds[i];
      owner_.ownedTokenIndexes[_initialTokenIds[i]] = i;
      emit Transfer(address(0), _initialOwner, _initialTokenIds[i]);
    }
  }

  function name() external override view returns (string memory) {
    return name_;
  }

  function symbol() external override view returns (string memory) {
    return symbol_;
  }

  function baseURI() external override view returns (string memory) {
    return baseURI_;
  }

  function totalSupply() external override view returns (uint256) {
    return totalSupply_;
  }

  function tokenURI(uint256 _indexId) external override view returns (string memory) {
    return string(abi.encodePacked(baseURI_, bytes32(_indexId).toString()));
  }

  function tokenByIndex(uint256 _index) external override view returns (uint256) {
    return tokenIds[_index];
  }

  function balanceOf(address _owner) external override view returns (uint256) {
    return owners[_owner].balance;
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index)
    external override view returns (uint256)
  {
    return owners[_owner].ownedTokenIds[_index];
  }

  function ownerOf(uint256 _tokenId) external override view returns (address) {
    return ownersAddresses[_tokenId];
  }

  function approvals(address _owner, address _spender)
    external override view returns (uint256)
  {
    return owners[_owner].approvalMasks[_spender];
  }

  function isApproved(address _owner, address _spender, uint256 _tokenId)
    external override view returns (bool)
  {
    return owners[_owner].approvalMasks[_spender] & _tokenId == _tokenId;
  }

  function isApprovedForAll(address _owner, address _spender)
    external override view returns (bool)
  {
    return owners[_owner].approvalMasks[_spender] == ALL_TOKENS;
  }

  function transfer(address _to, uint256 _tokenId)
    external override returns (bool)
  {
    return transferFromInternal(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId)
    external override returns (bool)
  {
    return transferFromInternal(_from, _to, _tokenId);
  }

  function approve(address _spender, uint256 _tokenId)
    external override returns (bool)
  {
    require(ownersAddresses[_tokenId] == msg.sender, "NFT02");
    owners[msg.sender].approvalMasks[_spender] |= _tokenId;

    emit Approval(msg.sender, _spender, _tokenId);
    return true;
  }

  function setApprovalMask(address _spender, uint256 _mask)
    external override returns (bool)
  {
    owners[msg.sender].approvalMasks[_spender] = _mask;

    emit ApprovalMaskUpdate(msg.sender, _spender, _mask);
    return true;
  }

  function transferFromInternal(address _from, address _to, uint256 _tokenId)
    internal returns (bool)
  {
    require(_to != address(0), "NFT01");
    require(ownersAddresses[_tokenId] == _from, "NFT02");
    require(msg.sender == _from ||
      (owners[_from].approvalMasks[_to] & _tokenId == _tokenId), "NFT03");

    ownersAddresses[_tokenId] = _to;

    Owner storage from = owners[_from];
    from.ownedTokenIds[from.ownedTokenIndexes[_tokenId]] =
      from.ownedTokenIds[from.balance-1];
    from.ownedTokenIds[from.balance-1] = 0;
    from.balance--;

    Owner storage to = owners[_to];
    to.ownedTokenIds[to.balance] = _tokenId;
    to.ownedTokenIndexes[_tokenId] = to.balance;
    to.balance++;

    emit Transfer(_from, _to, _tokenId);
    return true;
  }
}