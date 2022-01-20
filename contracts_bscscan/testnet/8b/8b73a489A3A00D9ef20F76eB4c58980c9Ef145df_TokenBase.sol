/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenBase {
  
   address public s;
  string public v;
  uint256 public  a;
  uint256 public b;
  uint8 public vss;
  bytes32 public rss;
  
  function transferToken(
        address[2] calldata addrs,//[userAddr,tokenAddr]
        uint256[3] calldata uints,//[fragment,_amount,time]
        string[2] calldata strs,//[chain,txid]
        uint8[] calldata vs,
        bytes32[] calldata rssMetadata
    ) external{
      s = addrs[0];
      a = uints[0];
      v = strs[0];
      vss = vs[0];
      rss = rssMetadata[0];

    }
 
}