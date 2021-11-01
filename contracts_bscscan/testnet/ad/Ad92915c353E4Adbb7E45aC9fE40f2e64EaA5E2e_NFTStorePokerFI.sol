// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";

/*
  ____    _                    _        _       _   _           
 / ___|  | |_    __ _    ___  | | __   | |     (_) | |__    ___ 
 \___ \  | __|  / _` |  / __| | |/ /   | |     | | | '_ \  / __|
  ___) | | |_  | (_| | | (__  |   <    | |___  | | | |_) | \__ \
 |____/   \__|  \__,_|  \___| |_|\_\   |_____| |_| |_.__/  |___/
*/

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Ownable is Context {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor ()  {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


/*
  ____            _                    _____   _     _   _   _____   _____ 
 |  _ \    ___   | | __   ___   _ __  |  ___| (_)   | \ | | |  ___| |_   _|
 | |_) |  / _ \  | |/ /  / _ \ | '__| | |_    | |   |  \| | | |_      | |  
 |  __/  | (_) | |   <  |  __/ | |    |  _|   | |   | |\  | |  _|     | |  
 |_|      \___/  |_|\_\  \___| |_|    |_|     |_|   |_| \_| |_|       |_|  
*/

contract NFTPokerFI is ERC721URIStorage, Ownable {
    
  //globals
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  address contractAddress;

  //O contstructor leva um argumento para o endereço, economizando o valor e disponibilizando-o no contrato inteligente. 
  //Dessa forma, quando alguém liga, o contrato pode permitir que a aprovação do contrato do MarketPlace transfira o token 
  //do proprietário para o vendedor"loja"  .marketplaceAddresscreateToken


  constructor(address marketplaceAddress) ERC721("NFT Player PokerFI", "NFTPokerFI") {
    contractAddress = marketplaceAddress;
  }

      function createToken(string memory tokenURI, uint256 itemCount) public onlyOwner returns (uint256[] memory) {
      require( _owner == msg.sender,"security guaranteed administrator only");
      if (itemCount == 0) {itemCount =1;}
      uint256 newItemId;
      uint currentIndex = 0;

      uint256[] memory items = new uint[](itemCount);      

        for (uint i = 0; i < itemCount; i++) {
            _tokenIds.increment();
             newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId);
            _setTokenURI(newItemId, tokenURI);
            setApprovalForAll(contractAddress, true);

            items[currentIndex] = newItemId;
            currentIndex += 1;
        }    
       //O valor é devolvido da função, pois estaremos precisando dele em nosso aplicativo de cliente 
       //para saber o valor dinâmico do que foi gerado pelo contrato [[array com os ids , 1, 2, 3, 4, 5, 6, 7,]] inteligente.newItemIdtokenId
      return items;
      }


      function myNfts() public view returns (uint256[] memory) {

        uint totalItemCount = _tokenIds.current();
        uint currentIndex = 0;
        address checar;
        uint contagemPrev = 0;
        for (uint i = 0; i < totalItemCount; i++) {
        checar = ownerOf(i+1);
        if (checar == msg.sender) {
           contagemPrev +=1;
          }
        }

        uint256[] memory items = new uint[](contagemPrev);

        for (uint i = 0; i < totalItemCount; i++) {
          checar = ownerOf(i+1);
          if (checar == msg.sender) {
          items[currentIndex] = i+1;
          currentIndex += 1;
          }
        }
      return items;

      }



}

/*
  _   _   _____   _____     __  __                  _             _     ____    _                       
 | \ | | |  ___| |_   _|   |  \/  |   __ _   _ __  | | __   ___  | |_  |  _ \  | |   __ _    ___    ___ 
 |  \| | | |_      | |     | |\/| |  / _` | | '__| | |/ /  / _ \ | __| | |_) | | |  / _` |  / __|  / _ \
 | |\  | |  _|     | |     | |  | | | (_| | | |    |   <  |  __/ | |_  |  __/  | | | (_| | | (__  |  __/
 |_| \_| |_|       |_|     |_|  |_|  \__,_| |_|    |_|\_\  \___|  \__| |_|     |_|  \__,_|  \___|  \___|
 */


contract NFTStorePokerFI is ReentrancyGuard, Ownable {

  using SafeMath for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold;

  //A estrutura nos permite armazenar registros de itens que queremos disponibilizar no mercado.MarketItem
  struct MarketItem {
    uint itemId;
    address nftContract;
    uint256 tokenId;
    address payable seller;   
    address payable owner;
    uint256 price;
      uint behavior;              /*behavior/comportamnento (0)owner preco 6% taxa, (1)store preco 10% taxa (2)auction 6% (3))game 0% */
      uint256 auctionEndTime;     /*horario encerramento leilão*/
    address payable commis1;    /*1.5%*/
    address payable commis2;    /*1.5%*/    
    address payable commis3;    /*1%*/
    address payable commis4;    /*1%*/
    address payable commis5;    /*1%*/

  }

  //Esse mapeamento nos permite criar um emparelhamento de valor chave entre IDs e s.MarketItem  
  mapping(uint256 => MarketItem) private idToMarketItem;

  event MarketItemCreated (
    uint indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price
  );


  function getMarketItem(uint256 marketItemId) public view returns (MarketItem memory) {
      return idToMarketItem[marketItemId];
  }






  function createMarketItem( 
    uint256 itemCount, 
    address nftContract, 
    uint256 tokenId, 
    uint256 price,
    uint256 auctionEndTime,
    address commis1,    
    address commis2,    
    address commis3,    
    address commis4,    
    address commis5    
    ) public payable nonReentrant {
    
    require(price > 0, "Price must be at least 1 wei");

    /*identify where from token, and behavior 0 = adm, 1 = user, 2 = auction(auctionEndTime>0) */
    uint behavior;
    if ( _owner == msg.sender ) { behavior = 0; } else { behavior = 1; itemCount=1;}
    if (auctionEndTime > 0 ) {
    require( _owner == msg.sender,"security guaranteed administrator only");
    behavior = 2; 
    auctionEndTime = block.timestamp + (auctionEndTime * 1 hours);
    }

        for (uint i = 0; i < itemCount; i++) {

          _itemIds.increment();
          uint256 itemId = _itemIds.current();
        
          idToMarketItem[itemId] =  MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
              behavior,
              auctionEndTime,
            payable(commis1),
            payable(commis2),
            payable(commis3),
            payable(commis4),
            payable(commis5)
          );

          IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

          emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price
          );


          tokenId+=1;

        }
          
  }



  /*FUNCAO DE VENDA/COMPRA*/
  function createMarketSale(address nftContract, uint256 itemId) public payable nonReentrant {

    /*variaveis de escopo*/  
    uint price = idToMarketItem[itemId].price;
    uint tokenId = idToMarketItem[itemId].tokenId;
    address payable commis1 = idToMarketItem[itemId].commis1;    /*1.5 ou 9% @adm */
    address payable commis2 = idToMarketItem[itemId].commis2;    /*1.5 ou 1% @dev */
    address payable commis3 = idToMarketItem[itemId].commis3;    /*1*/
    address payable commis4 = idToMarketItem[itemId].commis4;    /*1*/
    address payable commis5 = idToMarketItem[itemId].commis5;    /*1*/

    require(msg.value == price, "Please submit the asking price in order to complete the purchase");

    /*taxa situacao 1%*/ 
    uint amount = msg.value;
    uint256 taxFee = amount;
    taxFee = taxFee.div(100);  /*get 1% */
    uint256 tax1;
    uint256 tax2;

    /*NFT game owner = taxa situacao 0 = 6%, 5 wallets, 1.5%, 1.5%, 1%, 1%, 1%*/
    if (idToMarketItem[itemId].behavior == 0) {
       taxFee = taxFee.div(2);  /*get 1% e div 2 = 0.5%*/
       tax1 = taxFee.mul(3);    /*1.5*/
       tax2 = taxFee.mul(2);    /*1*/
       amount = amount.sub(tax1).sub(tax1).sub(tax2).sub(tax2).sub(tax2); /*retirando as taxas total 6% */  
       /*BNBTransfers*/  
       idToMarketItem[itemId].seller.transfer(amount); 
       commis1.transfer(tax1);
       commis2.transfer(tax1);
       commis3.transfer(tax2);
       commis4.transfer(tax2);
       commis5.transfer(tax2);
    }

    /*NFT user seller*/
    if (idToMarketItem[itemId].behavior == 1) {
     tax1 = taxFee.mul(9);  /* 9% ADM */
     tax2 = taxFee;         /*.mul(1%) dev; /*1*/
     amount = amount.sub(tax1).sub(tax2); /*retirando as taxas total 6% */  
       
      /* BNB Transfers */  
       idToMarketItem[itemId].seller.transfer(amount);
       commis1.transfer(tax1);  
       commis2.transfer(tax2);
    }

    require(idToMarketItem[itemId].behavior == 1 || idToMarketItem[itemId].behavior == 0, "Only game's and user's NFT itens can to sell in this function");
    /*passando propriedade p comprador NFT */  
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    idToMarketItem[itemId].owner = payable(msg.sender);
    _itemsSold.increment();
  }






  function fetchMarketItem(uint itemId) public view returns (MarketItem memory) {
    MarketItem memory item = idToMarketItem[itemId];
    return item;
  }




  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].owner == address(0)) {
        uint currentId = idToMarketItem[i + 1].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
   
    return items;
  }




  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        uint currentId = idToMarketItem[i + 1].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
   
    return items;
  }
}