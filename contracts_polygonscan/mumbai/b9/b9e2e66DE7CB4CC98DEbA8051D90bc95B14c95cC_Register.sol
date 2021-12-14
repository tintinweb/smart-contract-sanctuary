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

import "./UserData.sol";
import "../DAO/DAOCall.sol";
import "../utils/StringUtil.sol";


contract Register is DAOCall{

    using StringUtil for string;

    /**
     * @dev returns the eternal contract which holds all users registered data.
     */
    function userData() public view returns(UserData){
        return UserData(DAOGetAddress(keccak256("UserData")));
    }

    /**
     * @dev returns true if the user has been registered. (by `username`)
     */
    function registered(string memory username) public view returns(bool) {
        return userData().userAddress(username.lower()) != address(0);
    }

    /**
     * @dev returns true if the user has been registered. (by user `address`)
     */
    function registered(address userAddr) public view returns(bool) {
        return bytes(userData().getString(userAddr, keccak256("username"))).length > 0;
    }

    /**
     * @dev Returns the address `userAddr` of the `username`.
     *
     * Requirements:
     *
     * - `username` should be registered.
     */
    function usernameToAddress(string memory username) public view returns(address userAddr) {
        userAddr = userData().userAddress(username.lower());
        require(userAddr != address(0), "no user by this username");
        return userAddr;
    }

    /**
     * @dev Returns the `username` of the address `userAddr`.
     *
     * Requirements:
     *
     * - address `userAddr` should be registered.
     */
    function addressToUsername(address userAddr) external view returns(string memory username) {
        string memory _username = userData().getString(userAddr, keccak256("username"));
        require(bytes(_username).length > 0, "no user by this address");
        return _username;
    }

    /**
     * @dev Returns the `username` and `info` of the `userAddr`.
     *
     * Requirements:
     *
     * - address `userAddr` should be registered.
     */
    function addressToProfile(address userAddr) external view returns(
        string memory username,
        string memory userInfo
    ){
        UserData UD = userData();
        string memory _username = UD.getString(userAddr, keccak256("username"));
        require(bytes(_username).length > 0, "no user by this address");
        return(
            _username,
            UD.getString(userAddr, keccak256("userInfo"))
        );
    }

    /**
     * @dev Returns address `userAddr` and `info` of the `username`.
     *
     * Requirements:
     *
     * - `username` should be registered.
     */
    function usernameToProfile(string memory username) external view returns(
        address userAddr,
        string memory userInfo
    ){
        UserData UD = userData();
        userAddr = UD.userAddress(username.lower());
        require(userAddr != address(0), "no user by this username");
        return(
            userAddr,
            UD.getString(userAddr, keccak256("userInfo"))
        );
    }

    /**
     * @dev Sign in the Register contract by adopting a `username` and optional info.
     *
     * pure sign fee is more than usual sign.
     * Users can sign in usual by using `_` in the first character of `username`.
     * new user can introduce a string username as `presenter`.
     * 
     * Requirements:
     *
     * - Every address can only sign one username.
     * - Not allowed empty usernames.
     * - User has to adopt a username not taken before.
     */
    function signIn(string memory username, string memory userInfo, string memory presenter) external payable {
        UserData UD = userData();
        address userAddr = msg.sender;
        require(bytes(username).length > 0, "empty username input");
        require(UD.userAddress(username.lower()) == address(0), "username taken");

        bool pureSign;
        if(bytes(username)[0] != bytes1("_")) {
            pureSign = true;
            require(msg.value >= DAOGetUint(keccak256("pureRegisterFee")), "insufficient fee");
        } else {
            require(msg.value >= DAOGetUint(keccak256("normalRegisterFee")), "insufficient fee");
        }

        require(bytes(UD.getString(userAddr, keccak256("username"))).length == 0, "registered before.");
        UD.setUserAddress(username.lower(), userAddr);
        UD.setString(userAddr, keccak256("username"), username);

        if(bytes(userInfo).length > 0) {
            UD.setString(userAddr, keccak256("userInfo"), userInfo);
        }

        address presenterAddr = UD.userAddress(presenter.lower());
        (bool success, bytes memory data) = DAOGetAddress(keccak256("RegisterDAO")).call{value : msg.value}
            (abi.encodeWithSignature("registerSign(address, address, bool)", userAddr, presenterAddr, pureSign));

        if(success){
            UD.setBytes(userAddr, "RegisterDAOData", data);
        }
    }

    /**
     * @dev in addition to the username, every user can set personal info.
     *
     * To remove previously info, it can be called by empty string input.
     *
     * Requirements:
     *
     * - The user has to register first.
     */
    function setInfo(string memory userInfo) public {
        UserData UD = userData();
        address userAddr = msg.sender;
        require(bytes(UD.getString(userAddr, keccak256("username"))).length > 0 , "you have to sign in first");
        UD.setString(userAddr, keccak256("userInfo"), userInfo);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ============================ TEST_1.0.4 ==============================
//   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
//   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
//   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
//   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
//   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
// ======================================================================
//  ================ Open source smart contract on EVM =================
//   =============== Verify Random Function by ChanLink ===============

library StringUtil {

    /**
     * Lower
     * 
     * Converts all the values of a string to their corresponding lower case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string 
     */
    function lower(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     * 
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}