/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Blockup
 * @dev Add/Remove enabled accounts and store blocks using events
 */
contract Blockup {

    address public owner;
    
    mapping(address => uint) public accounts;
    
    event BlockUp (bytes12 indexed blockId, bytes12 parentId, uint version, bytes32 hash);
    
    constructor() 
    {
        owner = msg.sender;
    }
    
    /**
     * @dev Add new enabled account
     * @param account address
     */
    function addAccount(address account) public {
        require(
            msg.sender == owner,
            "Only contract owner can add new accounts."
        );
        require(
            account != 0x0000000000000000000000000000000000000000,
            "Invalid account provided."
        );
        require(
            !accountExists(account),
            "Account already added."
        );
        
        accounts[account] = 1;
    }
    
     /**
     * @dev Remove enabled account
     * @param account address
     */
    function removeAccount(address account) public {
        require(
            msg.sender == owner,
            "Only contract owner can remove accounts."
        );
        require(
            accountExists(account),
            "Account not found."
        );
        
        delete accounts[account];
    }
    
    /**
     * @dev Check if enabled account exists
     * @param account address
     */
    function accountExists(address account) public view returns (bool) {
        return accounts[account] == 1;
    }
    
    /**
     * @dev Check account and emit event
     * @param block_id id of the new block
     * @param parent_id id of parent block
     * @param version version number
     * @param hash block version data hash
     */
    function addBlock(
        bytes12 block_id,
        bytes12 parent_id,
        uint version,
        bytes32 hash
        ) public {
            emit BlockUp(block_id, parent_id, version, hash);
        }
}