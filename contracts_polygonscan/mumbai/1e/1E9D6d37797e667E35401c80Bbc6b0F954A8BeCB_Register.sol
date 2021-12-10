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
import "../utils/StringUtil.sol";


contract Register is DAOCall{

    using StringUtil for string;

    /**
     * @dev returns the eternal contract which holds all users registered data.
     */
    function userData() public view returns(UserData){
        return UserData(abi.decode(DAOGet("UserData"), (address)));
    }

    /**
     * @dev returns true if the user has been registered. (by user `address`)
     */
    function registered(address userAddr) public view returns(bool) {
        return userData().getData(userAddr, "username").length != 0;
    }

    /**
     * @dev returns true if the user has been registered. (by `username`)
     */
    function registered(string memory username) public view returns(bool) {
        return userData().getAddress(username.lower()) != address(0);
    }

    /**
     * @dev Returns the address `userAddr` of the `username`.
     *
     * Requirements:
     *
     * - `username` should be registered.
     */
    function usernameToAddress(string memory username) public view returns(address userAddr) {
        userAddr = userData().getAddress(username.lower());
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
        bytes memory usernameBytes = userData().getData(userAddr, "username");
        require(usernameBytes.length > 0, "no user by this address");
        return(abi.decode(usernameBytes, (string)));
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
        bytes memory usernameBytes = UD.getData(userAddr, "username");
        require(usernameBytes.length > 0, "no user by this address");
        return(
            abi.decode(usernameBytes, (string)),
            abi.decode(UD.getData(userAddr, "userInfo"), (string))
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
        userAddr = UD.getAddress(username.lower());
        require(userAddr != address(0), "no user by this username");
        return(
            userAddr,
            abi.decode(UD.getData(userAddr, "userInfo"), (string))
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
    function signIn(string memory username, string memory info, string memory presenter) external payable {
        UserData UD = userData();
        address userAddr = msg.sender;
        require(bytes(username).length > 0, "empty username input");
        require(UD.getAddress(username.lower()) == address(0), "username taken");

        bool pureSign;
        if(bytes(username)[0] != bytes1("_")) {
            pureSign = true;
            require(msg.value >= abi.decode(DAOGet("PureRegisterFee"), (uint256)), "this username is Payable");
        } else {
            require(msg.value >= abi.decode(DAOGet("normalRegisterFee"), (uint256)), "this username is Payable");
        }

        // _setUsername(userAddr, username);
        require(UD.getData(userAddr, "username").length == 0, "registered before.");
        UD.setAddress(username.lower(), userAddr);
        UD.setData(userAddr, "username", abi.encode(username));

        if(bytes(info).length > 0) {
            UD.setData(userAddr, "username", abi.encode(info));
        }

        address presenterAddr = UD.getAddress(presenter.lower());
        (bool success, bytes memory data) = abi.decode(DAOGet("RegisterDAO"), (address)).call{value : msg.value}
            (abi.encodeWithSignature("registerSign(address, address, bool)", userAddr, presenterAddr, pureSign));

        if(success){
            UD.setData(userAddr, "RegisterDAOData", data);
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
    function setInfo(string memory info) public {
        UserData UD = userData();
        address userAddr = msg.sender;
        require(UD.getData(userAddr, "username").length != 0 , "you have to sign in first");
        UD.setData(userAddr, "userInfo", abi.encode(info));
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
    function setAddress(string memory username, address userAddr) 
        external
        onlyRoll("Register")
    {
        usernameToAddr[username] = userAddr;
        emit SetAddress(username, userAddr);
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
        emit SetData(userAddr, varName, varData);
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