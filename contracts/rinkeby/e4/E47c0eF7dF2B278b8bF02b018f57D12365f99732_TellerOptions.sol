pragma solidity ^0.8.0;


/*
Teller Options
*/
                                                                                 
  
 interface IERC721   {
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
    ///  except this function just sets data to "".
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

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


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



 
 
 interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}
  
  
  /*
    Extensions:
    ability to buy and sell the option 
  */
  
  
/**
 * 
 * 
 *  Staking contract that supports community-extractable donations 
 *
 */
contract TellerOptions is ERC721TokenReceiver {
 
  
 /* address public _stakeableCurrency; 
  address public _reservePoolToken; 
   
  event Donation(address from, uint256 amount);*/


  event OptionCreated(address from, uint256 amount);


  uint256 public optionsCount = 0;

  mapping(uint256 => Option) public options;

  enum OptionStatus {
    undefined,created,filled,exercised,cancelled
  }

  struct Option {
    address nftContractAddress;
    uint256 tokenId;
    uint256 expirationTime;
    uint256 buyoutPriceWei;
    uint256 incentiveAmountWei;
    address optionCreator;
    address optionFiller;
    OptionStatus status;

  }
   
  constructor(    ) 
  { 
     
  }

  uint256 immutable ONE_YEAR = 31536000;

  function createOption(address nftContractAddress, uint256 tokenId, uint256 expirationTime, uint256 buyoutPriceWei ) public payable returns (bool success) {
    require(expirationTime > block.timestamp && expirationTime < block.timestamp + ONE_YEAR, 'invalid expiration time');
    uint256 incentiveAmountWei = msg.value; 

    //pull the NFT into escrow
    IERC721(nftContractAddress).safeTransferFrom( msg.sender, address(this),  tokenId   );

    //initialize the options struct data 
    options[optionsCount++] = Option(nftContractAddress,tokenId,expirationTime,buyoutPriceWei,incentiveAmountWei,msg.sender, address(0), OptionStatus.created);

    //emit 


    return true; 
  }

  function cancelOption(uint256 optionId) public { 
    require(msg.sender == options[optionId].optionCreator, 'not the option creator');
   

    OptionStatus originalStatus = options[optionId].status;
    //set status to cancelled, mitigate re-entrancy 
    options[optionId].status = OptionStatus.cancelled;  

     require(originalStatus == OptionStatus.created 
      || originalStatus == OptionStatus.filled  );

    //return the NFT to the creator
      IERC721(options[optionId].nftContractAddress).safeTransferFrom(  address(this), options[optionId].optionCreator,  options[optionId].tokenId   );
  
    //return any buyout ether to the filler [if exists]
      if(originalStatus == OptionStatus.filled){
        payable(options[optionId].optionFiller).transfer( options[optionId].buyoutPriceWei );
      }

  }
  

  function fulfillOption(uint256 optionId) public payable {
    require(options[optionId].status == OptionStatus.created, 'incorrect state');
    require(options[optionId].expirationTime > block.timestamp, 'already expired');
    require(msg.value == options[optionId].buyoutPriceWei,'incorrect ether value to escrow');

    //pull the buyoutpricewei into escrow and set option filled 
    options[optionId].optionFiller = msg.sender;
    options[optionId].status = OptionStatus.filled;

    //send the incentive amount to the fulfiller 
    payable(msg.sender).transfer(options[optionId].incentiveAmountWei);
  }

  function exerciseOption(uint256 optionId) public {
    require(msg.sender == options[optionId].optionCreator);
    require(options[optionId].status == OptionStatus.filled);
    require(block.timestamp < options[optionId].expirationTime);

      
    options[optionId].status = OptionStatus.exercised;

    //send the buyout ether to the optionCreator
    payable(options[optionId].optionCreator).transfer( options[optionId].buyoutPriceWei);


    //send the NFT to the optionFulfiller 
    IERC721(options[optionId].nftContractAddress).safeTransferFrom(  address(this), options[optionId].optionFiller,  options[optionId].tokenId   );
  
  }
   
   function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {

        return
            bytes4(
                keccak256(
                    "onERC721Received(address,address,uint256,bytes)"
                )
            );
    }
   
     // ------------------------------------------------------------------------

    // Don't accept ETH

    // ------------------------------------------------------------------------
 
    fallback() external payable { revert(); }
    receive() external payable { revert(); }
   

}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}