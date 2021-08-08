/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

// This contract is a fixed version of the old NFT Sprites contract (0x325a468f3453ea52c5cf3d0fa0ba68d4cbc0f8a4) which had a bug. Do not interact with the old contract.
// All the legitimate NFT Sprite owners from the old contract are given their NFT's in this new contract as well.

pragma solidity 0.8.0;

/**
 * @dev ERC-721 interface for accepting safe transfers.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721TokenReceiver
{

  /**
   * @dev Handle the receipt of a NFT. The ERC721 smart contract calls this function on the
   * recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
   * of other than the magic value MUST result in the transaction being reverted.
   * Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` unless throwing.
   * @notice The contract address is always the message sender. A wallet/broker/auction application
   * MUST implement the wallet interface if it will accept safe transfers.
   * @param _operator The address which called `safeTransferFrom` function.
   * @param _from The address which previously owned the token.
   * @param _tokenId The NFT identifier which is being transferred.
   * @param _data Additional data with no specified format.
   * @return Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

}

/**
 * @dev ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721
{

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they mayb be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Set or reaffirm the approved address for an NFT.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice The contract MUST allow multiple operators per owner.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
   * invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}


/**
 * @dev Utility library of inline functions on addresses.
 * @notice Based on:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 * Requires EIP-1052.
 */
library AddressUtils
{

  /**
   * @dev Returns whether the target address is a contract.
   * @param _addr Address to check.
   * @return addressCheck True if _addr is a contract, false if not.
   */
  function isContract(
    address _addr
  )
    internal
    view
    returns (bool addressCheck)
  {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) } // solhint-disable-line
    addressCheck = (codehash != 0x0 && codehash != accountHash);
  }

}


interface ERC165
{

