/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// Sources flattened with hardhat v2.3.3 https://hardhat.org

// File contracts/interfaces/IYearn.sol

pragma solidity 0.8.4;

interface IYearn {
    function pricePerShare() external view returns (uint256);
    function decimals() external view returns(uint256);
    function token() external view returns(address);
}


// File contracts/interfaces/AggregatorV3Interface.sol

pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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


// File contracts/core/YearnOracle.sol

// SPDX-License-Identifier: (c) Armor.Fi, 2021

pragma solidity 0.8.4;


/**
 * @title Yearn Oracle
 * @notice Yearn Oracle uses Chainlink to find the price of underlying Yearn assets,
 *         then determines amount of yTokens to pay for Ether needed by shield.
 * @author Armor.fi -- Robert M.C. Forster, Taek Lee
**/
contract YearnOracle {

    /**
     * @notice Get the amount of tokens owed for the input amount of Ether.
     * @param _ethOwed Amount of Ether that the shield owes to coverage base.
     * @param _yToken Address of the Yearn token to find value of.
     * @param _uTokenLink Chainlink address to get price of the underlying token.
     * @return yOwed Amount of Yearn token owed for this amount of Ether.
    **/
    function getTokensOwed(
        uint256 _ethOwed,
        address _yToken,
        address _uTokenLink
    )
      external
      view
    returns(
        uint256 yOwed
    )
    {   
        uint256 uOwed = ethToU(_ethOwed, _uTokenLink);
        yOwed = uToY(_yToken, uOwed);
    }
    
    /**
     * @notice Get the Ether owed for an amount of tokens that must be paid for.
     * @param _tokensOwed Amounts of tokens to find value of.
     * @param _yToken Address of the Yearn token that value is being found for.
     * @param _uTokenLink ChainLink address for the underlying token.
     * @return ethOwed Amount of Ether owed for this amount of tokens.
    **/
    function getEthOwed(
        uint256 _tokensOwed,
        address _yToken,
        address _uTokenLink
    )
      external
      view
    returns(
        uint256 ethOwed
    )
    {
        uint256 yPerU = uToY(_yToken, 1 ether);
        uint256 ethPerU = _findEthPerToken(_uTokenLink);
        uint256 ethPerY = yPerU
                          * ethPerU
                          / 1 ether;

        ethOwed = _tokensOwed
                  * ethPerY
                  / 1 ether;
    }

    /**
     * @notice Ether amount to underlying token owed.
     * @param _ethOwed Amount of Ether owed to the coverage base.
     * @param _uTokenLink Chainlink oracle address for the underlying token.
     * @return uOwed Amount of underlying tokens owed.
    **/
    function ethToU(
        uint256 _ethOwed,
        address _uTokenLink
    )
      public
      view
    returns(
        uint256 uOwed
    )
    {
        uint256 ethPerToken = _findEthPerToken(_uTokenLink);
        uOwed = _ethOwed 
                * 1 ether 
                / ethPerToken;
    }

    /**
     * @notice Underlying tokens to Yearn tokens conversion.
     * @param _yToken Address of the Yearn token.
     * @param _uOwed Amount of underlying tokens owed.
     * @return yOwed Amount of Yearn tokens owed.
    **/
    function uToY(
        address _yToken,
        uint256 _uOwed
    )
      public
      view
    returns(
        uint256 yOwed
    )
    {
        uint256 oneYToken = IYearn(_yToken).pricePerShare();
        yOwed = _uOwed 
                * (10 ** IYearn(_yToken).decimals())
                / oneYToken;
    }
    
    /**
     * @notice Finds the amount of cover required to protect all holdings and returns Ether value of 1 token.
     * @param _uTokenLink Chainlink oracle address for the underlying token.
     * @return ethPerToken Ether value of each pToken.
    **/
    function _findEthPerToken(
        address _uTokenLink
    )
      internal
      view
    returns (
        uint256 ethPerToken
    )
    {
        (/*roundIf*/, int tokenPrice, /*startedAt*/, /*timestamp*/, /*answeredInRound*/) = AggregatorV3Interface(_uTokenLink).latestRoundData();
        ethPerToken = uint256(tokenPrice);
    }
    
}