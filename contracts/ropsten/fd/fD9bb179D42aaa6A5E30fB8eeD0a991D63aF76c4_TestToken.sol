// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "ERC721.sol";


contract TestToken is ERC721 {
  constructor () ERC721("TestToken", "TTT") {
    // _mint(
    //   msg.sender,
    //   1366613 * 10 ** decimals()
    // );
  }
}