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
    mapping(address => mapping(bytes32 => bool)) boolData;
    mapping(address => mapping(bytes32 => uint)) uintData;
    mapping(address => mapping(bytes32 => int)) intData;
    mapping(address => mapping(bytes32 => address)) addressData;
    mapping(address => mapping(bytes32 => string)) stringData;
    mapping(address => mapping(bytes32 => bytes)) bytesData;


    /**
     * @dev emits when a `username` assignes to a `userAddr`.
     */
    event SetUserAddress(string indexed username, address indexed userAddr);

    /**
     * @dev emits when some data records about a user.
     */
    event SetBool(address indexed userAddr, bytes32 tag, bool data);
    event SetUint(address indexed userAddr, bytes32 tag, uint data);
    event SetInt(address indexed userAddr, bytes32 tag, int data);
    event SetAddress(address indexed userAddr, bytes32 tag, address data);
    event SetString(address indexed userAddr, bytes32 tag, string data);
    event SetBytes(address indexed userAddr, bytes32 tag, bytes data);



    /**
     * @dev returns the `userAddr` owner of `username`.
     */
    function userAddress(string memory username) external view returns(address userAddr) {
        return usernameToAddr[username];
    }


    /**
     * @dev returns the `data` of a `tag` recorded for `userAddr`.
     */
    function getBool(address userAddr, bytes32 tag) external view returns(bool data) {
        return boolData[userAddr][tag];
    }
    function getUint(address userAddr, bytes32 tag) external view returns(uint data) {
        return uintData[userAddr][tag];
    }
    function getInt(address userAddr, bytes32 tag) external view returns(int data) {
        return intData[userAddr][tag];
    }
    function getAddress(address userAddr, bytes32 tag) external view returns(address data) {
        return addressData[userAddr][tag];
    }
    function getString(address userAddr, bytes32 tag) external view returns(string memory data) {
        return stringData[userAddr][tag];
    }
    function getBytes(address userAddr, bytes32 tag) external view returns(bytes memory data) {
        return bytesData[userAddr][tag];
    }


    /**
     * @dev assign the `username` to `userAddr`.
     * (only Register roll can call this function).
     */
    function setUserAddress(string memory username, address userAddr) external onlyRoll("Register") {
        usernameToAddr[username] = userAddr;
        emit SetUserAddress(username, userAddr);
    }


    /**
     * @dev record `data` of case `tag` for a `userAddr`.
     * (only Register roll can call this function).
     */
    function setBool(address userAddr, bytes32 tag, bool data) external onlyRoll("Register") {
        boolData[userAddr][tag] = data;
        emit SetBool(userAddr, tag, data);
    }
    function setUint(address userAddr, bytes32 tag, uint data) external onlyRoll("Register") {
        uintData[userAddr][tag] = data;
        emit SetUint(userAddr, tag, data);
    }
    function setInt(address userAddr, bytes32 tag, int data) external onlyRoll("Register") {
        intData[userAddr][tag] = data;
        emit SetInt(userAddr, tag, data);
    }
    function setAddress(address userAddr, bytes32 tag, address data) external onlyRoll("Register") {
        addressData[userAddr][tag] = data;
        emit SetAddress(userAddr, tag, data);
    }
    function setString(address userAddr, bytes32 tag, string memory data) external onlyRoll("Register") {
        stringData[userAddr][tag] = data;
        emit SetString(userAddr, tag, data);
    }
    function setBytes(address userAddr, bytes32 tag, bytes memory data) external onlyRoll("Register") {
        bytesData[userAddr][tag] = data;
        emit SetBytes(userAddr, tag, data);
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
        (bool success, bytes memory _data) = DAOInit.staticcall(
            abi.encodeWithSignature("DAO()")
        );
        if(success) {return abi.decode(_data, (address));}
    }

    /**
     * @dev returns any `data` assigned to a `tag`.
     */
    function DAOGetBool(bytes32 tag) public view returns(bool data) {
        (bool success, bytes memory _data) = DAO().staticcall(
            abi.encodeWithSignature("getBool(bytes32)", tag)
        );
        if(success) {return abi.decode(_data, (bool));}
    }
    function DAOGetUint(bytes32 tag) public view returns(uint data) {
        (bool success, bytes memory _data) = DAO().staticcall(
            abi.encodeWithSignature("getUint256(bytes32)", tag)
        );
        if(success) {return abi.decode(_data, (uint));}
    }
    function DAOGetInt(bytes32 tag) public view returns(int data) {
        (bool success, bytes memory _data) = DAO().staticcall(
            abi.encodeWithSignature("getUint256(bytes32)", tag)
        );
        if(success) {return abi.decode(_data, (int));}
    }
    function DAOGetAddress(bytes32 tag) public view returns(address data) {
        (bool success, bytes memory _data) = DAO().staticcall(
            abi.encodeWithSignature("getAddress(bytes32)", tag)
        );
        if(success) {return abi.decode(_data, (address));}
    }
    function DAOGetString(bytes32 tag) public view returns(string memory data) {
        (bool success, bytes memory _data) = DAO().staticcall(
            abi.encodeWithSignature("getString(bytes32)", tag)
        );
        if(success) {return abi.decode(_data, (string));}
    }
    function DAOGetBytes(bytes32 tag) public view returns(bytes memory data) {
        (bool success, bytes memory _data) = DAO().staticcall(
            abi.encodeWithSignature("getBoolean(bytes32)", tag)
        );
        if(success) {return abi.decode(_data, (bytes));}
    }


    /**
     * @dev Throws if called by any address except DAO contract.
     */
    modifier onlyDAO() {
        require(
            msg.sender == DAO(),
            "DecentralAccess: restricted access to specific roll"
        );
        _;
    }

    /**
     * @dev Throws if called by any address except specific roll.
     */
    modifier onlyRoll(string memory roll) {
        require(
            DAOGetBool(keccak256(abi.encodePacked(roll, msg.sender))) || msg.sender == DAO(), 
            "DecentralAccess: restricted access to specific roll"
        );
        _;
    }
}