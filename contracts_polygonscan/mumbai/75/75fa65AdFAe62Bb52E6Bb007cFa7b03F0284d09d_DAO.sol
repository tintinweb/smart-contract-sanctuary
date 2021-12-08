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
//   =============== Verify Random Function by ChanLink ===============

/**
 * @dev this contract is source of every types of variables used by LOTT.LINK Ecosystem
 * and also executes changes that the LOTT.LINK Governance decides.
 */

contract DAO {

    /**
    * @dev DAOInit eternal address on MATIC MUMBAI testnet.
    */
    address immutable DAOInit = 0x245cAa689Fa16ab50DF4e8ab48555715877F79fF;

    /**
     * @dev Restrict access to the Governance of LOTT.LINK Ecosystem.
     */
    modifier onlyGov() {
        (bool success, bytes memory data) = DAOInit.staticcall(abi.encodeWithSignature("gov()"));
        require(success && msg.sender == abi.decode(data, (address)));
        _;
    }

    /**
    * @dev holding one-to-many assignments.
    */
    mapping (string => mapping(bytes => bool)) whiteLists;

    /**
    * @dev holding one-to-one assignments.
    */
    mapping (string => bytes) vars;

    /**
    * @dev emits when a one-to-one variable assignes or removes.
    */
    event Set(string varName, bytes varData);

    /**
    * @dev emits when a `varData` has been added to or omited from a `varName` whiteList.
    */
    event Set(string varName, bytes varData, bool validity);

    /**
    * @dev returns any `varData` assigned to a `varName`.
    */
    function get(string memory varName) 
        external 
        view 
        returns(bytes memory varData)
    {
        return vars[varName];
    }

    /**
    * @dev returns true if `varData` is in the whiteList of `varName`.
    */
    function check(string memory varName, bytes memory varData)
        external 
        view 
        returns(bool validity)
    {
        return whiteLists[varName][varData];
    }

    /**
    * @dev assign `varData` to a `varName` decided by the governance.
    */
    function set(string memory varName, bytes memory varData)
        external
        onlyGov
    {
        vars[varName] = varData;
        emit Set(varName, varData);
    }

    /**
    * @dev add `varData` to the whiteList of `varName` decided by the governance.
    */
    function set(string memory varName, bytes memory varData, bool validity)
        external
        onlyGov 
    {
        whiteLists[varName][varData] = validity;
        emit Set(varName, varData, validity);
    }

    /**
    * @dev call any smart contract 
    */
    function call(address contractAddr, bytes memory inputData)
        external
        onlyGov
        returns(bytes memory callBackData) 
    {
        (bool success, bytes memory data) = contractAddr.call(inputData);
        if (success) {return data;}
    }
}