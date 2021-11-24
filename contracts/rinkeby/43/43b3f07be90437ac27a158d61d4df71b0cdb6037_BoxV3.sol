// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// this is the implementation 

contract BoxV3 is Initializable {


    // we want to add these variables to the proxy contract     
    uint public width; // 0x0
    uint public length; //0x1
    uint public heigth; // 0x2 (we are adding a new storage variable to the proxy in slot position 2)



    // we inherit a contract Initializable
    // in the upgradable contract there's no constructor! 

    // initializer modifier, inizialize in this case is similar to a constructor
    function initialize(uint _width, uint _length) external initializer {
        width=_width;
        length=_length;
    }

    function area () external view returns (uint) {
        return length * width;
    }

    function changeWidth(uint _width) external {
        width = _width;
    }

    function getCube () external view returns (uint) {
        return width * length * heigth;
    }

    function changeHeigth(uint _heigth) external {
        heigth = _heigth;
    }

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