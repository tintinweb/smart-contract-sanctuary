pragma solidity ^0.5.0;

import "./ERC721Full.sol";

contract MarketSolar is ERC721Full {
  string public name;
  Image[] public nft;
  uint public imageId = 0;
  uint public userId = 0;
  mapping(uint => uint) public id;
  mapping(uint => bool) public _nftExists;
  mapping(uint => Image) public images;

  //Variables and struct to associate wallet address to a username
  mapping(address => uint) public usernames;
  addres2name[] public names;

  struct addres2name{
    address userAddress;
    string username;
  }

  //Struct of a NFT
  struct Image {
    uint id;                  //id of the nft
    string title;
    uint price;
    string hash;              //hash of the ipfs            
    string description;       //nft description
    string collection;        //what collection the nft bellongs
    address payable author;   //person that made the nft
    address payable owner;
  }

  struct Oferta {
    uint id;
    uint price;
    address owner;
    address payable buyer;
    uint256 idToken;
    bool pendent;
  }

  //Event used when new Token is created
  event TokenCreated(
    uint id,
    string title,
    uint price,
    string hash,
    string description,
    string collection,
    address payable author,
    address payable owner
  );

  event UsernameAddeed(
    address author,
    string name
  );

  event NftBought(
    address _seller, 
    address _buyer, 
    uint256 _price
  );


  constructor() public payable ERC721Full("SNSF", "SNSF") {
    name = "Solar System SNSF";
  }


  //function to update the usarnem and link it with it's wallet address
  function updateUsername(string memory _name) public {
    if(usernames[msg.sender] == 0){
      names.push(addres2name(msg.sender, _name));
      userId++;
      usernames[msg.sender] = userId;
    }
    else{
      uint _id = usernames[msg.sender] - 1;
      names[_id].username = _name;
    }
    emit UsernameAddeed(msg.sender, _name);
  }


  function allowBuy(uint256 _tokenId, uint256 _price) external {
    require(msg.sender == ownerOf(_tokenId), 'Not owner of this token');
    images[_tokenId].price = _price;
  }


  function buy(uint256 _tokenId) external payable {
    uint256 price = images[_tokenId].price;
    require(price > 0, 'This token is not for sale');
        
    address seller = ownerOf(_tokenId);
    _transferFrom(seller, msg.sender, _tokenId);
    images[_tokenId].price = 0;
    images[_tokenId].owner.transfer(msg.value);
    images[_tokenId].owner = msg.sender;

    emit NftBought(seller, msg.sender, msg.value);
  }


  //uploadImage to the blockchain and mint the nft.
  function uploadImage(string memory _title, uint _price, string memory _imgHash, string memory _description, string memory _collection) public {
    // Make sure the image hash exists
    require(bytes(_imgHash).length > 0);
    // Make sure image description exists
    require(bytes(_description).length > 0);
    // Make sure collectionage exists
    require(bytes(_collection).length > 0);
    // Make sure uploader address exists
    require(msg.sender!=address(0));

    // Increment image id
    imageId ++;

    // Add Image to the contract
    images[imageId] = Image(imageId, _title, _price, _imgHash, _description, _collection, msg.sender, msg.sender);

    //Mint the token
    require(!_nftExists[imageId]);
    uint _id = nft.push(images[imageId]);
    id[imageId] = _id;
    _mint(msg.sender, _id);
    _nftExists[imageId] = true;

    // Trigger an event
    emit TokenCreated(imageId, _title, _price, _imgHash, _description, _collection, msg.sender, msg.sender);
  }
} 

/*
  event Deposit(
    address indexed tipper,
    uint etherAmmount
  );
  event Withdraw(
    address indexed tipper,
    uint etherAmmount
  );
  event OfferSent(
    address indexed tipper,
    uint price
  );
  event OfferAccepted(
    address indexed tipper,
    uint etherAmmount
  );
  event OfferDeclined(
    address indexed tipper,
    uint etherAmmount
  );
  
  //Funció per depositar els diners d'un NFT.
  function deposit() payable public {
    //Afegim el diposit dins la cartera de dipòsits.
    etherBalanceOf[msg.sender] = etherBalanceOf[msg.sender] + msg.value;
    emit Deposit(msg.sender, msg.value);
  }
  //Funció per recuperars els diners dipositats en una oferta per un NFT.
  function withdraw(uint _price) payable public {
    //Per l'event. Referencia al preu del nft.
    uint userBalance = etherBalanceOf[msg.sender];
    //Retorno calers a la cartera personal
    msg.sender.transfer(etherBalanceOf[msg.sender]);
    //Balanç de la cartera de dipòsits del comprador queda ajustada.
    etherBalanceOf[msg.sender] = etherBalanceOf[msg.sender] - _price;
    emit Withdraw(msg.sender, userBalance);
  }
  //Funció que crida el propietari del NFT per acceptar l'oferta que li han fet per un NFT.
  function acceptOffer(uint _id) payable public {
    Oferta memory _ofertaFinal = ofertes[_id];
    //Per l'event, representa el preu del nft.
    uint userBalance = etherBalanceOf[msg.sender];
    //envia els diners de la cartera del venedor
    msg.sender.transfer(_ofertaFinal.price);
    //approve(_ofertaFinal.buyer, _ofertaFinal.idToken);    
    _transferFrom(_ofertaFinal.owner, _ofertaFinal.buyer, _ofertaFinal.idToken);
    //Balanç de la cartera de dipòsits queda ajustada.
    etherBalanceOf[_ofertaFinal.buyer] = etherBalanceOf[_ofertaFinal.buyer] - _ofertaFinal.price;
    //Desactivem l'oferta
    ofertes[_id].pendent = false;
    emit OfferAccepted(msg.sender, userBalance);
  }
  //Funció per declinar l'oferta i retornar els diners al comprador
  function declineOffer(uint _id) payable public{
    Oferta memory _ofertaFinal = ofertes[_id];
    //Per l'event, representa el preu del nft.
    uint userBalance = etherBalanceOf[msg.sender];
    //Retorna els diners a la conta del comprador i ajusta el seu balanç.
    withdraw(_ofertaFinal.price);
    //Desactivem l'oferta
    ofertes[_id].pendent = false;
    emit OfferDeclined(msg.sender, userBalance);
  }
  function sendOffer(uint _id) public payable{
    Image memory _img = images[_id];
    ofertaId++;
    //Classifiquem les ofertes en funció de l'obra.
    ofertes.push(Oferta(ofertaId, _img.price, ownerOf(_id), msg.sender, _id, true));
    //Fem el dipòsit dels diners per el NFT. 
    deposit();
    emit OfferSent(msg.sender, msg.value);
  }
*/