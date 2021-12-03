/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  function totalSupply() external view returns (uint256 total);
  function balanceOf(address _owner) external view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) external view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) external;
  function approve(address _to, uint256 _tokenId) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
}

interface IBEP20{
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
  
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

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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

//observer contract
contract pixelSquidObserver is  IERC721,Ownables {

  using SafeMath for uint256;
  string public name_ = "Observer";

  using EnumerableSet for EnumerableSet.AddressSet;
  EnumerableSet.AddressSet private _minters;
  address public inputtoken;
  struct Ability {
    uint256 watch_limit;
  }
  
  
  struct observer {
    string token_name;
    uint256 quality; //observer's quality (1: common ,2: rare,3: epic)
    uint256 level; //observer's level;
    string url; //observer's image url
    string background; //observer's background url
    string animation_url;//observer's animation url(only for rare lv.)
    Ability ability;
    uint256 value;//observer current value; unit: 
  }

  observer[] observers;
  string public symbol_ = "observer";
  uint256 observerMax = 3500;
  uint256 unitPrice = 100000000000000000000;
  uint[] market;

  mapping (uint => address) public observerToOwner; //every observer hava a unique id,call this mapping can found owner
  mapping (address => uint) ownerObserverCount; //return address owner observer counts
  mapping (uint => address) observerApprovals; //follow ERC721,allow observer transfer to someone
  mapping (uint256 => uint256) public tokenIdToPrice;



  event Take(address _to, address _from,uint _tokenId);
  event Create(string token_name, uint256 quality,uint256 level, string url,string animation_url,string background,uint256 strength,uint256 agility,uint256 intelligence,uint256 energy,uint256 stamina,uint256 value);

  function name() external override view returns (string memory) {
        return name_;
  }

  function symbol() external override view returns (string memory) {
        return symbol_;
  }

  function addMinter(address _addMinter)  public onlyOwner returns (bool) {
    require(_addMinter != address(0),"cant add zero address");
    return EnumerableSet.add(_minters, _addMinter);
  }

   function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address){
        require(_index <= getMinterLength() - 1, "observer: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "caller is not the minter");
        _;
    }

  function totalSupply() public override view returns (uint256) {
    return observerMax;
  }

  function balanceOf(address _owner) public override view returns (uint256 _balance) {
    return ownerObserverCount[_owner]; // show someone balance
  }

  function ownerOf(uint256 _tokenId) public override view returns (address _owner) {
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
  
  function seeObserverWatchLimit(uint256 _tokenId) public view returns (uint256 strength) {
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

  function transfer(address _to, uint256 _tokenId) public override {

    require(observerToOwner[_tokenId] == msg.sender);
    
  
    ownerObserverCount[msg.sender] = ownerObserverCount[msg.sender].sub(1);
 
    ownerObserverCount[_to] = ownerObserverCount[_to].add(1);
   
    observerToOwner[_tokenId] = _to;
    
    emit Transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public override{
    require(observerToOwner[_tokenId] == msg.sender);
    
    observerApprovals[_tokenId] = _to;
    
    emit Approval(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external override {
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

  function approveBusd (uint256 _amount) public {
      IBEP20(inputtoken).approve(msg.sender,_amount);
  }
  
  function recruitObserver(uint256 _amount,string memory _token_name ,uint256 _quality,uint256 _lv, string memory _url, string memory _animation_url,string memory _background,uint256 _watchLimit) external onlyMinter {
      
      require(observers.length <= observerMax,"Observer its full");
      require(_lv > 0 ,"wrong Observer's level");
      require(_quality>0,"quality cant than 0");
      require(_watchLimit >0,"wrong watch limit");
      
      IBEP20(inputtoken).transferFrom(msg.sender,address(this), _amount);  
      
    
      string memory token_name = _token_name;
      uint256 quality = _quality;
      uint256 level = _lv;
      string memory url = _url;
      string memory animation_url = _animation_url;
      string memory background = _background;
      
      Ability memory ability = Ability(_watchLimit);

      observers.push( observer(token_name,quality, level,url,animation_url,background,ability,0));
      uint256 id =  observers.length -1;
      observerToOwner[id] = msg.sender;
      ownerObserverCount[msg.sender]++;
      transfer(msg.sender,id); 
       emit Transfer(msg.sender,address(this),_amount);
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
      require( observers[_tokenId].value == amount,  "wrong price");
         
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
  
  function getObserverInfo (uint256 _tokenId) public view returns (string memory tokenName,uint256 quality ,uint256 level,string memory url,string memory animationUrl,string memory background,uint256 value){
      tokenName = observers[_tokenId].token_name;
      quality = observers[_tokenId].quality;
      level = observers[_tokenId].level;
      url = observers[_tokenId].url;
      animationUrl = observers[_tokenId].animation_url;
      background = observers[_tokenId].background;
      value = observers[_tokenId].value;
      return (tokenName,quality,level,url,animationUrl,background,value);
  }
  
  function getObserverAbility(uint256 _tokenId) public view returns (uint256 watchLimit){
       watchLimit = observers[_tokenId].ability.watch_limit;
   
      return watchLimit;
  }
  
  function getAllObserversOnMarket() public view returns (uint[] memory token_ids){
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

  function seeObserUnitPrice () public view returns (uint256) {
      return unitPrice;
  }
  
  function setObserverUrl(uint256 _tokenId, string calldata newUrl) external {
      require(msg.sender == ownerOf(_tokenId),"not owner");
      require(tokenIdToPrice[_tokenId] == 0,"this observers list in market");
      observers[_tokenId].url = newUrl;
  }
  
  function setObserverAnimation(uint256 _tokenId, string calldata newAnimationUrl) external {
      require(msg.sender == ownerOf(_tokenId),"not owner");
      require(tokenIdToPrice[_tokenId] == 0,"this observer list in market");
      observers[_tokenId].animation_url = newAnimationUrl;
  }

  function setObserverUnitPrice(uint256 _amount) public onlyOwner {
     unitPrice = _amount;
  }

  function setInputToken (address _contractAddr) public onlyOwner {
    inputtoken = _contractAddr;
  }
 
}