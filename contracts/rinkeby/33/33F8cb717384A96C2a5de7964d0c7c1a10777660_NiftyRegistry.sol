/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity ^0.5.4;

contract NiftyRegistry {
    
    
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    
    /**
     * Constants
     */ 
     
    uint constant public MAX_OWNER_COUNT = 50;
    

  /**
   * @dev Modifiers, mostly from the Gnosis Multisig
   */
    modifier onlyOwner() {
        require(isOwner[msg.sender] == true);
        _;
    }
  
   
   /** 
    * @dev A mapping of all sender keys
    */ 
    
   mapping(address => bool) validNiftyKeys;
   mapping (address => bool) public isOwner;
   
   /**
    * @dev Static view functions to retrieve information 
    */
     
    /**
    * @dev function to see if sending key is valid
    */
    
    function isValidNiftySender(address sending_key) public view returns (bool) {
      return(validNiftyKeys[sending_key]);
    }
    
      
      /**
       * @dev Functions to alter master contract information, such as HSM signing wallet keys, static contract
       * @dev All can only be changed by a multi sig transaciton so they have the onlyWallet modifier
       */ 
    
      /**
       * @dev Functions to add and remove nifty keys
       */
       
       function addNiftyKey(address new_sending_key) external onlyOwner {
           validNiftyKeys[new_sending_key] = true;
       }
       
       function removeNiftyKey(address sending_key) external onlyOwner {
           validNiftyKeys[sending_key] = false;
       }
  
  
  /**
   * Multisig transactions from https://github.com/gnosis/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol
   * Used to call transactions that will modify the master contract
   * Plus maintain owners, etc
   */
   
   /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    constructor(address[] memory _owners, address[] memory signing_keys)
        public
    {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
        }
        for (uint i=0; i<signing_keys.length; i++) {
            require(signing_keys[i] != address(0));
            validNiftyKeys[signing_keys[i]] = true;
        }
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyOwner
    {
        isOwner[owner] = true;
        emit OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyOwner
    {
        isOwner[owner] = false;
        emit OwnerRemoval(owner);
    }

 

}