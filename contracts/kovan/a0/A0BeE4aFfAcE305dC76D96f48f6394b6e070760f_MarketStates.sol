//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../access/BumperAccessControl.sol";

import "../interfaces/IProtocolConfig.sol";
import "../interfaces/IMarketStates.sol";
import "../interfaces/IMarket.sol";


// @title Its a smart contract that gets prices from Chainlink oracle and stores them 
//        and some calculated indexes day by day for future risk and position calculations.
contract MarketStates is IMarketStates, BumperAccessControl {

    /// @notice protocol configuration 
    IProtocolConfig public config;

    /// @notice oracle price feeds for tokens
    mapping(address => address) priceFeed;

    /// @notice store information day by day
    // key - token address
    // value - mapping where key - index of day since the day contract was deployed and value - struct with data 
    mapping(address => mapping(uint => MarketState)) stateHistory;
    uint start;

    function initialize(address _config) external {
        start = block.timestamp;
        config = IProtocolConfig(_config);
    }

    function setPriceFeed(address token, address feed) external {
        priceFeed[token] = feed;
    }

    /// @notice get current price from oracle
    function getCurrentPrice(address token) external view override returns (uint){
        return _getCurrentPrice(token);
    }

    function _getCurrentPrice(address token) internal view returns (uint){
        (, int price, , , ) = AggregatorV3Interface(priceFeed[token]).latestRoundData();        
        return uint(price); // int128(price*(2**64)/(10**18));
    }

    /// @notice get HistoryData structure for current day index
    function getCurrentState(address token) public view override returns (MarketState memory data) {
        data = stateHistory[ token ][ getCurrentIndex() ];
    }

    /// @notice get HistoryData for the given index
    function getStateAt(address token, uint index) public view override returns (MarketState memory data) { 
        return stateHistory[token][index];
    }

    /// @notice get the current index
    function getCurrentIndex() public view returns (uint index){
        return (block.timestamp - start)/1 days;
    }

    /// @notice get the date index from given timestamp
    function getDateIndex(uint timestamp) public view returns (uint index) {
        return (timestamp - start)/1 days;
    }

    function getWeightedAvgPrice(address token) public view returns (int128) {
        uint lastPrice = _getCurrentPrice(token); // test only !!! need to calculate avarage
        return int128 (int256 (lastPrice*(2**64)/(10**18)));
    }

    function getPriceVelAcc(address token) public view returns (int128 vel, int128 acc) { 
        return (1,1); // test only !!! need to calculate vel and acc
    }

    /// @notice generate new market state
    function generateState(address token) public view returns (MarketState memory state){
        // get market state
        (int128 AP, int128 AR, int128 CP, int128 CR, int128 L, int128 B, int128 D) = IMarket(config.getMarket(token)).getState();
        // get weighted avarage price 
        int128 wprice = getWeightedAvgPrice(token);
        (int128 vel, int128 acc) = getPriceVelAcc(token);
        state =  MarketState(
            wprice,
            vel,
            acc,
            AP,
            AR,
            L,
            CP,
            CR,
            B,
            D
        );                
    }

    /// @notice write current data to storage
    function updateState(address[] memory tokens) external override {
        for (uint i = 0; i < tokens.length; i++)
        {
            uint index = getCurrentIndex();
            if (stateHistory[tokens[i]][index].price == 0 )
            {
                MarketState memory state = generateState(tokens[i]);
                stateHistory[tokens[i]][index] = state; 
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

///@title BumperAccessControl contract is used to restrict access of functions to onlyGovernance and onlyOwner.
///@notice This contains suitable modifiers to restrict access of functions to onlyGovernance and onlyOwner.
contract BumperAccessControl is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
{
    ///@dev This stores if a particular address is considered as whitelist or not in form of mapping.
    mapping(address => bool) internal whitelist;

    event AddressAddedToWhitelist(address newWhitelistAddress);
    event AddressRemovedFromWhitelist(address removedWhitelistAddress);

    function _BumperAccessControl_init(address[] memory _whitelist)
        internal
        initializer
    {
        __Context_init_unchained();
        __Ownable_init();
        ///Setting white list addresses as true
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
        }
    }

    modifier onlyGovernance {
        //require(whitelist[_msgSender()], "!whitelist"); //ToDo:
        _;
    }

    modifier onlyGovernanceOrOwner {
        require(
            whitelist[_msgSender()] || owner() == _msgSender(),
            "!ownerOrWhitelist"
        );
        _;
    }

    ///@dev It sets this address as true in whitelist address mapping
    ///@param addr Address that is set as whitelist address
    function addAddressToWhitelist(address addr) external onlyOwner {
        whitelist[addr] = true;
        emit AddressAddedToWhitelist(addr);
    }

    ///@dev It sets passed address as false in whitelist address mapping
    ///@param addr Address that is removed as whitelist address
    function removeAddressFromWhitelist(address addr) external onlyOwner {
        whitelist[addr] = false;
        emit AddressRemovedFromWhitelist(addr);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../configuration/MarketConfig.sol";

interface IProtocolConfig {
    function getVersion() external view returns (uint16);
    function getStable() external view returns (address);
    function getConfig(address token) external view returns (MarketConfig memory config);
    function getBToken(address token) external view returns (address);
    function getMarket(address token) external view returns (address);
    function getETHMarket() external view returns (address);
    function getBump() external view returns (address);
    function getStateHistory() external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../market/State.sol";

interface IMarketStates {
    function getCurrentPrice(address token) external view returns (uint);
    function getCurrentState(address token) external view 
        returns (MarketState memory data);
    function getStateAt(address token, uint index) external view 
        returns (MarketState memory data);   
    function updateState(address[] memory tokens) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMarket {
    function premium(uint amount, uint32 risk, uint32 term) external view returns (uint);
    function protect(address account, uint amount, uint32 risk, uint32 term, bool autorenew) external returns (uint id);
    function protectETH(address account, uint amount, uint32 risk, uint32 term, bool autorenew) external payable returns (uint id);
    function close(address account, uint id) external;
    function claim(address account, uint id) external;
    function deposit(address account, uint amount, uint32 term) external returns (uint id);
    function withdraw(address account, uint id) external;
    function rebalance() external;    
    function govWithdraw(address token, address to, uint amount) external; // only governance
    function getState() external view returns (int128 AP, int128 AR, int128 CP, int128 CR, int128 B, int128 L, int128 D);

// NEED TO DISCUSS WITH SAM
//    function liquidate(uint id) external;
//    function handleTransfer(address from, address to, uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

struct MarketConfig {
    int128[2] U_Lambda;
    int128[2] U_Ref;
    int128[2] U_Max;
    int128    U_Speed;
    int128[6] W_Lambda;
    int128[6] W_Ref;
    int128[6] W_Max;
    int128    W_Speed;
    int128    gamma;
    int128    lambdaGamma;    
    int128    delta;    
    int128    lambdaDelta;
    int128    eps;
    int128    V_Max;
    int128    VRF_Max;
    int128    LRF_Max;
    int128    PRF_Max;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

struct MarketState {    
    int128 price;
    int128 AccelNorm;
    int128 VelNorm;        
    int128 AP;
    int128 AR;
    int128 L;
    int128 CP;
    int128 CR;
    int128 B;
    int128 D; 
}