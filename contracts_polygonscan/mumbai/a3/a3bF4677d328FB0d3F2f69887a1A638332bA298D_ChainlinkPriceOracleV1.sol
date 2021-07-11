/**
 *Submitted for verification at polygonscan.com on 2021-07-11
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/protocol/lib/Monetary.sol

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

pragma solidity ^0.5.7;


/**
 * @title Monetary
 * @author dYdX
 *
 * Library for types involving money
 */
library Monetary {

    /*
     * The price of a base-unit of an asset. Has `36 - token.decimals` decimals
     */
    struct Price {
        uint256 value;
    }

    /*
     * Total value of an some amount of an asset. Equal to (price * amount). Has 36 decimals.
     */
    struct Value {
        uint256 value;
    }
}

// File: contracts/protocol/interfaces/IPriceOracle.sol

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

pragma solidity ^0.5.7;


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

// File: contracts/external/interfaces/IChainlinkAggregator.sol

/*

    Copyright 2020 Dolomite.

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

pragma solidity ^0.5.7;

/**
 * @title IChainlinkAggregator
 * @author Dolomite
 *
 * Gets the latest price from the Chainlink Oracle Network. Amount of decimals depends on the base.
 */
contract IChainlinkAggregator {

    function latestAnswer() public view returns (int256);

}

// File: contracts/external/oracles/ChainlinkPriceOracleV1.sol

/*

    Copyright 2020 Dolomite.

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

pragma solidity ^0.5.7;






/**
 * @title ChainlinkPriceOracleV1
 * @author Dolomite
 *
 * An implementation of the dYdX IPriceOracle interface that makes Chainlink prices compatible with the protocol.
 */
contract ChainlinkPriceOracleV1 is IPriceOracle, Ownable {

    using SafeMath for uint;

    event TokenInsertedOrUpdated(
        address indexed token,
        address indexed aggregator,
        address indexed tokenPair
    );

    mapping(address => IChainlinkAggregator) public tokenToAggregatorMap;
    mapping(address => uint8) public tokenToDecimalsMap;

    // Defaults to USD if the value is the ZERO address
    mapping(address => address) public tokenToPairingMap;
    // Should defaults to CHAINLINK_USD_DECIMALS when value is empty
    mapping(address => uint8) public tokenToAggregatorDecimalsMap;

    uint8 public CHAINLINK_USD_DECIMALS = 8;
    uint8 public CHAINLINK_ETH_DECIMALS = 18;

    /**
     * Note, these arrays are set up, such that each index corresponds with one-another.
     *
     * @param tokens                The tokens that are supported by this adapter.
     * @param chainlinkAggregators  The Chainlink aggregators that have on-chain prices.
     * @param tokenDecimals         The number of decimals that each token has.
     * @param tokenPairs            The token against which this token's value is compared using the aggregator. The
     *                              zero address means USD.
     * @param aggregatorDecimals    The number of decimals that the value has that comes back from the corresponding
     *                              Chainlink Aggregator.
     */
    constructor(
        address[] memory tokens,
        address[] memory chainlinkAggregators,
        uint8[] memory tokenDecimals,
        address[] memory tokenPairs,
        uint8[] memory aggregatorDecimals
    ) public {
        require(
            tokens.length == chainlinkAggregators.length,
            "ChainlinkPriceOracleV1::constructor: INVALID_LENGTH_AGGREGATORS"
        );
        require(
            chainlinkAggregators.length == tokenDecimals.length,
            "ChainlinkPriceOracleV1::constructor: INVALID_LENGTH_TOKEN_DECIMALS"
        );
        require(
            tokenDecimals.length == tokenPairs.length,
            "ChainlinkPriceOracleV1::constructor: INVALID_LENGTH_TOKEN_PAIRS"
        );
        require(
            tokenPairs.length == aggregatorDecimals.length,
            "ChainlinkPriceOracleV1::constructor: INVALID_LENGTH_AGGREGATOR_DECIMALS"
        );

        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            tokenToAggregatorMap[token] = IChainlinkAggregator(chainlinkAggregators[i]);
            tokenToDecimalsMap[token] = tokenDecimals[i];
            if (tokenPairs[i] != address(0)) {
                tokenToPairingMap[token] = tokenPairs[i];
                tokenToAggregatorDecimalsMap[token] = aggregatorDecimals[i];
            }
        }
    }

    // ============ Admin Functions ============

    function insertOrUpdateOracleToken(
        address token,
        uint8 tokenDecimals,
        address chainlinkAggregator,
        uint8 aggregatorDecimals,
        address tokenPair
    ) public onlyOwner {
        tokenToAggregatorMap[token] = IChainlinkAggregator(chainlinkAggregator);
        tokenToDecimalsMap[token] = tokenDecimals;
        if (tokenPair != address(0)) {
            // The aggregator's price is NOT against USD. Therefore, we need to store what it's against as well as the
            // # of decimals the aggregator's price has.
            tokenToPairingMap[token] = tokenPair;
            tokenToAggregatorDecimalsMap[token] = aggregatorDecimals;
        }
        emit TokenInsertedOrUpdated(token, chainlinkAggregator, tokenPair);
    }

    // ============ Public Functions ============

    function getPrice(
        address token
    )
    public
    view
    returns (Monetary.Price memory) {
        require(
            address(tokenToAggregatorMap[token]) != address(0),
            "ChainlinkPriceOracleV1::getPrice: INVALID_TOKEN"
        );

        uint rawChainlinkPrice = uint(tokenToAggregatorMap[token].latestAnswer());
        address tokenPair = tokenToPairingMap[token];

        // standardize the Chainlink price to be the proper number of decimals of (36 - tokenDecimals)
        uint standardizedPrice = standardizeNumberOfDecimals(
            tokenToDecimalsMap[token],
            rawChainlinkPrice,
            tokenPair == address(0) ? CHAINLINK_USD_DECIMALS : tokenToAggregatorDecimalsMap[token]
        );

        if (tokenPair == address(0)) {
            // The pair has a USD base, we are done.
            return Monetary.Price({value : standardizedPrice});
        } else {
            // The price we just got and converted is NOT against USD. So we need to get its pair's price against USD.
            // We can do so by recursively calling #getPrice using the `tokenPair` as the parameter instead of `token`.
            uint tokenPairStandardizedPrice = getPrice(tokenPair).value;
            // Standardize the price to use 36 decimals.
            uint tokenPairWith36Decimals = tokenPairStandardizedPrice.mul(10 ** uint(tokenToDecimalsMap[tokenPair]));
            // Now that the chained price uses 36 decimals (and thus is standardized), we can do easy math.
            return Monetary.Price({value : standardizedPrice.mul(tokenPairWith36Decimals).div(ONE_DOLLAR)});
        }
    }

    /**
     * Standardizes `value` to have `ONE_DOLLAR` - `tokenDecimals` number of decimals.
     */
    function standardizeNumberOfDecimals(
        uint8 tokenDecimals,
        uint value,
        uint8 valueDecimals
    ) public pure returns (uint) {
        uint tokenDecimalsFactor = 10 ** uint(tokenDecimals);
        uint priceFactor = IPriceOracle.ONE_DOLLAR.div(tokenDecimalsFactor);
        uint valueFactor = 10 ** uint(valueDecimals);
        return value.mul(priceFactor).div(valueFactor);
    }

}