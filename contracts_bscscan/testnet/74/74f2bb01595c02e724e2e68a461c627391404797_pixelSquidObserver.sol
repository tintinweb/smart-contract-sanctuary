/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

pragma solidity ^0.5.11;


//kingdom scientist copy right.
//erc721 interface
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
contract pixelSquidObserver is  ERC721,Ownables {

  using SafeMath for uint256;
  string public name_ = "observer";
  struct Ability {
    uint256 watch_limit;
  }
  
  struct observer {
    string token_name;
    uint256 quality; //observer's quality (1: common ,2: rare)
    uint256 level; //observer's level;
    string url; //observer's image url
    string background; //observer's background url
    string animation_url;//observer's animation url(only for rare lv.)
    Ability ability;
    uint256 value;//observer current value; unit: BNB
  }

  observer[] observers;
  string public symbol_ = "observer";
  uint256 observerMax = 3500;
  uint[] market;

  mapping (uint => address) public observerToOwner; //every observer hava a unique id,call this mapping can found owner
  mapping (address => uint) ownerObserverCount; //return address owner observer counts
  mapping (uint => address) observerApprovals; //follow ERC721,allow observer transfer to someone
  mapping (uint256 => uint256) public tokenIdToPrice;

 
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _from, address indexed _to,uint indexed _tokenId);
  event Take(address _to, address _from,uint _tokenId);
  event Create(string token_name, uint256 quality,uint256 level, string url,string animation_url,string background,uint256 watch_limit,uint256 value);

  function name() external view returns (string memory) {
        return name_;
  }

  function symbol() external view returns (string memory) {
        return symbol_;
  }

  function totalSupply() public view returns (uint256) {
    return observerMax;
  }

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerObserverCount[_owner]; // show someone balance
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return observerToOwner[_tokenId]; // show someone observer's owner
  }

  function checkAllOwner(uint[] memory _tokenId, address owner) public view returns (bool) {
    for(uint i=0;i<_tokenId.length;i++){
        if(owner != observerToOwner[_tokenId[i]]){
            return false;   //check owner by observer 
        }
    }
    
    return true;
  }

  function seeObserverTokenName(uint256 _tokenId) public view returns (string memory token_name) {
    return observers[_tokenId].token_name;
  }
  
  function seeObserverQuality(uint256 _tokenId) public view returns (uint256 quality) {
    return observers[_tokenId].quality;
  }
  
  function seeObserverLevel(uint256 _tokenId) public view returns (uint256 level) {
    return observers[_tokenId].level;
  }
  
  function seeObserverURL(uint256 _tokenId) public view returns (string memory url){
      return observers[_tokenId].url;
  }
  
  function seeObserverAnimation(uint256 _tokenId) public view returns(string memory animation_url){
      return observers[_tokenId].animation_url;
  }
  
  function seeObserverBackground(uint256 _tokenId) public view returns(string memory background){
      return observers[_tokenId].background;
  }
  
  function seeObserverValue(uint256 _tokenId) public view returns (uint256 value){
      return observers[_tokenId].value;
  }
  
  function seeObserverStrength(uint256 _tokenId) public view returns (uint256 watch_limit) {
    return observers[_tokenId].ability.watch_limit;
  }
  
 

  function getObserverByOwner(address _owner) external view returns(uint[] memory) { 
    uint[] memory result = new uint[](ownerObserverCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < observers.length; i++) {
      if (observerToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

  function transfer(address _to, uint256 _tokenId) public {

    require(observerToOwner[_tokenId] == msg.sender);
    
  
    ownerObserverCount[msg.sender] = ownerObserverCount[msg.sender].sub(1);
 
    ownerObserverCount[_to] = ownerObserverCount[_to].add(1);
   
    observerToOwner[_tokenId] = _to;
    
    emit Transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public {
    require(observerToOwner[_tokenId] == msg.sender);
    
    observerApprovals[_tokenId] = _to;
    
    emit Approval(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external {
    // Safety check to prevent against an unexpected 0x0 default.
    require(observerToOwner[_tokenId] == _from);
    require(observerApprovals[_tokenId] == _to);
    
    observerApprovals[_tokenId] = address(0);
    ownerObserverCount[_from] = ownerObserverCount[_from].sub(1);
    ownerObserverCount[_to] = ownerObserverCount[_to].add(1);
    observerToOwner[_tokenId] = _to;
    
    emit Transfer(_from, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public {
    require(observerToOwner[_tokenId] == msg.sender);
    
    address owner = ownerOf(_tokenId);

    ownerObserverCount[msg.sender] = ownerObserverCount[msg.sender].add(1);
    ownerObserverCount[owner] = ownerObserverCount[owner].sub(1);
    observerToOwner[_tokenId] = msg.sender;
    
    emit Take(msg.sender, owner, _tokenId);
  }
  
  function recruitObserver(string memory _token_name ,uint256 _quality,uint256 _lv, string memory _url, string memory _animation_url,string memory _background,uint256 _watch_limit, uint256 _val) public {
      
      require(observers.length < observerMax,"observer its full");
      require(_lv > 0 ,"wrong observer's level");

      require(_watch_limit > 0 ,"watch_limit cant less than 0");
      require(_quality>0,"quality cant than 0");
      
      string memory token_name = _token_name;
      uint256 quality = _quality;
      uint256 level = _lv;
      string memory url = _url;
      string memory animation_url = _animation_url;
      string memory background = _background;
      
      uint256 val = _val;
      
      Ability memory ability = Ability(_watch_limit);
      
    
      uint256 id = observers.push(observer(token_name,quality, level,url,animation_url,background,ability,uint256(val))) - 1;
      observerToOwner[id] = msg.sender;
      ownerObserverCount[msg.sender]++;
     
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
      require(observers[_tokenId].value == amount,  "wrong price");
      
    
      seller.transfer(amount); 
      ownerObserverCount[seller] = ownerObserverCount[seller].sub(1);
      ownerObserverCount[_to] = ownerObserverCount[_to].add(1);
      observerToOwner[_tokenId] = _to;
      
      tokenIdToPrice[_tokenId] = 0;
      observers[_tokenId].value = 0;
      emit Transfer(seller, _to, _tokenId);
  }
  
  function sell(uint256 _tokenId, uint256 _price) external {
       require(_price > 0,'Price its too low');
       require(msg.sender == ownerOf(_tokenId),"not owner");
      
       tokenIdToPrice[_tokenId] = _price;
       observers[_tokenId].value = _price;
  }
  
  function cancelSell(uint256 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId),"not owner");
        require(tokenIdToPrice[_tokenId] > 0 ,"this token is not for sell alrealdy");
        tokenIdToPrice[_tokenId] = 0;
  }
  
  function checkTokenPriceById(uint256 _tokenId) public view returns (uint256 _price){
      return tokenIdToPrice[_tokenId];
  }
  
  function upObserverlevel(uint256 _tokenId) external {
       require(msg.sender == ownerOf(_tokenId),"not owner");
       observers[_tokenId].level = observers[_tokenId].level + 1;
  }
  
  function setObserverMax(uint256 _maxCnt) external {
      require(_maxCnt > 0,"max_cnt cant less than 0");
      observerMax = _maxCnt;
  }
  
  
  function getObserverTotCnt()public view returns (uint256){
      return observers.length;
  }
  
  function getObserverInfo (uint256 _tokenId) public view returns (string memory tokenName,uint256 quality ,uint256 level,string memory url,string memory animationUrl,string memory background,uint256 watch_limit,uint256 value){
      tokenName = observers[_tokenId].token_name;
      quality = observers[_tokenId].quality;
      level = observers[_tokenId].level;
      url = observers[_tokenId].url;
      animationUrl = observers[_tokenId].animation_url;
      background = observers[_tokenId].background;
      value = observers[_tokenId].value;
      watch_limit = observers[_tokenId].ability.watch_limit;
      return (tokenName,quality,level,url,animationUrl,background,watch_limit,value);
  }
  
  function getObserverAbility(uint256 _tokenId) public view returns (uint256 watch_limit){
      watch_limit = observers[_tokenId].ability.watch_limit;
      return watch_limit;
  }
  
  function getAllObserverOnMarket() public view returns (uint[] memory token_ids){
    uint[] memory result = new uint[](observers.length);
    uint counter = 0;
    for (uint i = 0; i < observers.length; i++) {
      if (observers[i].value > 0) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }
  
  function setObserverTokenName(uint256 _tokenId, string calldata newName) external {
      require(msg.sender == ownerOf(_tokenId),"not owner");
      require(tokenIdToPrice[_tokenId] == 0,"this observer list in market");
      observers[_tokenId].token_name = newName;
  }
  
  function seeObserverCount () public view returns (uint256) {
      return observers.length;    
  }
  
  function setObserverUrl(uint256 _tokenId, string calldata newUrl) external {
      require(msg.sender == ownerOf(_tokenId),"not owner");
      require(tokenIdToPrice[_tokenId] == 0,"this observer list in market");
      observers[_tokenId].url = newUrl;
  }
  
  function setObserverAnimation(uint256 _tokenId, string calldata newAnimationUrl) external {
      require(msg.sender == ownerOf(_tokenId),"not owner");
      require(tokenIdToPrice[_tokenId] == 0,"this observer list in market");
      observers[_tokenId].animation_url = newAnimationUrl;
  }
 
}