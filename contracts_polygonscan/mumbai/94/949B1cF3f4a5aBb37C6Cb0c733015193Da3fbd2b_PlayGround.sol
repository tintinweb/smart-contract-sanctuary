/**
 *Submitted for verification at polygonscan.com on 2021-08-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

contract PlayGround is Initializable {
    mapping(uint8 => address) public map;

    uint8 public a;
    uint128 public b;
    address public c;

    function initialize(uint8 _a) public initializer {
        a = _a;
    }

    function setA(uint8 _a) public {
        a = _a;
        b++;
    }

    function setC(address _c) public {
        c = _c;
    }
}