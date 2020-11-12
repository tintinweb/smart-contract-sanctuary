/*
 * Origin Protocol
 * https://originprotocol.com
 *
 * Released under the MIT license
 * https://github.com/OriginProtocol/origin-dollar
 *
 * Copyright 2020 Origin Protocol, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
// File: contracts/interfaces/uniswap/IUniswapV2Pair.sol

pragma solidity 0.5.11;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function sync() external;
}

// File: contracts/oracle/UniswapLib.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.11;

// Based on code from https://github.com/Uniswap/uniswap-v2-periphery

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // returns a uq112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << 112) / denominator);
    }

    // decode a uq112x112 into a uint with 18 decimals of precision
    function decode112with18(uq112x112 memory self)
        internal
        pure
        returns (uint256)
    {
        // we only have 256 - 224 = 32 bits to spare, so scaling up by ~60 bits is dangerous
        // instead, get close to:
        //  (x * 1e18) >> 112
        // without risk of overflowing, e.g.:
        //  (x) / 2 ** (112 - lg(1e18))
        return uint256(self._x) / 5192296858534827;
    }
}

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative +=
                uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
                timeElapsed;
            // counterfactual
            price1Cumulative +=
                uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
                timeElapsed;
        }
    }
}

// File: contracts/interfaces/IPriceOracle.sol

pragma solidity 0.5.11;

interface IPriceOracle {
    /**
     * @dev returns the asset price in USD, 6 decimal digits.
     * Compatible with the Open Price Feed.
     */
    function price(string calldata symbol) external view returns (uint256);
}

// File: contracts/interfaces/IEthUsdOracle.sol

pragma solidity 0.5.11;

interface IEthUsdOracle {
    /**
     * @notice Returns ETH price in USD.
     * @return Price in USD with 6 decimal digits.
     */
    function ethUsdPrice() external view returns (uint256);

    /**
     * @notice Returns token price in USD.
     * @param symbol. Asset symbol. For ex. "DAI".
     * @return Price in USD with 6 decimal digits.
     */
    function tokUsdPrice(string calldata symbol)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the asset price in ETH.
     * @param symbol. Asset symbol. For ex. "DAI".
     * @return Price in ETH with 8 decimal digits.
     */
    function tokEthPrice(string calldata symbol) external returns (uint256);
}

interface IViewEthUsdOracle {
    /**
     * @notice Returns ETH price in USD.
     * @return Price in USD with 6 decimal digits.
     */
    function ethUsdPrice() external view returns (uint256);

    /**
     * @notice Returns token price in USD.
     * @param symbol. Asset symbol. For ex. "DAI".
     * @return Price in USD with 6 decimal digits.
     */
    function tokUsdPrice(string calldata symbol)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the asset price in ETH.
     * @param symbol. Asset symbol. For ex. "DAI".
     * @return Price in ETH with 8 decimal digits.
     */
    function tokEthPrice(string calldata symbol)
        external
        view
        returns (uint256);
}

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: contracts/governance/Governable.sol

pragma solidity 0.5.11;

/**
 * @title OUSD Governable Contract
 * @dev Copy of the openzeppelin Ownable.sol contract with nomenclature change
 *      from owner to governor and renounce methods removed. Does not use
 *      Context.sol like Ownable.sol does for simplification.
 * @author Origin Protocol Inc
 */
