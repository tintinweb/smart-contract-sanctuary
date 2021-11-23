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
        require(size > 0, "Only non-contract/eoa can perform this operation");
        _;
    }

    function set_status(uint new_status) public notContract {
        status = new_status;
    }

    function get_status() public view notContract returns (uint) {
        return status;
    }
}