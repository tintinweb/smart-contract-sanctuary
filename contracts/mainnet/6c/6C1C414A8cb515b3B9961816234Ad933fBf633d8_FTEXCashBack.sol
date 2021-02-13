/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

pragma solidity 0.6.12;

// SPDX-License-Identifier: No License

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
        

        struct Set {
        
            bytes32[] _values;
    
            mapping (bytes32 => uint256) _indexes;
        }
    
        function _add(Set storage set, bytes32 value) private returns (bool) {
            if (!_contains(set, value)) {
                set._values.push(value);
                
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
                

                uint256 toDeleteIndex = valueIndex - 1;
                uint256 lastIndex = set._values.length - 1;

            
                bytes32 lastvalue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastvalue;
                set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

                set._values.pop();

                delete set._indexes[value];

                return true;
            } else {
                return false;
            }
        }

        
        function _contains(Set storage set, bytes32 value) private view returns (bool) {
            return set._indexes[value] != 0;
        }

        
        function _length(Set storage set) private view returns (uint256) {
            return set._values.length;
        }

    
        function _at(Set storage set, uint256 index) private view returns (bytes32) {
            require(set._values.length > index, "EnumerableSet: index out of bounds");
            return set._values[index];
        }

        

        struct AddressSet {
            Set _inner;
        }
    
        function add(AddressSet storage set, address value) internal returns (bool) {
            return _add(set._inner, bytes32(uint256(value)));
        }

    
        function remove(AddressSet storage set, address value) internal returns (bool) {
            return _remove(set._inner, bytes32(uint256(value)));
        }

        
        function contains(AddressSet storage set, address value) internal view returns (bool) {
            return _contains(set._inner, bytes32(uint256(value)));
        }

    
        function length(AddressSet storage set) internal view returns (uint256) {
            return _length(set._inner);
        }
    
        function at(AddressSet storage set, uint256 index) internal view returns (address) {
            return address(uint256(_at(set._inner, index)));
        }


    
        struct UintSet {
            Set _inner;
        }

        
        function add(UintSet storage set, uint256 value) internal returns (bool) {
            return _add(set._inner, bytes32(value));
        }

    
        function remove(UintSet storage set, uint256 value) internal returns (bool) {
            return _remove(set._inner, bytes32(value));
        }

        
        function contains(UintSet storage set, uint256 value) internal view returns (bool) {
            return _contains(set._inner, bytes32(value));
        }

        
        function length(UintSet storage set) internal view returns (uint256) {
            return _length(set._inner);
        }

    
        function at(UintSet storage set, uint256 index) internal view returns (uint256) {
            return uint256(_at(set._inner, index));
        }
    }
    
    contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    }


    interface Token {
        function transferFrom(address, address, uint) external returns (bool);
        function transfer(address, uint) external returns (bool);
        function balanceOf(address) external view returns (uint256);
    }

    contract FTEXCashBack is Ownable {
        using SafeMath for uint;
        using EnumerableSet for EnumerableSet.AddressSet;
        

        // FTEX token contract address
        address public constant tokenAddress = 0x9743cb5f346Daa80A3a50B0859Efb85A49E4B8CC;
        address public constant rewardAddress = 0xaA99007aa41ff10d76E91d96Ff4b0Bc773336C27 ;


        mapping(address => uint) public unclaimed;
        
        mapping(address => uint) public claimed;
        
        event CashbackAdded(address indexed user,uint amount ,uint time);
            
        event CashbackClaimed(address indexed user, uint amount ,uint time );
    

        
        function addCashback(address _user , uint _amount ) public  onlyOwner returns (bool)   {

                    unclaimed[_user] =  unclaimed[_user].add(_amount) ;
                   
                    emit CashbackAdded(_user,_amount,now);
                               
                    return true ;

        }
        
        function claim() public returns (uint)  {
            
            require(unclaimed[msg.sender] > 0, "Cannot claim 0 or less");

            uint amount = unclaimed[msg.sender] ;
            
            uint fee = amount.mul(500).div(1e4) ;
            
            amount = amount.sub(fee);

            Token(tokenAddress).transfer(msg.sender, amount);
            
            Token(tokenAddress).transfer(rewardAddress, fee);
          
            emit CashbackClaimed(msg.sender,unclaimed[msg.sender],now);
            
            claimed[msg.sender] = claimed[msg.sender].add(unclaimed[msg.sender]) ;
            
            unclaimed[msg.sender] =  0 ;

        }
          

        function getUnclaimeCashback(address _user) view public returns ( uint  ) {
                        return unclaimed[_user];
        }
        
        function getClaimeCashback(address _user) view public returns ( uint  ) {
                        return claimed[_user];
        }
          
 
        function addContractBalance(uint amount) public onlyOwner{
            require(Token(tokenAddress).transferFrom(msg.sender, address(this), amount), "Cannot add balance!");
            
        }
        
        function withdrawBalance() public onlyOwner {
           msg.sender.transfer(address(this).balance);
            
        } 
        
        function withdrawToken() public onlyOwner {
            require(Token(tokenAddress).transfer(msg.sender, Token(tokenAddress).balanceOf(address(this))), "Cannot withdraw balance!");
            
        } 
 
    

    }