/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-30
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

    contract GCBVault is Ownable {
        using SafeMath for uint;
        using EnumerableSet for EnumerableSet.AddressSet;
        
         uint public  vaultClose = 1e21;
         constructor(uint endTime) public {
            vaultClose = endTime;
        }
    

        // GCB token contract address
        address public constant tokenAddress = 0x3539a4F4C0dFfC813B75944821e380C9209D3446;
        
        uint public oneVaultLimit = 6e20;
        uint public fourVaultLimit = 6e20;

        uint public  oneCliff = 30 days;
        
        uint public  fourthCliff = 120 days;

        uint public  vaultTotal = 0;
        
        mapping(address => uint) public onemonth;
        
        mapping(address => uint) public onemonthCliff;
        
         mapping(address => uint) public claimed;
        
        mapping(address => uint) public fourmonth;
        
        mapping(address => uint) public fourmonthCliff;
        
        event DepositAdded(address indexed user,uint amount );
            
        event VaultClaimed(address indexed user, uint amount );
    

        
        function oneDeposit(uint _amount) public  returns (bool)   {
                    
                    uint amount = _amount.sub(_amount.mul(350).div(1e4));
                    require(oneVaultLimit >= amount , "Can't deposit more than limit") ;

                    require(vaultClose > now , "Can't deposit now") ;

                    Token(tokenAddress).transferFrom(msg.sender , address(this), _amount);
                    
                    onemonth[msg.sender] =  onemonth[msg.sender].add(amount) ;
                    
                    vaultTotal = vaultTotal.add(amount) ;

                    onemonthCliff[msg.sender] = now + oneCliff ;
                    
                    oneVaultLimit = oneVaultLimit.sub(amount) ;
                    
                    emit DepositAdded(msg.sender,amount);
                               
                    return true ;

            }
            
              function fourDeposit(uint _amount) public  returns (bool)   {

                    uint amount = _amount.sub(_amount.mul(350).div(1e4));
                    
                    require(fourVaultLimit >= amount , "Can't deposit more than limit") ;


                    require(vaultClose > now , "Can't deposit now") ;

                    Token(tokenAddress).transferFrom(msg.sender , address(this), _amount);
                    
                    fourmonth[msg.sender] =  fourmonth[msg.sender].add(amount) ;
                    
                    vaultTotal = vaultTotal.add(amount) ;

                    fourmonthCliff[msg.sender] = now + fourthCliff ;
                   
                    fourVaultLimit = fourVaultLimit.sub(amount);
                     
                    emit DepositAdded(msg.sender,amount);
                               
                    return true ;

            }
        
       
        function claim() public returns (uint)  {
            
            uint returnAmt = getTotalReturn(msg.sender) ;
            
            require(returnAmt > 0, "Cannot claim 0 or less");
            
            Token(tokenAddress).transfer(msg.sender, returnAmt);
          
            emit VaultClaimed(msg.sender,returnAmt);
            
            claimed[msg.sender] = claimed[msg.sender].add(returnAmt) ;
            
            if(onemonthCliff[msg.sender] < now ){
              oneVaultLimit = oneVaultLimit.add(onemonth[msg.sender]);
              vaultTotal = vaultTotal.sub(onemonth[msg.sender]) ;

              onemonth[msg.sender] =  0 ;
              onemonthCliff[msg.sender] =  0 ;
            }

            if(fourmonthCliff[msg.sender] < now){
              fourVaultLimit = fourVaultLimit.add(fourmonth[msg.sender]);
              vaultTotal = vaultTotal.sub(fourmonth[msg.sender]) ;

            fourmonth[msg.sender] =  0 ;
            fourmonthCliff[msg.sender] = 0 ;
            }


        }
          
        function getOneReturn(address _user) view public returns ( uint  ) {
                        
                        
                        uint oneR = 0 ;
                        if(onemonthCliff[_user] < now ){
                              oneR = onemonth[_user].add(onemonth[_user].mul(4200).div(1e4));
                        }
                       
                        return oneR ;
        }
        
          function getFourReturn(address _user) view public returns ( uint  ) {
                     
                        uint fourR = 0 ;
                        if(fourmonthCliff[_user] < now){
                             fourR = fourmonth[_user].add(fourmonth[_user].mul(24500).div(1e4));
                        }
                       
                        return fourR ;
        }

        function getTotalReturn(address _user) view public returns ( uint  ) {
                        
                        uint oneR = 0 ;
                        if(onemonthCliff[_user] < now ){
                              oneR = onemonth[_user].add(onemonth[_user].mul(4200).div(1e4));
                        }
                        
                        uint fourR = 0 ;
                        if(fourmonthCliff[_user] < now){
                             fourR = fourmonth[_user].add(fourmonth[_user].mul(24500).div(1e4));
                        }
                        uint total = oneR + fourR ;
                        return total ;
        }
        
        function getClaimeReturn(address _user) view public returns ( uint  ) {
                        return claimed[_user];
        }
          
          
        function updateCliff(uint one, uint four)  public onlyOwner returns ( bool  ) {
                        oneCliff = one ;
                        fourthCliff = four;
                        return true;
        }

        function updateVaultClose(uint _vaultClose)  public onlyOwner returns ( bool  ) {                        
                        vaultClose = _vaultClose;
                        return true;
        }
        
          
         
        function withdrawToken(uint amount) public onlyOwner {
            require(Token(tokenAddress).transfer(msg.sender, amount), "Cannot withdraw balance!");
            
        }   
    
 
        function addContractBalance(uint amount) public {
            require(Token(tokenAddress).transferFrom(msg.sender, address(this), amount), "Cannot add balance!");
            
        }
 
    

    }