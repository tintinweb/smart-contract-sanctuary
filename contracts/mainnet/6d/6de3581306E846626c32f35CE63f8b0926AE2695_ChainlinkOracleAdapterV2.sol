/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: chainlink/v0.5/contracts/dev/AggregatorInterface.sol

pragma solidity ^0.5.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// File: contracts/meta-oracles/proxies/ChainlinkOracleAdapterV2.sol

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;




/**
 * @title ChainlinkOracleAdapterV2
 * @author Set Protocol
 *
 * Coerces outputs from Chainlink oracles to uint256 and adapts value to 18 decimals.
 */
contract ChainlinkOracleAdapterV2 {
    using SafeMath for uint256;

    /* ============ State Variables ============ */
    AggregatorInterface public oracle;
    uint256 public priceMultiplier;

    /* ============ Constructor ============ */
    /*
     * Set address of aggregator being adapted for use. Different oracles return prices with different decimals.
     * In this iteration of ChainLinkOracleAdapter, we allow the deployer to specify the multiple decimal
     * to pass into the contract
     *
     * DPI (18): https://etherscan.io/address/0xD2A593BF7594aCE1faD597adb697b5645d5edDB2
     * DAI (8): https://etherscan.io/address/0xaed0c38402a5d19df6e4c03f4e2dced6e29c1ee9
     *
     * @param  _oracle                  The address of medianizer being adapted from bytes to uint256
     * @param  _priceMultiplierDecimals Decimal places to convert
     */
    constructor(
        AggregatorInterface _oracle,
        uint256 _priceMultiplierDecimals
    )
        public
    {
        oracle = _oracle;
        priceMultiplier = 10 ** _priceMultiplierDecimals;
    }

    /* ============ External ============ */

    /*
     * Reads value of oracle and coerces return to uint256 then applies price multiplier
     *
     * @returns         Chainlink oracle price in uint256
     */
    function read()
        external
        view
        returns (uint256)
    {
        // Read value of medianizer and coerce to uint256
        uint256 oracleOutput = uint256(oracle.latestAnswer());

        // Apply multiplier to create 18 decimal price (since Chainlink returns 8 decimals)
        return oracleOutput.mul(priceMultiplier);
    }
}