/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

contract Storage is Owner {

    mapping (address => bool) public _isAllowed;
    struct FileHash {
        string hash;
        uint256 timestamp;
    }
    mapping (address => FileHash[] ) public _hashFiles;

    function allowAddress(address account, bool value) external isOwner{
        _isAllowed[account] = value;
    }

    modifier isAllowed() {
        require(_isAllowed[msg.sender], "Caller is not allowed to save hashed files");
        _;
    }

    function saveHash(string memory hash) external isAllowed{
        FileHash memory _filehash;
        _filehash.hash = hash;
        _filehash.timestamp = block.timestamp;
        _hashFiles[msg.sender].push(_filehash);
    }
}