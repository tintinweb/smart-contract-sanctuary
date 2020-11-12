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

// File: contracts/interfaces/IMinMaxOracle.sol

pragma solidity 0.5.11;

interface IMinMaxOracle {
    //Assuming 8 decimals
    function priceMin(string calldata symbol) external returns (uint256);

    function priceMax(string calldata symbol) external returns (uint256);
}

interface IViewMinMaxOracle {
    function priceMin(string calldata symbol) external view returns (uint256);

    function priceMax(string calldata symbol) external view returns (uint256);
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

// File: contracts/oracle/MixOracle.sol

pragma solidity 0.5.11;

/**
 * @title OUSD MixOracle Contract
 * @notice The MixOracle pulls exchange rate from multiple oracles and returns
 *         min and max values.
 * @author Origin Protocol Inc
 */




contract MixOracle is IMinMaxOracle, InitializableGovernable {
    address[] public ethUsdOracles;

    struct MixConfig {
        address[] usdOracles;
        address[] ethOracles;
    }

    mapping(bytes32 => MixConfig) configs;

    uint256 constant MAX_INT = 2**256 - 1;
    uint256 public maxDrift;
    uint256 public minDrift;

    constructor(uint256 _maxDrift, uint256 _minDrift) public {
        maxDrift = _maxDrift;
        minDrift = _minDrift;
    }

    function setMinMaxDrift(uint256 _maxDrift, uint256 _minDrift)
        public
        onlyGovernor
    {
        maxDrift = _maxDrift;
        minDrift = _minDrift;
    }

    /**
     * @notice Adds an oracle to the list of oracles to pull data from.
     * @param oracle Address of an oracle that implements the IEthUsdOracle interface.
     **/
    function registerEthUsdOracle(address oracle) public onlyGovernor {
        for (uint256 i = 0; i < ethUsdOracles.length; i++) {
            require(ethUsdOracles[i] != oracle, "Oracle already registered.");
        }
        ethUsdOracles.push(oracle);
    }

    /**
     * @notice Removes an oracle to the list of oracles to pull data from.
     * @param oracle Address of an oracle that implements the IEthUsdOracle interface.
     **/
    function unregisterEthUsdOracle(address oracle) public onlyGovernor {
        for (uint256 i = 0; i < ethUsdOracles.length; i++) {
            if (ethUsdOracles[i] == oracle) {
                // swap with the last element of the array, and then delete last element (could be itself)
                ethUsdOracles[i] = ethUsdOracles[ethUsdOracles.length - 1];
                delete ethUsdOracles[ethUsdOracles.length - 1];
                ethUsdOracles.length--;
                return;
            }
        }
        revert("Oracle not found");
    }

    /**
     * @notice Adds an oracle to the list of oracles to pull data from.
     * @param ethOracles Addresses of oracles that implements the IEthUsdOracle interface and answers for this asset
     * @param usdOracles Addresses of oracles that implements the IPriceOracle interface and answers for this asset
     **/
    function registerTokenOracles(
        string calldata symbol,
        address[] calldata ethOracles,
        address[] calldata usdOracles
    ) external onlyGovernor {
        MixConfig storage config = configs[keccak256(abi.encodePacked(symbol))];
        config.ethOracles = ethOracles;
        config.usdOracles = usdOracles;
    }

    /**
     * @notice Returns the min price of an asset in USD.
     * @return symbol Asset symbol. Example: "DAI"
     * @return price Min price from all the oracles, in USD with 8 decimal digits.
     **/
    function priceMin(string calldata symbol) external returns (uint256 price) {
        MixConfig storage config = configs[keccak256(abi.encodePacked(symbol))];
        uint256 ep;
        uint256 p; //holder variables
        price = MAX_INT;
        if (config.ethOracles.length > 0) {
            ep = MAX_INT;
            for (uint256 i = 0; i < config.ethOracles.length; i++) {
                p = IEthUsdOracle(config.ethOracles[i]).tokEthPrice(symbol);
                if (ep > p) {
                    ep = p;
                }
            }
            price = ep;
            ep = MAX_INT;
            for (uint256 i = 0; i < ethUsdOracles.length; i++) {
                p = IEthUsdOracle(ethUsdOracles[i]).ethUsdPrice();
                if (ep > p) {
                    ep = p;
                }
            }
            if (price != MAX_INT && ep != MAX_INT) {
                // tokEthPrice has precision of 8 which ethUsdPrice has precision of 6
                // we want precision of 8
                price = (price * ep) / 1e6;
            }
        }

        if (config.usdOracles.length > 0) {
            for (uint256 i = 0; i < config.usdOracles.length; i++) {
                // upscale by 2 since price oracles are precision 6
                p = IPriceOracle(config.usdOracles[i]).price(symbol) * 1e2;
                if (price > p) {
                    price = p;
                }
            }
        }
        require(price < maxDrift, "Price exceeds max value.");
        require(price > minDrift, "Price lower than min value.");
        require(
            price != MAX_INT,
            "None of our oracles returned a valid min price!"
        );
    }

    /**
     * @notice Returns max price of an asset in USD.
     * @return symbol Asset symbol. Example: "DAI"
     * @return price Max price from all the oracles, in USD with 8 decimal digits.
     **/
    function priceMax(string calldata symbol) external returns (uint256 price) {
        MixConfig storage config = configs[keccak256(abi.encodePacked(symbol))];
        uint256 ep;
        uint256 p; //holder variables
        price = 0;
        if (config.ethOracles.length > 0) {
            ep = 0;
            for (uint256 i = 0; i < config.ethOracles.length; i++) {
                p = IEthUsdOracle(config.ethOracles[i]).tokEthPrice(symbol);
                if (ep < p) {
                    ep = p;
                }
            }
            price = ep;
            ep = 0;
            for (uint256 i = 0; i < ethUsdOracles.length; i++) {
                p = IEthUsdOracle(ethUsdOracles[i]).ethUsdPrice();
                if (ep < p) {
                    ep = p;
                }
            }
            if (price != 0 && ep != 0) {
                // tokEthPrice has precision of 8 which ethUsdPrice has precision of 6
                // we want precision of 8
                price = (price * ep) / 1e6;
            }
        }

        if (config.usdOracles.length > 0) {
            for (uint256 i = 0; i < config.usdOracles.length; i++) {
                // upscale by 2 since price oracles are precision 6
                p = IPriceOracle(config.usdOracles[i]).price(symbol) * 1e2;
                if (price < p) {
                    price = p;
                }
            }
        }

        require(price < maxDrift, "Price above max value.");
        require(price > minDrift, "Price below min value.");
        require(price != 0, "None of our oracles returned a valid max price!");
    }
}
