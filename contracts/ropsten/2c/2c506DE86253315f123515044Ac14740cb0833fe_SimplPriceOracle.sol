/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

/**
 *Submitted for verification at Etherscan.io on 2019-05-07
*/

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title Monetary
 * @author dYdX
 *
 * Library for types involving money
 */
library Monetary {

    /*
     * The price of a base-unit of an asset.
     */
    struct Price {
        uint256 value;
    }

    /*
     * Total value of an some amount of an asset. Equal to (price * amount).
     */
    struct Value {
        uint256 value;
    }
}

// File: contracts/protocol/interfaces/IPriceOracle.sol

/**
 * @title IPriceOracle
 * @author dYdX
 *
 * Interface that Price Oracles for Solo must implement in order to report prices.
 */
contract IPriceOracle {

    // ============ Constants ============

    uint256 public constant ONE_DOLLAR = 10 ** 36;

    // ============ Public Functions ============

    /**
     * Get the price of a token
     *
     * @param  token  The ERC20 token address of the market
     * @return        The USD price of a base unit of the token, then multiplied by 10^36.
     *                So a USD-stable coin with 18 decimal places would return 10^18.
     *                This is the price of the base unit rather than the price of a "human-readable"
     *                token amount. Every ERC20 may have a different number of decimals.
     */
    function getPrice(
        address token
    )
        public
        view
        returns (Monetary.Price memory);
}


// File: contracts/external/oracles/DaiPriceOracle.sol

/**
 * @title DaiPriceOracle
 * @author dYdX
 *
 * PriceOracle that gives the price of Dai in USD
 */
contract SimplPriceOracle is
    
    IPriceOracle
{
   

    // ============ Constants ============

    bytes32 constant FILE = "SimplPriceOracle";

    uint256 constant DECIMALS = 18;

    uint256 constant EXPECTED_PRICE = ONE_DOLLAR / (10 ** DECIMALS);

    // ============ Structs ============

    struct PriceInfo {
        uint128 price;
        uint32 lastUpdate;
    }


    // ============ Events ============

    event PriceSet(
        PriceInfo newPriceInfo
    );

    // ============ Storage ============

    PriceInfo public g_priceInfo;

    

    // ============ Constructor =============

    constructor(
       
    )
        public
    {
       
        g_priceInfo = PriceInfo({
            lastUpdate: uint32(block.timestamp),
            price: uint128(EXPECTED_PRICE)
        });
    }

    // ============ Admin Functions ============

  

    // ============ Public Functions ============

    function updatePrice(
        uint128 newprice
    )
        public
        returns (PriceInfo memory)
    {
        

        g_priceInfo = PriceInfo({
            price: newprice,
            lastUpdate: uint32(block.timestamp)
        });

        emit PriceSet(g_priceInfo);
        return g_priceInfo;
    }

    // ============ IPriceOracle Functions ============

    function getPrice(
        address /* token */
    )
        public
        view
        returns (Monetary.Price memory)
    {
        return Monetary.Price({
            value: g_priceInfo.price
        });
    }

}