  /**
   * @dev Checks if the smart contract includes a specific interface.
   * This function uses less than 30,000 gas.
   * @param _interfaceID The interface identifier, as specified in ERC-165.
   * @return True if _interfaceID is supported, false otherwise.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);
    
}

/**
 * @dev Implementation of standard for detect smart contract interfaces.
 */
contract SupportsInterface is
  ERC165
{

  /**
   * @dev Mapping of supported intefraces. You must not set element 0xffffffff to true.
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev Contract constructor.
   */
  constructor()
  {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }

  /**
   * @dev Function to check which interfaces are suported by this contract.
   * @param _interfaceID Id of the interface.
   * @return True if _interfaceID is supported, false otherwise.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    override
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

}



contract NFTSprites is
  ERC721,
  SupportsInterface
{
  using AddressUtils for address;

  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant ZERO_ADDRESS = "003001";
  string constant NOT_VALID_NFT = "003002";
  string constant NOT_OWNER_OR_OPERATOR = "003003";
  string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  string constant NFT_ALREADY_EXISTS = "003006";
  string constant NOT_OWNER = "003007";
  string constant IS_OWNER = "003008";
  
  string internal nftName = "NFT Sprites";
  string internal nftSymbol = "NFTS";
  
  uint public latestNewSpriteForSale;
  
  address owner;
    
  struct Sprite {
    address owner;
    bool currentlyForSale;
    uint price;
    uint timesSold;
  }
  
  mapping (uint => Sprite) public sprites;
  
  function getSpriteInfo (uint spriteNumber) public view returns (address, bool, uint, uint) {
    return (sprites[spriteNumber].owner, sprites[spriteNumber].currentlyForSale, sprites[spriteNumber].price, sprites[spriteNumber].timesSold);
  }
  
  // ownerOf does this as well
  function getSpriteOwner (uint spriteNumber) public view returns (address) {
    return (sprites[spriteNumber].owner);
  }
  
  mapping (address => uint[]) public spriteOwners;
  function spriteOwningHistory (address _address) public view returns (uint[] memory owningHistory) {
    owningHistory = spriteOwners[_address];
  }
  
  function name() external view returns (string memory _name) {
    _name = nftName;
  }
  
  function symbol() external view returns (string memory _symbol) {
    _symbol = nftSymbol;
  }

  /**
   * @dev Magic value of a smart contract that can recieve NFT.
   * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
   */
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  /**
   * @dev A mapping from NFT ID to the address that owns it.
   */
  mapping (uint256 => address) internal idToOwner;

  /**
   * @dev Mapping from NFT ID to approved address.
   */
  mapping (uint256 => address) internal idToApproval;

   /**
   * @dev Mapping from owner address to count of his tokens.
   */
  mapping (address => uint256) private ownerToNFTokenCount;

  /**
   * @dev Mapping from owner address to mapping of operator addresses.
   */
  mapping (address => mapping (address => bool)) internal ownerToOperators;

  /**
   * @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier canOperate(uint256 _tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that the msg.sender is allowed to transfer NFT.
   * @param _tokenId ID of the NFT to transfer.
   */
   
   // idToApproval[_tokenId] = _approved;
   
  modifier canTransfer(uint256 _tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_APPROVED_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that _tokenId is a valid Token.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier validNFToken(uint256 _tokenId) {
    require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
    _;
  }

  /**
   * @dev Contract constructor.
   */
  constructor() {
    supportedInterfaces[0x80ac58cd] = true; // ERC721
    
    // Below all the legitimate NFT Sprite owners from the old contract are given their NFT's in this new contract (can only be called once, when this contract is deployed).
    
    // original buyers
    ownerToNFTokenCount[0xDE6Ad599B2b669dA30525af0820D0a27ca5fdA6f] = 1;
    ownerToNFTokenCount[0x7DF397FB4981f2708931c3163eFA81be41C13302] = 1;
    ownerToNFTokenCount[0xC9f203B4692c04bA7155Ef71d8f5D42bfCfbC09B] = 1;
    ownerToNFTokenCount[0x48e4dd3e356823070D9d1B7d162d072aE9EFE0Cb] = 1;
    ownerToNFTokenCount[0xbf67e713ddEf50496c6F27C41Eaeecee3A9FA063] = 1;
    ownerToNFTokenCount[0x1A200f926A078400961B47C8965E57e1573C293C] = 1;
    ownerToNFTokenCount[0xd161F45C77cdBaa63bd59137d2773462924AfeDe] = 1;
    ownerToNFTokenCount[0xd9c3415Bf8600f007A1b4199DF967C25A3E00EeA] = 3;
    ownerToNFTokenCount[0x172d894dB40435D04A099e081eade6492D3E71a8] = 2;
    ownerToNFTokenCount[0xE2008Ef79a7d0D75EdAE70263384D4aC5D1A9f9A] = 1;
    ownerToNFTokenCount[0xB117a08963Db62c31070eEdff0e192176251a3Fb] = 1;
    ownerToNFTokenCount[0x375D4DE9c37B3b93e4C0af0E58D54F7DFF06cC16] = 1;
    ownerToNFTokenCount[0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA] = 2;
    ownerToNFTokenCount[0x4202C5Aa18c934B96Bc4aEDB3DA4593c44076618] = 1;
    ownerToNFTokenCount[0x7B167965d0449D27476eF236a8B6A02d5ABd27C4] = 1;
    ownerToNFTokenCount[0x40D80168B6663700B6AE55d71a8c2Cf61d0C1225] = 1;
    
    // addresses that received an NFT from an owner transferring it to them
    ownerToNFTokenCount[0x070DcB7ba170091F84783b224489aA8B280c1A30] = 1;
    ownerToNFTokenCount[0x6747B33F4293fB4fD1bEaa5D7935F85d5958b684] = 1;
    ownerToNFTokenCount[0xcDb89f98012b5755B4874CBf6E8787b18996c69D] = 1;
    
    sprites[0].owner = 0xDE6Ad599B2b669dA30525af0820D0a27ca5fdA6f;
    sprites[0].currentlyForSale = false;
    sprites[0].price = (10**15)*5;
    sprites[0].timesSold = 1;
    idToOwner[0] = 0xDE6Ad599B2b669dA30525af0820D0a27ca5fdA6f;
    spriteOwners[0xDE6Ad599B2b669dA30525af0820D0a27ca5fdA6f].push(0);
    
    sprites[1].owner = 0x7DF397FB4981f2708931c3163eFA81be41C13302;
    sprites[1].currentlyForSale = false;
    sprites[1].price = (10**15)*5;
    sprites[1].timesSold = 1;
    idToOwner[1] = 0x7DF397FB4981f2708931c3163eFA81be41C13302;
    spriteOwners[0x7DF397FB4981f2708931c3163eFA81be41C13302].push(1);
    
    sprites[2].owner = 0xC9f203B4692c04bA7155Ef71d8f5D42bfCfbC09B;
    sprites[2].currentlyForSale = false;
    sprites[2].price = 2**2 * (10**15)*5;
    sprites[2].timesSold = 1;
    idToOwner[2] = 0xC9f203B4692c04bA7155Ef71d8f5D42bfCfbC09B;
    spriteOwners[0xC9f203B4692c04bA7155Ef71d8f5D42bfCfbC09B].push(2);
    
    sprites[3].owner = 0xcDb89f98012b5755B4874CBf6E8787b18996c69D; // original owner was 0xC9f203B4692c04bA7155Ef71d8f5D42bfCfbC09B, who later transferred it to this new owner: https://etherscan.io/tx/0x48602caef82ae441cd0bc15010d9027c3317573ac80cea73f01d157c82000bd4
    sprites[3].currentlyForSale = false;
    sprites[3].price = 3**2 * (10**15)*5;
    sprites[3].timesSold = 1;
    idToOwner[3] = 0xcDb89f98012b5755B4874CBf6E8787b18996c69D;
    spriteOwners[0xcDb89f98012b5755B4874CBf6E8787b18996c69D].push(3);
    
    sprites[4].owner = 0x48e4dd3e356823070D9d1B7d162d072aE9EFE0Cb;
    sprites[4].currentlyForSale = false;
    sprites[4].price = 4**2 * (10**15)*5;
    sprites[4].timesSold = 1;
    idToOwner[4] = 0x48e4dd3e356823070D9d1B7d162d072aE9EFE0Cb;
    spriteOwners[0x48e4dd3e356823070D9d1B7d162d072aE9EFE0Cb].push(4);
    
    sprites[5].owner = 0xbf67e713ddEf50496c6F27C41Eaeecee3A9FA063;
    sprites[5].currentlyForSale = false;
    sprites[5].price = 5**2 * (10**15)*5;
    sprites[5].timesSold = 1;
    idToOwner[5] = 0xbf67e713ddEf50496c6F27C41Eaeecee3A9FA063;
    spriteOwners[0xbf67e713ddEf50496c6F27C41Eaeecee3A9FA063].push(5);
    
    sprites[6].owner = 0x1A200f926A078400961B47C8965E57e1573C293C;
    sprites[6].currentlyForSale = false;
    sprites[6].price = 6**2 * (10**15)*5;
    sprites[6].timesSold = 1;
    idToOwner[6] = 0x1A200f926A078400961B47C8965E57e1573C293C;
    spriteOwners[0x1A200f926A078400961B47C8965E57e1573C293C].push(6);
    
    sprites[7].owner = 0xd161F45C77cdBaa63bd59137d2773462924AfeDe;
    sprites[7].currentlyForSale = false;
    sprites[7].price = 7**2 * (10**15)*5;
    sprites[7].timesSold = 1;
    idToOwner[7] = 0xd161F45C77cdBaa63bd59137d2773462924AfeDe;
    spriteOwners[0xd161F45C77cdBaa63bd59137d2773462924AfeDe].push(7);
    
    sprites[8].owner = 0xd9c3415Bf8600f007A1b4199DF967C25A3E00EeA;
    sprites[8].currentlyForSale = false;
    sprites[8].price = 8**2 * (10**15)*5;
    sprites[8].timesSold = 1;
    idToOwner[8] = 0xd9c3415Bf8600f007A1b4199DF967C25A3E00EeA;
    spriteOwners[0xd9c3415Bf8600f007A1b4199DF967C25A3E00EeA].push(8);
    
    sprites[9].owner = 0xd9c3415Bf8600f007A1b4199DF967C25A3E00EeA;
    sprites[9].currentlyForSale = false;
    sprites[9].price = 9**2 * (10**15)*5;
    sprites[9].timesSold = 1;
    idToOwner[9] = 0xd9c3415Bf8600f007A1b4199DF967C25A3E00EeA;
    spriteOwners[0xd9c3415Bf8600f007A1b4199DF967C25A3E00EeA].push(9);
    
    sprites[10].owner = 0xd9c3415Bf8600f007A1b4199DF967C25A3E00EeA;
    sprites[10].currentlyForSale = false;
    sprites[10].price = 10**2 * (10**15)*5;
    sprites[10].timesSold = 1;
    idToOwner[10] = 0xd9c3415Bf8600f007A1b4199DF967C25A3E00EeA;
    spriteOwners[0xd9c3415Bf8600f007A1b4199DF967C25A3E00EeA].push(10);
    
    sprites[11].owner = 0x172d894dB40435D04A099e081eade6492D3E71a8;
    sprites[11].currentlyForSale = false;
    sprites[11].price = 11**2 * (10**15)*5;
    sprites[11].timesSold = 1;
    idToOwner[11] = 0x172d894dB40435D04A099e081eade6492D3E71a8;
    spriteOwners[0x172d894dB40435D04A099e081eade6492D3E71a8].push(11);
    
    sprites[12].owner = 0xE2008Ef79a7d0D75EdAE70263384D4aC5D1A9f9A;
    sprites[12].currentlyForSale = false;
    sprites[12].price = 12**2 * (10**15)*5;
    sprites[12].timesSold = 1;
    idToOwner[12] = 0xE2008Ef79a7d0D75EdAE70263384D4aC5D1A9f9A;
    spriteOwners[0xE2008Ef79a7d0D75EdAE70263384D4aC5D1A9f9A].push(12);
    
    sprites[13].owner = 0xB117a08963Db62c31070eEdff0e192176251a3Fb;
    sprites[13].currentlyForSale = false;
    sprites[13].price = 13**2 * (10**15)*5;
    sprites[13].timesSold = 1;
    idToOwner[13] = 0xB117a08963Db62c31070eEdff0e192176251a3Fb;
    spriteOwners[0xB117a08963Db62c31070eEdff0e192176251a3Fb].push(13);
    
    sprites[14].owner = 0x375D4DE9c37B3b93e4C0af0E58D54F7DFF06cC16;
    sprites[14].currentlyForSale = false;
    sprites[14].price = 14**2 * (10**15)*5;
    sprites[14].timesSold = 1;
    idToOwner[14] = 0x375D4DE9c37B3b93e4C0af0E58D54F7DFF06cC16;
    spriteOwners[0x375D4DE9c37B3b93e4C0af0E58D54F7DFF06cC16].push(14);
    
    sprites[15].owner = 0x070DcB7ba170091F84783b224489aA8B280c1A30; // original owner was 0xd9c3415Bf8600f007A1b4199DF967C25A3E00EeA, who later transferred it to this new owner: https://etherscan.io/tx/0xe2427b79bb545188468cba61a8ffc8a1f69ce1ce60f66a4ac18ac9f883336d22
    sprites[15].currentlyForSale = false;
    sprites[15].price = 15**2 * (10**15)*5;
    sprites[15].timesSold = 1;
    idToOwner[15] = 0x070DcB7ba170091F84783b224489aA8B280c1A30;
    spriteOwners[0x070DcB7ba170091F84783b224489aA8B280c1A30].push(15);
    
    sprites[16].owner = 0x172d894dB40435D04A099e081eade6492D3E71a8;
    sprites[16].currentlyForSale = false;
    sprites[16].price = 16**2 * (10**15)*5;
    sprites[16].timesSold = 1;
    idToOwner[16] = 0x172d894dB40435D04A099e081eade6492D3E71a8;
    spriteOwners[0x172d894dB40435D04A099e081eade6492D3E71a8].push(16);
    
    sprites[17].owner = 0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA;
    sprites[17].currentlyForSale = false;
    sprites[17].price = 17**2 * (10**15)*5;
    sprites[17].timesSold = 1;
    idToOwner[17] = 0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA;
    spriteOwners[0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA].push(17);
    
    sprites[18].owner = 0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA;
    sprites[18].currentlyForSale = false;
    sprites[18].price = 18**2 * (10**15)*5;
    sprites[18].timesSold = 1;
    idToOwner[18] = 0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA;
    spriteOwners[0xe4446D52e2bdB3E31470643Ab1753a4c2aEee3eA].push(18);
    
    sprites[19].owner = 0x4202C5Aa18c934B96Bc4aEDB3DA4593c44076618;
    sprites[19].currentlyForSale = false;
    sprites[19].price = 19**2 * (10**15)*5;
    sprites[19].timesSold = 1;
    idToOwner[19] = 0x4202C5Aa18c934B96Bc4aEDB3DA4593c44076618;
    spriteOwners[0x4202C5Aa18c934B96Bc4aEDB3DA4593c44076618].push(19);
    
    sprites[20].owner = 0x7B167965d0449D27476eF236a8B6A02d5ABd27C4;
    sprites[20].currentlyForSale = false;
    sprites[20].price = 20**2 * (10**15)*5;
    sprites[20].timesSold = 1;
    idToOwner[20] = 0x7B167965d0449D27476eF236a8B6A02d5ABd27C4;
    spriteOwners[0x7B167965d0449D27476eF236a8B6A02d5ABd27C4].push(20);
    
    sprites[21].owner = 0x40D80168B6663700B6AE55d71a8c2Cf61d0C1225;
    sprites[21].currentlyForSale = false;
    sprites[21].price = 21**2 * (10**15)*5;
    sprites[21].timesSold = 1;
    idToOwner[21] = 0x40D80168B6663700B6AE55d71a8c2Cf61d0C1225;
    spriteOwners[0x40D80168B6663700B6AE55d71a8c2Cf61d0C1225].push(21);
    
    sprites[22].owner = 0x6747B33F4293fB4fD1bEaa5D7935F85d5958b684; // original owner was 0x9e4a9b4334f3167bc7dd35f48f2238c73f532baf, who later transferred it to this new owner: https://etherscan.io/tx/0x85f5486c54ae8fd9b6bd73ed524835a0517f816d50f40273e74e1df706309db2
    sprites[22].currentlyForSale = false;
    sprites[22].price = 22**2 * (10**15)*5;
    sprites[22].timesSold = 1;
    idToOwner[22] = 0x6747B33F4293fB4fD1bEaa5D7935F85d5958b684;
    spriteOwners[0x6747B33F4293fB4fD1bEaa5D7935F85d5958b684].push(22);
    
    latestNewSpriteForSale = 23;
    
    sprites[23].currentlyForSale = true;
    sprites[23].price = 23**2 * (10**15)*5;
    
    owner = msg.sender;
  }
    
  function buySprite (uint spriteNumber) public payable {
    require(sprites[spriteNumber].currentlyForSale == true);
    require(msg.value == sprites[spriteNumber].price);
    require(spriteNumber < 100);
    sprites[spriteNumber].timesSold++;
    spriteOwners[msg.sender].push(spriteNumber);
    sprites[spriteNumber].currentlyForSale = false;
    if (spriteNumber != latestNewSpriteForSale) {
        // buying sprite that is already owned from someone
        // give existing sprite owner their money
        address currentSpriteOwner = getSpriteOwner(spriteNumber);
        payable(currentSpriteOwner).transfer(msg.value);
        // have to approve msg.sender for NFT to be transferred
        idToApproval[spriteNumber] = msg.sender;
        // _safeTransferFrom calls _transfer which updates the sprite owner to msg.sender and clears approvals
        _safeTransferFrom(currentSpriteOwner, msg.sender, spriteNumber, "");
    } else {
        // buying brand new latest sprite
        sprites[spriteNumber].owner = msg.sender;
        if (latestNewSpriteForSale != 99) {
            latestNewSpriteForSale++;
            sprites[latestNewSpriteForSale].price = latestNewSpriteForSale**2 * (10**15)*5;
            sprites[latestNewSpriteForSale].currentlyForSale = true;
        }
        _mint(msg.sender, spriteNumber);
    }
  }
  
  function sellSprite (uint spriteNumber, uint price) public {
    require(msg.sender == sprites[spriteNumber].owner);
    require(price > 0);
    sprites[spriteNumber].price = price;
    sprites[spriteNumber].currentlyForSale = true;
  }
  
  function dontSellSprite (uint spriteNumber) public {
    require(msg.sender == sprites[spriteNumber].owner);
    sprites[spriteNumber].currentlyForSale = false;
  }
  
  function giftSprite (uint spriteNumber, address receiver) public {
    require(msg.sender == sprites[spriteNumber].owner);
    require(receiver != address(0), ZERO_ADDRESS);
    spriteOwners[receiver].push(spriteNumber);
    _safeTransferFrom(msg.sender, receiver, spriteNumber, "");
  }
  
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }
  
  /**
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved Address to be approved for the given NFT ID.
   * @param _tokenId ID of the token to be approved.
   */
  function approve(address _approved, uint256 _tokenId) external override canOperate(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner, IS_OWNER);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice This works even if sender doesn't own any tokens at the time.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(address _operator, bool _approved) external override {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(address _owner) external override view returns (uint256) {
    require(_owner != address(0), ZERO_ADDRESS);
    return _getOwnerNFTCount(_owner);
  }

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
   * invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return _owner Address of _tokenId owner.
   */
  function ownerOf(uint256 _tokenId) external override view returns (address _owner) {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), NOT_VALID_NFT);
  }

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId ID of the NFT to query the approval of.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(uint256 _tokenId) external override view validNFToken(_tokenId) returns (address) {
    return idToApproval[_tokenId];
  }

  /**
   * @dev Checks if `_operator` is an approved operator for `_owner`.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
    return ownerToOperators[_owner][_operator];
  }

  /**
   * @dev Actually preforms the transfer.
   * @notice Does NO checks.
   * @param _to Address of a new owner.
   * @param _tokenId The NFT that is being transferred.
   */
  function _transfer(address _to, uint256 _tokenId) internal {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);
    
    sprites[_tokenId].owner = _to;

    emit Transfer(from, _to, _tokenId);
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(address _to, uint256 _tokenId) internal virtual {
    require(_to != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    _addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external burn
   * function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(uint256 _tokenId) internal virtual validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }
  
  /**
   * @dev Removes a NFT from owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(address _from, uint256 _tokenId) internal virtual {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from]--;
    delete idToOwner[_tokenId];
  }

  /**
   * @dev Assignes a new NFT to owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(address _to, uint256 _tokenId) internal virtual {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to]++;
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage (gas optimization) of owner nft count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(address _owner) internal virtual view returns (uint256) {
    return ownerToNFTokenCount[_owner];
  }

  /**
   * @dev Actually perform the safeTransferFrom.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);

    // isContract is function from address-utils.sol
    if (_to.isContract()) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  /**
   * @dev Clears the current approval of a given NFT ID.
   * @param _tokenId ID of the NFT to be transferred.
   */
  function _clearApproval(uint256 _tokenId) private {
    if (idToApproval[_tokenId] != address(0)) {
      delete idToApproval[_tokenId];
    }
  }
  
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
  function withdraw() public onlyOwner {
    payable(owner).transfer(address(this).balance);
  }
  
    /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they maybe be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(address _from, address _to, uint256 _tokenId) external override canTransfer(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
  }
  
}