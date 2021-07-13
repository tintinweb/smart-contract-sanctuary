/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

pragma solidity 0.6.12;

// SPDX-License-Identifier: BSD-3-Clause

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
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
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

// Modern ERC20 Token interface
interface IERC20 {
    function transfer(address to, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

// Modern ERC721 Token interface
interface IERC721 {
    function transferFrom(address from, address to, uint tokenId) external;
    function mint(address to) external;
}

contract NFT_Market is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.UintSet;

    // =========== Start Smart Contract Setup ==============
    
    // MUST BE CONSTANT - THE FEE TOKEN ADDRESS AND NFT ADDRESS
    // the below addresses are trusted and constant so no issue of re-entrancy happens
    address public constant trustedFeeTokenAddress = 0xc9d58eB97B96DA277cDD67EF9E0a764b9ad1105b;
    address public constant trustedNftAddress = 0x5F2Cf4da0722d320a7eBE0ea03746f0A8Cd3bAdD;
    
    // minting fee in token, 10 tokens (10e18 because token has 18 decimals)
    uint public mintFee = 10e18;
    
    // selling fee rate
    uint public sellingFeeRateX100 = 30;
    
    // ============ End Smart Contract Setup ================
    
    // ---------------- owner modifier functions ------------------------
    function setMintFee(uint _mintFee) public onlyOwner {
        mintFee = _mintFee;
    }
    function setSellingFeeRateX100(uint _sellingFeeRateX100) public onlyOwner {
        sellingFeeRateX100 = _sellingFeeRateX100;
    }
    
    // --------------- end owner modifier functions ---------------------
    
    enum PriceType {
        ETHER,
        TOKEN
    }
    
    event List(uint tokenId, uint price, PriceType priceType);
    event Unlist(uint tokenId);
    event Buy(uint tokenId);
    
     
    EnumerableSet.UintSet private nftsForSaleIds;
    
    // nft id => nft price
    mapping (uint => uint) private nftsForSalePrices;
    // nft id => nft owner
    mapping (uint => address) private nftOwners;
    // nft id => ETHER | TOKEN
    mapping (uint => PriceType) private priceTypes;
    
    // nft owner => nft id set
    mapping (address => EnumerableSet.UintSet) private nftsForSaleByAddress;
    
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return nftsForSaleByAddress[owner].length();
    }
    function totalListed() public view returns (uint256) {
        return nftsForSaleIds.length();
    }

    function getToken(uint tokenId) public view returns (uint _tokenId, uint _price, address _owner, PriceType _priceType) {
        _tokenId = tokenId;
        _price = nftsForSalePrices[tokenId];
        _owner = nftOwners[tokenId];
        _priceType = priceTypes[tokenId];
    }
    
    function getTokens(uint startIndex, uint endIndex) public view returns 
        (uint[] memory _tokens, uint[] memory _prices, address[] memory _owners, PriceType[] memory _priceTypes) {
        require(startIndex < endIndex, "Invalid indexes supplied!");
        uint len = endIndex.sub(startIndex);
        require(len <= totalListed(), "Invalid length!");
        
        _tokens = new uint[](len);
        _prices = new uint[](len);
        _owners = new address[](len);
        _priceTypes = new PriceType[](len);
        
        for (uint i = startIndex; i < endIndex; i = i.add(1)) {
            uint listIndex = i.sub(startIndex);
            
            uint tokenId = nftsForSaleIds.at(i);
            uint price = nftsForSalePrices[tokenId];
            address nftOwner = nftOwners[tokenId];
            PriceType priceType = priceTypes[tokenId];
            
            _tokens[listIndex] = tokenId;
            _prices[listIndex] = price;
            _owners[listIndex] = nftOwner;
            _priceTypes[listIndex] = priceType;
        }
    }
    
