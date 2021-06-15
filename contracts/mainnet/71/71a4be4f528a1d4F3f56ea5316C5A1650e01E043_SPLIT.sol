/*--------------------------------------------------------PRüF0.8.0
__/\\\\\\\\\\\\\ _____/\\\\\\\\\ _______/\\__/\\ ___/\\\\\\\\\\\\\\\        
 _\/\\\/////////\\\ _/\\\///////\\\ ____\//__\//____\/\\\///////////__       
  _\/\\\_______\/\\\_\/\\\_____\/\\\ ________________\/\\\ ____________      
   _\/\\\\\\\\\\\\\/__\/\\\\\\\\\\\/_____/\\\____/\\\_\/\\\\\\\\\\\ ____     
    _\/\\\/////////____\/\\\//////\\\ ___\/\\\___\/\\\_\/\\\///////______    
     _\/\\\ ____________\/\\\ ___\//\\\ __\/\\\___\/\\\_\/\\\ ____________   
      _\/\\\ ____________\/\\\ ____\//\\\ _\/\\\___\/\\\_\/\\\ ____________  
       _\/\\\ ____________\/\\\ _____\//\\\_\//\\\\\\\\\ _\/\\\ ____________ 
        _\/// _____________\/// _______\/// __\///////// __\/// _____________
         *-------------------------------------------------------------------*/

/*-----------------------------------------------------------------
 * PRUF DOUBLER CONTRACT  -- requires MINTER_ROLE, (SNAPSHOT_ROLE), PAUSER_ROLE in UTIL_TKN
 *---------------------------------------------------------------*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PRUF_INTERFACES.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

contract SPLIT is ReentrancyGuard, Pausable, AccessControl {
    //----------------------------ROLE DEFINITIONS
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CONTRACT_ADMIN_ROLE =
        keccak256("CONTRACT_ADMIN_ROLE");

    UTIL_TKN_Interface internal UTIL_TKN;

    mapping(address => uint256) internal hasSplit;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTRACT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        UTIL_TKN = UTIL_TKN_Interface(
            0xa49811140E1d6f653dEc28037Be0924C811C4538
        ); // for hard coded util tkn address
    }

    //---------------------------------MODIFIERS-------------------------------//

    /**
     * @dev Verify user credentials
     * Originating Address:
     *      is Admin
     */
    modifier isContractAdmin() {
        require(
            hasRole(CONTRACT_ADMIN_ROLE, msg.sender),
            "SPLIT:MOD-ICA: must have CONTRACT_ADMIN_ROLE"
        );
        _;
    }

    /**
     * @dev Verify user credentials
     * Originating Address:
     *      is Pauser
     */
    modifier isPauser() {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "SPLIT:MOD-IP: must have PAUSER_ROLE"
        );
        _;
    }

    //----------------------External functions---------------------//

    /**
     * @dev doubles pruf balance at snapshotID(1)
     */
    function splitMyPruf() external whenNotPaused {
        require(
            hasSplit[msg.sender] == 0,
            "SPLIT:SMP: Caller address has already been split"
        );
        //^^^^^^^checks^^^^^^^^^

        uint256 balanceAtSnapshot = UTIL_TKN.balanceOfAt(msg.sender, 1);
        hasSplit[msg.sender] = 170; //mark caller address as having been split
        //^^^^^^^effects^^^^^^^^^

        UTIL_TKN.mint(msg.sender, balanceAtSnapshot); //mint the new tokens to caller address
        //^^^^^^^Interactions^^^^^^^^^
    }

    /**
     * @dev doubles pruf balance at snapshotID(1)
     * @param _address - address to be split
     */
    function splitPrufAtAddress(address _address) external whenNotPaused {
        require(
            hasSplit[_address] == 0,
            "SPLIT:SMPAA: Caller address has already been split"
        );
        //^^^^^^^checks^^^^^^^^^

        uint256 balanceAtSnapshot = UTIL_TKN.balanceOfAt(_address, 1);
        hasSplit[_address] = 170; //mark caller address as having been split
        //^^^^^^^effects^^^^^^^^^

        UTIL_TKN.mint(_address, balanceAtSnapshot); //mint the new tokens to caller address
        //^^^^^^^Interactions^^^^^^^^^
    }

    /**
     * @dev checks address for available split, returns balance of pruf to be split
     * @param _address - address to be checked if eligible for split
     */
    function checkMyAddress(address _address) external view returns (uint256) {
        return hasSplit[_address];
    }

    /**
     * @dev Pauses pausable functions.
     * See {ERC20Pausable} and {Pausable-_pause}.
     * Requirements:
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual isPauser {
        //^^^^^^^checks^^^^^^^^^

        _pause();
        //^^^^^^^effects^^^^^^^^
    }

    /**
     * @dev Unpauses all pausable functions.
     * See {ERC20Pausable} and {Pausable-_unpause}.
     * Requirements:
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual isPauser {
        //^^^^^^^checks^^^^^^^^^

        _unpause();
        //^^^^^^^effects^^^^^^^^
    }
}