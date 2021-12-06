// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library IsContractLib {
    /**
     * @notice An addres is a contract if its {extcodesize} is greater than 0.
     *
     * @return bool
     *         on whether `account` is a contract.
     */
    function isContract(address account) external view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}