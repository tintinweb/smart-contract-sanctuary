import "./Ownable.sol";
import "./KittyMarketPlace.sol";

pragma solidity ^0.5.0;

contract KittyCore is Ownable, KittyMarketPlace {

  uint256 public constant CREATION_LIMIT_GEN0 = 10;

  // Counts the number of cats the contract owner has created.
  uint256 public gen0Counter;

  constructor() public {
    // We are creating the first kitty at index 0  
    _createKitty(0, 0, 0, uint256(-1), address(0));
  }

/*
*       we get a 
*
*       Basic binary operation
*
*       >>> '{0:08b}'.format(255 & 1)
*       '00000001'
*       >>> '{0:08b}'.format(255 & 2)
*       '00000010'
*       >>> '{0:08b}'.format(255 & 4)
*       '00000100'
*       >>> '{0:08b}'.format(255 & 8)
*       '00001000'
*       >>> '{0:08b}'.format(255 & 16)
*       '00010000'
*       >>> '{0:08b}'.format(255 & 32)
*       '00100000'
*       >>> '{0:08b}'.format(255 & 64)
*       '01000000'
*       >>> '{0:08b}'.format(255 & 128)
*       '10000000'
*
*       So we use a mask on our random number to check if we will use the mumID or the dadId
*
*       For example 205 is 11001101 in binary So
*       mum - mum - dad -dad -mum - mum - dad - mum
*
*/
  function Breeding(uint256 _dadId, uint256 _mumId) public {
      require(_owns(msg.sender, _dadId), "The user doesn't own the token");
      require(_owns(msg.sender, _mumId), "The user doesn't own the token");

      require(_mumId != _dadId, "The cat can't reproduce himself");

      ( uint256 Dadgenes,,,,uint256 DadGeneration ) = getKitty(_dadId);

      ( uint256 Mumgenes,,,,uint256 MumGeneration ) = getKitty(_mumId);

      uint256 geneKid;
      uint256 [8] memory geneArray;
      uint256 index = 7;
      uint8 random = uint8(now % 255);
      uint256 i = 0;
      
      for(i = 1; i <= 128; i=i*2){

          /* We are */
          if(random & i != 0){
              geneArray[index] = uint8(Mumgenes % 100);
          } else {
              geneArray[index] = uint8(Dadgenes % 100);
          }
          Mumgenes /= 100;
          Dadgenes /= 100;
        index -= 1;
      }
     
      /* Add a random parameter in a random place */
      uint8 newGeneIndex =  random % 7;
      geneArray[newGeneIndex] = random % 99;

      /* We reverse the DNa in the right order */
      for (i = 0 ; i < 8; i++ ){
        geneKid += geneArray[i];
        if(i != 7){
            geneKid *= 100;
        }
      }

      uint256 kidGen = 0;
      if (DadGeneration < MumGeneration){
        kidGen = MumGeneration + 1;
        kidGen /= 2;
      } else if (DadGeneration > MumGeneration){
        kidGen = DadGeneration + 1;
        kidGen /= 2;
      } else{
        kidGen = MumGeneration + 1;
      }

      _createKitty(_mumId, _dadId, kidGen, geneKid, msg.sender);
  }


  function createKittyGen0(uint256 _genes) public onlyOwner {
    require(gen0Counter < CREATION_LIMIT_GEN0);

    gen0Counter++;

    // Gen0 have no owners they are own by the contract
    uint256 tokenId = _createKitty(0, 0, 0, _genes, msg.sender);
    setOffer(0.2 ether, tokenId);
  }

  function getKitty(uint256 _id)
    public
    view
    returns (
    uint256 genes,
    uint256 birthTime,
    uint256 mumId,
    uint256 dadId,
    uint256 generation
  ) {
    Kitty storage kitty = kitties[_id];

    require(kitty.birthTime > 0, "the kitty doesn't exist");

    birthTime = uint256(kitty.birthTime);
    mumId = uint256(kitty.mumId);
    dadId = uint256(kitty.dadId);
    generation = uint256(kitty.generation);
    genes = kitty.genes;
  }
}

pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public{
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

pragma solidity ^0.5.0;

import "./KittyFactory.sol";

contract KittyOwnership is KittyFactory{

  string public constant name = "IvanKitties";
  string public constant symbol = "CK";

  event Transfer(address from, address to, uint256 tokenId);
  event Approval(address owner, address approved, uint256 tokenId);

  /*
  *    We use the modulo of each function to set the interfaceId
  */
  bytes4 constant InterfaceSignature_ERC165 =
      bytes4(keccak256('supportsInterface(bytes4)'));

  bytes4 constant InterfaceSignature_ERC721 =
      bytes4(keccak256('name()')) ^
      bytes4(keccak256('symbol()')) ^
      bytes4(keccak256('totalSupply()')) ^
      bytes4(keccak256('balanceOf(address)')) ^
      bytes4(keccak256('ownerOf(uint256)')) ^
      bytes4(keccak256('approve(address,uint256)')) ^
      bytes4(keccak256('transfer(address,uint256)')) ^
      bytes4(keccak256('transferFrom(address,address,uint256)')) ^
      bytes4(keccak256('tokensOfOwner(address)')) ^
      bytes4(keccak256('tokenMetadata(uint256,string)'));

  function supportsInterface(bytes4 _interfaceID) external pure returns (bool)
  {
      return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
  }

  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return kittyIndexToOwner[_tokenId] == _claimant;
  }

  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return kittyIndexToApproved[_tokenId] == _claimant;
  }

  function _approve(uint256 _tokenId, address _approved) internal {
      kittyIndexToApproved[_tokenId] = _approved;
  }

  function _deleteApproval(uint256 _tokenId) internal {
      require(_owns(msg.sender, _tokenId));
      delete kittyIndexToApproved[_tokenId];
  }


  /*
  *   Function required by the erc 721 interface
  */

  function totalSupply() public view returns (uint) {
      return kitties.length - 1;
  }

  function balanceOf(address _owner) public view returns (uint256 count) {
      return ownershipTokenCount[_owner];
  }

  function ownerOf(uint256 _tokenId)
      external
      view
      returns (address owner)
  {
      owner = kittyIndexToOwner[_tokenId];

      require(owner != address(0));
  }

  function approve(
      address _to,
      uint256 _tokenId
  )
      public
  {
      require(_owns(msg.sender, _tokenId));

      _approve(_tokenId, _to);
      emit Approval(msg.sender, _to, _tokenId);
  }

  function transfer(
      address _to,
      uint256 _tokenId
  )
      public
  {
      require(_to != address(0));
      require(_owns(msg.sender, _tokenId));

      _transfer(msg.sender, _to, _tokenId);
  }

  function transferFrom(
      address _from,
      address _to,
      uint256 _tokenId
  )
      public
  {
      require(_to != address(0));
      require(_approvedFor(msg.sender, _tokenId));
      require(_owns(_from, _tokenId));

      _transfer(_from, _to, _tokenId);
  }

  function tokensOfOwner(address _owner) public view returns(uint256[] memory ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
        return new uint256[](0);
    } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 totalCats = totalSupply();
        uint256 resultIndex = 0;

        uint256 catId;

        for (catId = 1; catId <= totalCats; catId++) {
            if (kittyIndexToOwner[catId] == _owner) {
                result[resultIndex] = catId;
                resultIndex++;
            }
        }

        return result;
    }
  }
}

import "./KittyOwnership.sol";

pragma solidity ^0.5.0;

