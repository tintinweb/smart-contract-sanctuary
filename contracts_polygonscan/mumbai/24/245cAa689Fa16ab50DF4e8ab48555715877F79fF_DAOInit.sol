// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ============================ TEST_1.0.6 ==============================
//   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
//   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
//   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
//   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
//   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
// ======================================================================
//  ================ Open source smart contract on EVM =================
//   ============== Verify Random Function by ChainLink ===============

/**
 * @dev this is an eternal contract which holds DAO contract address.
 */

import "./DecentralAccess.sol";

contract DAOInit is DecentralAccess{

    address private _DAO;

    event DAOChanged(address indexed previousDAO, address indexed newDAO);

    /**
     * @dev returns the current DAO contract address.
     */
    function DAO() external view returns(address DAOAddr) {
        return _DAO;
    }

    /**
     * @dev Transfers ownership of the contract to a `_newDAO`.
     * Can only be called by the Gov.
     * 
     */
    function changeDAO(address newDAO) public onlyGov {
        address previousDAO = _DAO; 
        _DAO = newDAO;
        emit DAOChanged(previousDAO, newDAO);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ============================ TEST_1.0.6 ==============================
//   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
//   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
//   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
//   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
//   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
// ======================================================================
//  ================ Open source smart contract on EVM =================
//   ============== Verify Random Function by ChainLink ===============


abstract contract DecentralAccess {

    address private _gov;

    event GovChanged(address indexed previousGov, address indexed newGov);

    /**
     * @dev Initializes the contract setting the deployer as the initial Gov.
     */
    constructor() {
        _gov = msg.sender;
    }

    /**
     * @dev Restrict access to the Gov.
     */
    modifier onlyGov {
        require(msg.sender == _gov);
        _;
    }

    /**
     * @dev Returns the address of the current Gov.
     */
    function gov() external view virtual returns (address) {
        return _gov;
    }

    /**
     * @dev Change the Governance ecosystem in epecial cases.
     */
    function changeGov(address newGov) public onlyGov {
        address previousGov = _gov;
        _gov = newGov;
        emit GovChanged(previousGov, newGov);
    }
}