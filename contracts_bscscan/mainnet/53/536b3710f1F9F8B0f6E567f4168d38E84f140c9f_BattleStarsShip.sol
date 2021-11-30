// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./InitialValue.sol";

contract BattleStarsShip is Ownable, ERC721Enumerable, InitialValue {
  using SafeMath for uint256;
  using Address for address;
  using Strings for string;

  event NewBattleStarSuccess(
    uint256 id,
    address owner,
    string faction,
    string collection
  );

  // Constructor
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    price = initialPrice;
  }

  // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // generate random id
  function _randomId(
    uint256 _tokenId,
    address _owner
  ) internal view returns (uint256) {
    uint256 rand = uint256(keccak256(abi.encodePacked(_tokenId, _owner)));
    return rand % battlestarsModulus;
  }

  // Create Battle Stars by faction type
  function _createBattleStarsEndurance(
    uint256 _tokenId,
    address _owner
  ) internal {
    uint256 randId = _randomId(_tokenId, _owner);
    randId = randId - randId % 100;

    BattleStar memory newBattleStar = BattleStar(
      randId,
      _owner,
      "Endurance",
      "Origin"
    );
    BattleStars.push(newBattleStar);

    emit NewBattleStarSuccess(randId, _owner, factions[0], "Origin");
  }

  function _createBattleStarsJaeger(
    uint256 _tokenId,
    address _owner
  ) internal {
    uint256 randId = _randomId(_tokenId, _owner);
    randId = randId - randId % 100;

    BattleStar memory newBattleStar = BattleStar(
      randId,
      _owner,
      "Jaeger",
      "Origin"
    );
    BattleStars.push(newBattleStar);

    emit NewBattleStarSuccess(randId, _owner, factions[1], "Origin");
  }

  function _createBattleStarsPrometeus(
    uint256 _tokenId,
    address _owner
  ) internal {
    uint256 randId = _randomId(_tokenId, _owner);
    randId = randId - randId % 100;

    BattleStar memory newBattleStar = BattleStar(
      randId,
      _owner,
      "Prometeus",
      "Origin"
    );
    BattleStars.push(newBattleStar);

    emit NewBattleStarSuccess(randId, _owner, factions[2], "Origin");
  }


  // set shipsForSaleEndurance
  function setShipsForSaleEndurance(uint256 _shipsForSaleEndurance) public onlyOwner {
    shipsForSaleEndurance = _shipsForSaleEndurance;
  }

  // set shipsForSaleJaeger
  function setShipsForSaleJaeger(uint256 _shipsForSaleJaeger) public onlyOwner {
    shipsForSaleJaeger = _shipsForSaleJaeger;
  }

  // set shipsForSalePrometeus
  function setShipsForSalePrometeus(uint256 _shipsForSalePrometeus) public onlyOwner {
    shipsForSalePrometeus = _shipsForSalePrometeus;
  }

  // Set new baseURI
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  // Set new baseExtension
  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  // Set new notRevealedUri
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  // Set new price
  function setPrice(uint256 _newPrice) public onlyOwner {
    require(_newPrice > 0, "Price must be greater than 0");
    price = _newPrice;
  }

  // Set sale active
  function setSaleActive(bool _newSaleActive) public onlyOwner {
    saleActive = _newSaleActive;
  }

  // set ship Endurance Out Of Stock
  function setShipEnduranceOutOfStock(bool _shipEnduranceOutOfStock) public onlyOwner {
    shipEnduranceOutOfStock = _shipEnduranceOutOfStock;
  }

  // set ship Jaeger Out Of Stock
  function setShipJaegerOutOfStock(bool _shipJaegerOutOfStock) public onlyOwner {
    shipJaegerOutOfStock = _shipJaegerOutOfStock;
  }

  // set ship Prometeus Out Of Stock
  function setShipPrometeusOutOfStock(bool _shipPrometeusOutOfStock) public onlyOwner {
    shipPrometeusOutOfStock = _shipPrometeusOutOfStock;
  }

  // Set only whitelisted
  function setOnlyWhitelisted(bool _newOnlyWhitelisted) public onlyOwner {
    onlyWhitelisted = _newOnlyWhitelisted;
  }

  // Set total Amount Of Supplies
  function setTotalAmountOfSupplies(uint256 _newTotalAmountOfSupplies) public onlyOwner {
    require(_newTotalAmountOfSupplies > 0, "Total amount of supplies must be greater than 0");
    totalAmountOfSupplies = _newTotalAmountOfSupplies;
  }

  // Set max mint amount per transaction
  function setMaxMintAmountPerTransaction(uint256 _newMaxMintAmountPerTransaction)
    public
    onlyOwner
  {
    maxMintAmountPerTransaction = _newMaxMintAmountPerTransaction;
  }

  // Set ntf per address limit
  function setNtfPerAddressLimit(uint256 _newNtfPerAddressLimit) public onlyOwner {
    ntfPerAddressLimit = _newNtfPerAddressLimit;
  }

  // get BattleStars length
  function getBattleStarsLength() public onlyOwner view returns (uint256) {
    return BattleStars.length;
  }

  // BattleStars id to BattleStar
  function getBattleStarId(uint256 _tokenId) public onlyOwner view returns (BattleStar memory) {
    return BattleStars[_tokenId];
  }

  // See which address owns which BattleStars
  function battlestarsOfOwner(address _owner) public view onlyOwner returns (uint256[] memory) {
    uint256 ownerBattleStarsCount = balanceOf(_owner);
    uint256[] memory battlestarsOwner = new uint256[](ownerBattleStarsCount);
    for (uint256 i = 0; i < ownerBattleStarsCount; i++) {
      battlestarsOwner[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return battlestarsOwner;
  }

  // safe Transfer From ship to new owner and balance of new owner
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override onlyOwner {
    require(msg.sender == _from, "Sender is not the owner of the ship");
    require(_to != address(0), "Receiver is the zero address");
    require(BattleStars[_tokenId].owner == _from, "Sender is not the owner of the ship");
    // transfer ownership
    BattleStars[_tokenId].owner = _to;
    battlestarsToOwner[_tokenId] = _to;
    addressMintedBalanceBattleStars[_to] = addressMintedBalanceBattleStars[_to].add(1);
    addressMintedBalanceBattleStars[_from] = addressMintedBalanceBattleStars[_from].sub(1);
    emit Transfer(_from, _to, _tokenId);
  }

  // get count ship Endurance
  function getCountShipEndurance() public onlyOwner view returns (uint256) {
    return countShipEndurance;
  }

  // get count ship Jaeger
  function getCountShipJaeger() public onlyOwner view returns (uint256) {
    return countShipJaeger;
  }

  // get count ship Prometeus
  function getCountShipPrometeus() public onlyOwner view returns (uint256) {
    return countShipPrometeus;
  }

  // token URI
  function tokenURI(uint256 _tokenId) public onlyOwner view virtual override returns (string memory) {
    require(_exists(_tokenId), "URI query for nonexistent token");

    if (revealedUri == false) {
      return notRevealedUri;
    }

    string memory _currentBaseUri = _baseURI();
    string memory _currentBaseExtension = baseExtension;

    return
      bytes(_currentBaseUri).length > 0
        ? string(abi.encodePacked(_currentBaseUri, _tokenId, _currentBaseExtension))
        : "";
  }

  // Reveal the URI
  function revealURI() public onlyOwner {
    require(saleActive == true, "Cannot reveal URI before the sale has started");
    revealedUri = true;
  }

  // white list a new address
  function whitelistAddress(address _newAddress) public onlyOwner {
    require(onlyWhitelisted == true, "Only whitelisted addresses can be whitelisted");
    require(_newAddress != address(0), "Cannot whitelist the null address");
    require(
      whitelistedAddresses.length < totalAmountOfSupplies,
      "Cannot whitelist more than addresses"
    );
    whitelistedAddresses.push(_newAddress);
  }


  // is white listed
  function isWhitelisted(address _addressUser) public view returns (bool) {
    require(onlyWhitelisted == true, "Only whitelisted addresses can be whitelisted");
    for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _addressUser) {
        return true;
      }
    }
    return false;
  }
  // Admin minting function to reserve tokens for the team, collabs, customs and giveaways
  function mintBattleStarsShipEnduranceReserved(address _addressTeam1, uint256 _mintAmount) public onlyOwner {

    require(onlyWhitelisted == true, "Only whitelisted addresses can mint");
    require(_mintAmount > 0, "Cannot mint 0 BattleStars");
    require( _mintAmount <= reserved, "Can't reserve more than set amount" );
    reserved -= _mintAmount;
    uint256 totalSupply = totalSupply();

    // 30% of the Battle Stars are for the team
    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint256 newBattleStarId = totalSupply + i;
      addressMintedBalanceBattleStars[_addressTeam1]++;
      battlestarsToOwner[newBattleStarId] = _addressTeam1;
      _createBattleStarsEndurance(newBattleStarId, _addressTeam1);
      countShipEndurance++;
      _safeMint(_addressTeam1, newBattleStarId);
    }
  }

  // Admin minting function to reserve tokens for the team, collabs, customs and giveaways
  function mintBattleStarsShipJaegerReserved(address _addressTeam2, uint256 _mintAmount) public onlyOwner {

    require(onlyWhitelisted == true, "Only whitelisted addresses can mint");
    require(_mintAmount > 0, "Cannot mint 0 BattleStars");
    require( _mintAmount <= reserved, "Can't reserve more than set amount" );
    reserved -= _mintAmount;
    uint256 totalSupply = totalSupply();


    // 40% of the Battle Stars are for the team
    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint256 newBattleStarId = totalSupply + i;
      addressMintedBalanceBattleStars[_addressTeam2]++;
      battlestarsToOwner[newBattleStarId] = _addressTeam2;
      _createBattleStarsJaeger(newBattleStarId, _addressTeam2);
      countShipJaeger++;
      _safeMint(_addressTeam2, newBattleStarId);
    }

  }

  // Admin minting function to reserve tokens for the team, collabs, customs and giveaways
  function mintBattleStarsShipPrometeusReserved(address _addressTeam3, uint256 _mintAmount) public onlyOwner {

    require(onlyWhitelisted == true, "Only whitelisted addresses can mint");
    require(_mintAmount > 0, "Cannot mint 0 BattleStars");
    require( _mintAmount <= reserved, "Can't reserve more than set amount" );
    reserved -= _mintAmount;
    uint256 totalSupply = totalSupply();

    // 30% of the Battle Stars are for the team
    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint256 newBattleStarId = totalSupply + i;
      addressMintedBalanceBattleStars[_addressTeam3]++;
      battlestarsToOwner[newBattleStarId] = _addressTeam3;
      _createBattleStarsPrometeus(newBattleStarId, _addressTeam3);
      countShipPrometeus++;
      _safeMint(_addressTeam3, newBattleStarId);
    }

  }

  // minting battle stars payed for by the owner
  function mintBattleStarsShipEndurance(uint256 _mintAmount) public payable {
    require(saleActive == true, "Cannot mint tokens before the sale has started");
    require(shipEnduranceOutOfStock == false, "Ship endurance is out of stock");
    uint256 totalSupply = totalSupply();

    require(
      countShipEndurance <= shipsForSaleEndurance,
      "Cannot mint more than the ships Endurance for sale"
    );

    require(
      countShipEndurance + _mintAmount <= shipsForSaleEndurance,
      "Cannot mint more Endurance than the total amount of supplies"
    );

    require(
      _mintAmount <= maxMintAmountPerTransaction,
      string(
        abi.encodePacked(
          "Cannot mint more than ",
          maxMintAmountPerTransaction,
          " battle stars per max mint amount per transaction"
        )
      )
    );

    require(
      addressMintedBalanceBattleStars[msg.sender] + _mintAmount <= ntfPerAddressLimit,
      string(
        abi.encodePacked(
          "Cannot mint more than ",
          ntfPerAddressLimit,
          " battle stars per ntf per address limit"
        )
      )
    );

    if (msg.sender != owner()) {
      require(
        msg.value >= price * _mintAmount,
        "Cannot mint more than the price of the battle stars"
      );
    }

    if (countShipEndurance + _mintAmount == shipsForSaleEndurance) {
      shipEnduranceOutOfStock = true;
    }

    // Mint Battle Stars
    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint256 newBattleStarId = totalSupply + i;
      addressMintedBalanceBattleStars[msg.sender]++;
      battlestarsToOwner[newBattleStarId] = msg.sender;
      _createBattleStarsEndurance(newBattleStarId, msg.sender);
      countShipEndurance++;
      _safeMint(msg.sender, newBattleStarId);
    }
  }

  function mintBattleStarsShipJaeger(uint256 _mintAmount) public payable {
    require(saleActive == true, "Cannot mint tokens before the sale has started");
    require(shipJaegerOutOfStock == false, "Ship Jaeger is out of stock");
    uint256 totalSupply = totalSupply();

    require(
      countShipJaeger <= shipsForSaleJaeger,
      "Cannot mint more than the ships Jaeger for sale"
    );

    require(
      countShipJaeger + _mintAmount <= shipsForSaleJaeger,
      "Cannot mint more Jaeger than the total amount of supplies"
    );

    require(
      _mintAmount <= maxMintAmountPerTransaction,
      string(
        abi.encodePacked(
          "Cannot mint more than ",
          maxMintAmountPerTransaction,
          " battle stars per transaction"
        )
      )
    );

    require(
      addressMintedBalanceBattleStars[msg.sender] + _mintAmount <= ntfPerAddressLimit,
      string(
        abi.encodePacked(
          "Cannot mint more than ",
          ntfPerAddressLimit,
          " battle stars per transaction"
        )
      )
    );

    if (msg.sender != owner()) {
      require(
        msg.value >= price * _mintAmount,
        "Cannot mint more than the price of the battle stars"
      );
    }

    if (countShipJaeger + _mintAmount == shipsForSaleJaeger) {
      shipJaegerOutOfStock = true;
    }

    // Mint Battle Stars
    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint256 newBattleStarId = totalSupply + i;
      addressMintedBalanceBattleStars[msg.sender]++;
      battlestarsToOwner[newBattleStarId] = msg.sender;
      _createBattleStarsJaeger(newBattleStarId, msg.sender);
      countShipJaeger++;
      _safeMint(msg.sender, newBattleStarId);
    }
  }

  function mintBattleStarsShipPrometeus(uint256 _mintAmount) public payable {
    require(saleActive == true, "Cannot mint tokens before the sale has started");
    require(shipPrometeusOutOfStock == false, "Ship Prometeus is out of stock");
    uint256 totalSupply = totalSupply();

    require(
      countShipPrometeus <= shipsForSalePrometeus,
      "Cannot mint more than the ships Prometeus for sale"
    );

    require(
      countShipPrometeus + _mintAmount <= shipsForSalePrometeus,
      "Cannot mint more Prometeus than the total amount of supplies"
    );

    require(
      _mintAmount <= maxMintAmountPerTransaction,
      string(
        abi.encodePacked(
          "Cannot mint more than ",
          maxMintAmountPerTransaction,
          " battle stars per transaction"
        )
      )
    );

    require(
      addressMintedBalanceBattleStars[msg.sender] + _mintAmount <= ntfPerAddressLimit,
      string(
        abi.encodePacked(
          "Cannot mint more than ",
          ntfPerAddressLimit,
          " battle stars per transaction"
        )
      )
    );

    if (msg.sender != owner()) {
      require(
        msg.value >= price * _mintAmount,
        "Cannot mint more than the price of the battle stars"
      );
    }

    if (countShipPrometeus + _mintAmount == shipsForSalePrometeus) {
      shipPrometeusOutOfStock = true;
    }

    // Mint Battle Stars
    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint256 newBattleStarId = totalSupply + i;
      addressMintedBalanceBattleStars[msg.sender]++;
      battlestarsToOwner[newBattleStarId] = msg.sender;
      _createBattleStarsPrometeus(newBattleStarId, msg.sender);
      countShipPrometeus++;
      _safeMint(msg.sender, newBattleStarId);
    }
  }

  // Withdraw funds form the contract
  function withdrawTeam() public payable onlyOwner {
    require(msg.sender == owner(), "Only the owner can withdraw funds");
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os, "Cannot withdraw funds from the contract");
  }
}