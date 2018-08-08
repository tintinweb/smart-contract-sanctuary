pragma solidity ^0.4.18;

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
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b0d4d5c4d5f0d1c8d9dfddcad5de9ed3df">[email&#160;protected]</a>> (https://github.com/dete)
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
  // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

contract CryptoCinema is ERC721, Ownable {

  event FilmCreated(uint256 tokenId, string name, address owner);
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);
  event Transfer(address from, address to, uint256 tokenId);

  string public constant NAME = "Film";
  string public constant SYMBOL = "FilmToken";

  uint256 private startingPrice = 0.01 ether;

  mapping (uint256 => address) public filmIdToOwner;

  mapping (address => uint256) private ownershipTokenCount;

  mapping (uint256 => address) public filmIdToApproved;

  mapping (uint256 => uint256) private filmIdToPrice;

  /*** DATATYPES ***/
  struct Film {
    string name;
  }

  Film[] private films;

  function approve(address _to, uint256 _tokenId) public { //ERC721
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));
    filmIdToApproved[_tokenId] = _to;
    Approval(msg.sender, _to, _tokenId);
  }

  function balanceOf(address _owner) public view returns (uint256 balance) { //ERC721
    return ownershipTokenCount[_owner];
  }

  function createFilmToken(string _name, uint256 _price) public onlyContractOwner {
    _createFilm(_name, msg.sender, _price);
  }

  function create18FilmsTokens() public onlyContractOwner {
     uint256 totalFilms = totalSupply();
	 
	 require (totalFilms<1); // only 3 tokens for start
	 
	 for (uint8 i=1; i<=18; i++)
		_createFilm("Film", address(this), startingPrice);
	
  }
  
  function getFilm(uint256 _tokenId) public view returns (string filmName, uint256 sellingPrice, address owner) {
    Film storage film = films[_tokenId];
    filmName = film.name;
    sellingPrice = filmIdToPrice[_tokenId];
    owner = filmIdToOwner[_tokenId];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  function name() public pure returns (string) { //ERC721
    return NAME;
  }

  function ownerOf(uint256 _tokenId) public view returns (address owner) { //ERC721
    owner = filmIdToOwner[_tokenId];
    require(owner != address(0));
  }

  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = filmIdToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = filmIdToPrice[_tokenId];

    require(oldOwner != newOwner);
    require(_addressNotNull(newOwner));
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 97), 100)); //97% to previous owner

	
    // The price increases by 20% 
    filmIdToPrice[_tokenId] = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 12), 10)); 

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //
    }

    TokenSold(_tokenId, sellingPrice, filmIdToPrice[_tokenId], oldOwner, newOwner, films[_tokenId].name);
	
    if (msg.value > sellingPrice) { //if excess pay
	    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
		msg.sender.transfer(purchaseExcess);
	}
  }
  
  function symbol() public pure returns (string) { //ERC721
    return SYMBOL;
  }

  function takeOwnership(uint256 _tokenId) public { //ERC721
    address newOwner = msg.sender;
    address oldOwner = filmIdToOwner[_tokenId];

    require(_addressNotNull(newOwner));
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) { //for web site view
    return filmIdToPrice[_tokenId];
  }

  function allFilmsInfo(uint256 _startFilmId) public view returns (address[] owners, uint256[] prices) { //for web site view
	
	uint256 totalFilms = totalSupply();
	
    if (totalFilms == 0 || _startFilmId >= totalFilms) {
        // Return an empty array
      return (new address[](0), new uint256[](0));
    }
	
	uint256 indexTo;
	if (totalFilms > _startFilmId+1000)
		indexTo = _startFilmId + 1000;
	else 	
		indexTo = totalFilms;
		
    uint256 totalResultFilms = indexTo - _startFilmId;		
		
	address[] memory owners_res = new address[](totalResultFilms);
	uint256[] memory prices_res = new uint256[](totalResultFilms);
	
	for (uint256 filmId = _startFilmId; filmId < indexTo; filmId++) {
	  owners_res[filmId - _startFilmId] = filmIdToOwner[filmId];
	  prices_res[filmId - _startFilmId] = filmIdToPrice[filmId];
	}
	
	return (owners_res, prices_res);
  }
  
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerToken) { //ERC721 for web site view
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalFilms = totalSupply();
      uint256 resultIndex = 0;

      uint256 filmId;
      for (filmId = 0; filmId <= totalFilms; filmId++) {
        if (filmIdToOwner[filmId] == _owner) {
          result[resultIndex] = filmId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  function totalSupply() public view returns (uint256 total) { //ERC721
    return films.length;
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
    return filmIdToApproved[_tokenId] == _to;
  }

  function _createFilm(string _name, address _owner, uint256 _price) private {
    Film memory _film = Film({
      name: _name
    });
    uint256 newFilmId = films.push(_film) - 1;

    require(newFilmId == uint256(uint32(newFilmId))); //check maximum limit of tokens

    FilmCreated(newFilmId, _name, _owner);

    filmIdToPrice[newFilmId] = _price;

    _transfer(address(0), _owner, newFilmId);
  }

  function _owns(address _checkedAddr, uint256 _tokenId) private view returns (bool) {
    return _checkedAddr == filmIdToOwner[_tokenId];
  }

function _transfer(address _from, address _to, uint256 _tokenId) private {
    ownershipTokenCount[_to]++;
    filmIdToOwner[_tokenId] = _to;

    // When creating new films _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete filmIdToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
}

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