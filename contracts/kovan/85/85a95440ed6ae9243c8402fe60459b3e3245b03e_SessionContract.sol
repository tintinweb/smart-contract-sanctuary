/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract SessionContract {

    address public admin;
    address public pendingAdmin;
    
    struct SessionHashInfo {
        string hash;
        uint256 date;
    }
    
    mapping(uint256 => SessionHashInfo) sessionHashes;
    uint256 public sessionCount = 0;
    
    /// @notice Session Hash Posted
    event SessionHashPosted(string hash, uint256 date);

    modifier onlyAdmin {
        if (msg.sender != admin) revert();
        _;
    }
    
    /**
     * @notice Construct new Session Contract
     */
     constructor() public {
        admin = msg.sender;
    }
    
    /**
      * @notice Admin add new session hash into the blockhash by end of the day
      * @param hash A hash for a day
      * @param date Current date for the hash
      */
    function addHash(string memory hash, uint256 date) external onlyAdmin {
       SessionHashInfo memory newSession = SessionHashInfo(hash, date);
       sessionHashes[sessionCount] = newSession;
       sessionCount = sessionCount + 1;
       emit SessionHashPosted(hash, date);
    }
    
    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address payable newPendingAdmin) external onlyAdmin {
        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin);
        require(msg.sender != address(0));

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);
    }
     
}