/**
 *Submitted for verification at Etherscan.io on 2020-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

pragma experimental ABIEncoderV2;

interface OrFeed {
  function getTokenAddress (string calldata symbol) external view returns (address);
  function arb (address fundsReturnToAddress, address liquidityProviderContractAddress, string[] calldata tokens,  uint256 amount, string[] calldata exchanges) external payable returns (bool);
}

contract OrFeedInterface {
    OrFeed orFeed;
    
    constructor() public {
        orFeed = OrFeed(0x8316B082621CFedAB95bf4a44a1d4B64a6ffc336);
    }
    
    function getTokenAddress(string memory _symbol) public view returns (address result) {
        result = orFeed.getTokenAddress(_symbol);
    }
    
    function arbitrage(address returnAddress, address liquidityAddress, string[] memory tokens,  uint256 amount, string[] memory exchanges) public payable returns (bool result) {
        result = orFeed.arb(returnAddress, liquidityAddress, tokens, amount, exchanges);
    }
}