    // overloaded getTokens to allow for getting seller tokens
    // _owners array not needed but returned for interface consistency
    // view function so no gas is used
    function getTokens(address seller, uint startIndex, uint endIndex) public view returns
        (uint[] memory _tokens, uint[] memory _prices, address[] memory _owners, PriceType[] memory _priceTypes) {
        require(startIndex < endIndex, "Invalid indexes supplied!");
        uint len = endIndex.sub(startIndex);
        require(len <= balanceOf(seller), "Invalid length!");
        
        _tokens = new uint[](len);
        _prices = new uint[](len);
        _owners = new address[](len);
        _priceTypes = new PriceType[](len);
        
        for (uint i = startIndex; i < endIndex; i = i.add(1)) {
            uint listIndex = i.sub(startIndex);
            
            uint tokenId = nftsForSaleByAddress[seller].at(i);
            uint price = nftsForSalePrices[tokenId];
            address nftOwner = nftOwners[tokenId];
            PriceType priceType = priceTypes[tokenId];
            
            _tokens[listIndex] = tokenId;
            _prices[listIndex] = price;
            _owners[listIndex] = nftOwner;
            _priceTypes[listIndex] = priceType;
        }
    }
    
    function mint() public {
        // owner can mint without fee
        // other users need to pay a fixed fee in token
        if (msg.sender != owner) {
            require(IERC20(trustedFeeTokenAddress).transferFrom(msg.sender, owner, mintFee), "Could not transfer mint fee!");
        }
        
        IERC721(trustedNftAddress).mint(msg.sender);
    }
    
    function list(uint tokenId, uint price, PriceType priceType) public {
        IERC721(trustedNftAddress).transferFrom(msg.sender, address(this), tokenId);
        
        nftsForSaleIds.add(tokenId);
        nftsForSaleByAddress[msg.sender].add(tokenId);
        nftOwners[tokenId] = msg.sender;
        nftsForSalePrices[tokenId] = price;
        priceTypes[tokenId] = priceType;
        
        emit List(tokenId, price, priceType);
    }
    
    function unlist(uint tokenId) public {
        require(nftsForSaleIds.contains(tokenId), "Trying to unlist an NFT which is not listed yet!");
        address nftOwner = nftOwners[tokenId];
        require(nftOwner == msg.sender, "Cannot unlist other's NFT!");
        
        nftsForSaleIds.remove(tokenId);
        nftsForSaleByAddress[msg.sender].remove(tokenId);
        delete nftOwners[tokenId];
        delete nftsForSalePrices[tokenId];
        delete priceTypes[tokenId];
        
        IERC721(trustedNftAddress).transferFrom(address(this), msg.sender, tokenId);
        emit Unlist(tokenId);
    }

    function buy(uint tokenId) public payable {
        require(nftsForSaleIds.contains(tokenId), "Trying to unlist an NFT which is not listed yet!");
        address payable nftOwner = address(uint160(nftOwners[tokenId]));
        address payable _owner = address(uint160(owner));
        
        uint price = nftsForSalePrices[tokenId];
        uint fee = price.mul(sellingFeeRateX100).div(1e4);
        uint amountAfterFee = price.sub(fee);
        PriceType _priceType = priceTypes[tokenId];
    
        nftsForSaleIds.remove(tokenId);
        nftsForSaleByAddress[nftOwners[tokenId]].remove(tokenId);
        delete nftOwners[tokenId];
        delete nftsForSalePrices[tokenId];
        delete priceTypes[tokenId];
        
        if (_priceType == PriceType.ETHER) {
            require(msg.value >= price, "Insufficient ETH is transferred to purchase!");
            _owner.transfer(fee);
            nftOwner.transfer(amountAfterFee);
            // in case extra ETH is transferred, forward the extra to owner
            if (msg.value > price) {
                _owner.transfer(msg.value.sub(price));                
            }
        } else if (_priceType == PriceType.TOKEN) {
            require(IERC20(trustedFeeTokenAddress).transferFrom(msg.sender, address(this), price), "Could not transfer fee to Marketplace!");
            require(IERC20(trustedFeeTokenAddress).transfer(_owner, fee), "Could not transfer purchase fee to admin!");
            require(IERC20(trustedFeeTokenAddress).transfer(nftOwner, amountAfterFee), "Could not transfer sale revenue to NFT seller!");
        } else {
            revert("Invalid Price Type!");
        }
        IERC721(trustedNftAddress).transferFrom(address(this), msg.sender, tokenId);
        emit Buy(tokenId);
    }
    
    event ERC721Received(address operator, address from, uint256 tokenId, bytes data);
    
    // ERC721 Interface Support Function
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns(bytes4) {
        require(msg.sender == trustedNftAddress);
        emit ERC721Received(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }
    
}