/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
    
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
    require(msg.sender == owner,"ERR_AUTHORIZED_OWNER_ONLY");
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0),"ERR_ZERO_ADDRESS");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
    }
 }

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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

contract RemitPresale is Ownable{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    uint256 public minDeposit;
    uint256 public maxDeposit;
    uint256 public tokenPrice;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public capAmount;
    uint256 public totalInvestment;
    uint256 public totalRemitPurchased;
    bool public isPaused;
    
    address public walletAddress;
    
    IERC20 public remit;
    constructor(address _tokenAddress,address _walletAddress)public{
        
        require(_walletAddress != address(0));
        require(_tokenAddress != address(0));
        remit = IERC20(_tokenAddress);
        walletAddress = _walletAddress;
    }
        
    
    //Mappings
    EnumerableSet.AddressSet private depositers;
    
    mapping(address => uint256)public claimableAmount;
    
    //Events
    
    event TokenPurchase(
    address indexed beneficiary,
    address indexed purchaser,
    uint256 value,
    uint256 amount
  );
  
  event TokenClaimed(
    address indexed purchaser,
    uint256 timestamp,
    uint256 amount
  );
      
    
    /*
     * @dev To start the pre sale
     * 
     * @param
     *  '_endTime' - specifies the end time of pre sale
     */
    function startPresale(uint256 _endTime)external onlyOwner{
        
        require(minDeposit != 0 && maxDeposit != 0 && tokenPrice != 0 ,"ERR_SET_MINDEPOSIT_MAXDEPOSIT_PRICE_FIRST");
        require(capAmount != 0,"ERR_CAP_AMOUNT_CANNOT_BE_0");
        require(_endTime > now , "ERR_PRESALE_ENDTIME_CANNOT_BE_CURRENT_TIME");
        
        startTime = now;
        endTime = _endTime;
        isPaused = false;
    }
    
     /*
     * @dev To buy the tokens
     *
     */
    function buyToken()public payable {
        
       address _buyer = msg.sender;
       uint256 _ethDeposited = msg.value;
       
       require(startTime != 0,"ERR_PRESALE_HAS_NOT_STARTED");
       require(now < endTime,"ERR_PRESALE_ENDED");
       require(!isPaused,"ERR_PRESALE_IS_PAUSED");
       require(_ethDeposited >= minDeposit && _ethDeposited <= maxDeposit,"ERR_AMOUNT_TOO_SMALL_OR_TOO_BIG");
       require(totalInvestment.add(_ethDeposited) <= capAmount,"ERR_CAP_HIT_CANNOT_ACCEPT");
       require(remit.balanceOf(address(this)) != 0,"ERR_TOKENS_SOLD_OUT");
       
       uint256 amount = _calculateTokens(_ethDeposited);
     
       if(!depositers.contains(_buyer)) depositers.add(_buyer);
       claimableAmount[_buyer] = claimableAmount[_buyer].add(amount);
     
       totalInvestment = totalInvestment.add(_ethDeposited);
        
       emit TokenPurchase(address(this),_buyer,_ethDeposited,amount);
    }
    
    /*
     * @dev To claim the tokens
     *
     */
    function claim()external  {
        
       address _buyer = msg.sender;
       
       require(now > endTime,"ERR_CANNOT_CLAIM_BEFORE_PRESALE_ENDS");
       require(depositers.contains(_buyer),"ERR_NOT_AUTHORIZED_TO_CLAIM");
       require(claimableAmount[_buyer] != 0,"ERR_NO_AMOUNT_TO_CLAIM");
       
       uint256 amount = claimableAmount[_buyer];
       
       require(remit.transfer(_buyer,amount),"ERR_TRANSFER_FAILED");
       
       claimableAmount[_buyer] = 0;
       depositers.remove(_buyer);
       
       emit TokenClaimed(_buyer,now,amount);
    }
    
    //To get number of tokens relevant to eth deposited
    function _calculateTokens(uint256 _ethDeposited)internal returns(uint256){
        uint256 tokens = (_ethDeposited).mul(1e18).div(tokenPrice);
        totalRemitPurchased = totalRemitPurchased.add(tokens);
        return tokens;
    }
    
     /*
     * @dev To withdraw the eth deposited
     *
     */
    function withdrawDepositedEth()external onlyOwner{
        (bool success,) = walletAddress.call{value:totalInvestment}(new bytes(0));
        require(success,"ERR_TRANSFER_FAILED");
        
        totalInvestment = 0;
    }
    
     /*
     * @dev To set minium deposit limit
     * 
     * @param
     *  '_minamount' - specifies minimum amount to be deposited
     */
    function setMinDeposit(uint256 _minamount)external onlyOwner{
        minDeposit = _minamount;
    }
    
     /*
     * @dev To set maximum deposit limit
     * 
     * @param
     *  '_maxamount' - specifies maximum amount can be deposited
     */
    function setMaxDeposit(uint256 _maxamount)external onlyOwner{
        maxDeposit = _maxamount;
    }
    
     /*
     * @dev To set token price
     * 
     * @param
     *  '_price' - specifies token price
     */
    function setPrice(uint _price)external onlyOwner{
        tokenPrice = _price;
    }
    
    /*
     * @dev To set cap limit
     * 
     * @param
     *  '_limit' - specifies cap limit
     */
    function setCap(uint _limit)external onlyOwner{
        capAmount = _limit;
    }
    
     /*
     * @dev To set wallet address where eth will be transferred
     * 
     * @param
     *  '_walletAddress' - specifies address of user
     */
    function setWalletAddress(address _walletAddress)external onlyOwner{
        walletAddress = _walletAddress;
    }
    
    /*
     * @dev To pauseor unpause the pre sale
     * 
     * @param
     *  '_val' - specifies the boolean value
     */
    function isPausable(bool _val)external onlyOwner{
        isPaused = _val;
    }
    
    receive () payable external {
      buyToken();
    }
    
    fallback () payable external {
       buyToken();
    }
   
}