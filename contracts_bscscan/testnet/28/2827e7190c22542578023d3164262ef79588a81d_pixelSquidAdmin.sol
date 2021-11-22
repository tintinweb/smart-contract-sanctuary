/**
 *Submitted for verification at BscScan.com on 2021-11-21
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
contract pixelSquidAdmin is  ERC721,Ownables {

  using SafeMath for uint256;
  string public name_ = "admin";
  struct Ability {
    uint256 hold_limit;
  }
  
  struct admin {
    string token_name;
    uint256 quality; //admin's quality (1: common ,2: rare)
    uint256 level; //admin's level;
    string url; //admin's image url
    string background; //admin's background url
    string animation_url;//admin's animation url(only for rare lv.)
    Ability ability;
    uint256 value;//admin current value; unit: BNB
  }

  admin[] admins;
  string public symbol_ = "admin";
  uint256 adminMax = 2000;
  uint[] market;

  mapping (uint => address) public adminToOwner; //every admin hava a unique id,call this mapping can found owner
  mapping (address => uint) ownerAdminCount; //return address owner admin counts
  mapping (uint => address) adminApprovals; //follow ERC721,allow admin transfer to someone
  mapping (uint256 => uint256) public tokenIdToPrice;

 
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _from, address indexed _to,uint indexed _tokenId);
  event Take(address _to, address _from,uint _tokenId);
  event Create(string token_name, uint256 quality,uint256 level, string url,string animation_url,string background,uint256 hold_limit,uint256 value);

  function name() external view returns (string memory) {
        return name_;
  }

  function symbol() external view returns (string memory) {
        return symbol_;
  }

  function totalSupply() public view returns (uint256) {
    return adminMax;
  }

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerAdminCount[_owner]; // show someone balance
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return adminToOwner[_tokenId]; // show someone admin's owner
  }

  function checkAllOwner(uint[] memory _tokenId, address owner) public view returns (bool) {
    for(uint i=0;i<_tokenId.length;i++){
        if(owner != adminToOwner[_tokenId[i]]){
            return false;   //check owner by admin 
        }
    }
    
    return true;
  }

  function seeAdminTokenName(uint256 _tokenId) public view returns (string memory token_name) {
    return admins[_tokenId].token_name;
  }
  
  function seeAdminQuality(uint256 _tokenId) public view returns (uint256 quality) {
    return admins[_tokenId].quality;
  }
  
  function seeAdminLevel(uint256 _tokenId) public view returns (uint256 level) {
    return admins[_tokenId].level;
  }
  
  function seeAdminURL(uint256 _tokenId) public view returns (string memory url){
      return admins[_tokenId].url;
  }
  
  function seeAdminAnimation(uint256 _tokenId) public view returns(string memory animation_url){
      return admins[_tokenId].animation_url;
  }
  
  function seeAdminBackground(uint256 _tokenId) public view returns(string memory background){
      return admins[_tokenId].background;
  }
  
  function seeAdminValue(uint256 _tokenId) public view returns (uint256 value){
      return admins[_tokenId].value;
  }
  
  function seeAdminHoldLimit(uint256 _tokenId) public view returns (uint256 hold_limit) {
    return admins[_tokenId].ability.hold_limit;
  }
  
  function getAdminByOwner(address _owner) external view returns(uint[] memory) { 
    uint[] memory result = new uint[](ownerAdminCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < admins.length; i++) {
      if (adminToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

  function transfer(address _to, uint256 _tokenId) public {

    require(adminToOwner[_tokenId] == msg.sender);
    
  
    ownerAdminCount[msg.sender] = ownerAdminCount[msg.sender].sub(1);
 
    ownerAdminCount[_to] = ownerAdminCount[_to].add(1);
   
    adminToOwner[_tokenId] = _to;
    
    emit Transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public {
    require(adminToOwner[_tokenId] == msg.sender);
    
    adminApprovals[_tokenId] = _to;
    
    emit Approval(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external {
    // Safety check to prevent against an unexpected 0x0 default.
    require(adminToOwner[_tokenId] == _from);
    require(adminApprovals[_tokenId] == _to);
    
    adminApprovals[_tokenId] = address(0);
    ownerAdminCount[_from] = ownerAdminCount[_from].sub(1);
    ownerAdminCount[_to] = ownerAdminCount[_to].add(1);
    adminToOwner[_tokenId] = _to;
    
    emit Transfer(_from, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public {
    require(adminToOwner[_tokenId] == msg.sender);
    
    address owner = ownerOf(_tokenId);

    ownerAdminCount[msg.sender] = ownerAdminCount[msg.sender].add(1);
    ownerAdminCount[owner] = ownerAdminCount[owner].sub(1);
    adminToOwner[_tokenId] = msg.sender;
    
    emit Take(msg.sender, owner, _tokenId);
  }
  
  function recruitAdmin(string memory _token_name ,uint256 _quality,uint256 _lv, string memory _url, string memory _animation_url,string memory _background,uint256 _hold_limit, uint256 _val) public {
      
      require(admins.length < adminMax,"admin its full");
      require(_lv > 0 ,"wrong admin's level");

      require(_hold_limit > 0 ,"hold_limit cant less than 0");
      require(_quality>0,"quality cant than 0");
      
      string memory token_name = _token_name;
      uint256 quality = _quality;
      uint256 level = _lv;
      string memory url = _url;
      string memory animation_url = _animation_url;
      string memory background = _background;
      
      uint256 val = _val;
      
      Ability memory ability = Ability(_hold_limit);
      
    
      uint256 id = admins.push(admin(token_name,quality, level,url,animation_url,background,ability,uint256(val))) - 1;
      adminToOwner[id] = msg.sender;
      ownerAdminCount[msg.sender]++;
      transfer(msg.sender,id);
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
      require(admins[_tokenId].value == amount,  "wrong price");
      
    
      seller.transfer(amount); 
      ownerAdminCount[seller] = ownerAdminCount[seller].sub(1);
      ownerAdminCount[_to] = ownerAdminCount[_to].add(1);
      adminToOwner[_tokenId] = _to;
      
      tokenIdToPrice[_tokenId] = 0;
      admins[_tokenId].value = 0;
      emit Transfer(seller, _to, _tokenId);
  }
  
  function sell(uint256 _tokenId, uint256 _price) external {
       require(_price > 0,'Price its too low');
       require(msg.sender == ownerOf(_tokenId),"not owner");
      
       tokenIdToPrice[_tokenId] = _price;
       admins[_tokenId].value = _price;
  }
  
  function cancelSell(uint256 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId),"not owner");
        require(tokenIdToPrice[_tokenId] > 0 ,"this token is not for sell alrealdy");
        tokenIdToPrice[_tokenId] = 0;
  }
  
  function checkTokenPriceById(uint256 _tokenId) public view returns (uint256 _price){
      return tokenIdToPrice[_tokenId];
  }
  
  function upAdminlevel(uint256 _tokenId) external {
       require(msg.sender == ownerOf(_tokenId),"not owner");
       admins[_tokenId].level = admins[_tokenId].level + 1;
  }
  
  function setAdminMax(uint256 _maxCnt) external {
      require(_maxCnt > 0,"max_cnt cant less than 0");
      adminMax = _maxCnt;
  }
  
  
  function getAdminTotCnt()public view returns (uint256){
      return admins.length;
  }
  
  function getAdminInfo (uint256 _tokenId) public view returns (string memory tokenName,uint256 quality ,uint256 level,string memory url,string memory animationUrl,string memory background,uint256 hold_limit,uint256 value){
      tokenName = admins[_tokenId].token_name;
      quality = admins[_tokenId].quality;
      level = admins[_tokenId].level;
      url = admins[_tokenId].url;
      animationUrl = admins[_tokenId].animation_url;
      background = admins[_tokenId].background;
      value = admins[_tokenId].value;
      hold_limit = admins[_tokenId].ability.hold_limit;
      return (tokenName,quality,level,url,animationUrl,background,hold_limit,value);
  }
  
  function getAdminAbility(uint256 _tokenId) public view returns (uint256 hold_limit){
      hold_limit = admins[_tokenId].ability.hold_limit;
      return hold_limit;
  }
  
  function getAllAdminOnMarket() public view returns (uint[] memory token_ids){
    uint[] memory result = new uint[](admins.length);
    uint counter = 0;
    for (uint i = 0; i < admins.length; i++) {
      if (admins[i].value > 0) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }
  
  function setAdminTokenName(uint256 _tokenId, string calldata newName) external {
      require(msg.sender == ownerOf(_tokenId),"not owner");
      require(tokenIdToPrice[_tokenId] == 0,"this admin list in market");
      admins[_tokenId].token_name = newName;
  }
  
  function seeAdminCount () public view returns (uint256) {
      return admins.length;    
  }
  
  function setAdminUrl(uint256 _tokenId, string calldata newUrl) external {
      require(msg.sender == ownerOf(_tokenId),"not owner");
      require(tokenIdToPrice[_tokenId] == 0,"this admin list in market");
      admins[_tokenId].url = newUrl;
  }
  
  function setAdminAnimation(uint256 _tokenId, string calldata newAnimationUrl) external {
      require(msg.sender == ownerOf(_tokenId),"not owner");
      require(tokenIdToPrice[_tokenId] == 0,"this admin list in market");
      admins[_tokenId].animation_url = newAnimationUrl;
  }
 
}