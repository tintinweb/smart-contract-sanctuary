// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../access/BumperAccessControl.sol";
import "../interfaces/IProtocolConfig.sol";

import "../market/State.sol";
import "./MarketConfig.sol";

/// @title Protocol configuration contract
/// @notice Store configuration data.
contract ProtocolConfig is IProtocolConfig, BumperAccessControl {

    uint16 version; // protocol version

    address public calc;    // risk calculation contract
    address public state;   // state history contract
    address public swap;    // swap tokens contract
    address public bump;    // BUMP token
    address public stable;  // Stable coin token
    address public factory; // market factory   

    mapping(address => MarketConfig)  marketConfigs; // protocol settings for every token
    mapping(address => address) bTokens; // bToken addresses mapping
    mapping(address => address) markets; // IMarket implementation for each market

    /// @notice Get market implementaion contract address (IMarket)
    function getVersion() external view override returns (uint16){
        return version;
    }

    /// @notice Set market implementaion contract address (IMarket)
    function setVersion(uint16 _version) external onlyGovernance {
         version = _version;
    }  

    /// @notice Set market bToken for token
    function setFactory(address _factory) external onlyGovernance {
        factory = _factory;
    }

    /// @notice Set market bToken for token
    function setStable(address _stable) external onlyGovernance {
        stable = _stable;
    }

    function getStable() public view override returns (address){
        return stable;
    }

    /// @notice Get market implementaion contract address (IMarket)
    function getConfig(address token) external view override returns (MarketConfig memory config){
        config = marketConfigs[token];
    }

    /// @notice Set market implementaion contract address (IMarket)
    function setConfig(address token, MarketConfig memory config) external onlyGovernance {
        marketConfigs[token] = config; 
    }

    /// @notice Set market bToken for token
    function setBToken(address token, address _bToken) external onlyGovernance {
        bTokens[token] = _bToken;
    }

    function getBToken(address token) public view override returns (address){
        return bTokens[token];
    }

    /// @notice Set market bToken for token
    function setMarket(address token, address _market) external onlyGovernance {
        markets[token] = _market;
    }

    /// @notice Get ERC20 market
    function getMarket(address token) public view override returns (address){
        return markets[token];
    }

    /// @notice get ETH market
    function getETHMarket() public view override returns (address){
        return markets[address(0)];
    }

    /// @notice Get IMarketStates implementation contract address 
    function getStateHistory() external view override returns (address) {
        return state;
    }

    /// @notice Set IMarketStates implementaion contract address 
    function setStateHistory(address _stateHistory) external onlyGovernance {
        state = _stateHistory;
    }

    /// @notice Get risk calculation contract address 
    function getRiskCalc() external view returns (address) {
        return calc;
    }

    /// @notice Set risk calculation contract address 
    function setRiskCalc(address _calc) external onlyGovernance {
        calc = _calc;
    }

    /// @notice Get swap contract address 
    function getSwapper() external view returns (address) {
        return calc;
    }

    /// @notice Set swap contract address 
    function setSwapper(address _calc) external onlyGovernance {
        calc = _calc;
    }

    /// @notice Get BUMP token address 
    function getBump() external view override returns (address) {
        return bump;
    }    

    /// @notice Set BUMP token address 
    function setBump(address _bump) external onlyGovernance {
        bump = _bump;
    }

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