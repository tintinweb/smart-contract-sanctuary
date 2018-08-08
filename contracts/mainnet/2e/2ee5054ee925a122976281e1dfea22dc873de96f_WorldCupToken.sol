pragma solidity ^0.4.21;
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
contract WorldCupToken is ERC721 {
  event Birth(uint256 tokenId, string name, address owner);
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);
  event Transfer(address from, address to, uint256 tokenId);
 
  /*** CONSTANTS ***/
  string public constant NAME = "WorldCupToken";
  string public constant SYMBOL = "WorldCupToken";
  uint256 private startingPrice = 0.1 ether;
  mapping (uint256 => address) private teamIndexToOwner;
  mapping (address => uint256) private ownershipTokenCount;
  mapping (uint256 => address) private teamIndexToApproved;
  mapping (uint256 => uint256) private teamIndexToPrice;
  mapping (string => uint256) private nameIndexToTeam;   // eg: Egypt => 0
  mapping (string => string) private teamIndexToName;    // eg: 0 => Egypt
  
  
  address private ceoAddress;
  bool private isStop;
  
  struct Team {
    string name;
  }
  Team[] private teams;
  
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }
  modifier onlyStart() {
    require(isStop == false);
    _;
  }
  
   function setStop() public onlyCEO {
    
    isStop = true;
  }
  function setStart() public onlyCEO {
    
    isStop = false;
  }
  
  /*** CONSTRUCTOR ***/
  function WorldCupToken() public {
    ceoAddress = msg.sender;
    isStop=false;
    _createTeam("Egypt", msg.sender, startingPrice);
    teamIndexToName["0"]="Egypt";
    
    _createTeam("Morocco", msg.sender, startingPrice);
    teamIndexToName["1"]="Morocco";
    
    _createTeam("Nigeria", msg.sender, startingPrice);
    teamIndexToName["2"]="Nigeria";
    
    _createTeam("Senegal", msg.sender, startingPrice);
    teamIndexToName["3"]="Senegal";
    
    _createTeam("Tunisia", msg.sender, startingPrice);
    teamIndexToName["4"]="Tunisia";
    
    _createTeam("Australia", msg.sender, startingPrice);
    teamIndexToName["5"]="Australia";
    
    _createTeam("IR Iran", msg.sender, startingPrice);
    teamIndexToName["6"]="IR Iran";
    
    _createTeam("Japan", msg.sender, startingPrice);
   teamIndexToName["7"]="Japan";
    
    _createTeam("Korea Republic", msg.sender, startingPrice);
   teamIndexToName["8"]="Korea Republic";
    
    _createTeam("Saudi Arabia", msg.sender, startingPrice);
    teamIndexToName["9"]="Saudi Arabia";
    
    _createTeam("Belgium", msg.sender, startingPrice);
    teamIndexToName["10"]="Belgium";
    
    _createTeam("Croatia", msg.sender, startingPrice);
    teamIndexToName["11"]="Croatia";
    
    
    _createTeam("Denmark", msg.sender, startingPrice);
    teamIndexToName["12"]="Denmark";
    
    
    _createTeam("England", msg.sender, startingPrice);
    teamIndexToName["13"]="England";
    
    
    _createTeam("France", msg.sender, startingPrice);
    teamIndexToName["14"]="France";
    
    
    _createTeam("Germany", msg.sender, startingPrice);
    teamIndexToName["15"]="Germany";
    
    
    _createTeam("Iceland", msg.sender, startingPrice);
    teamIndexToName["16"]="Iceland";
    
    
    _createTeam("Poland", msg.sender, startingPrice);
    teamIndexToName["17"]="Poland";
    
    
    _createTeam("Portugal", msg.sender, startingPrice);
    teamIndexToName["18"]="Portugal";
    
    
    _createTeam("Russia", msg.sender, startingPrice);
    teamIndexToName["19"]="Russia";
    
    
    _createTeam("Serbia", msg.sender, startingPrice);
    teamIndexToName["20"]="Serbia";
    
    
    _createTeam("Spain", msg.sender, startingPrice);
    teamIndexToName["21"]="Spain";
    
    
    _createTeam("Sweden", msg.sender, startingPrice);
    teamIndexToName["22"]="Sweden";
    
    
    _createTeam("Switzerland", msg.sender, startingPrice);
    teamIndexToName["23"]="Switzerland";
    
    
    _createTeam("Costa Rica", msg.sender, startingPrice);
    teamIndexToName["24"]="Costa Rica";
    
    
    _createTeam("Mexico", msg.sender, startingPrice);
    teamIndexToName["25"]="Mexico";
    
    
    
    _createTeam("Panama", msg.sender, startingPrice);
    teamIndexToName["26"]="Panama";
    
    
    _createTeam("Argentina", msg.sender, startingPrice);
    teamIndexToName["27"]="Argentina";
    
    _createTeam("Brazil", msg.sender, startingPrice);
    teamIndexToName["28"]="Brazil";
    
    _createTeam("Colombia", msg.sender, startingPrice);
    teamIndexToName["29"]="Colombia";
    
    _createTeam("Peru", msg.sender, startingPrice);
    teamIndexToName["30"]="Peru";
    
    _createTeam("Uruguay", msg.sender, startingPrice);
    teamIndexToName["31"]="Uruguay";
      
  }
  
  function approve(
    address _to,
    uint256 _tokenId
  ) public  onlyStart {
    require(_owns(msg.sender, _tokenId));
    teamIndexToApproved[_tokenId] = _to;
    Approval(msg.sender, _to, _tokenId);
  }
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }
  
   function getTeamId(string _name) public view returns (uint256 id) {
    return nameIndexToTeam[_name];
  }
  
  function getTeam(uint256 _tokenId) public view returns (
    string teamName,
    uint256 sellingPrice,
    address owner
  ) {
    Team storage team = teams[_tokenId];
    teamName = team.name;
    sellingPrice = teamIndexToPrice[_tokenId];
    owner = teamIndexToOwner[_tokenId];
  }
  
  function getTeam4name(string _name) public view returns (
    string teamName,
    uint256 sellingPrice,
    address owner
  ) {
    uint256 _tokenId = nameIndexToTeam[_name];
    Team storage team = teams[_tokenId];
    require(SafeMath.diffString(_name,team.name)==true);
    teamName = team.name;
    sellingPrice = teamIndexToPrice[_tokenId];
    owner = teamIndexToOwner[_tokenId];
  }
  
  
  function implementsERC721() public pure returns (bool) {
    return true;
  }
  function name() public pure returns (string) {
    return NAME;
  }
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = teamIndexToOwner[_tokenId];
    require(owner != address(0));
  }
  
  function payout(address _to) public onlyCEO {
    _payout(_to);
  }
  
   function () public payable onlyStart {
      
       string memory data=string(msg.data);
       require(SafeMath.diffString(data,"")==false);    //data is not empty
       
       string memory _name=teamIndexToName[data];
       require(SafeMath.diffString(_name,"")==false);   //name is not empty
       
       if(nameIndexToTeam[_name]==0){
           require(SafeMath.diffString(_name,teams[0].name)==true);
       }
       
       purchase(nameIndexToTeam[_name]);
   }
  
  
  function purchase(uint256 _tokenId) public payable onlyStart {
    address oldOwner = teamIndexToOwner[_tokenId];
    address newOwner = msg.sender;
    uint256 sellingPrice = teamIndexToPrice[_tokenId];
    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);
    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));
    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);
    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 92), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
    teamIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 130),100);
    
    _transfer(oldOwner, newOwner, _tokenId);
    if (oldOwner != address(this)) {
      oldOwner.send(payment); //oldOwner take 92% of the sellingPrice
    }
    TokenSold(_tokenId, sellingPrice, teamIndexToPrice[_tokenId], oldOwner, newOwner, teams[_tokenId].name);
    msg.sender.send(purchaseExcess);
  }
  
  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return teamIndexToPrice[_tokenId];
  }
  
  function symbol() public pure returns (string) {
    return SYMBOL;
  }
  
  function takeOwnership(uint256 _tokenId) public onlyStart{
    address newOwner = msg.sender;
    address oldOwner = teamIndexToOwner[_tokenId];
    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));
    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));
    _transfer(oldOwner, newOwner, _tokenId);
  }
  
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalPersons = totalSupply();
      uint256 resultIndex = 0;
      uint256 teamId;
      for (teamId = 0; teamId <= totalPersons; teamId++) {
        if (teamIndexToOwner[teamId] == _owner) {
          result[resultIndex] = teamId;
          resultIndex++;
        }
      }
      return result;
    }
  }
  
  
  function totalSupply() public view returns (uint256 total) {
    return teams.length;
  }
  
  
  function transfer(
    address _to,
    uint256 _tokenId
  ) public onlyStart {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));
    _transfer(msg.sender, _to, _tokenId);
  }
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public onlyStart{
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));
    _transfer(_from, _to, _tokenId);
  }
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }
  
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return teamIndexToApproved[_tokenId] == _to;
  }
  
  
  function _createTeam(string _name, address _owner, uint256 _price) private {
    
    Team memory _team = Team({
      name: _name
    });
    uint256 newTeamId = teams.push(_team) - 1;
    nameIndexToTeam[_name]=newTeamId;
    Birth(newTeamId, _name, _owner);
    teamIndexToPrice[newTeamId] = _price;
    _transfer(address(0), _owner, newTeamId);
  }
  
  
  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == teamIndexToOwner[_tokenId];
  }
  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.send(this.balance);
    } else {
      _to.send(this.balance);
    }
  }
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    ownershipTokenCount[_to]++;
    teamIndexToOwner[_tokenId] = _to;
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      delete teamIndexToApproved[_tokenId];
    }
    Transfer(_from, _to, _tokenId);
  }
}
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
  
function diffString(string a, string b) internal pure returns (bool) {
    bytes memory ab=bytes(a);
    bytes memory bb=bytes(b);
    if(ab.length!=bb.length){
        return false;
    }
    uint len=ab.length;
    for(uint i=0;i<len;i++){
        if(ab[i]!=bb[i]){
            return false;
        }
    }
    return true;
  }
}