contract Governable {
    // Storage position of the owner and pendingOwner of the contract
    bytes32
        private constant governorPosition = 0x7bea13895fa79d2831e0a9e28edede30099005a50d652d8957cf8a607ee6ca4a;
    //keccak256("OUSD.governor");

    bytes32
        private constant pendingGovernorPosition = 0x44c4d30b2eaad5130ad70c3ba6972730566f3e6359ab83e800d905c61b1c51db;
    //keccak256("OUSD.pending.governor");

    event PendingGovernorshipTransfer(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    event GovernorshipTransferred(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial Governor.
     */
    constructor() internal {
        _setGovernor(msg.sender);
        emit GovernorshipTransferred(address(0), _governor());
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function governor() public view returns (address) {
        return _governor();
    }

    function _governor() internal view returns (address governorOut) {
        bytes32 position = governorPosition;
        assembly {
            governorOut := sload(position)
        }
    }

    function _pendingGovernor()
        internal
        view
        returns (address pendingGovernor)
    {
        bytes32 position = pendingGovernorPosition;
        assembly {
            pendingGovernor := sload(position)
        }
    }

    /**
     * @dev Throws if called by any account other than the Governor.
     */
    modifier onlyGovernor() {
        require(isGovernor(), "Caller is not the Governor");
        _;
    }

    /**
     * @dev Returns true if the caller is the current Governor.
     */
    function isGovernor() public view returns (bool) {
        return msg.sender == _governor();
    }

    function _setGovernor(address newGovernor) internal {
        bytes32 position = governorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    function _setPendingGovernor(address newGovernor) internal {
        bytes32 position = pendingGovernorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Transfers Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the current Governor. Must be claimed for this to complete
     * @param _newGovernor Address of the new Governor
     */
    function transferGovernance(address _newGovernor) external onlyGovernor {
        _setPendingGovernor(_newGovernor);
        emit PendingGovernorshipTransfer(_governor(), _newGovernor);
    }

    /**
     * @dev Claim Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the new Governor.
     */
    function claimGovernance() external {
        require(
            msg.sender == _pendingGovernor(),
            "Only the pending Governor can complete the claim"
        );
        _changeGovernor(msg.sender);
    }

    /**
     * @dev Change Governance of the contract to a new account (`newGovernor`).
     * @param _newGovernor Address of the new Governor
     */
    function _changeGovernor(address _newGovernor) internal {
        require(_newGovernor != address(0), "New Governor is address(0)");
        emit GovernorshipTransferred(_governor(), _newGovernor);
        _setGovernor(_newGovernor);
    }
}

// File: contracts/governance/InitializableGovernable.sol

pragma solidity 0.5.11;

/**
 * @title OUSD InitializableGovernable Contract
 * @author Origin Protocol Inc
 */

contract InitializableGovernable is Governable, Initializable {
    function _initialize(address _governor) internal {
        _changeGovernor(_governor);
    }
}

// File: contracts/oracle/OpenUniswapOracle.sol

pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

/**
 * @title OUSD OpenUniswapOracle Contract
 * @author Origin Protocol Inc
 */




contract OpenUniswapOracle is IEthUsdOracle, InitializableGovernable {
    using FixedPoint for *;
    uint256 public constant PERIOD = 2 minutes;

    struct SwapConfig {
        bool ethOnFirst; // whether the weth is the first in pair
        address swap; // address of the uniswap pair
        uint256 blockTimestampLast;
        uint256 latestBlockTimestampLast;
        uint256 priceCumulativeLast;
        uint256 latestPriceCumulativeLast;
        uint256 baseUnit;
    }

    mapping(bytes32 => SwapConfig) swaps;

    IPriceOracle public ethPriceOracle; //price oracle for getting the Eth->USD price OPEN oracle..
    address ethToken;
    string constant ethSymbol = "ETH";
    bytes32 constant ethHash = keccak256(abi.encodePacked(ethSymbol));

    constructor(address ethPriceOracle_, address ethToken_) public {
        ethPriceOracle = IPriceOracle(ethPriceOracle_);
        ethToken = ethToken_;
    }

    function registerEthPriceOracle(address ethPriceOracle_)
        public
        onlyGovernor
    {
        ethPriceOracle = IPriceOracle(ethPriceOracle_);
    }

    function registerPair(address pair_) public onlyGovernor {
        IUniswapV2Pair pair = IUniswapV2Pair(pair_);
        address token;
        bool ethOnFirst = true;
        if (pair.token0() == ethToken) {
            token = pair.token1();
        } else {
            token = pair.token0();
            ethOnFirst = false;
        }
        SymboledERC20 st = SymboledERC20(token);
        string memory symbol = st.symbol();
        SwapConfig storage config = swaps[keccak256(abi.encodePacked(symbol))];

        // is the first token the eth Token
        config.ethOnFirst = ethOnFirst;
        config.swap = pair_;
        config.baseUnit = uint256(10)**st.decimals();

        // we want everything relative to first
        config.priceCumulativeLast = currentCumulativePrice(config);
        config.blockTimestampLast = block.timestamp;
        config.latestBlockTimestampLast = config.blockTimestampLast;
        config.latestPriceCumulativeLast = config.priceCumulativeLast;
    }

    function currentCumulativePrice(SwapConfig storage config)
        internal
        view
        returns (uint256)
    {
        (
            uint256 cumulativePrice0,
            uint256 cumulativePrice1,

        ) = UniswapV2OracleLibrary.currentCumulativePrices(config.swap);
        if (config.ethOnFirst) {
            return cumulativePrice1;
        } else {
            return cumulativePrice0;
        }
    }

    // This needs to be called regularly to update the pricing window
    function pokePriceWindow(SwapConfig storage config)
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 priceCumulative = currentCumulativePrice(config);

        uint256 timeElapsed = block.timestamp - config.latestBlockTimestampLast;

        if (timeElapsed >= PERIOD) {
            config.blockTimestampLast = config.latestBlockTimestampLast;
            config.priceCumulativeLast = config.latestPriceCumulativeLast;

            config.latestBlockTimestampLast = block.timestamp;
            config.latestPriceCumulativeLast = priceCumulative;
        }

        return (
            priceCumulative,
            config.priceCumulativeLast,
            config.blockTimestampLast
        );
    }

    // update to the latest window
    function updatePriceWindows(bytes32[] calldata symbolHashes) external {
        for (uint256 i = 0; i < symbolHashes.length; i++) {
            SwapConfig storage config = swaps[symbolHashes[i]];
            pokePriceWindow(config);
        }
    }

    //eth to usd price
    //precision from open is 6
    function ethUsdPrice() external view returns (uint256) {
        return ethPriceOracle.price(ethSymbol); // grab the eth price from the open oracle
    }

    //tok to Usd price
    //Note: for USDC and USDT this is fixed to 1 on openoracle
    // precision here is 8
    function tokUsdPrice(string calldata symbol)
        external
        view
        returns (uint256)
    {
        return ethPriceOracle.price(symbol); // grab the eth price from the open oracle
    }

    //tok to Eth price
    function tokEthPrice(string calldata symbol) external returns (uint256) {
        bytes32 tokenSymbolHash = keccak256(abi.encodePacked(symbol));
        SwapConfig storage config = swaps[tokenSymbolHash];
        (
            uint256 priceCumulative,
            uint256 priceCumulativeLast,
            uint256 blockTimestampLast
        ) = pokePriceWindow(config);

        require(
            priceCumulative > priceCumulativeLast,
            "There has been no cumulative change"
        );
        // This should be impossible, but better safe than sorry
        require(
            block.timestamp > blockTimestampLast,
            "now must come after before"
        );
        uint256 timeElapsed = block.timestamp - blockTimestampLast;

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224(
                (priceCumulative - config.priceCumulativeLast) / timeElapsed
            )
        );
        uint256 rawUniswapPriceMantissa = priceAverage.decode112with18();

        // Divide by 1e28 because it's decoded to 18 and then we want 8 decimal places of precision out so 18+18-8
        return mul(rawUniswapPriceMantissa, config.baseUnit) / 1e28;
    }

    // This actually calculate the latest price from outside oracles
    // It's a view but substantially more costly in terms of calculation
    function price(string calldata symbol) external view returns (uint256) {
        bytes32 tokenSymbolHash = keccak256(abi.encodePacked(symbol));
        uint256 ethPrice = ethPriceOracle.price(ethSymbol); // grab the eth price from the open oracle

        if (ethHash == tokenSymbolHash) {
            return ethPrice;
        } else {
            SwapConfig storage config = swaps[tokenSymbolHash];
            uint256 priceCumulative = currentCumulativePrice(config);

            require(
                priceCumulative > config.priceCumulativeLast,
                "There has been no cumulative change"
            );
            // This should be impossible, but better safe than sorry
            require(
                block.timestamp > config.blockTimestampLast,
                "now must come after before"
            );
            uint256 timeElapsed = block.timestamp - config.blockTimestampLast;

            // overflow is desired, casting never truncates
            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
                uint224(
                    (priceCumulative - config.priceCumulativeLast) / timeElapsed
                )
            );
            uint256 rawUniswapPriceMantissa = priceAverage.decode112with18();

            uint256 unscaledPriceMantissa = mul(
                rawUniswapPriceMantissa,
                ethPrice
            );

            return mul(unscaledPriceMantissa, config.baseUnit) / 1e36;
        }
    }

    function debugPrice(string calldata symbol)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        bytes32 tokenSymbolHash = keccak256(abi.encodePacked(symbol));
        uint256 ethPrice = ethPriceOracle.price(ethSymbol); // grab the eth price from the open oracle

        SwapConfig storage config = swaps[tokenSymbolHash];
        uint256 priceCumulative = currentCumulativePrice(config);

        require(
            priceCumulative > config.priceCumulativeLast,
            "There has been no cumulative change"
        );
        // This should be impossible, but better safe than sorry
        require(
            block.timestamp > config.blockTimestampLast,
            "now must come after before"
        );
        uint256 timeElapsed = block.timestamp - config.blockTimestampLast;
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224(
                (priceCumulative - config.priceCumulativeLast) / timeElapsed
            )
        );
        uint256 rawUniswapPriceMantissa = priceAverage.decode112with18();

        uint256 unscaledPriceMantissa = mul(rawUniswapPriceMantissa, ethPrice);

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed

        return (
            priceCumulative - config.priceCumulativeLast,
            timeElapsed,
            rawUniswapPriceMantissa,
            unscaledPriceMantissa
        );
    }

    function openPrice(string calldata symbol) external view returns (uint256) {
        return ethPriceOracle.price(symbol);
    }

    function getSwapConfig(string calldata symbol)
        external
        view
        returns (SwapConfig memory)
    {
        bytes32 tokenSymbolHash = keccak256(abi.encodePacked(symbol));
        return swaps[tokenSymbolHash];
    }

    /// @dev Overflow proof multiplication
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}

contract SymboledERC20 {
    function symbol() public view returns (string memory);

    function decimals() public view returns (uint8);
}
