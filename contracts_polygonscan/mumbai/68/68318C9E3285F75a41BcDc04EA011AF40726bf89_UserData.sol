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

import "../DAO/DAOCall.sol";

/**
 * @dev this is an eternal contract which holds all users registered data.
 */
contract UserData is DAOCall{

    /**
    * @dev holding all usernames taken.
    */
    mapping(string => address) usernameToAddr;

    /**
    * @dev holding all the data recorded for every user.
    */
    mapping(address => mapping(string => bytes)) addrToData;


    /**
    * @dev emits when a `username` assignes to a `userAddr`.
    */
    event SetAddress(string indexed username, address indexed userAddr);

    /**
    * @dev emits when some data records about a user.
    */
    event SetData(address indexed userAddr, string varName, bytes varData);


    /**
    * @dev returns the `userAddr` owner of `username`.
    */
    function getAddress(string memory username)
        external
        view 
        returns(address userAddr) 
    {
        return usernameToAddr[username];
    }

    /**
    * @dev returns the `varData` of a `varName` recorded for `userAddr`.
    */
    function getData(address userAddr, string memory varName)
        external
        view
        returns(bytes memory varData)
    {
        return addrToData[userAddr][varName];
    }

    /**
    * @dev assign the `username` to `userAddr`.
    * (only Register roll can call this function).
    */
    function setAddress(address userAddr, string memory username) 
        external
        onlyRoll("Register")
    {
        usernameToAddr[username] = userAddr;
    }

    /**
    * @dev record `varData` of case `varName` for a `userAddr`.
    * (only Register roll can call this function).
    */
    function setData(address userAddr, string memory varName, bytes memory varData)
        external
        onlyRoll("Register")
    {
        addrToData[userAddr][varName] = varData;
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

/**
 * @dev this is an abstract contract which provides functions to call DAO contract.
 */

abstract contract DAOCall {

    /**
    * @dev DAOInit eternal address on MATIC MUMBAI testnet.
    */
    address immutable DAOInit = 0x245cAa689Fa16ab50DF4e8ab48555715877F79fF;

    /**
     * @dev returns the current DAO contract address.
     */
    function DAO() public view returns(address DAOAddr){
        (bool success, bytes memory data) = DAOInit.staticcall(
            abi.encodeWithSignature("DAO()")
        );
        if(success) {return abi.decode(data, (address));}
    }

    /**
    * @dev returns any `varData` assigned to a `varName` in DAO contract.
    */
    function DAOGet(string memory varName) public view returns(bytes memory varData) {
        (bool success, bytes memory data) = DAO().staticcall(
            abi.encodeWithSignature("get(string)", varName)
        );
        if(success) {return data;}
    }

    /**
    * @dev returns true if `varData` is in the whiteList of `varName` in DAO contract.
    */
    function DAOCheck(string memory varName, bytes memory varData) public view returns(bool validity) {
        (bool success, bytes memory data) = DAO().staticcall(
            abi.encodeWithSignature("check(string, bytes)", varName, varData)
        );
        if(success) {return abi.decode(data, (bool));}
    }

    /**
     * @dev Throws if called by any other address except DAO contract.
     */
    modifier onlyDAO(string memory roll) {
        require(
            msg.sender == DAO(),
            "DecentralAccess: restricted access to specific roll"
        );
        _;
    }

    /**
     * @dev Throws if called by any other address except specific roll.
     */
    modifier onlyRoll(string memory roll) {
        require(
            msg.sender == DAO() || DAOCheck(roll, abi.encode(msg.sender)), 
            "DecentralAccess: restricted access to specific roll"
        );
        _;
    }
}