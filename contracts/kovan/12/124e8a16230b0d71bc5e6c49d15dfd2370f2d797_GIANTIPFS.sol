/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * GIANT IPFS Hash Contract
 */ 
contract GIANTIPFS {

    address public admin;
    address public pendingAdmin;
    
    struct IPFSHashInfo {
        string hash;
        uint256 date;
    }
    
    mapping(uint256 => IPFSHashInfo) ipfsHashes;
    uint256 public ipfsCount = 0;
    
    /// @notice IPFS Hash Posted
    event IPFSHashPosted(string hash, uint256 date);

    modifier onlyAdmin {
        if (msg.sender != admin) revert();
        _;
    }
    
    /**
     * @notice Construct new IPFS Contract
     */
     constructor() public {
        admin = msg.sender;
    }
    
    /**
      * @notice Admin add new ipfs hash into the blockhash by end of the day
      * @param hash A hash for a day
      * @param date Current date for the hash
      */
    function addHash(string memory hash, uint256 date) external onlyAdmin {
       IPFSHashInfo memory newIPFS = IPFSHashInfo(hash, date);
       ipfsHashes[ipfsCount] = newIPFS;
       ipfsCount = ipfsCount + 1;
       emit IPFSHashPosted(hash, date);
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