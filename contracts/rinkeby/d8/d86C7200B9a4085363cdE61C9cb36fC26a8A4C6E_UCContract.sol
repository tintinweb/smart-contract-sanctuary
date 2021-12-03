// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract UCContract{
  mapping(address => uint[]) public balances;
  mapping(uint => address) public owners;

  constructor(){}

  function balanceOf( address owner ) external view returns( uint ){
    return balances[ owner ].length;
  }

  function ownerOf( uint tokenId ) external view returns( address ){
    return owners[tokenId];
  }

  function setTokens( address owner, uint[] calldata tokenIds ) external {
    balances[ msg.sender ] = tokenIds;
    for(uint i; i < tokenIds.length; ++i ){
      owners[ tokenIds[ i ] ] = owner;
    }
  }

  function walletOfOwner( address owner ) external view returns( uint[] memory ){
    return balances[ owner ];
  }
}