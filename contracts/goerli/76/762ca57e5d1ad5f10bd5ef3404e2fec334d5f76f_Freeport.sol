/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity ^0.5;


/**
    NFT Freeport V2 


  Create a new, unknown Ethereum address X which you control 
  Select a random number 'salt'
  Derive a hash digest D, where D = sha256(tokenAddress,tokenId,X,salt)

  Store an NFT in this contract, belonging to hash digest D 

  Withdraw the NFT at a later time from address X, specifying your 'salt' number 



  By doing so, while the token is inside of the freeport contract, it is impossible to know who the owner is but only the owner will be able to withdraw it at a later time.
  The owner of the token is revealed when the art is removed from the Freeport.



 *** Client uses HDWallet Seeds 
 
*/

   


contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}

 
contract ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes memory sig) internal  pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}



/// @title ERC-721 Non-Fungible Token Standard
       /// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
       ///  Note: the ERC-165 identifier for this interface is 0x80ac58cd
       interface ERC721 /* is ERC165 */ {
           /// @dev This emits when ownership of any NFT changes by any mechanism.
           ///  This event emits when NFTs are created (`from` == 0) and destroyed
           ///  (`to` == 0). Exception: during contract creation, any number of NFTs
           ///  may be created and assigned without emitting Transfer. At the time of
           ///  any transfer, the approved address for that NFT (if any) is reset to none.
           event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

           /// @dev This emits when the approved address for an NFT is changed or
           ///  reaffirmed. The zero address indicates there is no approved address.
           ///  When a Transfer event emits, this also indicates that the approved
           ///  address for that NFT (if any) is reset to none.
           event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

           /// @dev This emits when an operator is enabled or disabled for an owner.
           ///  The operator can manage all NFTs of the owner.
           event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

           /// @notice Count all NFTs assigned to an owner
           /// @dev NFTs assigned to the zero address are considered invalid, and this
           ///  function throws for queries about the zero address.
           /// @param _owner An address for whom to query the balance
           /// @return The number of NFTs owned by `_owner`, possibly zero
           function balanceOf(address _owner) external view returns (uint256);

           /// @notice Find the owner of an NFT
           /// @dev NFTs assigned to zero address are considered invalid, and queries
           ///  about them do throw.
           /// @param _tokenId The identifier for an NFT
           /// @return The address of the owner of the NFT
           function ownerOf(uint256 _tokenId) external view returns (address);

           /// @notice Transfers the ownership of an NFT from one address to another address
           /// @dev Throws unless `msg.sender` is the current owner, an authorized
           ///  operator, or the approved address for this NFT. Throws if `_from` is
           ///  not the current owner. Throws if `_to` is the zero address. Throws if
           ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
           ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
           ///  `onERC721Received` on `_to` and throws if the return value is not
           ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
           /// @param _from The current owner of the NFT
           /// @param _to The new owner
           /// @param _tokenId The NFT to transfer
           /// @param data Additional data with no specified format, sent in call to `_to`
           function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

           /// @notice Transfers the ownership of an NFT from one address to another address
           /// @dev This works identically to the other function with an extra data parameter,
           ///  except this function just sets data to ""
           /// @param _from The current owner of the NFT
           /// @param _to The new owner
           /// @param _tokenId The NFT to transfer
           function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

           /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
           ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
           ///  THEY MAY BE PERMANENTLY LOST
           /// @dev Throws unless `msg.sender` is the current owner, an authorized
           ///  operator, or the approved address for this NFT. Throws if `_from` is
           ///  not the current owner. Throws if `_to` is the zero address. Throws if
           ///  `_tokenId` is not a valid NFT.
           /// @param _from The current owner of the NFT
           /// @param _to The new owner
           /// @param _tokenId The NFT to transfer
           function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

           /// @notice Set or reaffirm the approved address for an NFT
           /// @dev The zero address indicates there is no approved address.
           /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
           ///  operator of the current owner.
           /// @param _approved The new approved NFT controller
           /// @param _tokenId The NFT to approve
           function approve(address _approved, uint256 _tokenId) external payable;

           /// @notice Enable or disable approval for a third party ("operator") to manage
           ///  all of `msg.sender`'s assets.
           /// @dev Emits the ApprovalForAll event. The contract MUST allow
           ///  multiple operators per owner.
           /// @param _operator Address to add to the set of authorized operators.
           /// @param _approved True if the operator is approved, false to revoke approval
           function setApprovalForAll(address _operator, bool _approved) external;

           /// @notice Get the approved address for a single NFT
           /// @dev Throws if `_tokenId` is not a valid NFT
           /// @param _tokenId The NFT to find the approved address for
           /// @return The approved address for this NFT, or the zero address if there is none
           function getApproved(uint256 _tokenId) external view returns (address);

           /// @notice Query if an address is an authorized operator for another address
           /// @param _owner The address that owns the NFTs
           /// @param _operator The address that acts on behalf of the owner
           /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
           function isApprovedForAll(address _owner, address _operator) external view returns (bool);
       }

       interface ERC165 {
           /// @notice Query if a contract implements an interface
           /// @param interfaceID The interface identifier, as specified in ERC-165
           /// @dev Interface identification is specified in ERC-165. This function
           ///  uses less than 30,000 gas.
           /// @return `true` if the contract implements `interfaceID` and
           ///  `interfaceID` is not 0xffffffff, `false` otherwise
           function supportsInterface(bytes4 interfaceID) external view returns (bool);
       }

       interface ERC721TokenReceiver {
           /// @notice Handle the receipt of an NFT
           /// @dev The ERC721 smart contract calls this function on the
           /// recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
           /// of other than the magic value MUST result in the transaction being reverted.
           /// @notice The contract address is always the message sender.
           /// @param _operator The address which called `safeTransferFrom` function
           /// @param _from The address which previously owned the token
           /// @param _tokenId The NFT identifier which is being transferred
           /// @param _data Additional data with no specified format
           /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
           /// unless throwing
           function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
        }



