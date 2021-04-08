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
    
    event BlockUp (bytes24 indexed blockId, uint256 version, bytes32 hash);
    
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
     * @param version version number
     * @param hash block version data hash
     */
    function addBlock(
        bytes24 block_id,
        uint256 version,
        bytes32 hash
        ) public {
            require(
                accountExists(msg.sender),
                "Sender account not found."
            );
            emit BlockUp(block_id, version, hash);
        }
}