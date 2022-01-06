// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Initializable} from "./initializer/utils/Initializable.sol";

contract Tmp is Initializable {
    uint256 ok;
    uint256 uk;

    function init(uint256 _value) external initializer {
        test1(_value);
    }

    function test1(uint256 _value) public onlyInitializing {
        ok = _value;
    }

    function test2(uint256 _value) external {
        uk = _value;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            _initializing ? _isConstructor() : !_initialized,
            "Initializable: contract is already initialized"
        );

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() internal view returns (bool) {
        return !isContract(address(this));
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }
}