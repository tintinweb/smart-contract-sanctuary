// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./NonContract.sol";

contract TesterContract {

    NonContract public nonContract;

    constructor(address addr) {
        nonContract = NonContract(addr);
    }

    function set_status_non_contract(uint new_status) public {
        nonContract.set_status_non_contract(new_status);
    }

    function set_status_anyone(uint new_status) public {
        nonContract.set_status_anyone(new_status);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract NonContract {

    uint public status;

    modifier notContract() {
        uint size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "Only non-contract/eoa can perform this operation");
        _;
    }

    function set_status_non_contract(uint new_status) public notContract {
        status = new_status;
    }

    function set_status_anyone(uint new_status) public {
        status = new_status;
    }
}