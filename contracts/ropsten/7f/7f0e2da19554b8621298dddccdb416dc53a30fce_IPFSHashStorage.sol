pragma solidity ^0.4.24;
    
    /**
     * @title IPFSHashStorage
     * @dev The IPFSHashStorage Contract provides basic hash storage against a account
     * and hash retrieval functions.
     */
    
    contract IPFSHashStorage {
        mapping (address => string) private storedHash;
        event HashUpdated (address user);
       
       /**
       * @dev store function writes hash in msg sender account 
       * @param hash of IPFS file
       */

        function store(string hash) public {
            storedHash[msg.sender] = hash;
            emit HashUpdated(msg.sender);
        }

       /**
       * @dev getStoredHash function reads hash from msg sender account
       * @return hash of IPFS file
       */

        function getStoredHash() public view returns(string hash) {
            return storedHash[msg.sender];
        }

    }