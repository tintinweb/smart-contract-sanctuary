/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



// Part: IMisoMarket

interface IMisoMarket {

    function initMarket(
        bytes calldata data
    ) external;

    function getMarkets() external view returns(address[] memory);

    function getMarketTemplateId(address _auction) external view returns(uint64);
}

// Part: IMisoTokenFactory

interface IMisoTokenFactory {
    function numberOfTokens() external view returns (uint256);
    function getTokens() external view returns (address[] memory);
}

// File: MISOHelper.sol

contract MISOHelper {
    IMisoMarket public market;
    IMisoTokenFactory public tokenFactory;
    // IMisoLauncher public launcher;
    
    function setContracts(address _market, address _tokenFactory) public {
        market = IMisoMarket(_market);
        tokenFactory = IMisoTokenFactory(_tokenFactory);
    }

    function getData() public view returns(address) {
        return msg.sender;
    }
}