pragma solidity ^0.4.21;

contract Ownable {

  address public contractOwner;

  function Ownable() public {
    contractOwner = msg.sender;
  }

  modifier onlyContractOwner() {
    require(msg.sender == contractOwner);
    _;
  }

  function transferContractOwnership(address _newOwner) public onlyContractOwner {
    require(_newOwner != address(0));
    contractOwner = _newOwner;
  }
  
  function contractWithdraw() public onlyContractOwner {
      contractOwner.transfer(this.balance);
  }  

}

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="543031203114352c3d3b392e313a7a373b">[email&#160;protected]</a>> (https://github.com/dete)
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

contract EthPiranha is ERC721, Ownable {

  event PiranhaCreated(uint256 tokenId, string name, address owner);
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);
  event Transfer(address from, address to, uint256 tokenId);

  string public constant NAME = "Piranha";
  string public constant SYMBOL = "PiranhaToken";

  mapping (uint256 => address) private piranhaIdToOwner;

  mapping (address => uint256) private ownershipTokenCount;

  mapping (uint256 => address) private piranhaIdToApproved;
  
   /*** DATATYPES ***/
  struct Piranha {
    string name;
	uint8 size;
	uint256 gen;
	uint8 unique;
	uint256 growthStartTime;
	uint256 sellPrice;
	uint8 hungry;
  }

  Piranha[] public piranhas;

  function approve(address _to, uint256 _tokenId) public { //ERC721
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));
    piranhaIdToApproved[_tokenId] = _to;
    Approval(msg.sender, _to, _tokenId);
  }

  function balanceOf(address _owner) public view returns (uint256 balance) { //ERC721
    return ownershipTokenCount[_owner];
  }

  function createPiranhaTokens() public onlyContractOwner {
     for (uint8 i=0; i<15; i++) {
		_createPiranha("EthPiranha", msg.sender, 20 finney, 160, 1, 0);
	}
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  function name() public pure returns (string) { //ERC721
    return NAME;
  }

  function symbol() public pure returns (string) { //ERC721
    return SYMBOL;
  }  

  function ownerOf(uint256 _tokenId) public view returns (address owner) { //ERC721
    owner = piranhaIdToOwner[_tokenId];
    require(owner != address(0));
  }

  function buy(uint256 _tokenId) public payable {
    address oldOwner = piranhaIdToOwner[_tokenId];
    address newOwner = msg.sender;

	Piranha storage piranha = piranhas[_tokenId];

    uint256 sellingPrice = piranha.sellPrice;

    require(oldOwner != newOwner);
    require(_addressNotNull(newOwner));
    require(msg.value >= sellingPrice && sellingPrice > 0);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 97), 100)); //97% to previous owner, 3% dev tax

    // Stop selling
    piranha.sellPrice=0;
	piranha.hungry=0;

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //
    }

    TokenSold(_tokenId, sellingPrice, 0, oldOwner, newOwner, piranhas[_tokenId].name);
	
    if (msg.value > sellingPrice) { //if excess pay
	    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
		msg.sender.transfer(purchaseExcess);
	}
  }
  
  function changePiranhaName(uint256 _tokenId, string _name) public payable {
	require (piranhaIdToOwner[_tokenId] == msg.sender && msg.value == 0.001 ether);
	require(bytes(_name).length <= 15);
	
	Piranha storage piranha = piranhas[_tokenId];
	piranha.name = _name;
  }
  
  function startSelling(uint256 _tokenId, uint256 _price) public {
	require (piranhaIdToOwner[_tokenId] == msg.sender);
	
	Piranha storage piranha = piranhas[_tokenId];
	piranha.sellPrice = _price;
  }  

  function stopSelling(uint256 _tokenId) public {
	require (piranhaIdToOwner[_tokenId] == msg.sender);

	Piranha storage piranha = piranhas[_tokenId];
	require (piranha.sellPrice > 0);
	
	piranha.sellPrice = 0;
  }  
  
  function hungry(uint256 _tokenId) public {
	require (piranhaIdToOwner[_tokenId] == msg.sender);

	Piranha storage piranha = piranhas[_tokenId];
	require (piranha.hungry == 0);
	
	uint8 piranhaSize=uint8(piranha.size+(now-piranha.growthStartTime)/900);

	require (piranhaSize < 240);
	
	piranha.hungry = 1;
  }   

  function notHungry(uint256 _tokenId) public {
	require (piranhaIdToOwner[_tokenId] == msg.sender);

	Piranha storage piranha = piranhas[_tokenId];
	require (piranha.hungry == 1);
	
	piranha.hungry = 0;
  }   

  function bite(uint256 _tokenId, uint256 _victimTokenId) public payable {
	require (piranhaIdToOwner[_tokenId] == msg.sender);
	require (msg.value == 1 finney);
	
	Piranha storage piranha = piranhas[_tokenId];
	Piranha storage victimPiranha = piranhas[_victimTokenId];
	require (piranha.hungry == 1 && victimPiranha.hungry == 1);

	uint8 vitimPiranhaSize=uint8(victimPiranha.size+(now-victimPiranha.growthStartTime)/900);
	
	require (vitimPiranhaSize>40); // don&#39;t bite a small

	uint8 piranhaSize=uint8(piranha.size+(now-piranha.growthStartTime)/900)+10;
	
	if (piranhaSize>240) { 
	    piranha.size = 240; //maximum
		piranha.hungry = 0;
	} else {
	    piranha.size = piranhaSize;
	}
     
	//decrease victim size 
	if (vitimPiranhaSize>=50) {
	    vitimPiranhaSize-=10;
	    victimPiranha.size = vitimPiranhaSize;
	}
    else {
		victimPiranha.size=40;
	}
	
	piranha.growthStartTime=now;
	victimPiranha.growthStartTime=now;
	
  }    
  
  function breeding(uint256 _maleTokenId, uint256 _femaleTokenId) public payable {
  
    require (piranhaIdToOwner[_maleTokenId] ==  msg.sender && piranhaIdToOwner[_femaleTokenId] == msg.sender);
	require (msg.value == 0.01 ether);

	Piranha storage piranhaMale = piranhas[_maleTokenId];
	Piranha storage piranhaFemale = piranhas[_femaleTokenId];
	
	uint8 maleSize=uint8(piranhaMale.size+(now-piranhaMale.growthStartTime)/900);
	if (maleSize>240)
	   piranhaMale.size=240;
	else 
	   piranhaMale.size=maleSize;

	uint8 femaleSize=uint8(piranhaFemale.size+(now-piranhaFemale.growthStartTime)/900);
	if (femaleSize>240)
	   piranhaFemale.size=240;
	else 
	   piranhaFemale.size=femaleSize;
	   
	require (piranhaMale.size > 150 && piranhaFemale.size > 150);
	
	uint8 newbornSize = uint8(SafeMath.div(SafeMath.add(piranhaMale.size, piranhaMale.size),4));
	
	uint256 maxGen=piranhaFemale.gen;
	uint256 minGen=piranhaMale.gen;
	
	if (piranhaMale.gen > piranhaFemale.gen) {
		maxGen=piranhaMale.gen;
		minGen=piranhaFemale.gen;
	} 
	
	uint256 randNum = uint256(block.blockhash(block.number-1));
	uint256 newbornGen;
	uint8 newbornUnique = uint8(randNum%100+1); //chance to get rare piranha
	
	if (randNum%(10+maxGen) == 1) { // new generation, difficult depends on maxgen
		newbornGen = SafeMath.add(maxGen,1);
	} else if (maxGen == minGen) {
		newbornGen = maxGen;
	} else {
		newbornGen = SafeMath.add(randNum%(maxGen-minGen+1),minGen);
	}
	
	// 5% chance to get rare piranhas for each gen
	if (newbornUnique > 5) 
		newbornUnique = 0;
		
     //initiate new size, cancel selling
	 piranhaMale.size = uint8(SafeMath.div(piranhaMale.size,2));		
     piranhaFemale.size = uint8(SafeMath.div(piranhaFemale.size,2));	

	 piranhaMale.growthStartTime = now;	 
	 piranhaFemale.growthStartTime = now;	 

	 piranhaMale.sellPrice = 0;	 
	 piranhaFemale.sellPrice = 0;	 
		
	_createPiranha("EthPiranha", msg.sender, 0, newbornSize, newbornGen, newbornUnique);
  
  }
  
  function takeOwnership(uint256 _tokenId) public { //ERC721
    address newOwner = msg.sender;
    address oldOwner = piranhaIdToOwner[_tokenId];

    require(_addressNotNull(newOwner));
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  function allPiranhasInfo(uint256 _startPiranhaId) public view returns (address[] owners, uint8[] sizes, uint8[] hungry, uint256[] prices) { //for web site view
	
	uint256 totalPiranhas = totalSupply();
	Piranha storage piranha;
	
    if (totalPiranhas == 0 || _startPiranhaId >= totalPiranhas) {
        // Return an empty array
      return (new address[](0), new uint8[](0), new uint8[](0), new uint256[](0));
    }

	
	uint256 indexTo;
	if (totalPiranhas > _startPiranhaId+1000)
		indexTo = _startPiranhaId + 1000;
	else 	
		indexTo = totalPiranhas;
		
    uint256 totalResultPiranhas = indexTo - _startPiranhaId;		
		
	address[] memory owners_res = new address[](totalResultPiranhas);
	uint8[] memory size_res = new uint8[](totalResultPiranhas);
	uint8[] memory hungry_res = new uint8[](totalResultPiranhas);
	uint256[] memory prices_res = new uint256[](totalResultPiranhas);
	
	for (uint256 piranhaId = _startPiranhaId; piranhaId < indexTo; piranhaId++) {
	  piranha = piranhas[piranhaId];
	  
	  owners_res[piranhaId - _startPiranhaId] = piranhaIdToOwner[piranhaId];
	  hungry_res[piranhaId - _startPiranhaId] = piranha.hungry;
	  size_res[piranhaId - _startPiranhaId] = uint8(piranha.size+(now-piranha.growthStartTime)/900);
	  prices_res[piranhaId - _startPiranhaId] = piranha.sellPrice;
	}
	
	return (owners_res, size_res, hungry_res, prices_res);
  }
  
  function totalSupply() public view returns (uint256 total) { //ERC721
    return piranhas.length;
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
    return piranhaIdToApproved[_tokenId] == _to;
  }

  function _createPiranha(string _name, address _owner, uint256 _price, uint8 _size, uint256 _gen, uint8 _unique) private {
    Piranha memory _piranha = Piranha({
      name: _name,
	  size: _size,
	  gen: _gen,
	  unique: _unique,	  
	  growthStartTime: now,
	  sellPrice: _price,
	  hungry: 0
    });
    uint256 newPiranhaId = piranhas.push(_piranha) - 1;

    require(newPiranhaId == uint256(uint32(newPiranhaId))); //check maximum limit of tokens

    PiranhaCreated(newPiranhaId, _name, _owner);

    _transfer(address(0), _owner, newPiranhaId);
  }

  function _owns(address _checkedAddr, uint256 _tokenId) private view returns (bool) {
    return _checkedAddr == piranhaIdToOwner[_tokenId];
  }

  function _transfer(address _from, address _to, uint256 _tokenId) private {
    ownershipTokenCount[_to]++;
    piranhaIdToOwner[_tokenId] = _to;

    // When creating new piranhas _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete piranhaIdToApproved[_tokenId];
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