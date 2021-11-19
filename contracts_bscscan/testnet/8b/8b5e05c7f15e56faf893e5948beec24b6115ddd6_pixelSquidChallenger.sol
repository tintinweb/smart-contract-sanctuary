/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

pragma solidity ^0.5.11;


//kingdom scientist copy right.
//erc721的介面
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  function totalSupply() public view returns (uint256 total);
  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
}

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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownables {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

//strength contract
contract pixelSquidChallenger is  ERC721,Ownables {

  using SafeMath for uint256;
  string public name_ = "ps";
  struct Ability {
    uint256 strength;
    uint256 agility;
    uint256 intelligence;
    uint256 energy;
    uint256 stamina;
  }
  
  struct challenger {
    string token_name;
    uint256 quality; //challenger's quality (1: common ,2: rare)
    uint256 level; //challenger's level;
     string url; //challenger's image url
    string background; //challenger's background url
    string animation_url;//challenger's animation url(only for rare lv.)
    Ability ability;
    uint256 value;//challenger current value; unit: BNB
  }

  challenger[] challengers;
  string public symbol_ = "ps";
  uint256 challengerMax = 2 ;
  uint[] market;

  mapping (uint => address) public challengerToOwner; //every challenger hava a unique id,call this mapping can found owner
  mapping (address => uint) ownerChallengerCount; //return address owner challenger counts
  mapping (uint => address) challengerApprovals; //follow ERC721,allow challenger transfer to someone
  mapping (uint256 => uint256) public tokenIdToPrice;

 
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _from, address indexed _to,uint indexed _tokenId);
  event Take(address _to, address _from,uint _tokenId);
  event Create(string token_name, uint256 quality,uint256 level, string url,string animation_url,string background,uint256 strength,uint256 agility,uint256 intelligence,uint256 energy,uint256 stamina,uint256 value);

  function name() external view returns (string memory) {
        return name_;
  }

  function symbol() external view returns (string memory) {
        return symbol_;
  }

  function totalSupply() public view returns (uint256) {
    return challengerMax;
  }

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerChallengerCount[_owner]; // show someone balance
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return challengerToOwner[_tokenId]; // show someone challenger's owner
  }

  function checkAllOwner(uint[] memory _tokenId, address owner) public view returns (bool) {
    for(uint i=0;i<_tokenId.length;i++){
        if(owner != challengerToOwner[_tokenId[i]]){
            return false;   //check owner by challenger 
        }
    }
    
    return true;
  }

  function seeChallengerTokenName(uint256 _tokenId) public view returns (string memory token_name) {
    return challengers[_tokenId].token_name;
  }
  
  function seeChallengerQuality(uint256 _tokenId) public view returns (uint256 quality) {
    return challengers[_tokenId].quality;
  }
  
  function seeChallengerLevel(uint256 _tokenId) public view returns (uint256 level) {
    return challengers[_tokenId].level;
  }
  
  function seeChallengerURL(uint256 _tokenId) public view returns (string memory url){
      return challengers[_tokenId].url;
  }
  
  function seeChallengerAnimation(uint256 _tokenId) public view returns(string memory animation_url){
      return challengers[_tokenId].animation_url;
  }
  
  function seeChallengerBackground(uint256 _tokenId) public view returns(string memory background){
      return challengers[_tokenId].background;
  }
  
  function seeChallengerValue(uint256 _tokenId) public view returns (uint256 value){
      return challengers[_tokenId].value;
  }
  
  function seeChallengerStrength(uint256 _tokenId) public view returns (uint256 strength) {
    return challengers[_tokenId].ability.strength;
  }
  
  function seeChallengerAgility(uint256 _tokenId) public view returns (uint256 agility) {
    return challengers[_tokenId].ability.agility;
  }
  
  function seeChallengerIntelligence(uint256 _tokenId) public view returns (uint256 intelligence) {
    return challengers[_tokenId].ability.intelligence;
  }
  
  function seeChallengerEnergy(uint256 _tokenId) public view returns (uint256 energy) {
    return challengers[_tokenId].ability.energy;
  }
  
  function seeChallengerStamina(uint256 _tokenId) public view returns (uint256 stamina) {
   return challengers[_tokenId].ability.stamina;
  }
  

  function getChallengerByOwner(address _owner) external view returns(uint[] memory) { 
    uint[] memory result = new uint[](ownerChallengerCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < challengers.length; i++) {
      if (challengerToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

  function transfer(address _to, uint256 _tokenId) public {

    require(challengerToOwner[_tokenId] == msg.sender);
    
  
    ownerChallengerCount[msg.sender] = ownerChallengerCount[msg.sender].sub(1);
 
    ownerChallengerCount[_to] = ownerChallengerCount[_to].add(1);
   
    challengerToOwner[_tokenId] = _to;
    
    emit Transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public {
    require(challengerToOwner[_tokenId] == msg.sender);
    
    challengerApprovals[_tokenId] = _to;
    
    emit Approval(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external {
    // Safety check to prevent against an unexpected 0x0 default.
    require(challengerToOwner[_tokenId] == _from);
    require(challengerApprovals[_tokenId] == _to);
    
    challengerApprovals[_tokenId] = address(0);
    ownerChallengerCount[_from] = ownerChallengerCount[_from].sub(1);
    ownerChallengerCount[_to] = ownerChallengerCount[_to].add(1);
    challengerToOwner[_tokenId] = _to;
    
    emit Transfer(_from, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public {
    require(challengerToOwner[_tokenId] == msg.sender);
    
    address owner = ownerOf(_tokenId);

    ownerChallengerCount[msg.sender] = ownerChallengerCount[msg.sender].add(1);
    ownerChallengerCount[owner] = ownerChallengerCount[owner].sub(1);
    challengerToOwner[_tokenId] = msg.sender;
    
    emit Take(msg.sender, owner, _tokenId);
  }
  
  function createChallenger(string memory _token_name ,uint256 _quality,uint256 _lv, string memory _url, string memory _animation_url,string memory _background,uint256 _strength,uint256 _agility,uint256 _intelligence,uint256 _energy,uint256 _stamina, uint256 _val) public {
      
      require(challengers.length < challengerMax,"challenger its full");
      require(_lv > 0 ,"wrong challenger's level");
    
      require(_strength > 0,"strength cant than 0");
      require(_agility > 0,"strength cant than 0");
      require(_intelligence > 0,"strength cant than 0");
      require(_energy > 0,"strength cant than 0");
      require(_quality>0,"quality cant than 0");
      
      string memory token_name = _token_name;
      uint256 quality = _quality;
      uint256 level = _lv;
      string memory url = _url;
      string memory animation_url = _animation_url;
      string memory background = _background;
      uint256 val = _val;
      //Image memory image = Image(url,animation_url,background);
      Ability memory ability = Ability(_strength,_agility,_intelligence,_energy,_stamina);
      
     
      uint256 id = challengers.push(challenger(token_name,quality, level,url,animation_url,background,ability,uint256(val))) - 1;
      challengerToOwner[id] = msg.sender;
      ownerChallengerCount[msg.sender]++;
      //https://i.imgur.com/PMVPf9L.jpg
      //allowBuy(id, val);
  }
  
  function allowBuy(uint256 _tokenId, uint256 _price) internal {
        require(msg.sender == ownerOf(_tokenId), 'Not owner of this token');
        require(_price > 0, 'Price zero');
        tokenIdToPrice[_tokenId] = _price;
  }
  
  function buy(address payable seller, uint256 _tokenId) external payable {

      uint256 price = tokenIdToPrice[_tokenId];
      address _to = msg.sender;
      uint256 amount = msg.value;

      require(price > 0,'This token is not for sale');
      require(seller == ownerOf(_tokenId),'Not owner of this token');
      require(challengers[_tokenId].value == amount,  "wrong price");
      
    
      seller.transfer(amount); 
      ownerChallengerCount[seller] = ownerChallengerCount[seller].sub(1);
      ownerChallengerCount[_to] = ownerChallengerCount[_to].add(1);
      challengerToOwner[_tokenId] = _to;
      
      tokenIdToPrice[_tokenId] = 0;
      challengers[_tokenId].value = 0;
      emit Transfer(seller, _to, _tokenId);
  }
  
  function sell(uint256 _tokenId, uint256 _price) external {
       require(_price > 0,'Price its too low');
       require(msg.sender == ownerOf(_tokenId),"not owner");
      
       tokenIdToPrice[_tokenId] = _price;
       challengers[_tokenId].value = _price;
  }
  
  function cancelSell(uint256 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId),"not owner");
        require(tokenIdToPrice[_tokenId] > 0 ,"this token is not for sell alrealdy");
        tokenIdToPrice[_tokenId] = 0;
  }
  
  function checkTokenPriceById(uint256 _tokenId) public view returns (uint256 _price){
      return tokenIdToPrice[_tokenId];
  }
  
  function upChallengerlevel(uint256 _tokenId) external {
       require(msg.sender == ownerOf(_tokenId),"not owner");
       challengers[_tokenId].level = challengers[_tokenId].level + 1;
  }
  
  function setChallengerMax(uint256 _maxCnt) external {
      require(_maxCnt > 0,"max_cnt cant less than 0");
      challengerMax = _maxCnt;
  }
  
  
  function getChallengerTotCnt()public view returns (uint256){
      return challengers.length;
  }
  
  function getChallengerOnMarket() public view returns (uint[] memory){
      
      uint[] memory result = new uint[](market.length) ;
      uint counter = 0;
      for (uint i=0;i<challengers.length;i++){
          if (challengers[i].value > 0){
            result[counter] = i;
            counter ++;
          }
      }
      return market;
  }
  
  function getChallengerInfo (uint256 _tokenId) public view returns (string memory tokenName,uint256 quality ,uint256 level,string memory url,string memory animationUrl,string memory background,uint256 value){
      tokenName = challengers[_tokenId].token_name;
      quality = challengers[_tokenId].quality;
      level = challengers[_tokenId].level;
      url = challengers[_tokenId].url;
      animationUrl = challengers[_tokenId].animation_url;
      background = challengers[_tokenId].background;
      value = challengers[_tokenId].value;
      return (tokenName,quality,level,url,animationUrl,background,value);
  }
  
  function getChallengerAbility(uint256 _tokenId) public view returns (uint256 str,uint256 agi,uint256 itg,uint256 eng,uint256 sta){
       str = challengers[_tokenId].ability.strength;
       agi = challengers[_tokenId].ability.agility;
       itg = challengers[_tokenId].ability.intelligence;
       eng = challengers[_tokenId].ability.energy;
       sta = challengers[_tokenId].ability.stamina;
      return (str,agi,itg,eng,sta);
  }
  
  function getAllChallengers() public view returns (uint[] memory token_ids){
     
     uint[] memory result = new uint[](challengers.length);
    uint counter = 0;
    for (uint i = 0; i < challengers.length; i++) {
      if (challengers[i].value > 0) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }
 
}