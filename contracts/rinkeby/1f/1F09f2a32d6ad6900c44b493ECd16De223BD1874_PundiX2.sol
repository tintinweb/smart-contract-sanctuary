// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IPundiX.sol";

/**
 * @dev Implementation of PundiX2.
 */
contract PundiX2 {
    /**
     * @dev Call PundiX.
     */
    function callPundiX(address pundix_) public virtual {
         IPundiX(pundix_).getData();
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