pragma solidity ^0.4.21;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {

  address public contractOwner;

  event ContractOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    contractOwner = msg.sender;
  }

  modifier onlyContractOwner() {
    require(msg.sender == contractOwner);
    _;
  }

  function transferContractOwnership(address _newOwner) public onlyContractOwner {
    require(_newOwner != address(0));
    ContractOwnershipTransferred(contractOwner, _newOwner);
    contractOwner = _newOwner;
  }
  
  function payoutFromContract() public onlyContractOwner {
      contractOwner.transfer(this.balance);
  }  

}

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<span class="__cf_email__" data-cfemail="3f5b5a4b5a7f5e47565052455a51115c50">[email&#160;protected]</span>> (https://github.com/dete)
contract ERC721 {
  // Required methods
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

  // Optional
  // function name() public view returns (string name);
  // function symbol() public view returns (string symbol);
  // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

contract CryptoDrinks is ERC721, Ownable {

  event DrinkCreated(uint256 tokenId, string name, address owner);
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);
  event Transfer(address from, address to, uint256 tokenId);

  string public constant NAME = "CryptoDrinks";
  string public constant SYMBOL = "DrinksToken";

  uint256 private startingPrice = 0.02 ether;
  
  uint256 private startTime = now;

  mapping (uint256 => address) public drinkIdToOwner;

  mapping (address => uint256) private ownershipTokenCount;

  mapping (uint256 => address) public drinkIdToApproved;

  mapping (uint256 => uint256) private drinkIdToPrice;

  /*** DATATYPES ***/
  struct Drink {
    string name;
  }

  Drink[] private drinks;

  function approve(address _to, uint256 _tokenId) public { //ERC721
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));
    drinkIdToApproved[_tokenId] = _to;
    Approval(msg.sender, _to, _tokenId);
  }

  function balanceOf(address _owner) public view returns (uint256 balance) { //ERC721
    return ownershipTokenCount[_owner];
  }

  function createOneDrink(string _name) public onlyContractOwner {
    _createDrink(_name, address(this), startingPrice);
  }

  function createManyDrinks() public onlyContractOwner {
     uint256 totalDrinks = totalSupply();
	 
     require (totalDrinks < 1);
	 
 	 _createDrink("Barmen", address(this), 1 ether);
 	 _createDrink("Vodka", address(this), startingPrice);
	 _createDrink("Wine", address(this), startingPrice);
	 _createDrink("Cognac", address(this), startingPrice);
	 _createDrink("Martini", address(this), startingPrice);
	 _createDrink("Beer", address(this), startingPrice);
	 _createDrink("Tequila", address(this), startingPrice);
	 _createDrink("Whiskey", address(this), startingPrice);
	 _createDrink("Baileys", address(this), startingPrice);
	 _createDrink("Champagne", address(this), startingPrice);
  }
  
  function getDrink(uint256 _tokenId) public view returns (string drinkName, uint256 sellingPrice, address owner) {
    Drink storage drink = drinks[_tokenId];
    drinkName = drink.name;
    sellingPrice = drinkIdToPrice[_tokenId];
    owner = drinkIdToOwner[_tokenId];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  function name() public pure returns (string) { //ERC721
    return NAME;
  }

  function ownerOf(uint256 _tokenId) public view returns (address owner) { //ERC721
    owner = drinkIdToOwner[_tokenId];
    require(owner != address(0));
  }

  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
  
	require (now - startTime >= 10800 || _tokenId==0); //3 hours
	
    address oldOwner = drinkIdToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = drinkIdToPrice[_tokenId];

    require(oldOwner != newOwner);
    require(_addressNotNull(newOwner));
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 9), 10)); //90% to previous owner
    uint256 barmen_payment = uint256(SafeMath.div(sellingPrice, 10)); //10% to barmen

	address barmen = ownerOf(0);
	
    // Next price will in 2 times more if it less then 1 ether.
	if (sellingPrice >= 1 ether)
		drinkIdToPrice[_tokenId] = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 3), 2));
	else 	
		drinkIdToPrice[_tokenId] = uint256(SafeMath.mul(sellingPrice, 2));

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //
    }

    // Pay 10% to barmen, if drink sold
	// token 0 not drink, its barmen
    if (_tokenId > 0) {
      barmen.transfer(barmen_payment); //
    }

    TokenSold(_tokenId, sellingPrice, drinkIdToPrice[_tokenId], oldOwner, newOwner, drinks[_tokenId].name);
	
    if (msg.value > sellingPrice) { //if excess pay
	    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
		msg.sender.transfer(purchaseExcess);
	}
  }

  function secondsAfterStart() public view returns (uint256) { //ERC721
    return uint256(now - startTime);
  }
  
  function symbol() public pure returns (string) { //ERC721
    return SYMBOL;
  }


  function takeOwnership(uint256 _tokenId) public { //ERC721
    address newOwner = msg.sender;
    address oldOwner = drinkIdToOwner[_tokenId];

    require(_addressNotNull(newOwner));
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) { //for web site view
    return drinkIdToPrice[_tokenId];
  }
  
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) { //for web site view
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalDrinks = totalSupply();
      uint256 resultIndex = 0;

      uint256 drinkId;
      for (drinkId = 0; drinkId <= totalDrinks; drinkId++) {
        if (drinkIdToOwner[drinkId] == _owner) {
          result[resultIndex] = drinkId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  function totalSupply() public view returns (uint256 total) { //ERC721
    return drinks.length;
  }

  function transfer(address _to, uint256 _tokenId) public { //ERC721
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

	_transfer(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public { //ERC721
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }


  /* PRIVATE FUNCTIONS */
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return drinkIdToApproved[_tokenId] == _to;
  }

  function _createDrink(string _name, address _owner, uint256 _price) private {
    Drink memory _drink = Drink({
      name: _name
    });
    uint256 newDrinkId = drinks.push(_drink) - 1;

    require(newDrinkId == uint256(uint32(newDrinkId))); //check maximum limit of tokens

    DrinkCreated(newDrinkId, _name, _owner);

    drinkIdToPrice[newDrinkId] = _price;

    _transfer(address(0), _owner, newDrinkId);
  }

  function _owns(address _checkedAddr, uint256 _tokenId) private view returns (bool) {
    return _checkedAddr == drinkIdToOwner[_tokenId];
  }

function _transfer(address _from, address _to, uint256 _tokenId) private {
    ownershipTokenCount[_to]++;
    drinkIdToOwner[_tokenId] = _to;

    // When creating new drinks _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete drinkIdToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
}