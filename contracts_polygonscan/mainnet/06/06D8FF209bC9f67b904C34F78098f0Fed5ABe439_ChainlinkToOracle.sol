/**
 *Submitted for verification at polygonscan.com on 2021-07-24
*/

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

interface ILastPrice{
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface IDecimals{
    function decimals() external view returns (uint8) ;
}
contract ChainlinkToOracle {

    address public priceFeed;
    

    uint8 constant public decimalsusdc = 6;
    uint8 public decimalsFToken;
    
    string public oracle;
    
    uint8 oracleDecimals;

    address public fToken;
    address constant public usdc = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    constructor(address _fTokenOracle, address _fToken, string memory _oracle){
        priceFeed = _fTokenOracle;
        fToken = _fToken;
        oracle = _oracle;
        
        oracleDecimals = IDecimals(priceFeed).decimals();
        decimalsFToken = IDecimals(fToken).decimals();
    }

    /**
     * Returns the latest price
     */
     
    function getPrice(address, address) external view returns (uint price, uint lastUpdate){
      (,int answer,,uint time,) = ILastPrice(priceFeed).latestRoundData();
      uint fPrice = usdc > fToken ? uint(answer)*1e18/(10**oracleDecimals)*(10**decimalsusdc)/(10**decimalsFToken) : uint(answer)*1e18/(10**oracleDecimals)*(10**decimalsFToken)/(10**decimalsusdc);
      uint rTime = time;
      return (uint(fPrice),rTime);
    }
}