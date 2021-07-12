/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.5.0;


 

/**
Work in Progress
A decentralized exchange marketplace contract ERC721 tokens.
//https://github.com/larvalabs/cryptopunks/blob/master/contracts/CryptoPunksMarket.sol
Need to:
1) allow deposit of ERC721 token with safeTransferFrom
2) allow for on-chain 'bids' and 'asks' orders (making) against any ERC20 [token type and amt]
3) allow for on-chain taking of said orders
*/


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/*
PAYSPEC: Generic global invoicing contract


*/

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}






contract ECRecovery {
  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
      // Check the signature length
      if (signature.length != 65) {
          return (address(0));
      }

      // Divide the signature in r, s and v variables
      bytes32 r;
      bytes32 s;
      uint8 v;

      // ecrecover takes the signature parameters, and the only way to get them
      // currently is to use assembly.
      // solhint-disable-next-line no-inline-assembly
      assembly {
          r := mload(add(signature, 0x20))
          s := mload(add(signature, 0x40))
          v := byte(0, mload(add(signature, 0x60)))
      }

      // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
      // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
      // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
      // signatures from current libraries generate a unique signature with an s-value in the lower half order.
      //
      // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
      // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
      // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
      // these malleable signatures as well.
      if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
          return address(0);
      }

      if (v != 27 && v != 28) {
          return address(0);
      }

      // If the signature is valid (and not malleable), return the signer address
      return ecrecover(hash, v, r, s);
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
      // 32 is the length in bytes of hash,
      // enforced by the type signature above
      return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

}




