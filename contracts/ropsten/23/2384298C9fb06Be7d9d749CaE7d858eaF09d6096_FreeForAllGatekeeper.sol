// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import { SignUpGatekeeper } from './SignUpGatekeeper.sol';

contract FreeForAllGatekeeper is SignUpGatekeeper {

    /*
     * Registers the user without any restrictions.
     */
    function register(address, bytes memory) override public { }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract SignUpGatekeeper {
    function register(address _user, bytes memory _data) virtual public {}
}