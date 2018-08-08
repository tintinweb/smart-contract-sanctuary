pragma solidity ^0.4.18;

/**
 * @title ERC721 interface
 * @dev see https://github.com/ethereum/eips/issues/721
 */
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  mapping (address => bool) public admins;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
    admins[owner] = true;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  modifier onlyAdmin() {
    require(admins[msg.sender]);
    _;
  }

  function changeAdmin(address _newAdmin, bool _approved) onlyOwner public {
    admins[_newAdmin] = _approved;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

/**
 * @title ERC721Token
 * Generic implementation for the required functionality of the ERC721 standard
 */
contract ArkToken is ERC721, Ownable {
  using SafeMath for uint256;

  // Total amount of tokens
  uint256 private totalTokens;
  uint256 public developerCut;

  // Animal Data
  mapping (uint256 => Animal) public arkData;

  // Mapping from token ID to owner
  mapping (uint256 => address) private tokenOwner;

  // mom ID => baby ID
  mapping (uint256 => uint256) public babies;
  
  // baby ID => parents
  mapping (uint256 => uint256[2]) public babyMommas;
  
  // token ID => their baby-makin&#39; partner
  mapping (uint256 => uint256) public mates;

  // baby ID => sum price of mom and dad needed to make this babby
  mapping (uint256 => uint256) public babyMakinPrice;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private tokenApprovals;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) private ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private ownedTokensIndex;

  // Balances from % payouts.
  mapping (address => uint256) public birtherBalances; 

  // Events
  event Purchase(uint256 indexed _tokenId, address indexed _buyer, address indexed _seller, uint256 _purchasePrice);
  event Birth(address indexed _birther, uint256 indexed _mom, uint256 _dad, uint256 indexed _baby);

  // Purchasing Caps for Determining Next Pool Cut
  uint256 private firstCap  = 0.5 ether;
  uint256 private secondCap = 1.0 ether;
  uint256 private thirdCap  = 1.5 ether;
  uint256 private finalCap  = 3.0 ether;

  // Struct to store Animal Data
  struct Animal {
    uint256 price;         // Current price of the item.
    uint256 lastPrice;     // Last price needed to calculate whether baby-makin&#39; limit has made it
    address owner;         // Current owner of the item.
    address birther;       // Address that birthed the animal.
    uint256 birtherPct;    // Percent that birther will get for sales. The actual percent is this / 10.
    uint8 gender;          // Gender of this animal: 0 for male, 1 for female.
  }

  function createToken(uint256 _tokenId, uint256 _startingPrice, uint256 _cut, address _owner, uint8 _gender) onlyAdmin() public {
    // make sure price > 0
    require(_startingPrice > 0);
    // make sure token hasn&#39;t been used yet
    require(arkData[_tokenId].price == 0);
    
    // create new token
    Animal storage curAnimal = arkData[_tokenId];

    curAnimal.owner = _owner;
    curAnimal.price = _startingPrice;
    curAnimal.lastPrice = _startingPrice;
    curAnimal.gender = _gender;
    curAnimal.birther = _owner;
    curAnimal.birtherPct = _cut;

    // mint new token
    _mint(_owner, _tokenId);
  }

  function createMultiple (uint256[] _itemIds, uint256[] _prices, uint256[] _cuts, address[] _owners, uint8[] _genders) onlyAdmin() external {
    for (uint256 i = 0; i < _itemIds.length; i++) {
      createToken(_itemIds[i], _prices[i], _cuts[i], _owners[i], _genders[i]);
    }
  }

  function createBaby(uint256 _dad, uint256 _mom, uint256 _baby, uint256 _price) public onlyAdmin() 
  {
      mates[_mom] = _dad;
      mates[_dad] = _mom;
      babies[_mom] = _baby;
      babyMommas[_baby] = [_mom, _dad];
      babyMakinPrice[_baby] = _price;
  }
  
  function createBabies(uint256[] _dads, uint256[] _moms, uint256[] _babies, uint256[] _prices) external onlyAdmin() {
      require(_moms.length == _babies.length && _babies.length == _dads.length);
      for (uint256 i = 0; i < _moms.length; i++) {
          createBaby(_dads[i], _moms[i], _babies[i], _prices[i]);
      }
  }

  /**
  * @dev Determines next price of token
  * @param _price uint256 ID of current price
  */
  function getNextPrice (uint256 _price) private view returns (uint256 _nextPrice) {
    if (_price < firstCap) {
      return _price.mul(150).div(95);
    } else if (_price < secondCap) {
      return _price.mul(135).div(96);
    } else if (_price < thirdCap) {
      return _price.mul(125).div(97);
    } else if (_price < finalCap) {
      return _price.mul(117).div(97);
    } else {
      return _price.mul(115).div(98);
    }
  }

  /**
  * @dev Purchase animal from previous owner
  * @param _tokenId uint256 of token
  */
  function buyToken(uint256 _tokenId) public 
    payable
    isNotContract(msg.sender)
  {

    // get data from storage
    Animal storage animal = arkData[_tokenId];
    uint256 price = animal.price;
    address oldOwner = animal.owner;
    address newOwner = msg.sender;
    uint256 excess = msg.value.sub(price);

    // revert checks
    require(price > 0);
    require(msg.value >= price);
    require(oldOwner != msg.sender);
    require(oldOwner != address(0) && oldOwner != address(1)); // We&#39;re gonna put unbirthed babbies at 0x1
    
    uint256 totalCut = price.mul(4).div(100);
    
    uint256 birtherCut = price.mul(animal.birtherPct).div(1000); // birtherPct is % * 10 so we / 1000
    birtherBalances[animal.birther] = birtherBalances[animal.birther].add(birtherCut);
    
    uint256 devCut = totalCut.sub(birtherCut);
    developerCut = developerCut.add(devCut);

    transferToken(oldOwner, newOwner, _tokenId);

    // raise event
    Purchase(_tokenId, newOwner, oldOwner, price);

    // set new prices
    animal.price = getNextPrice(price);
    animal.lastPrice = price;

    // Transfer payment to old owner minus the developer&#39;s and birther&#39;s cut.
    oldOwner.transfer(price.sub(totalCut));
    // Send refund to owner if needed
    if (excess > 0) {
      newOwner.transfer(excess);
    }
    
    checkBirth(_tokenId);
  }
  
  /**
   * @dev Check to see whether a newly purchased animal should give birth.
   * @param _tokenId Unique ID of the newly transferred animal.
  */
  function checkBirth(uint256 _tokenId)
    internal
  {
    uint256 mom = 0;
    
    // gender 0 = male, 1 = female
    if (arkData[_tokenId].gender == 0) {
      mom = mates[_tokenId];
    } else {
      mom = _tokenId;
    }
    
    if (babies[mom] > 0) {
      if (tokenOwner[mates[_tokenId]] == msg.sender) {
        // Check if the sum price to make a baby for these mates has been passed.
        uint256 sumPrice = arkData[_tokenId].lastPrice + arkData[mates[_tokenId]].lastPrice;
        if (sumPrice >= babyMakinPrice[babies[mom]]) {
          autoBirth(babies[mom]);
          
          Birth(msg.sender, mom, mates[mom], babies[mom]);
          babyMakinPrice[babies[mom]] = 0;
          babies[mom] = 0;
          mates[mates[mom]] = 0;
          mates[mom] = 0;
        }
      }
    }
  }
  
  /**
   * @dev Internal function to birth a baby if an owner has both mom and dad.
   * @param _baby Token ID of the baby to birth.
  */
  function autoBirth(uint256 _baby)
    internal
  {
    Animal storage animal = arkData[_baby];
    animal.birther = msg.sender;
    transferToken(animal.owner, msg.sender, _baby);
  }

  /**
  * @dev Transfer Token from Previous Owner to New Owner
  * @param _from previous owner address
  * @param _to new owner address
  * @param _tokenId uint256 ID of token
  */
  function transferToken(address _from, address _to, uint256 _tokenId) internal {
    // check token exists
    require(tokenExists(_tokenId));

    // make sure previous owner is correct
    require(arkData[_tokenId].owner == _from);

    require(_to != address(0));
    require(_to != address(this));

    // clear approvals linked to this token
    clearApproval(_from, _tokenId);

    // remove token from previous owner
    removeToken(_from, _tokenId);

    // update owner and add token to new owner
    addToken(_to, _tokenId);

   //raise event
    Transfer(_from, _to, _tokenId);
  }

  /**
  * @dev Withdraw dev&#39;s cut
  */
  function withdraw(uint256 _amount) public onlyAdmin() {
    if (_amount == 0) { 
      _amount = developerCut; 
    }
    developerCut = developerCut.sub(_amount);
    owner.transfer(_amount);
  }

  /**
   * @dev Withdraw anyone&#39;s birther balance.
   * @param _beneficiary The person whose balance shall be sent to them.
  */
  function withdrawBalance(address _beneficiary) external {
    uint256 payout = birtherBalances[_beneficiary];
    birtherBalances[_beneficiary] = 0;
    _beneficiary.transfer(payout);
  }

  /**
   * @dev Return all relevant data for an animal.
   * @param _tokenId Unique animal ID.
  */
  function getArkData (uint256 _tokenId) external view 
  returns (address _owner, uint256 _price, uint256 _nextPrice, uint256 _mate, 
           address _birther, uint8 _gender, uint256 _baby, uint256 _babyPrice) 
  {
    Animal memory animal = arkData[_tokenId];
    uint256 baby;
    if (animal.gender == 1) baby = babies[_tokenId];
    else baby = babies[mates[_tokenId]];
    
    return (animal.owner, animal.price, getNextPrice(animal.price), mates[_tokenId], 
            animal.birther, animal.gender, baby, babyMakinPrice[baby]);
  }
  
  /**
   * @dev Get sum price required to birth baby.
   * @param _babyId Unique baby Id.
  */
  function getBabyMakinPrice(uint256 _babyId) external view
  returns (uint256 price)
  {
    price = babyMakinPrice[_babyId];
  }

  /**
   * @dev Get the parents of a certain baby.
   * @param _babyId Unique baby Id.
  */
  function getBabyMommas(uint256 _babyId) external view
  returns (uint256[2] parents)
  {
    parents = babyMommas[_babyId];
  }
  
  /**
   * @dev Frontend can use this to find the birther percent for animal.
   * @param _tokenId The unique id for the animal.
  */
  function getBirthCut(uint256 _tokenId) external view
  returns (uint256 birthCut)
  {
    birthCut = arkData[_tokenId].birtherPct;
  }

  /**
   * @dev Check the birther balance of a certain address.
   * @param _owner The address to check the balance of.
  */
  function checkBalance(address _owner) external view returns (uint256) {
    return birtherBalances[_owner];
  }

  /**
  * @dev Determines if token exists by checking it&#39;s price
  * @param _tokenId uint256 ID of token
  */
  function tokenExists (uint256 _tokenId) public view returns (bool _exists) {
    return arkData[_tokenId].price > 0;
  }

  /**
  * @dev Guarantees msg.sender is owner of the given token
  * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
  */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
  * @dev Guarantees msg.sender is not a contract
  * @param _buyer address of person buying animal
  */
  modifier isNotContract(address _buyer) {
    uint size;
    assembly { size := extcodesize(_buyer) }
    require(size == 0);
    _;
  }


  /**
  * @dev Gets the total amount of tokens stored by the contract
  * @return uint256 representing the total amount of tokens
  */
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

  /**
  * @dev Gets the balance of the specified address
  * @param _owner address to query the balance of
  * @return uint256 representing the amount owned by the passed address
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

  /**
  * @dev Gets the list of tokens owned by a given address
  * @param _owner address to query the tokens of
  * @return uint256[] representing the list of tokens owned by the passed address
  */
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

  /**
  * @dev Gets the owner of the specified token ID
  * @param _tokenId uint256 ID of the token to query the owner of
  * @return owner address currently marked as the owner of the given token ID
  */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    return owner;
  }

  /**
   * @dev Gets the approved address to take ownership of a given token ID
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved to take ownership of the given token ID
   */
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
  * @dev Transfers the ownership of a given token ID to another address
  * @param _to address to receive the ownership of the given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

  /**
  * @dev Approves another address to claim for the ownership of the given token ID
  * @param _to address to be approved for the given token ID
  * @param _tokenId uint256 ID of the token to be approved
  */
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

  /**
  * @dev Claims the ownership of a given token ID
  * @param _tokenId uint256 ID of the token being claimed by the msg.sender
  */
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

  /**
   * @dev Tells whether the msg.sender is approved for the given token ID or not
   * This function is not private so it can be extended in further implementations like the operatable ERC721
   * @param _owner address of the owner to query the approval of
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return bool whether the msg.sender is approved for the given token ID or not
   */
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }
  
  /**
  * @dev Internal function to clear current approval and transfer the ownership of a given token ID
  * @param _from address which you want to send tokens from
  * @param _to address which you want to transfer the token to
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal isNotContract(_to) {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

  /**
  * @dev Internal function to clear current approval of a given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    Approval(_owner, 0, _tokenId);
  }


    /**
  * @dev Mint token function
  * @param _to The address that will own the minted token
  * @param _tokenId uint256 ID of the token to be minted by the msg.sender
  */
  function _mint(address _to, uint256 _tokenId) internal {
    addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

  /**
  * @dev Internal function to add a token ID to the list of a given address
  * @param _to address representing the new owner of the given token ID
  * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
  */
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    arkData[_tokenId].owner = _to;
    
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

  /**
  * @dev Internal function to remove a token ID from the list of a given address
  * @param _from address representing the previous owner of the given token ID
  * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
  */
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }

  function name() public pure returns (string _name) {
    return "EthersArk Token";
  }

  function symbol() public pure returns (string _symbol) {
    return "EARK";
  }

}