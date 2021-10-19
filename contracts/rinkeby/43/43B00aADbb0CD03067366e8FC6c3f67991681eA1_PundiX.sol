// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IPundiX.sol";

/**
 * @dev Implementation of PundiX.
 */
contract PundiX is IPundiX {
    uint256 public sample;
    address public permitted;

    /**
     * @dev Initializes the contract
     */
    constructor(address permitted_) {
        sample = 123456;
        permitted = permitted_;
    }

    /**
     * @dev Gets data.
     */
    function getData() public view virtual override returns (uint256) {
        require(_isContract(msg.sender), "PundiX: the address is not contract");
        require(msg.sender == permitted, "PundiX: the address is not permitted");
        return sample;
    }

    /**
     * @dev Returns true if `account` is a contract.
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an PundiX compliant contract.
 */
interface IPundiX {
    function getData() external view returns (uint256);
}