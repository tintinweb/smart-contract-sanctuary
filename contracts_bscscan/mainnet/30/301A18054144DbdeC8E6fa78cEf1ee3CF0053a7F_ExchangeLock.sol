pragma solidity 0.6.2;

// SPDX-License-Identifier: No License

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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

     
    function _remove(Set storage set, bytes32 value) private returns (bool) {
      
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {  
             
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

         

            bytes32 lastvalue = set._values[lastIndex];

         
            set._values[toDeleteIndex] = lastvalue;
            
            set._indexes[lastvalue] = toDeleteIndex + 1; 
            
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


interface Token {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external returns (uint256);
}


contract ExchangeLock is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
 
  
    
    address public constant tokenAddress = 0x79fDe167C18C51892BE4B559b60d9420c02afd05;
    address public constant ben = 0x6FF418358be5D15d2217f4b0a2C624b20f8Eea00;
    uint public constant otokenQuantity = 10*1e6*1e18;
    uint public constant tokenShare = 25;
    uint public  tokenQuantity = tokenShare.mul(otokenQuantity).div(100);
    uint public  remainingToken = tokenShare.mul(otokenQuantity).div(100);
    uint public  releasePercentage = 260;
    uint public  initialReleasePercentage = 260;
    uint256 public lockedTime = 14 days ;
    uint public  nextClaim = block.timestamp.add(lockedTime);
    uint public  constant frequency = 30 days;
    uint public  currentCycle = 1;
 
  
      
        function releaseAmount() public view returns (uint){
               uint _releasePercentage = releasePercentage ;
               if(currentCycle == 1){
                   _releasePercentage = initialReleasePercentage ;
               }
               uint amt = _releasePercentage.mul(tokenQuantity).div(1e4) ;
                 if(amt > remainingToken){
                    amt = remainingToken ;
                }
                return amt ;
        }
       

        function claim()  public {               
            require(nextClaim < now, "Wait For next Cycle");
            require(remainingToken > 0, "Pool Ended");
            uint amt = releaseAmount() ;
            nextClaim = now + frequency ;
            currentCycle = currentCycle + 1 ;
            remainingToken = remainingToken.sub(amt) ;
            Token(tokenAddress).transfer(ben, amt);
        }
         
        function withdrawBNB() public onlyOwner{
                msg.sender.transfer(address(this).balance);
        }
        

        function transferExtraToken() public onlyOwner{
               Token(tokenAddress).transfer(msg.sender, Token(tokenAddress).balanceOf(address(this)));                 
        }
        
 
    
    
    
         

}

