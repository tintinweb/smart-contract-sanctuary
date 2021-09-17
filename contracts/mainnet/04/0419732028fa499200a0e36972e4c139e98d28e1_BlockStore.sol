/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

pragma solidity ^0.8.0;


/**
 NFT BlockStore 

 Made with <3 by InfernalToast 
*/
 
 
 interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        
        interface ProjectBasedNFT {
            function tokenIdToProjectId(uint256 tokenId) external returns(uint256);
        }



// ----------------------------------------------------------------------------

// Owned contract

// ----------------------------------------------------------------------------

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


/*

  An NFT exchange for ERC721 tokens 

  Supports offchain sell orders 

  Supports offchain buy orders 
 
*/

contract BlockStore is Owned, ECRecovery  {
 
    
  mapping (address => mapping(bytes32 => uint)) public burnedNonces; 
    
  

  mapping(address => uint256) public _fee_pct;
  mapping(address => bool) public _allowedNFTContractAddress;

  address constant internal NATIVE_ETH = 0x0000000000000000000000000000000000000010;
 
  mapping (address => uint256) userSellOrderNonce; 
                                         
 
  constructor(  ) public { 
   
  }

  function setFee( address projectContract, uint fee_pct ) public onlyOwner { 
    require(fee_pct >= 0 && fee_pct <=1000);

    _fee_pct[projectContract] = fee_pct; 
  }



  function setProjectAllowed( address projectContract, bool allow ) public onlyOwner { 
    
    _allowedNFTContractAddress[projectContract] = allow; 
  }


  //Do not allow ETH to enter
  receive() external payable {
    revert();
  }

  fallback() external payable {
    revert();
  }

  function getChainID() public view returns (uint256) {
    uint256 id;
    assembly {
        id := chainid()
    }
    return id;
  }
  
  
   
  event nftSale(address sellerAddress, address buyerAddress, address nftContractAddress, uint256 nftTokenId, address currencyTokenAddress, uint256 currencyTokenAmount);
  
  event nonceBurned(address indexed signer, bytes32 nonce);

  struct OffchainOrder {
   
    address orderCreator;
    bool isSellOrder;  //if false then its a buy order 

    address nftContractAddress;
    uint256 nftTokenId;

    address currencyTokenAddress; //if 0x10 that means eth 
    uint256 currencyTokenAmount;
    
    bytes32 nonce;//only used for sell orders and is random, used by front end to group offchain orders together 
    uint256 expires; 
  }
 
  
     bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
          "EIP712Domain(string contractName,string version,uint256 chainId,address verifyingContract)"
      );

   function getBidDomainTypehash() public pure returns (bytes32) {
      return EIP712DOMAIN_TYPEHASH;
   }

   function getEIP712DomainHash(string memory contractName, string memory version, uint256 chainId, address verifyingContract) public pure returns (bytes32) {

      return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(contractName)),
            keccak256(bytes(version)),
            chainId,
            verifyingContract
        ));
    }
 

  bytes32 constant ORDER_TYPEHASH = keccak256(  
    "OffchainOrder(address orderCreator,bool isSellOrder,address nftContractAddress,uint256 nftTokenId,address currencyTokenAddress,uint256 currencyTokenAmount,bytes32 nonce,uint256 expires)"
  );

  


  function getOrderTypehash()  public pure returns (bytes32) {
      return ORDER_TYPEHASH;
  }


  
  function getOrderHash(address orderCreator,bool isSellOrder,address nftContractAddress,uint256 nftTokenId,address currencyTokenAddress, uint256 currencyTokenAmount,bytes32 nonce,uint256 expires) public pure returns (bytes32) {
          return keccak256(abi.encode(
              ORDER_TYPEHASH,
              orderCreator,
              isSellOrder,
              nftContractAddress,
              nftTokenId,
              currencyTokenAddress,
              currencyTokenAmount,
              nonce,
              expires
          ));
      }

 

  function getOrderTypedDataHash(address orderCreator,bool isSellOrder,address nftContractAddress,uint256 nftTokenId,address currencyTokenAddress, uint256 currencyTokenAmount,bytes32 nonce,uint256 expires) public view returns (bytes32) {
 
              bytes32 digest = keccak256(abi.encodePacked(
                  "\x19\x01",
                  getEIP712DomainHash('BlockStore','1',getChainID(),address(this)),
                  getOrderHash(orderCreator,isSellOrder,nftContractAddress,nftTokenId,currencyTokenAddress,currencyTokenAmount,nonce,expires)
              ));
              return digest;
          }
  

  //require pre-approval from the buyer in the form of a personal sign of an offchain buy order 
  function sellNFTUsingBuyOrder(address buyer, address nftContractAddress, uint256 nftTokenId, address currencyToken, uint256 currencyAmount, bytes32 nonce, uint256 expires, bytes memory buyerSignature) public returns (bool){

      require(_allowedNFTContractAddress[nftContractAddress],'Project not allowed');

      //require personalsign from buyer to be submitted by seller  
      bytes32 sigHash = getOrderTypedDataHash(buyer,false,nftContractAddress,nftTokenId,currencyToken,currencyAmount,nonce,expires);
 
       
      require(buyer ==  recover(sigHash,buyerSignature) , 'Invalid signature');
         
      
      require(block.number < expires || expires == 0, 'bid expired');

      require(burnedNonces[buyer][nonce] == 0, 'nonce already burned');
      burnedNonces[buyer][nonce] = 0x1;
       
      
      ERC721(nftContractAddress).safeTransferFrom(msg.sender, buyer, nftTokenId);
      
      _transferCurrencyForSale(buyer,msg.sender,currencyToken,currencyAmount,_fee_pct[nftContractAddress]);
      
      
      emit nftSale(msg.sender, buyer,  nftContractAddress, nftTokenId, currencyToken, currencyAmount);
      emit nonceBurned(buyer, nonce);

      return true;
  }


  function buyNFTUsingSellOrder(address seller, address nftContractAddress, uint256 nftTokenId, address currencyToken, uint256 currencyAmount, bytes32 nonce, uint256 expires, bytes memory sellerSignature) payable public returns (bool){

      require(_allowedNFTContractAddress[nftContractAddress],'Project not allowed');


      //require personalsign from seller to be submitted by buyer  
      bytes32 sigHash = getOrderTypedDataHash(seller,true,nftContractAddress,nftTokenId,currencyToken,currencyAmount,nonce,expires);

      
       
      require(seller == recover(sigHash,sellerSignature), 'Invalid signature');
       
      
      require(block.number < expires || expires == 0, 'bid expired');
     
      require(burnedNonces[seller][nonce] == 0, 'nonce already burned');
      burnedNonces[seller][nonce] = 0x1;
       
      
      ERC721(nftContractAddress).safeTransferFrom(seller, msg.sender, nftTokenId);
      
      _transferCurrencyForSale(msg.sender,seller,currencyToken,currencyAmount,_fee_pct[nftContractAddress]);
      
      
      emit nftSale(  seller,  msg.sender, nftContractAddress, nftTokenId, currencyToken, currencyAmount);
      emit nonceBurned(seller, nonce);

      return true;
  }
  
  function _transferCurrencyForSale(address from, address to, address currencyToken, uint256 currencyAmount, uint256 feePct) internal returns (bool){
    uint256 feeAmount = (currencyAmount * feePct)/(10000);

    if(currencyToken == NATIVE_ETH){  
      require(msg.value == currencyAmount,'incorrect payment value'); 
      payable(to).transfer( currencyAmount - (feeAmount) );
      payable(owner).transfer( feeAmount );
    }else{
      require(msg.value == 0,'incorrect payment value'); 
      require( IERC20(currencyToken).transferFrom(from, to, currencyAmount - (feeAmount) ), 'unable to pay' );
      require( IERC20(currencyToken).transferFrom(from, owner, feeAmount ), 'unable to pay'  ); 
    }
    
    return true;
  } 
  
   
  function cancelOffchainOrder(address orderCreator, bool isSellOrder, address nftContractAddress, uint256 nftTokenId, address currencyToken, uint256 currencyAmount, bytes32 nonce, uint256 expires, bytes memory offchainSignature ) public returns (bool){
      bytes32 sigHash = getOrderTypedDataHash(orderCreator,isSellOrder,nftContractAddress,nftTokenId,currencyToken,currencyAmount,nonce,expires);
      address recoveredSignatureSigner = recover(sigHash,offchainSignature);
      
      require(orderCreator == recoveredSignatureSigner, 'Invalid signature');
      require(msg.sender == recoveredSignatureSigner, 'Not signature owner');


      require(burnedNonces[orderCreator][nonce] == 0, 'Nonce already burned');
      burnedNonces[orderCreator][nonce] = 0x2;
        
      emit nonceBurned(orderCreator, nonce);
      
      return true;
  }
  
  
  
}