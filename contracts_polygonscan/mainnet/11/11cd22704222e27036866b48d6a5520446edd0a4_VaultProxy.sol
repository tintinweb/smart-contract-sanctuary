/**
 *Submitted for verification at polygonscan.com on 2021-09-02
*/

// File: vaults-v1/contracts/libs/IStrategy.sol

pragma solidity >=0.6.12;



enum StratType { BASIC, MASTER_HEALER, MAXIMIZER_CORE, MAXIMIZER }



// For interacting with our own strategy

interface IStrategy {

    // Want address

    function wantAddress() external view returns (address);

    

    // Total want tokens managed by strategy

    function wantLockedTotal() external view returns (uint256);



    // Sum of all shares of users to wantLockedTotal

    function sharesTotal() external view returns (uint256);



    // Main want token compounding function

    function earn() external;



    // Transfer want tokens autoFarm -> strategy

    function deposit(address _userAddress, uint256 _wantAmt) external returns (uint256);



    // Transfer want tokens strategy -> vaultChef

    function withdraw(address _userAddress, uint256 _wantAmt) external returns (uint256);

    

    //Maximizer want token (eg crystl)

    function maxiAddress() external returns (address);

    

    function stratType() external returns (StratType);

    

    function initialize(uint _pid, uint _tolerance, address _govAddress, address _masterChef, address _uniRouter, address _wantAddress, address _earnedAddress, address _earnedToWmaticStep) external;



    function initialize(uint _pid, uint _tolerance, address _govAddress, address _masterChef, address _uniRouter, address _wantAddress, address _earnedToWmaticStep) external;

}
// File: vaults-v1/contracts/libs/IVaultHealer.sol



pragma solidity >=0.6.12;

interface IVaultHealer {

    function poolInfo(uint _pid) external view returns (address want, address strat);
    
    function maximizerDeposit(uint _amount) external;
    
    function strategyMaxiCore() external view returns (address);
    function strategyMasterHealer() external view returns (address);
    function strategyMaxiMasterHealer() external view returns (address);
    
}
// File: @openzeppelin/contracts/proxy/Proxy.sol



pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// File: @openzeppelin/contracts/proxy/utils/Initializable.sol



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

// File: vaults-v1/contracts/VaultProxy.sol



pragma solidity ^0.8.4;





contract VaultProxy is Proxy, Initializable {

    IVaultHealer private __vaultHealer;
    StratType private __stratType;
    
    function initialize(StratType _stratType) external initializer() {
        require(_stratType != StratType.BASIC, "YA BASIC");
        __stratType = _stratType;
        __vaultHealer = IVaultHealer(msg.sender);
    }
    
    function _implementation() internal view override returns (address) {
        if (__stratType == StratType.MASTER_HEALER) return __vaultHealer.strategyMasterHealer();
        if (__stratType == StratType.MAXIMIZER_CORE) return __vaultHealer.strategyMaxiCore();
        if (__stratType == StratType.MAXIMIZER) return __vaultHealer.strategyMaxiMasterHealer();
        revert("No implementation");
    }
}