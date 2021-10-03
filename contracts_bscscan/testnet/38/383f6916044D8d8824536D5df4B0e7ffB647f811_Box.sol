/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

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


contract Box is Initializable {
    uint256 private _value;

    // Emitted when the stored value changes
    event ValueChanged(uint256 value);

    // Stores a new value in the contract
    function initialize() public initializer {
		// __Context_init_unchained();
		// __Ownable_init_unchained();

        _value = 11;
        emit ValueChanged(_value);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return _value;
    }

     // Reads the last stored value
    function Setretrieve(uint value) public  returns (uint256) {
        _value = value;
        return _value;
    }
}




// pragma solidity 0.8.4;
 

// import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
// import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
// import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
// import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// contract Box is Initializable, ERC20Upgradeable, OwnableUpgradeable {
//     uint256 private value;
 
//     // Emitted when the stored value changes
//     event ValueChanged(uint256 newValue);
 
//     // Stores a new value in the contract
//     function store(uint256 newValue) public {
//         value = newValue;
//         emit ValueChanged(newValue);
//     }

//     function initialize(uint256 _x) initializer public {
//         __Context_init_unchained();
//         __Ownable_init_unchained();
//         // __ERC165_init_unchained();
//         // __ERC721_init("MyCollectible", "MCO");
//         __ERC20_init_unchained("MyCollectible", "MCO");
//         value = _x;
//     }
 
//     // Reads the last stored value
//     function retrieve() public view returns (uint256) {
//         return value;
//     }
// }