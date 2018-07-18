pragma solidity ^0.4.23;

/*******************************************************************************
 *
 * Copyright (c) 2018 Decentralization Authority MDAO.
 * Released under the MIT License.
 *
 * ZeroDb - An eternal database, providing a sustainable storage solution
 *          for use throughout the upgrade lifecycle of managing contracts.
 *
 * Version 18.7.17
 *
 * Web    : https://d14na.org
 * Email  : support@d14na.org
 * Github : https://github.com/d14na/zerodb.git/
 */


/*******************************************************************************
 * Owned contract
 */
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);

        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);
    }
}


/*******************************************************************************
 * Zer0net Db Contract
 */
contract Zer0netDb is Owned {
    /* Initialize all storage types. */
    mapping(bytes32 => address)    private addressStorage;
    mapping(bytes32 => bool)       private boolStorage;
    mapping(bytes32 => bytes)      private bytesStorage;
    mapping(bytes32 => int256)     private intStorage;
    mapping(bytes32 => string)     private stringStorage;
    mapping(bytes32 => uint256)    private uIntStorage;

    /**
     * @dev Only allow access from the latest version of an 0racle contract
     *      within the Zer0net after deployment.
     */
    modifier onlyAuthBy0racle() {
        /***********************************************************************
         * The owner is only allowed to set the authorized contracts upon
         * deployment, to register the initial contracts, afterwards their
         * direct access is permanently disabled.
         */
        if (msg.sender == owner) {
            /* Verify owner&#39;s write access has not already been disabled. */
            require(boolStorage[keccak256(&#39;owner.auth.disabled&#39;)] != true);
        } else {
            /* Verify write access is only permitted to authorized accounts. */
            require(boolStorage[keccak256(msg.sender, &#39;.has.auth&#39;)] == true);
        }

        _;      // function code is inserted here
    }

    /***************************************************************************
     * Initialize all getter methods.
     */

    /// @param _key The key for the record
    function getAddress(bytes32 _key) external view returns (address) {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) external view returns (bool) {
        return boolStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes(bytes32 _key) external view returns (bytes) {
        return bytesStorage[_key];
    }

    /// @param _key The key for the record
    function getInt(bytes32 _key) external view returns (int) {
        return intStorage[_key];
    }

    /// @param _key The key for the record
    function getString(bytes32 _key) external view returns (string) {
        return stringStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) external view returns (uint) {
        return uIntStorage[_key];
    }


    /***************************************************************************
     * Initialize all setter methods.
     */

    /// @param _key The key for the record
    function setAddress(bytes32 _key, address _value) onlyAuthBy0racle external {
        addressStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBool(bytes32 _key, bool _value) onlyAuthBy0racle external {
        boolStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes(bytes32 _key, bytes _value) onlyAuthBy0racle external {
        bytesStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setInt(bytes32 _key, int _value) onlyAuthBy0racle external {
        intStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setString(bytes32 _key, string _value) onlyAuthBy0racle external {
        stringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setUint(bytes32 _key, uint _value) onlyAuthBy0racle external {
        uIntStorage[_key] = _value;
    }


    /***************************************************************************
     * Initialize all delete methods.
     */

    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) onlyAuthBy0racle external {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBool(bytes32 _key) onlyAuthBy0racle external {
        delete boolStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key) onlyAuthBy0racle external {
        delete bytesStorage[_key];
    }

    /// @param _key The key for the record
    function deleteInt(bytes32 _key) onlyAuthBy0racle external {
        delete intStorage[_key];
    }

    /// @param _key The key for the record
    function deleteString(bytes32 _key) onlyAuthBy0racle external {
        delete stringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteUint(bytes32 _key) onlyAuthBy0racle external {
        delete uIntStorage[_key];
    }
}