/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd
interface iERC721 /* is ERC165 */ {
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






contract ERC721Receiver {

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public returns(bytes4);
}

contract OpenNFTExchange is ERC721Receiver,ECRecovery {

    using SafeMath for uint;


    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;



    struct Offer {
        bool isForSale;

        address nfTokenContract;
        uint nfTokenId;

        address sellerAddress;

        address currencyTokenContract;
        uint currencyTokenAmount;          // in the currency

        address onlySellTo;     // specify to sell only to a specific person
    }

    //offchain bids, use the code from lavawallet to handle Personalsign
    struct OffchainBid {

        address bidderAddress;

        address nfTokenContract;
        uint nfTokenId;

        address currencyTokenContract;
        uint currencyTokenAmount;

        uint expires; //block number to expire at

    //    bytes bidderSignature;
    }


   struct EIP712Domain {
      string name;
      string version;
      uint256 chainId;
      address verifyingContract;
      bytes32 salt;
   }

   EIP712Domain public domainData;

   bytes32 constant eip712salt = 0xb493912f33b564e014c6a3db21cef37bf544e13a7fcebd19e348216d05a0d0bc;


    mapping (address => mapping (uint => address)) public nfTokensInEscrow;  //itemsInEscrow[nftAddress][indexOfToken] => ownerAddress


    mapping (address => mapping (uint => Offer)) public nfTokensOfferedForSale;   //itemsOfferedForSale[nftAddress][indexOfToken] => Offer


  event NewOffer(address nfTokenContract, uint nfTokenId, address currencyTokenContract, uint currencyTokenAmount);

  //event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
  event Deposit(address nfTokenContract, uint nfTokenId);
  event Withdraw(address nfTokenContract, uint nfTokenId);

  event CancelOffer(address nfTokenContract, uint nfTokenId);
  event Trade(address nfTokenContract, uint nfTokenId, address currencyTokenContract, uint currencyTokenAmount, address newOwner);

  constructor() public {

    domainData = EIP712Domain({
        name: "Only721",
        version: "1",
        chainId: 1,
        verifyingContract: address(this),
        salt: eip712salt
    });


  }

  //Do not allow Currency to enter
  function() external payable {
    revert();
  }


  //return bytes4(keccak256("onERC721Received(address,address,uint256,bytes"));

  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public returns (bytes4)
  {
    return _ERC721_RECEIVED;
  }

  //deposit an NFT token into the exchange's escrow - requires an Approve first
  function depositNFT(address _nfTokenContract, uint _nfTokenId) public returns (bool){
     address from = msg.sender;

     require(ownerOf(_nfTokenContract,_nfTokenId) == address(0), "NFT already deposited");

     iERC721(_nfTokenContract).safeTransferFrom(from, address(this),_nfTokenId );

     //record the owner of the deposited item
     nfTokensInEscrow[_nfTokenContract][_nfTokenId] = from;

   return true;
  }

  function withdrawNFT(address _nfTokenContract, uint _nfTokenId) public returns (bool){
      address from = msg.sender;

      require(ownerOf(_nfTokenContract,_nfTokenId) == from, "Not the owner");

      iERC721(_nfTokenContract).safeTransferFrom(address(this),from,_nfTokenId);

      nfTokensInEscrow[_nfTokenContract][_nfTokenId] = address(0);

    return true;
  }

  function ownerOf(address _nfTokenContract, uint _nfTokenId) public view returns (address) {
     return nfTokensInEscrow[_nfTokenContract][_nfTokenId];
  }

  function offerAssetForSale(address _nfTokenContract, uint _nfTokenId, address _currencyTokenContract, uint _currencyTokenAmount  ) public returns (bool)
  {
    address from = msg.sender;

    require(ownerOf(_nfTokenContract,_nfTokenId) == from, "Not the owner");


    nfTokensOfferedForSale[_nfTokenContract][_nfTokenId] = Offer({
       isForSale: true,

       nfTokenContract: _nfTokenContract,
       nfTokenId: _nfTokenId,

       sellerAddress: from,

       currencyTokenContract: _currencyTokenContract,
       currencyTokenAmount: _currencyTokenAmount,

       onlySellTo: address(0) //sell to anyone
      });

      emit NewOffer( _nfTokenContract, _nfTokenId, _currencyTokenContract, _currencyTokenAmount );

    return true;
  }



  function cancelSaleOfferOnAsset( address _nfTokenContract, uint _nfTokenId ) public returns (bool) {

    address from = msg.sender;

    require(ownerOf(_nfTokenContract,_nfTokenId) == from, "Not the owner");

    require(_cancelSaleOfferOnAsset(_nfTokenContract,_nfTokenId));

    emit CancelOffer(_nfTokenContract,_nfTokenId);

    return true;
  }


  //requires pre-approval of the currencyToken specified in the offer
  function buyoutAsset(address _nfTokenContract, uint _nfTokenId,address currencyTokenContract,uint currencyTokenAmount) public returns (bool)
  {
    address buyer = msg.sender;

    Offer memory saleOffer = nfTokensOfferedForSale[_nfTokenContract][_nfTokenId];

    require(saleOffer.isForSale, "Not for sale");

    address onlySellTo = saleOffer.onlySellTo;
    require(onlySellTo == address(0) || onlySellTo == buyer, 'Not onlySellTo');


    require(saleOffer.currencyTokenContract == currencyTokenContract, "Incorrect currencyToken");
    require(saleOffer.currencyTokenAmount == currencyTokenAmount, "Incorrect currencyAmount");

    address seller = saleOffer.sellerAddress;

    address currencyToken = saleOffer.currencyTokenContract;
    //uint currencyTokenAmount = saleOffer.currencyTokenAmount;


    require(_handlePaymentForSaleOfNfToken(
      _nfTokenContract,
      _nfTokenId,
      buyer,
      saleOffer.sellerAddress,
      saleOffer.currencyTokenContract,
      saleOffer.currencyTokenAmount), 'Payment failed');

    //thsi is the issue
    require(_cancelSaleOfferOnAsset(_nfTokenContract, _nfTokenId));

    //reassign the owner of the asset
    nfTokensInEscrow[_nfTokenContract][_nfTokenId] = buyer;

    emit Trade(_nfTokenContract, _nfTokenId, saleOffer.currencyTokenContract , saleOffer.currencyTokenAmount, buyer);

    return true;
  }



  function _cancelSaleOfferOnAsset(address _nfTokenContract, uint _nfTokenId) private returns (bool)
  {

    address seller = nfTokensOfferedForSale[_nfTokenContract][_nfTokenId].sellerAddress;

    nfTokensOfferedForSale[_nfTokenContract][_nfTokenId] = Offer({
      isForSale: false,

      nfTokenContract: _nfTokenContract,
      nfTokenId: _nfTokenId,

      sellerAddress: seller,

      currencyTokenContract: address(0),
      currencyTokenAmount: 0,

      onlySellTo: address(0) //sell to anyone

      })  ;

    return true;
  }

  function _handlePaymentForSaleOfNfToken(address _nfTokenContract,uint _nfTokenId,address buyer, address seller, address currencyTokenContract, uint currencyTokenAmount) private returns (bool)
  {

    //pull the currency tokens into this contract and then send them to the seller
    require( ERC20Interface(currencyTokenContract).transferFrom(buyer,seller,currencyTokenAmount), 'Could not transferFrom the currencyToken' );

    return true;
  }


  bytes sig;



 



  //bids will be offchain and fed into the contract by the owner
  function acceptOffchainBidWithSignature(address _bidderAddress, address _nfTokenContract, uint _nfTokenId, address _currencyTokenContract, uint _currencyTokenAmount,  uint _expires, bytes memory buyerSignature  ) public returns (bool)
  { 
      OffchainBid memory bid = OffchainBid({
         bidderAddress: _bidderAddress,

         nfTokenContract: _nfTokenContract,
         nfTokenId: _nfTokenId,

         currencyTokenContract: _currencyTokenContract,
         currencyTokenAmount: _currencyTokenAmount,

         expires: _expires
          
          
      });
      
      
    address _nfTokenContract = bid.nfTokenContract;
    uint _nfTokenId = bid.nfTokenId;

    address from = msg.sender;
    require(ownerOf(_nfTokenContract,_nfTokenId) == from, "Not the owner");

    bytes32 sigHash = getBidTypedDataHash( _bidderAddress, _nfTokenContract, _nfTokenId,  _currencyTokenContract, _currencyTokenAmount, _expires );

    sig = buyerSignature;

    //check the signature of the offchain bid here ...
    address recoveredSignatureSigner = recover(sigHash, sig );
    require(bid.bidderAddress == recoveredSignatureSigner, 'Offchain signature invalid');

    require(_handlePaymentForSaleOfNfToken(_nfTokenContract,_nfTokenId,bid.bidderAddress, from, bid.currencyTokenContract, bid.currencyTokenAmount), 'Payment failed');

    require(_cancelSaleOfferOnAsset(_nfTokenContract, _nfTokenId));

    //reassign the owner of the asset
    nfTokensInEscrow[_nfTokenContract][_nfTokenId] = bid.bidderAddress;

  //  emit Trade(_nfTokenContract, _nfTokenId, bid.currencyTokenContract , bid.currencyTokenAmount, bid.bidderAddress);

    return true;
  }


  function getBidTypedDataHash(address _bidderAddress, address _nfTokenContract, uint _nfTokenId, address _currencyTokenContract, uint _currencyTokenAmount,  uint _expires) public view returns (bytes32)
  {

          // Note: we need to use `encodePacked` here instead of `encode`.
          bytes32 digest = keccak256(abi.encodePacked(
              "\x19\x01",
              getDomainHash(),
              getBidPacketHash(_bidderAddress,_nfTokenContract,_nfTokenId,_currencyTokenContract,_currencyTokenAmount,_expires)
          ));
          return digest;

  }


  //make sure this has no extra spaces
   bytes32 public EIP712DOMAIN_TYPEHASH = keccak256(
       "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
   );

  //make sure this has no extra spaces
   bytes32 public BIDPACKET_TYPEHASH = keccak256(
       "OffchainBid(address bidderAddress,address nfTokenContract,uint256 nfTokenId,address currencyTokenContract,uint256 currencyTokenAmount,uint256 expires)"
   );



     function getDomainHash()  public view returns (bytes32) {
           return keccak256(abi.encode(
               EIP712DOMAIN_TYPEHASH,
               keccak256(bytes(domainData.name)),
               keccak256(bytes(domainData.version)),
               domainData.chainId,
               domainData.verifyingContract,
               domainData.salt
           ));
       }



    function getBidPacketHash(address _bidderAddress, address _nfTokenContract, uint _nfTokenId, address _currencyTokenContract, uint _currencyTokenAmount,  uint _expires) public view returns (bytes32) {
        return keccak256(abi.encode(
            BIDPACKET_TYPEHASH,
            _bidderAddress,
            _nfTokenContract,
            _nfTokenId,
            _currencyTokenContract,
            _currencyTokenAmount,
            _expires
        ));
    }






}