contract Freeport is SafeMath,ERC721TokenReceiver,ECRecovery {

  mapping (bytes32 => uint) public usedVaultCodes; 
  //mapping (address => uint) public userNonce; 
  mapping (address => mapping (uint => bytes32)) public vaultCodes; //mapping of token addresses to mapping of account balances (token=0 means Ether)
  
  
   event Deposit(address tokenContract, uint tokenId, bytes32 ownerDigest);
   event Withdraw(address tokenContract, uint tokenId, bytes32 ownerDigest);

  constructor() public {

  }

  //Do not allow ETH to enter
  function() external payable {
    revert();
  }

 

  //allow safe receive of ERC721 
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4){
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }


    //the depositor knows the private key, SecretPrivKey1

   // bytes32 secretDigest = keccak256( SecretPubAddr1 )
  function depositToken(address from, address tokenContract, uint tokenId, bytes32 hashedSecretPublicAddress) public {
    
    require( vaultCodes[tokenContract][tokenId] == 0x0 );


    //make sure this pub key/pub addr has never been used (enforce high security practice) 
    require( usedVaultCodes[hashedSecretPublicAddress] == 0x0 );
    usedVaultCodes[hashedSecretPublicAddress] = 0x1;

    ERC721(tokenContract).transferFrom(from, address(this) ,tokenId)  ;
    //make sure that we received the token ? 

    vaultCodes[tokenContract][tokenId] = hashedSecretPublicAddress;

    emit Deposit(tokenContract, tokenId, hashedSecretPublicAddress);

  }



  function withdrawToken(address tokenContract, uint tokenId,address to, bytes32 actionMessageHash, bytes memory signature) public {

    
    //require that the action message data matches this request - prevent frontrun 
    require( actionMessageHash == keccak256(abi.encodePacked('withdraw', msg.sender, to, tokenContract, tokenId  )) );


    address recoveredPubAddr = recover(actionMessageHash,signature);
    
     
    bytes32 storedVaultCode = vaultCodes[tokenContract][tokenId];


    require(keccak256(abi.encodePacked(recoveredPubAddr)) == storedVaultCode);

    vaultCodes[tokenContract][tokenId] = 0x0;

    ERC721(tokenContract).approve(to,tokenId);
    ERC721(tokenContract).transferFrom(address(this),to,tokenId) ;    

   // emit Withdraw(tokenContract, tokenId, computedOwnerDigest);
     
  }



  /*
      Allow the owner of a token to transfer ownership within the contract, using a personal sign that is ecrecovered 
      Every single transaction requires a new private key + pub address pair 
  */
  function secretTransfer(address tokenContract, uint tokenId, bytes32 newVaultCode, bytes32 actionMessageHash, bytes memory signature) public {
    
    //require that the action message data matches this request - prevent frontrun 
    require( actionMessageHash == keccak256(abi.encodePacked('secretTransfer', msg.sender, newVaultCode, tokenContract, tokenId    )) );


    address recoveredPubAddr = recover(actionMessageHash,signature);
    
     
    bytes32 storedVaultCode = vaultCodes[tokenContract][tokenId];
 
    
    require(keccak256(abi.encodePacked(recoveredPubAddr)) == storedVaultCode);

    require( usedVaultCodes[newVaultCode] == 0x0 );
    usedVaultCodes[newVaultCode] = 0x1;


    vaultCodes[tokenContract][tokenId] = newVaultCode;
 

  }
 
      
 
}