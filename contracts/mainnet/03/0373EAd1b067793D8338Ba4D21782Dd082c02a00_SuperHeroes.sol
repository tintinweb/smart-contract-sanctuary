pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

contract SuperHeroes is Pausable {
    
  /*** CONSTANTS ***/

  string public constant name = "SuperHero";
  string public constant symbol = "SH";
  
  /** VARIABLES **/
  uint256 public fee = 2;
  uint256 public snatch = 24 hours;

  /*** DATA TYPES ***/

  struct Token {
    string name;
    uint256 price;
    uint256 purchased;
  }

  /*** STORAGE ***/

  Token[] tokens;

  mapping (uint256 => address) public tokenIndexToOwner;
  mapping (address => uint256) ownershipTokenCount;
  mapping (uint256 => address) public tokenIndexToApproved;
  mapping (uint256 => Token) public herosForSale;

  /*** INTERNAL FUNCTIONS ***/

  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return tokenIndexToOwner[_tokenId] == _claimant;
  }

  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return tokenIndexToApproved[_tokenId] == _claimant;
  }

  function _approve(address _to, uint256 _tokenId) internal {
    tokenIndexToApproved[_tokenId] = _to;
  }

  function _transfer(address _from, address _to, uint256 _tokenId) internal whenNotPaused {
    ownershipTokenCount[_to]++;
    tokenIndexToOwner[_tokenId] = _to;

    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      delete tokenIndexToApproved[_tokenId];
    }
  }

  function _mint(string _name, uint256 _price) internal returns (uint256 tokenId) {
    require(tokens.length < 250, "Max amount of superheroes is reached");  
    Token memory token = Token({
      name: _name,
      price: _price,
      purchased: now
    });
    tokenId = tokens.push(token) - 1;
    
    _transfer(0, owner, tokenId);
  }


  function totalSupply() public view returns (uint256) {
    return tokens.length;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return ownershipTokenCount[_owner];
  }

  function ownerOf(uint256 _tokenId) external view returns (address owner) {
    owner = tokenIndexToOwner[_tokenId];

    require(owner != address(0));
  }

  function approve(address _to, uint256 _tokenId) external {
    require(_owns(msg.sender, _tokenId));

    _approve(_to, _tokenId);
  }

  function transfer(address _to, uint256 _tokenId) external {
    require(_to != address(0));
    require(_to != address(this));
    require(_owns(msg.sender, _tokenId));

    _transfer(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external {
    require(_to != address(0));
    require(_to != address(this));
    require(_approvedFor(msg.sender, _tokenId));
    require(_owns(_from, _tokenId));

    _transfer(_from, _to, _tokenId);
  }

  function tokensOfOwner(address _owner) external view returns (uint256[]) {
    uint256 balance = balanceOf(_owner);

    if (balance == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](balance);
      uint256 maxTokenId = totalSupply();
      uint256 idx = 0;

      uint256 tokenId;
      for (tokenId = 1; tokenId <= maxTokenId; tokenId++) {
        if (tokenIndexToOwner[tokenId] == _owner) {
          result[idx] = tokenId;
          idx++;
        }
      }
    }

    return result;
  }


  /*** EXTERNAL FUNCTIONS ***/

  function mint(string _name, uint256 _price) external onlyOwner returns (uint256) {
    uint256 pricerecalc = _price;
    return _mint(_name, pricerecalc);
  }

  function getToken(uint256 _tokenId) external view returns (string _name, uint256 _price, uint256 _purchased) {
    Token memory token = tokens[_tokenId];

    _name = token.name;
    _price = token.price;
    _purchased = token.purchased;
  }
  
  function snatchHero(uint256 _id) external payable whenNotPaused {
      require(now - tokens[_id].purchased <= snatch);
      uint256 pricerecalc = tokens[_id].price;
      require(pricerecalc <= msg.value);
      address previos = tokenIndexToOwner[_id];
      uint256 realPriceFee = msg.value * fee / 100;
      uint256 realPrice = msg.value - realPriceFee;
      uint256 newPriceRise = pricerecalc * 120 / 100;
      // owner.transfer(realPriceFee);
      previos.transfer(realPrice);
      _transfer(previos, msg.sender, _id);
      tokens[_id].purchased = now;
      tokens[_id].price = newPriceRise;
  }
  
  function buyHero(uint256 _id) external payable whenNotPaused {
      require(herosForSale[_id].price != 0);
      uint256 pricerecalc = herosForSale[_id].price;
      require(msg.value >= pricerecalc);
      // owner.transfer(msg.value);
      _transfer(owner, msg.sender, _id);
      uint256 newPriceRise = pricerecalc * 120 / 100;
      tokens[_id].purchased = now;
      tokens[_id].price = newPriceRise;
      
      delete herosForSale[_id];
  }
  
  function saleHero(uint256 _id) external onlyOwner whenNotPaused {
      require(msg.sender == tokenIndexToOwner[_id]);
      herosForSale[_id] = tokens[_id];
  }

  function changePrice(uint256 _id, uint256 _price) external whenNotPaused {
      require(msg.sender == tokenIndexToOwner[_id]);
      tokens[_id].price = _price;
  }
  
  function withdraw(address to, uint256 amount) external onlyOwner {
      to.transfer(amount);
  }
}