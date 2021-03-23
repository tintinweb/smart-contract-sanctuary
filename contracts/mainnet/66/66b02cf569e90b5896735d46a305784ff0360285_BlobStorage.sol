pragma solidity 0.5.10;

import './LibInteger.sol';
import './LibBlob.sol';

/**
 * @title BlobStorage 
 * @dev Store core details about the blobs permanently
 */
contract BlobStorage
{
    using LibInteger for uint;

    /**
     * @dev The admin of the contract
     */
    address payable private _admin;

    /**
     * @dev Permitted addresses to carry out storage functions
     */
    mapping (address => bool) private _permissions;

    /**
     * @dev Names of tokens
     */
    mapping (uint => uint) private _names;

    /**
     * @dev Listing prices of tokens
     */
    mapping (uint => uint) private _listings;

    /**
     * @dev Original minters of tokens
     */
    mapping (uint => address payable) private _minters;

    /**
     * @dev Names currently reserved
     */
    mapping (uint => bool) private _reservations;

    /**
     * @dev The metadata of blobs
     */
    mapping (uint => uint[]) private _metadata;

    /**
     * @dev Initialise the contract
     */
    constructor() public
    {
        //The contract creator becomes the admin
        _admin = msg.sender;
    }

    /**
     * @dev Allow access only for the admin of contract
     */
    modifier onlyAdmin()
    {
        require(msg.sender == _admin);
        _;
    }

    /**
     * @dev Allow access only for the permitted addresses
     */
    modifier onlyPermitted()
    {
        require(_permissions[msg.sender]);
        _;
    }

    /**
     * @dev Give or revoke permission of accounts
     * @param account The address to change permission
     * @param permission True if the permission should be granted, false if it should be revoked
     */
    function permit(address account, bool permission) public onlyAdmin
    {
        _permissions[account] = permission;
    }

    /**
     * @dev Withdraw from the balance of this contract
     * @param amount The amount to be withdrawn, if zero is provided the whole balance will be withdrawn
     */
    function clean(uint amount) public onlyAdmin
    {
        if (amount == 0){
            _admin.transfer(address(this).balance);
        } else {
            _admin.transfer(amount);
        }
    }

    /**
     * @dev Set the name of token
     * @param id The id of token
     * @param value The value to be set
     */
    function setName(uint id, uint value) public onlyPermitted
    {
        _names[id] = value;
    }

    /**
     * @dev Set the listing price of token
     * @param id The id of token
     * @param value The value to be set
     */
    function setListing(uint id, uint value) public onlyPermitted
    {
        _listings[id] = value;
    }

    /**
     * @dev Set the original minter of token
     * @param id The id of token
     * @param value The value to be set
     */
    function setMinter(uint id, address payable value) public onlyPermitted
    {
        _minters[id] = value;
    }

    /**
     * @dev Set whether the name is reserved
     * @param name The name
     * @param value True if the name is reserved, otherwise false
     */
    function setReservation(uint name, bool value) public onlyPermitted
    {
        _reservations[name] = value;
    }

    /**
     * @dev Add a new version of metadata to the token
     * @param id The token id
     * @param value The value to be set
     */
    function incrementMetadata(uint id, uint value) public onlyPermitted
    {
        _metadata[id].push(value);
    }

    /**
     * @dev Remove the latest version of metadata from token
     * @param id The token id
     */
    function decrementMetadata(uint id) public onlyPermitted
    {
        _metadata[id].length = _metadata[id].length.sub(1);
    }

    /**
     * @dev Get name of token
     * @param id The id of token
     * @return string The name
     */
    function getName(uint id) public view returns (uint)
    {
        return _names[id];
    }

    /**
     * @dev Get listing price of token
     * @param id The id of token
     * @return uint The listing price
     */
    function getListing(uint id) public view returns (uint)
    {
        return _listings[id];
    }

    /**
     * @dev Get original minter of token
     * @param id The id of token
     * @return uint The original minter
     */
    function getMinter(uint id) public view returns (address payable)
    {
        return _minters[id];
    }

    /**
     * @dev Check whether the provided name is reserved
     * @param name The name to check
     * @return bool True if the name is reserved, otherwise false
     */
    function isReserved(uint name) public view returns (bool)
    {
        return _reservations[name];
    }

    /**
     * @dev Check whether the provided address is permitted
     * @param account The address to check
     * @return bool True if the address is permitted, otherwise false
     */
    function isPermitted(address account) public view returns (bool)
    {
        return _permissions[account];
    }

    /**
     * @dev Get latest version of metadata of token
     * @param id The id of token
     * @return uint The metadata value
     */
    function getLatestMetadata(uint id) public view returns (uint)
    {
        if (_metadata[id].length > 0) {
            return _metadata[id][_metadata[id].length.sub(1)];
        } else {
            return 0;
        }
    }

    /**
     * @dev Get previous version of metadata of token
     * @param id The id of token
     * @return uint The metadata value
     */
    function getPreviousMetadata(uint id) public view returns (uint)
    {
        if (_metadata[id].length > 1) {
            return _metadata[id][_metadata[id].length.sub(2)];
        } else {
            return 0;
        }
    }
}