contract KittyMarketPlace is KittyOwnership {

  struct Offer {
    address payable seller;
    uint256 price;
    uint256 tokenId;
  }

  Offer[] offers;

  mapping (uint256 => Offer) tokenIdToOffer;
  mapping (uint256 => uint256) tokenIdToOfferId;


  event MarketTransaction(string TxType, address owner, uint256 tokenId);

  function getOffer(uint256 _tokenId)
      public
      view
      returns
  (
      address seller,
      uint256 price,
      uint256 tokenId

  ) {
      Offer storage offer = tokenIdToOffer[_tokenId];
      return (
          offer.seller,
          offer.price,
          offer.tokenId
      );
  }


  function getAllTokenOnSale() public  returns(uint256[] memory listOfToken){
    uint256 totalOffers = offers.length;
    
    if (totalOffers == 0) {
        return new uint256[](0);
    } else {
  
      uint256[] memory resultOfToken = new uint256[](totalOffers);

      uint256 offerId;
  
      for (offerId = 0; offerId < totalOffers; offerId++) {
        if(offers[offerId].price != 0){
          resultOfToken[offerId] = offers[offerId].tokenId;
        }
      }
      return resultOfToken;
    }
  }

  function setOffer(uint256 _price, uint256 _tokenId)
    public
  {
    /*
    *   We give the contract the ability to transfer kitties
    *   As the kitties will be in the market place we need to be able to transfert them
    *   We are checking if the user is owning the kitty inside the approve function
    */
    require(_price > 0.009 ether, "Cat price should be greater than 0.01");
    require(tokenIdToOffer[_tokenId].price == 0, "You can't sell twice the same offers ");

    approve(address(this), _tokenId);

    Offer memory _offer = Offer({
      seller: msg.sender,
      price: _price,
      tokenId: _tokenId
    });

    tokenIdToOffer[_tokenId] = _offer;

    uint256 index = offers.push(_offer) - 1;

    tokenIdToOfferId[_tokenId] = index;

    emit MarketTransaction("Create offer", msg.sender, _tokenId);
  }

  function removeOffer(uint256 _tokenId)
    public
  {
    require(_owns(msg.sender, _tokenId), "The user doesn't own the token");

    Offer memory offer = tokenIdToOffer[_tokenId];

    require(offer.seller == msg.sender, "You should own the kitty to be able to remove this offer");

    /* we delete the offer info */
    delete offers[tokenIdToOfferId[_tokenId]];

    /* Remove the offer in the mapping*/
    delete tokenIdToOffer[_tokenId];


    _deleteApproval(_tokenId);

    emit MarketTransaction("Remove offer", msg.sender, _tokenId);
  }

  function buyKitty(uint256 _tokenId)
    public
    payable
  {
    Offer memory offer = tokenIdToOffer[_tokenId];
    require(msg.value == offer.price, "The price is not correct");

    /* we delete the offer info */
    delete offers[tokenIdToOfferId[_tokenId]];

    /* Remove the offer in the mapping*/
    delete tokenIdToOffer[_tokenId];

    /* TMP REMOVE THIS*/
    _approve(_tokenId, msg.sender);


    transferFrom(offer.seller, msg.sender, _tokenId);

    offer.seller.transfer(msg.value);
    emit MarketTransaction("Buy", msg.sender, _tokenId);
  }
}

pragma solidity ^0.5.0;

contract KittyFactory {

  /*
  *   A new cat is born
  */
  event Birth(address owner, uint256 kittyId, uint256 mumId, uint256 dadId, uint256 genes);

  /*
  *   A cat has been transfer
  */
  event Transfer(address from, address to, uint256 tokenId);

  /*
  *   Here we will use the same structure as the original crypto kitties game
  *   As it fit exactly into two bit words
  */
  struct Kitty {

      uint256 genes;
      uint64 birthTime;
      uint32 mumId;
      uint32 dadId;
      uint16 generation;
  }

  Kitty[] kitties;

  mapping (uint256 => address) public kittyIndexToOwner;
  mapping (address => uint256) ownershipTokenCount;

  // Add a list of approved kitties, that are allowed to be transfered
  mapping (uint256 => address) public kittyIndexToApproved;

  function _createKitty(
      uint256 _mumId,
      uint256 _dadId,
      uint256 _generation,
      uint256 _genes,
      address _owner
  )
      internal
      returns (uint)
  {

    Kitty memory _kitty = Kitty({
        genes: _genes,
        birthTime: uint64(now),
        mumId: uint32(_mumId),
        dadId: uint32(_dadId),
        generation: uint16(_generation)
    });

    uint256 newKittenId = kitties.push(_kitty) - 1;

    // It's probably never going to happen, 4 billion cats is A LOT, but
    // let's just be 100% sure we never let this happen.
    require(newKittenId == uint256(uint32(newKittenId)));

    // emit the birth event
    emit Birth(
        _owner,
        newKittenId,
        uint256(_kitty.mumId),
        uint256(_kitty.dadId),
        _kitty.genes
    );

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newKittenId);
    return newKittenId;
  }

  function _transfer(address _from, address _to, uint256 _tokenId) internal {

    // Since the number of kittens is capped to 2^32 we can't overflow this
    ownershipTokenCount[_to]++;
    // transfer ownership
    kittyIndexToOwner[_tokenId] = _to;

    if (_from != address(0)) {
        ownershipTokenCount[_from]--;

        delete kittyIndexToApproved[_tokenId];
    }

    // Emit the transfer event.
    emit Transfer(_from, _to, _tokenId);
  }
}

